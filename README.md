# Bagnon Consolidator

**Bagnon Consolidator** is a lightweight companion addon for **Bagnon** that
automatically deposits and stacks items from your bags into your personal bank
or guild bank based on how your bank is already organized.

---

## Features

- **Seamless Bagnon Integration**: Adds a **Consolidate to Bank** (`+`) button
  to the top-right header of your Bagnon inventory frame.
- **One-Click Snapshots**: Learns where your items belong directly from how
  your personal bank or guild bank tabs are already organized—no manual setup
  required.
- **Remembers Out-of-Stock Items**: Keeps track of an item's bank or guild tab
  even when your bank temporarily runs out of it.
- **Smart Stack Filling**: Tops off existing partial stacks in your personal
  bank or guild bank before using empty slots, prioritizing specialty bags
  (herb, mining, reagent, etc.).
- **Automatic Guild Bank Tab Matching**: Switches to the right guild bank tab
  for each item and deposits it there.
- **Conflict Protection**: Skips items stored across multiple guild bank tabs.
  If an item is kept in both your personal bank and guild bank, your personal
  bank takes priority and guild bank deposits skip it.
- **Warband Bank Safe**: Personal bank snapshots and deposits only touch your
  character's bank tabs, leaving your Warband Bank untouched.
- **Smart Deposit Safeguards**: Automatically skips soulbound items for guild
  bank deposits and skips items that cannot be placed in your personal bank.
- **Ignore List**: Keep specific items (like raid consumables or tools) in your
  bags so they are never deposited or re-learned on future snapshots.
- **In-Game Mappings Viewer**: Search, review, and manage your saved
  destinations, conflicts, and ignored items from anywhere in the world.

---

## Installation

### Prerequisites

- **Bagnon** must be installed and active.

### Manual Installation

1. Download the latest packaged `Bagnon_Consolidator` release (from CurseForge
   or GitHub Releases).
2. Extract the `Bagnon_Consolidator` folder into your World of Warcraft addons
   directory for your game version:
   - **Retail**: `_retail_/Interface/AddOns/Bagnon_Consolidator`
   - **WoW Forever**: `_forever_/Interface/AddOns/Bagnon_Consolidator`
   - **Classic Era (Vanilla)**:
     `_classic_era_/Interface/AddOns/Bagnon_Consolidator`
   - **Progression Classic (e.g., Mists of Pandaria Classic)**:
     `_classic_/Interface/AddOns/Bagnon_Consolidator`
3. Launch the game and make sure **Bagnon Consolidator** is enabled in your
   AddOns list at the character selection screen.

---

## How to Use

### 1. Initial Setup (Snapshot)

1. Open your **Bank** or **Guild Bank** with your items sorted into their
   desired bags or tabs.
2. Right-click the plus-sign (`+`) button on your main Bagnon inventory frame
   and click **Take Snapshot** (or click **Take Snapshot** inside the Mappings
   Viewer).
3. The addon scans your bank and remembers where each item belongs.

### 2. Consolidating Items

1. Whenever your bank or guild bank is open, **left-click** the plus-sign (`+`)
   button labeled **Consolidate to Bank** on your backpack frame.
2. The addon scans your bags and deposits matching items into their remembered
   bank bags or guild tabs.

### 3. Managing Mappings & Ignore List

1. **Right-click** the plus-sign (`+`) button and select **Open Mappings
   Viewer...** (or go to `Game Menu` → `Options` → `AddOns` → `Bagnon
   Consolidator`). Press `Escape` at any time to close the viewer.
2. Browse your saved items across **Personal**, **Guild Bank >**,
   **Conflicts**, and **Ignored**.
3. Click `Ignore [X]` next to any item you want to keep in your bags, `Clear` in
   the Conflicts tab to remove a conflict entry, or `Restore` in the Ignored tab
   to let an item be re-learned on future snapshots.
