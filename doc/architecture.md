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
   more than one guild bank tab, or in both personal bank and guild bank, it is
   mapped to **Conflicts (Go Nowhere)** and skipped.
5. **Ignore List Protection**: Items marked on the Ignore list are never
   consolidated and are skipped during snapshot ingestion.
6. **Zero-Stock Retention**: Additive snapshots preserve mappings for
   out-of-stock items until explicitly removed or reset.

---

## 2. File Layout & Loading Manifests

To conform with BagBrother's manifest load order guidelines, the addon loads
scripts via `main.xml`:

```text
bagnon_consolidator/
├── .agents/                 # Workspace configurations and rules
├── .gitignore               # Git ignore patterns
├── .luarc.json              # Lua Language Server configuration
├── .markdownlint.json       # Linter configuration for Markdown files
├── .pkgmeta                 # CurseForge packager configuration
├── .prettierrc              # Prettier formatting options
├── Bagnon_Consolidator.toc  # Set dependencies (Bagnon), loads main.xml
├── LICENSE                  # Software license file
├── README.md                # User guide, installation guidelines, features
├── main.xml                 # XML manifest loading scripts in topological order
├── types.lua                # EmmyLua type definitions and Blizzard stubs
├── core/
│   ├── init.lua             # Lifecycle, ADDON_LOADED event, DB bootstrapping
│   ├── utils.lua            # Identity helpers, item lookups, chat utilities
│   ├── snapshot.lua         # Additive snapshot ingestion engine & reset logic
│   └── engine.lua           # Consolidation queue builder & LibItemMove runner
├── ui/
│   ├── button.lua           # Backpack ConsolidateButton class & hooks
│   ├── viewer.lua           # Mappings Viewer modal window & search filter
│   └── options.lua          # Blizzard Settings & Interface Options panel
├── tests/
│   └── test_consolidator.lua# Standalone mock unit test suite (46 assertions)
├── scripts/
│   ├── dump_mappings.lua    # CLI helper to inspect SavedVariables database
│   └── setup_types.sh       # Type environment setup helper
└── doc/
    ├── project_context.md   # Project tasks, plans, and current state
    └── architecture.md      # Addon design and developer instructions (this file)
```

---

## 3. UI Hooks & Integration (`ui/button.lua`)

The addon hooks into Bagnon's frame instantiation lifecycle at runtime by
overriding the subclass method:

```lua
local origGetExtraButtons = Addon.Inventory.GetExtraButtons
function Addon.Inventory:GetExtraButtons()
    local buttons = origGetExtraButtons(self) or {}
    tinsert(buttons, self:GetWidget('ConsolidateButton'))
    return buttons
end
```

* `self:GetWidget('ConsolidateButton')` automatically looks up the global
  namespace `Addon.ConsolidateButton`, instantiates the button, and caches it
  on the frame.
* **Left-Click**: Starts consolidation to the open bank or guild bank.
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
* **Ignore Filtering**: Any `itemID` in `BagnonConsolidatorDB.ignored` is
  skipped during snapshots.
* **Conflict Detection**:
  * Item on $>1$ guild tab $\rightarrow$ mapped to `conflicts[guildKey]` with
    reason.
  * Item in personal bank AND guild bank $\rightarrow$ mapped to `conflicts`
    and stripped from active destinations.
* **Relocation Detection**: If an item moved completely from Tab $A \rightarrow$
  Tab $B$, its mapping updates cleanly.
* **Zero-Stock Retention**: Items previously mapped but currently at 0 count are
  retained in the database.

---

## 5. Viewer Frame & Auditing (`ui/viewer.lua`)

The standalone Viewer Frame (`BagnonConsolidatorViewerFrame`) provides full
auditing and pruning:

* **Destination Tabs**: `Personal Bank`, `Guild Tabs 1–8` (dynamically
  labeled), `Conflicts`, and `Ignored`.
* **Live Search**: Real-time filtering by item name or ID.
* **Per-Item `[✕]` Actions**:
  * Active Tab: Moves item to `Ignored` (prevents consolidation and
    re-learning).
  * Ignored Tab: Clears item from `Ignored` (allows re-learning on future
    snapshots).
  * Conflicts Tab: Clears the conflict entry.
* **Header Controls**: `Take Snapshot` and `Reset Mappings...` (with
  `StaticPopup` dialog).

---

## 6. Generalized Multi-Stack Consolidation Algorithm (`core/engine.lua`)

To compress partial stacks in the Backpack ($S_S$) and Bank ($S_D$),
`LibItemMove-1.0` executes:

1. **Ascending Sort**: Sort partial stacks in ascending order of size.
2. **Pre-Consolidate Destination**: Merge smallest partial stacks into largest
   partial stacks in the bank to maximize empty slots.
3. **Pre-Consolidate Source**: Merge smallest partial stacks in backpack.
4. **Cross-Container Merge**: Merge remaining partial backpack stack into bank
   partial stack.
5. **Remaining Stack Deposit**: Deposit remaining full/partial stacks to empty
   bank slots.

---

## 7. Database Memory & Saved Mappings

Persisted inside `BagnonConsolidatorDB`:

* **`guildTabs`**: Maps `guildKey` (`GuildName-GuildRealm`) $\rightarrow$
  `itemID` $\rightarrow$ `{ tab, name, tabName }`.
* **`personalBanks`**: Maps `charKey` (`CharacterName-RealmName`) $\rightarrow$
  `itemID` $\rightarrow$ `itemName`.
* **`ignored`**: Set of `itemID` $\rightarrow$ `itemName` blacklisted from
  consolidation and snapshots.
* **`conflicts`**: Maps `key` $\rightarrow$ `itemID` $\rightarrow$ `{ name,
  personal, tabs, reason }`.
* **`enableDebug`**: Boolean flag for verbose debugging logs.
