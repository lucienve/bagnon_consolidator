--[[
	Bagnon Consolidator - Snapshot Ingestion & Reset Engine
	Author: LVE
	All Rights Reserved
--]]

---@type string, BagnonAddon
local ADDON, Addon = (...):match('[^_]+'), _G[(...):match('[^_]+')]
local L = Addon.L or LibStub('AceLocale-3.0'):GetLocale('Bagnon_Consolidator')
local MAX_GUILDBANK_TABS = MAX_GUILDBANK_TABS or 8

-- Static Popup Registration
StaticPopupDialogs["BAGNON_CONSOLIDATOR_RESET_CONFIRM"] = {
	text = L["RESET_CONFIRM_DIALOG"],
	button1 = L["Yes"],
	button2 = L["No"],
	OnAccept = function(self, data)
		if Addon.ResetMappings then
			Addon.ResetMappings(data)
		end
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

local function ResetMappings(scope)
	if not BagnonConsolidatorDB then return end

	if scope == "guild" then
		local guildKey = Addon.GetGuildKey and Addon.GetGuildKey()
		if guildKey then
			BagnonConsolidatorDB.guildTabs[guildKey] = {}
			if BagnonConsolidatorDB.conflicts then
				BagnonConsolidatorDB.conflicts[guildKey] = {}
			end
			Addon.Print(string.format(L["Reset all guild bank mappings for %s"], guildKey))
		else
			Addon.Print(L["You are not currently in a guild."])
		end
	elseif scope == "personal" then
		local charKey = Addon.GetCharacterKey and Addon.GetCharacterKey()
		if charKey then
			BagnonConsolidatorDB.personalBanks[charKey] = {}
			if BagnonConsolidatorDB.conflicts then
				BagnonConsolidatorDB.conflicts[charKey] = {}
			end
			Addon.Print(string.format(L["Reset all personal bank mappings for %s"], charKey))
		end
	elseif scope == "all" then
		BagnonConsolidatorDB.guildTabs = {}
		BagnonConsolidatorDB.personalBanks = {}
		BagnonConsolidatorDB.ignored = {}
		BagnonConsolidatorDB.conflicts = {}
		Addon.Print(L["Reset all Bagnon Consolidator mappings and ignore lists."])
	end

	if Addon.Viewer and Addon.Viewer.Refresh then
		Addon.Viewer:Refresh()
	end
end

local function TakeSnapshot(targetFrame)
	if not BagnonConsolidatorDB then return false end

	local frame = targetFrame
	if not frame then
		if Addon.Frames:IsShown('guild') then
			frame = Addon.Frames:Get('guild')
		elseif Addon.Frames:IsShown('bank') then
			frame = Addon.Frames:Get('bank')
		end
	end

	if not frame then
		Addon.Print(L["Bank or Guild Bank must be open to take a snapshot."])
		return false
	end

	local isGuild = (frame.id == 'guild')

	if isGuild then
		local guildKey = Addon.GetGuildKey and Addon.GetGuildKey()
		if not guildKey then
			Addon.Print(L["You are not currently in a guild."])
			return false
		end

		BagnonConsolidatorDB.guildTabs[guildKey] = BagnonConsolidatorDB.guildTabs[guildKey] or {}
		BagnonConsolidatorDB.tabNames = BagnonConsolidatorDB.tabNames or {}
		BagnonConsolidatorDB.tabNames[guildKey] = BagnonConsolidatorDB.tabNames[guildKey] or {}
		BagnonConsolidatorDB.conflicts[guildKey] = BagnonConsolidatorDB.conflicts[guildKey] or {}

		local observedTabs = {}
		local itemCache = {}

		for tab = 1, MAX_GUILDBANK_TABS do
			local tName = GetGuildBankTabInfo and GetGuildBankTabInfo(tab)
			if tName and tName ~= "" then
				BagnonConsolidatorDB.tabNames[guildKey][tab] = tName
			end
			local bagInfo = frame:GetBagInfo(tab)
			local items = bagInfo and bagInfo.items
			if items then
				for slot in pairs(items) do
					local item = frame:Super(Addon.Guild):GetItemInfo(tab, slot)
					if item and item ~= Addon.None and item.itemID then
						local id = item.itemID
						observedTabs[id] = observedTabs[id] or {}
						observedTabs[id][tab] = true
						if not itemCache[id] then
							itemCache[id] = item
						end
					end
				end
			end
		end

		local mappedCount = 0
		local conflictCount = 0
		local skippedIgnoredCount = 0

		for id, tabs in pairs(observedTabs) do
			local item = itemCache[id]
			local itemName = item and Addon.GetItemName and Addon.GetItemName(item) or string.format(L["Item %d"], id)

			if BagnonConsolidatorDB.ignored and BagnonConsolidatorDB.ignored[id] then
				skippedIgnoredCount = skippedIgnoredCount + 1
				Addon.Debug("Snapshot: Skipped ignored item " .. itemName .. " (" .. id .. ")")
			elseif Addon.IsItemInAnyPersonalBank and Addon.IsItemInAnyPersonalBank(id) then
				local tabList = {}
				for t in pairs(tabs) do tinsert(tabList, t) end
				BagnonConsolidatorDB.conflicts[guildKey][id] = {
					name = itemName,
					personal = true,
					tabs = tabList,
					reason = L["Present in both Personal Bank and Guild Bank"]
				}
				BagnonConsolidatorDB.guildTabs[guildKey][id] = nil
				conflictCount = conflictCount + 1
				Addon.Debug("Snapshot: Conflict for " .. itemName .. " (in personal & guild bank)")
			else
				local tabCount = 0
				local targetTab
				local tabList = {}
				for t in pairs(tabs) do
					tabCount = tabCount + 1
					targetTab = t
					tinsert(tabList, t)
				end

				if tabCount > 1 then
					BagnonConsolidatorDB.conflicts[guildKey][id] = {
						name = itemName,
						personal = false,
						tabs = tabList,
						reason = L["Present on multiple Guild Bank tabs"]
					}
					BagnonConsolidatorDB.guildTabs[guildKey][id] = nil
					conflictCount = conflictCount + 1
					Addon.Debug("Snapshot: Multi-tab conflict for " .. itemName)
				elseif tabCount == 1 and targetTab then
					BagnonConsolidatorDB.conflicts[guildKey][id] = nil
					local tabName = GetGuildBankTabInfo(targetTab)
					BagnonConsolidatorDB.guildTabs[guildKey][id] = {
						tab = targetTab,
						name = itemName,
						tabName = tabName
					}
					mappedCount = mappedCount + 1
				end
			end
		end

		Addon.Print(string.format(L["Snapshot complete for Guild Bank: %s (%d items mapped, %d conflicts, %d ignored)."], guildKey, mappedCount, conflictCount, skippedIgnoredCount))
	else
		local charKey = Addon.GetCharacterKey and Addon.GetCharacterKey()
		if not charKey then
			Addon.Print(L["Unable to determine character name and realm."])
			return false
		end

		BagnonConsolidatorDB.personalBanks[charKey] = BagnonConsolidatorDB.personalBanks[charKey] or {}
		BagnonConsolidatorDB.conflicts[charKey] = BagnonConsolidatorDB.conflicts[charKey] or {}

		local mappedCount = 0
		local skippedIgnoredCount = 0

		if Addon.BankBags then
			for _, bag in ipairs(Addon.BankBags) do
				for slot = 1, frame:NumSlots(bag) do
					local item = frame:GetItemInfo(bag, slot)
					if item and item ~= Addon.None and item.itemID then
						local id = item.itemID --[[@as number]]
						local itemName = Addon.GetItemName and Addon.GetItemName(item) or string.format(L["Item %d"], id)

						if BagnonConsolidatorDB.ignored and BagnonConsolidatorDB.ignored[id] then
							skippedIgnoredCount = skippedIgnoredCount + 1
						else
							if BagnonConsolidatorDB.personalBanks and BagnonConsolidatorDB.personalBanks[charKey] then
								BagnonConsolidatorDB.personalBanks[charKey][id] = itemName
								mappedCount = mappedCount + 1
							end

							if BagnonConsolidatorDB.guildTabs then
								for gKey, gItems in pairs(BagnonConsolidatorDB.guildTabs) do
									if gItems and gItems[id] then
										gItems[id] = nil
										if BagnonConsolidatorDB.conflicts then
											BagnonConsolidatorDB.conflicts[gKey] = BagnonConsolidatorDB.conflicts[gKey] or {}
											BagnonConsolidatorDB.conflicts[gKey][id] = {
												name = itemName,
												personal = true,
												reason = string.format(L["Present in personal bank of %s"], tostring(charKey))
											}
										end
									end
								end
							end
						end
					end
				end
			end
		end

		Addon.Print(string.format(L["Snapshot complete for Personal Bank: %s (%d items mapped, %d ignored)."], charKey, mappedCount, skippedIgnoredCount))
	end

	if Addon.Viewer and Addon.Viewer.Refresh then
		Addon.Viewer:Refresh()
	end

	return true
end

Addon.TakeSnapshot = TakeSnapshot
Addon.ResetMappings = ResetMappings
