---
trigger: always_on
description:
  Bagnon Consolidator maintenance rules, WoW addon coding standards, testing procedures,
  and architecture guidelines.
---

# Bagnon Consolidator Maintenance & Development Directives

You must strictly adhere to these architectural patterns, coding standards,
testing procedures, and verification guidelines when maintaining or contributing to
the **Bagnon Consolidator** World of Warcraft addon codebase.

---

## 1. Codebase Architecture & Structure

Understand the file layout of this independent addon before modifying components:

- **Root Directory:**
  - `Bagnon_Consolidator.toc`: Set dependencies (specifically Bagnon), Author (LVE), Interface versions, and specifies `main.xml` as the entry manifest.
  - `main.xml`: XML manifest loading Lua scripts via `<Script>` tag to respect BagBrother/Bagnon load order guidelines.
  - `main.lua`: The single script containing core logic, Class definitions, hooks, UI events, and consolidation algorithm.
- **doc/**: Documentation containing the architectural specifications and task plans.
  - `architecture.md`: Addon design, algorithms, UI hooks, and database scanning details.
  - `project_context.md`: Architectural decisions and implementation progress checklists.
- **.agents/**: Agent-specific rules and configurations.

---

## 2. Formatting & Development Rules

All changes must strictly follow these formatting and registration guidelines:

### Indentation and Formatting

- **Use Tabs**: Indent Lua code using tabs (`\t`). Do not mix spaces and tabs.
- **Whitespace**: Maintain clean spacing around logical conditions, functions, and assignments.

### Local Pattern & Style Conformance

- **Namespace Access**:
  - Always extract the addon namespace at the top of the file:
    ```lua
    local ADDON, Addon = (...):match('[^_]+'), _G[(...):match('[^_]+')]
    ```
- **Multi-Expansion Compatibility**:
  - Always use `LibStub('C_Everywhere')` to bridge expansion API differences (e.g. `C.GetItemInfoInstant`, `C.GetItemInfo`).
- **Seamless Integration**: Mirror the surrounding coding style in `main.lua`, including variable naming conventions, table structures, and internal event loops.

### File Registrations & Load Order

- **XML Manifests**:
  - Avoid listing Lua files in `Bagnon_Consolidator.toc` directly.
  - Register any new script files in `main.xml` using `<Script file="filename.lua"/>`.

### Class and OOP Definitions

- Inherit from the Bagnon base component library classes using the `Addon.Tipped:NewClass` framework (or other suitable Bagnon class engines):
  ```lua
  local ConsolidateButton = Addon.Tipped:NewClass('ConsolidateButton', 'Button', 'BagnonButtonTemplate')
  ```
- Invoke parent/superclass methods via `self:Super(ClassName):MethodName(...)`.

### Asynchronous Consolidation Engine & Queue

- **Queue Runner (`Queue`)**:
  - Item moves (`move`) and guild bank tab switches (`switch_tab`) must run asynchronously via `Queue`.
  - Listen to `BAG_UPDATE_DELAYED` (Personal Bank) and `GUILDBANKBAGSLOTS_CHANGED` (Guild Bank) to sequence moves.
  - Implement a safety timeout (e.g., `C_Timer.After(1.5, callback)`) to prevent UI lockup when a WoW packet fails or is delayed.
  - Implement slot locking checks via `IsSlotLocked` to queue retries if slots are currently locked during move simulation.
- **Simulation Algorithm (`SimulateMove`, `ConsolidateItem`)**:
  - Consolidate item stacks by sorting slots in ascending order of item count.
  - Pre-consolidate the destination container (Bank) and source container (Backpack) separately before attempting cross-container merges.

---

## 3. Testing and Verification

You must perform syntax checking and validation for all Lua code changes:

- **Syntax Check**: Run `luac -p` on all modified or new Lua files before completing work:
  ```bash
  luac -p main.lua
  ```
- **In-Game Verification**: Automated CLI test suites are not supported. All logic, event sync, and layout changes must be manually verified inside the World of Warcraft client.
- **Error Display**: Ensure WoW script error displays are enabled during development:
  ```text
  /console scriptErrors 1
  ```
