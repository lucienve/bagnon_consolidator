# Bagnon Consolidator: Goals & Architecture

This document describes the design, goals, and architectural structure of the `Bagnon_Consolidator` addon. It serves as a guide for agents or developers performing maintenance or extending the addon.

---

## 1. Project Goals

The primary goal of `Bagnon_Consolidator` is to provide a single-button mechanism inside Bagnon's backpack frame to consolidate items from the backpack into the open bank (personal or guild bank) with the following rules:

1.  **Duplicate Detection**: Only move items from the backpack if at least one stack of that item already exists in the bank (personal) or on a single tab (guild).
2.  **Stack Consolidation (Compression)**: Combine partial stacks to minimize total container slots used, maximizing the number of full stacks.
3.  **Guild Bank Tab Matching**: Automatically switch to the correct tab where the item was originally found and deposit it there.
4.  **Multi-Tab Safeguard (Guild Bank)**: If an item is found in more than one guild bank tab, **do not move it**. Print a warning to the player's chat frame. This prevents messing up manual tab organization.
5.  **Personal Bank Bag Exemption**: Personal bank bags are consolidated in Bagnon's UI anyway, so it is fine for duplicates to exist in different bags; they will be merged normally.

---

## 2. File Layout & Loading Manifests

To conform with BagBrother's manifest load order guidelines, the addon avoids loading Lua scripts directly in the `.toc` file:

```text
bagnon_consolidator/
├── .agents/                 # Workspace configurations and rules
├── .gitignore               # Git ignore patterns
├── .markdownlint.json       # Linter configuration for Markdown files
├── .prettierrc              # Prettier formatting options
├── Bagnon_Consolidator.toc  # Set dependencies (Bagnon), Author (LVE), loads main.xml
├── LICENSE                  # Software license file
├── README.md                # User guide, installation guidelines, and features
├── main.xml                 # XML manifest loading Lua scripts via <Script> tag
├── main.lua                 # Core logic, class definitions, and event engine
└── doc/
    ├── project_context.md   # Project tasks, plans, and current state
    └── architecture.md      # Addon design and developer instructions (this file)
```

---

## 3. UI Hooks & Integration

The addon hooks into Bagnon's frame instantiation lifecycle at runtime by overriding the subclass method:

```lua
local origGetExtraButtons = Addon.Inventory.GetExtraButtons
function Addon.Inventory:GetExtraButtons()
    local buttons = origGetExtraButtons(self) or {}
    tinsert(buttons, self:GetWidget('ConsolidateButton'))
    return buttons
end
```

*   `self:GetWidget('ConsolidateButton')` automatically looks up the global namespace `Addon.ConsolidateButton` (which we register using `Addon.Tipped:NewClass`), instantiates the button using the XML template `BagnonButtonTemplate`, and caches it on the frame.
*   The button displays a custom plus-sign icon (`Interface/Icons/Spell_ChargePositive`) and triggers the engine upon `OnClick()`.

---

## 4. Offline Database Scanning

The WoW API only permits querying and moving items on the *active* guild bank tab (`GetCurrentGuildBankTab()`). To determine which tab an item is in (and check if it exists in multiple tabs) without triggering multiple tab switches, the addon queries the **offline database cache** managed by BagBrother:

*   `frame:GetBagInfo(tab)`: Accesses the cached data of the guild tab.
*   `bagInfo.items`: Contains a dictionary of slot indexes to item data strings.
*   **Item Parsing**: Standard cached items are stored as `itemID:enchantID:...;stackCount`. The addon parses this string using:
    ```lua
    local values = strsplit(';', data)
    local id = tonumber(values:match('^(%d+)'))
    ```
    This avoids calling slow WoW APIs and computes tab locations in a single frame.

---

## 5. Generalized Multi-Stack Consolidation Algorithm

To compress any combination of partial stacks in the Backpack ($S_S$) and Bank ($S_D$), the algorithm performs the following simulation:

1.  **Ascending Sort**: Sort both $S_S$ and $S_D$ in ascending order of stack size (e.g. 2, 5, 10, 15).
2.  **Pre-Consolidate Bank**: Merge the smallest partial stacks in the bank into the largest partial stacks until there is at most **one** partial stack of that item left in the bank. This frees up maximum empty bank slots.
3.  **Pre-Consolidate Backpack**: Do the same for the backpack.
4.  **Cross-Container Merge**: Merge the remaining partial stack in the backpack into the bank's partial stack.
5.  **Remaining Stack Deposit**: Move any remaining full or partial stacks in the backpack to empty bank slots.

*Note: All operations are simulated locally to generate the sequence of required moves before the queue is started.*

---

## 6. Asynchronous Event-Driven Queue Runner

Because item moves in WoW are throttled and make slots temporarily locked, the engine processes tasks sequentially:

*   **Move Task**: Swaps or merges items using `PickupItem(from)` and `PickupItem(to)`.
*   **Tab Switch Task**: Calls `SetCurrentGuildBankTab(tab)`.
*   **Synchronization Handler**: After executing a task, the queue yields and waits for event notification before calling `ProcessNext()`:
    *   `BAG_UPDATE_DELAYED` (Personal Bank)
    *   `GUILDBANKBAGSLOTS_CHANGED` (Guild Bank)
*   **Timeout Safety**: To prevent UI lockup if a packet is lost or a move fails silently, `Queue:WaitForEvent` uses `C_Timer.After(1.5, trigger)` to automatically resume queue processing after a 1.5-second timeout.

---

## 7. Database Memory & Saved Mappings

To enable consolidation of items when they are not currently present in the target container, the addon persists mapping data inside `BagnonConsolidatorDB`:

*   **Guild Bank Tab Memories (`guildTabs`)**: Maps `guildKey` (computed as `GuildName-GuildRealm`) to a lookup table of `itemID` -> `{ tab, name, tabName }`. Items are added when they are observed on a single guild bank tab and removed if they are seen on multiple tabs (to preserve player categorization).
*   **Personal Bank Memories (`personalBanks`)**: Maps `characterKey` (computed as `CharacterName-RealmName`) to a lookup table of `itemID` -> `true`. Items are recorded here when they are observed in a character's personal bank bags during a consolidation scan, and are used to authorize consolidation of that item even if the personal bank has 0 copies left of it.
