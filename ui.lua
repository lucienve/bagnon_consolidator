--[[
	Bagnon Consolidator - Viewer & Options UI
	Author: LVE
	All Rights Reserved
--]]

---@type string, BagnonAddon
local ADDON, Addon = (...):match('[^_]+'), _G[(...):match('[^_]+')]
local C = LibStub('C_Everywhere')

local Viewer = {}
Addon.Viewer = Viewer

local frame
local activeTab = "personal"
local activeGuildTab = 1
local searchQuery = ""
local itemRows = {}
local MAX_ROWS = 7
local ROW_HEIGHT = 42

local function GetCurrentScope()
	if activeTab == "guild" then
		return Addon.GetGuildKey() or "guild"
	elseif activeTab == "personal" then
		return Addon.GetCharacterKey() or "personal"
	end
	return "all"
end

local function GetCustomTabName(tabIdx)
	local liveName = GetGuildBankTabInfo and GetGuildBankTabInfo(tabIdx)
	if liveName and liveName ~= "" then return liveName end

	local guildKey = Addon.GetGuildKey()
	if guildKey and BagnonConsolidatorDB then
		if BagnonConsolidatorDB.tabNames and BagnonConsolidatorDB.tabNames[guildKey] then
			local savedName = BagnonConsolidatorDB.tabNames[guildKey][tabIdx]
			if savedName and savedName ~= "" then return savedName end
		end
		if BagnonConsolidatorDB.guildTabs and BagnonConsolidatorDB.guildTabs[guildKey] then
			for _, entry in pairs(BagnonConsolidatorDB.guildTabs[guildKey]) do
				if entry.tab == tabIdx and entry.tabName and entry.tabName ~= "" then
					return entry.tabName
				end
			end
		end
	end

	return nil
end

local function GetTabDisplayName(tabIdx)
	local customName = GetCustomTabName(tabIdx)
	local defaultName = "Tab " .. tabIdx
	if customName and customName ~= "" and customName:lower() ~= defaultName:lower() then
		return string.format("Tab %d: %s", tabIdx, customName)
	end
	return string.format("Tab %d:", tabIdx)
end

local function GetItemsForCurrentView()
	local items = {}
	local guildKey = Addon.GetGuildKey()
	local charKey = Addon.GetCharacterKey()

	if not BagnonConsolidatorDB then
		return items
	end

	if activeTab == "personal" then
		if charKey and BagnonConsolidatorDB.personalBanks and BagnonConsolidatorDB.personalBanks[charKey] then
			for itemID, itemName in pairs(BagnonConsolidatorDB.personalBanks[charKey]) do
				local match = true
				if searchQuery ~= "" then
					local lowerQuery = searchQuery:lower()
					if not itemName:lower():find(lowerQuery, 1, true) and not tostring(itemID):find(lowerQuery, 1, true) then
						match = false
					end
				end
				if match then
					tinsert(items, {
						id = itemID,
						name = itemName,
						category = "personal",
						destName = "Personal Bank",
						count = 0,
					})
				end
			end
		end
	elseif activeTab == "guild" then
		if guildKey and BagnonConsolidatorDB.guildTabs and BagnonConsolidatorDB.guildTabs[guildKey] then
			for itemID, entry in pairs(BagnonConsolidatorDB.guildTabs[guildKey]) do
				if entry.tab == activeGuildTab then
					local itemName = entry.name or ("Item " .. itemID)
					local match = true
					if searchQuery ~= "" then
						local lowerQuery = searchQuery:lower()
						if not itemName:lower():find(lowerQuery, 1, true) and not tostring(itemID):find(lowerQuery, 1, true) then
							match = false
						end
					end
					if match then
						tinsert(items, {
							id = itemID,
							name = itemName,
							category = "guild",
							tab = entry.tab,
							destName = entry.tabName or GetTabDisplayName(entry.tab),
							count = 0,
						})
					end
				end
			end
		end
	elseif activeTab == "conflicts" then
		if BagnonConsolidatorDB.conflicts then
			local function addConflicts(keyDict)
				if not keyDict then return end
				for itemID, conf in pairs(keyDict) do
					local itemName = conf.name or ("Item " .. itemID)
					local match = true
					if searchQuery ~= "" then
						local lowerQuery = searchQuery:lower()
						if not itemName:lower():find(lowerQuery, 1, true) and not tostring(itemID):find(lowerQuery, 1, true) then
							match = false
						end
					end
					if match then
						tinsert(items, {
							id = itemID,
							name = itemName,
							category = "conflicts",
							reason = conf.reason or "Multiple destinations",
							destName = "Conflict (Go Nowhere)",
							count = 0,
						})
					end
				end
			end

			if guildKey then addConflicts(BagnonConsolidatorDB.conflicts[guildKey]) end
			if charKey then addConflicts(BagnonConsolidatorDB.conflicts[charKey]) end
		end
	elseif activeTab == "ignored" then
		if BagnonConsolidatorDB.ignored then
			for itemID, itemName in pairs(BagnonConsolidatorDB.ignored) do
				local match = true
				if searchQuery ~= "" then
					local lowerQuery = searchQuery:lower()
					if not itemName:lower():find(lowerQuery, 1, true) and not tostring(itemID):find(lowerQuery, 1, true) then
						match = false
					end
				end
				if match then
					tinsert(items, {
						id = itemID,
						name = itemName,
						category = "ignored",
						destName = "Ignored (Never Deposit)",
						count = 0,
					})
				end
			end
		end
	end

	-- Sort items alphabetically by name
	table.sort(items, function(a, b)
		return (a.name or "") < (b.name or "")
	end)

	return items
end

local function CountCategory(cat, tabIdx)
	if not BagnonConsolidatorDB then return 0 end
	local count = 0
	local guildKey = Addon.GetGuildKey()
	local charKey = Addon.GetCharacterKey()

	if cat == "personal" then
		if charKey and BagnonConsolidatorDB.personalBanks and BagnonConsolidatorDB.personalBanks[charKey] then
			for _ in pairs(BagnonConsolidatorDB.personalBanks[charKey]) do
				count = count + 1
			end
		end
	elseif cat == "guild" then
		if guildKey and BagnonConsolidatorDB.guildTabs and BagnonConsolidatorDB.guildTabs[guildKey] then
			for _, entry in pairs(BagnonConsolidatorDB.guildTabs[guildKey]) do
				if entry.tab == tabIdx then
					count = count + 1
				end
			end
		end
	elseif cat == "conflicts" then
		if BagnonConsolidatorDB.conflicts then
			if guildKey and BagnonConsolidatorDB.conflicts[guildKey] then
				for _ in pairs(BagnonConsolidatorDB.conflicts[guildKey]) do count = count + 1 end
			end
			if charKey and BagnonConsolidatorDB.conflicts[charKey] then
				for _ in pairs(BagnonConsolidatorDB.conflicts[charKey]) do count = count + 1 end
			end
		end
	elseif cat == "ignored" then
		if BagnonConsolidatorDB.ignored then
			for _ in pairs(BagnonConsolidatorDB.ignored) do
				count = count + 1
			end
		end
	end
	return count
end

function Viewer:Refresh()
	if not frame or not frame:IsShown() then return end

	local items = GetItemsForCurrentView()
	local offset = FauxScrollFrame_GetOffset(frame.scrollFrame) or 0
	FauxScrollFrame_Update(frame.scrollFrame, #items, MAX_ROWS, ROW_HEIGHT)

	-- Update sub-navigation tab texts and badges
	if frame.personalTab then
		frame.personalTab:SetText(string.format("Personal (%d)", CountCategory("personal")))
	end
	if frame.guildDropTab then
		if activeTab == "guild" then
			frame.guildDropTab:SetText(string.format("Tab %d >", activeGuildTab))
		else
			frame.guildDropTab:SetText("Guild Bank >")
		end
	end
	if frame.conflictsTab then
		frame.conflictsTab:SetText(string.format("Conflicts (%d)", CountCategory("conflicts")))
	end
	if frame.ignoredTab then
		frame.ignoredTab:SetText(string.format("Ignored (%d)", CountCategory("ignored")))
	end

	-- Update view header title above the list
	if frame.viewHeaderTitle then
		if activeTab == "personal" then
			frame.viewHeaderTitle:SetText("|cff82c5ffPersonal Bank:|r " .. (Addon.GetCharacterKey() or "Current Character"))
		elseif activeTab == "guild" then
			local customName = GetCustomTabName(activeGuildTab)
			local defaultName = "Tab " .. activeGuildTab
			if customName and customName ~= "" and customName:lower() ~= defaultName:lower() then
				frame.viewHeaderTitle:SetText(string.format("|cff82c5ffGuild Bank:|r Tab %d: %s", activeGuildTab, customName))
			else
				frame.viewHeaderTitle:SetText(string.format("|cff82c5ffGuild Bank:|r Tab %d", activeGuildTab))
			end
		elseif activeTab == "conflicts" then
			frame.viewHeaderTitle:SetText("|cffffcc00Conflicts:|r Items with Multiple Destinations (Go Nowhere)")
		elseif activeTab == "ignored" then
			frame.viewHeaderTitle:SetText("|cffff8888Ignored:|r Items Excluded from Consolidation")
		end
	end

	frame.itemCountText:SetText(string.format("Showing %d items", #items))

	for i = 1, MAX_ROWS do
		local row = itemRows[i]
		local itemIdx = offset + i
		local itemData = items[itemIdx]

		if itemData then
			row.itemData = itemData
			row:Show()

			local itemID = itemData.id
			local itemName, itemLink, _, _, _, itemType, itemSubType, _, _, itemTexture = C.C_Item.GetItemInfo(itemID)
			itemName = itemName or itemData.name
			itemTexture = itemTexture or C.C_Item.GetItemIcon(itemID) or "Interface/Icons/INV_Misc_QuestionMark"

			row.icon:SetTexture(itemTexture)
			row.nameText:SetText(itemLink or itemName)

			if itemData.category == "ignored" then
				row.subText:SetText("|cffff8888Ignored - will not consolidate|r")
				row.deleteBtn:SetText("Restore")
				row.icon:SetDesaturated(true)
			elseif itemData.category == "conflicts" then
				row.subText:SetText("|cffffcc00Conflict: " .. (itemData.reason or "Multiple destinations") .. "|r")
				row.deleteBtn:SetText("Clear")
				row.icon:SetDesaturated(false)
			else
				if itemType and itemSubType and itemType ~= "" then
					row.subText:SetText("|cff888888" .. itemType .. " - " .. itemSubType .. " (ID: " .. itemID .. ")|r")
				elseif itemType and itemType ~= "" then
					row.subText:SetText("|cff888888" .. itemType .. " (ID: " .. itemID .. ")|r")
				else
					row.subText:SetText("|cff888888Item ID: " .. itemID .. "|r")
				end
				row.deleteBtn:SetText("Ignore [X]")
				row.icon:SetDesaturated(false)
			end
		else
			row.itemData = nil
			row:Hide()
		end
	end
end

local function CreateViewerFrame()
	frame = CreateFrame("Frame", "BagnonConsolidatorViewerFrame", UIParent, "BackdropTemplate")
	frame:SetSize(520, 500)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	frame:SetFrameStrata("DIALOG")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetClampedToScreen(true)

	frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 32,
		insets = { left = 8, right = 8, top = 8, bottom = 8 }
	})

	-- Title
	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	title:SetPoint("TOP", frame, "TOP", 0, -14)
	title:SetText("Bagnon Consolidator: Mappings")

	-- Close Button
	local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

	-- Top Action Buttons
	local snapBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	snapBtn:SetSize(140, 24)
	snapBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -42)
	snapBtn:SetText("Take Snapshot")
	snapBtn:SetScript("OnClick", function()
		if Addon.TakeSnapshot then
			Addon.TakeSnapshot()
		end
	end)

	local resetBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	resetBtn:SetSize(140, 24)
	resetBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, -42)
	resetBtn:SetText("Reset Mappings...")
	resetBtn:SetScript("OnClick", function()
		local scope = GetCurrentScope()
		local label = scope
		if activeTab == "guild" then label = Addon.GetGuildKey() or "Guild Bank"
		elseif activeTab == "personal" then label = Addon.GetCharacterKey() or "Personal Bank"
		else label = "All Addon Data" end
		StaticPopup_Show("BAGNON_CONSOLIDATOR_RESET_CONFIRM", label, nil, activeTab)
	end)

	-- Main Navigation Bar (Personal, Guild, Conflicts, Ignored)
	local navContainer = CreateFrame("Frame", nil, frame)
	navContainer:SetSize(488, 26)
	navContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -72)

	local function SelectTab(tabName, guildTabIdx)
		activeTab = tabName
		if guildTabIdx then activeGuildTab = guildTabIdx end
		FauxScrollFrame_SetOffset(frame.scrollFrame, 0)
		Viewer:Refresh()
	end

	local personalTab = CreateFrame("Button", nil, navContainer, "UIPanelButtonTemplate")
	personalTab:SetSize(115, 22)
	personalTab:SetPoint("LEFT", navContainer, "LEFT", 0, 0)
	personalTab:SetText("Personal")
	personalTab:SetScript("OnClick", function() SelectTab("personal") end)
	frame.personalTab = personalTab

	local guildDropTab = CreateFrame("Button", nil, navContainer, "UIPanelButtonTemplate")
	guildDropTab:SetSize(125, 22)
	guildDropTab:SetPoint("LEFT", personalTab, "RIGHT", 4, 0)
	guildDropTab:SetText("Guild Bank >")
	guildDropTab:SetScript("OnClick", function()
		MenuUtil.CreateContextMenu(guildDropTab, function(_, menu)
			menu:SetTag("BagnonConsolidatorGuildTabs")
			menu:CreateTitle("Select Guild Bank Tab")
			local numTabs = MAX_GUILDBANK_TABS or 8
			for i = 1, numTabs do
				local tabLabel = GetTabDisplayName(i)
				local count = CountCategory("guild", i)
				menu:CreateButton(string.format("%s (%d)", tabLabel, count), function()
					SelectTab("guild", i)
				end)
			end
		end)
	end)
	frame.guildDropTab = guildDropTab

	local conflictsTab = CreateFrame("Button", nil, navContainer, "UIPanelButtonTemplate")
	conflictsTab:SetSize(115, 22)
	conflictsTab:SetPoint("LEFT", guildDropTab, "RIGHT", 4, 0)
	conflictsTab:SetText("Conflicts")
	conflictsTab:SetScript("OnClick", function() SelectTab("conflicts") end)
	frame.conflictsTab = conflictsTab

	local ignoredTab = CreateFrame("Button", nil, navContainer, "UIPanelButtonTemplate")
	ignoredTab:SetSize(115, 22)
	ignoredTab:SetPoint("LEFT", conflictsTab, "RIGHT", 4, 0)
	ignoredTab:SetText("Ignored")
	ignoredTab:SetScript("OnClick", function() SelectTab("ignored") end)
	frame.ignoredTab = ignoredTab

	-- View Header Title (Shows current selected tab/destination)
	local viewHeaderTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	viewHeaderTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -104)
	viewHeaderTitle:SetPoint("RIGHT", frame, "RIGHT", -20, 0)
	viewHeaderTitle:SetJustifyH("LEFT")
	frame.viewHeaderTitle = viewHeaderTitle

	-- Search Input Box
	local searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	searchBox:SetSize(200, 20)
	searchBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -126)
	searchBox:SetAutoFocus(false)
	searchBox:SetScript("OnTextChanged", function(self)
		searchQuery = self:GetText() or ""
		FauxScrollFrame_SetOffset(frame.scrollFrame, 0)
		Viewer:Refresh()
	end)

	local searchLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	searchLabel:SetPoint("LEFT", searchBox, "RIGHT", 8, 0)
	searchLabel:SetText("Filter by name/ID")

	local countText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	countText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -20, -130)
	countText:SetText("Showing 0 items")
	frame.itemCountText = countText

	-- Scroll Frame
	local scrollFrame = CreateFrame("ScrollFrame", "BagnonConsolidatorScrollFrame", frame, "FauxScrollFrameTemplate")
	scrollFrame:SetSize(460, ROW_HEIGHT * MAX_ROWS)
	scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -152)
	scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, function() Viewer:Refresh() end)
	end)
	frame.scrollFrame = scrollFrame

	-- Item Rows
	for i = 1, MAX_ROWS do
		local row = CreateFrame("Frame", nil, frame, "BackdropTemplate")
		row:SetSize(456, ROW_HEIGHT - 4)
		row:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -152 - ((i - 1) * ROW_HEIGHT))
		row:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 12,
			insets = { left = 3, right = 3, top = 3, bottom = 3 }
		})
		row:SetBackdropColor(0.1, 0.1, 0.1, 0.6)

		local icon = row:CreateTexture(nil, "ARTWORK")
		icon:SetSize(32, 32)
		icon:SetPoint("LEFT", row, "LEFT", 4, 0)
		row.icon = icon

		local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		nameText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -2)
		nameText:SetPoint("RIGHT", row, "RIGHT", -90, 0)
		nameText:SetJustifyH("LEFT")
		row.nameText = nameText

		local subText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		subText:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 8, 2)
		subText:SetPoint("RIGHT", row, "RIGHT", -90, 0)
		subText:SetJustifyH("LEFT")
		row.subText = subText

		local delBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
		delBtn:SetSize(80, 22)
		delBtn:SetPoint("RIGHT", row, "RIGHT", -6, 0)
		delBtn:SetText("Remove")
		delBtn:SetScript("OnClick", function()
			local data = row.itemData
			if not data or not BagnonConsolidatorDB then return end

			local itemID = data.id
			local itemName = data.name

			if data.category == "personal" then
				local charKey = Addon.GetCharacterKey()
				if charKey and BagnonConsolidatorDB.personalBanks[charKey] then
					BagnonConsolidatorDB.personalBanks[charKey][itemID] = nil
				end
				BagnonConsolidatorDB.ignored[itemID] = itemName
				Addon.Print(itemName .. " moved to Ignored list.")
			elseif data.category == "guild" then
				local guildKey = Addon.GetGuildKey()
				if guildKey and BagnonConsolidatorDB.guildTabs[guildKey] then
					BagnonConsolidatorDB.guildTabs[guildKey][itemID] = nil
				end
				BagnonConsolidatorDB.ignored[itemID] = itemName
				Addon.Print(itemName .. " moved to Ignored list.")
			elseif data.category == "ignored" then
				BagnonConsolidatorDB.ignored[itemID] = nil
				Addon.Print(itemName .. " removed from Ignored list (can be re-learned on next snapshot).")
			elseif data.category == "conflicts" then
				local guildKey = Addon.GetGuildKey()
				local charKey = Addon.GetCharacterKey()
				if guildKey and BagnonConsolidatorDB.conflicts[guildKey] then
					BagnonConsolidatorDB.conflicts[guildKey][itemID] = nil
				end
				if charKey and BagnonConsolidatorDB.conflicts[charKey] then
					BagnonConsolidatorDB.conflicts[charKey][itemID] = nil
				end
				Addon.Print(itemName .. " conflict cleared.")
			end

			Viewer:Refresh()
		end)
		row.deleteBtn = delBtn

		itemRows[i] = row
	end

	frame:Hide()
	return frame
end

function Viewer:Toggle()
	if not frame then
		CreateViewerFrame()
	end
	if frame:IsShown() then
		frame:Hide()
	else
		frame:Show()
		Viewer:Refresh()
	end
end

-- Register Addon Options in Blizzard Settings Panel
local optionsCategoryFrame = CreateFrame("Frame", "BagnonConsolidatorOptionsPanel", UIParent)
optionsCategoryFrame.name = "Bagnon Consolidator"

local optTitle = optionsCategoryFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
optTitle:SetPoint("TOPLEFT", 16, -16)
optTitle:SetText("Bagnon Consolidator")

local optDesc = optionsCategoryFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
optDesc:SetPoint("TOPLEFT", optTitle, "BOTTOMLEFT", 0, -8)
optDesc:SetPoint("RIGHT", optionsCategoryFrame, "RIGHT", -16, 0)
optDesc:SetJustifyH("LEFT")
optDesc:SetText("Auto-deposits and consolidates item stacks from your bags to the bank or guild bank based on your physical bank snapshot.")

local openViewerBtn = CreateFrame("Button", nil, optionsCategoryFrame, "UIPanelButtonTemplate")
openViewerBtn:SetSize(180, 26)
openViewerBtn:SetPoint("TOPLEFT", optDesc, "BOTTOMLEFT", 0, -16)
openViewerBtn:SetText("Open Mappings Viewer...")
openViewerBtn:SetScript("OnClick", function()
	Viewer:Toggle()
end)

local debugCheck = CreateFrame("CheckButton", "BagnonConsolidatorDebugCheck", optionsCategoryFrame, "InterfaceOptionsCheckButtonTemplate")
debugCheck:SetPoint("TOPLEFT", openViewerBtn, "BOTTOMLEFT", 0, -12)
if _G[debugCheck:GetName() .. "Text"] then
	_G[debugCheck:GetName() .. "Text"]:SetText("Enable Debug Logs")
end
debugCheck:SetScript("OnShow", function(self)
	self:SetChecked(BagnonConsolidatorDB and BagnonConsolidatorDB.enableDebug or false)
end)
debugCheck:SetScript("OnClick", function(self)
	if BagnonConsolidatorDB then
		BagnonConsolidatorDB.enableDebug = self:GetChecked()
		LibStub('LibItemMove-1.0').Debug = BagnonConsolidatorDB.enableDebug
	end
end)

if Settings and Settings.RegisterCanvasLayoutCategory then
	local category = Settings.RegisterCanvasLayoutCategory(optionsCategoryFrame, optionsCategoryFrame.name)
	Settings.RegisterAddOnCategory(category)
elseif InterfaceOptions_AddCategory then
	InterfaceOptions_AddCategory(optionsCategoryFrame)
end
