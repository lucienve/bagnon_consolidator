# Project Context: Bagnon Consolidator

This document tracks the current plan, architectural decisions, and tasks for the Bagnon Consolidator addon.

## Architectural Decisions

1.  **Addon Style**: Developed as a self-contained addon named `Bagnon_Consolidator` located at the root of the repository.
2.  **UI Integration**: Implemented by hook-overriding `Bagnon.Inventory.GetExtraButtons()` at runtime to insert a custom button into the backpack frame.
3.  **Loading Manifest**: Uses `Bagnon_Consolidator.toc` to load `main.xml`, which then loads `main.lua` via `<Script file="main.lua"/>` to respect BagBrother's manifest conventions.
4.  **Guild Bank Safeguard**: Skip items found in multiple guild bank tabs to preserve player categorization; print warning to chat.
5.  **Guild Bank Processing**: Processed tab-by-tab asynchronously, waiting for `GUILDBANKBAGSLOTS_CHANGED` between tab switches.
6.  **Personal Bank Processing**: Consolidated across all bank bags normally without multi-bag restrictions.
7.  **Coding Conventions**: Tab indentation for Lua scripts, usage of `LibStub('C_Everywhere')` wrapper library, and syntax verification using `luac -p`.

## Current Plan & Progress

*   **Phase 1: Setup and Directory Structure**
    *   [x] Set up repository root directory structure
    *   [x] Create `Bagnon_Consolidator.toc` and `main.xml`
*   **Phase 2: Addon Script Implementation**
    *   [x] Hook UI frames to inject consolidation button
    *   [x] Write the scan and check algorithms (multi-tab check)
    *   [x] Write the recursive stack optimization algorithm
    *   [x] Implement asynchronous event-driven queue runner
*   **Phase 3: Verification & Staging**
    *   [x] Syntax checking using `luac -p`
    *   [x] Stage files in Git index
    *   [x] Document changes in `walkthrough.md`
*   **Phase 4: Lua Type Checking Integration**
    *   [x] Set up type definitions and configurations
    *   [x] Add annotations to main.lua
    *   [x] Configure GitHub Actions workflow for static checks

