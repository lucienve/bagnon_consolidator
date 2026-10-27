---
trigger: always_on
description:
  Bagnon Consolidator maintenance rules, WoW addon coding standards,
  testing procedures, and architecture guidelines.
---

# Bagnon Consolidator Maintenance & Development Directives

You must strictly adhere to these architectural patterns, coding standards,
testing procedures, and verification guidelines when maintaining or
contributing to the **Bagnon Consolidator** World of Warcraft addon codebase.

---

## 1. Codebase Architecture & Structure

Understand the file layout of this independent addon before modifying
components:

- **Root Directory:**
  - `Bagnon_Consolidator.toc`: Set dependencies (specifically Bagnon), Author
    (LVE), Interface versions, and specifies `main.xml` as the entry manifest.
  - `main.xml`: XML manifest loading Lua scripts via `<Script>` tag to respect
    BagBrother/Bagnon load order guidelines.
  - `core/`: Modular core engine scripts (`init.lua`, `utils.lua`,
    `snapshot.lua`, `engine.lua`).
  - `ui/`: User interface and configuration components (`button.lua`,
    `viewer.lua`, `options.lua`).
- **docs/**: Documentation containing architectural specifications and plans.
  - `architecture.md`: Addon design, algorithms, UI hooks, and database
    scanning details.
  - `project_context.md`: Architectural decisions and progress checklists.
- **.agents/**: Agent-specific rules and configurations.

---

## 2. Formatting & Development Rules

All changes must strictly follow these formatting and registration guidelines:

### Indentation and Formatting

- **Use Tabs**: Indent Lua code using tabs (`\t`). Do not mix spaces and tabs.
- **Whitespace**: Maintain clean spacing around logical conditions, functions,
  and assignments.

### Local Pattern & Style Conformance

- **Namespace Access**:
  - Always extract the addon namespace at the top of the file:
    ```lua
    local ADDON, Addon = (...):match('[^_]+'), _G[(...):match('[^_]+')]
    ```
- **Multi-Expansion Compatibility**:
  - Always use `LibStub('C_Everywhere')` to bridge expansion API differences
    (e.g. `C.C_Item.GetItemInfo`, `C.C_Item.GetItemIconByID`).
- **Seamless Integration**: Mirror the surrounding coding style across `core/`
  and `ui/` modules, including variable naming conventions, table structures,
  and event registration idioms.

### File Registrations & Load Order

- **XML Manifests**:
  - Avoid listing Lua files in `Bagnon_Consolidator.toc` directly.
  - Register any new script files in `main.xml` using
    `<Script file="filename.lua"/>` in topological dependency order.

### Class and OOP Definitions

- Inherit from the Bagnon base component library classes using the
  `Addon.Tipped:NewClass` framework (or other suitable Bagnon class engines):
  ```lua
  local ConsolidateButton = Addon.Tipped:NewClass('ConsolidateButton', 'Button', 'BagnonButtonTemplate')
  ```
- Invoke parent/superclass methods via `self:Super(ClassName):MethodName(...)`.

### Asynchronous Consolidation Engine & Movement Delegation

- **Delegation to `LibItemMove-1.0` (`core/engine.lua`)**:
  - Container scanning, multi-tab routing, stack consolidation, lock checks,
    transaction verification, and slot pairing are delegated to
    `LibItemMove-1.0`.
  - Queue item moves via `LibItemMove:Move(queue, context, callback)`.
  - Handle asynchronous events gracefully: `PROGRESS`, `UPDATE_UI`, `DONE`,
    `TIMEOUT_ERROR`, `CURSOR_LOCKED_ERROR`, and `PERMISSION_ERROR`.
  - Enforce combat lockdown safety checks (`InCombatLockdown()`) prior to
    starting consolidation runs.

---

## 3. Testing and Verification

All changes must pass the three-pillar quality verification gate before staging:

- **Static Type Checking (Pillar 1)**: Run LuaLS across the codebase:
  ```bash
  lua-language-server --check . --checklevel=Warning
  ```
- **WoW Domain & Taint Linting (Pillar 2)**:
  Run `wow_lua_lint` across all target client flavors (`mainline`, `mists`,
  `vanilla`, `forever`) to guarantee zero execution taint, no secure frame
  manipulation during combat lockdown, and no removed APIs. Pass
  `knownGlobals: ["LibStub", "BagnonConsolidatorDB", "StaticPopup_Show"]`.
- **Manifest & XML Integrity (Pillar 3)**:
  - Run `wow_toc_validate` on `Bagnon_Consolidator.toc`.
  - Run `wow_xml_validate` on `main.xml` and `locales/locales.xml`.
  - Run `luac -p` on all Lua scripts:
    ```bash
    luac -p core/*.lua ui/*.lua locales/*.lua scripts/dump_mappings.lua types.lua tests/test_consolidator.lua
    ```
- **Automated Unit Testing**: Execute the mock regression test suite:
  ```bash
  lua tests/test_consolidator.lua
  ```
- **In-Game Verification**: Verify UI frame rendering, button placement,
  viewer navigation, and item movements inside the World of Warcraft client.
- **Error Display**: Ensure WoW script error displays are enabled during
  development:
  ```text
  /console scriptErrors 1
  ```
