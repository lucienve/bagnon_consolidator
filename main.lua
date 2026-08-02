--[[
	Bagnon Consolidator
	Auto-deposits and consolidates item stacks from your bags to the bank or guild bank.
	Author: LVE
	All Rights Reserved
--]]

local ADDON, Addon = (...):match('[^_]+'), _G[(...):match('[^_]+')]
local C = LibStub('C_Everywhere')

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
		return
	end
	local bankFrame = Addon.Frames:Get('bank')
	local guildFrame = Addon.Frames:Get('guild')

	if bankFrame and bankFrame:IsShown() and not bankFrame:IsCached() then
		Addon.ConsolidateEngine:Start(bankFrame)
	elseif guildFrame and guildFrame:IsShown() and not guildFrame:IsCached() then
		Addon.ConsolidateEngine:Start(guildFrame)
	else
		DEFAULT_CHAT_FRAME:AddMessage("|cff82c5ffBagnon Consolidator:|r Bank or Guild Bank must be open and active.")
	end
end

-- Hook into Bagnon's Extra Buttons list
local origGetExtraButtons = Addon.Inventory.GetExtraButtons
function Addon.Inventory:GetExtraButtons()
	local buttons = origGetExtraButtons(self) or {}
	tinsert(buttons, self:GetWidget('ConsolidateButton'))
	return buttons
end

Addon.ConsolidateButton = ConsolidateButton


--[[ Consolidation Queue and Engine ]]--

local Engine = {}
Addon.ConsolidateEngine = Engine

local Queue = { tasks = {}, running = false }

function Queue:Add(fromBag, fromSlot, toBag, toSlot)
	tinsert(self.tasks, {
		type = "move",
		fromBag = fromBag, fromSlot = fromSlot,
		toBag = toBag, toSlot = toSlot
	})
end

function Queue:AddTabSwitch(tab)
	tinsert(self.tasks, {
		type = "switch_tab",
		tab = tab
	})
end

local eventFrame = CreateFrame("Frame")
function Queue:WaitForEvent(event, callback)
	local triggered = false
	local function trigger()
		if not triggered then
			triggered = true
			eventFrame:UnregisterEvent(event)
			callback()
		end
	end

	eventFrame:RegisterEvent(event)
	eventFrame:SetScript("OnEvent", function(self, evt)
		if evt == event then
			trigger()
		end
	end)

	C_Timer.After(1.5, trigger) -- 1.5s timeout safety
end

local function IsSlotLocked(frame, bagOrTab, slot)
	local info = frame:GetItemInfo(bagOrTab, slot)
	return info and info ~= Addon.None and info.isLocked
end

function Queue:Start(frame)
	if self.running then return end
	self.frame = frame
	self.isGuild = frame.id == 'guild'
	self.running = true
	self:ProcessNext()
end

function Queue:Stop()
	self.running = false
	self.tasks = {}
	self.frame = nil
end

function Queue:ProcessNext()
	if not self.running then return end

	if not self.frame or not self.frame:IsShown() or InCombatLockdown() then
		self:Stop()
		return
	end

	if #self.tasks == 0 then
		self:Stop()
		PlaySound(SOUNDKIT.UI_BAG_SORTING_01)
		DEFAULT_CHAT_FRAME:AddMessage("|cff82c5ffBagnon Consolidator:|r Consolidation complete.")
		return
	end

	local task = self.tasks[1]

	if task.type == "switch_tab" then
		if GetCurrentGuildBankTab() == task.tab then
			tremove(self.tasks, 1)
			self:ProcessNext()
		else
			SetCurrentGuildBankTab(task.tab)
			self:WaitForEvent("GUILDBANKBAGSLOTS_CHANGED", function()
				tremove(self.tasks, 1)
				self:ProcessNext()
			end)
		end
		return
	end

	if task.type == "move" then
		if IsSlotLocked(self.frame, task.fromBag, task.fromSlot) or IsSlotLocked(self.frame, task.toBag, task.toSlot) then
			C_Timer.After(0.1, function() self:ProcessNext() end)
			return
		end

		tremove(self.tasks, 1)

		self.frame.PickupItem(task.fromBag, task.fromSlot)
		self.frame.PickupItem(task.toBag, task.toSlot)

		local eventName = self.isGuild and "GUILDBANKBAGSLOTS_CHANGED" or "BAG_UPDATE_DELAYED"
		self:WaitForEvent(eventName, function()
			self:ProcessNext()
		end)
	end
end

local function SimulateMove(from, to, maxStack)
	local space = maxStack - to.count
	if from.count <= space then
		Queue:Add(from.bag, from.slot, to.bag, to.slot)
		to.count = to.count + from.count
		from.count = 0
	else
		Queue:Add(from.bag, from.slot, to.bag, to.slot)
		to.count = maxStack
		from.count = from.count - space
	end
end

local function ConsolidateItem(itemID, maxStack, bankSlots, bagSlots, emptyBankSlots)
	-- Sort ascending by item count to consolidate smaller stacks first
	table.sort(bankSlots, function(a, b) return a.count < b.count end)
	table.sort(bagSlots, function(a, b) return a.count < b.count end)

	-- 1. Pre-consolidate Bank (Destination)
	if #bankSlots > 1 then
		local i = 1
		local j = #bankSlots
		while i < j do
			local small = bankSlots[i]
			local large = bankSlots[j]
			if large.count < maxStack then
				SimulateMove(small, large, maxStack)
				if small.count == 0 then
					i = i + 1
				end
				if large.count == maxStack then
					j = j - 1
				end
			else
				j = j - 1
			end
		end
		local temp = {}
		for _, slot in ipairs(bankSlots) do
			if slot.count > 0 then
				tinsert(temp, slot)
			else
				tinsert(emptyBankSlots, slot)
			end
		end
		bankSlots = temp
		table.sort(bankSlots, function(a, b) return a.count < b.count end)
	end

	-- 2. Pre-consolidate Backpack (Source)
	if #bagSlots > 1 then
		local i = 1
		local j = #bagSlots
		while i < j do
			local small = bagSlots[i]
			local large = bagSlots[j]
			if large.count < maxStack then
				SimulateMove(small, large, maxStack)
				if small.count == 0 then
					i = i + 1
				end
				if large.count == maxStack then
					j = j - 1
				end
			else
				j = j - 1
			end
		end
		local temp = {}
		for _, slot in ipairs(bagSlots) do
			if slot.count > 0 then
				tinsert(temp, slot)
			end
		end
		bagSlots = temp
		table.sort(bagSlots, function(a, b) return a.count < b.count end)
	end

	-- 3. Cross-Container Merge
	for _, bankSlot in ipairs(bankSlots) do
		if bankSlot.count < maxStack then
			for _, bagSlot in ipairs(bagSlots) do
				if bagSlot.count > 0 then
					SimulateMove(bagSlot, bankSlot, maxStack)
					if bankSlot.count == maxStack then
						break
					end
				end
			end
		end
	end

	-- 4. Move remaining backpack stacks to empty bank slots
	for _, bagSlot in ipairs(bagSlots) do
		if bagSlot.count > 0 then
			if #emptyBankSlots > 0 then
				local emptySlot = tremove(emptyBankSlots, 1)
				Queue:Add(bagSlot.bag, bagSlot.slot, emptySlot.bag, emptySlot.slot)
				emptySlot.count = bagSlot.count
				bagSlot.count = 0
			else
				break
			end
		end
	end
end

function Engine:Start(frame)
	if Queue.running then return end

	local isGuild = frame.id == 'guild'
	local itemTabs = {}
	local duplicateItems = {}

	-- 1. Scan Bank container to find items and active tabs
	if isGuild then
		for tab = 1, 8 do
			local bagInfo = frame:GetBagInfo(tab)
			local items = bagInfo and bagInfo.items
			if items then
				for slot, data in pairs(items) do
					local id
					if data:sub(1,9) == 'battlepet' then
						id = tonumber(data:match(':(%d+):%d+:%d+'))
					elseif data:sub(1,9) == 'keystone:' then
						id = tonumber(data:match(':(%d+)'))
					else
						local values = strsplit(';', data)
						id = tonumber(values:match('^(%d+)')) or tonumber(values:match('item:(%d+)'))
						if not id then
							id = select(1, C.GetItemInfoInstant('item:' .. values))
						end
					end
					if id then
						itemTabs[id] = itemTabs[id] or {}
						itemTabs[id][tab] = true
					end
				end
			end
		end
	else
		for _, bag in ipairs(Addon.BankBags) do
			for slot = 1, frame:NumSlots(bag) do
				local item = frame:GetItemInfo(bag, slot)
				if item and item ~= Addon.None and item.itemID then
					duplicateItems[item.itemID] = true
				end
			end
		end
	end

	-- 2. Scan Backpack to find matching duplicate items
	local backpackMatches = {}
	for _, bag in ipairs(Addon.InventoryBags) do
		for slot = 1, Addon.Inventory:NumSlots(bag) do
			local item = Addon.Inventory:GetItemInfo(bag, slot)
			if item and item ~= Addon.None and item.itemID then
				local id = item.itemID
				local match = false

				if isGuild then
					if itemTabs[id] then
						local tabCount = 0
						local targetTab
						for tab in pairs(itemTabs[id]) do
							tabCount = tabCount + 1
							targetTab = tab
						end

						if tabCount > 1 then
							local link = item.hyperlink or ("item:" .. id)
							DEFAULT_CHAT_FRAME:AddMessage("|cff82c5ffBagnon Consolidator:|r " .. link .. " is present in multiple guild bank tabs. Skipped.")
							itemTabs[id] = nil
						elseif tabCount == 1 then
							match = true
							backpackMatches[id] = targetTab
						end
					end
				else
					if duplicateItems[id] then
						match = true
						backpackMatches[id] = true
					end
				end
			end
		end
	end

	-- 3. Build Tasks
	Queue.tasks = {}

	if isGuild then
		local tabTasks = {}
		for tab = 1, 8 do
			tabTasks[tab] = {}
		end

		for itemID, tab in pairs(backpackMatches) do
			if itemTabs[itemID] then
				tinsert(tabTasks[tab], itemID)
			end
		end

		for tab, items in ipairs(tabTasks) do
			if #items > 0 then
				Queue:AddTabSwitch(tab)

				local emptySlots = {}
				for slot = 1, 98 do
					local item = frame:Super(Addon.Guild):GetItemInfo(tab, slot)
					if not item or item == Addon.None or not item.itemID then
						tinsert(emptySlots, { bag = tab, slot = slot, count = 0 })
					end
				end

				for _, itemID in ipairs(items) do
					local bankSlots = {}
					for slot = 1, 98 do
						local item = frame:Super(Addon.Guild):GetItemInfo(tab, slot)
						if item and item ~= Addon.None and item.itemID == itemID then
							tinsert(bankSlots, { bag = tab, slot = slot, count = item.stackCount or 1 })
						end
					end

					local bagSlots = {}
					local maxStack = 20
					for _, bag in ipairs(Addon.InventoryBags) do
						for slot = 1, Addon.Inventory:NumSlots(bag) do
							local item = Addon.Inventory:GetItemInfo(bag, slot)
							if item and item ~= Addon.None and item.itemID == itemID then
								tinsert(bagSlots, { bag = bag, slot = slot, count = item.stackCount or 1 })
								if item.hyperlink then
									maxStack = select(8, C.GetItemInfo(item.hyperlink)) or maxStack
								end
							end
						end
					end

					ConsolidateItem(itemID, maxStack, bankSlots, bagSlots, emptySlots)
				end
			end
		end
	else
		local emptySlots = {}
		for _, bag in ipairs(Addon.BankBags) do
			for slot = 1, frame:NumSlots(bag) do
				local item = frame:GetItemInfo(bag, slot)
				if not item or item == Addon.None or not item.itemID then
					tinsert(emptySlots, { bag = bag, slot = slot, count = 0 })
				end
			end
		end

		for itemID in pairs(backpackMatches) do
			local bankSlots = {}
			for _, bag in ipairs(Addon.BankBags) do
				for slot = 1, frame:NumSlots(bag) do
					local item = frame:GetItemInfo(bag, slot)
					if item and item ~= Addon.None and item.itemID == itemID then
						tinsert(bankSlots, { bag = bag, slot = slot, count = item.stackCount or 1 })
					end
				end
			end

			local bagSlots = {}
			local maxStack = 20
			for _, bag in ipairs(Addon.InventoryBags) do
				for slot = 1, Addon.Inventory:NumSlots(bag) do
					local item = Addon.Inventory:GetItemInfo(bag, slot)
					if item and item ~= Addon.None and item.itemID == itemID then
						tinsert(bagSlots, { bag = bag, slot = slot, count = item.stackCount or 1 })
						if item.hyperlink then
							maxStack = select(8, C.GetItemInfo(item.hyperlink)) or maxStack
						end
					end
				end
			end

			ConsolidateItem(itemID, maxStack, bankSlots, bagSlots, emptySlots)
		end
	end

	if #Queue.tasks > 0 then
		Queue:Start(frame)
	else
		PlaySound(847) -- Error sound
		DEFAULT_CHAT_FRAME:AddMessage("|cff82c5ffBagnon Consolidator:|r No items need consolidation.")
	end
end
