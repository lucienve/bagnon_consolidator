--[[
	Bagnon Consolidator - Localization (frFR)
	French Translation
--]]

local ADDON, Addon = (...):match('[^_]+'), _G[(...):match('[^_]+')]
local L = LibStub("AceLocale-3.0"):NewLocale("Bagnon_Consolidator", "frFR")
if not L then return end

-- Addon Metadata & General
L["Bagnon Consolidator"] = "Bagnon Consolidator"
L["Consolidate to Bank"] = "Consolider vers la banque"
L["Consolidate to Bank Tooltip"] = "Trouve les objets en double dans vos sacs et les dépose dans la banque ouverte en consolidant les piles pour libérer de la place."
L["Options / Mappings"] = "Options / Correspondances"
L["Open Mappings Viewer..."] = "Ouvrir le visualiseur de correspondances..."
L["Take Snapshot"] = "Prendre un instantané"
L["Reset Mappings..."] = "Réinitialiser les correspondances..."
L["Enable Debug Logs"] = "Activer les journaux de débogage"
L["All Addon Data"] = "Toutes les données de l'addon"
L["Current Character"] = "Personnage actuel"
L["Personal Bank"] = "Banque personnelle"
L["Guild Bank"] = "Banque de guilde"
L["Unknown Item"] = "Objet inconnu"

-- Dialogs & Confirmations
L["RESET_CONFIRM_DIALOG"] = "Voulez-vous vraiment réinitialiser toutes les correspondances enregistrées pour %s ?"
L["Yes"] = "Oui"
L["No"] = "Non"

-- Notifications & Status Messages
L["Reset all guild bank mappings for %s"] = "Toutes les correspondances de la banque de guilde ont été réinitialisées pour %s"
L["You are not currently in a guild."] = "Vous n'êtes actuellement pas dans une guilde."
L["Reset all personal bank mappings for %s"] = "Toutes les correspondances de la banque personnelle ont été réinitialisées pour %s"
L["Reset all Bagnon Consolidator mappings and ignore lists."] = "Toutes les correspondances et listes d'ignorés ont été réinitialisées."
L["Bank or Guild Bank must be open to take a snapshot."] = "La banque ou la banque de guilde doit être ouverte pour prendre un instantané."
L["Unable to determine character name and realm."] = "Impossible de déterminer le nom du personnage et le royaume."
L["Snapshot complete for Guild Bank: %s (%d items mapped, %d conflicts, %d ignored)."] = "Instantané terminé pour la banque de guilde : %s (%d objets associés, %d conflits, %d ignorés)."
L["Snapshot complete for Personal Bank: %s (%d items mapped, %d ignored)."] = "Instantané terminé pour la banque personnelle : %s (%d objets associés, %d ignorés)."
L["Cannot consolidate in combat."] = "Impossible de consolider en combat."
L["Bank or Guild Bank must be open and active."] = "La banque ou la banque de guilde doit être ouverte et active."
L["Consolidation is already in progress."] = "La consolidation est déjà en cours."
L["Consolidation complete."] = "Consolidation terminée."
L["Consolidation stopped: %s"] = "Consolidation interrompue : %s"
L["No items need consolidation."] = "Aucun objet à consolider."

-- Conflict & Ignore Reasons
L["Present in both Personal Bank and Guild Bank"] = "Présent à la fois dans la banque personnelle et la banque de guilde"
L["Present on multiple Guild Bank tabs"] = "Présent sur plusieurs onglets de la banque de guilde"
L["Present in personal bank of %s"] = "Présent dans la banque personnelle de %s"
L["Item has conflicting destinations."] = "L'objet a des destinations conflictuelles."
L["Multiple destinations"] = "Destinations multiples"
L["Conflict (Go Nowhere)"] = "Conflit (Ne pas déposer)"
L["Ignored (Never Deposit)"] = "Ignoré (Ne jamais déposer)"
L["%s: %s (Skipped)."] = "%s : %s (Ignoré)."
L["%s has conflicting destinations (Skipped)."] = "%s a des destinations conflictuelles (Ignoré)."

-- Viewer & Management UI
L["Bagnon Consolidator: Mappings"] = "Bagnon Consolidator : Correspondances"
L["Personal"] = "Personnel"
L["Guild Bank >"] = "Banque de guilde >"
L["Select Guild Bank Tab"] = "Sélectionner l'onglet de banque de guilde"
L["Tab %d"] = "Onglet %d"
L["Tab %d >"] = "Onglet %d >"
L["Tab %d: %s"] = "Onglet %d : %s"
L["Tab %d:"] = "Onglet %d :"
L["Personal (%d)"] = "Personnel (%d)"
L["Conflicts (%d)"] = "Conflits (%d)"
L["Ignored (%d)"] = "Ignorés (%d)"
L["Conflicts"] = "Conflits"
L["Ignored"] = "Ignorés"
L["Personal Bank Header"] = "|cff82c5ffBanque personnelle :|r %s"
L["Guild Bank Header Custom"] = "|cff82c5ffBanque de guilde :|r Onglet %d : %s"
L["Guild Bank Header"] = "|cff82c5ffBanque de guilde :|r Onglet %d"
L["Conflicts Header"] = "|cffffcc00Conflits :|r Objets avec plusieurs destinations (Ne pas déposer)"
L["Ignored Header"] = "|cffff8888Ignorés :|r Objets exclus de la consolidation"
L["Filter by name/ID"] = "Filtrer par nom/ID"
L["Showing %d items"] = "Affichage de %d objets"
L["Showing 0 items"] = "Affichage de 0 objets"
L["Ignored - will not consolidate"] = "Ignoré - ne sera pas consolidé"
L["Conflict: %s"] = "Conflit : %s"
L["Restore"] = "Restaurer"
L["Clear"] = "Effacer"
L["Ignore [X]"] = "Ignorer [X]"
L["Remove"] = "Supprimer"
L["Item ID: %d"] = "ID de l'objet : %d"
L["Item %d"] = "Objet %d"
L["%s moved to Ignored list."] = "%s déplacé vers la liste des ignorés."
L["%s removed from Ignored list (can be re-learned on next snapshot)."] = "%s retiré de la liste des ignorés (sera réappris au prochain instantané)."
L["%s conflict cleared."] = "Conflit résolu pour %s."

-- Options Panel
L["Options Description"] = "Dépose et consolide automatiquement les piles d'objets de vos sacs vers la banque ou la banque de guilde selon votre instantané."
