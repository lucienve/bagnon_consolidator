--[[
	Bagnon Consolidator - Unit Test Suite
	Tests additive snapshot ingestion, conflict detection, zero-stock retention,
	ignore filtering, queue generation, and viewer data operations in a mocked WoW environment.
--]]

local numPassed = 0
local numFailed = 0

local function assertEqual(actual, expected, testName)
	if actual ~= expected then
		print(string.format("[FAIL] %s: Expected %s, got %s", testName, tostring(expected), tostring(actual)))
		numFailed = numFailed + 1
		error("Assertion failure in " .. testName)
	else
		numPassed = numPassed + 1
	end
end

local function assertTrue(condition, testName)
	if not condition then
		print(string.format("[FAIL] %s: Condition was false", testName))
		numFailed = numFailed + 1
		error("Assertion failure in " .. testName)
	else
		numPassed = numPassed + 1
	end
end

local function assertFalse(condition, testName)
	if condition then
		print(string.format("[FAIL] %s: Condition was true", testName))
		numFailed = numFailed + 1
		error("Assertion failure in " .. testName)
	else
		numPassed = numPassed + 1
	end
end

---@class MockLibItemMove : LibItemMove
---@field lastMovedQueue table<any, any>|nil
---@field lastContext string|nil

-- Setup Mock Environment
local registeredEvents = {}
local eventFrames = {}

_G.tinsert = table.insert
_G.tremove = table.remove
_G.KEYRING_CONTAINER = -2
_G.MAX_GUILDBANK_TABS = 8
_G.SOUNDKIT = {
	UI_BAG_SORTING_01 = 43937,
	IG_BACKPACK_CLOSE = 863,
	IG_QUEST_CANCEL = 879,
}
_G.StaticPopupDialogs = {}
_G.StaticPopup_Show = function(which, text1, text2, data) end
_G.UISpecialFrames = {}
local playedSounds = {}
_G.PlaySound = function(soundID)
	if type(soundID) ~= "number" then
		error("bad argument #1 to 'PlaySound' (number expected, got " .. type(soundID) .. ")")
	end
	table.insert(playedSounds, soundID)
end
_G.InCombatLockdown = function() return false end

_G.DEFAULT_CHAT_FRAME = {
	messages = {},
	AddMessage = function(self, msg)
		table.insert(self.messages, msg)
	end
} --[[@as any]]

_G.UnitName = function(unit)
	if unit == "player" then return "TestPlayer" end
	return "Unknown"
end

_G.GetRealmName = function()
	return "TestRealm"
end

local mockGuildInfo = { "TestGuild", "GM", 0, "TestRealm" }
_G.GetGuildInfo = function(unit)
	if unit == "player" and mockGuildInfo then
		return mockGuildInfo[1], mockGuildInfo[2], mockGuildInfo[3], mockGuildInfo[4]
	end
	return nil
end

local mockGuildTabs = {
	[1] = { name = "Reagents", icon = "icon1", isViewable = true, canDeposit = true, numWithdrawals = 10, remainingWithdrawals = 10 },
	[2] = { name = "Consumables", icon = "icon2", isViewable = true, canDeposit = true, numWithdrawals = 10, remainingWithdrawals = 10 },
	[3] = { name = "Vault", icon = "icon3", isViewable = true, canDeposit = false, numWithdrawals = 0, remainingWithdrawals = 0 },
	[4] = { name = "Equipment", icon = "icon4", isViewable = true, canDeposit = true, numWithdrawals = 10, remainingWithdrawals = 10 },
}

_G.GetGuildBankTabInfo = function(tab)
	local info = mockGuildTabs[tab]
	if info then
		return info.name, info.icon, info.isViewable, info.canDeposit, info.numWithdrawals, info.remainingWithdrawals
	end
	return nil
end

_G.CreateFrame = function(frameType, frameName, parent, template)
	local f = {
		name = frameName,
		scripts = {},
		shown = true,
		SetScript = function(self, scriptType, fn)
			self.scripts[scriptType] = fn
		end,
		GetScript = function(self, scriptType)
			return self.scripts[scriptType]
		end,
		RegisterEvent = function(self, event)
			registeredEvents[event] = registeredEvents[event] or {}
			table.insert(registeredEvents[event], self)
		end,
		UnregisterEvent = function(self, event)
			if registeredEvents[event] then
				for i = #registeredEvents[event], 1, -1 do
					if registeredEvents[event][i] == self then
						table.remove(registeredEvents[event], i)
					end
				end
			end
		end,
		Show = function(self) self.shown = true end,
		Hide = function(self) self.shown = false end,
		IsShown = function(self) return self.shown end,
		SetSize = function(self, w, h) self.width, self.height = w, h end,
		SetPoint = function(self, ...) end,
		SetFrameStrata = function(self, strata) end,
		SetMovable = function(self, mov) end,
		EnableMouse = function(self, en) end,
		RegisterForDrag = function(self, ...) end,
		SetClampedToScreen = function(self, c) end,
		SetBackdrop = function(self, t) end,
		SetBackdropColor = function(self, ...) end,
		CreateFontString = function(self, name, layer, template)
			return {
				text = "",
				SetPoint = function(self, ...) end,
				SetText = function(self, txt) self.text = txt end,
				GetText = function(self) return self.text end,
				SetJustifyH = function(self, j) end,
			}
		end,
		CreateTexture = function(self, name, layer)
			return {
				texture = "",
				SetSize = function(self, w, h) end,
				SetPoint = function(self, ...) end,
				SetTexture = function(self, tex) self.texture = tex end,
				SetDesaturated = function(self, desat) end,
			}
		end,
		SetText = function(self, txt) self.text = txt end,
		GetText = function(self) return self.text or "" end,
		SetAutoFocus = function(self, af) end,
		SetChecked = function(self, chk) self.checked = chk end,
		GetChecked = function(self) return self.checked or false end,
		GetName = function(self) return self.name or "Frame" end,
		StartMoving = function(self) end,
		StopMovingOrSizing = function(self) end,
	}
	if frameName and frameName ~= "" then
		_G[frameName] = f
	end
	table.insert(eventFrames, f)
	return f
end

_G.FauxScrollFrame_GetOffset = function(frame) return frame.offset or 0 end
_G.FauxScrollFrame_SetOffset = function(frame, offset) frame.offset = offset end
_G.FauxScrollFrame_Update = function(frame, numItems, numToDisplay, valueStep) end
_G.FauxScrollFrame_OnVerticalScroll = function(frame, offset, itemHeight, updateFunction)
	frame.offset = math.floor(offset / itemHeight)
	updateFunction()
end

_G.MenuUtil = {
	CreateContextMenu = function(parent, callback)
		local menu = {
			SetTag = function(self, tag) end,
			CreateTitle = function(self, title) end,
			CreateButton = function(self, text, fn) end,
			CreateDivider = function(self) end,
			CreateCheckbox = function(self, text, getFn, setFn) end,
		}
		if callback then callback(parent, menu) end
	end
}

_G.Settings = {
	RegisterCanvasLayoutCategory = function(frame, name) return { ID = name } end,
	RegisterAddOnCategory = function(cat) end,
}

-- Libraries
local mockItemDB = {
	[1710] = { name = "Greater Healing Potion", itemType = "Consumable", itemSubType = "Potion" },
	[2447] = { name = "Peacebloom", itemType = "Tradeskill", itemSubType = "Herb" },
	[765]  = { name = "Silverleaf", itemType = "Tradeskill", itemSubType = "Herb" },
	[2589] = { name = "Linen Cloth", itemType = "Tradeskill", itemSubType = "Cloth" },
	[1205] = { name = "Iron Ore", itemType = "Tradeskill", itemSubType = "Metal & Stone" },
}

local mockLibraries = {}
_G.LibStub = function(major)
	if major == 'C_Everywhere' then
		return {
			C_Item = {
				GetItemInfo = function(id)
					local entry = mockItemDB[id]
					if entry then
						return entry.name, "[" .. entry.name .. "]", 1, 1, 1, entry.itemType, entry.itemSubType, 20, "INV_Misc", 134400
					end
					return nil
				end,
				GetItemIconByID = function(id) return 134400 end,
				GetItemIcon = function(itemLoc) return 134400 end,
			},
			GetItemInfoInstant = function(id) return id end,
			GetItemInfo = function(id)
				local entry = mockItemDB[id]
				if entry then return entry.name, "[" .. entry.name .. "]" end
				return nil
			end,
			GetItemIconByID = function(id) return 134400 end,
			GetItemIcon = function(itemLoc) return 134400 end,
		}
	elseif major == 'LibItemMove-1.0' then
		mockLibraries['LibItemMove-1.0'] = mockLibraries['LibItemMove-1.0'] or {
			Debug = false,
			lastMovedQueue = nil,
			lastContext = nil,
			Move = function(self, queue, context, callback)
				self.lastMovedQueue = queue
				self.lastContext = context
				if callback then
					callback("PROGRESS", "item:2447", 10)
					callback("DONE")
				end
			end
		}
		return mockLibraries['LibItemMove-1.0']
	elseif major == 'AceLocale-3.0' then
		return {
			GetLocale = function(self, app, silent)
				return setmetatable({}, {
					__index = function(t, k) return k end
				})
			end
		}
	end
	return nil
end

-- Initialize Bagnon Addon table
local Addon = {
	BankBags = { -1, 5, 6, 7, 8, 9, 10 },
	InventoryBags = { 0, 1, 2, 3, 4, -2 },
	None = {},
	Guild = {},
}

Addon.Tipped = {
	NewClass = function(self, name, parent, template)
		local cls = {
			name = name,
			Super = function(self, parentCls)
				return {
					New = function(parentSelf, parentObj)
						return {
							Icon = { SetTexture = function(self, tex) end },
							RegisterForClicks = function(self, ...) end,
						}
					end
				}
			end
		}
		return cls
	end
}

local mockInventorySlots = {}
Addon.Inventory = {
	GetExtraButtons = function(self) return {} end,
	GetWidget = function(self, name) return { name = name } end,
	NumSlots = function(self, bag)
		return (mockInventorySlots[bag] and #mockInventorySlots[bag]) or 0
	end,
	GetItemInfo = function(self, bag, slot)
		if mockInventorySlots[bag] and mockInventorySlots[bag][slot] then
			return mockInventorySlots[bag][slot]
		end
		return Addon.None
	end,
}

local mockBankSlots = {}
local mockGuildBagInfo = {}

local mockBankFrame = {
	id = 'bank',
	shown = true,
	IsShown = function(self) return self.shown end,
	IsCached = function(self) return false end,
	NumSlots = function(self, bag)
		return (mockBankSlots[bag] and #mockBankSlots[bag]) or 0
	end,
	GetItemInfo = function(self, bag, slot)
		if mockBankSlots[bag] and mockBankSlots[bag][slot] then
			return mockBankSlots[bag][slot]
		end
		return Addon.None
	end,
}

local mockGuildFrame = {
	id = 'guild',
	shown = false,
	IsShown = function(self) return self.shown end,
	IsCached = function(self) return false end,
	GetBagInfo = function(self, tab)
		return mockGuildBagInfo[tab]
	end,
	Super = function(self, cls)
		return {
			GetItemInfo = function(parentSelf, tab, slot)
				local bagInfo = mockGuildBagInfo[tab]
				if bagInfo and bagInfo.items and bagInfo.items[slot] then
					return bagInfo.items[slot]
				end
				return Addon.None
			end
		}
	end
}

Addon.Frames = {
	Get = function(self, name)
		if name == 'bank' then return mockBankFrame end
		if name == 'guild' then return mockGuildFrame end
		return nil
	end,
	IsShown = function(self, name)
		if name == 'bank' then return mockBankFrame:IsShown() end
		if name == 'guild' then return mockGuildFrame:IsShown() end
		return false
	end,
}

_G["Bagnon"] = Addon

-- Helper to load addon scripts
local function loadAddonFile(filePath)
	local fn, err = loadfile(filePath)
	if not fn then
		error("Failed to load file " .. filePath .. ": " .. tostring(err))
	end
	fn("Bagnon_Consolidator", Addon)
end

-- Load addon files in topological manifest order
local function LoadAddonScripts()
	loadAddonFile("core/init.lua")
	loadAddonFile("core/utils.lua")
	loadAddonFile("core/snapshot.lua")
	loadAddonFile("core/engine.lua")
	loadAddonFile("ui/button.lua")
	loadAddonFile("ui/viewer.lua")
	loadAddonFile("ui/options.lua")
end

LoadAddonScripts()

-- Simulate ADDON_LOADED event
if registeredEvents["ADDON_LOADED"] then
	for _, f in ipairs(registeredEvents["ADDON_LOADED"]) do
		local onEvent = f:GetScript("OnEvent")
		if onEvent then
			onEvent(f, "ADDON_LOADED", "Bagnon_Consolidator")
		end
	end
end

print("=== Running Bagnon Consolidator Unit Tests ===")

-- ----------------------------------------------------
-- Test 1: Addon Initialization & DB Default Structure
-- ----------------------------------------------------
do
	assertTrue(BagnonConsolidatorDB ~= nil, "DB Initialized")
	assertTrue(type(BagnonConsolidatorDB.guildTabs) == "table", "guildTabs table exists")
	assertTrue(type(BagnonConsolidatorDB.personalBanks) == "table", "personalBanks table exists")
	assertTrue(type(BagnonConsolidatorDB.ignored) == "table", "ignored table exists")
	assertTrue(type(BagnonConsolidatorDB.conflicts) == "table", "conflicts table exists")
	assertEqual(BagnonConsolidatorDB.enableDebug, false, "enableDebug default")
	print("[PASS] Test 1: Addon Initialization & DB Defaults")
end

-- ----------------------------------------------------
-- Test 2: Identity & Item Helpers
-- ----------------------------------------------------
do
	assertEqual(Addon.GetCharacterKey(), "TestPlayer-TestRealm", "GetCharacterKey")
	assertEqual(Addon.GetGuildKey(), "TestGuild-TestRealm", "GetGuildKey")
	assertEqual(Addon.GetItemName({ hyperlink = "|cffffffff[Peacebloom]|r", itemID = 2447 }), "Peacebloom", "GetItemName hyperlink")
	assertEqual(Addon.GetItemName({ itemID = 2447 }), "Peacebloom", "GetItemName itemID lookup")
	print("[PASS] Test 2: Identity and Item Helper Utilities")
end

-- ----------------------------------------------------
-- Test 3: Personal Bank Additive Snapshot Ingestion
-- ----------------------------------------------------
do
	mockBankSlots = {
		[-1] = {
			[1] = { itemID = 2447, stackCount = 20, hyperlink = "|cffffffff[Peacebloom]|r" },
			[2] = { itemID = 765, stackCount = 15, hyperlink = "|cffffffff[Silverleaf]|r" },
		}
	}
	mockBankFrame.shown = true
	mockGuildFrame.shown = false

	local snapSuccess = Addon.TakeSnapshot(mockBankFrame)
	assertTrue(snapSuccess, "TakeSnapshot personal bank success")

	local charKey = Addon.GetCharacterKey()
	assertTrue(BagnonConsolidatorDB.personalBanks[charKey] ~= nil, "Personal bank entry exists")
	assertEqual(BagnonConsolidatorDB.personalBanks[charKey][2447], "Peacebloom", "Item 2447 mapped to personal bank")
	assertEqual(BagnonConsolidatorDB.personalBanks[charKey][765], "Silverleaf", "Item 765 mapped to personal bank")
	print("[PASS] Test 3: Personal Bank Additive Snapshot Ingestion")
end

-- ----------------------------------------------------
-- Test 4: Guild Bank Snapshot Ingestion & Conflict Detection
-- ----------------------------------------------------
do
	mockGuildBagInfo = {
		[1] = { items = { [1] = { itemID = 2589, stackCount = 20, hyperlink = "[Linen Cloth]" } } },
		[2] = { items = { [1] = { itemID = 1205, stackCount = 20, hyperlink = "[Iron Ore]" } } },
		[3] = { items = { [1] = { itemID = 1205, stackCount = 10, hyperlink = "[Iron Ore]" } } }, -- Multi-tab conflict for Iron Ore (Tab 2 and 3)
	}
	mockBankFrame.shown = false
	mockGuildFrame.shown = true

	local snapSuccess = Addon.TakeSnapshot(mockGuildFrame)
	assertTrue(snapSuccess, "TakeSnapshot guild bank success")

	local guildKey = Addon.GetGuildKey()
	assertTrue(BagnonConsolidatorDB.guildTabs[guildKey] ~= nil, "Guild bank entry exists")
	
	-- Linen Cloth mapped cleanly to Tab 1
	local linenEntry = BagnonConsolidatorDB.guildTabs[guildKey][2589]
	assertTrue(linenEntry ~= nil, "Linen cloth mapped")
	assertEqual(linenEntry.tab, 1, "Linen cloth on Tab 1")

	-- Iron Ore is on Tab 2 and Tab 3 -> Conflict
	local ironEntry = BagnonConsolidatorDB.guildTabs[guildKey][1205]
	assertEqual(ironEntry, nil, "Iron ore stripped from active guild tabs")
	local ironConflict = BagnonConsolidatorDB.conflicts[guildKey][1205]
	assertTrue(ironConflict ~= nil, "Iron ore recorded in conflicts")
	assertEqual(ironConflict.personal, false, "Iron ore is multi-guild tab conflict")

	print("[PASS] Test 4: Guild Bank Snapshot Ingestion & Multi-Tab Conflict")
end

-- ----------------------------------------------------
-- Test 5: Cross-Container Conflict Detection (Personal vs Guild)
-- ----------------------------------------------------
do
	local charKey = Addon.GetCharacterKey()
	local guildKey = Addon.GetGuildKey()

	-- Peacebloom (2447) is in Personal Bank. Now present in Guild Tab 1.
	mockGuildBagInfo = {
		[1] = { items = { [1] = { itemID = 2447, stackCount = 10, hyperlink = "[Peacebloom]" } } }
	}
	mockBankFrame.shown = false
	mockGuildFrame.shown = true

	Addon.TakeSnapshot(mockGuildFrame)

	-- Peacebloom must NOT be in guildTabs, but MUST be recorded under conflicts
	assertEqual(BagnonConsolidatorDB.guildTabs[guildKey][2447], nil, "Peacebloom not mapped to guild tab due to conflict")
	local pbConflict = BagnonConsolidatorDB.conflicts[guildKey][2447]
	assertTrue(pbConflict ~= nil, "Peacebloom present in conflicts table")
	assertEqual(pbConflict.personal, true, "Peacebloom marked as personal conflict")

	print("[PASS] Test 5: Cross-Container Personal vs Guild Bank Conflict")
end

-- ----------------------------------------------------
-- Test 6: Ignore List Filtering and Zero-Stock Retention
-- ----------------------------------------------------
do
	local guildKey = Addon.GetGuildKey()
	-- Add Greater Healing Potion (1710) to Ignore list
	BagnonConsolidatorDB.ignored[1710] = "Greater Healing Potion"

	mockGuildBagInfo = {
		[1] = { items = { [1] = { itemID = 1710, stackCount = 5, hyperlink = "[Greater Healing Potion]" } } }
	}
	Addon.TakeSnapshot(mockGuildFrame)

	assertEqual(BagnonConsolidatorDB.guildTabs[guildKey][1710], nil, "Ignored item not mapped during snapshot")
	assertEqual(BagnonConsolidatorDB.conflicts[guildKey][1710], nil, "Ignored item not placed into conflicts")

	-- Zero-Stock Retention: Linen Cloth (2589) was mapped to Tab 1 earlier; it is not in mockGuildBagInfo now
	local retainedLinen = BagnonConsolidatorDB.guildTabs[guildKey][2589]
	assertTrue(retainedLinen ~= nil, "Zero-stock mapped item retained in database")
	assertEqual(retainedLinen.tab, 1, "Retained item preserves target tab")

	print("[PASS] Test 6: Ignore List Filtering & Zero-Stock Retention")
end

-- ----------------------------------------------------
-- Test 7: Reset Mappings Scopes
-- ----------------------------------------------------
do
	local charKey = Addon.GetCharacterKey()
	local guildKey = Addon.GetGuildKey()

	-- Scope: "guild"
	Addon.ResetMappings("guild")
	assertTrue(next(BagnonConsolidatorDB.guildTabs[guildKey]) == nil, "Guild tabs reset")
	assertTrue(BagnonConsolidatorDB.personalBanks[charKey][2447] ~= nil, "Personal bank unaffected by guild reset")

	-- Scope: "personal"
	Addon.ResetMappings("personal")
	assertTrue(next(BagnonConsolidatorDB.personalBanks[charKey]) == nil, "Personal bank reset")

	-- Restore sample data and test "all"
	BagnonConsolidatorDB.guildTabs[guildKey] = { [2589] = { tab = 1, name = "Linen Cloth" } }
	BagnonConsolidatorDB.personalBanks[charKey] = { [2447] = "Peacebloom" }
	BagnonConsolidatorDB.ignored[1710] = "Greater Healing Potion"
	Addon.ResetMappings("all")

	assertTrue(next(BagnonConsolidatorDB.guildTabs) == nil, "All guild tabs cleared")
	assertTrue(next(BagnonConsolidatorDB.personalBanks) == nil, "All personal banks cleared")
	assertTrue(next(BagnonConsolidatorDB.ignored) == nil, "All ignored items cleared")

	print("[PASS] Test 7: Reset Mappings Scopes (Guild, Personal, All)")
end

-- ----------------------------------------------------
-- Test 8: Consolidation Engine Queue Generation (Personal Bank)
-- ----------------------------------------------------
do
	local charKey = Addon.GetCharacterKey()
	BagnonConsolidatorDB.personalBanks[charKey] = {
		[2447] = "Peacebloom",
		[765] = "Silverleaf",
	}

	mockInventorySlots = {
		[0] = {
			[1] = { itemID = 2447, stackCount = 5, hyperlink = "[Peacebloom]" },
			[2] = { itemID = 765, stackCount = 10, hyperlink = "[Silverleaf]" },
			[3] = { itemID = 9999, stackCount = 1, hyperlink = "[Unmapped Item]" },
		},
		[-2] = { -- Keyring container (must be skipped)
			[1] = { itemID = 2447, stackCount = 20, hyperlink = "[Peacebloom]" }
		}
	}

	mockBankFrame.shown = true
	mockGuildFrame.shown = false

	Addon.ConsolidateEngine:Start(mockBankFrame)

	local libItemMove = LibStub('LibItemMove-1.0') --[[@as MockLibItemMove]]
	assertEqual(libItemMove.lastContext, "BagToBank", "Personal bank context")
	assertTrue(libItemMove.lastMovedQueue ~= nil, "Move queue created")
	if libItemMove.lastMovedQueue then
		assertEqual(libItemMove.lastMovedQueue["2447"], 5, "Peacebloom quantity in moveQueue")
		assertEqual(libItemMove.lastMovedQueue["765"], 10, "Silverleaf quantity in moveQueue")
		assertEqual(libItemMove.lastMovedQueue["9999"], nil, "Unmapped item excluded from moveQueue")
	end

	print("[PASS] Test 8: Consolidation Engine Move Queue (Personal Bank & Keyring Skip)")
end

-- ----------------------------------------------------
-- Test 9: Consolidation Engine Multi-Tab Queue (Guild Bank & Permissions)
-- ----------------------------------------------------
do
	local guildKey = Addon.GetGuildKey()
	assertTrue(guildKey ~= nil, "guildKey is valid")
	if guildKey then
		BagnonConsolidatorDB.guildTabs[guildKey] = {
			[2589] = { tab = 1, name = "Linen Cloth" }, -- Tab 1 has canDeposit = true
			[1710] = { tab = 3, name = "Greater Healing Potion" }, -- Tab 3 has canDeposit = false
		}
	end

	mockInventorySlots = {
		[0] = {
			[1] = { itemID = 2589, stackCount = 15, hyperlink = "[Linen Cloth]" },
			[2] = { itemID = 1710, stackCount = 5, hyperlink = "[Greater Healing Potion]" },
		}
	}

	mockBankFrame.shown = false
	mockGuildFrame.shown = true

	Addon.ConsolidateEngine:Start(mockGuildFrame)

	local libItemMove = LibStub('LibItemMove-1.0') --[[@as MockLibItemMove]]
	assertEqual(libItemMove.lastContext, "BagToGuildBank", "Guild bank context")
	assertTrue(libItemMove.lastMovedQueue ~= nil, "Multi-tab move queue created")
	if libItemMove.lastMovedQueue then
		assertTrue(libItemMove.lastMovedQueue[1] ~= nil, "Tab 1 queue exists")
		if libItemMove.lastMovedQueue[1] then
			assertEqual(libItemMove.lastMovedQueue[1]["2589"], 15, "Linen Cloth moved to Tab 1")
		end
		assertEqual(libItemMove.lastMovedQueue[3], nil, "Tab 3 skipped due to no deposit permission")
	end

	print("[PASS] Test 9: Guild Bank Multi-Tab Queue & Deposit Permissions")
end

-- ----------------------------------------------------
-- Test 10: Viewer Data Operations & Filter Operations
-- ----------------------------------------------------
do
	local charKey = Addon.GetCharacterKey()
	BagnonConsolidatorDB.personalBanks[charKey] = {
		[2447] = "Peacebloom",
		[765] = "Silverleaf",
		[99999] = "Uncached Custom Item",
	}
	BagnonConsolidatorDB.ignored = {
		[1710] = "Greater Healing Potion"
	}

	-- Open Viewer Frame
	Addon.Viewer:Toggle()
	assertTrue(Addon.Viewer ~= nil, "Viewer module exists")

	-- Toggle off
	Addon.Viewer:Toggle()

	print("[PASS] Test 10: Viewer Operations & Toggle State")
end

-- ----------------------------------------------------
-- Test 11: Personal Bank Pre-Filtering (C_Bank.IsItemAllowedInBankType)
-- ----------------------------------------------------
do
	local prevEnum = _G["Enum"]
	local prevItemLocation = _G["ItemLocation"]
	local prevCBank = _G["C_Bank"]

	local allowedSlots = {}
	local bankCheckCalls = 0
	local checkedSlots = {}
	local checkedBankTypes = {}

	_G["Enum"] = {
		BankType = {
			Character = 0,
			Guild = 1,
			Account = 2,
		}
	} --[[@as any]]

	_G["ItemLocation"] = {
		CreateFromBagAndSlot = function(self, bag, slot)
			return { bagID = bag, slotIndex = slot }
		end
	} --[[@as any]]

	_G["C_Bank"] = {
		IsItemAllowedInBankType = function(bankType, itemLocation)
			bankCheckCalls = bankCheckCalls + 1
			table.insert(checkedBankTypes, bankType)
			local key = tostring(itemLocation.bagID) .. ":" .. tostring(itemLocation.slotIndex)
			checkedSlots[key] = true
			return allowedSlots[key] == true
		end
	} --[[@as any]]

	local charKey = Addon.GetCharacterKey()
	local guildKey = Addon.GetGuildKey()
	assertTrue(charKey ~= nil, "charKey is valid for Test 11")
	assertTrue(guildKey ~= nil, "guildKey is valid for Test 11")

	if charKey then
		BagnonConsolidatorDB.personalBanks[charKey] = {
			[2447] = "Peacebloom",
			[765] = "Silverleaf",
		}
	end
	BagnonConsolidatorDB.ignored = {}
	BagnonConsolidatorDB.conflicts = {}

	local libItemMove = LibStub('LibItemMove-1.0') --[[@as MockLibItemMove]]

	-- 11a: Mixed allowed and disallowed slots (including per-slot check on same itemID)
	allowedSlots = {
		["0:1"] = true,
		["0:2"] = false,
		["0:3"] = false,
	}
	mockInventorySlots = {
		[0] = {
			[1] = { itemID = 2447, stackCount = 5, hyperlink = "[Peacebloom]" },
			[2] = { itemID = 2447, stackCount = 3, hyperlink = "[Peacebloom]" },
			[3] = { itemID = 765, stackCount = 10, hyperlink = "[Silverleaf]" },
			[4] = { itemID = 9999, stackCount = 2, hyperlink = "[Unmapped Item]" },
		}
	}
	mockBankFrame.shown = true
	mockGuildFrame.shown = false
	libItemMove.lastMovedQueue = nil
	libItemMove.lastContext = nil

	Addon.ConsolidateEngine:Start(mockBankFrame)

	assertEqual(libItemMove.lastContext, "BagToBank", "Test 11a personal bank context")
	assertTrue(libItemMove.lastMovedQueue ~= nil, "Test 11a moveQueue dispatched")
	if libItemMove.lastMovedQueue then
		assertEqual(libItemMove.lastMovedQueue["2447"], 5, "Test 11a only allowed slot quantity queued for 2447")
		assertEqual(libItemMove.lastMovedQueue["765"], nil, "Test 11a fully disallowed item 765 excluded")
		assertEqual(libItemMove.lastMovedQueue["9999"], nil, "Test 11a unmapped item 9999 excluded")
	end
	assertEqual(bankCheckCalls, 3, "Test 11a checked exactly 3 mapped slots")
	assertTrue(checkedSlots["0:1"] and checkedSlots["0:2"] and checkedSlots["0:3"], "Test 11a checked mapped slots")
	assertEqual(checkedSlots["0:4"], nil, "Test 11a skipped C_Bank check for unmapped slot 0:4")
	for _, bankType in ipairs(checkedBankTypes) do
		assertEqual(bankType, 0, "Test 11a passed Enum.BankType.Character (0)")
	end

	-- 11b: All mapped slots disallowed -> skip LibItemMove:Move and print No items need consolidation
	allowedSlots = {}
	bankCheckCalls = 0
	checkedSlots = {}
	checkedBankTypes = {}
	libItemMove.lastMovedQueue = nil
	libItemMove.lastContext = nil

	local chatMessages = (DEFAULT_CHAT_FRAME --[[@as { messages: string[] }]]).messages
	local msgStart = #chatMessages

	Addon.ConsolidateEngine:Start(mockBankFrame)

	assertEqual(libItemMove.lastMovedQueue, nil, "Test 11b LibItemMove:Move not called when all mapped items disallowed")
	assertEqual(libItemMove.lastContext, nil, "Test 11b context remains nil")
	assertEqual(bankCheckCalls, 3, "Test 11b checked all 3 mapped slots")

	local sawNoItems = false
	local sawComplete = false
	for i = msgStart + 1, #chatMessages do
		if chatMessages[i]:find("No items need consolidation.", 1, true) then
			sawNoItems = true
		end
		if chatMessages[i]:find("Consolidation complete.", 1, true) then
			sawComplete = true
		end
	end
	assertTrue(sawNoItems, "Test 11b reported No items need consolidation.")
	assertFalse(sawComplete, "Test 11b did not report Consolidation complete.")

	-- 11c: Guild bank consolidation unaffected even when Character Bank check returns false
	if guildKey then
		BagnonConsolidatorDB.guildTabs[guildKey] = {
			[2589] = { tab = 1, name = "Linen Cloth" },
		}
	end
	mockInventorySlots = {
		[0] = {
			[1] = { itemID = 2589, stackCount = 12, hyperlink = "[Linen Cloth]" },
		}
	}
	mockBankFrame.shown = false
	mockGuildFrame.shown = true
	bankCheckCalls = 0
	libItemMove.lastMovedQueue = nil
	libItemMove.lastContext = nil

	Addon.ConsolidateEngine:Start(mockGuildFrame)

	assertEqual(libItemMove.lastContext, "BagToGuildBank", "Test 11c guild bank context unaffected")
	assertTrue(libItemMove.lastMovedQueue ~= nil, "Test 11c guild moveQueue created")
	if libItemMove.lastMovedQueue then
		assertTrue(libItemMove.lastMovedQueue[1] ~= nil, "Test 11c Tab 1 queue exists")
		if libItemMove.lastMovedQueue[1] then
			assertEqual(libItemMove.lastMovedQueue[1]["2589"], 12, "Test 11c Linen Cloth queued for Tab 1")
		end
	end
	assertEqual(bankCheckCalls, 0, "Test 11c guild bank did not call C_Bank.IsItemAllowedInBankType")

	_G["C_Bank"] = prevCBank
	_G["ItemLocation"] = prevItemLocation
	_G["Enum"] = prevEnum

	print("[PASS] Test 11: Personal Bank Pre-Filtering (C_Bank.IsItemAllowedInBankType)")
end

-- ----------------------------------------------------
-- Test 12: Character Bank vs Account/Warband Bank Isolation (#10)
-- ----------------------------------------------------
do
	local prevEnum = _G["Enum"]
	local prevCBank = _G["C_Bank"]
	local prevBankBags = Addon.BankBags
	local prevBankSlots = mockBankSlots
	local prevGuildBagInfo = mockGuildBagInfo
	local prevInventorySlots = mockInventorySlots
	local prevBankShown = mockBankFrame.shown
	local prevGuildShown = mockGuildFrame.shown

	local charKey = Addon.GetCharacterKey()
	local guildKey = Addon.GetGuildKey()
	assertTrue(charKey ~= nil, "charKey is valid for Test 12")
	assertTrue(guildKey ~= nil, "guildKey is valid for Test 12")

	if charKey and guildKey then
		-- 12a: Retail 120100 layout (CharacterBankTab_1..6 = 6..11, AccountBankTab_1..5 = 12..16)
		Addon.BankBags = { 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 }
		_G["Enum"] = {
			BankType = { Character = 0, Guild = 1, Account = 2 },
			BagIndex = {
				CharacterBankTab_1 = 6,
				CharacterBankTab_2 = 7,
				CharacterBankTab_3 = 8,
				CharacterBankTab_4 = 9,
				CharacterBankTab_5 = 10,
				CharacterBankTab_6 = 11,
				AccountBankTab_1 = 12,
				AccountBankTab_2 = 13,
				AccountBankTab_3 = 14,
				AccountBankTab_4 = 15,
				AccountBankTab_5 = 16,
			},
		} --[[@as any]]

		local fetchMode = "partial"
		_G["C_Bank"] = {
			FetchPurchasedBankTabIDs = function(bankType)
				if fetchMode == "nil" then
					return nil
				elseif fetchMode == "empty" then
					return {}
				end
				if bankType == 2 then
					return { 12, 13 }
				end
				return { 6, 7, 8, 9, 10, 11 }
			end,
		} --[[@as any]]

		BagnonConsolidatorDB.personalBanks[charKey] = {}
		BagnonConsolidatorDB.guildTabs[guildKey] = {
			[2589] = { tab = 1, name = "Linen Cloth" },
		}
		BagnonConsolidatorDB.conflicts = {}
		BagnonConsolidatorDB.ignored = {}

		mockBankSlots = {
			[6] = { [1] = { itemID = 2447, stackCount = 20, hyperlink = "[Peacebloom]" } },
			[11] = { [1] = { itemID = 765, stackCount = 10, hyperlink = "[Silverleaf]" } },
			[12] = { [1] = { itemID = 2589, stackCount = 20, hyperlink = "[Linen Cloth]" } },
			[15] = { [1] = { itemID = 1205, stackCount = 5, hyperlink = "[Iron Ore]" } },
		}
		mockBankFrame.shown = true
		mockGuildFrame.shown = false

		assertTrue(Addon.TakeSnapshot(mockBankFrame), "Test 12a Retail snapshot succeeds")
		assertEqual(BagnonConsolidatorDB.personalBanks[charKey][2447], "Peacebloom", "Test 12a CharacterBankTab_1 mapped")
		assertEqual(BagnonConsolidatorDB.personalBanks[charKey][765], "Silverleaf", "Test 12a CharacterBankTab_6 mapped")
		assertEqual(BagnonConsolidatorDB.personalBanks[charKey][2589], nil, "Test 12a purchased AccountBankTab_1 excluded")
		assertEqual(BagnonConsolidatorDB.personalBanks[charKey][1205], nil, "Test 12a unreturned AccountBankTab_4 excluded")
		assertTrue(BagnonConsolidatorDB.guildTabs[guildKey][2589] ~= nil, "Test 12a Guild item not stripped by Account tab")
		assertEqual(BagnonConsolidatorDB.conflicts[guildKey], nil, "Test 12a no false Personal-vs-Guild conflict created")

		-- Offline / empty and nil returns from FetchPurchasedBankTabIDs still isolate AccountBankTab_*
		fetchMode = "empty"
		BagnonConsolidatorDB.personalBanks[charKey] = {}
		assertTrue(Addon.TakeSnapshot(mockBankFrame), "Test 12a empty FetchPurchasedBankTabIDs snapshot succeeds")
		assertEqual(BagnonConsolidatorDB.personalBanks[charKey][2447], "Peacebloom", "Test 12a empty mode keeps CharacterBankTab_1")
		assertEqual(BagnonConsolidatorDB.personalBanks[charKey][765], "Silverleaf", "Test 12a empty mode keeps CharacterBankTab_6")
		assertEqual(BagnonConsolidatorDB.personalBanks[charKey][2589], nil, "Test 12a empty mode excludes AccountBankTab_1")
		assertEqual(BagnonConsolidatorDB.personalBanks[charKey][1205], nil, "Test 12a empty mode excludes AccountBankTab_4")

		fetchMode = "nil"
		BagnonConsolidatorDB.personalBanks[charKey] = {}
		assertTrue(Addon.TakeSnapshot(mockBankFrame), "Test 12a nil FetchPurchasedBankTabIDs snapshot succeeds")
		assertEqual(BagnonConsolidatorDB.personalBanks[charKey][2447], "Peacebloom", "Test 12a nil mode keeps CharacterBankTab_1")
		assertEqual(BagnonConsolidatorDB.personalBanks[charKey][765], "Silverleaf", "Test 12a nil mode keeps CharacterBankTab_6")
		assertEqual(BagnonConsolidatorDB.personalBanks[charKey][2589], nil, "Test 12a nil mode excludes AccountBankTab_1")
		assertEqual(BagnonConsolidatorDB.personalBanks[charKey][1205], nil, "Test 12a nil mode excludes AccountBankTab_4")

		-- 12b: WoW Forever 16001 layout (CharacterBankTab_1..9 = 6..14, AccountBankTab_1..9 = 15..23)
		Addon.BankBags = { 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23 }
		_G["Enum"] = {
			BankType = { Character = 0, Guild = 1, Account = 2 },
			BagIndex = {
				CharacterBankTab_1 = 6,
				CharacterBankTab_2 = 7,
				CharacterBankTab_3 = 8,
				CharacterBankTab_4 = 9,
				CharacterBankTab_5 = 10,
				CharacterBankTab_6 = 11,
				CharacterBankTab_7 = 12,
				CharacterBankTab_8 = 13,
				CharacterBankTab_9 = 14,
				AccountBankTab_1 = 15,
				AccountBankTab_2 = 16,
				AccountBankTab_3 = 17,
				AccountBankTab_4 = 18,
				AccountBankTab_5 = 19,
				AccountBankTab_6 = 20,
				AccountBankTab_7 = 21,
				AccountBankTab_8 = 22,
				AccountBankTab_9 = 23,
			},
		} --[[@as any]]

		_G["C_Bank"] = {
			FetchPurchasedBankTabIDs = function(bankType)
				if bankType == 2 then
					return { 15, 16, 17, 18, 19, 20, 21, 22, 23 }
				end
				return { 6, 7, 8, 9, 10, 11, 12, 13, 14 }
			end,
		} --[[@as any]]

		BagnonConsolidatorDB.personalBanks[charKey] = {}
		mockBankSlots = {
			[6] = { [1] = { itemID = 2447, stackCount = 20, hyperlink = "[Peacebloom]" } },
			[12] = { [1] = { itemID = 765, stackCount = 10, hyperlink = "[Silverleaf]" } },
			[14] = { [1] = { itemID = 2589, stackCount = 15, hyperlink = "[Linen Cloth]" } },
			[15] = { [1] = { itemID = 1205, stackCount = 5, hyperlink = "[Iron Ore]" } },
			[23] = { [1] = { itemID = 1710, stackCount = 3, hyperlink = "[Greater Healing Potion]" } },
		}

		assertTrue(Addon.TakeSnapshot(mockBankFrame), "Test 12b Forever snapshot succeeds")
		assertEqual(BagnonConsolidatorDB.personalBanks[charKey][2447], "Peacebloom", "Test 12b CharacterBankTab_1 (6) mapped")
		assertEqual(BagnonConsolidatorDB.personalBanks[charKey][765], "Silverleaf", "Test 12b CharacterBankTab_7 (12) mapped")
		assertEqual(BagnonConsolidatorDB.personalBanks[charKey][2589], "Linen Cloth", "Test 12b CharacterBankTab_9 (14) mapped")
		assertEqual(BagnonConsolidatorDB.personalBanks[charKey][1205], nil, "Test 12b AccountBankTab_1 (15) excluded")
		assertEqual(BagnonConsolidatorDB.personalBanks[charKey][1710], nil, "Test 12b AccountBankTab_9 (23) excluded")

		-- 12c: Classic / Mists layout (C_Bank = nil, dead AccountBankTab_1..5 = 13..17, no CharacterBankTab_1)
		_G["C_Bank"] = nil
		_G["Enum"] = {
			BagIndex = {
				Bank = -1,
				Reagentbank = -3,
				BankBag_1 = 6,
				BankBag_2 = 7,
				BankBag_3 = 8,
				BankBag_4 = 9,
				BankBag_5 = 10,
				BankBag_6 = 11,
				BankBag_7 = 12,
				AccountBankTab_1 = 13,
				AccountBankTab_2 = 14,
				AccountBankTab_3 = 15,
				AccountBankTab_4 = 16,
				AccountBankTab_5 = 17,
			},
		} --[[@as any]]
		Addon.BankBags = { -1, -3, 5, 6, 7, 8, 9, 10, 11 }
		BagnonConsolidatorDB.personalBanks[charKey] = {}
		mockBankSlots = {
			[-1] = { [1] = { itemID = 2447, stackCount = 20, hyperlink = "[Peacebloom]" } },
			[-3] = { [1] = { itemID = 765, stackCount = 10, hyperlink = "[Silverleaf]" } },
			[6] = { [1] = { itemID = 2589, stackCount = 15, hyperlink = "[Linen Cloth]" } },
			[11] = { [1] = { itemID = 1205, stackCount = 5, hyperlink = "[Iron Ore]" } },
		}

		assertTrue(Addon.TakeSnapshot(mockBankFrame), "Test 12c Classic/Mists snapshot succeeds")
		assertEqual(BagnonConsolidatorDB.personalBanks[charKey][2447], "Peacebloom", "Test 12c legacy Bank (-1) mapped")
		assertEqual(BagnonConsolidatorDB.personalBanks[charKey][765], "Silverleaf", "Test 12c legacy Reagentbank (-3) mapped")
		assertEqual(BagnonConsolidatorDB.personalBanks[charKey][2589], "Linen Cloth", "Test 12c legacy bag 6 mapped")
		assertEqual(BagnonConsolidatorDB.personalBanks[charKey][1205], "Iron Ore", "Test 12c legacy bag 11 mapped")

		-- 12d: Remote Warband-only bank access guard in Engine:Start
		local canUseCalls = 0
		local checkedTypes = {}
		_G["Enum"] = {
			BankType = { Character = 0, Guild = 1, Account = 2 },
		} --[[@as any]]
		_G["C_Bank"] = {
			CanUseBank = function(bankType)
				canUseCalls = canUseCalls + 1
				table.insert(checkedTypes, bankType)
				return bankType == 2
			end,
		} --[[@as any]]

		BagnonConsolidatorDB.personalBanks[charKey] = { [2447] = "Peacebloom" }
		BagnonConsolidatorDB.conflicts = {
			[charKey] = {
				[765] = { name = "Silverleaf" },
			},
		}
		mockInventorySlots = {
			[0] = {
				[1] = { itemID = 2447, stackCount = 5, hyperlink = "[Peacebloom]" },
				[2] = { itemID = 765, stackCount = 2, hyperlink = "[Silverleaf]" },
			},
		}

		local libItemMove = LibStub('LibItemMove-1.0') --[[@as MockLibItemMove]]
		libItemMove.lastMovedQueue = nil
		libItemMove.lastContext = nil
		mockBankFrame.shown = true
		mockGuildFrame.shown = false

		local chatMessages = (DEFAULT_CHAT_FRAME --[[@as { messages: string[] }]]).messages
		local msgStart = #chatMessages

		Addon.ConsolidateEngine:Start(mockBankFrame)

		assertEqual(canUseCalls, 1, "Test 12d CanUseBank called once for personal bank")
		assertEqual(checkedTypes[1], 0, "Test 12d checked Enum.BankType.Character (0)")
		assertEqual(libItemMove.lastMovedQueue, nil, "Test 12d skipped LibItemMove:Move when Character Bank unusable")
		assertEqual(libItemMove.lastContext, nil, "Test 12d context remains nil")

		local sawBankRequired = false
		local sawNoItems = false
		local sawConflict = false
		for i = msgStart + 1, #chatMessages do
			if chatMessages[i]:find("Bank or Guild Bank must be open and active.", 1, true) then
				sawBankRequired = true
			end
			if chatMessages[i]:find("No items need consolidation.", 1, true) then
				sawNoItems = true
			end
			if chatMessages[i]:find("conflicting destinations", 1, true) then
				sawConflict = true
			end
		end
		assertTrue(sawBankRequired, "Test 12d printed Bank or Guild Bank must be open and active.")
		assertFalse(sawNoItems, "Test 12d did not emit No items need consolidation.")
		assertFalse(sawConflict, "Test 12d did not emit conflict warnings before aborting")

		-- Guild Bank remains unaffected and does not call C_Bank.CanUseBank
		canUseCalls = 0
		BagnonConsolidatorDB.guildTabs[guildKey] = {
			[2589] = { tab = 1, name = "Linen Cloth" },
		}
		mockInventorySlots = {
			[0] = {
				[1] = { itemID = 2589, stackCount = 10, hyperlink = "[Linen Cloth]" },
			},
		}
		mockBankFrame.shown = false
		mockGuildFrame.shown = true

		Addon.ConsolidateEngine:Start(mockGuildFrame)

		assertEqual(canUseCalls, 0, "Test 12d guild bank did not call C_Bank.CanUseBank")
		assertEqual(libItemMove.lastContext, "BagToGuildBank", "Test 12d guild bank context unaffected")
		assertTrue(libItemMove.lastMovedQueue ~= nil, "Test 12d guild moveQueue dispatched")
		if libItemMove.lastMovedQueue and libItemMove.lastMovedQueue[1] then
			assertEqual(libItemMove.lastMovedQueue[1]["2589"], 10, "Test 12d Linen Cloth queued for Tab 1")
		end
	end

	mockGuildFrame.shown = prevGuildShown
	mockBankFrame.shown = prevBankShown
	mockInventorySlots = prevInventorySlots
	mockGuildBagInfo = prevGuildBagInfo
	mockBankSlots = prevBankSlots
	Addon.BankBags = prevBankBags
	_G["C_Bank"] = prevCBank
	_G["Enum"] = prevEnum

	print("[PASS] Test 12: Character Bank vs Account/Warband Bank Isolation (#10)")
end

-- ----------------------------------------------------
-- Test 13: Cross-Flavor SOUNDKIT Playback Guards & Fallbacks (#11)
-- ----------------------------------------------------
do
	local prevSoundKit = _G["SOUNDKIT"]
	local prevEnum = _G["Enum"]
	local prevCBank = _G["C_Bank"]
	local prevInventorySlots = mockInventorySlots
	local prevBankShown = mockBankFrame.shown
	local prevGuildShown = mockGuildFrame.shown

	local charKey = Addon.GetCharacterKey()
	assertTrue(charKey ~= nil, "charKey is valid for Test 13")

	if charKey then
		local prevPersonalBank = BagnonConsolidatorDB.personalBanks[charKey]
		local prevConflicts = BagnonConsolidatorDB.conflicts
		local prevIgnored = BagnonConsolidatorDB.ignored
		local libItemMove = LibStub('LibItemMove-1.0') --[[@as MockLibItemMove]]
		local origMove = libItemMove.Move
		local chatMessages = (DEFAULT_CHAT_FRAME --[[@as { messages: string[] }]]).messages

		local function hasChatMessageSince(startIdx, pattern)
			for i = startIdx + 1, #chatMessages do
				if chatMessages[i]:find(pattern, 1, true) then
					return true
				end
			end
			return false
		end

		BagnonConsolidatorDB.personalBanks[charKey] = {
			[2447] = "Peacebloom",
		}
		BagnonConsolidatorDB.conflicts = {}
		BagnonConsolidatorDB.ignored = {}
		mockBankFrame.shown = true
		mockGuildFrame.shown = false

		-- 13a: DONE plays UI_BAG_SORTING_01 when present
		_G["SOUNDKIT"] = {
			UI_BAG_SORTING_01 = 43937,
			IG_BACKPACK_CLOSE = 863,
			IG_QUEST_CANCEL = 879,
		}
		mockInventorySlots = {
			[0] = {
				[1] = { itemID = 2447, stackCount = 5, hyperlink = "[Peacebloom]" },
			},
		}
		local soundStart = #playedSounds
		Addon.ConsolidateEngine:Start(mockBankFrame)
		assertEqual(#playedSounds - soundStart, 1, "Test 13a played 1 sound on DONE")
		assertEqual(playedSounds[soundStart + 1], 43937, "Test 13a played UI_BAG_SORTING_01")

		-- 13b: DONE falls back to IG_BACKPACK_CLOSE when UI_BAG_SORTING_01 is nil
		_G["SOUNDKIT"] = {
			IG_BACKPACK_CLOSE = 863,
			IG_QUEST_CANCEL = 879,
		}
		soundStart = #playedSounds
		Addon.ConsolidateEngine:Start(mockBankFrame)
		assertEqual(#playedSounds - soundStart, 1, "Test 13b played 1 sound on DONE fallback")
		assertEqual(playedSounds[soundStart + 1], 863, "Test 13b fell back to IG_BACKPACK_CLOSE")

		-- 13c: DONE with SOUNDKIT = {} and SOUNDKIT = nil no-ops safely and resets isConsolidating
		for _, labelAndKit in ipairs({
			{ label = "empty table", kit = {} },
			{ label = "nil", kit = nil },
		}) do
			_G["SOUNDKIT"] = labelAndKit.kit
			soundStart = #playedSounds
			local msgStart = #chatMessages
			Addon.ConsolidateEngine:Start(mockBankFrame)
			assertEqual(#playedSounds - soundStart, 0, "Test 13c (" .. labelAndKit.label .. ") played 0 sounds on DONE")
			assertTrue(hasChatMessageSince(msgStart, "Consolidation complete."), "Test 13c (" .. labelAndKit.label .. ") still printed completion message")

			-- Verify isConsolidating reset behaviorally with a subsequent dispatch
			_G["SOUNDKIT"] = { UI_BAG_SORTING_01 = 43937 }
			libItemMove.lastMovedQueue = nil
			msgStart = #chatMessages
			Addon.ConsolidateEngine:Start(mockBankFrame)
			assertTrue(libItemMove.lastMovedQueue ~= nil, "Test 13c (" .. labelAndKit.label .. ") subsequent run dispatched")
			assertFalse(hasChatMessageSince(msgStart, "Consolidation is already in progress."), "Test 13c (" .. labelAndKit.label .. ") did not remain stuck consolidating")
		end

		-- 13d: Empty queue, TIMEOUT_ERROR, and unusable bank play IG_QUEST_CANCEL (not 847) and no-op when SOUNDKIT is {} or nil
		-- 1) Empty queue
		mockInventorySlots = { [0] = {} }
		_G["SOUNDKIT"] = { IG_QUEST_CANCEL = 879 }
		soundStart = #playedSounds
		Addon.ConsolidateEngine:Start(mockBankFrame)
		assertEqual(#playedSounds - soundStart, 1, "Test 13d empty queue played 1 sound")
		assertEqual(playedSounds[soundStart + 1], 879, "Test 13d empty queue played IG_QUEST_CANCEL instead of 847")

		_G["SOUNDKIT"] = {}
		soundStart = #playedSounds
		Addon.ConsolidateEngine:Start(mockBankFrame)
		assertEqual(#playedSounds - soundStart, 0, "Test 13d empty queue with SOUNDKIT={} played 0 sounds")

		_G["SOUNDKIT"] = nil
		soundStart = #playedSounds
		Addon.ConsolidateEngine:Start(mockBankFrame)
		assertEqual(#playedSounds - soundStart, 0, "Test 13d empty queue with SOUNDKIT=nil played 0 sounds")

		-- 2) TIMEOUT_ERROR callback
		mockInventorySlots = {
			[0] = {
				[1] = { itemID = 2447, stackCount = 5, hyperlink = "[Peacebloom]" },
			},
		}
		libItemMove.Move = function(self, queue, context, callback)
			self.lastMovedQueue = queue
			self.lastContext = context
			if callback then
				callback("TIMEOUT_ERROR")
			end
		end

		_G["SOUNDKIT"] = { IG_QUEST_CANCEL = 879 }
		soundStart = #playedSounds
		local errMsgStart = #chatMessages
		Addon.ConsolidateEngine:Start(mockBankFrame)
		assertEqual(#playedSounds - soundStart, 1, "Test 13d TIMEOUT_ERROR played 1 sound")
		assertEqual(playedSounds[soundStart + 1], 879, "Test 13d TIMEOUT_ERROR played IG_QUEST_CANCEL instead of 847")
		assertTrue(hasChatMessageSince(errMsgStart, "TIMEOUT_ERROR"), "Test 13d TIMEOUT_ERROR printed stop message")

		for _, labelAndKit in ipairs({
			{ label = "empty table", kit = {} },
			{ label = "nil", kit = nil },
		}) do
			_G["SOUNDKIT"] = labelAndKit.kit
			soundStart = #playedSounds
			Addon.ConsolidateEngine:Start(mockBankFrame)
			assertEqual(#playedSounds - soundStart, 0, "Test 13d TIMEOUT_ERROR (" .. labelAndKit.label .. ") played 0 sounds")

			-- Verify isConsolidating reset after error callback
			libItemMove.lastMovedQueue = nil
			errMsgStart = #chatMessages
			Addon.ConsolidateEngine:Start(mockBankFrame)
			assertTrue(libItemMove.lastMovedQueue ~= nil, "Test 13d TIMEOUT_ERROR (" .. labelAndKit.label .. ") subsequent run dispatched")
			assertFalse(hasChatMessageSince(errMsgStart, "Consolidation is already in progress."), "Test 13d TIMEOUT_ERROR (" .. labelAndKit.label .. ") reset isConsolidating")
		end

		libItemMove.Move = origMove

		-- 3) Unusable character bank (CanUseBank == false)
		_G["Enum"] = { BankType = { Character = 0 } } --[[@as any]]
		_G["C_Bank"] = {
			CanUseBank = function() return false end,
		} --[[@as any]]

		_G["SOUNDKIT"] = { IG_QUEST_CANCEL = 879 }
		soundStart = #playedSounds
		Addon.ConsolidateEngine:Start(mockBankFrame)
		assertEqual(#playedSounds - soundStart, 1, "Test 13d unusable bank played 1 sound")
		assertEqual(playedSounds[soundStart + 1], 879, "Test 13d unusable bank played IG_QUEST_CANCEL instead of 847")

		_G["SOUNDKIT"] = {}
		soundStart = #playedSounds
		Addon.ConsolidateEngine:Start(mockBankFrame)
		assertEqual(#playedSounds - soundStart, 0, "Test 13d unusable bank with SOUNDKIT={} played 0 sounds")

		_G["SOUNDKIT"] = nil
		soundStart = #playedSounds
		Addon.ConsolidateEngine:Start(mockBankFrame)
		assertEqual(#playedSounds - soundStart, 0, "Test 13d unusable bank with SOUNDKIT=nil played 0 sounds")

		BagnonConsolidatorDB.personalBanks[charKey] = prevPersonalBank
		BagnonConsolidatorDB.conflicts = prevConflicts
		BagnonConsolidatorDB.ignored = prevIgnored
	end

	mockGuildFrame.shown = prevGuildShown
	mockBankFrame.shown = prevBankShown
	mockInventorySlots = prevInventorySlots
	_G["C_Bank"] = prevCBank
	_G["Enum"] = prevEnum
	_G["SOUNDKIT"] = prevSoundKit

	print("[PASS] Test 13: Cross-Flavor SOUNDKIT Playback Guards & Fallbacks (#11)")
end

-- ----------------------------------------------------
-- Test 14: Cross-Flavor Keyring Container Resolution (#12)
-- ----------------------------------------------------
do
	local prevKeyring = _G["KEYRING_CONTAINER"]
	local prevEnum = _G["Enum"]
	local prevCBank = _G["C_Bank"]
	local prevInventoryBags = Addon.InventoryBags
	local prevInventorySlots = mockInventorySlots
	local prevBankShown = mockBankFrame.shown
	local prevGuildShown = mockGuildFrame.shown

	local charKey = Addon.GetCharacterKey()
	local guildKey = Addon.GetGuildKey()
	assertTrue(charKey ~= nil, "charKey is valid for Test 14")
	assertTrue(guildKey ~= nil, "guildKey is valid for Test 14")

	if charKey and guildKey then
		local prevPersonalBank = BagnonConsolidatorDB.personalBanks[charKey]
		local prevGuildTabs = BagnonConsolidatorDB.guildTabs[guildKey]
		local prevConflicts = BagnonConsolidatorDB.conflicts
		local prevIgnored = BagnonConsolidatorDB.ignored
		local libItemMove = LibStub('LibItemMove-1.0') --[[@as MockLibItemMove]]

		_G["C_Bank"] = nil
		BagnonConsolidatorDB.personalBanks[charKey] = {
			[2447] = "Peacebloom",
		}
		BagnonConsolidatorDB.guildTabs[guildKey] = {
			[2589] = { tab = 1, name = "Linen Cloth" },
		}
		BagnonConsolidatorDB.conflicts = {}
		BagnonConsolidatorDB.ignored = {}

		-- 14a: Classic / Mists (KEYRING_CONTAINER = -2, Enum.BagIndex.Keyring = -2) skips bag -2
		_G["KEYRING_CONTAINER"] = -2
		_G["Enum"] = {
			BagIndex = {
				Keyring = -2,
				Bank = -1,
			},
		} --[[@as any]]
		Addon.InventoryBags = { 0, 1, 2, 3, 4, -2 }
		mockInventorySlots = {
			[0] = {
				[1] = { itemID = 2447, stackCount = 5, hyperlink = "[Peacebloom]" },
				[2] = { itemID = 2589, stackCount = 7, hyperlink = "[Linen Cloth]" },
			},
			[-2] = {
				[1] = { itemID = 2447, stackCount = 20, hyperlink = "[Peacebloom]" },
				[2] = { itemID = 2589, stackCount = 20, hyperlink = "[Linen Cloth]" },
			},
		}

		mockBankFrame.shown = true
		mockGuildFrame.shown = false
		libItemMove.lastMovedQueue = nil
		libItemMove.lastContext = nil
		Addon.ConsolidateEngine:Start(mockBankFrame)
		assertEqual(libItemMove.lastContext, "BagToBank", "Test 14a personal bank context")
		assertTrue(libItemMove.lastMovedQueue ~= nil, "Test 14a personal moveQueue created")
		if libItemMove.lastMovedQueue then
			assertEqual(libItemMove.lastMovedQueue["2447"], 5, "Test 14a personal bank skipped keyring (-2)")
		end

		mockBankFrame.shown = false
		mockGuildFrame.shown = true
		libItemMove.lastMovedQueue = nil
		libItemMove.lastContext = nil
		Addon.ConsolidateEngine:Start(mockGuildFrame)
		assertEqual(libItemMove.lastContext, "BagToGuildBank", "Test 14a guild bank context")
		assertTrue(libItemMove.lastMovedQueue ~= nil and libItemMove.lastMovedQueue[1] ~= nil, "Test 14a guild Tab 1 queue created")
		if libItemMove.lastMovedQueue and libItemMove.lastMovedQueue[1] then
			assertEqual(libItemMove.lastMovedQueue[1]["2589"], 7, "Test 14a guild bank skipped keyring (-2)")
		end

		-- 14b: Retail / Forever (KEYRING_CONTAINER = nil, Enum.BagIndex.Keyring = -1, Characterbanktab = -2)
		_G["KEYRING_CONTAINER"] = nil
		_G["Enum"] = {
			BagIndex = {
				Keyring = -1,
				Characterbanktab = -2,
			},
		} --[[@as any]]
		Addon.InventoryBags = { 0, 1, 2, 3, 4, -1, -2 }
		mockInventorySlots = {
			[0] = {
				[1] = { itemID = 2447, stackCount = 5, hyperlink = "[Peacebloom]" },
				[2] = { itemID = 2589, stackCount = 7, hyperlink = "[Linen Cloth]" },
			},
			[-1] = {
				[1] = { itemID = 2447, stackCount = 20, hyperlink = "[Peacebloom]" },
				[2] = { itemID = 2589, stackCount = 20, hyperlink = "[Linen Cloth]" },
			},
			[-2] = {
				[1] = { itemID = 2447, stackCount = 3, hyperlink = "[Peacebloom]" },
				[2] = { itemID = 2589, stackCount = 4, hyperlink = "[Linen Cloth]" },
			},
		}

		mockBankFrame.shown = true
		mockGuildFrame.shown = false
		libItemMove.lastMovedQueue = nil
		libItemMove.lastContext = nil
		Addon.ConsolidateEngine:Start(mockBankFrame)
		assertEqual(libItemMove.lastContext, "BagToBank", "Test 14b personal bank context")
		assertTrue(libItemMove.lastMovedQueue ~= nil, "Test 14b personal moveQueue created")
		if libItemMove.lastMovedQueue then
			assertEqual(libItemMove.lastMovedQueue["2447"], 8, "Test 14b personal bank skipped -1 and kept -2")
		end

		mockBankFrame.shown = false
		mockGuildFrame.shown = true
		libItemMove.lastMovedQueue = nil
		libItemMove.lastContext = nil
		Addon.ConsolidateEngine:Start(mockGuildFrame)
		assertEqual(libItemMove.lastContext, "BagToGuildBank", "Test 14b guild bank context")
		assertTrue(libItemMove.lastMovedQueue ~= nil and libItemMove.lastMovedQueue[1] ~= nil, "Test 14b guild Tab 1 queue created")
		if libItemMove.lastMovedQueue and libItemMove.lastMovedQueue[1] then
			assertEqual(libItemMove.lastMovedQueue[1]["2589"], 11, "Test 14b guild bank skipped -1 and kept -2")
		end

		-- Precedence check: Enum.BagIndex.Keyring (-1) still wins if stray global KEYRING_CONTAINER = -2 exists
		_G["KEYRING_CONTAINER"] = -2
		mockBankFrame.shown = true
		mockGuildFrame.shown = false
		libItemMove.lastMovedQueue = nil
		Addon.ConsolidateEngine:Start(mockBankFrame)
		assertTrue(libItemMove.lastMovedQueue ~= nil, "Test 14b precedence personal moveQueue created")
		if libItemMove.lastMovedQueue then
			assertEqual(libItemMove.lastMovedQueue["2447"], 8, "Test 14b Enum.BagIndex.Keyring takes precedence over stray KEYRING_CONTAINER")
		end

		-- 14c: Legacy Fallback (KEYRING_CONTAINER = nil, Enum = nil) falls back to -2
		_G["KEYRING_CONTAINER"] = nil
		_G["Enum"] = nil
		Addon.InventoryBags = { 0, 1, 2, 3, 4, -2 }
		mockInventorySlots = {
			[0] = {
				[1] = { itemID = 2447, stackCount = 5, hyperlink = "[Peacebloom]" },
				[2] = { itemID = 2589, stackCount = 7, hyperlink = "[Linen Cloth]" },
			},
			[-2] = {
				[1] = { itemID = 2447, stackCount = 20, hyperlink = "[Peacebloom]" },
				[2] = { itemID = 2589, stackCount = 20, hyperlink = "[Linen Cloth]" },
			},
		}

		mockBankFrame.shown = true
		mockGuildFrame.shown = false
		libItemMove.lastMovedQueue = nil
		libItemMove.lastContext = nil
		Addon.ConsolidateEngine:Start(mockBankFrame)
		assertEqual(libItemMove.lastContext, "BagToBank", "Test 14c personal bank context")
		assertTrue(libItemMove.lastMovedQueue ~= nil, "Test 14c personal moveQueue created")
		if libItemMove.lastMovedQueue then
			assertEqual(libItemMove.lastMovedQueue["2447"], 5, "Test 14c personal bank fallback skipped -2")
		end

		mockBankFrame.shown = false
		mockGuildFrame.shown = true
		libItemMove.lastMovedQueue = nil
		libItemMove.lastContext = nil
		Addon.ConsolidateEngine:Start(mockGuildFrame)
		assertEqual(libItemMove.lastContext, "BagToGuildBank", "Test 14c guild bank context")
		assertTrue(libItemMove.lastMovedQueue ~= nil and libItemMove.lastMovedQueue[1] ~= nil, "Test 14c guild Tab 1 queue created")
		if libItemMove.lastMovedQueue and libItemMove.lastMovedQueue[1] then
			assertEqual(libItemMove.lastMovedQueue[1]["2589"], 7, "Test 14c guild bank fallback skipped -2")
		end

		BagnonConsolidatorDB.personalBanks[charKey] = prevPersonalBank
		BagnonConsolidatorDB.guildTabs[guildKey] = prevGuildTabs
		BagnonConsolidatorDB.conflicts = prevConflicts
		BagnonConsolidatorDB.ignored = prevIgnored
	end

	mockGuildFrame.shown = prevGuildShown
	mockBankFrame.shown = prevBankShown
	mockInventorySlots = prevInventorySlots
	Addon.InventoryBags = prevInventoryBags
	_G["C_Bank"] = prevCBank
	_G["Enum"] = prevEnum
	_G["KEYRING_CONTAINER"] = prevKeyring

	print("[PASS] Test 14: Cross-Flavor Keyring Container Resolution (#12)")
end

-- ----------------------------------------------------
-- Test 15: Guild Bank Soulbound Filtering & GetGuildBankTabInfo Guards (#13)
-- ----------------------------------------------------
do
	local prevCContainer = _G["C_Container"]
	local prevGetGuildBankTabInfo = _G["GetGuildBankTabInfo"]
	local prevCBank = _G["C_Bank"]
	local prevInventorySlots = mockInventorySlots
	local prevGuildBagInfo = mockGuildBagInfo
	local prevBankShown = mockBankFrame.shown
	local prevGuildShown = mockGuildFrame.shown

	local charKey = Addon.GetCharacterKey()
	local guildKey = Addon.GetGuildKey()
	assertTrue(charKey ~= nil, "charKey is valid for Test 15")
	assertTrue(guildKey ~= nil, "guildKey is valid for Test 15")

	if charKey and guildKey then
		local prevPersonalBanks = BagnonConsolidatorDB.personalBanks
		local prevGuildTabs = BagnonConsolidatorDB.guildTabs
		local prevTabNames = BagnonConsolidatorDB.tabNames
		local prevConflicts = BagnonConsolidatorDB.conflicts
		local prevIgnored = BagnonConsolidatorDB.ignored
		local libItemMove = LibStub('LibItemMove-1.0') --[[@as MockLibItemMove]]
		local chatMessages = (DEFAULT_CHAT_FRAME --[[@as { messages: string[] }]]).messages

		local function hasChatMessageSince(startIdx, pattern)
			for i = startIdx + 1, #chatMessages do
				if chatMessages[i]:find(pattern, 1, true) then
					return true
				end
			end
			return false
		end

		_G["C_Bank"] = nil
		BagnonConsolidatorDB.personalBanks = {}
		BagnonConsolidatorDB.guildTabs = {
			[guildKey] = {
				[2589] = { tab = 1, name = "Linen Cloth" }, -- Tab 1 has canDeposit = true
				[1710] = { tab = 3, name = "Greater Healing Potion" }, -- Tab 3 has canDeposit = false
			},
		}
		BagnonConsolidatorDB.conflicts = {}
		BagnonConsolidatorDB.ignored = {}

		-- 15a: All matching items soulbound via item.isBound = true -> skip Move and print No items need consolidation.
		mockInventorySlots = {
			[0] = {
				[1] = { itemID = 2589, stackCount = 5, hyperlink = "[Linen Cloth]", isBound = true },
			},
		}
		mockBankFrame.shown = false
		mockGuildFrame.shown = true
		libItemMove.lastMovedQueue = nil
		libItemMove.lastContext = nil

		local soundStart = #playedSounds
		local msgStart = #chatMessages
		Addon.ConsolidateEngine:Start(mockGuildFrame)

		assertEqual(libItemMove.lastMovedQueue, nil, "Test 15a LibItemMove:Move not called when all items soulbound")
		assertEqual(libItemMove.lastContext, nil, "Test 15a context remains nil")
		assertEqual(#playedSounds - soundStart, 1, "Test 15a played 1 cancel sound")
		assertEqual(playedSounds[soundStart + 1], 879, "Test 15a played IG_QUEST_CANCEL")
		assertTrue(hasChatMessageSince(msgStart, "No items need consolidation."), "Test 15a printed No items need consolidation.")
		assertFalse(hasChatMessageSince(msgStart, "Consolidation complete."), "Test 15a did not print Consolidation complete.")

		-- 15b: Mixed soulbound and unbound stacks -> only unbound queued; unmapped/non-depositable skip C_Container
		local containerInfoCalls = 0
		_G["C_Container"] = {
			GetContainerItemInfo = function(bag, slot)
				containerInfoCalls = containerInfoCalls + 1
				return nil
			end,
		} --[[@as any]]

		mockInventorySlots = {
			[0] = {
				[1] = { itemID = 2589, stackCount = 5, hyperlink = "[Linen Cloth]", isBound = true },
				[2] = { itemID = 2589, stackCount = 10, hyperlink = "[Linen Cloth]", isBound = false },
				[3] = { itemID = 9999, stackCount = 1, hyperlink = "[Unmapped Item]" },
				[4] = { itemID = 1710, stackCount = 2, hyperlink = "[Greater Healing Potion]" },
			},
		}
		libItemMove.lastMovedQueue = nil
		libItemMove.lastContext = nil
		Addon.ConsolidateEngine:Start(mockGuildFrame)

		assertEqual(libItemMove.lastContext, "BagToGuildBank", "Test 15b guild bank context")
		assertTrue(libItemMove.lastMovedQueue ~= nil and libItemMove.lastMovedQueue[1] ~= nil, "Test 15b Tab 1 queue created")
		if libItemMove.lastMovedQueue and libItemMove.lastMovedQueue[1] then
			assertEqual(libItemMove.lastMovedQueue[1]["2589"], 10, "Test 15b queued only unbound stack quantity")
		end
		assertEqual(libItemMove.lastMovedQueue and libItemMove.lastMovedQueue[3], nil, "Test 15b Tab 3 excluded")
		assertEqual(containerInfoCalls, 0, "Test 15b skipped C_Container fallback for explicit isBound and unmapped/non-depositable slots")

		-- 15c: C_Container.GetContainerItemInfo fallback when item.isBound is nil
		local checkedFallbackSlots = {}
		local fallbackBoundMap = {
			["0:1"] = { isBound = true },
			["0:2"] = { isBound = false },
			["0:3"] = nil,
		}
		containerInfoCalls = 0
		_G["C_Container"] = {
			GetContainerItemInfo = function(bag, slot)
				containerInfoCalls = containerInfoCalls + 1
				local key = tostring(bag) .. ":" .. tostring(slot)
				checkedFallbackSlots[key] = true
				return fallbackBoundMap[key]
			end,
		} --[[@as any]]

		mockInventorySlots = {
			[0] = {
				[1] = { itemID = 2589, stackCount = 4, hyperlink = "[Linen Cloth]" },
				[2] = { itemID = 2589, stackCount = 6, hyperlink = "[Linen Cloth]" },
				[3] = { itemID = 2589, stackCount = 3, hyperlink = "[Linen Cloth]" },
				[4] = { itemID = 2589, stackCount = 2, hyperlink = "[Linen Cloth]", isBound = false },
			},
		}
		libItemMove.lastMovedQueue = nil
		libItemMove.lastContext = nil
		Addon.ConsolidateEngine:Start(mockGuildFrame)

		assertEqual(libItemMove.lastContext, "BagToGuildBank", "Test 15c fallback guild context")
		assertTrue(libItemMove.lastMovedQueue ~= nil and libItemMove.lastMovedQueue[1] ~= nil, "Test 15c Tab 1 queue created")
		if libItemMove.lastMovedQueue and libItemMove.lastMovedQueue[1] then
			assertEqual(libItemMove.lastMovedQueue[1]["2589"], 11, "Test 15c queued unbound fallback, nil fallback, and explicit unbound slots")
		end
		assertEqual(containerInfoCalls, 3, "Test 15c consulted C_Container.GetContainerItemInfo only for nil isBound slots")
		assertTrue(checkedFallbackSlots["0:1"] and checkedFallbackSlots["0:2"] and checkedFallbackSlots["0:3"], "Test 15c checked slots 1-3")
		assertEqual(checkedFallbackSlots["0:4"], nil, "Test 15c did not consult C_Container for explicit isBound=false slot 4")

		-- C_Container == nil with item.isBound == nil defaults to unbound without error
		_G["C_Container"] = nil
		mockInventorySlots = {
			[0] = {
				[1] = { itemID = 2589, stackCount = 7, hyperlink = "[Linen Cloth]" },
			},
		}
		libItemMove.lastMovedQueue = nil
		libItemMove.lastContext = nil
		Addon.ConsolidateEngine:Start(mockGuildFrame)
		assertEqual(libItemMove.lastContext, "BagToGuildBank", "Test 15c nil C_Container guild context")
		assertTrue(libItemMove.lastMovedQueue ~= nil and libItemMove.lastMovedQueue[1] ~= nil, "Test 15c nil C_Container Tab 1 queue created")
		if libItemMove.lastMovedQueue and libItemMove.lastMovedQueue[1] then
			assertEqual(libItemMove.lastMovedQueue[1]["2589"], 7, "Test 15c nil C_Container defaults to unbound")
		end

		-- 15d: Personal Bank consolidation still queues soulbound items normally
		BagnonConsolidatorDB.personalBanks[charKey] = {
			[2447] = "Peacebloom",
		}
		mockInventorySlots = {
			[0] = {
				[1] = { itemID = 2447, stackCount = 6, hyperlink = "[Peacebloom]", isBound = true },
			},
		}
		mockBankFrame.shown = true
		mockGuildFrame.shown = false
		libItemMove.lastMovedQueue = nil
		libItemMove.lastContext = nil
		Addon.ConsolidateEngine:Start(mockBankFrame)

		assertEqual(libItemMove.lastContext, "BagToBank", "Test 15d personal bank context")
		assertTrue(libItemMove.lastMovedQueue ~= nil, "Test 15d personal moveQueue created")
		if libItemMove.lastMovedQueue then
			assertEqual(libItemMove.lastMovedQueue["2447"], 6, "Test 15d personal bank still queues soulbound items")
		end

		-- 15e: GetGuildBankTabInfo == nil guards in Engine:Start and TakeSnapshot
		_G["GetGuildBankTabInfo"] = nil
		mockInventorySlots = {
			[0] = {
				[1] = { itemID = 2589, stackCount = 10, hyperlink = "[Linen Cloth]", isBound = false },
			},
		}
		mockBankFrame.shown = false
		mockGuildFrame.shown = true
		libItemMove.lastMovedQueue = nil
		libItemMove.lastContext = nil
		msgStart = #chatMessages
		Addon.ConsolidateEngine:Start(mockGuildFrame)

		assertEqual(libItemMove.lastMovedQueue, nil, "Test 15e Engine:Start fails closed when GetGuildBankTabInfo is nil")
		assertEqual(libItemMove.lastContext, nil, "Test 15e context remains nil when GetGuildBankTabInfo is nil")
		assertTrue(hasChatMessageSince(msgStart, "No items need consolidation."), "Test 15e Engine:Start printed No items need consolidation.")

		BagnonConsolidatorDB.personalBanks = {}
		BagnonConsolidatorDB.guildTabs = {}
		BagnonConsolidatorDB.conflicts = {}
		mockGuildBagInfo = {
			[1] = { items = { [1] = { itemID = 2589, stackCount = 20, hyperlink = "[Linen Cloth]" } } },
		}
		local snapSuccess = Addon.TakeSnapshot(mockGuildFrame)
		assertTrue(snapSuccess, "Test 15e TakeSnapshot succeeds when GetGuildBankTabInfo is nil")
		assertTrue(BagnonConsolidatorDB.guildTabs[guildKey] ~= nil and BagnonConsolidatorDB.guildTabs[guildKey][2589] ~= nil, "Test 15e TakeSnapshot mapped item with nil GetGuildBankTabInfo")
		if BagnonConsolidatorDB.guildTabs[guildKey] and BagnonConsolidatorDB.guildTabs[guildKey][2589] then
			assertEqual(BagnonConsolidatorDB.guildTabs[guildKey][2589].tab, 1, "Test 15e TakeSnapshot recorded tab 1")
			assertEqual(BagnonConsolidatorDB.guildTabs[guildKey][2589].tabName, nil, "Test 15e TakeSnapshot recorded nil tabName")
		end

		BagnonConsolidatorDB.personalBanks = prevPersonalBanks
		BagnonConsolidatorDB.guildTabs = prevGuildTabs
		BagnonConsolidatorDB.tabNames = prevTabNames
		BagnonConsolidatorDB.conflicts = prevConflicts
		BagnonConsolidatorDB.ignored = prevIgnored
	end

	mockGuildFrame.shown = prevGuildShown
	mockBankFrame.shown = prevBankShown
	mockGuildBagInfo = prevGuildBagInfo
	mockInventorySlots = prevInventorySlots
	_G["C_Bank"] = prevCBank
	_G["GetGuildBankTabInfo"] = prevGetGuildBankTabInfo
	_G["C_Container"] = prevCContainer

	print("[PASS] Test 15: Guild Bank Soulbound Filtering & GetGuildBankTabInfo Guards (#13)")
end

-- ----------------------------------------------------
-- Test 16: Viewer Reset Mappings Scope Across All Tabs (#3)
-- ----------------------------------------------------
do
	local prevStaticPopupShow = _G["StaticPopup_Show"]
	local prevMenuUtil = _G["MenuUtil"]
	local prevPersonalBanks = BagnonConsolidatorDB.personalBanks
	local prevGuildTabs = BagnonConsolidatorDB.guildTabs
	local prevIgnored = BagnonConsolidatorDB.ignored
	local prevConflicts = BagnonConsolidatorDB.conflicts

	local charKey = Addon.GetCharacterKey()
	local guildKey = Addon.GetGuildKey()
	assertTrue(charKey ~= nil, "charKey is valid for Test 16")
	assertTrue(guildKey ~= nil, "guildKey is valid for Test 16")

	---@type any
	local viewerFrame
	---@type any
	local resetBtn
	for _, f in ipairs(eventFrames) do
		if f.name == "BagnonConsolidatorViewerFrame" then
			viewerFrame = f
		elseif f.text == "Reset Mappings..." then
			resetBtn = f
		end
	end

	assertTrue(viewerFrame ~= nil, "Test 16 located BagnonConsolidatorViewerFrame")
	assertTrue(resetBtn ~= nil, "Test 16 located Reset Mappings button")

	if viewerFrame and resetBtn and charKey and guildKey then
		local wasShown = viewerFrame:IsShown()
		if not wasShown then
			Addon.Viewer:Toggle()
		end

		local lastPopup
		_G["StaticPopup_Show"] = function(which, text1, text2, data)
			lastPopup = {
				which = which,
				text1 = text1,
				text2 = text2,
				data = data,
			}
		end

		local function seedDB()
			BagnonConsolidatorDB.guildTabs = {
				[guildKey] = {
					[2589] = { tab = 1, name = "Linen Cloth" },
				},
			}
			BagnonConsolidatorDB.personalBanks = {
				[charKey] = {
					[2447] = "Peacebloom",
				},
			}
			BagnonConsolidatorDB.ignored = {
				[1710] = "Greater Healing Potion",
			}
			BagnonConsolidatorDB.conflicts = {
				[guildKey] = {
					[1205] = { name = "Iron Ore", personal = false, tabs = { 2, 3 }, reason = "Present on multiple Guild Bank tabs" },
				},
				[charKey] = {
					[765] = { name = "Silverleaf", personal = true, reason = "Multiple destinations" },
				},
			}
		end

		local function acceptLastPopup()
			assertTrue(lastPopup ~= nil, "Test 16 StaticPopup_Show was invoked")
			if lastPopup then
				local dialog = StaticPopupDialogs[lastPopup.which]
				assertTrue(dialog ~= nil and type(dialog.OnAccept) == "function", "Test 16 dialog OnAccept exists")
				if dialog and dialog.OnAccept then
					dialog.OnAccept(nil, lastPopup.data)
				end
			end
		end

		-- 16a: Conflicts tab passes scope "all" and clears all DB tables
		seedDB()
		lastPopup = nil
		viewerFrame.conflictsTab:GetScript("OnClick")()
		resetBtn:GetScript("OnClick")()
		assertTrue(lastPopup ~= nil, "Test 16a popup shown on Conflicts tab")
		if lastPopup then
			assertEqual(lastPopup.which, "BAGNON_CONSOLIDATOR_RESET_CONFIRM", "Test 16a popup id")
			assertEqual(lastPopup.text1, "All Addon Data", "Test 16a popup label")
			assertEqual(lastPopup.text2, nil, "Test 16a popup text2")
			assertEqual(lastPopup.data, "all", "Test 16a popup scope is all")
		end
		acceptLastPopup()
		assertTrue(next(BagnonConsolidatorDB.guildTabs) == nil, "Test 16a guildTabs cleared")
		assertTrue(next(BagnonConsolidatorDB.personalBanks) == nil, "Test 16a personalBanks cleared")
		assertTrue(next(BagnonConsolidatorDB.ignored) == nil, "Test 16a ignored cleared")
		assertTrue(next(BagnonConsolidatorDB.conflicts) == nil, "Test 16a conflicts cleared")

		-- 16b: Ignored tab passes scope "all" and clears all DB tables
		seedDB()
		lastPopup = nil
		viewerFrame.ignoredTab:GetScript("OnClick")()
		resetBtn:GetScript("OnClick")()
		assertTrue(lastPopup ~= nil, "Test 16b popup shown on Ignored tab")
		if lastPopup then
			assertEqual(lastPopup.which, "BAGNON_CONSOLIDATOR_RESET_CONFIRM", "Test 16b popup id")
			assertEqual(lastPopup.text1, "All Addon Data", "Test 16b popup label")
			assertEqual(lastPopup.text2, nil, "Test 16b popup text2")
			assertEqual(lastPopup.data, "all", "Test 16b popup scope is all")
		end
		acceptLastPopup()
		assertTrue(next(BagnonConsolidatorDB.guildTabs) == nil, "Test 16b guildTabs cleared")
		assertTrue(next(BagnonConsolidatorDB.personalBanks) == nil, "Test 16b personalBanks cleared")
		assertTrue(next(BagnonConsolidatorDB.ignored) == nil, "Test 16b ignored cleared")
		assertTrue(next(BagnonConsolidatorDB.conflicts) == nil, "Test 16b conflicts cleared")

		-- 16c: Personal tab passes scope "personal" and clears only personal mappings/conflicts
		seedDB()
		lastPopup = nil
		viewerFrame.personalTab:GetScript("OnClick")()
		resetBtn:GetScript("OnClick")()
		assertTrue(lastPopup ~= nil, "Test 16c popup shown on Personal tab")
		if lastPopup then
			assertEqual(lastPopup.which, "BAGNON_CONSOLIDATOR_RESET_CONFIRM", "Test 16c popup id")
			assertEqual(lastPopup.text1, charKey, "Test 16c popup label is charKey")
			assertEqual(lastPopup.text2, nil, "Test 16c popup text2")
			assertEqual(lastPopup.data, "personal", "Test 16c popup scope is personal")
		end
		acceptLastPopup()
		assertTrue(next(BagnonConsolidatorDB.personalBanks[charKey]) == nil, "Test 16c personalBanks[charKey] cleared")
		assertTrue(next(BagnonConsolidatorDB.conflicts[charKey]) == nil, "Test 16c conflicts[charKey] cleared")
		assertTrue(BagnonConsolidatorDB.guildTabs[guildKey] ~= nil and BagnonConsolidatorDB.guildTabs[guildKey][2589] ~= nil, "Test 16c guildTabs preserved")
		assertTrue(BagnonConsolidatorDB.conflicts[guildKey] ~= nil and BagnonConsolidatorDB.conflicts[guildKey][1205] ~= nil, "Test 16c guild conflicts preserved")
		assertTrue(BagnonConsolidatorDB.ignored[1710] ~= nil, "Test 16c ignored preserved")

		-- 16d: Guild tab passes scope "guild" and clears only guild mappings/conflicts
		seedDB()
		lastPopup = nil
		local menuButtons = {}
		_G["MenuUtil"] = {
			CreateContextMenu = function(parent, callback)
				local menu = {
					SetTag = function(self, tag) end,
					CreateTitle = function(self, title) end,
					CreateButton = function(self, text, fn)
						table.insert(menuButtons, { text = text, fn = fn })
					end,
					CreateDivider = function(self) end,
					CreateCheckbox = function(self, text, getFn, setFn) end,
				}
				if callback then
					callback(parent, menu)
				end
			end,
		} --[[@as any]]

		viewerFrame.guildDropTab:GetScript("OnClick")()
		assertTrue(#menuButtons >= 1 and type(menuButtons[1].fn) == "function", "Test 16d captured guild tab menu buttons")
		if menuButtons[1] and menuButtons[1].fn then
			menuButtons[1].fn()
		end
		assertEqual(viewerFrame.guildDropTab:GetText(), "Tab 1 >", "Test 16d switched to Guild Tab 1")

		resetBtn:GetScript("OnClick")()
		assertTrue(lastPopup ~= nil, "Test 16d popup shown on Guild tab")
		if lastPopup then
			assertEqual(lastPopup.which, "BAGNON_CONSOLIDATOR_RESET_CONFIRM", "Test 16d popup id")
			assertEqual(lastPopup.text1, guildKey, "Test 16d popup label is guildKey")
			assertEqual(lastPopup.text2, nil, "Test 16d popup text2")
			assertEqual(lastPopup.data, "guild", "Test 16d popup scope is guild")
		end
		acceptLastPopup()
		assertTrue(next(BagnonConsolidatorDB.guildTabs[guildKey]) == nil, "Test 16d guildTabs[guildKey] cleared")
		assertTrue(next(BagnonConsolidatorDB.conflicts[guildKey]) == nil, "Test 16d conflicts[guildKey] cleared")
		assertTrue(BagnonConsolidatorDB.personalBanks[charKey] ~= nil and BagnonConsolidatorDB.personalBanks[charKey][2447] ~= nil, "Test 16d personalBanks preserved")
		assertTrue(BagnonConsolidatorDB.conflicts[charKey] ~= nil and BagnonConsolidatorDB.conflicts[charKey][765] ~= nil, "Test 16d personal conflicts preserved")
		assertTrue(BagnonConsolidatorDB.ignored[1710] ~= nil, "Test 16d ignored preserved")

		-- Teardown: restore default tab, viewer visibility, mocks, and DB tables
		viewerFrame.personalTab:GetScript("OnClick")()
		if not wasShown and viewerFrame:IsShown() then
			Addon.Viewer:Toggle()
		end
	end

	BagnonConsolidatorDB.conflicts = prevConflicts
	BagnonConsolidatorDB.ignored = prevIgnored
	BagnonConsolidatorDB.guildTabs = prevGuildTabs
	BagnonConsolidatorDB.personalBanks = prevPersonalBanks
	_G["MenuUtil"] = prevMenuUtil
	_G["StaticPopup_Show"] = prevStaticPopupShow

	print("[PASS] Test 16: Viewer Reset Mappings Scope Across All Tabs (#3)")
end

-- ----------------------------------------------------
-- Test 17: Viewer Escape Key Registration (UISpecialFrames) (#4)
-- ----------------------------------------------------
do
	local function countSpecialFrameEntries(targetName)
		local count = 0
		if UISpecialFrames then
			for _, name in ipairs(UISpecialFrames) do
				if name == targetName then
					count = count + 1
				end
			end
		end
		return count
	end

	-- 17a: Frame is registered once and repeated toggles do not add duplicates
	assertEqual(countSpecialFrameEntries("BagnonConsolidatorViewerFrame"), 1, "Test 17a initial UISpecialFrames registration count")
	Addon.Viewer:Toggle()
	Addon.Viewer:Toggle()
	assertEqual(countSpecialFrameEntries("BagnonConsolidatorViewerFrame"), 1, "Test 17a UISpecialFrames registration remains unique after toggles")

	-- 17b: Simulated CloseSpecialWindows() hides viewer and preserves toggle parity
	local viewerFrame = _G["BagnonConsolidatorViewerFrame"]
	assertTrue(viewerFrame ~= nil, "Test 17b global BagnonConsolidatorViewerFrame exists")
	if viewerFrame then
		if not viewerFrame:IsShown() then
			Addon.Viewer:Toggle()
		end
		assertTrue(viewerFrame:IsShown(), "Test 17b viewer is shown before simulated Escape")

		local closedAny = false
		if UISpecialFrames then
			for _, frameName in pairs(UISpecialFrames) do
				local specialFrame = _G[frameName]
				if specialFrame and specialFrame:IsShown() then
					specialFrame:Hide()
					closedAny = true
				end
			end
		end

		assertTrue(closedAny, "Test 17b CloseSpecialWindows matched a shown special frame")
		assertFalse(viewerFrame:IsShown(), "Test 17b viewer hidden after simulated Escape")

		-- Re-opening via Toggle must immediately show the frame without toggle desync
		Addon.Viewer:Toggle()
		assertTrue(viewerFrame:IsShown(), "Test 17b viewer re-opens on first Toggle after Escape")
		Addon.Viewer:Toggle()
		assertFalse(viewerFrame:IsShown(), "Test 17b viewer closes cleanly on second Toggle")
	end

	-- 17c: Defensive nil guard when UISpecialFrames is nil
	local prevViewer = Addon.Viewer
	local prevUISpecialFrames = _G["UISpecialFrames"]
	local prevGlobalViewer = _G["BagnonConsolidatorViewerFrame"]
	local prevGlobalScroll = _G["BagnonConsolidatorScrollFrame"]
	local prevEventFramesLen = #eventFrames

	_G["UISpecialFrames"] = nil
	loadAddonFile("ui/viewer.lua")
	Addon.Viewer:Toggle()
	local nilGuardViewer = _G["BagnonConsolidatorViewerFrame"]
	assertTrue(nilGuardViewer ~= nil and nilGuardViewer:IsShown(), "Test 17c viewer opens without error when UISpecialFrames is nil")
	Addon.Viewer:Toggle()
	if nilGuardViewer then
		assertFalse(nilGuardViewer:IsShown(), "Test 17c viewer closes cleanly when UISpecialFrames is nil")
	end

	for i = #eventFrames, prevEventFramesLen + 1, -1 do
		table.remove(eventFrames, i)
	end
	_G["BagnonConsolidatorScrollFrame"] = prevGlobalScroll
	_G["BagnonConsolidatorViewerFrame"] = prevGlobalViewer
	_G["UISpecialFrames"] = prevUISpecialFrames
	Addon.Viewer = prevViewer

	print("[PASS] Test 17: Viewer Escape Key Registration (UISpecialFrames) (#4)")
end

print(string.format("\n=== ALL %d UNIT TESTS PASSED SUCCESSFULLY! ===", numPassed))
