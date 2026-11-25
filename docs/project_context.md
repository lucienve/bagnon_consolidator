# Project Context: Bagnon Consolidator

This document tracks the current plan, architectural decisions, and tasks for
the Bagnon Consolidator addon.

## Architectural Decisions

1. **Addon Style**: Developed as a self-contained addon named
   `Bagnon_Consolidator` located at the root of the repository.
2. **UI Integration**: Implemented by hook-overriding
   `Bagnon.Inventory.GetExtraButtons()` at runtime to insert a custom button
   into the backpack frame.
3. **Loading Manifest**: Uses `Bagnon_Consolidator.toc` to load `main.xml`,
   which loads `libs/libItemMove/libItemMove.xml`,
   `libs/AceLocale-3.0/AceLocale-3.0.xml`, and `locales/locales.xml`, followed
   by modular scripts in `core/` (`init.lua`, `utils.lua`, `snapshot.lua`,
   `engine.lua`) and `ui/` (`button.lua`, `viewer.lua`, `options.lua`) in
   topological dependency order.
4. **Guild Bank Safeguard**: Skip items found in multiple guild bank tabs to
   preserve player categorization; flag under Conflicts.
5. **Guild Bank Processing**: Processed tab-by-tab sequentially. Handled by
   `LibItemMove-1.0`'s multi-tab runner, which triggers
   `SetCurrentGuildBankTab` and awaits `GUILDBANKBAGSLOTS_CHANGED`.
6. **Personal Bank Processing**: Consolidated across all bank bags normally
   without multi-bag restrictions.
7. **Coding Conventions**: Tab indentation for Lua scripts, usage of
   `LibStub('C_Everywhere')` wrapper library, and syntax verification using
   `luac -p`.
8. **Keyring Container Exemption**: Excludes the dynamically resolved keyring
   container via `GetKeyringContainer()` (`Enum.BagIndex.Keyring` →
   `KEYRING_CONTAINER` → `-2`) during inventory scans to avoid scanning keyring
   slots and prevent colliding with `-2` (`Characterbanktab`) on modern clients.
9. **Cross-Flavor Item API & Fallback Usage**: Uses `LibStub('C_Everywhere')`
   (`C.C_Item.GetItemInfo`, `C.C_Item.GetItemIconByID`) for item lookups and
   icons across flavors, delegating container scanning/movement to
   `LibItemMove-1.0` and falling back to `C_Container.GetContainerItemInfo` only
   for `item.isBound` in `IsItemSoulbound()` when `Bagnon` omits it.
10. **Library Move Engine**: Fully delegates transaction scheduling, slot
    pairing, cursor safety check, item split commands, lock check retries, and
    event-driven transaction verification to `LibItemMove-1.0`.
11. **Additive Snapshot Ingestion**: `Addon.TakeSnapshot()` performs
    non-destructive scans of the active container, adding newly discovered
    items and updating relocations while preserving out-of-stock items.
12. **Ignore List Protection**: Mappings deleted via `Ignore [X]` in the active
    view are moved to `BagnonConsolidatorDB.ignored`, preventing both future
    consolidation and re-ingestion during subsequent snapshots.
13. **Strict Personal/Guild Mutual Exclusivity**: If an item is present across
    multiple guild tabs, it is mapped to `conflicts[guildKey]` and stripped from
    `guildTabs[guildKey]`. If an item is present in both personal bank and guild
    bank, the guild bank mapping is stripped into `conflicts[guildKey]` while the
    personal bank mapping is retained.
14. **Management Viewer Frame (`ui/viewer.lua`)**: Provides a standalone movable
    window registered in `UISpecialFrames` (for `Escape`-key dismissal) to
    inspect destinations (`Personal`, `Guild Bank >` dropdown for
    `1..MAX_GUILDBANK_TABS`, `Conflicts`, `Ignored`), filter items in real time,
    and manage entries via `Ignore [X]`, `Restore`, and `Clear` buttons.
15. **Context Menu Shortcuts**: Right-clicking the backpack Consolidate button
    brings up a `MenuUtil` context menu offering *Open Mappings Viewer...*,
    *Take Snapshot*, *Reset Mappings...*, and the *Enable Debug Logs* toggle.
16. **Settings Options Panel**: Registered under Blizzard's Settings interface
    with a button to toggle the viewer frame and toggle debug logs.
17. **Precision Transaction Verification**: Utilizes exact expected destination
    slot quantities and verifies that the cursor is empty before declaring a
    move transaction complete.
18. **Lag Tolerance**: 5-second timeout thresholds for transaction verification
    and lock checks to handle synchronization lag during peak hours.
19. **Localization Architecture**: Utilizes `AceLocale-3.0` embedded in
    `libs/AceLocale-3.0/` with base dictionary `locales/enUS.lua` (`isDefault =
    true`) and complete localized dictionaries in `locales/` (`deDE`, `frFR`,
    `esES`, `esMX`, `ruRU`, `zhCN`, `zhTW`, `koKR`, `ptBR`, `itIT`).
20. **CurseForge Packaging & CI/CD**: Uses `BigWigsMods/packager@v2` triggered
    on Git release tags (e.g. `vX.Y.Z`) via `.github/workflows/release.yml`.
    Dynamic version stamping is enabled with `## Version: @project-version@`,
    CurseForge project mapping via `## X-Curse-Project-ID: 1656218`, and
    packaging dependency management via `.pkgmeta`. Releases use
    `manual-changelog` pointing to `CHANGELOG.md` for player-friendly release
    notes. Releases are gated behind a presubmit verification job
    (`setup_types.sh`, `lua-typecheck-action`, `luac -p`, and unit tests).
21. **Mock Unit Testing Harness**: Implemented in
    [`tests/test_consolidator.lua`](../tests/test_consolidator.lua) with a pure
    Lua mock environment for Blizzard FrameXML, `C_Everywhere`, `LibItemMove`,
    `AceLocale-3.0`, and `Bagnon` objects to execute regression testing across
    snapshots, conflict detection, queue builders, and viewer operations.
22. **Three-Pillar Validation & WoW Standards**:
    Adheres strictly to the Three-Pillar validation gate:
    - *Pillar 1 (LuaLS)*: Type checking via `.luarc.json` and `types.lua`,
      eliminating dummy table clobbering.
    - *Pillar 2 (wow_lua_lint)*: Zero-warning domain and taint linting across
      Retail, Mists of Pandaria Classic, Classic Era, and WoW Forever flavors.
    - *Pillar 3 (Manifest & Schema Integrity)*: Strict `wow_toc_validate` and
      `wow_xml_validate` compliance with schema namespace in `main.xml`.
    - *Asset Resolution*: Uses numeric FileDataIDs (`135769`, `134400`) for
      direct CASC texture lookups with canonical inline comments.
    - *Docs Structure*: Standardized documentation in `docs/`.
23. **Multi-Client & WoW Forever Support**: Supports Retail, Mists of Pandaria
    Classic, Classic Era, and WoW Forever via packager directives
    (`Interface-Mainline`, `Interface-Mists`, `Interface-Classic`,
    `Interface-Forever`, generating `_Camelot.toc` for WoW Forever). See
    `Bagnon_Consolidator.toc` as the single source of truth for active interface
    numbers.
24. **Cross-Flavor Icon Resolution & Standard Templates**: Uses
    `C.C_Item.GetItemIconByID` with numeric FileDataID `134400` fallback to
    safely resolve uncached item icons across modern and Classic clients, and
    inherits `UICheckButtonTemplate` for settings checkboxes.
25. **Character vs. Account/Warband Bank Isolation**: `GetAccountBankBagSet()`
    excludes Account/Warband Bank tabs from personal bank snapshots, and
    `CanUseCharacterBank()` guards personal bank consolidation against remote
    Warband-only bank sessions.
26. **Eligibility Pre-Filtering**: Personal Bank consolidation filters out
    disallowed items via `C_Bank.IsItemAllowedInBankType`, and Guild Bank
    consolidation filters out soulbound items via `IsItemSoulbound()` and
    nil-guards `GetGuildBankTabInfo`.
27. **Cross-Flavor `SOUNDKIT` Playback Guards**: `PlaySoundSafe()` validates
    `PlaySound` and numeric `SOUNDKIT` constants across all flavors
    (`UI_BAG_SORTING_01` with `IG_BACKPACK_CLOSE` fallback on completion,
    `IG_QUEST_CANCEL` on abort/empty).
28. **Viewer Escape Close & Scoped Reset**: `BagnonConsolidatorViewerFrame`
    registers in `UISpecialFrames` for `Escape`-key dismissal, and `Reset
    Mappings...` maps viewer tabs (`personal`, `guild`, `conflicts`/`ignored` →
    `all`) to valid reset scopes.

## Completed Tasks

- Implemented the Snapshot & Viewer Frame architecture with additive merge
  engine.
- Added `BagnonConsolidatorViewer` window with destination tabs, search
  filtering, and per-item removal/ignore controls.
- Integrated right-click context menu options (*Take Snapshot*, *Reset
  Mappings...*, *Open Mappings Viewer...*, *Enable Debug Logs*).
- Added confirmation dialog (`StaticPopup`) for resetting mappings.
- Updated CLI helper `scripts/dump_mappings.lua` to display ignored items and
  conflicts.
- Integrated `AceLocale-3.0` localization framework across all UI text,
  dialogs, tooltips, and notification messages.
- Configured automated CurseForge packaging pipeline with `.pkgmeta`, TOC
  metadata (`X-Curse-Project-ID: 1656218`), and gated release workflow
  (`.github/workflows/release.yml`).
- Implemented Phase 1: Test-First Unit Testing Suite
  ([`tests/test_consolidator.lua`](../tests/test_consolidator.lua)) establishing
  a baseline regression test suite against current business logic.
- Implemented Phase 2: Modular Restructuring into `core/` and `ui/` packages
  with `git mv` history preservation and updated `main.xml` load order.
- Implemented Phase 3: Manifests, CI Integration & Documentation updates
  (added unit testing and syntax checks to GitHub Actions workflow, updated
  `.pkgmeta` ignore rules, and refreshed architectural documentation).
- Synchronized addon with updated WoW addon development rules, Three-Pillar
  validation gates (`wow_xml_validate`, `wow_toc_validate`, `wow_lua_lint`,
  `lua-language-server`), type definitions in `types.lua`, numeric FileDataID
  texture resolution in `ui/button.lua`, and migrated `doc/` to `docs/`.
- Updated `Bagnon_Consolidator.toc` with missing packager flavor directive
  (`Interface-Mists`), pruned retired expansions (Cataclysm, Wrath, BCC), and
  converted `IconTexture` to numeric FileDataID `135738`.
- Updated `libs/libItemMove` submodule reference to `2813b54` containing modern
  Retail container resolution enhancements and cleanups.
- Fixed consolidate button and addon icon texture FileDataID from `135738`
  (`spell_arcane_manatap`) to `135769` (`spell_chargepositive`).
- Updated `Bagnon_Consolidator.toc` and `libs/libItemMove` submodule (`e5390f8`)
  for WoW Forever and bumped Retail interface metadata.
- Synchronized addon with Mists of Pandaria Classic and current development
  rules: updated icon resolution to `C.C_Item.GetItemIconByID`, migrated options
  CheckButton to `UICheckButtonTemplate`, typed `MenuUtil` and `Settings` in
  `types.lua`, added typed parameters to `core/init.lua`, expanded `luac -p`
  coverage in CI, and updated `.agents/` maintenance directives.
- Prepared v1.1.0 minor release notes in `CHANGELOG.md`.
- Updated `libs/libItemMove` submodule to `41d3be8`, resolving runtime taint
  from `core/types.lua` (Bagnon Consolidator `#7` / `libItemMove#4`) and WoW
  Forever 9-tab bank/warbank container IDs (Bagnon Consolidator `#8` /
  `libItemMove#2`), plus virtual bank tab family safety (`libItemMove#3`),
  Mists warbank/guildbank guards, Reagent Bag family matching, negative
  item-link IDs, sequential partial-stack accumulation, and `Pickup` for
  full-stack/unstackable moves.
- Pre-filtered bank-disallowed items in `core/engine.lua` via
  `C_Bank.IsItemAllowedInBankType` (PR `#14`).
- Isolated Character Bank tabs from Account/Warband Bank tabs in
  `core/snapshot.lua` and added `C_Bank.CanUseBank` guard in `core/engine.lua`
  (PR `#15`).
- Added cross-flavor `SOUNDKIT` playback guards and replaced raw sound ID `847`
  with `IG_QUEST_CANCEL` in `core/engine.lua` (PR `#16`).
- Resolved keyring container dynamically from `Enum.BagIndex.Keyring` in
  `core/engine.lua` (PR `#17`).
- Excluded soulbound items from Guild Bank consolidation queues and nil-guarded
  `GetGuildBankTabInfo` in `core/engine.lua` and `core/snapshot.lua` (PR `#18`).
- Fixed `Reset Mappings...` scope mapping for `Conflicts` and `Ignored` tabs in
  `ui/viewer.lua` (PR `#19`).
- Registered `BagnonConsolidatorViewerFrame` in `UISpecialFrames` for `Escape`
  close support in `ui/viewer.lua` (PR `#20`).
- Audited and updated project documentation and code comments for accuracy.
- Prepared v1.2.0 minor release notes in `CHANGELOG.md`.

## Release Workflow Guide

To publish a new version to CurseForge:

1. Ensure all changes are committed on `main`.
2. Create and push a semver Git tag:

   ```bash
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```

3. The `.github/workflows/release.yml` workflow will automatically run
   presubmit verification (type checking, unit tests, and syntax validation)
   and, upon passing, package and deploy the release directly to CurseForge.
