--[[
	Bagnon Consolidator - Consolidation Engine
	Author: LVE
	All Rights Reserved
--]]

---@type string, BagnonAddon
local ADDON, Addon = (...):match('[^_]+'), _G[(...):match('[^_]+')]
local LibItemMove = LibStub('LibItemMove-1.0') --[[@as LibItemMove]]
local L = Addon.L or LibStub('AceLocale-3.0'):GetLocale('Bagnon_Consolidator')
local KEYRING_CONTAINER = KEYRING_CONTAINER or -2

local Engine = {}
Addon.ConsolidateEngine = Engine

local isConsolidating = false

function Engine:Start(frame)
	if isConsolidating then
		Addon.Print(L["Consolidation is already in progress."])
		return
	end

	local isGuild = frame.id == 'guild'
	local backpackMatches = {}
	local warnedIgnored = {}
	local warnedConflicts = {}

	local guildKey = isGuild and Addon.GetGuildKey and Addon.GetGuildKey() or nil
	local charKey = (not isGuild) and Addon.GetCharacterKey and Addon.GetCharacterKey() or nil

	-- Scan Backpack to find matching items
	if Addon.InventoryBags then
		for _, bag in ipairs(Addon.InventoryBags) do
			if bag ~= KEYRING_CONTAINER then
				for slot = 1, Addon.Inventory:NumSlots(bag) do
					local item = Addon.Inventory:GetItemInfo(bag, slot)
					if item and item ~= Addon.None and item.itemID then
						local id = item.itemID --[[@as number]]

						if BagnonConsolidatorDB.ignored and BagnonConsolidatorDB.ignored[id] then
							if not warnedIgnored[id] then
								warnedIgnored[id] = true
								Addon.Debug("Skipping ignored item: " .. (item.hyperlink or tostring(id)))
							end
						elseif isGuild then
							if BagnonConsolidatorDB.conflicts and BagnonConsolidatorDB.conflicts[guildKey] and BagnonConsolidatorDB.conflicts[guildKey][id] then
								if not warnedConflicts[id] then
									warnedConflicts[id] = true
									local link = item.hyperlink or ("item:" .. id)
									local reason = BagnonConsolidatorDB.conflicts[guildKey][id].reason or L["Item has conflicting destinations."]
									Addon.Print(string.format(L["%s: %s (Skipped)."], link, reason))
								end
							else
								local entry = guildKey and BagnonConsolidatorDB.guildTabs[guildKey] and BagnonConsolidatorDB.guildTabs[guildKey][id]
								local targetTab = entry and entry.tab
								if targetTab then
									local _, _, _, canDeposit = GetGuildBankTabInfo(targetTab)
									if canDeposit then
										backpackMatches[id] = targetTab
									else
										Addon.Debug("Item ID " .. id .. " mapped to tab " .. targetTab .. " but lacks deposit permission.")
									end
								end
							end
						else
							if BagnonConsolidatorDB.conflicts and BagnonConsolidatorDB.conflicts[charKey] and BagnonConsolidatorDB.conflicts[charKey][id] then
								if not warnedConflicts[id] then
									warnedConflicts[id] = true
									local link = item.hyperlink or ("item:" .. id)
									Addon.Print(string.format(L["%s has conflicting destinations (Skipped)."], link))
								end
							else
								local mapped = charKey and BagnonConsolidatorDB.personalBanks[charKey] and BagnonConsolidatorDB.personalBanks[charKey][id]
								if mapped then
									backpackMatches[id] = true
								end
							end
						end
					end
				end
			end
		end
	end

	-- Build moveQueue and multiTabQueue
	local totalToMove = 0
	local multiTabQueue = {}
	local moveQueue = {}

	if isGuild then
		for _, bag in ipairs(Addon.InventoryBags) do
			if bag ~= KEYRING_CONTAINER then
				for slot = 1, Addon.Inventory:NumSlots(bag) do
					local item = Addon.Inventory:GetItemInfo(bag, slot)
					if item and item ~= Addon.None and item.itemID then
						local id = item.itemID
						local tab = backpackMatches[id]
						if tab then
							local itemKey = tostring(id)
							local count = item.stackCount or 1
							multiTabQueue[tab] = multiTabQueue[tab] or {}
							multiTabQueue[tab][itemKey] = (multiTabQueue[tab][itemKey] or 0) + count
							totalToMove = totalToMove + count
						end
					end
				end
			end
		end
	else
		for _, bag in ipairs(Addon.InventoryBags) do
			if bag ~= KEYRING_CONTAINER then
				for slot = 1, Addon.Inventory:NumSlots(bag) do
					local item = Addon.Inventory:GetItemInfo(bag, slot)
					if item and item ~= Addon.None and item.itemID then
						local id = item.itemID
						if backpackMatches[id] then
							local itemKey = tostring(id)
							local count = item.stackCount or 1
							moveQueue[itemKey] = (moveQueue[itemKey] or 0) + count
							totalToMove = totalToMove + count
						end
					end
				end
			end
		end
	end

	-- Dispatch to LibItemMove
	if totalToMove > 0 then
		isConsolidating = true
		local context = isGuild and "BagToGuildBank" or "BagToBank"
		local queue = isGuild and multiTabQueue or moveQueue

		Addon.Debug("Starting LibItemMove: context=" .. context .. ", totalToMove=" .. totalToMove)
		if LibItemMove then
			LibItemMove:Move(queue, context, function(event, ...)
				if event == "PROGRESS" then
					local itemString, qty = ...
					Addon.Debug("Consolidated: " .. tostring(itemString) .. " (Qty: " .. tostring(qty) .. ")")
				elseif event == "DONE" then
					isConsolidating = false
					PlaySound(SOUNDKIT.UI_BAG_SORTING_01)
					Addon.Print(L["Consolidation complete."])
				elseif event == "TIMEOUT_ERROR" or event == "CURSOR_LOCKED_ERROR" or event == "PERMISSION_ERROR" then
					isConsolidating = false
					PlaySound(847)
					Addon.Print(string.format(L["Consolidation stopped: %s"], tostring(event)))
				end
			end)
		end
	else
		PlaySound(847)
		Addon.Print(L["No items need consolidation."])
	end
end
