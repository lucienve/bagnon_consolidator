# Bagnon Consolidator Release Notes

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
