--[[
	Bagnon Consolidator - Blizzard Options / Settings Panel
	Author: LVE
	All Rights Reserved
--]]

---@type string, BagnonAddon
local ADDON, Addon = (...):match('[^_]+'), _G[(...):match('[^_]+')]
local L = Addon.L or LibStub('AceLocale-3.0'):GetLocale('Bagnon_Consolidator')

-- Register Addon Options in Blizzard Settings Panel
local optionsCategoryFrame = CreateFrame("Frame", "BagnonConsolidatorOptionsPanel", UIParent)
optionsCategoryFrame.name = L["Bagnon Consolidator"]

local optTitle = optionsCategoryFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
optTitle:SetPoint("TOPLEFT", 16, -16)
optTitle:SetText(L["Bagnon Consolidator"])

local optDesc = optionsCategoryFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
optDesc:SetPoint("TOPLEFT", optTitle, "BOTTOMLEFT", 0, -8)
optDesc:SetPoint("RIGHT", optionsCategoryFrame, "RIGHT", -16, 0)
optDesc:SetJustifyH("LEFT")
optDesc:SetText(L["Options Description"])

local openViewerBtn = CreateFrame("Button", nil, optionsCategoryFrame, "UIPanelButtonTemplate")
openViewerBtn:SetSize(180, 26)
openViewerBtn:SetPoint("TOPLEFT", optDesc, "BOTTOMLEFT", 0, -16)
openViewerBtn:SetText(L["Open Mappings Viewer..."])
openViewerBtn:SetScript("OnClick", function()
	if Addon.Viewer and Addon.Viewer.Toggle then
		Addon.Viewer:Toggle()
	end
end)

local debugCheck = CreateFrame("CheckButton", "BagnonConsolidatorDebugCheck", optionsCategoryFrame, "InterfaceOptionsCheckButtonTemplate")
debugCheck:SetPoint("TOPLEFT", openViewerBtn, "BOTTOMLEFT", 0, -12)
if _G[debugCheck:GetName() .. "Text"] then
	_G[debugCheck:GetName() .. "Text"]:SetText(L["Enable Debug Logs"])
end
debugCheck:SetScript("OnShow", function(self)
	self:SetChecked(BagnonConsolidatorDB and BagnonConsolidatorDB.enableDebug or false)
end)
debugCheck:SetScript("OnClick", function(self)
	if BagnonConsolidatorDB then
		BagnonConsolidatorDB.enableDebug = self:GetChecked()
		local lib = LibStub('LibItemMove-1.0')
		if lib then
			lib.Debug = BagnonConsolidatorDB.enableDebug
		end
	end
end)

if Settings and Settings.RegisterCanvasLayoutCategory then
	local category = Settings.RegisterCanvasLayoutCategory(optionsCategoryFrame, optionsCategoryFrame.name)
	Settings.RegisterAddOnCategory(category)
elseif InterfaceOptions_AddCategory then
	InterfaceOptions_AddCategory(optionsCategoryFrame)
end
