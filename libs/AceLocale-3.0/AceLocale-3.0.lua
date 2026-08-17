--[[
	AceLocale-3.0 - Provides localization services for addons
	Written by Jerry, ace-commits@curseforge.com
	All Rights Reserved
--]]

local MAJOR, MINOR = "AceLocale-3.0", 6
---@class AceLocale30
local AceLocale, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not AceLocale then return end -- No upgrade needed

-- Lua APIs
local assert, tostring, error = assert, tostring, error
local setmetatable, rawset, rawget = setmetatable, rawset, rawget
local geterrorhandler = geterrorhandler

local gameLocale = GetLocale()
if gameLocale == "enGB" then
	gameLocale = "enUS"
end

AceLocale.apps = AceLocale.apps or {}
AceLocale.appnames = AceLocale.appnames or {}

-- This metatable is used on the string tables returned to the caller of :GetLocale()
local readMeta = {
	__index = function(self, key)
		rawset(self, key, key)
		return key
	end
}

-- This metatable is used for tables passed to :NewLocale() for non-default locales
local writeMeta = {
	__newindex = function(self, key, value)
		rawset(self, key, value == true and key or value)
	end
}

-- This metatable is used for tables passed to :NewLocale() for the default locale
local writeDefaultMeta = {
	__newindex = function(self, key, value)
		rawset(self, key, value == true and key or value)
	end
}

--- Register a new locale for the specified application.
---@param application string Unique name identifying the addon/application
---@param locale string 4-character locale identifier (e.g. "enUS", "deDE", "zhCN")
---@param isDefault boolean|nil If true, this locale is the fallback/default locale
---@param silent boolean|nil If true, does not log errors
---@return table|nil
function AceLocale:NewLocale(application, locale, isDefault, silent)
	local app = AceLocale.apps[application]
	if not app then
		app = {}
		AceLocale.apps[application] = app
		AceLocale.appnames[app] = application
	end

	if locale ~= gameLocale and not isDefault then
		return nil
	end

	local target = app[locale]
	if not target then
		target = setmetatable({}, isDefault and writeDefaultMeta or writeMeta)
		app[locale] = target
	end

	return target
end

--- Get the locale table for the specified application.
---@param application string Unique name identifying the addon/application
---@param silent boolean|nil If true, does not log warnings
---@return table
function AceLocale:GetLocale(application, silent)
	local app = AceLocale.apps[application]
	if not app then
		if not silent then
			error(string.format("Usage: AceLocale:GetLocale(application[, silent]): '%s' - No locales registered for this application", tostring(application)), 2)
		end
		return setmetatable({}, readMeta)
	end

	local loc = app[gameLocale] or app["enUS"]
	if not loc then
		if not silent then
			error(string.format("Usage: AceLocale:GetLocale(application[, silent]): '%s' - No supported locale available", tostring(application)), 2)
		end
		loc = setmetatable({}, readMeta)
	else
		setmetatable(loc, readMeta)
	end

	return loc
end
