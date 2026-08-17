--[[
	Bagnon Consolidator - Localization (esMX)
	Spanish (Latin America) Translation
--]]

local ADDON, Addon = (...):match('[^_]+'), _G[(...):match('[^_]+')]
local L = LibStub("AceLocale-3.0"):NewLocale("Bagnon_Consolidator", "esMX")
if not L then return end

-- Addon Metadata & General
L["Bagnon Consolidator"] = "Bagnon Consolidator"
L["Consolidate to Bank"] = "Consolidar en el banco"
L["Consolidate to Bank Tooltip"] = "Encuentra objetos duplicados en tus bolsas y los traslada al banco abierto, consolidando acumulaciones para ahorrar espacio."
L["Options / Mappings"] = "Opciones / Asignaciones"
L["Open Mappings Viewer..."] = "Abrir visor de asignaciones..."
L["Take Snapshot"] = "Tomar instantánea"
L["Reset Mappings..."] = "Restablecer asignaciones..."
L["Enable Debug Logs"] = "Habilitar registros de depuración"
L["All Addon Data"] = "Todos los datos del addon"
L["Current Character"] = "Personaje actual"
L["Personal Bank"] = "Banco personal"
L["Guild Bank"] = "Banco de hermandad"
L["Unknown Item"] = "Objeto desconocido"

-- Dialogs & Confirmations
L["RESET_CONFIRM_DIALOG"] = "¿Seguro que deseas restablecer todas las asignaciones guardadas para %s?"
L["Yes"] = "Sí"
L["No"] = "No"

-- Notifications & Status Messages
L["Reset all guild bank mappings for %s"] = "Se restablecieron todas las asignaciones del banco de hermandad para %s"
L["You are not currently in a guild."] = "Actualmente no estás en una hermandad."
L["Reset all personal bank mappings for %s"] = "Se restablecieron todas las asignaciones del banco personal para %s"
L["Reset all Bagnon Consolidator mappings and ignore lists."] = "Se restablecieron todas las asignaciones y listas de ignorados."
L["Bank or Guild Bank must be open to take a snapshot."] = "El banco o banco de hermandad debe estar abierto para tomar una instantánea."
L["Unable to determine character name and realm."] = "No se pudo determinar el nombre del personaje y reino."
L["Snapshot complete for Guild Bank: %s (%d items mapped, %d conflicts, %d ignored)."] = "Instantánea completada para el banco de hermandad: %s (%d objetos asignados, %d conflictos, %d ignorados)."
L["Snapshot complete for Personal Bank: %s (%d items mapped, %d ignored)."] = "Instantánea completada para el banco personal: %s (%d objetos asignados, %d ignorados)."
L["Cannot consolidate in combat."] = "No se puede consolidar en combate."
L["Bank or Guild Bank must be open and active."] = "El banco o banco de hermandad debe estar abierto y activo."
L["Consolidation is already in progress."] = "La consolidación ya está en curso."
L["Consolidation complete."] = "Consolidación completada."
L["Consolidation stopped: %s"] = "Consolidación detenida: %s"
L["No items need consolidation."] = "No hay objetos que necesiten consolidación."

-- Conflict & Ignore Reasons
L["Present in both Personal Bank and Guild Bank"] = "Presente tanto en el banco personal como en el banco de hermandad"
L["Present on multiple Guild Bank tabs"] = "Presente en varias pestañas del banco de hermandad"
L["Present in personal bank of %s"] = "Presente en el banco personal de %s"
L["Item has conflicting destinations."] = "El objeto tiene destinos conflictivos."
L["Multiple destinations"] = "Múltiples destinos"
L["Conflict (Go Nowhere)"] = "Conflicto (No depositar)"
L["Ignored (Never Deposit)"] = "Ignorado (Nunca depositar)"
L["%s: %s (Skipped)."] = "%s: %s (Omitido)."
L["%s has conflicting destinations (Skipped)."] = "%s tiene destinos conflictivos (Omitido)."

-- Viewer & Management UI
L["Bagnon Consolidator: Mappings"] = "Bagnon Consolidator: Asignaciones"
L["Personal"] = "Personal"
L["Guild Bank >"] = "Banco de hermandad >"
L["Select Guild Bank Tab"] = "Seleccionar pestaña del banco de hermandad"
L["Tab %d"] = "Pestaña %d"
L["Tab %d >"] = "Pestaña %d >"
L["Tab %d: %s"] = "Pestaña %d: %s"
L["Tab %d:"] = "Pestaña %d:"
L["Personal (%d)"] = "Personal (%d)"
L["Conflicts (%d)"] = "Conflictos (%d)"
L["Ignored (%d)"] = "Ignorados (%d)"
L["Conflicts"] = "Conflictos"
L["Ignored"] = "Ignorados"
L["Personal Bank Header"] = "|cff82c5ffBanco personal:|r %s"
L["Guild Bank Header Custom"] = "|cff82c5ffBanco de hermandad:|r Pestaña %d: %s"
L["Guild Bank Header"] = "|cff82c5ffBanco de hermandad:|r Pestaña %d"
L["Conflicts Header"] = "|cffffcc00Conflictos:|r Objetos con múltiples destinos (No depositar)"
L["Ignored Header"] = "|cffff8888Ignorados:|r Objetos excluidos de la consolidación"
L["Filter by name/ID"] = "Filtrar por nombre/ID"
L["Showing %d items"] = "Mostrando %d objetos"
L["Showing 0 items"] = "Mostrando 0 objetos"
L["Ignored - will not consolidate"] = "Ignorado - no se consolidará"
L["Conflict: %s"] = "Conflicto: %s"
L["Restore"] = "Restaurar"
L["Clear"] = "Borrar"
L["Ignore [X]"] = "Ignorar [X]"
L["Remove"] = "Eliminar"
L["Item ID: %d"] = "ID de objeto: %d"
L["Item %d"] = "Objeto %d"
L["%s moved to Ignored list."] = "%s trasladado a la lista de ignorados."
L["%s removed from Ignored list (can be re-learned on next snapshot)."] = "%s eliminado de la lista de ignorados (se volverá a aprender en la siguiente instantánea)."
L["%s conflict cleared."] = "Conflicto resuelto para %s."

-- Options Panel
L["Options Description"] = "Deposita y consolida automáticamente las acumulaciones de objetos de tus bolsas al banco o banco de hermandad según tu instantánea."
