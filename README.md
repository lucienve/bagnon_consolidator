# Bagnon Consolidator

**Bagnon Consolidator** is a lightweight companion addon for **Bagnon** that helps you automatically clean up, consolidate, and deposit duplicate item stacks from your bags into your personal bank or guild bank.

---

## Features

- **Seamless Bagnon Integration**: Adds a clean **Consolidate to Bank** (`+`) button to the top-right header of your inventory bag frame.
- **Smart Duplicate Detection**: Only transfers items from your backpack if at least one stack of that item already exists in the bank (or guild bank). This prevents cluttering your bank with new, unsorted items or gear.
- **Stack Compression**: Merges partial item stacks in both your bank and inventory to maximize empty space and keep your containers tidy.
- **Automatic Guild Bank Tab Matching**: Automatically detects which tab a duplicate item is on, switches to that tab, and deposits it there.
- **Multi-Tab Safeguard (Guild Bank)**: If you store the same item on multiple guild bank tabs, the addon will safely skip transferring it and print a warning message in your chat to protect your manual organization.

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

1. Open your **Bank** or **Guild Bank** at a banker or vault.
2. Click the green plus-sign (`+`) button labeled **Consolidate to Bank** at the top right of your main Bagnon inventory bag frame.
3. The addon will automatically scan your containers and execute the consolidations asynchronously.
