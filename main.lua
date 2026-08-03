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


--[[ Consolidation Queue and Engine ]]--

local Engine = {}
Addon.ConsolidateEngine = Engine

local Queue = { tasks = {}, running = false }

function Queue:Add(fromBag, fromSlot, fromIsGuild, toBag, toSlot, toIsGuild, expectedCount)
	tinsert(self.tasks, {
		type = "move",
		fromBag = fromBag, fromSlot = fromSlot, fromIsGuild = not not fromIsGuild,
		toBag = toBag, toSlot = toSlot, toIsGuild = not not toIsGuild,
		expectedCount = expectedCount
	})
end

function Queue:AddTabSwitch(tab)
	tinsert(self.tasks, {
		type = "switch_tab",
		tab = tab
	})
end

function Queue:WaitForEvent(event, callback)
	local frame = CreateFrame("Frame")
	local triggered = false
	local function trigger()
		if not triggered then
			triggered = true
			frame:UnregisterAllEvents()
			frame:SetScript("OnEvent", nil)
			callback()
		end
	end

	frame:RegisterEvent(event)
	frame:SetScript("OnEvent", function(self, evt)
		if evt == event then
			trigger()
		end
	end)

	C_Timer.After(1.5, trigger) -- 1.5s timeout safety
end

local function IsSlotLockedCompat(bag, slot)
	if C_Container and C_Container.GetContainerItemInfo then
		local info = C_Container.GetContainerItemInfo(bag, slot)
		return info and info.isLocked
	else
		local _, _, locked = GetContainerItemInfo(bag, slot)
		return locked
	end
end

local function PickupItem(isGuildSlot, bagOrTab, slot)
	if isGuildSlot then
		PickupGuildBankItem(bagOrTab, slot)
	else
		if C_Container and C_Container.PickupContainerItem then
			C_Container.PickupContainerItem(bagOrTab, slot)
		else
			PickupContainerItem(bagOrTab, slot)
		end
	end
end

local function IsSlotLocked(isGuild, bagOrTab, slot)
	if isGuild then
		local _, _, locked = GetGuildBankItemInfo(bagOrTab, slot)
		if locked then
			Debug("IsSlotLocked: Guild slot locked on tab " .. tostring(bagOrTab) .. ", slot " .. tostring(slot))
		end
		return locked
	else
		local locked = IsSlotLockedCompat(bagOrTab, slot)
		if locked then
			Debug("IsSlotLocked: Container slot locked on bag " .. tostring(bagOrTab) .. ", slot " .. tostring(slot))
		end
		return locked
	end
end

function Queue:IsAnySlotLocked()
	if Addon.InventoryBags then
		for _, bag in ipairs(Addon.InventoryBags) do
			if bag ~= KEYRING_CONTAINER then
				for slot = 1, Addon.Inventory:NumSlots(bag) do
					if IsSlotLockedCompat(bag, slot) then
						return true
					end
				end
			end
		end
	end

	if self.isGuild then
		local tab = GetCurrentGuildBankTab()
		if tab then
			for slot = 1, 98 do
				local _, _, locked = GetGuildBankItemInfo(tab, slot)
				if locked then
					return true
				end
			end
		end
	else
		if Addon.BankBags then
			for _, bag in ipairs(Addon.BankBags) do
				for slot = 1, self.frame:NumSlots(bag) do
					if IsSlotLockedCompat(bag, slot) then
						return true
					end
				end
			end
		end
	end
	return false
end

function Queue:VerifyTask(task)
	if task.type == "move" then
		local item
		if task.toIsGuild then
			item = self.frame:GetItemInfo(task.toBag, task.toSlot)
		else
			if task.toBag >= 0 and task.toBag <= 4 then
				item = Addon.Inventory:GetItemInfo(task.toBag, task.toSlot)
			else
				item = self.frame:GetItemInfo(task.toBag, task.toSlot)
			end
		end

		local count = 0
		local hasItem = false

		if item and item ~= Addon.None and item.itemID then
			count = item.stackCount or 1
			hasItem = true
		elseif task.toIsGuild then
			-- Fallback to direct raw API for Guild Bank if link is not cached yet
			local _, itemCount = GetGuildBankItemInfo(task.toBag, task.toSlot)
			if itemCount and itemCount > 0 then
				count = itemCount
				hasItem = true
			end
		else
			-- Fallback to direct raw API for Container Bags if link is not cached yet
			local info = C_Container.GetContainerItemInfo(task.toBag, task.toSlot)
			if info and info.stackCount and info.stackCount > 0 then
				count = info.stackCount
				hasItem = true
			end
		end

		if not hasItem then
			return false
		end

		if task.expectedCount and count < task.expectedCount then
			return false
		end
	end
	return true
end

function Queue:PrintRemainingDuplicates()
	if not self.isGuild or not Engine.itemTabs then return end

	Print("Checking for remaining duplicate items in backpack...")
	local found = false
	for _, bag in ipairs(Addon.InventoryBags) do
		if bag ~= KEYRING_CONTAINER then
			for slot = 1, Addon.Inventory:NumSlots(bag) do
				local item = Addon.Inventory:GetItemInfo(bag, slot)
				if item and item ~= Addon.None and item.itemID then
					local id = item.itemID
					if Engine.itemTabs[id] then
						local link = item.hyperlink or ("item:" .. id)
						Print("  Remaining: " .. link .. " in bag " .. tostring(bag) .. ", slot " .. tostring(slot) .. " (count: " .. tostring(item.stackCount or 1) .. ")")
						found = true
					end
				end
			end
		end
	end
	if not found then
		Print("  No duplicate items remaining in backpack.")
	end
end

function Queue:Start(frame)
	Debug("Queue:Start called, frame: " .. tostring(frame) .. ", frame.id: " .. tostring(frame and frame.id))
	if self.running then
		Debug("Queue: already running!")
		return
	end
	self.frame = frame
	self.isGuild = frame.id == 'guild'
	self.running = true
	self.lastTask = nil
	self:ProcessNext()
end

function Queue:Stop()
	Debug("Queue:Stop called")
	self.running = false
	self.tasks = {}
	self.frame = nil
	self.lastTask = nil
	Engine.itemTabs = nil
end

function Queue:ProcessNext()
	Debug("Queue:ProcessNext - running: " .. tostring(self.running) .. ", frame: " .. tostring(self.frame) .. ", isShown: " .. tostring(self.frame and self.frame:IsShown()) .. ", combat: " .. tostring(InCombatLockdown()) .. ", tasks remaining: " .. #self.tasks)
	if not self.running then return end

	if not self.frame or not self.frame:IsShown() or InCombatLockdown() then
		Debug("Queue:ProcessNext - aborting queue!")
		self:Stop()
		return
	end

	-- Check and verify the result of the last executed move task
	if self.lastTask then
		ClearCursor() -- Safely return any leftovers before checking
		if not self:VerifyTask(self.lastTask) then
			self.lastTask.retries = (self.lastTask.retries or 0) + 1
			if self.lastTask.retries <= 3 then
				Debug("Queue: move task failed verification. Retrying (" .. self.lastTask.retries .. "/3)... expected " .. tostring(self.lastTask.expectedCount))
				-- Place it back at the start of tasks
				tinsert(self.tasks, 1, self.lastTask)
				self.lastTask = nil
				-- Wait 0.3 seconds to let the server recover from any throttle/lag
				C_Timer.After(0.3, function() self:ProcessNext() end)
				return
			else
				Print("Queue: move task failed 3 times. Skipping to prevent infinite hang.")
				self.lastTask = nil
			end
		else
			self.lastTask = nil
		end
	end

	if #self.tasks == 0 then
		self:PrintRemainingDuplicates()
		self:Stop()
		PlaySound(SOUNDKIT.UI_BAG_SORTING_01)
		Print("Consolidation complete.")
		return
	end

	if self:IsAnySlotLocked() then
		Debug("Queue:ProcessNext - some slots are locked. Retrying in 0.05s.")
		C_Timer.After(0.05, function() self:ProcessNext() end)
		return
	end

	local task = self.tasks[1]

	if task.type == "switch_tab" then
		Debug("Queue: executing switch_tab to tab " .. tostring(task.tab))
		if GetCurrentGuildBankTab() == task.tab then
			tremove(self.tasks, 1)
			C_Timer.After(0.1, function() self:ProcessNext() end)
		else
			SetCurrentGuildBankTab(task.tab)
			self:WaitForEvent("GUILDBANKBAGSLOTS_CHANGED", function()
				tremove(self.tasks, 1)
				C_Timer.After(0.2, function() self:ProcessNext() end)
			end)
		end
		return
	end

	if task.type == "move" then
		if IsSlotLocked(task.fromIsGuild, task.fromBag, task.fromSlot) or IsSlotLocked(task.toIsGuild, task.toBag, task.toSlot) then
			C_Timer.After(0.1, function() self:ProcessNext() end)
			return
		end

		tremove(self.tasks, 1)
		self.lastTask = task

		ClearCursor() -- Clear any cursor item left from partial stack merges (automatically returns it to its source slot)

		Debug("Queue: executing move task from bag " .. tostring(task.fromBag) .. " (guild: " .. tostring(task.fromIsGuild) .. "), slot " .. tostring(task.fromSlot) .. " to bag " .. tostring(task.toBag) .. " (guild: " .. tostring(task.toIsGuild) .. "), slot " .. tostring(task.toSlot))
		PickupItem(task.fromIsGuild, task.fromBag, task.fromSlot)
		PickupItem(task.toIsGuild, task.toBag, task.toSlot)

		local eventName = (task.fromIsGuild or task.toIsGuild) and "GUILDBANKBAGSLOTS_CHANGED" or "BAG_UPDATE_DELAYED"
		local delay = (task.fromIsGuild or task.toIsGuild) and 0.25 or 0.05
		self:WaitForEvent(eventName, function()
			C_Timer.After(delay, function() self:ProcessNext() end)
		end)
	end
end

local function SimulateMove(from, to, maxStack)
	Debug("SimulateMove from " .. tostring(from.bag) .. "," .. tostring(from.slot) .. " (count: " .. tostring(from.count) .. ") to " .. tostring(to.bag) .. "," .. tostring(to.slot) .. " (count: " .. tostring(to.count) .. ") max: " .. tostring(maxStack))
	local space = maxStack - to.count
	if from.count <= space then
		local newCount = to.count + from.count
		Queue:Add(from.bag, from.slot, from.isGuild, to.bag, to.slot, to.isGuild, newCount)
		to.count = newCount
		from.count = 0
	else
		Queue:Add(from.bag, from.slot, from.isGuild, to.bag, to.slot, to.isGuild, maxStack)
		to.count = maxStack
		from.count = from.count - space
	end
	Debug("SimulateMove result: from count is now " .. tostring(from.count) .. ", to count is now " .. tostring(to.count))
end

local function ConsolidateItem(itemID, maxStack, bankSlots, bagSlots, emptyBankSlots)
	Debug("ConsolidateItem for ID: " .. tostring(itemID) .. " (maxStack: " .. tostring(maxStack) .. ")")
	Debug("  bankSlots: " .. #bankSlots .. ", bagSlots: " .. #bagSlots .. ", emptyBankSlots: " .. #emptyBankSlots)
	for i, slot in ipairs(bankSlots) do
		Debug("  bankSlot " .. i .. ": bag " .. tostring(slot.bag) .. ", slot " .. tostring(slot.slot) .. ", count: " .. tostring(slot.count))
	end
	for i, slot in ipairs(bagSlots) do
		Debug("  bagSlot " .. i .. ": bag " .. tostring(slot.bag) .. ", slot " .. tostring(slot.slot) .. ", count: " .. tostring(slot.count))
	end

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
			Debug("  Step 4: bagSlot " .. tostring(bagSlot.bag) .. "," .. tostring(bagSlot.slot) .. " has count: " .. tostring(bagSlot.count) .. ", emptyBankSlots available: " .. #emptyBankSlots)
			if #emptyBankSlots > 0 then
				local emptySlot = tremove(emptyBankSlots, 1)
				Debug("  Step 4: Moving remaining stack from bag " .. tostring(bagSlot.bag) .. ", slot " .. tostring(bagSlot.slot) .. " to empty bank bag " .. tostring(emptySlot.bag) .. ", slot " .. tostring(emptySlot.slot))
				Queue:Add(bagSlot.bag, bagSlot.slot, bagSlot.isGuild, emptySlot.bag, emptySlot.slot, emptySlot.isGuild, bagSlot.count)
				emptySlot.count = bagSlot.count
				bagSlot.count = 0
			else
				Debug("  Step 4: No empty bank slots left!")
				break
			end
		end
	end
end

function Engine:Start(frame)
	if Queue.running then return end

	local isGuild = frame.id == 'guild'
	local itemTabs = {}
	Engine.itemTabs = itemTabs
	local duplicateItems = {}

	-- 1. Scan Bank container to find items and active tabs
	if isGuild then
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
					end
				end
			end
		end
	else
		if Addon.BankBags then
			for _, bag in ipairs(Addon.BankBags) do
				for slot = 1, frame:NumSlots(bag) do
					local item = frame:GetItemInfo(bag, slot)
					if item and item ~= Addon.None and item.itemID then
						duplicateItems[item.itemID] = true
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
							if itemTabs[id] then
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
		end
	end

	-- 3. Build Tasks
	Queue.tasks = {}

	if isGuild then
		local tabTasks = {}
		for tab = 1, MAX_GUILDBANK_TABS do
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
						tinsert(emptySlots, { bag = tab, slot = slot, count = 0, isGuild = true })
					end
				end

				for _, itemID in ipairs(items) do
					local bankSlots = {}
					for slot = 1, 98 do
						local item = frame:Super(Addon.Guild):GetItemInfo(tab, slot)
						if item and item ~= Addon.None and item.itemID == itemID then
							tinsert(bankSlots, { bag = tab, slot = slot, count = item.stackCount or 1, isGuild = true })
						end
					end

					local bagSlots = {}
					local maxStack = 1
					for _, bag in ipairs(Addon.InventoryBags) do
						if bag ~= KEYRING_CONTAINER then
							for slot = 1, Addon.Inventory:NumSlots(bag) do
								local item = Addon.Inventory:GetItemInfo(bag, slot)
								if item and item ~= Addon.None and item.itemID == itemID then
									tinsert(bagSlots, { bag = bag, slot = slot, count = item.stackCount or 1, isGuild = false })
									if item.hyperlink then
										maxStack = select(8, C.C_Item.GetItemInfo(item.hyperlink)) or maxStack
									end
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
					tinsert(emptySlots, { bag = bag, slot = slot, count = 0, isGuild = false })
				end
			end
		end

		for itemID in pairs(backpackMatches) do
			local bankSlots = {}
			for _, bag in ipairs(Addon.BankBags) do
				for slot = 1, frame:NumSlots(bag) do
					local item = frame:GetItemInfo(bag, slot)
					if item and item ~= Addon.None and item.itemID == itemID then
						tinsert(bankSlots, { bag = bag, slot = slot, count = item.stackCount or 1, isGuild = false })
					end
				end
			end

			local bagSlots = {}
			local maxStack = 1
			for _, bag in ipairs(Addon.InventoryBags) do
				if bag ~= KEYRING_CONTAINER then
					for slot = 1, Addon.Inventory:NumSlots(bag) do
						local item = Addon.Inventory:GetItemInfo(bag, slot)
						if item and item ~= Addon.None and item.itemID == itemID then
							tinsert(bagSlots, { bag = bag, slot = slot, count = item.stackCount or 1, isGuild = false })
							if item.hyperlink then
								maxStack = select(8, C.C_Item.GetItemInfo(item.hyperlink)) or maxStack
							end
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
		Print("No items need consolidation.")
	end
end
