--[[
	Bagnon Consolidator - Localization (deDE)
	German Translation
--]]

local ADDON, Addon = (...):match('[^_]+'), _G[(...):match('[^_]+')]
local L = LibStub("AceLocale-3.0"):NewLocale("Bagnon_Consolidator", "deDE")
if not L then return end

-- Addon Metadata & General
L["Bagnon Consolidator"] = "Bagnon Consolidator"
L["Consolidate to Bank"] = "Zur Bank konsolidieren"
L["Consolidate to Bank Tooltip"] = "Findet doppelte Gegenstände in euren Taschen und verschiebt sie in die geöffnete Bank, um Stapel zusammenzuführen und Platz zu sparen."
L["Options / Mappings"] = "Optionen / Zuordnungen"
L["Open Mappings Viewer..."] = "Zuordnungs-Viewer öffnen..."
L["Take Snapshot"] = "Snapshot erstellen"
L["Reset Mappings..."] = "Zuordnungen zurücksetzen..."
L["Enable Debug Logs"] = "Debug-Protokolle aktivieren"
L["All Addon Data"] = "Alle Addondaten"
L["Current Character"] = "Aktueller Charakter"
L["Personal Bank"] = "Persönliche Bank"
L["Guild Bank"] = "Gildenbank"
L["Unknown Item"] = "Unbekannter Gegenstand"

-- Dialogs & Confirmations
L["RESET_CONFIRM_DIALOG"] = "Seid ihr sicher, dass ihr alle gespeicherten Zuordnungen für %s zurücksetzen möchtet?"
L["Yes"] = "Ja"
L["No"] = "Nein"

-- Notifications & Status Messages
L["Reset all guild bank mappings for %s"] = "Alle Gildenbank-Zuordnungen für %s wurden zurückgesetzt."
L["You are not currently in a guild."] = "Ihr befindet euch derzeit in keiner Gilde."
L["Reset all personal bank mappings for %s"] = "Alle persönlichen Bankzuordnungen für %s wurden zurückgesetzt."
L["Reset all Bagnon Consolidator mappings and ignore lists."] = "Alle Bagnon Consolidator-Zuordnungen und Ignorierlisten wurden zurückgesetzt."
L["Bank or Guild Bank must be open to take a snapshot."] = "Die Bank oder Gildenbank muss geöffnet sein, um einen Snapshot zu erstellen."
L["Unable to determine character name and realm."] = "Charaktername und Realm konnten nicht ermittelt werden."
L["Snapshot complete for Guild Bank: %s (%d items mapped, %d conflicts, %d ignored)."] = "Snapshot für Gildenbank abgeschlossen: %s (%d Gegenstände zugeordnet, %d Konflikte, %d ignoriert)."
L["Snapshot complete for Personal Bank: %s (%d items mapped, %d ignored)."] = "Snapshot für persönliche Bank abgeschlossen: %s (%d Gegenstände zugeordnet, %d ignoriert)."
L["Cannot consolidate in combat."] = "Im Kampf kann nicht konsolidiert werden."
L["Bank or Guild Bank must be open and active."] = "Bank oder Gildenbank muss geöffnet und aktiv sein."
L["Consolidation is already in progress."] = "Konsolidierung läuft bereits."
L["Consolidation complete."] = "Konsolidierung abgeschlossen."
L["Consolidation stopped: %s"] = "Konsolidierung gestoppt: %s"
L["No items need consolidation."] = "Keine Gegenstände erfordern eine Konsolidierung."

-- Conflict & Ignore Reasons
L["Present in both Personal Bank and Guild Bank"] = "Sowohl in der persönlichen Bank als auch in der Gildenbank vorhanden"
L["Present on multiple Guild Bank tabs"] = "Auf mehreren Gildenbank-Fächern vorhanden"
L["Present in personal bank of %s"] = "In der persönlichen Bank von %s vorhanden"
L["Item has conflicting destinations."] = "Gegenstand hat widersprüchliche Zielorte."
L["Multiple destinations"] = "Mehrere Zielorte"
L["Conflict (Go Nowhere)"] = "Konflikt (Nicht verschieben)"
L["Ignored (Never Deposit)"] = "Ignoriert (Nie einlagern)"
L["%s: %s (Skipped)."] = "%s: %s (Übersprungen)."
L["%s has conflicting destinations (Skipped)."] = "%s hat widersprüchliche Zielorte (Übersprungen)."

-- Viewer & Management UI
L["Bagnon Consolidator: Mappings"] = "Bagnon Consolidator: Zuordnungen"
L["Personal"] = "Persönlich"
L["Guild Bank >"] = "Gildenbank >"
L["Select Guild Bank Tab"] = "Gildenbank-Fach auswählen"
L["Tab %d"] = "Fach %d"
L["Tab %d >"] = "Fach %d >"
L["Tab %d: %s"] = "Fach %d: %s"
L["Tab %d:"] = "Fach %d:"
L["Personal (%d)"] = "Persönlich (%d)"
L["Conflicts (%d)"] = "Konflikte (%d)"
L["Ignored (%d)"] = "Ignoriert (%d)"
L["Conflicts"] = "Konflikte"
L["Ignored"] = "Ignoriert"
L["Personal Bank Header"] = "|cff82c5ffPersönliche Bank:|r %s"
L["Guild Bank Header Custom"] = "|cff82c5ffGildenbank:|r Fach %d: %s"
L["Guild Bank Header"] = "|cff82c5ffGildenbank:|r Fach %d"
L["Conflicts Header"] = "|cffffcc00Konflikte:|r Gegenstände mit mehreren Zielorten (Nicht verschieben)"
L["Ignored Header"] = "|cffff8888Ignoriert:|r Von der Konsolidierung ausgeschlossene Gegenstände"
L["Filter by name/ID"] = "Nach Name/ID filtern"
L["Showing %d items"] = "Zeige %d Gegenstände"
L["Showing 0 items"] = "Zeige 0 Gegenstände"
L["Ignored - will not consolidate"] = "Ignoriert - wird nicht konsolidiert"
L["Conflict: %s"] = "Konflikt: %s"
L["Restore"] = "Wiederherstellen"
L["Clear"] = "Löschen"
L["Ignore [X]"] = "Ignorieren [X]"
L["Remove"] = "Entfernen"
L["Item ID: %d"] = "Gegenstands-ID: %d"
L["Item %d"] = "Gegenstand %d"
L["%s moved to Ignored list."] = "%s auf Ignorierliste verschoben."
L["%s removed from Ignored list (can be re-learned on next snapshot)."] = "%s von Ignorierliste entfernt (wird beim nächsten Snapshot neu erfasst)."
L["%s conflict cleared."] = "Konflikt für %s behoben."

-- Options Panel
L["Options Description"] = "Lagert Gegenstandsstapel automatisch aus den Taschen in die Bank oder Gildenbank basierend auf dem Bank-Snapshot ein."
