# CLAUDE.md — DAW Project Manager

Instructions for AI assistants working on this codebase.

---

## Non-negotiables

### Tests are part of every task
- Every bug fix must include a regression test that would have caught the bug.
- Every new feature must include tests covering its logic in full.
- Run `flutter test` before every commit — only commit if all tests pass.
- If logic is too deep in the widget tree to unit test, write the closest possible test (model/service/repository level) and note explicitly what cannot be automated.

### Always use AppLocalizations for UI strings
- Never hardcode user-visible text in widget trees.
- Any label, tooltip, snackbar message, dialog text, or button label must have a key in `lib/l10n/app_en.arb` and be referenced via `AppLocalizations.of(context)!.someKey`.
- Add the key to all locale ARB files, then run `flutter gen-l10n`.
- The app ships in 9 languages — hardcoded strings silently break all non-English users.
- `app_pt.arb` is Brazilian Portuguese only — there is a single Portuguese locale for this app, and it targets Brazil. Never introduce European Portuguese spelling or vocabulary (e.g. "ficheiro", "deteção"/"detetar", "descarregar", "ecrã", "utilizador", "está a fazer"-style progressive) — use the Brazilian equivalent instead (e.g. "arquivo", "detecção"/"detectar", "baixar", "tela", "usuário", "está fazendo"). When adding or editing a `pt` string, match the vocabulary already established in the rest of `app_pt.arb`.

### New model fields must be evaluated for Drive sync AND local backup
- When adding a field to `MusicProject` (or any synced model), decide: is this user-generated data or a device-local preference?
- **User data** (metadata, timers, todos, paths) → add to `_serializeProject` AND `_deserializeProject` in `lib/services/google_drive_sync_service.dart`. If skipped, the field is silently lost on every Drive restore.
- **Device-local settings** (which theme is selected, layout, update checks) → do NOT sync. `AppSettings` fields are generally device-local.
- The split can run through one feature: a **custom theme's definition** is user data (synced and backed up), while **which theme is selected** is a device-local preference (neither). Ask the question per field, not per feature.
- Also check `lib/services/backup_service.dart` (local file export/import) for the same question, for any *global* (non-per-profile) data — `TodoTemplate`, `ProjectTemplate`, `TemplateRoot`, custom mixdown folder names, custom themes, phase settings. This is Flatpak's only backup path (see below), so a field skipped here is a field Flatpak users can never back up at all, not just "won't survive a Drive restore."
- Merging is **union, never deletion**: something present locally but absent in the incoming data is something made since, not something removed. On a same-id collision the newer `updatedAt` wins. `mergeCustomThemes` is the reference implementation.

### Google Drive sync is not offered inside Flatpak
- `GoogleDriveSyncService.isSupported` is `false` only when actually running inside a Flatpak sandbox (detected via the `/.flatpak-info` marker file every Flatpak app has at runtime), `true` everywhere else — including the plain Linux tarball and the AppImage. Every UI entry point to `GoogleDriveSyncPage` (dashboard, profile page, startup dialog, tray menu) is gated on it — don't add a new one without the same gate.
- Why: the desktop OAuth flow requires a client secret (confirmed against a live Google sign-in attempt — PKCE alone isn't accepted for this app's "Desktop app" OAuth client type; see the long comment on `_desktopClientSecret` in `google_drive_sync_service.dart`). Flathub's build sandbox has no secret-injection mechanism, so shipping the secret there would mean committing it in the open in the public Flathub submission repo. Not offering the feature was chosen over that for Flatpak specifically — the tarball/AppImage are built by this repo's own CI (`build_linux` in `release.yml`), same trust boundary as Windows/macOS, so they get the real secret too.
- The Flatpak build compiles `lib/config/oauth_config.dart` from the committed template's placeholder text directly (no real values, no GitHub secrets involved) — see `flatpak/README.md`. The Linux tarball/AppImage build (`build_linux`) injects real values from GitHub secrets like every other desktop platform.

---

## Architecture

### State management — Riverpod
- All providers live in `lib/providers/providers.dart`.
- Main data flow: `repositoryProvider` → `allProjectsStreamProvider` → `projectsProvider` (filtered/sorted) → UI.
- Search state is per-tab: `projectsSearchProvider`, `releasesSearchProvider`, `queueSearchProvider`, etc.

### Local persistence — Hive CE
- Models with `@HiveType` / `@HiveField` and a `part` directive (e.g. `Release`, `TodoTemplate`) use code-generated adapters — run `dart run build_runner build --delete-conflicting-outputs` after changing them.
- `MusicProject` and other models have manually written `TypeAdapter`s inline in their model file — `build_runner` skips these intentionally.
- Adapters are registered in `ProjectRepository` with `isAdapterRegistered` guards to prevent double-registration.

### Platform detection
- Use `MobileUtils.isMobile()` (from `lib/utils/mobile_utils.dart`) for mobile vs desktop checks — not `Platform.isAndroid` or `Platform.isIOS` directly.
- Desktop = macOS + Windows + Linux. Mobile = Android + iOS.
- Primary development and test target is **macOS**.
- Linux is otherwise a full desktop target. The only feature gap is Google Drive sync specifically inside the Flatpak build (see `GoogleDriveSyncService.isSupported` above) — the tarball/AppImage have it.

### Themes — every theme is a `CustomTheme` spec fed through one builder
- There is exactly **one** `ThemeData` builder: `AppThemes.buildFrom(CustomTheme)` in `lib/providers/theme_provider.dart`. The three built-ins are `CustomTheme` constants (`neonDarkSpec`, `classicDarkSpec`, `studioLightSpec`) run through it, and user themes go through the same call. Never hand-write a second `ThemeData` — a component styled in only one builder is a component user themes fall back to raw Material defaults for.
- `test/providers/built_in_theme_regression_test.dart` keeps a verbatim copy of the pre-refactor themes and asserts `buildFrom` still reproduces them. If you change `buildFrom`, that test tells you which built-in you moved. Its one accepted deviation (`studioLight`'s `bodySmall` tone) is documented in the file.
- Two active themes: `AppThemeType.neonDark` and `AppThemeType.classicDark`. `AppThemeType.studioLight` exists in the enum but is hidden from the UI until it is ready — `AppThemes.visibleBuiltIns` is the list every menu, switcher and picker must use; `allBuiltIns` is only for resolving a stored id.
- The active theme is identified by a **string id**, not an enum: `selectedThemeIdProvider` holds either an `AppThemeType.name` or a user theme's uuid, and `activeThemeProvider` resolves it to a spec (falling back to Classic Dark for anything unknown). Watch `themeDataProvider` for colors and `activeThemeProvider` when you need the spec.
- **Never branch on theme identity.** `themeType == AppThemeType.neonDark` used to pick grid row colors in four places, which silently lumped every user theme in with Classic Dark. Derive from the spec instead — `hasVividAccent`, `gridRowSelectColor`, `gridRowOddColor`, `gridRowEvenColor`, `gridBorderColor` in `lib/utils/theme_derivations.dart`.
- A widget that caches colors (any `TrinaGrid`) must key on `spec.identityKey`, not `spec.id` — editing a user theme keeps its id, and the id alone would leave the old palette on screen.
- User themes are **dark-only in v1**: the editor pins `brightness` to `Brightness.dark` because large parts of the UI still carry hardcoded `Colors.white70`-style literals that vanish on a light background. Unlocking the toggle is the same work as finishing `studioLight`.
- Theme *definitions* are user data: they sync to Drive and go into local backup (see `mergeCustomThemes` in `lib/services/custom_theme_merge.dart`, shared by both so a restore and a sync can't disagree). The *selected* theme is a device-local preference and is deliberately in neither.

---

## UI conventions

### An archived project is not a missing one
- Archiving (#116) zips a project out of the working library and sets `archivePath` / `archivedAt` / `archiveEntryPath`. `filePath` deliberately keeps naming the **original location** — it is what `fileExtension`, DAW launching and the containing-folder helpers read, and leaving it alone is what makes "restore to where it came from" free.
- So `isMissingFileCandidate` is `!isVirtual && !isArchived`. Anything new that reads a non-resolving path as "the file was deleted" must gate on it, exactly as version stacks already require. Getting this wrong offers to delete the one row pointing at the archive holding the work.
- `ArchiveScope` is resolved by `defaultScopeFor` in `lib/services/project_archive_service.dart`: a bundle (`.logicx`/`.luna`/`.band`) archives alone, a file with a folder to itself takes the folder, a file sharing its folder takes only itself. The shared "does anything else live here?" test is `folderIsDedicatedTo` in `lib/utils/project_folder_utils.dart`, used by moving too.
- Never let an archive land in a scan root, inside one, or above one — the next scan would re-index every zip straight back in. `conflictingScanRoot` is the guard, and it runs both at destination-pick time and again inside `archiveProject`.
- Originals are deleted only when the user asked *and* the written zip has been reopened and verified entry by entry (`verifyArchive`). Zips are written to a `.zip.part` and renamed on success, so a cancelled or crashed run never leaves something that looks finished.
- Archived state is **user data** (all three fields sync and back up); the archive *destination folder* (`archiveFolderProvider`) is a **device-local preference** and is in neither. Same split as themes.
- Archived visibility is its own 0/1/2 axis (`showArchivedProjectsProvider`), not `hidden`. Session-only, for the same reason as the hidden one.
- Archiving and moving are both refused for a **stack** — it owns no files, so doing either coherently means doing it to every member and re-pointing the stack. Members are archived and moved individually.

### A version stack is a *virtual* project — never assume a row has a file
- Version stacking (#94) makes a stack a real row in the projects box with `isVirtual: true`, whose `filePath` is the **folder** its versions live in, not a file. Anything that treats a non-resolving path as "the file was deleted" must gate on `MusicProject.isMissingFileCandidate` — `missingProjectIds` and the grid's `cloud_off` indicator already do. Getting this wrong offers to delete the one row holding a song's shared notes, todos, deadline and work time.
- A stack owns the shared metadata; its members keep their own fields **untouched but dormant**, which is what makes `unstack` lossless. Stacking promotes exactly one member's metadata (`stackProjects(metadataSourceId:)`) — nothing is ever merged, so two versions' details cannot be mangled together. The dashboard asks which member to promote only when two or more of them satisfy `MusicProject.hasUserMetadata`.
- Work time and sessions on a stack are **derived on read** (`stackTotalWorkSeconds` / `stackSessions`), never stored on the stack row. Don't add a rolled-up copy — it would need invalidating on every timer tick, member deletion and Drive restore.
- `projectsProvider` filters out stack members (`isStackMember`), so the list shows the stack instead of its versions. Anything totalling that list counts a stacked song once.
- `ScanMode.versionStack` is the third scan mode: it auto-stacks by immediate parent folder via `ProjectRepository.autoStackFolders()`, which runs after every scan. It only ever *adds* — it never unstacks, re-parents or dissolves anything, so hand-made stacks survive a rescan. Manual stacking works in **all three** modes; the mode only controls the automatic pass.

### Launching a project in its DAW always goes through `launchProjectInDaw`
- Use `launchProjectInDaw(context, ref, project)` from `lib/ui/session_actions.dart` for every "open/launch in DAW" button — never call `FileLauncher.launchProject`/`launchWithBinary` directly from UI code.
- Why: this is the one place that knows about the DAW executable-override system (`ProjectRepository.getDawLaunchCommandPaths`, Settings > DAW Locations — every desktop platform), its missing-path remediation, and the configure prompt (`showDawLaunchCommandDialog`). A DAW type maps to a *list* of override paths: one resolves → run it, several resolve → `showDawLaunchPickerDialog` asks which. The configure prompt fires up front on Linux (no dependable OS file association) and only after a failed standard launch on Windows/macOS. A direct `FileLauncher` call bypasses all of that. The decision lives in the pure `resolveDawLaunchAction` / `shouldPromptDawLocationAfterFailedLaunch` helpers.

### Destructive confirm-dialog buttons need an explicit `foregroundColor`
- Any `ElevatedButton`/`FilledButton` styled with a hardcoded red `backgroundColor` (delete/remove/reset confirmations) must also set `foregroundColor` — Flutter does not derive readable text contrast from an arbitrary `backgroundColor` on its own, and the default has been wrong before.
- Pairing used throughout the app: `Colors.red` / `Colors.red.shade700` → `foregroundColor: Colors.white`; `Colors.red.shade300` (lighter, used for less-destructive actions like "Hide" or "Remove") → `foregroundColor: Colors.black`.

### A `Row` pairing a text field with a button needs `CrossAxisAlignment.center`
- `Row(children: [Expanded(child: TextField(...)), button])` defaults to `CrossAxisAlignment.start`, which top-aligns the button against the field's full decorated height (label + border) instead of visually centering it — looks broken, especially once the field grows (e.g. an `errorText`).
- Always set `crossAxisAlignment: CrossAxisAlignment.center` on this shape of `Row`. This has been the same one-line bug fixed independently in multiple dialogs — grep for `CrossAxisAlignment.start` near a `TextField` before assuming a new field+button row is fine as-is.

### A DAW logo shown as a field's `prefixIcon` needs explicit sizing
- `Image.asset(getDawLogoPath(dawType), ...)` renders at the source PNG's native size if unconstrained — oversized and breaking the field's layout when used as an `InputDecoration.prefixIcon`.
- Always pass `width: 16, height: 16, fit: BoxFit.contain`, with an `errorBuilder` falling back to `Icon(Icons.piano, color: color)` for DAWs with no logo asset. See `_buildDawPrefixIcon` in `lib/ui/project_detail_page.dart` for the canonical implementation to mirror.

### A project's visual identity is always drawn by `ProjectCoverAvatar` / `ProjectCoverBleed`
- Cover art, accent color and icon (#110) are never rendered by hand — the mobile list and the detail header use `ProjectCoverAvatar`, the projects grid uses `ProjectCoverBleed` — so the "cover art wins over color/icon" rule and the stale-path fallback live in one place.
- **Nothing is assigned by default.** `thumbnailPath`, `accentColor` and `iconKey` are all opt-in; `projectAccentColor` / `projectIcon` in `lib/utils/project_visuals.dart` return null for a project nobody has decorated, and the widgets then render *zero size*. Never invent a stand-in color, icon or placeholder image for a list row — a generic default on every row is the thing this feature deliberately does not do. `projectHasVisualIdentity` is the check for "is there anything to draw".
- The one exception is `showEmptyPlaceholder`, for editing surfaces only (detail header, appearance dialog), where the tile is the way into the editor.
- A stored `iconKey` this build no longer ships reads as "no icon", not as a crash — retiring an icon from `kProjectIconChoices` is safe.
- The grid's Name column sets `cellPadding: EdgeInsets.zero` so the cover can reach the cell's left border and span the full row height; everything else in that cell re-applies `_kNameCellInset` itself.

### The dashboard has two views and exactly one filtered list
- The desktop projects tab draws either the `TrinaGrid` table or `ProjectCardGrid` (`lib/ui/widgets/project_card_grid.dart`, #111). Both are handed the **same** `projectsProvider` output — the toggle in the filter bar chooses how that list is drawn, never what is in it. Never filter, search or re-sort inside a view; that belongs in `projectsProvider` so both views can't disagree.
- `dashboardViewModeProvider` is a device-local preference in the `settings` box, like the theme and the detail-page layout — deliberately not Drive-synced and not backed up.
- `ProjectCardGrid` takes plain values, label strings and callbacks — no `Ref`, no Hive, no `AppLocalizations` — which is what makes it widget-testable. Resolve strings in the page and pass a `ProjectCardLabels`.
- A project with no cover art still needs a visual identity: `projectAccentColor`/`projectInitials` in `lib/utils/project_accent_color.dart` derive one from the project id, so it is identical on every machine with nothing stored. Cover art (`thumbnailPath`) wins over the generated colour, and a user-typed `MusicProject.cardInitials` wins over the derived letters (`projectCardInitials` resolves that order; blank means "go back to derived", never a blank card).
- Every card is the same size regardless of its name: the name block is a fixed two lines tall and the cover above it absorbs the difference. Anything else added to the footer has to keep that property, or one long title makes one card taller than the row.
- The card's launch / open-folder / play icons sit on the cover, not in the footer, for the same reason. The first one follows session mode — bookmark instead of launch — exactly as the grid row and the context menu do.
- Cards are ordered by `sortProjects` (`lib/utils/project_sort.dart`), shared with the mobile list's sort dropdown, driven by the device-local `dashboardCardSortProvider`. This is the *only* thing a view is allowed to do to the shared list.
- The right-click menu on a project lives in `lib/ui/project_context_menu.dart` and is shared by the grid row and the card. Add new entries there — a second copy is how the two views drift apart.

### A grid row's "open full detail page" action uses `Icons.assignment` + `tooltipViewDetails`
- Every `TrinaGrid` actions column that navigates to a dedicated detail page (not an inline edit dialog) uses `Icon(Icons.assignment)` with `tooltip: l10n.tooltipViewDetails`, matching `dashboard_page.dart`'s project rows. Keep new detail-page entry points (grid action icon, row double-tap) consistent with this rather than inventing a new icon/label per page.

---

## Common tasks

### Adding a new DAW
1. Add the file extension (with comment) to `ScannerService.supportedExtensions` in `lib/services/scanner_service.dart`.
2. Map the extension to a display name in `MetadataExtractor` (`lib/services/metadata_extractor.dart`).
3. Optionally add a logo asset and register it in the logo map in `dashboard_page.dart`.
4. Update the supported DAWs table in `README.md`.

### Adding a new UI string
1. Add the key + English value to `lib/l10n/app_en.arb`.
2. Add the same key to every other `app_<locale>.arb` file (use the English value as a placeholder if translation is pending).
3. Run `flutter gen-l10n` — generated code lands in `lib/generated/l10n/`.
4. Reference via `AppLocalizations.of(context)!.yourKey` — never import the generated file directly; it is re-exported from the package.

### Adding a new MusicProject field
1. Add a `@HiveField(N)` with the next available index.
2. Add a default value in the `MusicProjectAdapter.read()` for backwards compatibility with existing boxes.
3. Add the field to `copyWith()`.
4. Decide sync scope (see Non-negotiables above) and update `_serializeProject` / `_deserializeProject` if needed.
5. Update `TestFactories.makeProject()` in `test/helpers/test_factories.dart` to expose the field for tests.

---

## Key file locations

| What | Where |
|------|-------|
| Data models | `lib/models/` |
| Riverpod providers | `lib/providers/providers.dart` |
| Hive repository | `lib/repository/project_repository.dart` |
| File scanner | `lib/services/scanner_service.dart` |
| Metadata extractor (BPM, key, DAW version) | `lib/services/metadata_extractor.dart` |
| Google Drive sync (not available inside Flatpak) | `lib/services/google_drive_sync_service.dart` |
| Local backup/restore (Flatpak's only backup path) | `lib/services/backup_service.dart` |
| Archive a project to a verified zip, and restore it | `lib/services/project_archive_service.dart` |
| Move one project's files, rewriting its stored paths | `lib/services/project_move_service.dart` |
| "Does another project share this folder?" (archive scope + move) | `lib/utils/project_folder_utils.dart` |
| Version stack list (project detail) | `lib/ui/widgets/project_versions_section.dart` |
| Settings hub — single scrollable page, left nav jumps to section | `lib/ui/settings_page.dart` |
| Main dashboard | `lib/ui/dashboard_page.dart` |
| Dashboard card/gallery view | `lib/ui/widgets/project_card_grid.dart` |
| Project right-click menu (grid + cards) | `lib/ui/project_context_menu.dart` |
| Sorting shared by cards + mobile list | `lib/utils/project_sort.dart` |
| Project detail / editor | `lib/ui/project_detail_page.dart` |
| Localization strings (source of truth) | `lib/l10n/app_en.arb` |
| Theme specs, builder and providers | `lib/providers/theme_provider.dart` |
| Theme spec model (`CustomTheme`) | `lib/models/custom_theme.dart` |
| Theme-derived values (grid colors, vivid-accent test) | `lib/utils/theme_derivations.dart` |
| Per-project accent color + icon resolution | `lib/utils/project_visuals.dart` |
| Project cover art tile + grid-row bleed | `lib/ui/widgets/project_cover_avatar.dart` |
| Project appearance editor (cover, color, icon) | `lib/ui/dialogs/project_appearance_dialog.dart` |
| Theme editor / color picker dialogs | `lib/ui/dialogs/theme_editor_dialog.dart`, `lib/ui/dialogs/color_picker_dialog.dart` |
| Theme merge rules shared by backup + Drive sync | `lib/services/custom_theme_merge.dart` |
| Platform helpers | `lib/utils/mobile_utils.dart` |
| Test factories | `test/helpers/test_factories.dart` |
| OAuth client config (not versioned) | `lib/config/oauth_config.dart` |

---

## Codegen commands

```bash
# After changing Hive models with @HiveType / @HiveField
dart run build_runner build --delete-conflicting-outputs

# After adding or editing localization strings
flutter gen-l10n
```
