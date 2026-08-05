local path = arg[1]
if not path then
	print("Usage: lua scripts/dump_mappings.lua <path_to_WTF_SavedVariables/Bagnon_Consolidator.lua>")
	os.exit(1)
end

local f, err = loadfile(path)
if not f then
	print("Error: Could not load the variables file: " .. tostring(err))
	os.exit(1)
end

-- Initialize the global database variable so the script can execute it safely
BagnonConsolidatorDB = nil

f() -- Execute the file to populate the BagnonConsolidatorDB global table

if not BagnonConsolidatorDB or not BagnonConsolidatorDB.guildTabs then
	print("No guild bank tab mappings found in: " .. path)
	os.exit(0)
end

local hasGuilds = false
for guildKey, items in pairs(BagnonConsolidatorDB.guildTabs) do
	hasGuilds = true
	print("Guild / Realm: " .. guildKey)
	print(string.rep("=", #guildKey + 15))
	
	local sorted = {}
	for itemID, entry in pairs(items) do
		table.insert(sorted, {
			id = itemID,
			tab = entry.tab,
			name = entry.name or "Unknown Item",
			tabName = entry.tabName or ("Tab " .. tostring(entry.tab))
		})
	end
	
	-- Sort by tab index first, then alphabetically by item name
	table.sort(sorted, function(a, b)
		if a.tab ~= b.tab then
			return a.tab < b.tab
		end
		return a.name < b.name
	end)
	
	if #sorted > 0 then
		for _, entry in ipairs(sorted) do
			print(string.format("  - Tab %d (%-12s): [%d] %s", entry.tab, entry.tabName, entry.id, entry.name))
		end
	else
		print("  (No mappings recorded)")
	end
	print("")
end

if not hasGuilds then
	print("No guild bank tab mappings found in: " .. path)
end
