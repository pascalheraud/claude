---
name: db
description: Java database access conventions — column loading, required columns documentation, partial entity patterns
---

# Java + Database Conventions

## Column loading

Only load the columns strictly necessary for the operation. Never fetch the full entity when only a subset of fields is needed.

When a method receives an entity as a parameter and relies on specific columns being populated, document the required columns in a Javadoc comment:

```java
/**
 * @param newsletter required columns: id, auxiliaireId, titreEmail, corpsEmail
 */
private void sendTestEmail(Newsletter newsletter) { … }
```
