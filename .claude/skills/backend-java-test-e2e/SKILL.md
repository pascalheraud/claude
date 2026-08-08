---
name: backend-java-test-e2e
description: Java End-to-End testing conventions — Playwright for browser automation, Testcontainers to stand up the DB and the app (npm-built frontend), one scenario class per scenario. Builds on the generic test-e2e skill.
---

# Java E2E tests

Java-specific implementation of the [[test-e2e]] conventions. Load [[test-e2e]] first — this skill only adds what's specific to a JVM/Testcontainers stack; it doesn't repeat the scenario/PageObject/snapshot rules.

## Browser automation: Playwright

[Playwright for Java](https://playwright.dev/java/) is the library used to drive the browser. It backs both the PageObject classes (element access, navigation) and the low-level actions a scenario test needs.

- One shared `Playwright`/`Browser` instance per test run (expensive to start), a fresh `BrowserContext`/`Page` per test (cheap, gives test isolation — cookies, storage, and navigation state don't leak between scenarios).
- PageObjects hold a `Page` reference, not a `Browser` or `BrowserContext` — they only need element-level access.

## Environment setup: Testcontainers for the DB, container or process for the app

The full stack for a test run is stood up as follows:
- **A DB container** (e.g. `PostgreSQLContainer`), migrated to the real schema — the same container/`DataSource` wiring described in [[backend-java-test-data-builder]] for E2E tests. Always a Testcontainer, regardless of how the app itself is run.
- **The app, built and served in production mode** (npm build + backend package, not a dev server, not `spring-boot:run` with devtools). How it's *run* depends on what the project already has:
  - If the project has a Dockerfile/docker-compose setup, use Testcontainers' `GenericContainer` (or a project-specific `Dockerfile`-based image) wired to the DB container's network alias.
  - If the project has **no** Docker packaging for the app (common for projects that were never containerized), don't add one just for E2E tests — start the built artifacts as plain OS processes instead (`java -jar` for the backend, `node server.js` with `NODE_ENV=production` for an npm-built frontend), pointed at the DB container's **host-mapped** port (the JVM/Node process isn't on the container's Docker network). This is still "production mode" — packaged/built artifacts, not source-run dev servers — it just skips the container layer for the app tier.

Both the DB container and the app (however it's run) are started once per test run (or per test class, depending on how expensive teardown/isolation trade off for the project) and exposed to Playwright via the app's mapped/host port. Isolation between scenarios comes from `TestDataBuilder.apply()` (delete + reseed) between tests, not from restarting containers or processes per test.

## Email-dependent flows: read the outbound-email table, don't stand up SMTP by default

Scenarios that depend on a value only ever delivered by email (a signup confirmation code, an OTP/temporary password, a password-reset link) need a way to read that value without a real mailbox. Before reaching for a full SMTP test double (GreenMail, MailHog, etc.), check whether the app already persists sent emails to a table/log as a side effect of sending — many apps do, for audit/debugging. If so, read the code straight from there via a JDBC/repository query, the same `DataSource` the test's `TestDataBuilder` uses. This is simpler than parsing MIME and doesn't require running an SMTP server in CI.

If persisting sent emails would also require *actually reaching* an SMTP server to succeed (i.e. sending throws when the mail server is unreachable), and the app has an existing non-production mode that skips the real SMTP call while still recording the message, prefer running the E2E app in that mode over standing up a fake SMTP server — but treat this as a deliberate, narrow, and reversible exception to "real app in production mode" (see [[test-e2e]]), not a default. Document the specific reason it's needed in the project-specific skill, and prefer the fake-SMTP-container approach if the non-production mode skips anything beyond email delivery.

```java
@Testcontainers
class E2ETestBase {
    @Container
    static PostgreSQLContainer<?> db = new PostgreSQLContainer<>("postgres:16")
        .withNetworkAliases("db");

    @Container
    static GenericContainer<?> app = new GenericContainer<>(DockerImageName.parse("myapp:test"))
        .withNetwork(db.getNetwork())
        .dependsOn(db)
        .withExposedPorts(8080);

    static TestDataBuilder testData;
    static Playwright playwright;
    static Browser browser;

    @BeforeAll
    static void setUpAll() {
        testData = new TestDataBuilder(TestDataBuilder.dataSourceFrom(db));
        playwright = Playwright.create();
        browser = playwright.chromium().launch();
    }
}
```

## Given/When/Then in JUnit

[[test-e2e]]'s Given/When/Then structure, in JUnit: a comment per section, even one-liners.

```java
@Test
void wrongPassword_showsErrorAndStaysOnPage() {
    // Given a registered user and the login page
    Data auxiliaire = testDataBuilder.newAuxiliaire();
    testDataBuilder.withPassword(auxiliaire, PASSWORD);
    testDataBuilder.apply();
    LoginPage loginPage = LoginPage.open(page, baseUrl(), auxiliaire.getEmail());

    // When submitting an incorrect password
    loginPage.fillPassword("wrong-password");
    loginPage.submit();

    // Then an error is shown and the user stays on the login page
    assertThat(loginPage.waitForPasswordErrorMessage()).isEqualTo("Votre mot de passe est incorrect");
    assertThat(loginPage.currentUrl()).contains("/connexion/");
}
```

## PageObjects in Java: static `open`, destination-typed returns

[[test-e2e]]'s PageObject conventions, in Java: a private constructor, a `static open(...)` factory for direct navigation, and methods returning the destination page's PageObject when the outcome is unconditional.

```java
class LoginPage {
    private final Page page;
    private LoginPage(Page page) { this.page = page; }

    // Direct navigation: static factory, not an instance method.
    static LoginPage open(Page page, String baseUrl, String email) {
        page.navigate(baseUrl + "/login?email=" + email);
        return new LoginPage(page);
    }

    LoginPage fillPassword(String password) { ... ; return this; }
    // Submitting logs in and always lands on the account page — returns that page's PageObject.
    AccountPage submit() { ... ; return new AccountPage(page); }
    String getErrorMessage() { ... }
}

class AccountPage {
    boolean isLoggedIn() { ... }
}

// in the scenario test:
LoginPage loginPage = LoginPage.open(page, baseUrl(), "test@example.com");
loginPage.fillPassword("wrong").submit();
assertThat(loginPage.getErrorMessage()).isEqualTo("Invalid credentials");
```

## Non-intrusive mocking in Spring: `@Primary` subclass

[[test-e2e]]'s "mocking is non-intrusive" rule, wired with Spring: the real service exposes a `protected` extension point, a mock subclass overrides it and is annotated `@Primary` so Spring wires it in ahead of the real bean — nothing in the app's own configuration references the mock.

```java
@Component
public class EmailsManager {
    protected void deliver(Email email, String content, SentEmail sentEmail) throws MailException, MessagingException {
        // real SMTP call
    }
}

@Component
@Primary
public class MockEmailsManager extends EmailsManager {
    @Autowired
    private MockCallRepository mockCallRepository;

    @Override
    protected void deliver(Email email, String content, SentEmail sentEmail) {
        mockCallRepository.insert(new MockCall(email.getRecipient(), email.getSubject(), content));
    }
}
```

Keep the mock subclass (and any supporting types it alone needs, e.g. `MockCall`/`MockCallRepository` above) out of the production build — see the project-specific skill for the build mechanism (e.g. a dedicated source root added only under an `e2e` Maven profile).

## One class per scenario

Every scenario (see [[test-e2e]] for what counts as a scenario) is its own test class — no single class enumerating multiple unrelated scenarios as separate `@Test` methods. **All scenarios are covered**: every user journey the app supports has a corresponding scenario class, not just a representative subset.

```java
class SignUpScenarioTest extends E2ETestBase {
    @Test
    void newUserCanSignUpAndReachDashboard() {
        testData.apply(); // seed/reset baseline data for this scenario

        Page page = browser.newContext().newPage();
        SignUpPage signUp = new SignUpPage(page).navigateTo();
        signUp.fillEmail("new@example.com").fillPassword("Str0ngPass!").submit();

        assertThat(new DashboardPage(page).isDisplayed()).isTrue();
    }
}
```

A scenario class may still have multiple `@Test` methods if the scenario has meaningfully distinct paths (e.g. "sign-up" happy path vs. "sign-up with already-used email") — what it must not do is bundle a *different* scenario (e.g. "search") into the same class for convenience.

## Project-specific usage

A project skill using these conventions should document:
- The Testcontainers image/version used for the DB.
- Whether the app runs as a container or as a plain OS process for E2E tests, and how it's built (npm build step, Dockerfile location, or packaged jar/bundle path and launch command).
- How email-dependent flows read their codes (outbound-email table + query, or a fake SMTP container), and whether that required a non-default app run mode — with the reason.
- Where scenario test classes and PageObjects live, and the naming convention (e.g. `XxxScenarioTest`, `XxxPage`).
- The CI job that runs the E2E suite (see [[test-e2e]]).
