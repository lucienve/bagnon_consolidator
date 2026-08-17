# Bagnon Consolidator

**Bagnon Consolidator** is a lightweight companion addon for **Bagnon** that helps you automatically clean up, consolidate, and deposit item stacks from your bags into your personal bank or guild bank based on your physical bank organization.

---

## Features

- **Seamless Bagnon Integration**: Adds a clean **Consolidate to Bank** (`+`) button to the top-right header of your inventory bag frame.
- **Physical Ingestion & Snapshots**: Learns item destinations directly from the physical layout of your bank or guild bank tabs with a single snapshot click—no tedious manual data entry.
- **Zero-Stock Retention**: Additive snapshots remember an item's designated bank tab even when it is temporarily out of stock (0 in bank).
- **Stack Compression**: Merges partial item stacks in both your bank and inventory to maximize empty space and keep your containers tidy.
- **Automatic Guild Bank Tab Matching**: Automatically switches to the correct guild bank tab for each item and deposits it there.
- **Strict Multi-Destination Safeguards**: If an item is stored across multiple guild bank tabs, or in both your personal bank and guild bank, it is flagged as a conflict and safely skipped to protect your manual organization.
- **Ignore List & Pruning**: Easily exclude specific items (such as raid consumables or tools) from consolidation and future snapshots.
- **In-Game Mappings Viewer**: Dedicated viewer window to search, audit, and manage your mappings, conflicts, and ignored items anywhere in the world.

---

## Installation

### Prerequisites
- **Bagnon** must be installed and active.

### Manual Installation
1. Download the `Bagnon_Consolidator` folder.
2. Place or extract the folder into your World of Warcraft addons directory depending on your version:
   - **Retail**: `_retail_/Interface/AddOns/Bagnon_Consolidator`
   - **Classic Era (Vanilla)**: `_classic_era_/Interface/AddOns/Bagnon_Consolidator`
   - **Progression Classic (e.g., Mists of Pandaria Classic, Cataclysm Classic)**: `_classic_/Interface/AddOns/Bagnon_Consolidator`
3. Launch the game and ensure **Bagnon Consolidator** is checked in your AddOns list at the character selection screen.

---

## How to Use

### 1. Initial Setup (Snapshot)
1. Open your **Bank** or **Guild Bank** at a banker or vault with your items sorted into their desired bags or tabs.
2. Right-click the green plus-sign (`+`) button on your main Bagnon inventory frame and click **Take Snapshot** (or click **Take Snapshot** in the Mappings Viewer).
3. The addon will scan your containers and save the mappings.

### 2. Consolidating Items
1. Whenever your bank or guild bank is open, **left-click** the green plus-sign (`+`) button labeled **Consolidate to Bank** on your backpack frame.
2. The addon will automatically scan your inventory and deposit matching items into their designated bank bags or guild tabs.

### 3. Managing Mappings & Ignore List
1. **Right-click** the plus-sign (`+`) button and select **Open Mappings Viewer...** (or navigate to `Game Menu` $\rightarrow$ `Options` $\rightarrow$ `AddOns` $\rightarrow$ `Bagnon Consolidator`).
2. Browse items across **Personal Bank**, **Guild Bank Tabs**, **Conflicts**, and **Ignored** lists.
3. Click `Ignore [X]` next to any item you wish to keep in your bags; click `Restore` in the Ignored tab to allow it to be re-learned on future snapshots.
