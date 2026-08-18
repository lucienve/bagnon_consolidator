--[[
	Bagnon Consolidator - Mappings Viewer Modal Window
	Author: LVE
	All Rights Reserved
--]]

---@type string, BagnonAddon
local ADDON, Addon = (...):match('[^_]+'), _G[(...):match('[^_]+')]
local C = LibStub('C_Everywhere') --[[@as C_Everywhere]]
local L = Addon.L or LibStub('AceLocale-3.0'):GetLocale('Bagnon_Consolidator')

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
		return (Addon.GetGuildKey and Addon.GetGuildKey()) or "guild"
	elseif activeTab == "personal" then
		return (Addon.GetCharacterKey and Addon.GetCharacterKey()) or "personal"
	end
	return "all"
end

local function GetCustomTabName(tabIdx)
	local liveName = GetGuildBankTabInfo and GetGuildBankTabInfo(tabIdx)
	if liveName and liveName ~= "" then return liveName end

	local guildKey = Addon.GetGuildKey and Addon.GetGuildKey()
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
	local defaultName = string.format(L["Tab %d"], tabIdx)
	if customName and customName ~= "" and customName:lower() ~= defaultName:lower() then
		return string.format(L["Tab %d: %s"], tabIdx, customName)
	end
	return string.format(L["Tab %d:"], tabIdx)
end

local function GetItemsForCurrentView()
	local items = {}
	local guildKey = Addon.GetGuildKey and Addon.GetGuildKey()
	local charKey = Addon.GetCharacterKey and Addon.GetCharacterKey()

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
						destName = L["Personal Bank"],
						count = 0,
					})
				end
			end
		end
	elseif activeTab == "guild" then
		if guildKey and BagnonConsolidatorDB.guildTabs and BagnonConsolidatorDB.guildTabs[guildKey] then
			for itemID, entry in pairs(BagnonConsolidatorDB.guildTabs[guildKey]) do
				if entry.tab == activeGuildTab then
					local itemName = entry.name or string.format(L["Item %d"], itemID)
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
					local itemName = conf.name or string.format(L["Item %d"], itemID)
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
							reason = conf.reason or L["Multiple destinations"],
							destName = L["Conflict (Go Nowhere)"],
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
						destName = L["Ignored (Never Deposit)"],
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
	local guildKey = Addon.GetGuildKey and Addon.GetGuildKey()
	local charKey = Addon.GetCharacterKey and Addon.GetCharacterKey()

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
		frame.personalTab:SetText(string.format(L["Personal (%d)"], CountCategory("personal")))
	end
	if frame.guildDropTab then
		if activeTab == "guild" then
			frame.guildDropTab:SetText(string.format(L["Tab %d >"], activeGuildTab))
		else
			frame.guildDropTab:SetText(L["Guild Bank >"])
		end
	end
	if frame.conflictsTab then
		frame.conflictsTab:SetText(string.format(L["Conflicts (%d)"], CountCategory("conflicts")))
	end
	if frame.ignoredTab then
		frame.ignoredTab:SetText(string.format(L["Ignored (%d)"], CountCategory("ignored")))
	end

	-- Update view header title above the list
	if frame.viewHeaderTitle then
		if activeTab == "personal" then
			frame.viewHeaderTitle:SetText(string.format(L["Personal Bank Header"], ((Addon.GetCharacterKey and Addon.GetCharacterKey()) or L["Current Character"])))
		elseif activeTab == "guild" then
			local customName = GetCustomTabName(activeGuildTab)
			local defaultName = string.format(L["Tab %d"], activeGuildTab)
			if customName and customName ~= "" and customName:lower() ~= defaultName:lower() then
				frame.viewHeaderTitle:SetText(string.format(L["Guild Bank Header Custom"], activeGuildTab, customName))
			else
				frame.viewHeaderTitle:SetText(string.format(L["Guild Bank Header"], activeGuildTab))
			end
		elseif activeTab == "conflicts" then
			frame.viewHeaderTitle:SetText(L["Conflicts Header"])
		elseif activeTab == "ignored" then
			frame.viewHeaderTitle:SetText(L["Ignored Header"])
		end
	end

	frame.itemCountText:SetText(string.format(L["Showing %d items"], #items))

	for i = 1, MAX_ROWS do
		local row = itemRows[i]
		local itemIdx = offset + i
		local itemData = items[itemIdx]

		if itemData then
			row.itemData = itemData
			row:Show()

			local itemID = itemData.id
			local itemName, itemLink, itemType, itemSubType, itemTexture
			if C.C_Item and itemID then
				local _, _, _, _, _, iType, iSubType, _, _, iTex = C.C_Item.GetItemInfo(itemID)
				local iName, iLink = C.C_Item.GetItemInfo(itemID)
				itemName = iName or itemData.name
				itemLink = iLink
				itemType = iType
				itemSubType = iSubType
				itemTexture = iTex or C.C_Item.GetItemIcon(itemID) or "Interface/Icons/INV_Misc_QuestionMark"
			else
				itemName = itemData.name
				itemTexture = "Interface/Icons/INV_Misc_QuestionMark"
			end

			row.icon:SetTexture(itemTexture)
			row.nameText:SetText(itemLink or itemName)

			if itemData.category == "ignored" then
				row.subText:SetText("|cffff8888" .. L["Ignored - will not consolidate"] .. "|r")
				row.deleteBtn:SetText(L["Restore"])
				row.icon:SetDesaturated(true)
			elseif itemData.category == "conflicts" then
				row.subText:SetText("|cffffcc00" .. string.format(L["Conflict: %s"], (itemData.reason or L["Multiple destinations"])) .. "|r")
				row.deleteBtn:SetText(L["Clear"])
				row.icon:SetDesaturated(false)
			else
				if itemType and itemSubType and itemType ~= "" then
					row.subText:SetText("|cff888888" .. itemType .. " - " .. itemSubType .. " (ID: " .. itemID .. ")|r")
				elseif itemType and itemType ~= "" then
					row.subText:SetText("|cff888888" .. itemType .. " (ID: " .. itemID .. ")|r")
				else
					row.subText:SetText("|cff888888" .. string.format(L["Item ID: %d"], itemID) .. "|r")
				end
				row.deleteBtn:SetText(L["Ignore [X]"])
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
	title:SetText(L["Bagnon Consolidator: Mappings"])

	-- Close Button
	local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

	-- Top Action Buttons
	local snapBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	snapBtn:SetSize(140, 24)
	snapBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -42)
	snapBtn:SetText(L["Take Snapshot"])
	snapBtn:SetScript("OnClick", function()
		if Addon.TakeSnapshot then
			Addon.TakeSnapshot()
		end
	end)

	local resetBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	resetBtn:SetSize(140, 24)
	resetBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, -42)
	resetBtn:SetText(L["Reset Mappings..."])
	resetBtn:SetScript("OnClick", function()
		local label = L["All Addon Data"]
		if activeTab == "guild" then
			label = (Addon.GetGuildKey and Addon.GetGuildKey()) or L["Guild Bank"]
		elseif activeTab == "personal" then
			label = (Addon.GetCharacterKey and Addon.GetCharacterKey()) or L["Personal Bank"]
		end
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
	personalTab:SetText(L["Personal"])
	personalTab:SetScript("OnClick", function() SelectTab("personal") end)
	frame.personalTab = personalTab

	local guildDropTab = CreateFrame("Button", nil, navContainer, "UIPanelButtonTemplate") --[[@as Button]]
	guildDropTab:SetSize(125, 22)
	guildDropTab:SetPoint("LEFT", personalTab, "RIGHT", 4, 0)
	guildDropTab:SetText(L["Guild Bank >"])
	guildDropTab:SetScript("OnClick", function()
		MenuUtil.CreateContextMenu(guildDropTab, function(_, menu)
			menu:SetTag("BagnonConsolidatorGuildTabs")
			menu:CreateTitle(L["Select Guild Bank Tab"])
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
	conflictsTab:SetText(L["Conflicts"])
	conflictsTab:SetScript("OnClick", function() SelectTab("conflicts") end)
	frame.conflictsTab = conflictsTab

	local ignoredTab = CreateFrame("Button", nil, navContainer, "UIPanelButtonTemplate")
	ignoredTab:SetSize(115, 22)
	ignoredTab:SetPoint("LEFT", conflictsTab, "RIGHT", 4, 0)
	ignoredTab:SetText(L["Ignored"])
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
	searchLabel:SetText(L["Filter by name/ID"])

	local countText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	countText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -20, -130)
	countText:SetText(L["Showing 0 items"])
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
		delBtn:SetText(L["Remove"])
		delBtn:SetScript("OnClick", function()
			local data = row.itemData
			if not data or not BagnonConsolidatorDB then return end

			local itemID = data.id
			local itemName = data.name

			if data.category == "personal" then
				local charKey = Addon.GetCharacterKey and Addon.GetCharacterKey()
				if charKey and BagnonConsolidatorDB.personalBanks[charKey] then
					BagnonConsolidatorDB.personalBanks[charKey][itemID] = nil
				end
				BagnonConsolidatorDB.ignored[itemID] = itemName
				Addon.Print(string.format(L["%s moved to Ignored list."], itemName))
			elseif data.category == "guild" then
				local guildKey = Addon.GetGuildKey and Addon.GetGuildKey()
				if guildKey and BagnonConsolidatorDB.guildTabs[guildKey] then
					BagnonConsolidatorDB.guildTabs[guildKey][itemID] = nil
				end
				BagnonConsolidatorDB.ignored[itemID] = itemName
				Addon.Print(string.format(L["%s moved to Ignored list."], itemName))
			elseif data.category == "ignored" then
				BagnonConsolidatorDB.ignored[itemID] = nil
				Addon.Print(string.format(L["%s removed from Ignored list (can be re-learned on next snapshot)."], itemName))
			elseif data.category == "conflicts" then
				local guildKey = Addon.GetGuildKey and Addon.GetGuildKey()
				local charKey = Addon.GetCharacterKey and Addon.GetCharacterKey()
				if guildKey and BagnonConsolidatorDB.conflicts[guildKey] then
					BagnonConsolidatorDB.conflicts[guildKey][itemID] = nil
				end
				if charKey and BagnonConsolidatorDB.conflicts[charKey] then
					BagnonConsolidatorDB.conflicts[charKey][itemID] = nil
				end
				Addon.Print(string.format(L["%s conflict cleared."], itemName))
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
