# PostHog — React integration

## Screen tracking with useEffect

Track the current screen on component mount:

```ts
// In each screen component
useEffect(() => {
  analyticsService.screen("LessonScreen", { pack_id: packId });
}, []);
```

## Screen tracking with React Router

Centralize screen tracking in the router subscription instead of per-component `useEffect`:

```ts
// router setup (React Router v6)
router.subscribe((state) => {
  analyticsService.screen(state.location.pathname);
});
```
