--[[
	Bagnon Consolidator - Localization (zhTW)
	Traditional Chinese Translation
--]]

local ADDON, Addon = (...):match('[^_]+'), _G[(...):match('[^_]+')]
local L = LibStub("AceLocale-3.0"):NewLocale("Bagnon_Consolidator", "zhTW")
if not L then return end

-- Addon Metadata & General
L["Bagnon Consolidator"] = "Bagnon Consolidator"
L["Consolidate to Bank"] = "整合存入銀行"
L["Consolidate to Bank Tooltip"] = "在背包中尋找重複物品並將其存入已開啟的銀行，自動合併堆疊以節省空間。"
L["Options / Mappings"] = "選項 / 對應"
L["Open Mappings Viewer..."] = "開啟對應檢視器..."
L["Take Snapshot"] = "建立快照"
L["Reset Mappings..."] = "重設對應..."
L["Enable Debug Logs"] = "啟用除錯記錄"
L["All Addon Data"] = "所有插件資料"
L["Current Character"] = "目前角色"
L["Personal Bank"] = "個人銀行"
L["Guild Bank"] = "公會銀行"
L["Unknown Item"] = "未知物品"

-- Dialogs & Confirmations
L["RESET_CONFIRM_DIALOG"] = "確定要重設 %s 的所有已儲存對應嗎？"
L["Yes"] = "是"
L["No"] = "否"

-- Notifications & Status Messages
L["Reset all guild bank mappings for %s"] = "已重設 %s 的所有公會銀行對應。"
L["You are not currently in a guild."] = "你目前不在公會中。"
L["Reset all personal bank mappings for %s"] = "已重設 %s 的所有個人銀行對應。"
L["Reset all Bagnon Consolidator mappings and ignore lists."] = "已重設所有 Bagnon Consolidator 對應與忽略清單。"
L["Bank or Guild Bank must be open to take a snapshot."] = "必須開啟銀行或公會銀行才能建立快照。"
L["Unable to determine character name and realm."] = "無法取得角色名稱與伺服器。"
L["Snapshot complete for Guild Bank: %s (%d items mapped, %d conflicts, %d ignored)."] = "公會銀行快照完成：%s（已對應 %d 個物品，%d 個衝突，%d 個已忽略）。"
L["Snapshot complete for Personal Bank: %s (%d items mapped, %d ignored)."] = "個人銀行快照完成：%s（已對應 %d 個物品，%d 個已忽略）。"
L["Cannot consolidate in combat."] = "戰鬥中無法進行整合。"
L["Bank or Guild Bank must be open and active."] = "銀行或公會銀行必須處於開啟並可用狀態。"
L["Consolidation is already in progress."] = "整合正在進行中。"
L["Consolidation complete."] = "整合完成。"
L["Consolidation stopped: %s"] = "整合已停止：%s"
L["No items need consolidation."] = "沒有需要整合的物品。"

-- Conflict & Ignore Reasons
L["Present in both Personal Bank and Guild Bank"] = "同時存在於個人銀行與公會銀行"
L["Present on multiple Guild Bank tabs"] = "存在於多個公會銀行標籤頁"
L["Present in personal bank of %s"] = "存在於 %s 的個人銀行中"
L["Item has conflicting destinations."] = "物品存在衝突的目的地。"
L["Multiple destinations"] = "多個目的地"
L["Conflict (Go Nowhere)"] = "衝突（不移動）"
L["Ignored (Never Deposit)"] = "已忽略（從不存入）"
L["%s: %s (Skipped)."] = "%s：%s（已略過）。"
L["%s has conflicting destinations (Skipped)."] = "%s 存在衝突的目的地（已略過）。"

-- Viewer & Management UI
L["Bagnon Consolidator: Mappings"] = "Bagnon Consolidator：對應"
L["Personal"] = "個人"
L["Guild Bank >"] = "公會銀行 >"
L["Select Guild Bank Tab"] = "選擇公會銀行標籤頁"
L["Tab %d"] = "標籤 %d"
L["Tab %d >"] = "標籤 %d >"
L["Tab %d: %s"] = "標籤 %d：%s"
L["Tab %d:"] = "標籤 %d："
L["Personal (%d)"] = "個人 (%d)"
L["Conflicts (%d)"] = "衝突 (%d)"
L["Ignored (%d)"] = "已忽略 (%d)"
L["Conflicts"] = "衝突"
L["Ignored"] = "已忽略"
L["Personal Bank Header"] = "|cff82c5ff個人銀行：|r %s"
L["Guild Bank Header Custom"] = "|cff82c5ff公會銀行：|r 標籤 %d：%s"
L["Guild Bank Header"] = "|cff82c5ff公會銀行：|r 標籤 %d"
L["Conflicts Header"] = "|cffffcc00衝突：|r 擁有多個目的地的物品（不移動）"
L["Ignored Header"] = "|cffff8888已忽略：|r 排除在整合之外的物品"
L["Filter by name/ID"] = "依名稱/ID過濾"
L["Showing %d items"] = "顯示 %d 個物品"
L["Showing 0 items"] = "顯示 0 個物品"
L["Ignored - will not consolidate"] = "已忽略 - 不會整合"
L["Conflict: %s"] = "衝突：%s"
L["Restore"] = "復原"
L["Clear"] = "清除"
L["Ignore [X]"] = "忽略 [X]"
L["Remove"] = "移除"
L["Item ID: %d"] = "物品 ID：%d"
L["Item %d"] = "物品 %d"
L["%s moved to Ignored list."] = "%s 已移至忽略清單。"
L["%s removed from Ignored list (can be re-learned on next snapshot)."] = "%s 已從忽略清單中移除（將在下次快照時重新記錄）。"
L["%s conflict cleared."] = "%s 衝突已清除。"

-- Options Panel
L["Options Description"] = "根據你的銀行快照，自動將背包中的物品堆疊存入個人銀行或公會銀行並進行整合。"
