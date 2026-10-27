---@meta

-- Stub out Blizzard globals not present or recognized in annotations
---@class ChatFrame : Frame
---@field AddMessage fun(self: ChatFrame, message: string)
---@type ChatFrame
DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME

---@class SoundKit
---@field UI_BAG_SORTING_01 number
---@type SoundKit
SOUNDKIT = SOUNDKIT

---@type number
MAX_GUILDBANK_TABS = MAX_GUILDBANK_TABS
---@type number
KEYRING_CONTAINER = KEYRING_CONTAINER

---@class BagnonConsolidatorDBEntry
---@field tab number
---@field name string
---@field tabName string|nil

---@class BagnonConsolidatorConflictEntry
---@field name string
---@field tabs number[]|nil
---@field personal boolean|nil
---@field reason string|nil

---@class BagnonConsolidatorDB
---@field guildTabs table<string, table<number, BagnonConsolidatorDBEntry>>
---@field tabNames table<string, table<number, string>>|nil
---@field personalBanks table<string, table<number, string>>
---@field ignored table<number, string>
---@field conflicts table<string, table<number, BagnonConsolidatorConflictEntry>>
---@field enableDebug boolean|nil
---@type BagnonConsolidatorDB
BagnonConsolidatorDB = BagnonConsolidatorDB

---@type fun(tab: number): string|nil, string|nil, boolean|nil, boolean|nil, number|nil, number|nil
GetGuildBankTabInfo = GetGuildBankTabInfo

---@type fun(bag: number, slot: number): string|nil, number|nil, boolean|nil, number|nil, boolean|nil, boolean|nil, string|nil, boolean|nil, boolean|nil, number|nil
GetContainerItemInfo = GetContainerItemInfo
---@type fun(bag: number, slot: number)
PickupContainerItem = PickupContainerItem

---@type table<string, table>
StaticPopupDialogs = StaticPopupDialogs
---@type fun(which: string, text_arg1?: string, text_arg2?: string, data?: any): Frame|nil
StaticPopup_Show = StaticPopup_Show

---@class MenuDescriptionProxy
---@field SetTag fun(self: MenuDescriptionProxy, tag: string)
---@field CreateTitle fun(self: MenuDescriptionProxy, text: string): any
---@field CreateButton fun(self: MenuDescriptionProxy, text: string, callback?: fun()): any
---@field CreateDivider fun(self: MenuDescriptionProxy): any
---@field CreateCheckbox fun(self: MenuDescriptionProxy, text: string, isSelected: fun(): boolean, setSelected: fun()): any

---@class MenuUtilTable
---@field CreateContextMenu fun(ownerRegion: Region|nil, generator: fun(ownerRegion: Region|nil, rootDescription: MenuDescriptionProxy)): any
---@type MenuUtilTable
MenuUtil = MenuUtil

---@class SettingsCategory
---@field ID string|number|nil

---@class SettingsTable
---@field RegisterCanvasLayoutCategory fun(frame: Frame, name: string): SettingsCategory
---@field RegisterAddOnCategory fun(category: SettingsCategory)
---@type SettingsTable
Settings = Settings

---@type fun(frame: Frame)
InterfaceOptions_AddCategory = InterfaceOptions_AddCategory

---@class ScrollFrame : Frame
---@field offset number|nil

---@type fun(scrollFrame: ScrollFrame): number
FauxScrollFrame_GetOffset = FauxScrollFrame_GetOffset
---@type fun(scrollFrame: ScrollFrame, numItems: number, numToDisplay: number, valueStep: number)
FauxScrollFrame_Update = FauxScrollFrame_Update
---@type fun(scrollFrame: ScrollFrame, offset: number)
FauxScrollFrame_SetOffset = FauxScrollFrame_SetOffset
---@type fun(scrollFrame: ScrollFrame, offset: number, itemHeight: number, updateFunction: fun())
FauxScrollFrame_OnVerticalScroll = FauxScrollFrame_OnVerticalScroll

---@class UICheckButton : CheckButton
---@field Text FontString|nil

-- Declare LibStub and libraries
---@class LibStub
local LibStub = {}
---@param major string
---@return any
function LibStub:__call(major) end

---@class C_Everywhere_Item
---@field GetItemInfo fun(item: string|number): string|nil, string|nil, number|nil, number|nil, number|nil, string|nil, string|nil, number|nil, string|nil, string|number|nil
---@field GetItemIconByID fun(item: string|number): number|nil
---@field GetItemIcon fun(itemLocation: table): number|nil

---@class C_Everywhere
---@field C_Item C_Everywhere_Item
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
---@param item string|number
---@return number|nil itemIcon
function C_Everywhere.GetItemIconByID(item) end
---@param itemLocation table
---@return number|nil itemIcon
function C_Everywhere.GetItemIcon(itemLocation) end

---@class LibItemMove
---@field Debug boolean|nil
---@field Move fun(self: LibItemMove, queue: table, context: string, callback?: fun(event: string, ...))

---@class AceLocale30
---@field NewLocale fun(self: AceLocale30, application: string, locale: string, isDefault?: boolean, silent?: boolean): table<string, any>|nil
---@field GetLocale fun(self: AceLocale30, application: string, silent?: boolean): table<string, string>

-- Addon private table and module definitions
---@class BagnonAddon
---@field L table<string, string>
---@field Tipped BagnonTipped
---@field Frames BagnonFrames
---@field Inventory BagnonInventory
---@field BankBags number[]
---@field InventoryBags number[]
---@field None BagnonItemInfo
---@field Guild BagnonFrame
---@field ConsolidateButton ConsolidateButton
---@field ConsolidateEngine ConsolidateEngine
---@field Viewer any
---@field TakeSnapshot fun(frame?: any): boolean
---@field ResetMappings fun(scope?: string)
---@field GetCharacterKey fun(): string|nil
---@field GetGuildKey fun(): string|nil
---@field IsItemInAnyPersonalBank fun(itemID: number): boolean
---@field GetItemName fun(item: any): string
---@field Print fun(msg: string)
---@field Debug fun(msg: string)
---@type BagnonAddon
Bagnon = Bagnon

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
---@param button string|nil
function ConsolidateButton:OnClick(button) end
---@param title string
---@param ... string
function ConsolidateButton:ShowTooltip(title, ...) end

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
