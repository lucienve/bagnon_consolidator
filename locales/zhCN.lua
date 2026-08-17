--[[
	Bagnon Consolidator - Localization (zhCN)
	Simplified Chinese Translation
--]]

local ADDON, Addon = (...):match('[^_]+'), _G[(...):match('[^_]+')]
local L = LibStub("AceLocale-3.0"):NewLocale("Bagnon_Consolidator", "zhCN")
if not L then return end

-- Addon Metadata & General
L["Bagnon Consolidator"] = "Bagnon Consolidator"
L["Consolidate to Bank"] = "整合存入银行"
L["Consolidate to Bank Tooltip"] = "在背包中查找重复物品并将其存入已打开的银行，自动合并堆叠以节省空间。"
L["Options / Mappings"] = "选项 / 映射"
L["Open Mappings Viewer..."] = "打开映射查看器..."
L["Take Snapshot"] = "创建快照"
L["Reset Mappings..."] = "重置映射..."
L["Enable Debug Logs"] = "启用调试日志"
L["All Addon Data"] = "所有插件数据"
L["Current Character"] = "当前角色"
L["Personal Bank"] = "个人银行"
L["Guild Bank"] = "公会银行"
L["Unknown Item"] = "未知物品"

-- Dialogs & Confirmations
L["RESET_CONFIRM_DIALOG"] = "确定要重置 %s 的所有已保存映射吗？"
L["Yes"] = "是"
L["No"] = "否"

-- Notifications & Status Messages
L["Reset all guild bank mappings for %s"] = "已重置 %s 的所有公会银行映射。"
L["You are not currently in a guild."] = "你当前不在公会中。"
L["Reset all personal bank mappings for %s"] = "已重置 %s 的所有个人银行映射。"
L["Reset all Bagnon Consolidator mappings and ignore lists."] = "已重置所有 Bagnon Consolidator 映射和忽略列表。"
L["Bank or Guild Bank must be open to take a snapshot."] = "必须打开银行或公会银行才能创建快照。"
L["Unable to determine character name and realm."] = "无法获取角色名和服务器。"
L["Snapshot complete for Guild Bank: %s (%d items mapped, %d conflicts, %d ignored)."] = "公会银行快照完成：%s（已映射 %d 个物品，%d 个冲突，%d 个已忽略）。"
L["Snapshot complete for Personal Bank: %s (%d items mapped, %d ignored)."] = "个人银行快照完成：%s（已映射 %d 个物品，%d 个已忽略）。"
L["Cannot consolidate in combat."] = "战斗中无法进行整合。"
L["Bank or Guild Bank must be open and active."] = "银行或公会银行必须处于打开并可用状态。"
L["Consolidation is already in progress."] = "整合正在进行中。"
L["Consolidation complete."] = "整合完成。"
L["Consolidation stopped: %s"] = "整合已停止：%s"
L["No items need consolidation."] = "没有需要整合的物品。"

-- Conflict & Ignore Reasons
L["Present in both Personal Bank and Guild Bank"] = "同时存在于个人银行和公会银行"
L["Present on multiple Guild Bank tabs"] = "存在于多个公会银行标签页"
L["Present in personal bank of %s"] = "存在于 %s 的个人银行中"
L["Item has conflicting destinations."] = "物品存在冲突的目的地。"
L["Multiple destinations"] = "多个目的地"
L["Conflict (Go Nowhere)"] = "冲突（不移动）"
L["Ignored (Never Deposit)"] = "已忽略（从不存入）"
L["%s: %s (Skipped)."] = "%s：%s（已跳过）。"
L["%s has conflicting destinations (Skipped)."] = "%s 存在冲突的目的地（已跳过）。"

-- Viewer & Management UI
L["Bagnon Consolidator: Mappings"] = "Bagnon Consolidator：映射"
L["Personal"] = "个人"
L["Guild Bank >"] = "公会银行 >"
L["Select Guild Bank Tab"] = "选择公会银行标签页"
L["Tab %d"] = "标签 %d"
L["Tab %d >"] = "标签 %d >"
L["Tab %d: %s"] = "标签 %d：%s"
L["Tab %d:"] = "标签 %d："
L["Personal (%d)"] = "个人 (%d)"
L["Conflicts (%d)"] = "冲突 (%d)"
L["Ignored (%d)"] = "已忽略 (%d)"
L["Conflicts"] = "冲突"
L["Ignored"] = "已忽略"
L["Personal Bank Header"] = "|cff82c5ff个人银行：|r %s"
L["Guild Bank Header Custom"] = "|cff82c5ff公会银行：|r 标签 %d：%s"
L["Guild Bank Header"] = "|cff82c5ff公会银行：|r 标签 %d"
L["Conflicts Header"] = "|cffffcc00冲突：|r 拥有多个目的地的物品（不移动）"
L["Ignored Header"] = "|cffff8888已忽略：|r 排除在整合之外的物品"
L["Filter by name/ID"] = "按名称/ID过滤"
L["Showing %d items"] = "显示 %d 个物品"
L["Showing 0 items"] = "显示 0 个物品"
L["Ignored - will not consolidate"] = "已忽略 - 不会整合"
L["Conflict: %s"] = "冲突：%s"
L["Restore"] = "恢复"
L["Clear"] = "清除"
L["Ignore [X]"] = "忽略 [X]"
L["Remove"] = "移除"
L["Item ID: %d"] = "物品 ID：%d"
L["Item %d"] = "物品 %d"
L["%s moved to Ignored list."] = "%s 已移至忽略列表。"
L["%s removed from Ignored list (can be re-learned on next snapshot)."] = "%s 已从忽略列表中移除（将在下次快照时重新记录）。"
L["%s conflict cleared."] = "%s 冲突已清除。"

-- Options Panel
L["Options Description"] = "根据你的银行快照，自动将背包中的物品堆叠存入个人银行或公会银行并进行整合。"
