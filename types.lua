---@meta

-- Stub out Blizzard globals not present or recognized in annotations
---@class ChatFrame : Frame
---@field AddMessage fun(self: ChatFrame, message: string)
DEFAULT_CHAT_FRAME = {} --[[@as ChatFrame]]

SOUNDKIT = {
	UI_BAG_SORTING_01 = 0
}

MAX_GUILDBANK_TABS = 8

-- Declare LibStub and libraries
---@class LibStub
local LibStub = {}
---@param major string
---@return any
function LibStub:__call(major) end

---@class C_Everywhere
local C_Everywhere = {}
---@param item string
---@return number itemID
function C_Everywhere.GetItemInfoInstant(item) end
---@param item string|number
---@return string itemName
---@return string itemLink
---@return number itemQuality
---@return number itemLevel
---@return number itemMinLevel
---@return string itemType
---@return string itemSubType
---@return number itemStackCount
function C_Everywhere.GetItemInfo(item) end

-- Addon private table and module definitions
---@class BagnonAddon
---@field Tipped BagnonTipped
---@field Frames BagnonFrames
---@field Inventory BagnonInventory
---@field BankBags number[]
---@field InventoryBags number[]
---@field None any
---@field Guild any
---@field ConsolidateButton ConsolidateButton
---@field ConsolidateEngine ConsolidateEngine
_G["Bagnon"] = {} --[[@as BagnonAddon]]

---@class BagnonTipped
local BagnonTipped = {}
---@param name string
---@param template string
---@param xmlTemplate string
---@return any
function BagnonTipped:NewClass(name, template, xmlTemplate) end

---@class ConsolidateButton : Button
---@field Icon Texture
---@field Super fun(self: ConsolidateButton, class: any): any
local ConsolidateButton = {}
---@param parent Frame
---@return ConsolidateButton
function ConsolidateButton:New(parent) end
function ConsolidateButton:OnEnter() end
function ConsolidateButton:OnClick() end
---@param title string
---@param text string
function ConsolidateButton:ShowTooltip(title, text) end

---@class BagnonFrames
local BagnonFrames = {}
---@param name 'bank'|'guild'|'inventory'|string
---@return BagnonFrame|nil
function BagnonFrames:Get(name) end
---@param name 'bank'|'guild'|'inventory'|string
---@return boolean
function BagnonFrames:IsShown(name) end

---@class BagnonFrame : Frame
---@field id string
---@field PickupItem fun(bagOrTab: number, slot: number)
local BagnonFrame = {}
---@return boolean
function BagnonFrame:IsShown() end
---@return boolean
function BagnonFrame:IsCached() end
---@param bag number
---@return number
function BagnonFrame:NumSlots(bag) end
---@param bagOrTab number
---@param slot number
---@return BagnonItemInfo|nil
function BagnonFrame:GetItemInfo(bagOrTab, slot) end
---@param tab number
---@return BagnonBagInfo|nil
function BagnonFrame:GetBagInfo(tab) end
---@param class any
---@return any
function BagnonFrame:Super(class) end

---@class BagnonItemInfo
---@field isLocked boolean|nil
---@field itemID number|nil
---@field stackCount number|nil
---@field hyperlink string|nil

---@class BagnonBagInfo
---@field items table<number, string>|nil

---@class BagnonInventory
local BagnonInventory = {}
---@return Button[]|nil
function BagnonInventory:GetExtraButtons() end
---@param name string
---@return any
function BagnonInventory:GetWidget(name) end
---@param bag number
---@return number
function BagnonInventory:NumSlots(bag) end
---@param bag number
---@param slot number
---@return BagnonItemInfo|nil
function BagnonInventory:GetItemInfo(bag, slot) end

---@class ConsolidateEngine
local ConsolidateEngine = {}
---@param frame BagnonFrame
function ConsolidateEngine:Start(frame) end
