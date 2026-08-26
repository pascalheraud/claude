# React — Capacitor Specific Reference

## 1. App lifecycle & state au resume

Le WebView ne se démonte pas quand l'app passe en background. React conserve son état mais les
données peuvent être périmées au retour. Il faut écouter `appStateChange` manuellement.

```typescript
import { useEffect } from 'react';
import { App, AppState } from '@capacitor/app';

function useAppResume(onResume: () => void) {
  useEffect(() => {
    const handle = App.addListener('appStateChange', (state: AppState) => {
      if (state.isActive) onResume();
    });
    return () => { handle.then(h => h.remove()); };
  }, [onResume]);
}

// Usage dans un composant
function PhraseList() {
  const refreshData = useCallback(() => { /* reload from IDB */ }, []);
  useAppResume(refreshData);
}
```

Autres événements utiles :
```typescript
App.addListener('resume', handler);        // alias de appStateChange isActive=true
App.addListener('pause', handler);         // app mise en background
App.addListener('appUrlOpen', handler);    // deep link reçu
```

---

## 2. Cleanup des listeners Capacitor

`addListener` est async et retourne un `PluginListenerHandle`. Sans cleanup, les listeners
s'accumulent à chaque re-mount (surtout visible en dev avec React StrictMode qui double-monte).

```typescript
// ✅ Pattern correct
useEffect(() => {
  let handle: Awaited<ReturnType<typeof Keyboard.addListener>>;

  Keyboard.addListener('keyboardWillShow', ({ keyboardHeight }) => {
    setKbHeight(keyboardHeight);
  }).then(h => { handle = h; });

  return () => { handle?.remove(); };
}, []);

// ✅ Pattern alternatif avec Promise.all pour plusieurs listeners
useEffect(() => {
  const listeners = Promise.all([
    Keyboard.addListener('keyboardWillShow', onShow),
    Keyboard.addListener('keyboardWillHide', onHide),
  ]);

  return () => { listeners.then(hs => hs.forEach(h => h.remove())); };
}, [onShow, onHide]);
```

**React StrictMode** en dev double-monte les composants → double les listeners. Ne pas confondre
avec un vrai bug de production. Toujours vérifier le cleanup avant de chercher ailleurs.

---

## 3. Back button Android + React Router

Ne jamais utiliser `window.history.back()` dans une SPA React Router — ça bypasse le state du router.

```typescript
// Avec React Router v6
import { useNavigate } from 'react-router-dom';
import { App } from '@capacitor/app';

function useAndroidBackButton() {
  const navigate = useNavigate();

  useEffect(() => {
    const handle = App.addListener('backButton', ({ canGoBack }) => {
      if (canGoBack) {
        navigate(-1);
      } else {
        App.exitApp();
      }
    });
    return () => { handle.then(h => h.remove()); };
  }, [navigate]);
}
```

Pour les écrans modaux ou drawers qui doivent intercepter le back avant le router :
```typescript
// Surcharge locale dans le composant modal
useEffect(() => {
  const handle = App.addListener('backButton', () => {
    closeModal();  // intercepte — ne propage pas au router
  });
  return () => { handle.then(h => h.remove()); };
}, [closeModal]);
```

---

## 4. Custom hooks Capacitor

Encapsuler les plugins dans des hooks dédiés évite les appels directs dans les composants et
centralise le cleanup.

```typescript
// hooks/useKeyboardHeight.ts
export function useKeyboardHeight() {
  const [height, setHeight] = useState(0);

  useEffect(() => {
    const listeners = Promise.all([
      Keyboard.addListener('keyboardWillShow', e => setHeight(e.keyboardHeight)),
      Keyboard.addListener('keyboardWillHide', () => setHeight(0)),
    ]);
    return () => { listeners.then(hs => hs.forEach(h => h.remove())); };
  }, []);

  return height;
}

// hooks/useNetworkStatus.ts
import { Network } from '@capacitor/network';

export function useNetworkStatus() {
  const [online, setOnline] = useState(true);

  useEffect(() => {
    Network.getStatus().then(s => setOnline(s.connected));
    const handle = Network.addListener('networkStatusChange', s => setOnline(s.connected));
    return () => { handle.then(h => h.remove()); };
  }, []);

  return online;
}

// hooks/useAppState.ts
export function useAppState() {
  const [isActive, setIsActive] = useState(true);

  useEffect(() => {
    const handle = App.addListener('appStateChange', s => setIsActive(s.isActive));
    return () => { handle.then(h => h.remove()); };
  }, []);

  return isActive;
}
```

---

## 5. Performances React sur mobile WebView

### Listes longues
Le WebView est moins pardonnable qu'un browser desktop sur les re-renders.

```typescript
// Virtualisation avec react-window
import { FixedSizeList } from 'react-window';

function PhraseList({ phrases }: { phrases: Phrase[] }) {
  const Row = useCallback(({ index, style }: { index: number; style: React.CSSProperties }) => (
    <div style={style}>
      <PhraseCard phrase={phrases[index]} />
    </div>
  ), [phrases]);

  return (
    <FixedSizeList height={window.innerHeight} itemCount={phrases.length} itemSize={72} width="100%">
      {Row}
    </FixedSizeList>
  );
}
```

### Memo & callbacks
```typescript
// Mémoïser les composants de liste
const PhraseCard = React.memo(({ phrase }: { phrase: Phrase }) => { /* ... */ });

// Stabiliser les callbacks passés en props
const handleSelect = useCallback((id: string) => {
  setSelected(id);
}, []); // dépendances minimales
```

### Lazy loading des routes
```typescript
// router.tsx
const PhraseDetail = React.lazy(() => import('./screens/PhraseDetail'));
const Settings = React.lazy(() => import('./screens/Settings'));

function Router() {
  return (
    <Suspense fallback={<LoadingScreen />}>
      <Routes>
        <Route path="/phrase/:id" element={<PhraseDetail />} />
        <Route path="/settings" element={<Settings />} />
      </Routes>
    </Suspense>
  );
}
```

---

## 6. IndexedDB + React state

Pattern recommandé : IDB comme persistence, React state comme source de vérité en mémoire.
Ne jamais lire IDB pendant le render — toujours via `useEffect` ou un service.

```typescript
// Chargement initial
function usePackData(packId: string) {
  const [pack, setPack] = useState<Pack | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    packService.getById(packId)
      .then(setPack)
      .finally(() => setLoading(false));
  }, [packId]);

  return { pack, loading };
}

// Écriture : mutation → IDB → update state local
async function handleComplete(phraseId: string) {
  await progressService.markComplete(phraseId);   // écrit en IDB
  setProgress(prev => ({ ...prev, [phraseId]: true }));  // update state
}
```

**Ne pas** synchroniser IDB → state via polling. Utiliser un pattern event/callback depuis le
service si plusieurs composants doivent réagir à la même mutation.

---

## 6bis. Web-component design systems (Stencil/Lit-based UI kits) inside Capacitor

Design systems shipped as web components (Siemens iX, Ionic Framework itself, Shoelace, etc.) render
their internal layout inside a **shadow root**. Two consequences that only bite once you're inside a
Capacitor WebView chasing safe-area bugs:

1. **They often don't read `env(safe-area-inset-*)` directly.** Check whether the library exposes its
   own CSS custom properties for insets instead (e.g. Siemens iX's `ix-application`/`ix-content`/
   `ix-menu`/`ix-modal` read `--ix-safe-area-inset-{top,right,bottom,left}`, defaulting to `0`, *not*
   `env(...)`). Custom properties inherit through shadow boundaries, `env()` padding applied to an
   ancestor element (e.g. `body`) does not reach into the shadow tree — so "I set padding on body and
   the notch still overlaps the header" usually means the library wants a var bridge, not raw `env()`:
   ```css
   :root {
     --ix-safe-area-inset-top: env(safe-area-inset-top);
     --ix-safe-area-inset-bottom: env(safe-area-inset-bottom);
     /* ...right/left the same way; check the specific library's var names */
   }
   ```
   Also check whether the library's own root element sizes itself with `100vh`/`100vw` (as
   `ix-application` does) rather than `100%` — if so, padding on `html`/`body` has no effect on it at
   all, regardless of the safe-area question.
2. **Hardcoded shadow-DOM spacing can't be overridden by a normal outer selector.** A `:host {...}`
   rule inside the component's own stylesheet has higher effective priority than a same-specificity
   outer tag selector from your page's CSS, even though `:host`'s specificity is only that of a
   pseudo-class. If a component ships a fixed, non-configurable padding/margin that's wrong for a
   mobile layout (a common desktop-oriented default) and exposes no CSS custom property or `part()`
   for it, the only lever from outside is `!important`:
   ```css
   /* Only works if the library gives no CSS var for this — check first */
   ix-content {
     padding-left: 1rem !important;
     padding-right: 1rem !important;
   }
   ```

---

## 7. Build Vite + Capacitor

### `vite.config.ts` — points critiques
```typescript
export default defineConfig({
  base: './',  // ← OBLIGATOIRE — chemins relatifs pour le WebView

  build: {
    sourcemap: false,        // ne pas embarquer les sources dans l'APK/IPA
    target: 'es2015',        // compatibilité WebView Android anciens
    chunkSizeWarningLimit: 500,
  },

  plugins: [react()],
});
```

Sans `base: './'`, les assets (JS, CSS, images) cherchent `/assets/...` en absolu — introuvable
dans le WebView Capacitor qui sert depuis `capacitor://localhost/`.

### Tree-shaking des plugins
```typescript
// ✅ Import nommé — seul le plugin utilisé est bundlé
import { Camera } from '@capacitor/camera';
import { Filesystem } from '@capacitor/filesystem';

// ❌ Éviter l'import du core global
import Capacitor from '@capacitor/core';
```

### Workflow de build
```bash
npm run build          # Vite → dist/
npx cap sync           # copie dist/ vers android/assets/public et ios/
npx cap open android   # ouvre Android Studio
npx cap open ios       # ouvre Xcode
```

Toujours faire `cap sync` après chaque build ou ajout de plugin.

---

## 8. Appels plugins — règles dans les composants React

```typescript
// ✅ Dans un useEffect (après le mount)
useEffect(() => {
  Haptics.impact({ style: ImpactStyle.Light });
}, []);

// ✅ Dans un event handler
const handlePress = async () => {
  await Haptics.impact({ style: ImpactStyle.Medium });
  await doSomething();
};

// ❌ Jamais pendant le render
function BadComponent() {
  Camera.checkPermissions(); // ← crash ou comportement indéfini
  return <div />;
}
```

Les plugins natifs sont async et peuvent lancer des permissions dialogs ou des animations natives —
ils ne doivent jamais bloquer le cycle de render React.
