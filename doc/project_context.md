# Project Context: Bagnon Consolidator

This document tracks the current plan, architectural decisions, and tasks for the Bagnon Consolidator addon.

## Architectural Decisions

1.  **Addon Style**: Developed as a self-contained addon named `Bagnon_Consolidator` located at the root of the repository.
2.  **UI Integration**: Implemented by hook-overriding `Bagnon.Inventory.GetExtraButtons()` at runtime to insert a custom button into the backpack frame.
3.  **Loading Manifest**: Uses `Bagnon_Consolidator.toc` to load `main.xml`, which loads `libs/libItemMove/libItemMove.xml` followed by `main.lua` to respect BagBrother's manifest conventions.
4.  **Guild Bank Safeguard**: Skip items found in multiple guild bank tabs to preserve player categorization; print warning to chat.
5.  **Guild Bank Processing**: Processed tab-by-tab sequentially. This is handled by `LibItemMove-1.0`'s multi-tab runner, which automatically triggers `SetCurrentGuildBankTab` and yields the coroutine until `GUILDBANKBAGSLOTS_CHANGED` is received before proceeding with moves.
6.  **Personal Bank Processing**: Consolidated across all bank bags normally without multi-bag restrictions.
7.  **Coding Conventions**: Tab indentation for Lua scripts, usage of `LibStub('C_Everywhere')` wrapper library, and syntax verification using `luac -p`.
8.  **Keyring Container Exemption**: Excludes the keyring container (`bag == -2` or `KEYRING_CONTAINER`) during inventory scans to prevent client-side silent errors.
9.  **JIT Namespace Compatibility**: Directly invokes JIT-emulated namespace functions like `C.C_Item.GetItemInfo` (instead of the `C.GetItemInfo` table) and falls back to native global `C_Container` table methods when the emulated layer fails.
10. **Library Move Engine**: Fully delegates transaction scheduling, slot pairing, cursor safety check, item split commands, lock check retries, and event-driven transaction verification to `LibItemMove-1.0`.
11. **Guild Bank Tab Remembering**: Remembers the mapping of item IDs to their guild bank tabs in a per-account database (`BagnonConsolidatorDB`) scoped by guild and realm keys. Enables consolidation to empty slots of a remembered tab when that item is not currently present in the guild bank.
12. **Personal Bank Remembering**: Remembers the item IDs that each character has previously stored in their individual bank in a per-account database (`BagnonConsolidatorDB.personalBanks`) scoped by `CharacterName-RealmName`. Enables consolidation to empty bank slots when that item is not currently present in the character's bank but was there in the past.
13. **Personal/Guild Mutual Exclusivity**: Enforces that an item has at most one designated location category. If an item is ever observed in a character's personal bank, its remembered location is immediately cleared from `guildTabs` for all guilds and characters. It is also skipped during guild bank consolidation, printing a warning once per item ID per run.

## Future Plans

1.  **Improve Remembered Mappings Interaction**: Add a slash command (e.g., `/bconsolidator forget <itemID>` or `/bconsolidator reset`) or a simple GUI configuration panel to let users manually clear, reset, or manage the learned guild bank tab and personal bank mappings.
