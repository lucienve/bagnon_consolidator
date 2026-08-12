--[[
	Bagnon Consolidator
	Auto-deposits and consolidates item stacks from your bags to the bank or guild bank.
	Author: LVE
	All Rights Reserved
--]]

---@type string, BagnonAddon
local ADDON, Addon = (...):match('[^_]+'), _G[(...):match('[^_]+')]
local C = LibStub('C_Everywhere')
local KEYRING_CONTAINER = KEYRING_CONTAINER or -2

local loaderFrame = CreateFrame("Frame")
loaderFrame:RegisterEvent("ADDON_LOADED")
loaderFrame:SetScript("OnEvent", function(self, event, name)
	if name == "Bagnon_Consolidator" then
		BagnonConsolidatorDB = BagnonConsolidatorDB or {}
		BagnonConsolidatorDB.guildTabs = BagnonConsolidatorDB.guildTabs or {}
		BagnonConsolidatorDB.personalBanks = BagnonConsolidatorDB.personalBanks or {}
		self:UnregisterEvent("ADDON_LOADED")
	end
end)

local function GetCharacterKey()
	local name = UnitName("player")
	local realm = GetRealmName()
	if not name or not realm then return nil end
	return name .. "-" .. realm
end

local function GetGuildKey()
	local guildName, _, _, guildRealm = GetGuildInfo("player")
	if not guildName then return nil end
	return guildName .. "-" .. (guildRealm or GetRealmName())
end

local function IsItemInAnyPersonalBank(itemID)
	if not BagnonConsolidatorDB or not BagnonConsolidatorDB.personalBanks then
		return false
	end
	for charKey, items in pairs(BagnonConsolidatorDB.personalBanks) do
		if items[itemID] then
			return true
		end
	end
	return false
end

local function GetItemName(item)
	if item.hyperlink then
		local name = item.hyperlink:match("%[(.-)%]")
		if name then return name end
	end
	if item.itemID then
		local name = C.C_Item.GetItemInfo(item.itemID)
		if name then return name end
	end
	return "Unknown Item"
end

local function Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff82c5ffBagnon Consolidator:|r " .. msg)
end

local DEBUG = false
local function Debug(msg)
	if DEBUG then
		DEFAULT_CHAT_FRAME:AddMessage("|cff82c5ffBagnon Consolidator (Debug):|r " .. msg)
	end
end

local ConsolidateButton = Addon.Tipped:NewClass('ConsolidateButton', 'Button', 'BagnonButtonTemplate')

function ConsolidateButton:New(parent)
	local b = self:Super(ConsolidateButton):New(parent)
	b.Icon:SetTexture("Interface/Icons/Spell_ChargePositive")
	b:RegisterForClicks('anyUp')
	return b
end

function ConsolidateButton:OnEnter()
	self:ShowTooltip("Consolidate to Bank", "|cffbbbbbbFinds duplicate items in your bags and moves them to the open bank, consolidating stacks to save space.|r")
end

function ConsolidateButton:OnClick()
	if InCombatLockdown() then
		Print("Cannot consolidate in combat.")
		return
	end

	if Addon.Frames:IsShown('bank') then
		local bankFrame = Addon.Frames:Get('bank')
		if bankFrame and not bankFrame:IsCached() then
			Addon.ConsolidateEngine:Start(bankFrame)
			return
		end
	end

	if Addon.Frames:IsShown('guild') then
		local guildFrame = Addon.Frames:Get('guild')
		if guildFrame and not guildFrame:IsCached() then
			Addon.ConsolidateEngine:Start(guildFrame)
			return
		end
	end

	Print("Bank or Guild Bank must be open and active.")
end

-- Hook into Bagnon's Extra Buttons list
local origGetExtraButtons = Addon.Inventory.GetExtraButtons
function Addon.Inventory:GetExtraButtons()
	local buttons = origGetExtraButtons and origGetExtraButtons(self) or {}
	tinsert(buttons, self:GetWidget('ConsolidateButton'))
	return buttons
end

Addon.ConsolidateButton = ConsolidateButton


--[[ Consolidation Engine ]]--

local Engine = {}
Addon.ConsolidateEngine = Engine
local LibItemMove = LibStub('LibItemMove-1.0')

local isConsolidating = false

function Engine:Start(frame)
	if isConsolidating then
		Print("Consolidation is already in progress.")
		return
	end

	local isGuild = frame.id == 'guild'
	local itemTabs = {}
	local duplicateItems = {}
	local warnedPersonalItems = {}

	-- 1. Scan Bank container to find items and active tabs
	if isGuild then
		local itemCache = {}
		for tab = 1, MAX_GUILDBANK_TABS do
			local bagInfo = frame:GetBagInfo(tab)
			local items = bagInfo and bagInfo.items
			if items then
				for slot in pairs(items) do
					local item = frame:Super(Addon.Guild):GetItemInfo(tab, slot)
					if item and item ~= Addon.None and item.itemID then
						local id = item.itemID
						itemTabs[id] = itemTabs[id] or {}
						itemTabs[id][tab] = true
						if not itemCache[id] then
							itemCache[id] = item
						end
					end
				end
			end
		end

		local guildKey = GetGuildKey()
		if guildKey then
			BagnonConsolidatorDB.guildTabs[guildKey] = BagnonConsolidatorDB.guildTabs[guildKey] or {}
			for id, tabs in pairs(itemTabs) do
				local tabCount = 0
				local targetTab
				for tab in pairs(tabs) do
					tabCount = tabCount + 1
					targetTab = tab
				end
				if tabCount == 1 then
					if IsItemInAnyPersonalBank(id) then
						BagnonConsolidatorDB.guildTabs[guildKey][id] = nil
						Debug("Skipped adding item ID " .. id .. " to guildTabs because it exists in personal bank.")
					else
						local item = itemCache[id]
						local itemName = item and GetItemName(item) or "Unknown Item"
						local tabName = GetGuildBankTabInfo(targetTab)
						BagnonConsolidatorDB.guildTabs[guildKey][id] = {
							tab = targetTab,
							name = itemName,
							tabName = tabName
						}
					end
				elseif tabCount > 1 then
					BagnonConsolidatorDB.guildTabs[guildKey][id] = nil
				end
			end
		end
	else
		local charKey = GetCharacterKey()
		if charKey then
			BagnonConsolidatorDB.personalBanks[charKey] = BagnonConsolidatorDB.personalBanks[charKey] or {}
		end

		if Addon.BankBags then
			for _, bag in ipairs(Addon.BankBags) do
				for slot = 1, frame:NumSlots(bag) do
					local item = frame:GetItemInfo(bag, slot)
					if item and item ~= Addon.None and item.itemID then
						duplicateItems[item.itemID] = true
						if charKey then
							BagnonConsolidatorDB.personalBanks[charKey][item.itemID] = GetItemName(item)
						end
						if BagnonConsolidatorDB.guildTabs then
							for gKey, items in pairs(BagnonConsolidatorDB.guildTabs) do
								if items[item.itemID] then
									items[item.itemID] = nil
									Debug("Removed guild bank location for item ID " .. item.itemID .. " on " .. gKey)
								end
							end
						end
					end
				end
			end
		end
	end

	-- 2. Scan Backpack to find matching duplicate items
	local backpackMatches = {}
	if Addon.InventoryBags then
		for _, bag in ipairs(Addon.InventoryBags) do
			if bag ~= KEYRING_CONTAINER then
				for slot = 1, Addon.Inventory:NumSlots(bag) do
					local item = Addon.Inventory:GetItemInfo(bag, slot)
					if item and item ~= Addon.None and item.itemID then
						local id = item.itemID --[[@as number]]
						local match = false

						if isGuild then
							if IsItemInAnyPersonalBank(id) then
								if not warnedPersonalItems[id] then
									warnedPersonalItems[id] = true
									local link = item.hyperlink or ("item:" .. id)
									Print(link .. " has been designated as a personal bank item. Skipped guild bank consolidation.")
								end
							elseif itemTabs[id] then
								local tabCount = 0
								local targetTab
								for tab in pairs(itemTabs[id]) do
									tabCount = tabCount + 1
									targetTab = tab
								end
 
								if tabCount > 1 then
									local link = item.hyperlink or ("item:" .. id)
									Print(link .. " is present in multiple guild bank tabs. Skipped.")
									itemTabs[id] = nil
								elseif tabCount == 1 then
									match = true
									backpackMatches[id] = targetTab
								end
							elseif not backpackMatches[id] then
								local guildKey = GetGuildKey()
								local entry = guildKey and BagnonConsolidatorDB.guildTabs[guildKey] and BagnonConsolidatorDB.guildTabs[guildKey][id]
								local targetTab = entry and entry.tab
								if targetTab then
									local _, _, _, canDeposit = GetGuildBankTabInfo(targetTab)
									if canDeposit then
										itemTabs[id] = { [targetTab] = true }
										match = true
										backpackMatches[id] = targetTab
										Debug("Remembered tab " .. tostring(targetTab) .. " for item ID " .. tostring(id))
									else
										Debug("Remembered tab " .. tostring(targetTab) .. " for item ID " .. tostring(id) .. " but player lacks deposit permission.")
									end
								end
							end
						else
							local charKey = GetCharacterKey()
							local remembered = charKey and BagnonConsolidatorDB.personalBanks[charKey] and BagnonConsolidatorDB.personalBanks[charKey][id]
							if duplicateItems[id] or remembered then
								match = true
								backpackMatches[id] = true
							end
						end
					end
				end
			end
		end
	end

	-- 3. Build moveQueue and multiTabQueue
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

	-- 4. Dispatch to LibItemMove
	if totalToMove > 0 then
		isConsolidating = true
		local context = isGuild and "BagToGuildBank" or "BagToBank"
		local queue = isGuild and multiTabQueue or moveQueue

		Debug("Starting LibItemMove: context=" .. context .. ", totalToMove=" .. totalToMove)
		LibItemMove:Move(queue, context, function(event, ...)
			if event == "PROGRESS" then
				local itemString, qty = ...
				Debug("Consolidated: " .. tostring(itemString) .. " (Qty: " .. tostring(qty) .. ")")
			elseif event == "DONE" then
				isConsolidating = false
				PlaySound(SOUNDKIT.UI_BAG_SORTING_01)
				Print("Consolidation complete.")
			elseif event == "TIMEOUT_ERROR" or event == "CURSOR_LOCKED_ERROR" or event == "PERMISSION_ERROR" then
				isConsolidating = false
				PlaySound(847) -- Error sound
				Print("Consolidation stopped: " .. tostring(event))
			end
		end)
	else
		PlaySound(847) -- Error sound
		Print("No items need consolidation.")
	end
end
