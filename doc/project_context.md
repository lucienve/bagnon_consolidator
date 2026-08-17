# Project Context: Bagnon Consolidator

This document tracks the current plan, architectural decisions, and tasks for the Bagnon Consolidator addon.

## Architectural Decisions

1.  **Addon Style**: Developed as a self-contained addon named `Bagnon_Consolidator` located at the root of the repository.
2.  **UI Integration**: Implemented by hook-overriding `Bagnon.Inventory.GetExtraButtons()` at runtime to insert a custom button into the backpack frame.
3.  **Loading Manifest**: Uses `Bagnon_Consolidator.toc` to load `main.xml`, which loads `libs/libItemMove/libItemMove.xml`, followed by `main.lua` and `ui.lua` to respect BagBrother's manifest conventions.
4.  **Guild Bank Safeguard**: Skip items found in multiple guild bank tabs to preserve player categorization; flag under Conflicts.
5.  **Guild Bank Processing**: Processed tab-by-tab sequentially. Handled by `LibItemMove-1.0`'s multi-tab runner, which triggers `SetCurrentGuildBankTab` and awaits `GUILDBANKBAGSLOTS_CHANGED`.
6.  **Personal Bank Processing**: Consolidated across all bank bags normally without multi-bag restrictions.
7.  **Coding Conventions**: Tab indentation for Lua scripts, usage of `LibStub('C_Everywhere')` wrapper library, and syntax verification using `luac -p`.
8.  **Keyring Container Exemption**: Excludes the keyring container (`bag == -2` or `KEYRING_CONTAINER`) during inventory scans to prevent client-side silent errors.
9.  **JIT Namespace Compatibility**: Directly invokes JIT-emulated namespace functions like `C.C_Item.GetItemInfo` and falls back to native global `C_Container` table methods when the emulated layer fails.
10. **Library Move Engine**: Fully delegates transaction scheduling, slot pairing, cursor safety check, item split commands, lock check retries, and event-driven transaction verification to `LibItemMove-1.0`.
11. **Additive Snapshot Ingestion**: `Addon.TakeSnapshot()` performs non-destructive scans of the active container, adding newly discovered items and updating relocations while preserving out-of-stock items.
12. **Ignore List Protection**: Mappings deleted via `[✕]` in the active view are moved to `BagnonConsolidatorDB.ignored`, preventing both future consolidation and re-ingestion during subsequent snapshots.
13. **Strict Personal/Guild Mutual Exclusivity**: If an item is present in both personal bank and guild bank (or across multiple guild tabs), it is mapped to `conflicts` (Go Nowhere) and skipped during consolidation.
14. **Management Viewer Frame (`ui.lua`)**: Provides a standalone GUI modal to inspect destinations (`Personal`, `Guild Tabs 1–8`, `Conflicts`, `Ignored`), filter items in real time, and prune entries via per-item `[✕]` buttons.
15. **Context Menu Shortcuts**: Right-clicking the backpack Consolidate button brings up a `MenuUtil` context menu offering *Open Mappings Viewer...*, *Take Snapshot*, *Reset Mappings...*, and the *Enable Debug Logs* toggle.
16. **Settings Options Panel**: Registered under Blizzard's Settings interface with a button to toggle the viewer frame and toggle debug logs.
17. **Precision Transaction Verification**: Utilizes exact expected destination slot quantities and verifies that the cursor is empty before declaring a move transaction complete.
18. **Lag Tolerance**: 5-second timeout thresholds for transaction verification and lock checks to handle synchronization lag during peak hours.
19. **Localization Architecture**: Utilizes `AceLocale-3.0` embedded in `libs/AceLocale-3.0/` with base dictionary `locales/enUS.lua` (`isDefault = true`) and modular skeletons in `locales/` (`deDE`, `frFR`, `esES`, `esMX`, `ruRU`, `zhCN`, `zhTW`, `koKR`, `ptBR`, `itIT`).

## Completed Tasks

*   Implemented the Snapshot & Viewer Frame architecture with additive merge engine.
*   Added `BagnonConsolidatorViewer` modal window with destination tabs, search filtering, and per-item removal/ignore controls.
*   Integrated right-click context menu options (*Take Snapshot*, *Reset Mappings...*, *Open Mappings Viewer...*, *Enable Debug Logs*).
*   Added confirmation dialog (`StaticPopup`) for resetting mappings.
*   Updated CLI helper `scripts/dump_mappings.lua` to display ignored items and conflicts.
*   Integrated `AceLocale-3.0` localization framework across all UI text, dialogs, tooltips, and notification messages.
