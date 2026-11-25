# Bagnon Consolidator Release Notes

## v1.2.1

### Improvements

* **Retail Interface Update:** Updated Retail interface metadata to `120105`
  (Midnight 12.1.5).
* **Submodule Update:** Updated embedded `LibItemMove-1.0` submodule to
  `f54ac8e`, removing unused symbols, shadowed context methods, and unreachable
  guards.

## v1.2.0

### Bugfixes

* **Character & Warband Bank Isolation:** Isolated Character Bank tabs from
  Account/Warband Bank tabs during personal bank snapshots and added a
  Character Bank availability check (`C_Bank.CanUseBank`) so remote
  Warband-only bank access does not trigger failed deposits.
* **Personal Bank Eligibility Filtering:** Pre-filters personal bank
  consolidation queues via `C_Bank.IsItemAllowedInBankType` so bank-disallowed
  items are skipped cleanly.
* **Guild Bank Soulbound Filtering & Guards:** Excludes soulbound items from
  Guild Bank consolidation queues and guards `GetGuildBankTabInfo` calls when
  guild bank APIs are unavailable.
* **Cross-Flavor Keyring Resolution:** Dynamically resolves the keyring
  container from `Enum.BagIndex.Keyring` (falling back to `KEYRING_CONTAINER`
  and `-2`), avoiding collisions with modern bank container indices.
* **Safe Audio Playback:** Guards all `SOUNDKIT` playback across client flavors
  and replaces raw sound ID `847` with `SOUNDKIT.IG_QUEST_CANCEL` (with
  `IG_BACKPACK_CLOSE` fallback on completion).
* **Mappings Viewer Reset Scope:** Fixed `Reset Mappings...` on the Conflicts
  and Ignored tabs to pass the valid `"all"` reset scope.
* **Mappings Viewer Escape Close:** Registered `BagnonConsolidatorViewerFrame`
  in `UISpecialFrames` so pressing `Escape` closes the viewer cleanly.

### Improvements

* **Submodule Update:** Synced embedded `LibItemMove-1.0` submodule to
  `b08f894`, resolving runtime taint from meta type files, WoW Forever 9-tab
  bank/warbank container resolution, virtual bank tab family safety, Mists
  warbank/guildbank guards, Reagent Bag family matching, negative item-link
  IDs, sequential partial-stack accumulation, and full-stack/unstackable pickup
  handling.
* **Documentation & Testing:** Expanded the mock unit test suite to 256
  assertions covering cross-flavor safeguards and updated player and developer
  documentation for accuracy.

## v1.1.0

### Improvements
* **Mists of Pandaria Classic & Icon Modernization:** Modernized item icon
  resolution to use `C.C_Item.GetItemIconByID` with numeric FileDataID `134400`
  fallback across all clients, eliminating invalid item ID queries in modern
  Classic and Retail.
* **Settings Checkbutton Modernization:** Migrated options debug checkbox
  from the deprecated `InterfaceOptionsCheckButtonTemplate` to
  `UICheckButtonTemplate` with cross-flavor text label resolution.
* **Submodule Update:** Updated LibItemMove-1.0 submodule to `feaca76`, adding
  container hyperlink normalization and hardened multi-client container
  resolution.
* **Type Annotations & CI Quality Gates:** Added EmmyLua typing for MenuUtil,
  Settings, and loader frame event handlers, and expanded CI `luac` syntax
  checks across all localization and script files.

## v1.0.3

### Features
* **WoW Forever Support:** Added client compatibility and TOC packaging
  directives for WoW Forever (Camelot, interface 16001).
* **Modern Expansion Sync:** Updated Retail interface version to 120100
  (Midnight 12.1).
* **Library Update:** Updated LibItemMove-1.0 submodule to e5390f8 for WoW
  Forever support.

## v1.0.2

### Bugfixes
* **Icon Resolution:** Corrected consolidate button icon FileDataID from Mana
  Tap (`135738`) to Charge Positive (`135769`).

## v1.0.1

### Improvements
* **Library Update:** Updated LibItemMove-1.0 submodule with modernized
  container resolution for Retail 11.0/12.0 and retired client cleanups.

## v1.0.0

### Features
* **Automatic Item Consolidation:** Consolidates matching item stacks from your
  backpack into personal and guild banks with a single click.
* **Smart Memory & Snapshots:** Remembers personal bank storage history per
  character and tracks guild bank tab mappings.
* **Conflict & Overlap Protection:** Prevents accidental movement when items
  exist across multiple guild tabs or both personal and guild banks.
* **Mappings Viewer:** In-game UI frame to search, inspect, and manage
  remembered item destinations and ignored items.
* **Multi-Language Support:** Fully localized for English, German, French,
  Spanish, Russian, Chinese, Korean, Portuguese, and Italian.
* **Multi-Expansion Compatibility:** Supports Retail, Mists of Pandaria
  Classic, and Classic Era.
