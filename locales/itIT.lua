--[[
	Bagnon Consolidator - Localization (itIT)
	Italian Translation
--]]

local ADDON, Addon = (...):match('[^_]+'), _G[(...):match('[^_]+')]
local L = LibStub("AceLocale-3.0"):NewLocale("Bagnon_Consolidator", "itIT")
if not L then return end

-- Addon Metadata & General
L["Bagnon Consolidator"] = "Bagnon Consolidator"
L["Consolidate to Bank"] = "Consolida in banca"
L["Consolidate to Bank Tooltip"] = "Trova gli oggetti duplicati nelle borse e li sposta nella banca aperta, consolidando le pile per risparmiare spazio."
L["Options / Mappings"] = "Opzioni / Mappature"
L["Open Mappings Viewer..."] = "Apri visualizzatore mappature..."
L["Take Snapshot"] = "Crea istantanea"
L["Reset Mappings..."] = "Reimposta mappature..."
L["Enable Debug Logs"] = "Abilita registri di debug"
L["All Addon Data"] = "Tutti i dati dell'addon"
L["Current Character"] = "Personaggio attuale"
L["Personal Bank"] = "Banca personale"
L["Guild Bank"] = "Banca di gilda"
L["Unknown Item"] = "Oggetto sconosciuto"

-- Dialogs & Confirmations
L["RESET_CONFIRM_DIALOG"] = "Sei sicuro di voler reimpostare tutte le mappature salvate per %s?"
L["Yes"] = "Sì"
L["No"] = "No"

-- Notifications & Status Messages
L["Reset all guild bank mappings for %s"] = "Tutte le mappature della banca di gilda per %s sono state reimpostate."
L["You are not currently in a guild."] = "Al momento non fai parte di una gilda."
L["Reset all personal bank mappings for %s"] = "Tutte le mappature della banca personale per %s sono state reimpostate."
L["Reset all Bagnon Consolidator mappings and ignore lists."] = "Tutte le mappature e le liste ignorati di Bagnon Consolidator sono state reimpostate."
L["Bank or Guild Bank must be open to take a snapshot."] = "La banca o la banca di gilda deve essere aperta per creare un'istantanea."
L["Unable to determine character name and realm."] = "Impossibile determinare il nome del personaggio e il reame."
L["Snapshot complete for Guild Bank: %s (%d items mapped, %d conflicts, %d ignored)."] = "Istantanea completata per la Banca di gilda: %s (%d oggetti mappati, %d conflitti, %d ignorati)."
L["Snapshot complete for Personal Bank: %s (%d items mapped, %d ignored)."] = "Istantanea completata per la Banca personale: %s (%d oggetti mappati, %d ignorati)."
L["Cannot consolidate in combat."] = "Impossibile consolidare durante il combattimento."
L["Bank or Guild Bank must be open and active."] = "La banca o la banca di gilda deve essere aperta e attiva."
L["Consolidation is already in progress."] = "Il consolidamento è già in corso."
L["Consolidation complete."] = "Consolidamento completato."
L["Consolidation stopped: %s"] = "Consolidamento interrotto: %s"
L["No items need consolidation."] = "Nessun oggetto richiede il consolidamento."

-- Conflict & Ignore Reasons
L["Present in both Personal Bank and Guild Bank"] = "Presente sia nella banca personale che nella banca di gilda"
L["Present on multiple Guild Bank tabs"] = "Presente su più schede della banca di gilda"
L["Present in personal bank of %s"] = "Presente nella banca personale di %s"
L["Item has conflicting destinations."] = "L'oggetto ha destinazioni contrastanti."
L["Multiple destinations"] = "Destinazioni multiple"
L["Conflict (Go Nowhere)"] = "Conflitto (Non spostare)"
L["Ignored (Never Deposit)"] = "Ignorato (Non depositare mai)"
L["%s: %s (Skipped)."] = "%s: %s (Saltato)."
L["%s has conflicting destinations (Skipped)."] = "%s ha destinazioni contrastanti (Saltato)."

-- Viewer & Management UI
L["Bagnon Consolidator: Mappings"] = "Bagnon Consolidator: Mappature"
L["Personal"] = "Personale"
L["Guild Bank >"] = "Banca di gilda >"
L["Select Guild Bank Tab"] = "Seleziona scheda banca di gilda"
L["Tab %d"] = "Scheda %d"
L["Tab %d >"] = "Scheda %d >"
L["Tab %d: %s"] = "Scheda %d: %s"
L["Tab %d:"] = "Scheda %d:"
L["Personal (%d)"] = "Personale (%d)"
L["Conflicts (%d)"] = "Conflitti (%d)"
L["Ignored (%d)"] = "Ignorati (%d)"
L["Conflicts"] = "Conflitti"
L["Ignored"] = "Ignorati"
L["Personal Bank Header"] = "|cff82c5ffBanca personale:|r %s"
L["Guild Bank Header Custom"] = "|cff82c5ffBanca di gilda:|r Scheda %d: %s"
L["Guild Bank Header"] = "|cff82c5ffBanca di gilda:|r Scheda %d"
L["Conflicts Header"] = "|cffffcc00Conflitti:|r Oggetti con destinazioni multiple (Non spostare)"
L["Ignored Header"] = "|cffff8888Ignorati:|r Oggetti esclusi dal consolidamento"
L["Filter by name/ID"] = "Filtra per nome/ID"
L["Showing %d items"] = "Visualizzazione di %d oggetti"
L["Showing 0 items"] = "Visualizzazione di 0 oggetti"
L["Ignored - will not consolidate"] = "Ignorato - non verrà consolidato"
L["Conflict: %s"] = "Conflitto: %s"
L["Restore"] = "Ripristina"
L["Clear"] = "Cancella"
L["Ignore [X]"] = "Ignora [X]"
L["Remove"] = "Rimuovi"
L["Item ID: %d"] = "ID oggetto: %d"
L["Item %d"] = "Oggetto %d"
L["%s moved to Ignored list."] = "%s spostato nella lista ignorati."
L["%s removed from Ignored list (can be re-learned on next snapshot)."] = "%s rimosso dalla lista ignorati (verrà nuovamente memorizzato alla prossima istantanea)."
L["%s conflict cleared."] = "Conflitto per %s risolto."

-- Options Panel
L["Options Description"] = "Deposita e consolida automaticamente le pile di oggetti dalle borse alla banca o alla banca di gilda in base all'istantanea."
