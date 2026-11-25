# Bagnon Consolidator: Goals & Architecture

This document describes the design, goals, and architectural structure of the
`Bagnon_Consolidator` addon. It serves as a guide for agents or developers
performing maintenance or extending the addon.

---

## 1. Project Goals

The primary goal of `Bagnon_Consolidator` is to provide a single-button
mechanism inside Bagnon's backpack frame to consolidate items from the backpack
into the open bank (personal or guild bank) with the following rules:

1. **Duplicate Detection & Physical Ingestion**: Mappings are established by
   physical layout in the personal bank or guild bank tabs via additive
   snapshots.
2. **Stack Consolidation (Compression)**: Combine partial stacks to minimize
   total container slots used, maximizing the number of full stacks.
3. **Guild Bank Tab Matching**: Automatically switch to the correct tab where
   the item was originally found and deposit it there.
4. **Multi-Tab Safeguard (Guild Bank) & Exclusivity**: If an item is found in
   more than one guild bank tab, it is mapped to `conflicts[guildKey]` and
   skipped. If an item is found in both personal bank and guild bank, the guild
   bank mapping is stripped and recorded under `conflicts[guildKey]`, while the
   personal bank mapping is retained.
5. **Ignore List Protection**: Items marked on the Ignore list are never
   consolidated and are skipped during snapshot ingestion.
6. **Zero-Stock Retention**: Additive snapshots preserve mappings for
   out-of-stock items until explicitly removed or reset.
7. **Multi-Flavor Compatibility**: Supports Retail, Mists of Pandaria Classic,
   Classic Era, and WoW Forever. See `Bagnon_Consolidator.toc` for active
   interface versions.

---

## 2. File Layout & Loading Manifests

To conform with BagBrother's manifest load order guidelines, the addon loads
scripts via `main.xml`:

```text
bagnon_consolidator/
├── .agents/                 # Workspace configurations and rules
├── .github/                 # CI typecheck/release workflows & Dependabot
├── .gitignore               # Git ignore patterns
├── .gitmodules              # Submodule configuration (LibItemMove-1.0)
├── .luarc.json              # Lua Language Server configuration
├── .markdownlint.json       # Markdownlint rule configuration
├── .pkgmeta                 # CurseForge packager configuration
├── .prettierrc              # Prettier formatting configuration
├── Bagnon_Consolidator.toc  # Set dependencies (Bagnon), loads main.xml
├── CHANGELOG.md             # Release notes (CurseForge manual-changelog)
├── LICENSE                  # Software license file
├── README.md                # User guide, installation guidelines, features
├── main.xml                 # XML manifest loading scripts in topological order
├── types.lua                # EmmyLua type definitions and Blizzard stubs
├── libs/
│   ├── AceLocale-3.0/       # Localization library (packaged external)
│   └── libItemMove/         # Asynchronous item movement submodule
├── locales/
│   ├── locales.xml          # Localization manifest
│   ├── enUS.lua             # Default / fallback locale dictionary
│   └── *.lua                # Translated locale dictionaries
├── core/
│   ├── init.lua             # Lifecycle, ADDON_LOADED event, DB bootstrapping
│   ├── utils.lua            # Identity helpers, item lookups, chat utilities
│   ├── snapshot.lua         # Additive snapshot ingestion engine & reset logic
│   └── engine.lua           # Consolidation queue builder & LibItemMove runner
├── ui/
│   ├── button.lua           # Backpack ConsolidateButton class & hooks
│   ├── viewer.lua           # Mappings Viewer window & search filter
│   └── options.lua          # Blizzard Settings & Interface Options panel
├── tests/
│   └── test_consolidator.lua # Standalone mock unit regression test suite
├── scripts/
│   ├── dump_mappings.lua    # CLI helper to inspect SavedVariables database
│   └── setup_types.sh       # Type environment setup helper
└── docs/
    ├── project_context.md   # Project tasks, plans, and current state
    └── architecture.md      # Addon design and developer instructions
```

---

## 3. UI Hooks & Integration (`ui/button.lua`)

The addon hooks into Bagnon's frame instantiation lifecycle at runtime by
overriding the subclass method:

```lua
local origGetExtraButtons = Addon.Inventory.GetExtraButtons
function Addon.Inventory:GetExtraButtons()
    local buttons = origGetExtraButtons and origGetExtraButtons(self) or {}
    tinsert(buttons, self:GetWidget('ConsolidateButton'))
    return buttons
end
```

* `self:GetWidget('ConsolidateButton')` automatically looks up the global
  namespace `Addon.ConsolidateButton`, instantiates the button, and caches it
  on the frame.
* **Left-Click**: Checks `InCombatLockdown()`, requires an open non-cached
  `bank` or `guild` frame, and invokes `Addon.ConsolidateEngine:Start(frame)` to
  start consolidation.
* **Right-Click**: Opens a `MenuUtil` context menu featuring:
  * *Open Mappings Viewer...* (toggles `Addon.Viewer`)
  * *Take Snapshot* (triggers additive container scan)
  * *Reset Mappings...* (prompts confirmation to clear active container
    mappings)
  * *Enable Debug Logs* (toggle)

---

## 4. Additive Ingestion & Snapshot Engine (`core/snapshot.lua`)

The snapshot engine (`Addon.TakeSnapshot`) operates with additive rules:

* **Offline Database Scanning**: Scans guild bank tabs using BagBrother's
  offline cache (`frame:GetBagInfo(tab)`), reading all tabs instantaneously.
* **Character vs. Account/Warband Bank Isolation**: `GetAccountBankBagSet()`
  resolves Account/Warband Bank container IDs via
  `C_Bank.FetchPurchasedBankTabIDs(Enum.BankType.Account)` and
  `Enum.BagIndex.AccountBankTab_*` on modern bank clients so personal bank
  snapshots skip Warband tabs.
* **Guild Tab Name Caching & Guards**: Caches observed tab names in
  `BagnonConsolidatorDB.tabNames` and nil-guards `GetGuildBankTabInfo` calls.
* **Ignore Filtering**: Any `itemID` in `BagnonConsolidatorDB.ignored` is
  skipped during snapshots.
* **Conflict Detection**:
  * Item on > 1 guild tab → mapped to `conflicts[guildKey]` with reason and
    stripped from `guildTabs[guildKey]`.
  * Item in personal bank and guild bank → mapped to `conflicts[guildKey]` and
    stripped from `guildTabs[guildKey]`, while `personalBanks[charKey]` is
    retained.
* **Relocation Detection**: If an item moved completely from Tab A → Tab B, its
  mapping updates cleanly.
* **Zero-Stock Retention**: Items previously mapped but currently at 0 count are
  retained in the database.

---

## 5. Viewer Frame & Auditing (`ui/viewer.lua`)

The standalone Viewer Frame (`BagnonConsolidatorViewerFrame`) is a movable,
non-modal `DIALOG`-strata window registered in `UISpecialFrames` for
`Escape`-key closing, providing full auditing and pruning:

* **Destination Tabs**: `Personal`, `Guild Bank >` dropdown (`MenuUtil`, tabs
  `1..MAX_GUILDBANK_TABS` with custom labels and item counts), `Conflicts`, and
  `Ignored`.
* **Live Search**: Real-time filtering by item name or ID.
* **Per-Item Row Actions**:
  * `Ignore [X]` (Personal/Guild tabs): Moves item to `Ignored` (prevents
    consolidation and re-learning).
  * `Restore` (Ignored tab): Clears item from `Ignored` (allows re-learning on
    future snapshots).
  * `Clear` (Conflicts tab): Clears the conflict entry.
* **Header Controls**: `Take Snapshot` and `Reset Mappings...` (opens
  `StaticPopup` with scope `personal` on the Personal tab, `guild` on the Guild
  tab, or `all` on the Conflicts and Ignored tabs).

---

## 6. Consolidation Engine & `LibItemMove-1.0` Delegation (`core/engine.lua`)

1. **Queue Building & Pre-Filtering (`core/engine.lua`)**:
   * `CanUseCharacterBank()` guard (`C_Bank.CanUseBank`) aborts personal bank
     runs when only a remote Warband bank is accessible.
   * Dynamic keyring exclusion (`GetKeyringContainer()`:
     `Enum.BagIndex.Keyring` → `KEYRING_CONTAINER` → `-2`) prevents scanning
     keyring slots.
   * Skips ignored items (`BagnonConsolidatorDB.ignored`) and active conflicts
     (`BagnonConsolidatorDB.conflicts`).
   * Guild Bank runs verify deposit permissions via nil-guarded
     `GetGuildBankTabInfo`, exclude soulbound items (`IsItemSoulbound()`,
     checking `item.isBound` with `C_Container.GetContainerItemInfo` fallback),
     and build `multiTabQueue`.
   * Personal Bank runs pre-filter items via `IsAllowedInCharacterBank()`
     (`C_Bank.IsItemAllowedInBankType`) and build `moveQueue`.
   * Dispatches to `LibItemMove:Move(queue, context, callback)` and plays
     cross-flavor guarded audio via `PlaySoundSafe()` (`UI_BAG_SORTING_01` →
     `IG_BACKPACK_CLOSE`, `IG_QUEST_CANCEL`).
2. **Execution & Stack Pairing (`LibItemMove-1.0`)**:
   * Scans destination partial stacks (`GetPartialSlots`) and compatible empty
     slots (`GetEmptySlots`, prioritizing specialty bags before general bags).
   * Iterates source slots in container order, pairing into destination partial
     stacks first (tracking remaining room across sequential moves) and then
     empty destination slots.
   * Executes cooperatively in a coroutine with slot-lock checks, cursor
     safety/recovery, transaction verification, and sequential Guild Bank tab
     switching with rate-limit throttling.

---

## 7. Database Memory & Saved Mappings

Persisted inside `BagnonConsolidatorDB`:

* **`guildTabs`**: Maps `guildKey` (`GuildName-GuildRealm`) → `itemID` →
  `{ tab, name, tabName }`.
* **`tabNames`**: Maps `guildKey` → `tabIndex` → `tabName` for offline guild tab
  labels.
* **`personalBanks`**: Maps `charKey` (`CharacterName-RealmName`) → `itemID` →
  `itemName`.
* **`ignored`**: Set of `itemID` → `itemName` blacklisted from consolidation and
  snapshots.
* **`conflicts`**: Maps `guildKey` → `itemID` → `{ name, reason }`.
* **`enableDebug`**: Boolean flag for verbose debugging logs.
