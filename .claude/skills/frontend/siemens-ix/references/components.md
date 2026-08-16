<!-- Source: https://ix.siemens.io/docs/components/overview (fetched 2026-08-13) — re-check that page for new/renamed components before treating this list as exhaustive for a future iX version. Component names below are the React wrapper export (`@siemens/ix-react`, pinned 5.1.1 in this environment); the linked doc page covers the underlying web component and applies to every framework wrapper. -->

# Siemens iX — component catalog

Full categorized list from the official docs index (`/docs/components/overview`), each with its guide URL and the matching `@siemens/ix-react` export. Use this to find the right component before reaching for a custom one, per [[siemens-ix]]'s "reach for iX first" rule.

Doc URL pattern: `https://ix.siemens.io/docs/components/<slug>` (append `/guide` for usage, `/code` for copy-paste examples — not every slug follows the plain suffix pattern, e.g. `input` → `ix-input`, but `Date input` → slug `input-date` → `IxDateInput`).

## Application frame

| Component | React export | Doc |
|---|---|---|
| Application | `IxApplication` | `/docs/components/application` |
| Application header | `IxApplicationHeader` | `/docs/components/application-header` |
| Application menu | `IxMenu`, `IxMenuItem`, `IxMenuCategory`, `IxMenuAvatar`, `IxMenuAvatarItem`, `IxMenuSettings`, `IxMenuSettingsItem`, `IxMenuAbout`, `IxMenuAboutItem`, `IxMenuAboutNews` | `/docs/components/application-menu` |
| Avatar | `IxAvatar` | `/docs/components/avatar` |
| Content | `IxContent` | `/docs/components/content` |
| Content header | `IxContentHeader` | `/docs/components/content-header` |
| About and legal | `IxMenuAbout`, `IxMenuAboutItem`, `IxMenuAboutNews` | `/docs/components/about-and-legal` |
| Settings | `IxMenuSettings`, `IxMenuSettingsItem` | `/docs/components/settings` |
| Popover news | `IxPopover*` family | `/docs/components/popover-news` |

See [[siemens-ix-react]]'s "Application shell" section for the real composition pattern (`IxApplication` + `IxApplicationHeader` + `IxMenu` + `IxContent`), sourced from the official React starter app.

## Navigation and hierarchy

| Component | React export | Doc |
|---|---|---|
| Breadcrumb | `IxBreadcrumb`, `IxBreadcrumbItem` | `/docs/components/breadcrumb` |
| Group | `IxGroup`, `IxGroupItem`, `IxGroupContextMenu` | `/docs/components/group` |
| Pagination | `IxPagination` | `/docs/components/pagination` |
| Tabs | `IxTabs`, `IxTabItem` | `/docs/components/tabs` |
| Tree | (not exported under a top-level `IxTree*` name in this package version — check `@siemens/ix-react` exports before use) | `/docs/components/tree` |
| Workflow | `IxWorkflowSteps`, `IxWorkflowStep` | `/docs/components/workflow` |

## Containers and layouts

| Component | React export | Doc |
|---|---|---|
| Blind (collapsible panel) | `IxBlind` | `/docs/components/blind` |
| Card | `IxCard`, `IxCardContent`, `IxCardTitle`, `IxCardAccordion` | `/docs/components/card` |
| Card list | `IxCardList` | `/docs/components/card-list` |
| Flip (flip-tile) | `IxFlipTile`, `IxFlipTileContent` | `/docs/components/flip` |
| Event list | `IxEventList`, `IxEventListItem` | `/docs/components/event-list` |
| Layout auto | `IxLayoutAuto` | `/docs/components/layout-auto` |
| Layout grid | `IxLayoutGrid`, `IxRow`, `IxCol` | `/docs/components/layout-grid` |
| Modal | `IxModal`, `IxModalHeader`, `IxModalContent`, `IxModalFooter` | `/docs/components/modal` |
| Panes | `IxPane`, `IxPaneLayout` | `/docs/components/panes` |
| Tile | `IxTile`, `IxPushCard`, `IxActionCard` | `/docs/components/tile` |

## Forms (guides, not components)

`/docs/components/forms-field`, `/docs/components/forms-layout`, `/docs/components/forms-validation`, `/docs/components/forms-behavior` — patterns for composing the input components below into real forms (field layout, validation states, `@form-ready` behavior), not standalone components.

## Input fields and selections

| Component | React export | Doc |
|---|---|---|
| Category filter | `IxCategoryFilter` | `/docs/components/category-filter` |
| Checkbox | `IxCheckbox`, `IxCheckboxGroup` | `/docs/components/checkbox` |
| Custom field | `IxCustomField` | `/docs/components/custom-field` |
| Date dropdown | `IxDateDropdown` | `/docs/components/date-dropdown` |
| Date input | `IxDateInput` | `/docs/components/input-date` |
| Date picker | `IxDatePicker` | `/docs/components/date-picker` |
| Date time picker | `IxDatetimePicker`, `IxDatetimeInput` | `/docs/components/date-time-picker` |
| Expanding search | `IxExpandingSearch` | `/docs/components/expanding-search` |
| Number input | `IxNumberInput` | `/docs/components/input-number` |
| Range field | `IxRangeField` | `/docs/components/range-field` |
| Radio | `IxRadio`, `IxRadioGroup` | `/docs/components/radio` |
| Select | `IxSelect`, `IxSelectItem` | `/docs/components/select` |
| Slider | `IxSlider` | `/docs/components/slider` |
| Input (text) | `IxInput` — `name` prop is **not** forwarded to the internal native `<input>`; see [[siemens-ix-react]]'s Playwright note if you need to target it in e2e tests | `/docs/components/input` |
| Textarea | `IxTextarea` | `/docs/components/textarea` |
| Time picker | `IxTimePicker`, `IxTimeInput` | `/docs/components/time-picker` |
| Toggle | `IxToggle` | `/docs/components/toggle` |
| Upload | `IxUpload` | `/docs/components/upload` |

## Buttons and actions

| Component | React export | Doc |
|---|---|---|
| Button | `IxButton` | `/docs/components/button` |
| Dropdown button | `IxDropdownButton`, `IxDropdown`, `IxDropdownItem`, `IxDropdownHeader`, `IxDropdownQuickActions` | `/docs/components/dropdown-button` |
| Icon button | `IxIconButton`, `IxIconToggleButton` | `/docs/components/icon-button` |
| Link button | `IxLinkButton` | `/docs/components/link-button` |
| Split button | `IxSplitButton` | `/docs/components/split-button` |
| Toggle button | `IxToggleButton` | `/docs/components/toggle-button` |
| Chip | `IxChip`, `IxFilterChip` | `/docs/components/chip` |

## System feedback and status

| Component | React export | Doc |
|---|---|---|
| Empty state | `IxEmptyState` | `/docs/components/empty-state` |
| Message bar | `IxMessageBar` | `/docs/components/messagebar` |
| Pill | `IxPill` | `/docs/components/pill` |
| Progress indicator | `IxProgressIndicator` | `/docs/components/progress-indicator/guide` |
| Spinner | `IxSpinner` | `/docs/components/spinner` |
| Toast | `IxToast`, `IxToastContainer` | `/docs/components/toast` |
| Tooltip | `IxTooltip` | `/docs/components/tooltip` |

## Data display

| Component | React export | Doc |
|---|---|---|
| Angular data grid | (Angular-specific; not part of `@siemens/ix-react`) | `/docs/components/grid` |
| HTML table | plain HTML `<table>` styled by iX CSS, no dedicated component | `/docs/components/html-grid` |
| Key value | `IxKeyValue` | `/docs/components/key-value` |
| Key value list | `IxKeyValueList` | `/docs/components/key-value-list` |
| KPI | `IxKpi` | `/docs/components/kpi` |

## Charts

Chart components are documented separately (`@siemens/ix-echarts` theme + ECharts itself) — see `/docs/components/charts-overview/overview` and the line/bar/gauge/pie/3D/special-chart guide pages linked from there. Not part of the core `@siemens/ix-react` component set; only relevant if the project adopts ECharts.

## Typography and icons

Not listed in the components-overview grouping above but exported and used throughout this catalog:
- `IxTypography` — text styling (headings, body, labels) instead of raw `<p>`/`<h1>` with hand-rolled CSS. Docs: `/docs/styles/typography` (per [[siemens-ix]]).
- `IxIcon` — icon rendering via `@siemens/ix-icons` name/import, instead of inlined SVGs. Docs: `/docs/icons/icon-library` (per [[siemens-ix]]).
