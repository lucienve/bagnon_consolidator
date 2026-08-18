--[[
	Bagnon Consolidator - Backpack Button & Context Menu
	Author: LVE
	All Rights Reserved
--]]

---@type string, BagnonAddon
local ADDON, Addon = (...):match('[^_]+'), _G[(...):match('[^_]+')]
local LibItemMove = LibStub('LibItemMove-1.0') --[[@as LibItemMove]]
local L = Addon.L or LibStub('AceLocale-3.0'):GetLocale('Bagnon_Consolidator')

local ConsolidateButton = Addon.Tipped:NewClass('ConsolidateButton', 'Button', 'BagnonButtonTemplate')

function ConsolidateButton:New(parent)
	local b = self:Super(ConsolidateButton):New(parent)
	b.Icon:SetTexture("Interface/Icons/Spell_ChargePositive")
	b:RegisterForClicks('anyUp')
	return b
end

function ConsolidateButton:OnEnter()
	self:ShowTooltip(
		L["Consolidate to Bank"],
		"|cffbbbbbb" .. L["Consolidate to Bank Tooltip"] .. "|r",
		"|R " .. L["Options / Mappings"]
	)
end

function ConsolidateButton:OnClick(button)
	if button == "RightButton" then
		MenuUtil.CreateContextMenu(self, function(_, menu)
			menu:SetTag("BagnonConsolidatorOptions")
			menu:CreateTitle(L["Bagnon Consolidator"])

			menu:CreateButton(L["Open Mappings Viewer..."], function()
				if Addon.Viewer and Addon.Viewer.Toggle then
					Addon.Viewer:Toggle()
				end
			end)

			menu:CreateButton(L["Take Snapshot"], function()
				if Addon.TakeSnapshot then
					Addon.TakeSnapshot()
				end
			end)

			menu:CreateButton(L["Reset Mappings..."], function()
				local scope = "all"
				local label = L["All Addon Data"]
				if Addon.Frames:IsShown('guild') then
					scope = "guild"
					label = (Addon.GetGuildKey and Addon.GetGuildKey()) or L["Guild Bank"]
				elseif Addon.Frames:IsShown('bank') then
					scope = "personal"
					label = (Addon.GetCharacterKey and Addon.GetCharacterKey()) or L["Personal Bank"]
				end
				StaticPopup_Show("BAGNON_CONSOLIDATOR_RESET_CONFIRM", label, nil, scope)
			end)

			menu:CreateDivider()

			menu:CreateCheckbox(L["Enable Debug Logs"],
				function() return BagnonConsolidatorDB and BagnonConsolidatorDB.enableDebug or false end,
				function()
					if BagnonConsolidatorDB then
						BagnonConsolidatorDB.enableDebug = not BagnonConsolidatorDB.enableDebug
						if LibItemMove then
							LibItemMove.Debug = BagnonConsolidatorDB.enableDebug
						end
					end
				end)
		end)
		return
	end

	if InCombatLockdown() then
		Addon.Print(L["Cannot consolidate in combat."])
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

	Addon.Print(L["Bank or Guild Bank must be open and active."])
end

-- Hook into Bagnon's Extra Buttons list
local origGetExtraButtons = Addon.Inventory.GetExtraButtons
function Addon.Inventory:GetExtraButtons()
	local buttons = origGetExtraButtons and origGetExtraButtons(self) or {}
	tinsert(buttons, self:GetWidget('ConsolidateButton'))
	return buttons
end

Addon.ConsolidateButton = ConsolidateButton
