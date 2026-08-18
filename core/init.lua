--[[
	Bagnon Consolidator - Lifecycle & Initialization
	Author: LVE
	All Rights Reserved
--]]

---@type string, BagnonAddon
local ADDON, Addon = (...):match('[^_]+'), _G[(...):match('[^_]+')]
local LibItemMove = LibStub('LibItemMove-1.0') --[[@as LibItemMove]]
local L = LibStub('AceLocale-3.0'):GetLocale('Bagnon_Consolidator')
Addon.L = L

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
		if LibItemMove then
			LibItemMove.Debug = BagnonConsolidatorDB.enableDebug
		end
		self:UnregisterEvent("ADDON_LOADED")
	end
end)
