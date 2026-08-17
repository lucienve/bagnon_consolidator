--[[
	Bagnon Consolidator - Localization (enUS / enGB)
	Default / Fallback Locale Dictionary
--]]

local ADDON, Addon = (...):match('[^_]+'), _G[(...):match('[^_]+')]
local L = LibStub("AceLocale-3.0"):NewLocale("Bagnon_Consolidator", "enUS", true)
if not L then return end

-- Addon Metadata & General
L["Bagnon Consolidator"] = true
L["Consolidate to Bank"] = true
L["Consolidate to Bank Tooltip"] = "Finds duplicate items in your bags and moves them to the open bank, consolidating stacks to save space."
L["Options / Mappings"] = true
L["Open Mappings Viewer..."] = true
L["Take Snapshot"] = true
L["Reset Mappings..."] = true
L["Enable Debug Logs"] = true
L["All Addon Data"] = true
L["Current Character"] = true
L["Personal Bank"] = true
L["Guild Bank"] = true
L["Unknown Item"] = true

-- Dialogs & Confirmations
L["RESET_CONFIRM_DIALOG"] = "Are you sure you want to reset all stored mappings for %s?"
L["Yes"] = true
L["No"] = true

-- Notifications & Status Messages
L["Reset all guild bank mappings for %s"] = true
L["You are not currently in a guild."] = true
L["Reset all personal bank mappings for %s"] = true
L["Reset all Bagnon Consolidator mappings and ignore lists."] = true
L["Bank or Guild Bank must be open to take a snapshot."] = true
L["Unable to determine character name and realm."] = true
L["Snapshot complete for Guild Bank: %s (%d items mapped, %d conflicts, %d ignored)."] = true
L["Snapshot complete for Personal Bank: %s (%d items mapped, %d ignored)."] = true
L["Cannot consolidate in combat."] = true
L["Bank or Guild Bank must be open and active."] = true
L["Consolidation is already in progress."] = true
L["Consolidation complete."] = true
L["Consolidation stopped: %s"] = true
L["No items need consolidation."] = true

-- Conflict & Ignore Reasons
L["Present in both Personal Bank and Guild Bank"] = true
L["Present on multiple Guild Bank tabs"] = true
L["Present in personal bank of %s"] = true
L["Item has conflicting destinations."] = true
L["Multiple destinations"] = true
L["Conflict (Go Nowhere)"] = true
L["Ignored (Never Deposit)"] = true
L["%s: %s (Skipped)."] = true
L["%s has conflicting destinations (Skipped)."] = true

-- Viewer & Management UI
L["Bagnon Consolidator: Mappings"] = true
L["Personal"] = true
L["Guild Bank >"] = true
L["Select Guild Bank Tab"] = true
L["Tab %d"] = true
L["Tab %d >"] = true
L["Tab %d: %s"] = true
L["Tab %d:"] = true
L["Personal (%d)"] = true
L["Conflicts (%d)"] = true
L["Ignored (%d)"] = true
L["Conflicts"] = true
L["Ignored"] = true
L["Personal Bank Header"] = "|cff82c5ffPersonal Bank:|r %s"
L["Guild Bank Header Custom"] = "|cff82c5ffGuild Bank:|r Tab %d: %s"
L["Guild Bank Header"] = "|cff82c5ffGuild Bank:|r Tab %d"
L["Conflicts Header"] = "|cffffcc00Conflicts:|r Items with Multiple Destinations (Go Nowhere)"
L["Ignored Header"] = "|cffff8888Ignored:|r Items Excluded from Consolidation"
L["Filter by name/ID"] = true
L["Showing %d items"] = true
L["Showing 0 items"] = true
L["Ignored - will not consolidate"] = true
L["Conflict: %s"] = true
L["Restore"] = true
L["Clear"] = true
L["Ignore [X]"] = true
L["Remove"] = true
L["Item ID: %d"] = true
L["Item %d"] = true
L["%s moved to Ignored list."] = true
L["%s removed from Ignored list (can be re-learned on next snapshot)."] = true
L["%s conflict cleared."] = true

-- Options Panel
L["Options Description"] = "Auto-deposits and consolidates item stacks from your bags to the bank or guild bank based on your physical bank snapshot."
