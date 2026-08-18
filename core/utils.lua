--[[
	Bagnon Consolidator - Utility Functions & Helpers
	Author: LVE
	All Rights Reserved
--]]

---@type string, BagnonAddon
local ADDON, Addon = (...):match('[^_]+'), _G[(...):match('[^_]+')]
local C = LibStub('C_Everywhere') --[[@as C_Everywhere]]
local L = Addon.L or LibStub('AceLocale-3.0'):GetLocale('Bagnon_Consolidator')

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
	if item.itemID and C.C_Item then
		local name = C.C_Item.GetItemInfo(item.itemID)
		if name then return name end
	end
	return L["Unknown Item"]
end

local function Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff82c5ffBagnon Consolidator:|r " .. msg)
end

local function Debug(msg)
	if BagnonConsolidatorDB and BagnonConsolidatorDB.enableDebug then
		DEFAULT_CHAT_FRAME:AddMessage("|cff82c5ffBagnon Consolidator (Debug):|r " .. msg)
	end
end

-- Export helpers on Addon namespace
Addon.GetCharacterKey = GetCharacterKey
Addon.GetGuildKey = GetGuildKey
Addon.IsItemInAnyPersonalBank = IsItemInAnyPersonalBank
Addon.GetItemName = GetItemName
Addon.Print = Print
Addon.Debug = Debug
