--[[
	Bagnon Consolidator
	Auto-deposits and consolidates item stacks from your bags to the bank or guild bank.
	Author: LVE
	All Rights Reserved
--]]

---@type string, BagnonAddon
local ADDON, Addon = (...):match('[^_]+'), _G[(...):match('[^_]+')]
local C = LibStub('C_Everywhere')
local LibItemMove = LibStub('LibItemMove-1.0')
local KEYRING_CONTAINER = KEYRING_CONTAINER or -2

local loaderFrame = CreateFrame("Frame")
loaderFrame:RegisterEvent("ADDON_LOADED")
loaderFrame:SetScript("OnEvent", function(self, event, name)
	if name == "Bagnon_Consolidator" then
		BagnonConsolidatorDB = BagnonConsolidatorDB or {}
		BagnonConsolidatorDB.guildTabs = BagnonConsolidatorDB.guildTabs or {}
		BagnonConsolidatorDB.tabNames = BagnonConsolidatorDB.tabNames or {}
		BagnonConsolidatorDB.personalBanks = BagnonConsolidatorDB.personalBanks or {}
		BagnonConsolidatorDB.ignored = BagnonConsolidatorDB.ignored or {}
		BagnonConsolidatorDB.conflicts = BagnonConsolidatorDB.conflicts or {}
		if BagnonConsolidatorDB.enableDebug == nil then
			BagnonConsolidatorDB.enableDebug = false
		end
		LibItemMove.Debug = BagnonConsolidatorDB.enableDebug
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
	for _, items in pairs(BagnonConsolidatorDB.personalBanks) do
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

local function Debug(msg)
	if BagnonConsolidatorDB and BagnonConsolidatorDB.enableDebug then
		DEFAULT_CHAT_FRAME:AddMessage("|cff82c5ffBagnon Consolidator (Debug):|r " .. msg)
	end
end

-- Export helpers
Addon.GetCharacterKey = GetCharacterKey
Addon.GetGuildKey = GetGuildKey
Addon.GetItemName = GetItemName
Addon.Print = Print
Addon.Debug = Debug

-- Static Popup Registration
StaticPopupDialogs["BAGNON_CONSOLIDATOR_RESET_CONFIRM"] = {
	text = "Are you sure you want to reset all stored mappings for %s?",
	button1 = "Yes",
	button2 = "No",
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
		local guildKey = GetGuildKey()
		if guildKey then
			BagnonConsolidatorDB.guildTabs[guildKey] = {}
			if BagnonConsolidatorDB.conflicts then
				BagnonConsolidatorDB.conflicts[guildKey] = {}
			end
			Print("Reset all guild bank mappings for " .. guildKey)
		else
			Print("You are not currently in a guild.")
		end
	elseif scope == "personal" then
		local charKey = GetCharacterKey()
		if charKey then
			BagnonConsolidatorDB.personalBanks[charKey] = {}
			if BagnonConsolidatorDB.conflicts then
				BagnonConsolidatorDB.conflicts[charKey] = {}
			end
			Print("Reset all personal bank mappings for " .. charKey)
		end
	elseif scope == "all" then
		BagnonConsolidatorDB.guildTabs = {}
		BagnonConsolidatorDB.personalBanks = {}
		BagnonConsolidatorDB.ignored = {}
		BagnonConsolidatorDB.conflicts = {}
		Print("Reset all Bagnon Consolidator mappings and ignore lists.")
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
		Print("Bank or Guild Bank must be open to take a snapshot.")
		return false
	end

	local isGuild = (frame.id == 'guild')

	if isGuild then
		local guildKey = GetGuildKey()
		if not guildKey then
			Print("You are not currently in a guild.")
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
			local itemName = item and GetItemName(item) or ("Item " .. id)

			if BagnonConsolidatorDB.ignored and BagnonConsolidatorDB.ignored[id] then
				skippedIgnoredCount = skippedIgnoredCount + 1
				Debug("Snapshot: Skipped ignored item " .. itemName .. " (" .. id .. ")")
			elseif IsItemInAnyPersonalBank(id) then
				local tabList = {}
				for t in pairs(tabs) do tinsert(tabList, t) end
				BagnonConsolidatorDB.conflicts[guildKey][id] = {
					name = itemName,
					personal = true,
					tabs = tabList,
					reason = "Present in both Personal Bank and Guild Bank"
				}
				BagnonConsolidatorDB.guildTabs[guildKey][id] = nil
				conflictCount = conflictCount + 1
				Debug("Snapshot: Conflict for " .. itemName .. " (in personal & guild bank)")
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
						reason = "Present on multiple Guild Bank tabs"
					}
					BagnonConsolidatorDB.guildTabs[guildKey][id] = nil
					conflictCount = conflictCount + 1
					Debug("Snapshot: Multi-tab conflict for " .. itemName)
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

		Print(string.format("Snapshot complete for Guild Bank: %s (%d items mapped, %d conflicts, %d ignored).", guildKey, mappedCount, conflictCount, skippedIgnoredCount))
	else
		local charKey = GetCharacterKey()
		if not charKey then
			Print("Unable to determine character name and realm.")
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
						local itemName = GetItemName(item)

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
												reason = "Present in personal bank of " .. tostring(charKey)
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

		Print(string.format("Snapshot complete for Personal Bank: %s (%d items mapped, %d ignored).", charKey, mappedCount, skippedIgnoredCount))
	end

	if Addon.Viewer and Addon.Viewer.Refresh then
		Addon.Viewer:Refresh()
	end

	return true
end

Addon.TakeSnapshot = TakeSnapshot
Addon.ResetMappings = ResetMappings

local ConsolidateButton = Addon.Tipped:NewClass('ConsolidateButton', 'Button', 'BagnonButtonTemplate')

function ConsolidateButton:New(parent)
	local b = self:Super(ConsolidateButton):New(parent)
	b.Icon:SetTexture("Interface/Icons/Spell_ChargePositive")
	b:RegisterForClicks('anyUp')
	return b
end

function ConsolidateButton:OnEnter()
	self:ShowTooltip(
		"Consolidate to Bank",
		"|cffbbbbbbFinds duplicate items in your bags and moves them to the open bank, consolidating stacks to save space.|r",
		"|R Options / Mappings"
	)
end

function ConsolidateButton:OnClick(button)
	if button == "RightButton" then
		MenuUtil.CreateContextMenu(self, function(_, menu)
			menu:SetTag("BagnonConsolidatorOptions")
			menu:CreateTitle("Bagnon Consolidator")

			menu:CreateButton("Open Mappings Viewer...", function()
				if Addon.Viewer and Addon.Viewer.Toggle then
					Addon.Viewer:Toggle()
				end
			end)

			menu:CreateButton("Take Snapshot", function()
				TakeSnapshot()
			end)

			menu:CreateButton("Reset Mappings...", function()
				local scope = "all"
				local label = "everything"
				if Addon.Frames:IsShown('guild') then
					scope = "guild"
					label = GetGuildKey() or "Guild Bank"
				elseif Addon.Frames:IsShown('bank') then
					scope = "personal"
					label = GetCharacterKey() or "Personal Bank"
				end
				StaticPopup_Show("BAGNON_CONSOLIDATOR_RESET_CONFIRM", label, nil, scope)
			end)

			menu:CreateDivider()

			menu:CreateCheckbox("Enable Debug Logs",
				function() return BagnonConsolidatorDB and BagnonConsolidatorDB.enableDebug or false end,
				function()
					BagnonConsolidatorDB.enableDebug = not BagnonConsolidatorDB.enableDebug
					LibItemMove.Debug = BagnonConsolidatorDB.enableDebug
				end)
		end)
		return
	end

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

local isConsolidating = false

function Engine:Start(frame)
	if isConsolidating then
		Print("Consolidation is already in progress.")
		return
	end

	local isGuild = frame.id == 'guild'
	local backpackMatches = {}
	local warnedIgnored = {}
	local warnedConflicts = {}

	local guildKey = isGuild and GetGuildKey() or nil
	local charKey = (not isGuild) and GetCharacterKey() or nil

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
								Debug("Skipping ignored item: " .. (item.hyperlink or tostring(id)))
							end
						elseif isGuild then
							if BagnonConsolidatorDB.conflicts and BagnonConsolidatorDB.conflicts[guildKey] and BagnonConsolidatorDB.conflicts[guildKey][id] then
								if not warnedConflicts[id] then
									warnedConflicts[id] = true
									local link = item.hyperlink or ("item:" .. id)
									local reason = BagnonConsolidatorDB.conflicts[guildKey][id].reason or "Item has conflicting destinations."
									Print(link .. ": " .. reason .. " (Skipped).")
								end
							else
								local entry = guildKey and BagnonConsolidatorDB.guildTabs[guildKey] and BagnonConsolidatorDB.guildTabs[guildKey][id]
								local targetTab = entry and entry.tab
								if targetTab then
									local _, _, _, canDeposit = GetGuildBankTabInfo(targetTab)
									if canDeposit then
										backpackMatches[id] = targetTab
									else
										Debug("Item ID " .. id .. " mapped to tab " .. targetTab .. " but lacks deposit permission.")
									end
								end
							end
						else
							if BagnonConsolidatorDB.conflicts and BagnonConsolidatorDB.conflicts[charKey] and BagnonConsolidatorDB.conflicts[charKey][id] then
								if not warnedConflicts[id] then
									warnedConflicts[id] = true
									local link = item.hyperlink or ("item:" .. id)
									Print(link .. " has conflicting destinations (Skipped).")
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
				PlaySound(847)
				Print("Consolidation stopped: " .. tostring(event))
			end
		end)
	else
		PlaySound(847)
		Print("No items need consolidation.")
	end
end
