# Project Context: Bagnon Consolidator

This document tracks the current plan, architectural decisions, and tasks for the Bagnon Consolidator addon.

## Architectural Decisions

1.  **Addon Style**: Developed as a self-contained addon named `Bagnon_Consolidator` located at the root of the repository.
2.  **UI Integration**: Implemented by hook-overriding `Bagnon.Inventory.GetExtraButtons()` at runtime to insert a custom button into the backpack frame.
3.  **Loading Manifest**: Uses `Bagnon_Consolidator.toc` to load `main.xml`, which then loads `main.lua` via `<Script file="main.lua"/>` to respect BagBrother's manifest conventions.
4.  **Guild Bank Safeguard**: Skip items found in multiple guild bank tabs to preserve player categorization; print warning to chat.
11. **Guild Bank Processing**: Processed tab-by-tab asynchronously, waiting for `GUILDBANKBAGSLOTS_CHANGED` between tab switches.
12. **Personal Bank Processing**: Consolidated across all bank bags normally without multi-bag restrictions.
13. **Coding Conventions**: Tab indentation for Lua scripts, usage of `LibStub('C_Everywhere')` wrapper library, and syntax verification using `luac -p`.
14. **Keyring Container Exemption**: Excludes the keyring container (`bag == -2` or `KEYRING_CONTAINER`) during inventory scans to prevent client-side silent errors.
15. **JIT Namespace Compatibility**: Directly invokes JIT-emulated namespace functions like `C.C_Item.GetItemInfo` (instead of the `C.GetItemInfo` table) and falls back to native global `C_Container` table methods when the emulated layer fails.
16. **Guild Bank API Dispatcher**: Dispatches item moves using `PickupContainerItem` (for backpack/inventory container bags) and `PickupGuildBankItem` (for guild bank tabs) with a dot `.` syntax, since these are raw Blizzard API bindings rather than OOP methods.
17. **Self-Healing Queue Verification**: Verifies completed move tasks by tracking expected item count and querying live slot states using `frame:GetItemInfo` (bypassing stale cache layers), retrying failures automatically.
18. **Dynamic Queue Events**: Automatically routes events and delays based on the specific move task containers (e.g., waiting for `BAG_UPDATE_DELAYED` for backpack-only moves) rather than the active UI window type.
19. **Remainder Recovery**: Invokes `ClearCursor()` before every move operation to automatically return any leftover stack items from partial merges to their origin slots.
20. **Guild Bank Tab Remembering**: Remembers the mapping of item IDs to their guild bank tabs in a per-account database (`BagnonConsolidatorDB`) scoped by guild and realm keys. Enables consolidation to empty slots of a remembered tab when that item is not currently present in the guild bank.

## Future Plans

1.  **Improve Remembered Mappings Interaction**: Add a slash command (e.g., `/bconsolidator forget <itemID>` or `/bconsolidator reset`) or a simple GUI configuration panel to let users manually clear, reset, or manage the learned guild bank tab mappings.
