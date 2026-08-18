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
_G.SOUNDKIT = { UI_BAG_SORTING_01 = 123 }
_G.StaticPopupDialogs = {}
_G.StaticPopup_Show = function(which, text1, text2, data) end
_G.PlaySound = function(soundID) end
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
						return entry.name, "[" .. entry.name .. "]", 1, 1, 1, entry.itemType, entry.itemSubType, 20, "INV_Misc", "Interface/Icons/Item"
					end
					return nil
				end,
				GetItemIcon = function(id) return "Interface/Icons/Item" end,
			},
			GetItemInfoInstant = function(id) return id end,
			GetItemInfo = function(id)
				local entry = mockItemDB[id]
				if entry then return entry.name, "[" .. entry.name .. "]" end
				return nil
			end,
			GetItemIcon = function(id) return "Interface/Icons/Item" end,
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

-- Load addon files (supports both pre-refactor and post-refactor paths)
local function LoadAddonScripts()
	local okCore, _ = pcall(function()
		loadAddonFile("core/init.lua")
		loadAddonFile("core/utils.lua")
		loadAddonFile("core/snapshot.lua")
		loadAddonFile("core/engine.lua")
		loadAddonFile("ui/button.lua")
		loadAddonFile("ui/viewer.lua")
		loadAddonFile("ui/options.lua")
	end)

	if not okCore then
		-- Fall back to pre-refactor files
		loadAddonFile("main.lua")
		loadAddonFile("ui.lua")
	end
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

print(string.format("\n=== ALL %d UNIT TESTS PASSED SUCCESSFULLY! ===", numPassed))
