--[[
	Bagnon Consolidator - Localization (ruRU)
	Russian Translation
--]]

local ADDON, Addon = (...):match('[^_]+'), _G[(...):match('[^_]+')]
local L = LibStub("AceLocale-3.0"):NewLocale("Bagnon_Consolidator", "ruRU")
if not L then return end

-- Addon Metadata & General
L["Bagnon Consolidator"] = "Bagnon Consolidator"
L["Consolidate to Bank"] = "Объединить в банк"
L["Consolidate to Bank Tooltip"] = "Находит дубликаты предметов в сумках и переносит их в открытый банк, объединяя стопки для экономии места."
L["Options / Mappings"] = "Параметры / Сопоставления"
L["Open Mappings Viewer..."] = "Открыть просмотр сопоставлений..."
L["Take Snapshot"] = "Сделать снимок"
L["Reset Mappings..."] = "Сбросить сопоставления..."
L["Enable Debug Logs"] = "Включить журнал отладки"
L["All Addon Data"] = "Все данные аддона"
L["Current Character"] = "Текущий персонаж"
L["Personal Bank"] = "Личный банк"
L["Guild Bank"] = "Банк гильдии"
L["Unknown Item"] = "Неизвестный предмет"

-- Dialogs & Confirmations
L["RESET_CONFIRM_DIALOG"] = "Вы уверены, что хотите сбросить все сохраненные сопоставления для %s?"
L["Yes"] = "Да"
L["No"] = "Нет"

-- Notifications & Status Messages
L["Reset all guild bank mappings for %s"] = "Сброшены все сопоставления банка гильдии для %s"
L["You are not currently in a guild."] = "Вы в настоящее время не состоите в гильдии."
L["Reset all personal bank mappings for %s"] = "Сброшены все сопоставления личного банка для %s"
L["Reset all Bagnon Consolidator mappings and ignore lists."] = "Сброшены все сопоставления и списки игнорирования Bagnon Consolidator."
L["Bank or Guild Bank must be open to take a snapshot."] = "Банк или банк гильдии должен быть открыт для создания снимка."
L["Unable to determine character name and realm."] = "Не удалось определить имя персонажа и игровой мир."
L["Snapshot complete for Guild Bank: %s (%d items mapped, %d conflicts, %d ignored)."] = "Снимок банка гильдии завершен: %s (сопоставлено предметов: %d, конфликтов: %d, пропущено: %d)."
L["Snapshot complete for Personal Bank: %s (%d items mapped, %d ignored)."] = "Снимок личного банка завершен: %s (сопоставлено предметов: %d, пропущено: %d)."
L["Cannot consolidate in combat."] = "Нельзя объединять во время боя."
L["Bank or Guild Bank must be open and active."] = "Банк или банк гильдии должен быть открыт и активен."
L["Consolidation is already in progress."] = "Объединение уже выполняется."
L["Consolidation complete."] = "Объединение завершено."
L["Consolidation stopped: %s"] = "Объединение остановлено: %s"
L["No items need consolidation."] = "Нет предметов, требующих объединения."

-- Conflict & Ignore Reasons
L["Present in both Personal Bank and Guild Bank"] = "Присутствует как в личном банке, так и в банке гильдии"
L["Present on multiple Guild Bank tabs"] = "Присутствует на нескольких вкладках банка гильдии"
L["Present in personal bank of %s"] = "Присутствует в личном банке персонажа %s"
L["Item has conflicting destinations."] = "У предмета конфликтующие места назначения."
L["Multiple destinations"] = "Несколько мест назначения"
L["Conflict (Go Nowhere)"] = "Конфликт (Не перемещать)"
L["Ignored (Never Deposit)"] = "Игнорируется (Никогда не сдавать)"
L["%s: %s (Skipped)."] = "%s: %s (Пропущено)."
L["%s has conflicting destinations (Skipped)."] = "%s имеет конфликтующие места назначения (Пропущено)."

-- Viewer & Management UI
L["Bagnon Consolidator: Mappings"] = "Bagnon Consolidator: Сопоставления"
L["Personal"] = "Личный"
L["Guild Bank >"] = "Банк гильдии >"
L["Select Guild Bank Tab"] = "Выбрать вкладку банка гильдии"
L["Tab %d"] = "Вкладка %d"
L["Tab %d >"] = "Вкладка %d >"
L["Tab %d: %s"] = "Вкладка %d: %s"
L["Tab %d:"] = "Вкладка %d:"
L["Personal (%d)"] = "Личный (%d)"
L["Conflicts (%d)"] = "Конфликты (%d)"
L["Ignored (%d)"] = "Игнорируемые (%d)"
L["Conflicts"] = "Конфликты"
L["Ignored"] = "Игнорируемые"
L["Personal Bank Header"] = "|cff82c5ffЛичный банк:|r %s"
L["Guild Bank Header Custom"] = "|cff82c5ffБанк гильдии:|r Вкладка %d: %s"
L["Guild Bank Header"] = "|cff82c5ffБанк гильдии:|r Вкладка %d"
L["Conflicts Header"] = "|cffffcc00Конфликты:|r Предметы с несколькими назначениями (Не перемещать)"
L["Ignored Header"] = "|cffff8888Игнорируемые:|r Предметы, исключенные из объединения"
L["Filter by name/ID"] = "Фильтр по названию/ID"
L["Showing %d items"] = "Показано предметов: %d"
L["Showing 0 items"] = "Показано предметов: 0"
L["Ignored - will not consolidate"] = "Игнорируется - не будет объединяться"
L["Conflict: %s"] = "Конфликт: %s"
L["Restore"] = "Восстановить"
L["Clear"] = "Очистить"
L["Ignore [X]"] = "Игнорировать [X]"
L["Remove"] = "Удалить"
L["Item ID: %d"] = "ID предмета: %d"
L["Item %d"] = "Предмет %d"
L["%s moved to Ignored list."] = "%s перемещен в список игнорирования."
L["%s removed from Ignored list (can be re-learned on next snapshot)."] = "%s удален из списка игнорирования (будет повторно изучен при следующем снимке)."
L["%s conflict cleared."] = "Конфликт для %s устранен."

-- Options Panel
L["Options Description"] = "Автоматически перемещает и объединяет стопки предметов из ваших сумок в банк или банк гильдии на основе снимка банка."
