-- Anime Adventures hub (VaderUI)
repeat task.wait() until game:IsLoaded()

---------------------------------------------- [ Configs ] ----------------------------------------------

local MAP_NAME = "Anime Adventures"
local VaderUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/DONUT6599/ddgdhdf/refs/heads/main/VaderUI.lua"))()
local Env = (getgenv and getgenv()) or _G

local State = {
	-- lobby
	Join = {}, Stage = {}, Difficulty = "Normal", FriendsOnly = false,
	AutoJoinChallenge = false, Loadout = "Don't change", TeleportDelay = 0,
	-- event
	AutoContract = false, ContractWeakTo = { Physical = true, Magic = true }, ContractTierMode = "Highest tier",
	ContractMaxTier = 10, SkipCompletedContracts = true,
	AutoEventShop = false, EventShopItems = {},
	-- dungeon
	AutoDungeon = false, DungeonStart = false, DungeonChests = "Save for the end", DungeonShrine = "Accept if no curse",
	DungeonPickBy = "Rewards, then weakness", DungeonLookahead = true,
	DungeonRoomOrder = {}, DungeonWeakOrder = {}, DungeonShopOrder = {},
	-- macro
	MacroName = nil, AutoSwitchMacro = false,
	-- match
	LeaveOnChallenge = false, AutoStart = false, StartDelay = 10, AutoSkip = false,
	PlayMacro = false, RecordMacro = false, AutoUpgrade = false, UpgradeFirst = {},
	AutoAbility = false, AutoSell = false, SellWave = 20, EndAction = "Nothing",
	-- auto play
	AutoPlace = false, ShowPlacePoint = true, ShowHolograms = true, PlaceBeforeUpgrade = true,
	Slots = {}, -- slot id -> { On, Mode, Percent, Max }
	-- summon
	AutoSummon = false, Banner = nil, SummonPay = "Gems x10", KeepGems = 0,
	-- traits
	RerollTargets = { Golden = true, Unique = true, Divine = true }, RerollMinTier = 3,
	RerollPay = "Reroll Token", ProtectMythic = true,
	StatMode = "All stats", StatTarget = "S",
	-- rewards
	AutoDaily = false, AutoBattlePass = false, AutoQuests = false, AutoMissions = false, AutoLevelRewards = false,
	Codes = "",
	-- misc
	LowGraphics = false, HideName = false, WebhookUrl = "", WebhookSend = { ["Match results"] = true, ["Rare summons"] = true, ["Reroll hits"] = true },
}
---------------------------------------------- [ Prepare Project ] ----------------------------------------------

local Collection = {}; Collection.__index = Collection
local Services = setmetatable({}, {
	__index = function(_, k)
		return game:GetService(k)
	end
})

local Connections = {}
local closed = false
-- replaced by the real one once the config is loaded
function Collection:SaveProfile() return false end
local Window = VaderUI:CreateWindow({
	Title = MAP_NAME,
	SubTitle = "by vaderhug",
	TabWidth = 180,
	Size = UDim2.fromOffset(620, 480),
	Theme = "Dark",
	MinimizeKey = Enum.KeyCode.RightControl,
})
Env.VaderMapStarter = VaderUI

function Collection:Notify(message)
	VaderUI:Notify({ Title = MAP_NAME, Content = tostring(message), Duration = 4 })
end

-- Register event connections here so closing/reloading disconnects them.
function Collection:Track(connection)
	table.insert(Connections, connection)
	return connection
end

--------------------------- [[ Services ]] ---------------------------

local Players = Services.Players
local HttpService = Services.HttpService
local CollectionService = Services.CollectionService
local ReplicatedStorage = Services.ReplicatedStorage

--------------------------- [[ Game Variables ]] ---------------------------

local LP = Players.LocalPlayer
local Loader = require(ReplicatedStorage.src.Loader)
-- the game's modules by name, loaded on first use: Data.Units, Core.TraitServiceCore, Client.GUIService
function Collection:ModuleTable(load)
	return setmetatable({}, {
		__index = function(self, name)
			local module = load(script, name)
			rawset(self, name, module)
			return module
		end
	})
end
local Data = Collection:ModuleTable(Loader.load_data)
local Core = Collection:ModuleTable(Loader.load_core_service)
local Client = Collection:ModuleTable(Loader.load_client_service)

-- from autoexec this can run before the game has registered its client services; keep asking until it has
while not (Client.EndpointsClient and Client.EndpointsClient.session) do task.wait(0.5) end
local session = Client.EndpointsClient.session
local toServer = ReplicatedStorage.endpoints.client_to_server
local fromServer = ReplicatedStorage.endpoints.server_to_client
local IS_LOBBY = workspace._MAP_CONFIG.IsLobby.Value

--------------------------- [[ Game Functions ]] ---------------------------

function Collection:Invoke(name, ...)
	local remote = toServer:FindFirstChild(name)
	if not remote then return nil end
	local ok, result = pcall(remote.InvokeServer, remote, ...)
	return ok and result or nil
end

-- Waits Teleport Delay before an action that sends you to another place. wanted() is checked every tick, so
-- turning the feature off during the wait cancels it; false comes back when it was cancelled or the hub closed.
function Collection:TeleportDelay(why, wanted)
	if State.TeleportDelay > 0 then Collection:Notify(string.format("%s in %ds", why, State.TeleportDelay)) end
	local t0 = os.clock()
	while os.clock() - t0 < State.TeleportDelay do
		if closed or not wanted() then return false end
		task.wait(0.2)
	end
	return not closed and wanted() and true or false
end

function Collection:Owned() return session.collection.collection_profile_data.owned_units end
function Collection:UnitName(u) return (Data.Units[u.unit_id] and Data.Units[u.unit_id].name) or u.unit_id end
function Collection:Gems() return LP._stats.gem_amount.Value end
function Collection:Money() return LP._stats.resource.Value end
function Collection:InPad() return LP:FindFirstChild("AlreadyInLobby") and LP.AlreadyInLobby.Value end
function Collection:DungeonData() return session.profile_data.dungeon_data or {} end

function Collection:DescribeTraits(traits)
	local out = {}
	for _, t in traits or {} do
		local def = Data.Traits[t.trait]
		table.insert(out, (def and def.name or t.trait) .. " " .. Core.TraitServiceCore.convert_to_roman_numerals(tostring(t.tier)))
	end
	return #out > 0 and table.concat(out, " + ") or "no trait"
end

-- Waits for a server_to_client event about one unit after firing a request.
function Collection:RequestAndWait(event, uuid, fire)
	local got
	local conn = event.OnClientEvent:Connect(function(id, data)
		if id == uuid then got = data end
	end)
	fire()
	local t0 = os.clock()
	while got == nil and not closed and os.clock() - t0 < 5 do task.wait(0.1) end
	conn:Disconnect()
	return got
end

--------------------------- [[ Files ]] ---------------------------

local canPersist = type(isfile) == "function" and type(readfile) == "function"
	and type(writefile) == "function" and type(makefolder) == "function"
	and type(isfolder) == "function"
local profileFolder = "Vaderhug/" .. MAP_NAME:gsub("[^%w_%-]", "")
local profilePath = profileFolder .. "/" .. LP.Name .. ".json"
local macroFolder = profileFolder .. "/macros"
local macroAssignPath = profileFolder .. "/macro_assignments.json"
local challengePath = profileFolder .. "/" .. LP.Name .. "_challenge.json"
if canPersist then
	if not isfolder("Vaderhug") then makefolder("Vaderhug") end
	if not isfolder(profileFolder) then makefolder(profileFolder) end
	if not isfolder(macroFolder) then makefolder(macroFolder) end
end
function Collection:ReadJson(path, default)
	if canPersist and isfile(path) then
		local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
		if ok and type(data) == "table" then return data end
	end
	return default
end
function Collection:WriteJson(path, data)
	if canPersist then pcall(writefile, path, HttpService:JSONEncode(data)) end
end
local placePositionsPath = profileFolder .. "/place_positions.json"
local placePositions = Collection:ReadJson(placePositionsPath, {}) -- "map|slot" -> { x, y, z } from "Set Position Here"

--------------------------- [[ Webhook ]] ---------------------------

local httpRequest = request or http_request or (syn and syn.request)
function Collection:Webhook(kind, title, lines)
	if not State.WebhookSend[kind] or not State.WebhookUrl:match("^https://") or not httpRequest then return end
	task.spawn(pcall, httpRequest, {
		Url = State.WebhookUrl,
		Method = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body = HttpService:JSONEncode({ embeds = { {
			title = title,
			description = table.concat(lines, "\n"),
			color = 0x8458F0,
			footer = { text = MAP_NAME .. " | " .. LP.Name },
		} } }),
	})
end

--------------------------- [[ Macro Recorder ]] ---------------------------

-- wraps the game's own endpoint wrapper so actions done by hand are captured
local MACRO_ACTIONS = { spawn_unit = "spawn", upgrade_unit_ingame = "upgrade", sell_unit_ingame = "sell", use_active_attack = "ability" }
local MACRO_MODES = { "Story", "Infinite", "Legend", "Raid", "Challenge", "Event", "Contract" }
local originalInvoke = Client.EndpointsClient.invoke_server
local assignments = Collection:ReadJson(macroAssignPath, {}) -- "Mode|map" -> macro name
local recording, recordTarget -- steps recorded this match and the macro they go into
local MacroStatus
function Collection:MapKey() return Loader.LevelData and Loader.LevelData.map end
function Collection:Wave() return workspace:FindFirstChild("_wave_num") and workspace._wave_num.Value or 0 end

function Collection:MacroPath(name) return macroFolder .. "/" .. name .. ".json" end
function Collection:CleanMacroName(name)
	return (tostring(name or ""):gsub("[^%w_%- ]", ""):gsub("^%s+", ""):gsub("%s+$", ""))
end
function Collection:ListMacros()
	local names = {}
	if canPersist and type(listfiles) == "function" then
		for _, path in listfiles(macroFolder) do
			local name = path:match("([^/\\]+)%.json$")
			if name then table.insert(names, name) end
		end
	end
	table.sort(names)
	return names
end
function Collection:LoadMacro(name) return name and Collection:ReadJson(Collection:MacroPath(name), {}).steps or {} end
function Collection:SaveMacro(name, steps) Collection:WriteJson(Collection:MacroPath(name), { steps = steps }) end

function Collection:CurrentMode()
	local d = Loader.LevelData
	if not d then return nil end
	if d._event_contract then return "Contract" end
	if d._challenge or d.id == "__DAILY_CHALLENGE" then return "Challenge" end
	if d._is_event_challenge or d._roguelike_mode then return "Event" end
	local w = d.world and Data.Worlds[d.world]
	if w and w.raid_world then return "Raid" end
	if w and w.legend_stage then return "Legend" end
	if d.infinite or d._gamemode == "infinite" then return "Infinite" end
	return "Story"
end

-- the macro for this match: a game mode + map assignment when Auto Switch is on, else the picked macro
function Collection:ActiveMacroName()
	if State.AutoSwitchMacro then
		local mode = Collection:CurrentMode()
		local assigned = mode and (assignments[mode .. "|" .. tostring(Collection:MapKey())] or assignments[mode .. "|Any map"])
		if assigned then return assigned end
	end
	return State.MacroName
end

-- which recorded spawn a unit model came from: same unit, closest to where it was placed
function Collection:SpawnIndexOf(steps, model)
	local st = typeof(model) == "Instance" and model:FindFirstChild("_stats")
	local uuid = st and st:FindFirstChild("uuid") and st.uuid.Value
	if not uuid then return nil end
	local pos, best, bestDist = model:GetPivot().Position, nil, math.huge
	for i, step in steps do
		if step.type == "spawn" and step.uuid == uuid then
			local d = Vector2.new(step.cf[1] - pos.X, step.cf[3] - pos.Z).Magnitude
			if d < bestDist then best, bestDist = i, d end
		end
	end
	return best
end

function Collection:MacroSummary(steps)
	local counts = { spawn = 0, upgrade = 0, sell = 0, ability = 0 }
	for _, step in steps do counts[step.type] += 1 end
	return string.format("%d steps: %d spawn, %d upgrade, %d sell, %d ability", #steps, counts.spawn, counts.upgrade, counts.sell, counts.ability)
end

-- a plain function (no self): it stands in for the game's EndpointsClient.invoke_server
function Collection.RecordingInvoke(name, ...)
	local action = State.RecordMacro and recording and Collection:MapKey() and MACRO_ACTIONS[name]
	local step
	if action == "spawn" then
		local uuid, cf = ...
		step = { type = action, wave = Collection:Wave(), uuid = uuid, cf = { cf:GetComponents() } }
	elseif action then
		-- resolve the unit before the call: a sold unit is gone afterwards
		local index = Collection:SpawnIndexOf(recording, (...))
		step = index and { type = action, wave = Collection:Wave(), unit = index }
	end
	local result = table.pack(originalInvoke(name, ...))
	if step and (result[1] or action == "sell" or action == "ability") then
		table.insert(recording, step)
		local isNew = not recordTarget
		recordTarget = recordTarget or Collection:ActiveMacroName() or Collection:CleanMacroName((Collection:CurrentMode() or "Macro") .. "_" .. Collection:MapKey())
		Collection:SaveMacro(recordTarget, recording)
		if isNew and Collection.RefreshMacroLists then Collection:RefreshMacroLists() end
		if MacroStatus then MacroStatus:SetDesc("Recording into " .. recordTarget .. " - " .. Collection:MacroSummary(recording)) end
	end
	return table.unpack(result, 1, result.n)
end
Client.EndpointsClient.invoke_server = Collection.RecordingInvoke

local originalDestroy = VaderUI.Destroy
function VaderUI:Destroy()
	if closed then return end
	pcall(Collection.SaveProfile, Collection)
	closed = true
	State.HideName = false
	pcall(Collection.ApplyHideName, Collection)
	State.Join, State.AutoSummon, State.PlayMacro, State.AutoUpgrade = {}, false, false, false
	if Client.EndpointsClient.invoke_server == Collection.RecordingInvoke then Client.EndpointsClient.invoke_server = originalInvoke end
	for _, connection in ipairs(Connections) do
		pcall(function() connection:Disconnect() end)
	end
	table.clear(Connections)
	if Env.VaderMapStarter == self then Env.VaderMapStarter = nil end
	originalDestroy(self)
end

--------------------------- [[ Data For Dropdowns ]] ---------------------------

-- stages per game mode: label -> level id
local MODES = { "Story", "Infinite", "Legend", "Raid" }
local JOIN_ORDER = { "Raid", "Legend", "Story", "Infinite" }
local stages = {}
for _, mode in MODES do stages[mode] = { labels = {}, ids = {} } end
function Collection:AddStage(mode, label, levelId)
	local s = stages[mode]
	if s.ids[label] then label = label .. " (" .. levelId .. ")" end
	s.ids[label] = levelId
	table.insert(s.labels, label)
end
for worldId, w in Data.Worlds do
	local mode = w.raid_world and "Raid" or (w.legend_stage and "Legend" or "Story")
	local acts = {}
	for key, level in w.levels or {} do
		table.insert(acts, { n = tonumber(key) or 0, id = type(level) == "table" and level.id or level })
	end
	table.sort(acts, function(a, b) return a.n < b.n end)
	for _, act in acts do
		local level = Data.Levels[act.id]
		if level then Collection:AddStage(mode, (w.name or worldId) .. " - " .. (level.name or act.id), act.id) end
	end
	if w.infinite and w.infinite.id and Data.Levels[w.infinite.id] then Collection:AddStage("Infinite", w.name or worldId, w.infinite.id) end
end
for _, mode in MODES do table.sort(stages[mode].labels) end

-- owned units: dropdown label <-> uuid
local labelOf, uuidOf = {}, {}
function Collection:BuildUnitLabels()
	labelOf, uuidOf = {}, {}
	local rows = {}
	for uuid, u in Collection:Owned() do
		local ok, lvl = pcall(Core.UnitServiceCore.calculate_level, u.unit_id, u.xp or 0)
		local label = string.format("%s (%s) Lv%s - %s #%s", Collection:UnitName(u), tostring(Data.Units[u.unit_id] and Data.Units[u.unit_id].rarity),
			ok and lvl or "?", Collection:DescribeTraits(u.traits), uuid:sub(2, 5))
		labelOf[uuid], uuidOf[label] = label, uuid
		table.insert(rows, label)
	end
	table.sort(rows)
	return rows
end

local equippedNames = {}
for _, uuid in session.profile_data.collection.equipped_units do
	local u = Collection:Owned()[uuid]
	if u and not table.find(equippedNames, Collection:UnitName(u)) then table.insert(equippedNames, Collection:UnitName(u)) end
end

local loadoutValues = { "Don't change" }
for i = 1, Data.GameplaySettings.NUM_TEAM_SLOTS or 0 do
	local saved = session.profile_data.loadouts_v2 and session.profile_data.loadouts_v2[tostring(i)]
	table.insert(loadoutValues, "Team " .. i .. (type(saved) == "table" and saved.name and (" - " .. saved.name) or ""))
end

local bannerValues = {}
for id, b in Data.Banners do
	if type(b) == "table" and b.active then table.insert(bannerValues, id) end
end
table.sort(bannerValues)
State.Banner = table.find(bannerValues, "EventClover") and "EventClover" or bannerValues[1]

local traitNames = {}
for id, def in Data.Traits do table.insert(traitNames, def.name or id) end
table.sort(traitNames)

local RANKS = { "C-", "C", "C+", "B-", "B", "B+", "A-", "A", "A+", "S-", "S", "S+", "SS", "SSS" }

-- event shop: label -> { key, cost, currency }
local eventShopValues, eventShopItems = {}, {}
for key, data in Data.ItemsForSaleEvent do
	if type(data) == "table" and data.resource_cost then
		local item = Data.Items[data.item_id]
		local name = item and item.name or (key:gsub("_", " "):gsub("^%l", string.upper))
		local label = string.format("%s (%d %s)", name, data.resource_cost.amount, data.resource_cost.id)
		eventShopItems[label] = { key = key, cost = data.resource_cost.amount, currency = data.resource_cost.id }
		table.insert(eventShopValues, label)
	end
end
table.sort(eventShopValues)

function Collection:EventResource(id)
	local value = LP._stats:FindFirstChild("_resource" .. tostring(id))
	return value and value.Value or (session.profile_data.resources or {})[id] or 0
end

-- maps for macro assignments: "map_id (World)"
local mapValues = { "Any map" }
do
	local seen = {}
	for _, level in Data.Levels do
		if type(level) == "table" and level.map and not seen[level.map] then
			seen[level.map] = true
			local w = level.world and Data.Worlds[level.world]
			table.insert(mapValues, level.map .. " (" .. tostring(w and w.name or level.name or "?") .. ")")
		end
	end
	table.sort(mapValues, function(a, b) return a == "Any map" or (b ~= "Any map" and a < b) end)
end

local ROOM = Core.DungeonServiceCore.TYPES -- dungeon room type ids

--------------------------- [[ Priority Lists ]] ---------------------------

-- A paragraph row holding a reorderable list: the box turns an entry on or off, the arrows move it.
-- Value is { { id = ..., on = true }, ... } top first, and it saves with the config like any other control.
local PALETTE = {
	Dark = { Field = Color3.fromRGB(17, 14, 25), Text = Color3.fromRGB(240, 236, 250), SubText = Color3.fromRGB(160, 152, 184),
		Accent = Color3.fromRGB(132, 88, 240), Off = Color3.fromRGB(62, 55, 84) },
	Amethyst = { Field = Color3.fromRGB(28, 17, 52), Text = Color3.fromRGB(244, 240, 255), SubText = Color3.fromRGB(190, 176, 224),
		Accent = Color3.fromRGB(168, 128, 255), Off = Color3.fromRGB(82, 62, 128) },
	Light = { Field = Color3.fromRGB(255, 255, 255), Text = Color3.fromRGB(24, 18, 38), SubText = Color3.fromRGB(105, 96, 128),
		Accent = Color3.fromRGB(112, 68, 224), Off = Color3.fromRGB(205, 198, 222) },
}
local priorityLists = {} -- render functions, re-run when the theme changes

function Collection:Instance(ClassName, Property)
	local Object = Instance.new(ClassName)
	for i, v in Property do
		if i ~= "Parent" then Object[i] = v end
	end
	Object.Parent = Property.Parent
	return Object
end

function Collection:AddPriorityList(section, id, options)
	local info, default = {}, {}
	for _, entry in options.Entries do
		info[entry.id] = entry
		table.insert(default, { id = entry.id, on = entry.on ~= false })
	end
	local element = section:AddParagraph({ Title = options.Title, Content = options.Description })
	element.Type = "Priority"
	Collection:Instance("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = element.Frame })
	local list = Collection:Instance("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, math.min(#default, options.Rows or 8) * 30),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3,
		Parent = element.Frame,
	})
	Collection:Instance("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })

	local render
	local function changed()
		render()
		if options.Callback then options.Callback(element.Value) end
	end
	render = function()
		local c = PALETTE[VaderUI.Theme] or PALETTE.Dark
		list.ScrollBarImageColor3 = c.Off
		for _, child in list:GetChildren() do
			if child:IsA("Frame") then child:Destroy() end
		end
		for rank, entry in element.Value do
			local e = info[entry.id]
			local line = Collection:Instance("Frame", {
				Size = UDim2.new(1, -6, 0, 26), BackgroundColor3 = c.Field, BorderSizePixel = 0, LayoutOrder = rank, Parent = list,
			})
			Collection:Instance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = line })
			local box = Collection:Instance("TextButton", {
				Text = "", AutoButtonColor = false, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 5, 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = entry.on and c.Accent or c.Off,
				Parent = line,
			})
			Collection:Instance("UICorner", { CornerRadius = UDim.new(0, 4), Parent = box })
			box.MouseButton1Click:Connect(function()
				entry.on = not entry.on
				changed()
			end)
			Collection:Instance("TextLabel", {
				BackgroundTransparency = 1, Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -80, 1, 0),
				Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd, RichText = true, TextColor3 = entry.on and c.Text or c.SubText,
				Text = string.format("%d. %s%s", rank, e.label,
					e.desc and string.format('  <font color="#%s">%s</font>', c.SubText:ToHex(), e.desc) or ""),
				Parent = line,
			})
			for i, step in { -1, 1 } do
				local arrow = Collection:Instance("ImageButton", {
					BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, i == 1 and -28 or -4, 0.5, 0),
					Size = UDim2.fromOffset(20, 20), Image = "rbxassetid://10709790948", Rotation = step < 0 and 180 or 0, ImageColor3 = c.SubText,
					Parent = line,
				})
				arrow.MouseButton1Click:Connect(function()
					local other = element.Value[rank + step]
					if other then
						element.Value[rank], element.Value[rank + step] = other, entry
						changed()
					end
				end)
			end
		end
	end

	-- keeps the saved order, drops ids that no longer exist and adds new ones at their default spot
	function element:SetValue(value)
		local seen, merged = {}, {}
		for _, entry in type(value) == "table" and value or {} do
			if type(entry) == "table" and info[entry.id] and not seen[entry.id] then
				seen[entry.id] = true
				table.insert(merged, { id = entry.id, on = entry.on ~= false })
			end
		end
		for _, entry in default do
			if not seen[entry.id] then table.insert(merged, { id = entry.id, on = entry.on }) end
		end
		self.Value = merged
		changed()
	end

	VaderUI.Options[id] = element
	table.insert(priorityLists, render)
	element:SetValue(default)
	return element
end

--------------------------- [[ Tabs ]] ---------------------------

local Tabs = {
	Main = Window:AddTab({ Title = "Main" }),
	Event = Window:AddTab({ Title = "Event" }),
	Dungeon = Window:AddTab({ Title = "Dungeon" }),
	Match = Window:AddTab({ Title = "Match" }),
	AutoPlay = Window:AddTab({ Title = "Auto Play" }),
	Macro = Window:AddTab({ Title = "Macro" }),
	Summon = Window:AddTab({ Title = "Summon" }),
	Traits = Window:AddTab({ Title = "Traits & Stats" }),
	Rewards = Window:AddTab({ Title = "Rewards" }),
	Misc = Window:AddTab({ Title = "Misc" }),
	Settings = Window:AddTab({ Title = "Settings" }),
}

--------------------------- [[ Main Tab ]] ---------------------------

local JoinSection = Tabs.Main:AddSection("Auto Join")
local JoinStatus = JoinSection:AddParagraph({
	Title = "Status",
	Content = IS_LOBBY and "Idle. With several modes on, tries Challenge, Raid, Legend, Story, then Infinite."
		or "In a match - joining runs in the lobby.",
})
JoinSection:AddToggle("FriendsOnly", {
	Title = "Friends Only", Default = false,
	Callback = function(value) State.FriendsOnly = value end,
})
JoinSection:AddDropdown("Loadout", {
	Title = "Team Loadout", Values = loadoutValues, Default = "Don't change", Multi = false,
	Description = "Loaded once before auto join starts a stage.",
	Callback = function(value) State.Loadout = value end,
})
JoinSection:AddSlider("TeleportDelay", {
	Title = "Teleport Delay (seconds)", Default = 0, Min = 0, Max = 60, Rounding = 0,
	Description = "Waits this long before anything that sends you to another place: starting a stage, challenge or contract, entering a dungeon room, replay / next votes and going back to the lobby. Turning that feature off during the wait cancels it.",
	Callback = function(value) State.TeleportDelay = value end,
})

local MODE_INFO = {
	Story = "Story acts.",
	Infinite = "Infinite mode. Always Hard.",
	Legend = "Legend stages. Always Hard.",
	Raid = "Raids. Always Hard. Skipped when it can't start, e.g. no tries left.",
}
for _, mode in MODES do
	local section = Tabs.Main:AddSection(mode)
	section:AddToggle("Join" .. mode, {
		Title = "Auto Join " .. mode, Default = false, Description = MODE_INFO[mode],
		Callback = function(value) State.Join[mode] = value end,
	})
	section:AddDropdown(mode .. "Stage", {
		Title = mode == "Infinite" and "World" or "Stage", Values = stages[mode].labels, Multi = false,
		Callback = function(value) State.Stage[mode] = value end,
	})
	if mode == "Story" then
		section:AddDropdown("Difficulty", {
			Title = "Difficulty", Values = { "Normal", "Hard" }, Default = "Normal", Multi = false,
			Callback = function(value) State.Difficulty = value end,
		})
	end
end

local ChallengeSection = Tabs.Main:AddSection("Challenge")
ChallengeSection:AddToggle("AutoJoinChallenge", {
	Title = "Auto Join Challenge", Default = false,
	Description = "In the lobby: joins the rotating challenge first if you haven't cleared it.",
	Callback = function(value) State.AutoJoinChallenge = value end,
})
ChallengeSection:AddToggle("LeaveOnChallenge", {
	Title = "Leave When Challenge Changes", Default = false,
	Description = "In a match: goes back to lobby when a new rotating challenge starts.",
	Callback = function(value) State.LeaveOnChallenge = value end,
})

--------------------------- [[ Event Tab ]] ---------------------------

local eventNote, contractPreview = "Idle", "Next contract: checking..."
local EventStatus = Tabs.Event:AddParagraph({ Title = "Status", Content = "-" })
function Collection:RefreshEventStatus()
	local res = Data.GameplaySettings.CURRENT_EVENT_RESOURCE
	EventStatus:SetDesc(string.format("%s: %d\n%s\n%s", tostring(res), Collection:EventResource(res), contractPreview, eventNote))
end
Collection:RefreshEventStatus()

local ContractSection = Tabs.Event:AddSection("Event Contracts")
ContractSection:AddToggle("AutoContract", {
	Title = "Auto Contract", Default = false,
	Description = "In the lobby: opens a contract portal and starts it. After a contract match: votes the next contract.",
	Callback = function(value) State.AutoContract = value end,
})
ContractSection:AddDropdown("ContractWeakTo", {
	Title = "Weak To", Values = { "Physical", "Magic" }, Multi = true, Default = { "Physical", "Magic" },
	Description = "Only contracts weak to a picked damage type. Both picked allows either; none picked allows any.",
	Callback = function(value) State.ContractWeakTo = value end,
})
ContractSection:AddDropdown("ContractTierMode", {
	Title = "Tier", Values = { "Highest tier", "Highest up to Max Tier" }, Default = "Highest tier", Multi = false,
	Callback = function(value) State.ContractTierMode = value end,
})
ContractSection:AddSlider("ContractMaxTier", {
	Title = "Max Tier", Min = 1, Max = 30, Default = 10, Rounding = 0,
	Description = "Used with \"Highest up to Max Tier\".",
	Callback = function(value) State.ContractMaxTier = value end,
})
ContractSection:AddToggle("SkipCompletedContracts", {
	Title = "Skip Completed Contracts", Default = true,
	Description = "A completed contract gives no extra rewards until it rotates.",
	Callback = function(value) State.SkipCompletedContracts = value end,
})

local EventShopSection = Tabs.Event:AddSection("Event Shop")
EventShopSection:AddDropdown("EventShopItems", {
	Title = "Items", Values = eventShopValues, Multi = true, Default = {},
	Callback = function(value) State.EventShopItems = value end,
})
EventShopSection:AddToggle("AutoEventShop", {
	Title = "Auto Buy", Default = false,
	Description = "Buys the picked items whenever you have enough event currency.",
	Callback = function(value) State.AutoEventShop = value end,
})

--------------------------- [[ Dungeon Tab ]] ---------------------------

local roomEntries = {
	{ id = ROOM.TREASURE_GOLD, label = "Rare Chest", desc = "better loot, Secret unit chance after the boss" },
	{ id = ROOM.TREASURE, label = "Chest", desc = "generic loot" },
	{ id = ROOM.MONEY, label = "Hoard", desc = "money for shops" },
	{ id = ROOM.SHOP, label = "Shop", desc = "buy items" },
	{ id = ROOM.SHRINE, label = "Shrine", desc = "an offer to accept or deny" },
	{ id = ROOM.CURSE, label = "Curse", desc = "stronger enemies for the rest of the run", on = false },
}

local weakEntries = {}
for id, def in Data.DamageTypes.TYPES do
	local name = def.name or id
	table.insert(weakEntries, {
		id = id, label = name, on = id == "physical" or id == "magic",
		desc = not id:find(name:lower(), 1, true) and id or nil, -- "Rose" is ice_damage, "Storm" lightning_damage
	})
end
table.sort(weakEntries, function(a, b)
	if a.on ~= b.on then return a.on end
	return a.label < b.label
end)

local TIER_RANK = { legendary = 4, ["3"] = 3, ["2"] = 2, ["1"] = 1 }
local shopEntries = {}
for id, item in Core.DungeonServiceCore.ITEMS do
	if id:sub(1, 1) ~= "_" then -- a leading underscore marks curses
		table.insert(shopEntries, {
			id = id, label = string.format("%s (%d)", item.name, item.cost), desc = item.description, tier = TIER_RANK[item.tier] or 0,
		})
	end
end
table.sort(shopEntries, function(a, b)
	if a.tier ~= b.tier then return a.tier > b.tier end
	return a.label < b.label
end)

local DungeonSection = Tabs.Dungeon:AddSection("Dungeon Run")
local DungeonStatus = DungeonSection:AddParagraph({ Title = "Status", Content = "-" })
DungeonSection:AddToggle("AutoDungeon", {
	Title = "Auto Dungeon", Default = false,
	Description = "Picks rooms, buys from shops, handles chests and shrines, and continues after a death. In a match it waits for the match to end before picking.",
	Callback = function(value) State.AutoDungeon = value end,
})
DungeonSection:AddToggle("DungeonStart", {
	Title = "Auto Start Run", Default = false,
	Description = "In the lobby: starts a run with a Dungeon Run Key when none is going. Turns itself off when a run can't start.",
	Callback = function(value) State.DungeonStart = value end,
})
DungeonSection:AddDropdown("DungeonChests", {
	Title = "Open Chests", Values = { "Save for the end", "At every checkpoint" }, Default = "Save for the end", Multi = false,
	Description = "Rare Chests opened after the boss room can drop a Secret unit.",
	Callback = function(value) State.DungeonChests = value end,
})
DungeonSection:AddDropdown("DungeonShrine", {
	Title = "Shrine", Values = { "Accept", "Accept if no curse", "Deny" }, Default = "Accept if no curse", Multi = false,
	Callback = function(value) State.DungeonShrine = value end,
})

local RoomSection = Tabs.Dungeon:AddSection("Room Priority")
RoomSection:AddDropdown("DungeonPickBy", {
	Title = "Pick Rooms By", Values = { "Rewards, then weakness", "Weakness, then rewards" }, Default = "Rewards, then weakness", Multi = false,
	Callback = function(value) State.DungeonPickBy = value end,
})
RoomSection:AddToggle("DungeonLookahead", {
	Title = "Look One Room Ahead", Default = true,
	Description = "Adds half the best reward score of the rooms each choice leads to.",
	Callback = function(value) State.DungeonLookahead = value end,
})
Collection:AddPriorityList(RoomSection, "DungeonRoomOrder", {
	Title = "Rewards", Entries = roomEntries, Rows = #roomEntries,
	Description = "On: wanted, higher counts more. Off: avoided.",
	Callback = function(value) State.DungeonRoomOrder = value end,
})
Collection:AddPriorityList(RoomSection, "DungeonWeakOrder", {
	Title = "Weak Against", Entries = weakEntries, Rows = #weakEntries,
	Description = "Prefers rooms whose enemies take extra damage from the types that are on, higher counts more. Off: ignored.",
	Callback = function(value) State.DungeonWeakOrder = value end,
})

local DungeonShopSection = Tabs.Dungeon:AddSection("Shop Priority")
Collection:AddPriorityList(DungeonShopSection, "DungeonShopOrder", {
	Title = "Items", Entries = shopEntries,
	Description = "Buys the highest item on the list that the shop has and you can afford, one at a time, until none fit. Off: never bought.",
	Callback = function(value) State.DungeonShopOrder = value end,
})

--------------------------- [[ Match Tab ]] ---------------------------

local MatchSection = Tabs.Match:AddSection("Match")
local MatchStatus = MatchSection:AddParagraph({ Title = "Status", Content = IS_LOBBY and "In the lobby." or "Waiting..." })
MatchSection:AddToggle("AutoStart", {
	Title = "Auto Vote Start", Default = false,
	Description = "Counts down from Start Delay, then votes start. Turn it off during the countdown to cancel.",
	Callback = function(value) State.AutoStart = value end,
})
MatchSection:AddSlider("StartDelay", {
	Title = "Start Delay (seconds)", Default = 10, Min = 0, Max = 60, Rounding = 0,
	Callback = function(value) State.StartDelay = value end,
})
MatchSection:AddToggle("AutoSkip", {
	Title = "Auto Skip Waves", Default = false,
	Callback = function(value) State.AutoSkip = value end,
})
MatchSection:AddDropdown("EndAction", {
	Title = "When Match Ends", Values = { "Nothing", "Replay", "Next Stage", "Lobby" }, Default = "Nothing", Multi = false,
	Description = "Next Stage falls back to Replay outside story mode.",
	Callback = function(value) State.EndAction = value end,
})

local SellSection = Tabs.Match:AddSection("Sell")
SellSection:AddToggle("AutoSell", {
	Title = "Auto Sell Units At Wave", Default = false,
	Callback = function(value) State.AutoSell = value end,
})
SellSection:AddSlider("SellWave", {
	Title = "Sell At Wave", Default = 20, Min = 1, Max = 200, Rounding = 0,
	Callback = function(value) State.SellWave = value end,
})

--------------------------- [[ Auto Play Tab ]] ---------------------------

local PlaceSection = Tabs.AutoPlay:AddSection("Auto Place")
local PlaceStatus = PlaceSection:AddParagraph({ Title = "Status", Content = IS_LOBBY and "In the lobby." or "Waiting..." })
PlaceSection:AddToggle("AutoPlace", {
	Title = "Auto Place", Default = false,
	Description = "Places the slots that are on around each slot's own point: one of each unit, then second copies, and so on, slot order breaking ties. Waits for money, and pauses while Play Macro is on.",
	Callback = function(value) State.AutoPlace = value end,
})
PlaceSection:AddToggle("ShowHolograms", {
	Title = "Show Holograms", Default = true,
	Description = "See-through copies of your units on the exact spots Auto Place will use, in order, tagged slot·copy. On your screen only.",
	Callback = function(value) State.ShowHolograms = value end,
})
PlaceSection:AddToggle("ShowPlacePoint", {
	Title = "Show Placement Points", Default = true,
	Description = "A numbered glowing ball at each slot's point, on your screen only.",
	Callback = function(value) State.ShowPlacePoint = value end,
})

-- where a unit can stand, for slot titles and the status
function Collection:PlacementTag(data)
	return data.hill_unit and " (hill)" or (data.hybrid_placement and " (hill or ground)" or "")
end

-- one section per team slot; positions are saved per map and slot
function Collection:SetSlotPosition(slot)
	local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
	local map = Collection:MapKey()
	if IS_LOBBY or not map or not root then return Collection:Notify("Stand on the spot in a match first.") end
	placePositions[map .. "|" .. slot] = { root.Position.X, root.Position.Y, root.Position.Z }
	Collection:WriteJson(placePositionsPath, placePositions)
	VaderUI.Options["Slot" .. slot .. "Mode"]:SetValue("My position")
	Collection:Notify("Saved slot " .. slot .. "'s spot for " .. map)
end

for _, slot in Data.GameplaySettings.UNIT_SLOTS do
	local cfg = { On = true, Mode = "Enemy path", Percent = 50, Max = 6 }
	State.Slots[slot] = cfg
	local equipped = session.profile_data.collection.equipped_units
	local u = Collection:Owned()[equipped[slot] or equipped[tonumber(slot)] or ""]
	local cap = u and Data.Units[u.unit_id] and Data.Units[u.unit_id].spawn_cap
	local section = Tabs.AutoPlay:AddSection("Slot " .. slot .. " - "
		.. (u and (Collection:UnitName(u) .. Collection:PlacementTag(Data.Units[u.unit_id] or {})) or "empty"))
	section:AddToggle("Slot" .. slot .. "Place", {
		Title = "Place This Slot", Default = true,
		Callback = function(value) cfg.On = value end,
	})
	section:AddDropdown("Slot" .. slot .. "Mode", {
		Title = "Place Around", Values = { "Enemy path", "My position" }, Default = "Enemy path", Multi = false,
		Callback = function(value) cfg.Mode = value end,
	})
	section:AddSlider("Slot" .. slot .. "Percent", {
		Title = "Path Point (% from enemy spawn)", Default = 50, Min = 0, Max = 100, Rounding = 0,
		Description = "0 is where enemies spawn, 100 is your base. Used with Enemy path.",
		Callback = function(value) cfg.Percent = value end,
	})
	section:AddSlider("Slot" .. slot .. "Max", {
		Title = "Max Placed", Default = 6, Min = 1, Max = 6, Rounding = 0,
		Description = cap and ("This unit can be placed " .. cap .. " time" .. (cap == 1 and "" or "s") .. " at most.") or nil,
		Callback = function(value) cfg.Max = value end,
	})
	section:AddButton({
		Title = "Set Position Here",
		Description = "Saves where your character stands as this slot's spot on this map and switches it to My position.",
		Callback = function() Collection:SetSlotPosition(slot) end,
	})
end

local UpgradeSection = Tabs.AutoPlay:AddSection("Upgrade & Abilities")
UpgradeSection:AddToggle("AutoUpgrade", {
	Title = "Auto Upgrade", Default = false,
	Description = "Picked units first, then the cheapest upgrade.",
	Callback = function(value) State.AutoUpgrade = value end,
})
UpgradeSection:AddDropdown("UpgradeFirst", {
	Title = "Upgrade First", Values = equippedNames, Multi = true, Default = {},
	Callback = function(value) State.UpgradeFirst = value end,
})
UpgradeSection:AddToggle("PlaceBeforeUpgrading", {
	Title = "Place Before Upgrading", Default = true,
	Description = "With Auto Place on, upgrades wait until every slot is placed, so money adds up to the next placement.",
	Callback = function(value) State.PlaceBeforeUpgrade = value end,
})
UpgradeSection:AddToggle("AutoAbility", {
	Title = "Auto Use Abilities", Default = false,
	Callback = function(value) State.AutoAbility = value end,
})

--------------------------- [[ Macro Tab ]] ---------------------------

local MacroMain = Tabs.Macro:AddSection("Macro")
MacroStatus = MacroMain:AddParagraph({ Title = "Status", Content = IS_LOBBY and "In the lobby." or "Waiting for the match..." })
MacroMain:AddDropdown("MacroName", {
	Title = "Macro", Values = Collection:ListMacros(), Multi = false,
	Description = "Recorded into and played. With Auto Switch on, an assignment for this game mode and map wins.",
	Callback = function(value) State.MacroName = value end,
})
MacroMain:AddToggle("RecordMacro", {
	Title = "Record Macro", Default = false,
	Description = "Records your spawns, upgrades, sells and abilities. Replaces the macro's steps once your first action lands; with no macro picked it creates Mode_map.",
	Callback = function(value)
		State.RecordMacro = value
		recording, recordTarget = value and {} or nil, nil
	end,
})
MacroMain:AddToggle("PlayMacro", {
	Title = "Play Macro", Default = false,
	Description = "Replays in order. Spawns and upgrades wait for money; sells and abilities wait for their recorded wave.",
	Callback = function(value) State.PlayMacro = value end,
})

local MacroManage = Tabs.Macro:AddSection("Manage")
MacroManage:AddInput("MacroNewName", {
	Title = "Name", Placeholder = "macro name", Default = "", Finished = false,
})
function Collection:TypedName()
	local name = Collection:CleanMacroName(VaderUI.Options.MacroNewName.Value)
	if name == "" then Collection:Notify("Type a name first (letters, numbers, space, _ and -).") return nil end
	if canPersist and isfile(Collection:MacroPath(name)) then Collection:Notify(name .. " already exists.") return nil end
	return name
end
MacroManage:AddButton({
	Title = "Create Macro",
	Callback = function()
		local name = Collection:TypedName()
		if not name then return end
		Collection:SaveMacro(name, {})
		Collection:RefreshMacroLists()
		VaderUI.Options.MacroName:SetValue(name)
		Collection:Notify("Created " .. name)
	end,
})
MacroManage:AddButton({
	Title = "Rename Selected Macro",
	Description = "Renames the picked macro to the name above. Its assignments follow it.",
	Callback = function()
		local old = State.MacroName
		if not old then return Collection:Notify("Pick a macro to rename.") end
		local name = Collection:TypedName()
		if not name then return end
		writefile(Collection:MacroPath(name), readfile(Collection:MacroPath(old)))
		if type(delfile) == "function" then delfile(Collection:MacroPath(old)) end
		for key, assigned in assignments do
			if assigned == old then assignments[key] = name end
		end
		Collection:WriteJson(macroAssignPath, assignments)
		Collection:RefreshMacroLists()
		VaderUI.Options.MacroName:SetValue(name)
		Collection:RefreshAssignList()
		Collection:Notify("Renamed " .. old .. " to " .. name)
	end,
})
MacroManage:AddButton({
	Title = "Delete Selected Macro",
	Callback = function()
		local name = State.MacroName
		if not name then return Collection:Notify("Pick a macro to delete.") end
		Window:Dialog({
			Title = "Delete macro?",
			Content = "Delete " .. name .. " and its assignments? This can't be undone.",
			Buttons = {
				{ Title = "Delete", Callback = function()
					if type(delfile) == "function" then delfile(Collection:MacroPath(name)) end
					for key, assigned in assignments do
						if assigned == name then assignments[key] = nil end
					end
					Collection:WriteJson(macroAssignPath, assignments)
					Collection:RefreshMacroLists()
					Collection:RefreshAssignList()
					Collection:Notify("Deleted " .. name)
				end },
				{ Title = "Cancel" },
			},
		})
	end,
})

local MacroSwitch = Tabs.Macro:AddSection("Auto Switch")
local AssignList = MacroSwitch:AddParagraph({ Title = "Assignments", Content = "-" })
function Collection:RefreshAssignList()
	local lines = {}
	for key, name in assignments do
		local mode, map = key:match("^(.-)|(.*)$")
		table.insert(lines, string.format("%s | %s -> %s", mode, map, name))
	end
	table.sort(lines)
	AssignList:SetDesc(#lines > 0 and table.concat(lines, "\n") or "None yet.")
end
Collection:RefreshAssignList()
MacroSwitch:AddToggle("AutoSwitchMacro", {
	Title = "Switch Macro By Game Mode & Map", Default = false,
	Description = "Each match uses the macro assigned to its game mode and map, then its game mode on Any map.",
	Callback = function(value) State.AutoSwitchMacro = value end,
})
MacroSwitch:AddDropdown("AssignMode", { Title = "Game Mode", Values = MACRO_MODES, Default = "Story", Multi = false })
MacroSwitch:AddDropdown("AssignMap", { Title = "Map", Values = mapValues, Default = "Any map", Multi = false })
MacroSwitch:AddDropdown("AssignMacro", { Title = "Macro", Values = Collection:ListMacros(), Multi = false })
function Collection:AssignKey()
	local map = VaderUI.Options.AssignMap.Value or "Any map"
	return VaderUI.Options.AssignMode.Value .. "|" .. (map == "Any map" and map or map:match("^(%S+)"))
end
MacroSwitch:AddButton({
	Title = "Use Current Match",
	Description = "Fills Game Mode and Map from the match you're in.",
	Callback = function()
		if not Collection:CurrentMode() then return Collection:Notify("Join a match first.") end
		VaderUI.Options.AssignMode:SetValue(Collection:CurrentMode())
		for _, label in mapValues do
			if label:match("^(%S+)") == Collection:MapKey() then VaderUI.Options.AssignMap:SetValue(label) end
		end
	end,
})
MacroSwitch:AddButton({
	Title = "Assign",
	Callback = function()
		local name = VaderUI.Options.AssignMacro.Value
		if not name then return Collection:Notify("Pick a macro to assign.") end
		assignments[Collection:AssignKey()] = name
		Collection:WriteJson(macroAssignPath, assignments)
		Collection:RefreshAssignList()
		Collection:Notify(Collection:AssignKey() .. " -> " .. name)
	end,
})
MacroSwitch:AddButton({
	Title = "Remove Assignment",
	Callback = function()
		assignments[Collection:AssignKey()] = nil
		Collection:WriteJson(macroAssignPath, assignments)
		Collection:RefreshAssignList()
	end,
})

function Collection:RefreshMacroLists()
	local names = Collection:ListMacros()
	for _, id in { "MacroName", "AssignMacro" } do
		local option = VaderUI.Options[id]
		local keep = option.Value
		option:SetValues(names)
		option:SetValue(keep and table.find(names, keep) and keep or nil)
	end
end

--------------------------- [[ Summon Tab ]] ---------------------------

local SummonSection = Tabs.Summon:AddSection("Auto Summon")
local SummonStatus = SummonSection:AddParagraph({ Title = "Status", Content = "Idle" })
SummonSection:AddDropdown("Banner", {
	Title = "Banner", Values = bannerValues, Default = State.Banner, Multi = false,
	Callback = function(value) State.Banner = value end,
})
SummonSection:AddDropdown("SummonPay", {
	Title = "Summon", Values = { "Gems x1", "Gems x10", "Ticket" }, Default = "Gems x10", Multi = false,
	Callback = function(value) State.SummonPay = value end,
})
SummonSection:AddInput("KeepGems", {
	Title = "Keep At Least (gems)", Default = "0", Numeric = true, Finished = true,
	Callback = function(value) State.KeepGems = tonumber(value) or 0 end,
})
SummonSection:AddToggle("AutoSummon", {
	Title = "Auto Summon", Default = false,
	Description = "Stops at your gem reserve, when storage is full, or when a summon doesn't go through.",
	Callback = function(value) State.AutoSummon = value end,
})

local AutoSellSection = Tabs.Summon:AddSection("Sell Junk Units")
local SELL_RARITIES = { "Rare", "Epic", "Legendary", "Mythic" }
local currentAutosell = {}
for _, rarity in SELL_RARITIES do
	local setting = LP._settings:FindFirstChild("autosell_" .. rarity:lower())
	if setting and setting.Value then currentAutosell[rarity] = true end
end
AutoSellSection:AddDropdown("AutoSellRarities", {
	Title = "Auto-Sell Summoned", Values = SELL_RARITIES, Multi = true, Default = currentAutosell,
	Description = "Uses the game's own auto-sell for newly summoned units.",
	Callback = function(picked)
		for _, rarity in SELL_RARITIES do
			local name = "autosell_" .. rarity:lower()
			local setting = LP._settings:FindFirstChild(name)
			local want = picked[rarity] == true
			if setting and setting.Value ~= want then Collection:Invoke("toggle_setting", name, want) end
		end
	end,
})

--------------------------- [[ Traits & Stats Tab ]] ---------------------------

local unitLabels = Collection:BuildUnitLabels()
local TraitSection = Tabs.Traits:AddSection("Trait Reroll")
local TraitStatus = TraitSection:AddParagraph({ Title = "Status", Content = "Pick a unit." })
local PAY = {
	["Reroll Token"] = "token",
	["Star Remnant"] = "star_remnant",
	["Star Remnant (Limited)"] = "star_remnant_limited",
	["Legacy Remnant"] = "trait_reroll_legacy",
}
local traitUuid, statUuid, traitRunning = nil, nil, false

function Collection:TraitBalance(payId)
	if payId == "token" then return session.profile_data.trait_reroll_tokens or 0 end
	return session.inventory:get_number_of_owned_item(payId) or 0
end
function Collection:TraitCost(u, payId)
	if payId == "token" then return 1 end
	return Core.TraitServiceCore.get_reroll_requirements(Data.Units[u.unit_id].rarity, Data.Items[payId].usage.type, payId)
end
function Collection:IsTargetTrait(traits)
	for _, t in traits or {} do
		local def = Data.Traits[t.trait]
		local tiered = t.trait == "superior" or t.trait == "range" or t.trait == "nimble"
		if def and State.RerollTargets[def.name or t.trait] and (not tiered or tonumber(t.tier) >= State.RerollMinTier) then
			return true
		end
	end
	return false
end
function Collection:RefreshTraitStatus(extra)
	local u = traitUuid and Collection:Owned()[traitUuid]
	local payId = PAY[State.RerollPay]
	local lines = {}
	if u then
		table.insert(lines, Collection:UnitName(u) .. ": " .. Collection:DescribeTraits(u.traits))
		table.insert(lines, string.format("%s: %d  |  cost per roll: %d", State.RerollPay, Collection:TraitBalance(payId), Collection:TraitCost(u, payId)))
	end
	if extra then table.insert(lines, extra) end
	TraitStatus:SetDesc(#lines > 0 and table.concat(lines, "\n") or "Pick a unit.")
end

TraitSection:AddDropdown("TraitUnit", {
	Title = "Unit", Values = unitLabels, Multi = false,
	Callback = function(label)
		traitUuid = uuidOf[label]
		Collection:RefreshTraitStatus()
	end,
})
TraitSection:AddDropdown("RerollTargets", {
	Title = "Stop On Traits", Values = traitNames, Multi = true, Default = { "Golden", "Unique", "Divine" },
	Callback = function(value) State.RerollTargets = value end,
})
TraitSection:AddSlider("RerollMinTier", {
	Title = "Min Tier For Superior / Range / Nimble", Min = 1, Max = 3, Default = 3, Rounding = 0,
	Callback = function(value) State.RerollMinTier = value end,
})
TraitSection:AddDropdown("RerollPay", {
	Title = "Pay With", Values = { "Reroll Token", "Star Remnant", "Star Remnant (Limited)", "Legacy Remnant" },
	Default = "Reroll Token", Multi = false,
	Callback = function(value)
		State.RerollPay = value
		Collection:RefreshTraitStatus()
	end,
})
TraitSection:AddToggle("ProtectMythic", {
	Title = "Protect Mythic Traits", Default = true,
	Description = "Stop instead of rerolling away a Mythic trait you didn't pick.",
	Callback = function(value) State.ProtectMythic = value end,
})

function Collection:RefreshUnitDropdowns()
	local rows = Collection:BuildUnitLabels()
	for id, uuid in { TraitUnit = traitUuid, StatUnit = statUuid } do
		VaderUI.Options[id]:SetValues(rows)
		if labelOf[uuid] then VaderUI.Options[id]:SetValue(labelOf[uuid]) end
	end
end

function Collection:FinishTrait(msg)
	traitRunning = false
	VaderUI.Options.AutoTraitReroll:SetValue(false)
	Collection:RefreshUnitDropdowns()
	Collection:RefreshTraitStatus(msg)
	Collection:Notify(msg)
end

function Collection:TraitLoop(uuid, payId)
	local u = Collection:Owned()[uuid]
	local i = 0
	while true do
		i += 1
		if not traitRunning or closed then return Collection:FinishTrait("Stopped after " .. (i - 1) .. " rolls") end
		local have, need = Collection:TraitBalance(payId), Collection:TraitCost(u, payId)
		if have < need then
			return Collection:FinishTrait(string.format("Out of %s (have %d, need %d) after %d rolls", State.RerollPay, have, need, i - 1))
		end
		local traits = Collection:RequestAndWait(fromServer.unit_traits_changed, uuid, function()
			if payId == "token" then
				Collection:Invoke("request_token_trait_reroll", uuid)
			else
				Collection:Invoke("use_item", payId, { unit_uuid = uuid })
			end
		end)
		if not traitRunning then return Collection:FinishTrait("Stopped after " .. i .. " rolls") end
		if not traits then return Collection:FinishTrait("No response from server on roll " .. i) end
		Collection:RefreshTraitStatus(string.format("Roll %d: %s", i, Collection:DescribeTraits(traits)))
		if Collection:IsTargetTrait(traits) then
			Collection:Webhook("Reroll hits", "Trait hit!", { Collection:UnitName(u) .. " -> **" .. Collection:DescribeTraits(traits) .. "**", "Rolls: " .. i })
			return Collection:FinishTrait("GOT IT: " .. Collection:UnitName(u) .. " -> " .. Collection:DescribeTraits(traits) .. " in " .. i .. " rolls")
		end
		if State.ProtectMythic and Core.TraitServiceCore.unit_has_mythic_trait({ traits = traits }) then
			return Collection:FinishTrait("Rolled " .. Collection:DescribeTraits(traits) .. " (Mythic, not picked) - kept it")
		end
		task.wait(0.75)
	end
end

TraitSection:AddToggle("AutoTraitReroll", {
	Title = "Auto Trait Reroll", Default = false,
	Description = "Rolls until a picked trait or out of currency. Never uses the Robux reroll.",
	Callback = function(on)
		if not on then traitRunning = false return end
		if traitRunning then return end
		local u = traitUuid and Collection:Owned()[traitUuid]
		local payId = PAY[State.RerollPay]
		local function reject(msg)
			VaderUI.Options.AutoTraitReroll:SetValue(false)
			Collection:RefreshTraitStatus(msg)
		end
		if not u then return reject("Pick a unit first.") end
		if next(State.RerollTargets) == nil then return reject("Pick at least one trait.") end
		if Collection:IsTargetTrait(u.traits) then return reject(Collection:UnitName(u) .. " already has " .. Collection:DescribeTraits(u.traits)) end
		if State.ProtectMythic and Core.TraitServiceCore.unit_has_mythic_trait(u) then
			return reject(Collection:UnitName(u) .. " has " .. Collection:DescribeTraits(u.traits) .. " (Mythic). Turn off Protect Mythic to reroll it.")
		end
		if Collection:TraitBalance(payId) < Collection:TraitCost(u, payId) then
			return reject(string.format("Not enough %s (have %d, need %d)", State.RerollPay, Collection:TraitBalance(payId), Collection:TraitCost(u, payId)))
		end
		local uuid = traitUuid
		Window:Dialog({
			Title = "Start trait reroll?",
			Content = string.format("%s (%s)\nRolls until a picked trait or out of currency. %d %s each, you have %d.",
				Collection:UnitName(u), Collection:DescribeTraits(u.traits), Collection:TraitCost(u, payId), State.RerollPay, Collection:TraitBalance(payId)),
			Buttons = {
				{ Title = "Start", Callback = function()
					traitRunning = true
					task.spawn(Collection.TraitLoop, Collection, uuid, payId)
				end },
				{ Title = "Cancel", Callback = function() VaderUI.Options.AutoTraitReroll:SetValue(false) end },
			},
		})
	end,
})

local StatSection = Tabs.Traits:AddSection("Stat Reroll")
local StatStatus = StatSection:AddParagraph({ Title = "Status", Content = "Pick a unit." })
local STAT_MODES = { ["All stats"] = "all", ["Damage only"] = "potency_stat", ["Speed only"] = "speed_stat", ["Range only"] = "range_stat" }
local STAT_LABEL = { potency_stat = "Damage", speed_stat = "Speed", range_stat = "Range" }
local statRunning = false

function Collection:StatItem() return STAT_MODES[State.StatMode] == "all" and "reroll_stat_all" or "reroll_stat_specific" end
function Collection:StatRanks(u, stats)
	local parts = {}
	for _, stat in { "potency_stat", "speed_stat", "range_stat" } do
		local ok, r = pcall(Core.TraitServiceCore.calculate_stat_rank, u.unit_id, stats or u.trait_stats or {}, stat)
		parts[stat] = ok and r or "?"
	end
	return parts
end
function Collection:StatsText(ranks)
	return string.format("Damage %s | Speed %s | Range %s", ranks.potency_stat, ranks.speed_stat, ranks.range_stat)
end
function Collection:StatHit(ranks)
	local need = table.find(RANKS, State.StatTarget) or #RANKS
	local mode = STAT_MODES[State.StatMode]
	for stat, rank in ranks do
		if (mode == "all" or mode == stat) and (table.find(RANKS, rank) or 0) < need then return false end
	end
	return true
end
function Collection:RefreshStatStatus(extra)
	local u = statUuid and Collection:Owned()[statUuid]
	local lines = {}
	if u then
		table.insert(lines, Collection:UnitName(u) .. ": " .. Collection:StatsText(Collection:StatRanks(u)))
		table.insert(lines, Collection:StatItem() .. ": " .. (session.inventory:get_number_of_owned_item(Collection:StatItem()) or 0) .. "  |  cost per roll: 1")
	end
	if extra then table.insert(lines, extra) end
	StatStatus:SetDesc(#lines > 0 and table.concat(lines, "\n") or "Pick a unit.")
end

StatSection:AddDropdown("StatUnit", {
	Title = "Unit", Values = unitLabels, Multi = false,
	Callback = function(label)
		statUuid = uuidOf[label]
		Collection:RefreshStatStatus()
	end,
})
StatSection:AddDropdown("StatMode", {
	Title = "Reroll", Values = { "All stats", "Damage only", "Speed only", "Range only" }, Default = "All stats", Multi = false,
	Callback = function(value)
		State.StatMode = value
		Collection:RefreshStatStatus()
	end,
})
StatSection:AddDropdown("StatTarget", {
	Title = "Stop At Rank (or better)", Values = RANKS, Default = "S", Multi = false,
	Description = "For All stats, every stat must reach it.",
	Callback = function(value) State.StatTarget = value end,
})

function Collection:FinishStat(msg)
	statRunning = false
	VaderUI.Options.AutoStatReroll:SetValue(false)
	Collection:RefreshUnitDropdowns()
	Collection:RefreshStatStatus(msg)
	Collection:Notify(msg)
end

function Collection:StatLoop(uuid)
	local u = Collection:Owned()[uuid]
	local mode, item = STAT_MODES[State.StatMode], Collection:StatItem()
	local i = 0
	while true do
		i += 1
		if not statRunning or closed then return Collection:FinishStat("Stopped after " .. (i - 1) .. " rolls") end
		if (session.inventory:get_number_of_owned_item(item) or 0) < 1 then
			return Collection:FinishStat("Out of " .. item .. " after " .. (i - 1) .. " rolls")
		end
		local stats = Collection:RequestAndWait(fromServer.unit_base_stats_changed, uuid, function()
			if mode == "all" then Collection:Invoke("reroll_base_stats_all", uuid) else Collection:Invoke("reroll_base_stats_specific", uuid, mode) end
		end)
		if not statRunning then return Collection:FinishStat("Stopped after " .. i .. " rolls") end
		if not stats then return Collection:FinishStat("No response from server on roll " .. i) end
		local ranks = Collection:StatRanks(u, stats)
		Collection:RefreshStatStatus(string.format("Roll %d: %s", i, Collection:StatsText(ranks)))
		if Collection:StatHit(ranks) then
			Collection:Webhook("Reroll hits", "Stat hit!", { Collection:UnitName(u) .. " -> " .. Collection:StatsText(ranks), "Rolls: " .. i })
			return Collection:FinishStat("GOT IT: " .. Collection:UnitName(u) .. " -> " .. Collection:StatsText(ranks) .. " in " .. i .. " rolls")
		end
		task.wait(0.75)
	end
end

StatSection:AddToggle("AutoStatReroll", {
	Title = "Auto Stat Reroll", Default = false,
	Callback = function(on)
		if not on then statRunning = false return end
		if statRunning then return end
		local uuid = statUuid
		local u = uuid and Collection:Owned()[uuid]
		local function reject(msg)
			VaderUI.Options.AutoStatReroll:SetValue(false)
			Collection:RefreshStatStatus(msg)
		end
		if not u then return reject("Pick a unit first.") end
		if Collection:StatHit(Collection:StatRanks(u)) then return reject(Collection:UnitName(u) .. " already meets " .. State.StatTarget) end
		local have = session.inventory:get_number_of_owned_item(Collection:StatItem()) or 0
		if have < 1 then return reject("You have no " .. Collection:StatItem()) end
		Window:Dialog({
			Title = "Start stat reroll?",
			Content = string.format("%s (%s)\n%s until %s or better. You have %d %s.",
				Collection:UnitName(u), Collection:StatsText(Collection:StatRanks(u)), State.StatMode, State.StatTarget, have, Collection:StatItem()),
			Buttons = {
				{ Title = "Start", Callback = function()
					statRunning = true
					task.spawn(Collection.StatLoop, Collection, uuid)
				end },
				{ Title = "Cancel", Callback = function() VaderUI.Options.AutoStatReroll:SetValue(false) end },
			},
		})
	end,
})

Tabs.Traits:AddButton({
	Title = "Refresh Unit Lists",
	Callback = function() Collection:RefreshUnitDropdowns() end,
})

--------------------------- [[ Rewards Tab ]] ---------------------------

local ClaimSection = Tabs.Rewards:AddSection("Auto Claim")
local RewardStatus = ClaimSection:AddParagraph({ Title = "Status", Content = "Checks every minute." })
ClaimSection:AddToggle("AutoDaily", {
	Title = "Daily Reward", Default = false,
	Callback = function(value) State.AutoDaily = value end,
})
ClaimSection:AddToggle("AutoBattlePass", {
	Title = "Battle Pass", Default = false,
	Callback = function(value) State.AutoBattlePass = value end,
})
ClaimSection:AddToggle("AutoQuests", {
	Title = "Quests", Default = false,
	Callback = function(value) State.AutoQuests = value end,
})
ClaimSection:AddToggle("AutoMissions", {
	Title = "Missions & Daily Missions", Default = false,
	Callback = function(value) State.AutoMissions = value end,
})
ClaimSection:AddToggle("AutoLevelRewards", {
	Title = "Player Level Rewards", Default = false,
	Callback = function(value) State.AutoLevelRewards = value end,
})

local CodeSection = Tabs.Rewards:AddSection("Codes")
CodeSection:AddInput("Codes", {
	Title = "Codes", Placeholder = "code1, code2, ...", Default = "", Finished = true,
	Callback = function(value) State.Codes = value end,
})
CodeSection:AddButton({
	Title = "Redeem Codes",
	Callback = function()
		local done, failed = {}, {}
		for code in State.Codes:gmatch("[^,%s]+") do
			table.insert(Collection:Invoke("redeem_code", code) and done or failed, code)
		end
		Collection:Notify(string.format("Redeemed: %s\nFailed/used: %s",
			#done > 0 and table.concat(done, ", ") or "-", #failed > 0 and table.concat(failed, ", ") or "-"))
	end,
})

--------------------------- [[ Misc Tab ]] ---------------------------

local Performance = Tabs.Misc:AddSection("Performance")
local LOW_GRAPHICS = { "low_quality", "low_quality_textures", "low_quality_shadows", "disable_effects", "disable_other_fx", "disable_kill_fx" }
Performance:AddToggle("LowGraphics", {
	Title = "Low Graphics (more FPS)", Default = false,
	Description = "Uses the game's own low quality and effect settings.",
	Callback = function(value)
		-- Ignore the initial "off" so the player's own game settings are left alone.
		if not value and not State.LowGraphics then return end
		State.LowGraphics = value
		for _, name in LOW_GRAPHICS do
			local setting = LP._settings:FindFirstChild(name)
			if setting and setting.Value ~= value then Collection:Invoke("toggle_setting", name, value) end
		end
	end,
})

local Privacy = Tabs.Misc:AddSection("Privacy")
local HIDE_FRAMES = { "Name_Frame", "Level_Frame", "Guild_Frame" }
local shownBefore = {} -- overhead frame -> its Visible before we hid it
function Collection:ApplyHideName()
	local head = LP.Character and LP.Character:FindFirstChild("Head")
	local overhead = head and head:FindFirstChild("_overhead")
	local frame = overhead and overhead:FindFirstChild("Frame")
	if not frame then return end
	for _, name in HIDE_FRAMES do
		local f = frame:FindFirstChild(name)
		if f and State.HideName then
			if shownBefore[f] == nil then shownBefore[f] = f.Visible end
			f.Visible = false
		elseif f and shownBefore[f] ~= nil then
			f.Visible = shownBefore[f]
			shownBefore[f] = nil
		end
	end
end
Privacy:AddToggle("HideName", {
	Title = "Hide My Name, Guild & Level", Default = false,
	Description = "Hides them on your overhead, on your screen only. Other players still see them.",
	Callback = function(value)
		State.HideName = value
		Collection:ApplyHideName()
	end,
})

local WebhookSection = Tabs.Misc:AddSection("Discord Webhook")
WebhookSection:AddInput("WebhookUrl", {
	Title = "Webhook URL", Placeholder = "https://discord.com/api/webhooks/...", Default = "", Finished = true,
	Callback = function(value) State.WebhookUrl = value end,
})
WebhookSection:AddDropdown("WebhookSend", {
	Title = "Send", Values = { "Match results", "Rare summons", "Reroll hits" }, Multi = true,
	Default = { "Match results", "Rare summons", "Reroll hits" },
	Callback = function(value) State.WebhookSend = value end,
})
WebhookSection:AddButton({
	Title = "Send Test Message",
	Callback = function()
		if not httpRequest then return Collection:Notify("Your executor has no HTTP request function.") end
		if not State.WebhookUrl:match("^https://") then return Collection:Notify("Paste a webhook URL first.") end
		local send = State.WebhookSend
		State.WebhookSend = { Test = true }
		Collection:Webhook("Test", "Webhook connected", { "Gems: " .. Collection:Gems() })
		State.WebhookSend = send
		Collection:Notify("Test sent.")
	end,
})

-- the joke button: shows the image full screen for 5 seconds, nothing else
local DUPE_IMAGE_URL = "https://raw.githubusercontent.com/DONUT6599/Kneeguardseller/refs/heads/main/bb1.jpeg"
function Collection:ShowDupeImage()
	local getAsset = getcustomasset or getsynasset
	if not (canPersist and getAsset) then return Collection:Notify("Your executor can't show custom images.") end
	local path = profileFolder .. "/bb1.jpeg"
	local ok, data = pcall(game.HttpGet, game, DUPE_IMAGE_URL)
	if ok and data ~= "" then writefile(path, data) end
	if not isfile(path) then return Collection:Notify("Couldn't download the image.") end
	local gui = Collection:Instance("ScreenGui", {
		Name = "VaderDupe", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 1000000, Parent = VaderUI.GUI.Parent,
	})
	Collection:Instance("ImageLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0,
		Image = getAsset(path), ScaleType = Enum.ScaleType.Fit, Parent = gui,
	})
	task.delay(5, function() gui:Destroy() end)
end

local DupeSection = Tabs.Misc:AddSection("Dupe")
DupeSection:AddButton({ Title = "Dupe", Callback = function() Collection:ShowDupeImage() end })

--------------------------- [[ Loops ]] ---------------------------

-- keep the overhead hidden: the game rebuilds it on respawn and may re-show parts of it
task.spawn(function()
	while not closed do
		if State.HideName then Collection:ApplyHideName() end
		task.wait(0.5)
	end
end)

--------------------------- [[ Lobby ]] ---------------------------

-- challenge tracking, auto join
local challengeInfo = Collection:ReadJson(challengePath, {})
function Collection:RefreshChallenge()
	local c = Collection:Invoke("get_normal_challenge")
	if type(c) == "table" and c.current_uuid then
		challengeInfo.uuid = c.current_uuid
		Collection:WriteJson(challengePath, challengeInfo)
	end
	return c
end

function Collection:FreePad(folder)
	for _, pad in folder:GetChildren() do
		local owner, tele, players = pad:FindFirstChild("Owner"), pad:FindFirstChild("Teleporting"), pad:FindFirstChild("Players")
		if owner and owner.Value == nil and tele and not tele.Value and (not players or #players:GetChildren() == 0) then
			return pad
		end
	end
end

function Collection:JoinChallenge()
	local c = Collection:RefreshChallenge()
	if type(c) ~= "table" or c.current_uuid == session.profile_data.last_completed_challenge_uuid then return nil end
	local folder = workspace:FindFirstChild("_CHALLENGES") and workspace._CHALLENGES:FindFirstChild("Challenges")
	for _, pad in folder and folder:GetChildren() or {} do
		local tele, players = pad:FindFirstChild("Teleporting"), pad:FindFirstChild("Players")
		if tele and not tele.Value and (not players or #players:GetChildren() == 0) and Collection:Invoke("request_join_lobby", pad.Name) then
			if not Collection:TeleportDelay("Starting the challenge", function() return State.AutoJoinChallenge end) then
				Collection:Invoke("request_leave_lobby", pad.Name)
				return nil, "Challenge: start cancelled."
			end
			Collection:Invoke("request_start_game", pad.Name)
			return pad, "Joined challenge: " .. tostring(c.current_challenge) .. " on " .. tostring(c.current_level_id)
		end
	end
	return nil, "No free challenge pad"
end

local WEAK_TYPES = { Physical = "physical", Magic = "magic" }

-- the biggest weakness among the picked damage types; 0 when none are picked, nil when none match
function Collection:ContractWeakness(c)
	if next(State.ContractWeakTo) == nil then return 0 end
	local best
	for _, w in c._weak_against or {} do
		for label, id in WEAK_TYPES do
			if State.ContractWeakTo[label] and w.damage_type == id and (not best or w.amplification > best) then
				best = w.amplification
			end
		end
	end
	return best
end

function Collection:DescribeContract(c)
	local weak = {}
	for _, w in c._weak_against or {} do
		local dt = Data.DamageTypes.TYPES[w.damage_type]
		table.insert(weak, string.format("%s %d%%", dt and dt.name or w.damage_type, w.amplification * 100))
	end
	return string.format("%s - Tier %d, weak to %s", (tostring(c.name):gsub("^Contract: ", "")), c._portal_depth or 0,
		#weak > 0 and table.concat(weak, ", ") or "nothing")
end

-- highest-tier open contract that's weak to a picked type; skipSlot leaves out the one just played
function Collection:PickContract(skipSlot)
	local contracts = Collection:Invoke("get_current_event_contracts")
	if type(contracts) ~= "table" then return nil end
	local done = session.profile_data.event_contracts_data or {}
	local bestKey, best
	for key, c in contracts do
		local ec = type(c) == "table" and c._event_contract
		if ec then
			local cleared = done[ec.contract_group] and done[ec.contract_group][ec.slot]
			local completed = cleared and cleared >= ec.interval
			local tier, weak = c._portal_depth or 0, Collection:ContractWeakness(c)
			local tierOk = State.ContractTierMode == "Highest tier" or tier <= State.ContractMaxTier
			if weak and tierOk and ec.slot ~= skipSlot and not (completed and State.SkipCompletedContracts)
				and (not best or tier > best.tier or (tier == best.tier and weak > best.weak)) then
				bestKey, best = key, { contract = c, tier = tier, weak = weak }
			end
		end
	end
	return bestKey, best and best.contract
end

function Collection:JoinContract()
	local key, contract = Collection:PickContract()
	if not key then return nil, "Contract: none open (all completed?)." end
	local created
	local conn = fromServer.portal_lobby_owner_created.OnClientEvent:Connect(function(pad) created = pad end)
	local opened = Collection:Invoke("open_event_contract_portal", key)
	local t0 = os.clock()
	while opened and not created and os.clock() - t0 < 5 do task.wait(0.1) end
	conn:Disconnect()
	if not created then return nil, "Contract: couldn't open a portal." end
	if not Collection:TeleportDelay("Starting the contract", function() return State.AutoContract end) then
		Collection:Invoke("request_leave_lobby", created.Name)
		return nil, "Contract: start cancelled."
	end
	Collection:Invoke("request_start_game", created.Name)
	return created, "Contract: starting " .. tostring(contract.name)
end

function Collection:AnyModeOn()
	for _, on in State.Join do
		if on then return true end
	end
	return false
end

local loadoutLoaded = false
function Collection:JoinStage(mode)
	local label = State.Stage[mode]
	local levelId = label and stages[mode].ids[label]
	if not levelId then return nil, mode .. ": pick a stage." end
	if State.Loadout ~= "Don't change" and not loadoutLoaded then
		loadoutLoaded = true
		Collection:Invoke("load_team_loadout", State.Loadout:match("^Team (%d+)"))
	end
	local pad = Collection:FreePad(mode == "Raid" and workspace._RAID.Raid or workspace._LOBBIES.Story)
	if not pad then return nil, mode .. ": no free pad." end
	if not Collection:Invoke("request_join_lobby", pad.Name) then return nil, mode .. ": couldn't join a pad." end
	if not Collection:Invoke("request_lock_level", pad.Name, levelId, State.FriendsOnly, mode == "Story" and State.Difficulty or "Hard") then
		Collection:Invoke("request_leave_lobby", pad.Name)
		return nil, mode .. ": can't start " .. label .. " (locked or no tries)."
	end
	if not Collection:TeleportDelay("Starting " .. label, function() return State.Join[mode] end) then
		Collection:Invoke("request_leave_lobby", pad.Name)
		return nil, mode .. ": start cancelled."
	end
	Collection:Invoke("request_start_game", pad.Name)
	return pad, "Starting " .. mode .. ": " .. label
end

if IS_LOBBY then
	Collection:RefreshChallenge()
	Collection:Track(fromServer.normal_challenge_remaining_time_changed.OnClientEvent:Connect(function(seconds)
		if type(seconds) == "number" then
			challengeInfo.ends_at = os.time() + seconds
			Collection:WriteJson(challengePath, challengeInfo)
		end
	end))
	task.spawn(function()
		task.wait(5)
		while not closed do
			-- an auto dungeon run (or one about to start) has the lobby to itself
			if (State.AutoJoinChallenge or State.AutoContract or Collection:AnyModeOn()) and not Collection:InPad()
				and not (State.AutoDungeon and (Collection:DungeonData()._started or State.DungeonStart)) then
				local pad, msg
				local notes = {}
				for _, try in {
					{ State.AutoJoinChallenge, Collection.JoinChallenge },
					{ State.AutoContract, Collection.JoinContract },
				} do
					if pad then break end
					if try[1] then
						pad, msg = try[2](Collection)
						if msg then table.insert(notes, msg) end
					end
				end
				for _, mode in JOIN_ORDER do
					if pad then break end
					if State.Join[mode] then
						pad, msg = Collection:JoinStage(mode)
						table.insert(notes, msg)
					end
				end
				if #notes > 0 then
					JoinStatus:SetDesc(table.concat(notes, "\n"))
					eventNote = table.concat(notes, "\n")
					Collection:RefreshEventStatus()
				end
				if pad then
					task.wait(20)
					-- still here: the start didn't go through, free the pad and try again
					if not closed and Collection:InPad() then Collection:Invoke("request_leave_lobby", pad.Name) end
				end
			end
			task.wait(4)
		end
	end)
end

--------------------------- [[ Match ]] ---------------------------

function Collection:MyUnits()
	local list = {}
	for _, m in workspace:FindFirstChild("_UNITS") and workspace._UNITS:GetChildren() or {} do
		local st = m:FindFirstChild("_stats")
		if st and st:FindFirstChild("player") and st.player.Value == LP and st:FindFirstChild("uuid")
			and not CollectionService:HasTag(m, "minion_units") then
			table.insert(list, m)
		end
	end
	return list
end

function Collection:UpgradeCost(m)
	local ok, info, isMax = pcall(Client.GUIService.get_next_upgrade_info, m, Collection:Owned()[m._stats.uuid.Value] or {})
	if ok and info and not isMax then return math.ceil(info.cost * Core.UnitServiceCore.calculate_upgrade_cost_multiplier(m, session)) end
end

--------------------------- [[ Auto Play ]] ---------------------------

local placePending = false -- Auto Place still has units to put down; Place Before Upgrading holds upgrades meanwhile

-- a slot's point: a spot along the first enemy lane, or the position saved for this map and slot
function Collection:PlaceAnchor(slot)
	local cfg = State.Slots[slot]
	if cfg.Mode == "My position" then
		local p = placePositions[tostring(Collection:MapKey()) .. "|" .. slot]
		if not p then return nil, "no spot saved on this map" end
		return Vector3.new(p[1], p[2], p[3]), "saved spot"
	end
	local PathService = Core.PathService
	local base = workspace:FindFirstChild("_BASES") and workspace._BASES:FindFirstChild("pve")
	local lanes = base and PathService.PATH_CACHE and PathService.PATH_CACHE[base]
	if not lanes then return nil, "enemy path not loaded yet" end
	local lane
	for laneFolder in lanes do
		if not (PathService.HIDDEN_MOCK_LANES or {})[laneFolder.Name] and (not lane or laneFolder.Name < lane.Name) then lane = laneFolder end
	end
	if not lane then return nil, "no enemy path on this map" end
	local _, _, position = PathService.get_path_position_by_distance_from_spawn(base, lane, lanes[lane].total_distance * cfg.Percent / 100)
	return position, cfg.Percent .. "% of the path"
end

-- the game lifts a placement by half the unit model's height. Read from the stored template: building a model
-- with get_unit_model runs the unit's setup script on this thread, which strips the executor's permissions.
local unitHalfHeight = {}
function Collection:UnitHalfHeight(unitId)
	if not unitHalfHeight[unitId] then
		local chars, data = Core.UnitServiceCore.unit_chars or {}, Data.Units[unitId] or {}
		local model = chars[unitId] or (data.evolved and chars[data.evolved.from])
		local root = model and (model.PrimaryPart or model:FindFirstChild("HumanoidRootPart"))
		unitHalfHeight[unitId] = root and root.Size.Y / 2 or 1
	end
	return unitHalfHeight[unitId]
end

-- ground (or hill) the game accepts at x, z, off the road and clear of other units' hitboxes (and of reserved
-- { pos, radius } spots, used to lay out holograms); mirrors PlacementCore
local placeRay = RaycastParams.new()
placeRay.FilterType = Enum.RaycastFilterType.Include
local roadOverlap = OverlapParams.new()
roadOverlap.FilterType = Enum.RaycastFilterType.Include
function Collection:PlacementSpot(data, x, y, z, radius, reserved)
	local terrain = workspace:FindFirstChild("_terrain")
	if not terrain then return nil end
	placeRay.FilterDescendantsInstances = { terrain }
	local hit = workspace:Raycast(Vector3.new(x, y + 40, z), Vector3.new(0, -120, 0), placeRay)
	if not hit or hit.Instance.Name == "_donotplace" then return nil end
	local ground, hill = terrain:FindFirstChild("ground"), terrain:FindFirstChild("hill")
	local onGround = ground and hit.Instance:IsDescendantOf(ground)
	local onHill = hill and hit.Instance:IsDescendantOf(hill)
	if data.hill_unit then
		if hill and not onHill then return nil end
	elseif data.hybrid_placement then
		if not (onGround or not hill or onHill) then return nil end
	elseif not onGround then
		return nil
	end
	if workspace:FindFirstChild("_road") then
		roadOverlap.FilterDescendantsInstances = { workspace._road }
		if #workspace:GetPartBoundsInRadius(hit.Position, radius, roadOverlap) > 0 then return nil end
	end
	for _, m in workspace._UNITS:GetChildren() do
		local box = m:FindFirstChild("_hitbox")
		if box and CollectionService:HasTag(m, "player_units")
			and Vector2.new(box.Position.X - hit.Position.X, box.Position.Z - hit.Position.Z).Magnitude < radius + box.Size.Z / 2 then
			return nil
		end
	end
	for _, r in reserved or {} do
		if Vector2.new(r.pos.X - hit.Position.X, r.pos.Z - hit.Position.Z).Magnitude < radius + r.radius then return nil end
	end
	return hit.Position
end

-- points 3 studs apart across the tops of the map's hill parts, nearest to the anchor first
function Collection:HillPoints(anchor)
	local hill = workspace:FindFirstChild("_terrain") and workspace._terrain:FindFirstChild("hill")
	local points = {}
	for _, part in hill and hill:GetDescendants() or {} do
		if part:IsA("BasePart") then
			local size = part.Size
			for x = -size.X / 2 + 1.5, size.X / 2 - 1.5, 3 do
				for z = -size.Z / 2 + 1.5, size.Z / 2 - 1.5, 3 do
					table.insert(points, part.CFrame * Vector3.new(x, size.Y / 2, z))
				end
			end
		end
	end
	table.sort(points, function(a, b) return (a - anchor).Magnitude < (b - anchor).Magnitude end)
	return points
end

-- the nearest free spot around the anchor: rings 3 studs apart, out to 30 studs. Hill units can only stand on hills,
-- so they search the hill parts instead, wherever those are. bad holds spots the server refused
function Collection:FindSpot(data, anchor, bad, reserved)
	local radius = data.override_hitbox_radius or 2
	if data.hill_unit and workspace._terrain:FindFirstChild("hill") then
		for _, p in Collection:HillPoints(anchor) do
			local key = math.floor(p.X) .. "," .. math.floor(p.Z)
			if not bad[key] then
				local spot = Collection:PlacementSpot(data, p.X, p.Y, p.Z, radius, reserved)
				if spot then return spot, key end
			end
		end
		return nil
	end
	for r = 3, 30, 3 do
		local steps = math.max(8, math.floor(2 * math.pi * r / 3))
		for k = 0, steps - 1 do
			local a = 2 * math.pi * k / steps
			local x, z = anchor.X + math.cos(a) * r, anchor.Z + math.sin(a) * r
			local key = math.floor(x) .. "," .. math.floor(z)
			if not bad[key] then
				local spot = Collection:PlacementSpot(data, x, anchor.Y, z, radius, reserved)
				if spot then return spot, key end
			end
		end
	end
end

-- a numbered ball at a slot's point, on this client only
function Collection:PlaceMarker(slot)
	local ball = Collection:Instance("Part", {
		Name = "VaderPlacePoint" .. slot, Shape = Enum.PartType.Ball, Size = Vector3.new(2, 2, 2), Anchored = true,
		CanCollide = false, CanQuery = false, CanTouch = false, Material = Enum.Material.Neon,
		Color = Color3.fromRGB(132, 88, 240), Transparency = 0.25, Parent = workspace,
	})
	local tag = Collection:Instance("BillboardGui", { Size = UDim2.fromOffset(22, 22), StudsOffset = Vector3.new(0, 2, 0), AlwaysOnTop = true, Parent = ball })
	Collection:Instance("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = slot, TextScaled = true, Font = Enum.Font.GothamBold,
		TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0, Parent = tag,
	})
	return ball
end

-- a see-through copy of the unit at a spot it will be placed on, tagged "slot·copy"; on this client only.
-- Clones the stored template, so no unit setup script runs.
local HOLOGRAM_COLOR = Color3.fromRGB(132, 88, 240)
local HOLOGRAM_STRIP = { "Decal", "Texture", "SurfaceAppearance", "Script", "LocalScript", "ModuleScript", "Humanoid",
	"Sound", "ParticleEmitter", "Trail", "Beam", "BillboardGui", "Light" }
function Collection:Hologram(s, spot, copy, parent)
	local chars = Core.UnitServiceCore.unit_chars or {}
	local template = chars[s.u.unit_id] or (s.data.evolved and chars[s.data.evolved.from])
	local half = Collection:UnitHalfHeight(s.u.unit_id)
	local cf = CFrame.lookAt(spot + Vector3.new(0, half, 0), Vector3.new(s.anchor.X, spot.Y + half, s.anchor.Z))
	local holo = template and template:Clone()
	if holo then
		for _, d in holo:GetDescendants() do
			local strip = false
			for _, class in HOLOGRAM_STRIP do
				if d:IsA(class) then strip = true break end
			end
			if strip then
				d:Destroy()
			elseif d:IsA("BasePart") then
				d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch, d.CastShadow = true, false, false, false, false
				d.Material, d.Color = Enum.Material.ForceField, HOLOGRAM_COLOR
				if d:IsA("MeshPart") then pcall(function() d.TextureID = "" end) end
			elseif d:IsA("SpecialMesh") then
				d.TextureId = ""
			end
		end
		holo:PivotTo(cf)
	else
		local radius = s.data.override_hitbox_radius or 2
		holo = Collection:Instance("Part", {
			Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, radius * 2, radius * 2), Anchored = true,
			CanCollide = false, CanQuery = false, CanTouch = false, Material = Enum.Material.ForceField, Color = HOLOGRAM_COLOR,
			CFrame = CFrame.new(spot + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		})
	end
	local tag = Collection:Instance("BillboardGui", {
		Size = UDim2.fromOffset(34, 18), StudsOffsetWorldSpace = Vector3.new(0, 3, 0), AlwaysOnTop = true,
		Adornee = holo:IsA("Model") and (holo.PrimaryPart or holo:FindFirstChildWhichIsA("BasePart")) or holo, Parent = holo,
	})
	Collection:Instance("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = s.slot .. "·" .. copy, TextScaled = true,
		Font = Enum.Font.GothamBold, TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0, Parent = tag,
	})
	holo.Parent = parent
end

-- lays out holograms for every placement still to come, in the order Auto Place will make them
local hologramFolder
function Collection:BuildHolograms(slots, bad, full)
	if hologramFolder then hologramFolder:Destroy() end
	hologramFolder = Collection:Instance("Folder", { Name = "VaderHolograms", Parent = workspace })
	local counts, skip, reserved = {}, {}, {}
	for _, s in slots do counts[s.slot] = s.count end
	for _ = 1, 36 do
		local pick
		for _, s in slots do
			if not full[s.uuid] and not skip[s.slot] and counts[s.slot] < s.cap and (not pick or counts[s.slot] < counts[pick.slot]) then
				pick = s
			end
		end
		if not pick then break end
		local spot = Collection:FindSpot(pick.data, pick.anchor, bad, reserved)
		if spot then
			table.insert(reserved, { pos = spot, radius = pick.data.override_hitbox_radius or 2 })
			counts[pick.slot] += 1
			Collection:Hologram(pick, spot, counts[pick.slot], hologramFolder)
		else
			skip[pick.slot] = true
		end
	end
end

function Collection:ClearHolograms()
	if hologramFolder then hologramFolder:Destroy() end
	hologramFolder = nil
end

-- one placement per tick: the slot with the fewest units down goes next, slot order breaking ties
if not IS_LOBBY then task.spawn(function()
	local markers = {} -- slot -> ball
	local hologramKey -- what the holograms were laid out for; rebuilt when it changes
	local bad, refusals, full = {}, {}, {} -- refused spots, refusals in a row per unit, units at their limit
	-- game code called from here can leave this thread without the executor's permissions; put them back each tick
	local setIdentity = setthreadidentity or set_thread_identity
	local identity = getthreadidentity and getthreadidentity()
	while not closed do
		task.wait(1)
		if setIdentity and identity then pcall(setIdentity, identity) end
		local ok, problem = pcall(function()
			local placed = {}
			for _, m in Collection:MyUnits() do
				placed[m._stats.uuid.Value] = (placed[m._stats.uuid.Value] or 0) + 1
			end
			local equipped = session.profile_data.collection.equipped_units
			local pick, lines, slots = nil, {}, {}
			for _, slot in Data.GameplaySettings.UNIT_SLOTS do
				local cfg = State.Slots[slot]
				local uuid = equipped[slot] or equipped[tonumber(slot)]
				local u = uuid and Collection:Owned()[uuid]
				local data = u and Data.Units[u.unit_id]
				local anchor, where
				if data and cfg.On then anchor, where = Collection:PlaceAnchor(slot) end

				if anchor and State.ShowPlacePoint then
					markers[slot] = markers[slot] or Collection:PlaceMarker(slot)
					markers[slot].Position = anchor + Vector3.new(0, 1, 0)
				elseif markers[slot] then
					markers[slot]:Destroy()
					markers[slot] = nil
				end

				if data and cfg.On then
					local count, cap = placed[uuid] or 0, math.min(cfg.Max, data.spawn_cap or cfg.Max)
					table.insert(lines, string.format("%s %s%s: %d/%d%s", slot, Collection:UnitName(u), Collection:PlacementTag(data), count, cap,
						anchor and (" at " .. where) or (" - " .. where)))
					if anchor then
						table.insert(slots, { slot = slot, uuid = uuid, u = u, data = data, count = count, cap = cap, anchor = anchor })
					end
					if anchor and not full[uuid] and count < cap and (not pick or count < pick.count) then
						pick = { slot = slot, uuid = uuid, u = u, data = data, count = count, anchor = anchor }
					end
				end
			end

			placePending = State.AutoPlace and not State.PlayMacro and pick ~= nil
			local note
			if not State.AutoPlace then
				note = "Auto Place is off."
			elseif State.PlayMacro then
				note = "Paused while Play Macro is on."
			elseif not pick then
				note = "Every slot that's on is placed."
			else
				local name = "slot " .. pick.slot .. " " .. Collection:UnitName(pick.u)
				local cost = math.ceil(session.collection:get_upgraded_unit_data(pick.u.unit_id).cost
					* Core.UnitServiceCore.calculate_spawn_cost_multiplier(session))
				if Collection:Money() < cost then
					note = string.format("Next: %s - waiting for %d¥", name, cost)
				elseif session.collection:is_unit_on_cooldown(pick.uuid) then
					note = "Next: " .. name .. " - on cooldown"
				else
					local spot, key = Collection:FindSpot(pick.data, pick.anchor, bad)
					if not spot then
						full[pick.uuid] = true
						note = pick.data.hill_unit and ("No free hill spot for " .. name .. " - skipping it.")
							or ("No free spot for " .. name .. " within 30 studs of its point - skipping it.")
					else
						local pos = spot + Vector3.new(0, Collection:UnitHalfHeight(pick.u.unit_id), 0)
						if Collection:Invoke("spawn_unit", pick.uuid, CFrame.lookAt(pos, Vector3.new(pick.anchor.X, pos.Y, pick.anchor.Z))) then
							refusals[pick.uuid] = 0
							note = string.format("Placed %s #%d", name, pick.count + 1)
						else
							bad[key] = true
							refusals[pick.uuid] = (refusals[pick.uuid] or 0) + 1
							-- refused at several spots in a row: the unit is at the server's limit
							if refusals[pick.uuid] >= 5 then full[pick.uuid] = true end
							note = string.format("%s was refused at a spot (%d/5)", name, refusals[pick.uuid])
						end
					end
				end
			end
			PlaceStatus:SetDesc(note .. (#lines > 0 and ("\n" .. table.concat(lines, "\n")) or ""))

			if State.ShowHolograms then
				local key, refused = { #CollectionService:GetTagged("player_units") }, 0
				for _ in bad do refused += 1 end
				for _, s in slots do
					table.insert(key, string.format("%s:%d/%d%s@%.0f,%.0f", s.slot, s.count, s.cap, full[s.uuid] and "F" or "", s.anchor.X, s.anchor.Z))
				end
				key = table.concat(key, "|") .. "#" .. refused
				if key ~= hologramKey then
					hologramKey = key
					Collection:BuildHolograms(slots, bad, full)
				end
			elseif hologramKey then
				hologramKey = nil
				Collection:ClearHolograms()
			end
		end)
		if not ok then pcall(PlaceStatus.SetDesc, PlaceStatus, "Auto Place error: " .. tostring(problem)) end
	end
	for _, ball in markers do ball:Destroy() end
	Collection:ClearHolograms()
end) end

local dungeonMatchOver = false -- a dungeon room is only picked after its match ends
if not IS_LOBBY then task.spawn(function()
	while not Loader.LevelData and not closed do task.wait(0.5) end
	if closed then return end
	local matchStart = os.time()
	local startChallenge = (Collection:RefreshChallenge() or {}).current_uuid
	local gameStarted = workspace._DATA.GameStarted
	local soldThisMatch = false

	Collection:Track(fromServer.start_vote_wave_skip.OnClientEvent:Connect(function()
		if State.AutoSkip then Collection:Invoke("vote_wave_skip") end
	end))

	Collection:Track(workspace._wave_num.Changed:Connect(function(wave)
		MatchStatus:SetDesc("Wave " .. tostring(wave) .. "  |  Money " .. tostring(Collection:Money()))
		if State.AutoSell and not soldThisMatch and wave >= State.SellWave then
			soldThisMatch = true
			for _, m in Collection:MyUnits() do Collection:Invoke("sell_unit_ingame", m) end
			Collection:Notify("Sold all units at wave " .. wave)
		end
	end))

	Collection:Track(fromServer.game_finished.OnClientEvent:Connect(function(results)
		dungeonMatchOver = true
		results = type(results) == "table" and results or {}
		Collection:Webhook("Match results", (results.victory and "Victory" or "Defeat") .. " - " .. tostring(Loader.LevelData.name or Loader.LevelData.id), {
			"Wave: " .. tostring(workspace._wave_num.Value),
			"Gems: " .. tostring(results.gem_reward or 0) .. "  Gold: " .. tostring(results.gold_reward or 0) .. "  XP: " .. tostring(results.xp_reward or 0),
			"Total gems: " .. Collection:Gems(),
		})
		task.delay(3, function()
			if closed then return end
			if Loader.LevelData._dungeon and State.AutoDungeon then return end -- the dungeon loop takes it from here
			local contract = Loader.LevelData._event_contract
			if contract and State.AutoContract then
				local _, nextContract = Collection:PickContract(results.victory and contract.slot or nil)
				if nextContract then
					if Collection:TeleportDelay("Voting the next contract", function() return State.AutoContract end) then
						Collection:Invoke("set_game_finished_vote", "eventcontract", { _eventcontractslot = nextContract._event_contract.slot })
					end
					return
				end
			end
			local action = State.EndAction
			if action == "Nothing" or not Collection:TeleportDelay(action, function() return State.EndAction == action end) then return end
			if action == "Replay" then
				Collection:Invoke("set_game_finished_vote", "replay")
			elseif action == "Next Stage" then
				Collection:Invoke("set_game_finished_vote", Loader.LevelData._is_actual_storymode and "next_story" or "replay")
			elseif action == "Lobby" then
				Collection:Invoke("teleport_back_to_lobby")
			end
		end)
	end))

	-- vote start after a countdown, leaving time to place units or cancel
	task.spawn(function()
		local countdown, lastVote = nil, 0
		while not closed and not gameStarted.Value do
			if not State.AutoStart then
				countdown = nil
			else
				countdown = countdown or State.StartDelay
				if countdown > 0 then
					MatchStatus:SetDesc("Auto start in " .. countdown .. "s")
					countdown -= 1
				elseif os.clock() - lastVote > 10 then
					lastVote = os.clock()
					MatchStatus:SetDesc("Voted to start")
					Collection:Invoke("vote_start")
				end
			end
			task.wait(1)
		end
	end)

	-- macro playback
	task.spawn(function()
		local loaded, steps, finished = false, {}, false
		local models, taken = {}, {}
		local i, tries = 1, 0
		local function advance() i, tries = i + 1, 0 end
		local function retry(why)
			tries += 1
			if tries >= 5 then
				MacroStatus:SetDesc(string.format("Step %d/%d skipped: %s", i, #steps, why))
				advance()
			end
		end
		-- the unit a playback spawn produced: same unit, nearest to the recorded spot
		local function spawnedModel(step)
			local pos = Vector3.new(step.cf[1], step.cf[2], step.cf[3])
			local t0 = os.clock()
			repeat
				local best, bestDist
				for _, m in Collection:MyUnits() do
					if not taken[m] and m._stats.uuid.Value == step.uuid then
						local d = (m:GetPivot().Position - pos).Magnitude
						if not bestDist or d < bestDist then best, bestDist = m, d end
					end
				end
				if best then
					taken[best] = true
					return best
				end
				task.wait(0.2)
			until os.clock() - t0 > 3
		end

		while not closed do
			task.wait(0.5)
			-- the macro can still change (picked or auto-switched) until its first step runs
			if i == 1 and Collection:ActiveMacroName() ~= loaded then
				loaded = Collection:ActiveMacroName()
				steps = Collection:LoadMacro(loaded)
				MacroStatus:SetDesc(string.format("%s / %s -> %s", tostring(Collection:CurrentMode()), tostring(Collection:MapKey()),
					loaded and (loaded .. " (" .. Collection:MacroSummary(steps) .. ")") or "no macro"))
			end
			if i > #steps then
				if #steps > 0 and not finished then
					finished = true
					MacroStatus:SetDesc(loaded .. " finished (" .. #steps .. " steps)")
				end
			elseif State.PlayMacro and not State.RecordMacro then
				local step = steps[i]
				local spawnStep = step.type == "spawn" and step or steps[step.unit]
				local u = spawnStep and Collection:Owned()[spawnStep.uuid]
				local m = step.unit and models[step.unit]
				local function status(note)
					MacroStatus:SetDesc(string.format("Step %d/%d: %s %s - %s", i, #steps, step.type, u and Collection:UnitName(u) or "?", note))
				end
				if not u then
					MacroStatus:SetDesc(string.format("Step %d/%d skipped: unit isn't in your collection", i, #steps))
					advance()
				elseif step.type == "spawn" then
					local cost = session.collection:get_upgraded_unit_data(u.unit_id).cost * Core.UnitServiceCore.calculate_spawn_cost_multiplier(session)
					if Collection:Money() < cost then
						status("waiting for " .. math.ceil(cost) .. "¥")
					elseif Collection:Invoke("spawn_unit", step.uuid, CFrame.new(table.unpack(step.cf))) then
						models[i] = spawnedModel(step)
						advance()
					else
						retry("server refused the spawn")
					end
				elseif not (m and m.Parent) then
					MacroStatus:SetDesc(string.format("Step %d/%d skipped: its unit isn't on the map", i, #steps))
					advance()
				elseif step.type == "upgrade" then
					local cost = Collection:UpgradeCost(m)
					if not cost then
						advance()
					elseif Collection:Money() < cost then
						status("waiting for " .. cost .. "¥")
					elseif Collection:Invoke("upgrade_unit_ingame", m) then
						advance()
					else
						retry("server refused the upgrade")
					end
				elseif Collection:Wave() < step.wave then
					status("waiting for wave " .. step.wave)
				else
					Collection:Invoke(step.type == "sell" and "sell_unit_ingame" or "use_active_attack", m)
					advance()
				end
			end
		end
	end)

	-- upgrade, abilities
	task.spawn(function()
		local lastAbility = 0
		while not closed do
			task.wait(1)
			if State.AutoUpgrade and not (State.AutoPlace and State.PlaceBeforeUpgrade and placePending) then
				local best, bestPicked
				for _, m in Collection:MyUnits() do
					local cost = Collection:UpgradeCost(m)
					if cost then
						local u = Collection:Owned()[m._stats.uuid.Value] or {}
						local picked = u.unit_id and State.UpgradeFirst[Collection:UnitName(u)] == true
						if not best or (picked and not bestPicked) or (picked == bestPicked and cost < best.cost) then
							best, bestPicked = { model = m, cost = cost }, picked
						end
					end
				end
				if best and Collection:Money() >= best.cost then Collection:Invoke("upgrade_unit_ingame", best.model) end
			end

			if State.AutoAbility and os.clock() - lastAbility > 3 then
				lastAbility = os.clock()
				for _, m in Collection:MyUnits() do
					local ok, activeId = pcall(Core.UnitServiceCore.get_active_id, m)
					local attack = ok and activeId and Data.Attacks[activeId]
					if attack and not (attack.custom_client_script and attack.custom_client_script.active_start) then
						Collection:Invoke("use_active_attack", m)
					end
				end
			end
		end
	end)

	-- leave when the rotating challenge changes
	task.spawn(function()
		while not closed do
			task.wait(20)
			if State.LeaveOnChallenge and not Loader.LevelData._challenge and not Loader.LevelData._dungeon then
				local c = Collection:Invoke("get_normal_challenge")
				local changed
				if type(c) == "table" and c.current_uuid then
					changed = startChallenge ~= nil and c.current_uuid ~= startChallenge
				else
					-- the match server didn't answer: fall back to the countdown seen in the lobby
					changed = challengeInfo.ends_at ~= nil and challengeInfo.ends_at > matchStart and os.time() >= challengeInfo.ends_at
				end
				if changed then
					Collection:Notify("New challenge - leaving to lobby")
					if Collection:TeleportDelay("Back to the lobby", function() return State.LeaveOnChallenge end) then
						Collection:Invoke("teleport_back_to_lobby")
						return
					end
				end
			end
		end
	end)
end) end

--------------------------- [[ Dungeon ]] ---------------------------

local ROOM_NAMES = {
	[ROOM.TREASURE_GOLD] = "Rare Chest", [ROOM.TREASURE] = "Chest", [ROOM.MONEY] = "Hoard", [ROOM.SHOP] = "Shop",
	[ROOM.SHRINE] = "Shrine", [ROOM.CURSE] = "Curse", [ROOM.OPEN_CHEST] = "Open Chests", [ROOM.BOSS_FINAL] = "Boss",
}

function Collection:RoomScores(room)
	local reward, weak = 0, 0
	local n, m = #State.DungeonRoomOrder, #State.DungeonWeakOrder
	for rank, entry in State.DungeonRoomOrder do
		if room._t and room._t[entry.id] then reward += entry.on and (n - rank + 1) or -n end
	end
	for _, w in room._l and room._l._weak_against or {} do
		for rank, entry in State.DungeonWeakOrder do
			if entry.on and entry.id == w.damage_type then weak += (m - rank + 1) * (w.amplification or 1) end
		end
	end
	return reward, weak
end

function Collection:DescribeRoom(room)
	local tags, weak = {}, {}
	for typeId in room._t or {} do table.insert(tags, ROOM_NAMES[typeId] or typeId) end
	for _, w in room._l and room._l._weak_against or {} do
		local dt = Data.DamageTypes.TYPES[w.damage_type]
		table.insert(weak, string.format("%s %d%%", dt and dt.name or w.damage_type, math.floor((w.amplification or 0) * 100)))
	end
	return string.format("%s [%s] weak: %s", tostring(room._l and (room._l._location_name or room._l.map) or "?"),
		#tags > 0 and table.concat(tags, ", ") or "plain", #weak > 0 and table.concat(weak, ", ") or "-")
end

-- next["1".."3"] are the choices, next["nextN"] the rooms choice N leads to; a room already picked must be replayed
function Collection:PickRoom(dd)
	local picked = dd.selected_next and dd.selected_next.choice_str
	if picked then return picked, dd.next and dd.next[picked] or {} end
	local best, bestKey
	for i = 1, 3 do
		local room = dd.next and dd.next[tostring(i)]
		if room then
			local reward, weak = Collection:RoomScores(room)
			if State.DungeonLookahead then
				local ahead
				for _, after in dd.next["next" .. i] or {} do
					local score = Collection:RoomScores(after)
					ahead = math.max(ahead or score, score)
				end
				reward += (ahead or 0) * 0.5
			end
			local key = State.DungeonPickBy == "Weakness, then rewards" and { weak, reward } or { reward, weak }
			if not bestKey or key[1] > bestKey[1] or (key[1] == bestKey[1] and key[2] > bestKey[2]) then
				best, bestKey = tostring(i), key
			end
		end
	end
	return best, best and dd.next[best]
end

-- the highest item on the list that the shop has and you can afford; prices follow Curse of Shopping
function Collection:PickShopItem(dd, offers, tried)
	local cash = (dd._resources or {}).money or 0
	local mul = math.max(0, Core.DungeonServiceCore.sum_item_values(dd, "shop_prices") + 1)
	for _, entry in State.DungeonShopOrder do
		if entry.on and not tried[entry.id] then
			for index, offer in offers or {} do
				local item = Core.DungeonServiceCore.ITEMS[offer.id]
				local price = item and math.ceil(item.cost * mul)
				if offer.id == entry.id and price and cash >= price then return index, item, price end
			end
		end
	end
end

-- one action per tick, then wait for the server's dungeon_changed so the next tick reads fresh data
-- (buying shifts the shop list, so indexes are never reused)
task.spawn(function()
	local tried, opens, lastEnter, lastStart, lastLeave = {}, 0, 0, 0, 0
	local note = "Idle"
	local function act(name, ...)
		local updated = false
		local conn = fromServer.dungeon_changed.OnClientEvent:Connect(function() updated = true end)
		Collection:Invoke(name, ...)
		local t0 = os.clock()
		while not updated and not closed and os.clock() - t0 < 3 do task.wait(0.1) end
		conn:Disconnect()
		task.wait(0.3) -- let the game's own handler store the new data
	end
	while not closed do
		task.wait(1)
		local dd = Collection:DungeonData()
		local res = dd._resources or {}
		local shop = dd.current_shops and dd.current_shops[1]
		if State.AutoDungeon then
			if dd._dead then
				note = "Died at depth " .. tostring(dd._dead.depth_reached) .. " - continuing"
				act("dungeon_continue_death")
			elseif shop and shop._t == ROOM.SHOP then
				local index, item, price = Collection:PickShopItem(dd, shop.data, tried)
				if index then
					note = string.format("Buying %s for %d", item.name, price)
					act("dungeon_buy_shop", index)
					if (Collection:DungeonData()._resources or {}).money == res.money then tried[item.id] = true end
				else
					note, tried = "Shop: nothing else on the list fits", {}
					act("dungeon_continue_shop")
				end
			elseif shop and shop._t == ROOM.OPEN_CHEST then
				local open = State.DungeonChests == "At every checkpoint" or dd._finished
				opens += 1
				if open and opens <= 60 and (res.treasure or 0) > 0 then
					note = "Opening chests (" .. res.treasure .. " left)"
					act("dungeon_open_chest")
				elseif open and opens <= 60 and (res.treasure_gold or 0) > 0 then
					note = "Opening rare chests (" .. res.treasure_gold .. " left)"
					act("dungeon_open_chest", true)
				else
					note, opens = open and "Chests opened" or "Saving chests for the end", 0
					act("dungeon_continue_shop")
				end
			elseif shop and shop._t == ROOM.SHRINE then
				local cursed = false
				for _, offer in shop.data or {} do
					if offer._t ~= "Item" then cursed = true end
				end
				local accept = State.DungeonShrine == "Accept" or (State.DungeonShrine == "Accept if no curse" and not cursed)
				note = accept and "Shrine: accepted" or "Shrine: denied"
				act(accept and "dungeon_shrine_accept" or "dungeon_continue_shop")
			elseif dd._started and (IS_LOBBY or dungeonMatchOver) and os.clock() - lastEnter > 20 then
				local choice, room = Collection:PickRoom(dd)
				if choice and Collection:TeleportDelay("Entering room " .. choice, function() return State.AutoDungeon end) then
					lastEnter = os.clock()
					note = "Entering room " .. choice .. ": " .. Collection:DescribeRoom(room)
					act("dungeon_enter_room", choice)
				end
			elseif not dd._started and IS_LOBBY and State.DungeonStart and not Collection:InPad() and os.clock() - lastStart > 10 then
				lastStart = os.clock()
				note = "Starting a run"
				act("dungeon_start")
				if not Collection:DungeonData()._started then
					VaderUI.Options.DungeonStart:SetValue(false)
					note = "Couldn't start a run (out of Dungeon Run Keys?)"
					Collection:Notify("Dungeon: " .. note)
				end
			elseif not dd._started and not IS_LOBBY and dungeonMatchOver and Loader.LevelData and Loader.LevelData._dungeon
				and os.clock() - lastLeave > 20 then
				lastLeave = os.clock()
				note = "Run over - back to the lobby"
				if Collection:TeleportDelay(note, function() return State.AutoDungeon end) then
					Collection:Invoke("teleport_back_to_lobby")
				end
			end
		end
		-- preview the pick even with Auto Dungeon off, to check the priorities against real rooms
		local first, choice, room = dd.next and dd.next["1"], nil, nil
		if dd._started and not shop then choice, room = Collection:PickRoom(dd) end
		DungeonStatus:SetDesc(string.format("%s  |  Depth %s/%d  |  Money %d  |  Chests %d + %d rare\n%s%s",
			dd._started and "Run going" or "No run", first and tostring(first._d) or "-", Core.DungeonServiceCore.NUM_ROOMS,
			res.money or 0, res.treasure or 0, res.treasure_gold or 0, note,
			choice and ("\nBest room: " .. choice .. " - " .. Collection:DescribeRoom(room)) or ""))
	end
end)

--------------------------- [[ Event Shop ]] ---------------------------

-- buys, and keeps the event currency in the status fresh
task.spawn(function()
	local failed, ticks = {}, 0
	while not closed do
		-- the contract preview costs a server call, so refresh it every 30 seconds
		if ticks % 6 == 0 then
			local _, c = Collection:PickContract()
			contractPreview = "Next contract: " .. (c and Collection:DescribeContract(c) or "none match your filters")
		end
		ticks += 1
		Collection:RefreshEventStatus()
		task.wait(5)
		if State.AutoEventShop then
			for label in State.EventShopItems do
				local item = eventShopItems[label]
				if item and not failed[label] and Collection:EventResource(item.currency) >= item.cost then
					local before = Collection:EventResource(item.currency)
					Collection:Invoke("buy_item_generic", item.key, "event", "ItemShopEvent", "1")
					task.wait(2)
					if Collection:EventResource(item.currency) < before then
						Collection:Notify("Bought " .. label)
					else
						failed[label] = true -- sold out or one-per-player; stop retrying this session
					end
				end
			end
		end
	end
end)

--------------------------- [[ Summon ]] ---------------------------

-- lobby only
task.spawn(function()
	local spent, pulls, best = 0, 0, {}
	while not closed do
		task.wait(1)
		if State.AutoSummon then
			local function stop(msg)
				VaderUI.Options.AutoSummon:SetValue(false)
				SummonStatus:SetDesc(msg .. string.format("\nPulls: %d  |  Gems spent: %d%s", pulls, spent,
					#best > 0 and ("\nBest: " .. table.concat(best, ", ")) or ""))
				Collection:Notify(msg)
			end
			if not IS_LOBBY then
				stop("Summoning only works in the lobby.")
			else
				local n = State.SummonPay == "Gems x10" and 10 or 1
				local payArg = ({ ["Gems x1"] = "gems", ["Gems x10"] = "gems10", Ticket = "ticket" })[State.SummonPay]
				local banner = Data.Banners[State.Banner] or {}
				local cost = State.SummonPay == "Ticket" and 0 or (banner.gem_cost or 50) * n
				local count, capacity = 0, session.collection.collection_profile_data.capacity
				for _ in Collection:Owned() do count += 1 end
				if Collection:Gems() - cost < State.KeepGems then
					stop("Reached your gem reserve (" .. State.KeepGems .. ").")
				elseif count + n > capacity then
					stop("Unit storage is full (" .. count .. "/" .. capacity .. ").")
				else
					local beforeGems, before = Collection:Gems(), {}
					for uuid in Collection:Owned() do before[uuid] = true end
					Collection:Invoke("buy_from_banner", State.Banner, payArg)
					local t0, changed = os.clock(), false
					repeat
						task.wait(0.25)
						if Collection:Gems() ~= beforeGems then changed = true end
						for uuid in Collection:Owned() do if not before[uuid] then changed = true break end end
					until changed or os.clock() - t0 > 8 or closed
					if not changed then
						stop("Summon didn't go through (banner currency, storage or cooldown).")
					else
						pulls += n
						spent += math.max(beforeGems - Collection:Gems(), 0)
						for uuid, u in Collection:Owned() do
							local rarity = Data.Units[u.unit_id] and Data.Units[u.unit_id].rarity
							if not before[uuid] and (rarity == "Mythic" or rarity == "Secret") then
								table.insert(best, Collection:UnitName(u))
								Collection:Notify("Pulled " .. rarity .. ": " .. Collection:UnitName(u))
								Collection:Webhook("Rare summons", rarity .. " pulled!", { "**" .. Collection:UnitName(u) .. "**", "Banner: " .. State.Banner })
							end
						end
						SummonStatus:SetDesc(string.format("Pulls: %d  |  Gems spent: %d  |  Gems left: %d%s", pulls, spent, Collection:Gems(),
							#best > 0 and ("\nBest: " .. table.concat(best, ", ")) or ""))
						task.wait(1)
					end
				end
			end
		end
	end
end)

--------------------------- [[ Rewards ]] ---------------------------

task.spawn(function()
	while not closed do
		local claimed = {}
		if State.AutoDaily and Collection:Invoke("claim_daily_reward") then table.insert(claimed, "daily") end
		if State.AutoBattlePass and Collection:Invoke("claim_battlepass_rewards") then table.insert(claimed, "battle pass") end
		if State.AutoQuests and session.quest_handler then
			for _, quest in session.quest_handler.quest_profile_data.quests or {} do
				local ok, complete = pcall(Core.QuestClassesCore.is_quest_complete, session, quest)
				if ok and complete and Collection:Invoke("redeem_quest", quest.uuid) then table.insert(claimed, "quest") end
			end
		end
		if State.AutoMissions then
			for _, kind in { { "request_current_missions", "request_claim_mission", "missions_data" },
				{ "request_current_dailymissions", "request_claim_dailymission", "dailymissions_data" } } do
				local done = (session.profile_data[kind[3]] or {}).claimed_missions or {}
				for _, id in Collection:Invoke(kind[1]) or {} do
					if not done[id] and Collection:Invoke(kind[2], id) then table.insert(claimed, "mission") end
				end
			end
		end
		if State.AutoLevelRewards then
			local ok, level = pcall(Core.LevelServiceCore.calculate_level, LP, LP._stats.player_xp.Value)
			for _, reward in Data.PlayerLevelRewards do
				if ok and type(reward) == "table" and reward.level and not session.profile_data.level_rewards_claimed[reward.level]
					and level >= tonumber(reward.level) and Collection:Invoke("claim_player_level_rewards", reward.level) then
					table.insert(claimed, "level " .. reward.level)
				end
			end
		end
		if #claimed > 0 then RewardStatus:SetDesc(os.date("%H:%M") .. " claimed: " .. table.concat(claimed, ", ")) end
		for _ = 1, 60 do
			if closed then return end
			task.wait(1)
		end
	end
end)

--------------------------- [[ Settings ]] ---------------------------

local Settings = Tabs.Settings:AddSection("Theme Settings")
Settings:AddDropdown("Theme", {
	Title = "Theme", Values = VaderUI.Themes, Default = "Dark",
	Callback = function(value)
		VaderUI:SetTheme(value)
		for _, render in priorityLists do render() end
	end,
})
local minimizeKey = Settings:AddKeybind("MinimizeKey", {
	Title = "Show / Hide Key", Default = "RightControl", Mode = "Toggle",
})
VaderUI.MinimizeKeybind = minimizeKey
Settings:AddButton({ Title = "Unload UI", Callback = function() VaderUI:Destroy() end })

local antiAFK = true
local autoSave = true
local profileReady = false
local restoring = false
local lastSaved
local lastError

function Collection:Snapshot()
	local data = { Version = 1, Options = {} }
	for id, option in pairs(VaderUI.Options) do
		if option.SetValue and option.Type ~= "Button" and option.Type ~= "Paragraph" then
			data.Options[id] = { Type = option.Type, Value = option.Value, Mode = option.Mode }
		end
	end
	-- JSON round-trip detaches tables from live dropdown values.
	return HttpService:JSONDecode(HttpService:JSONEncode(data))
end
function Collection:Equal(a, b)
	if type(a) ~= type(b) then return false end
	if type(a) ~= "table" then return a == b end
	for key, value in pairs(a) do if not Collection:Equal(value, b[key]) then return false end end
	for key in pairs(b) do if a[key] == nil then return false end end
	return true
end
function Collection:SaveProfile(force)
	if closed or restoring or not profileReady then return false, "Config storage is unavailable or paused." end
	if not force and not autoSave then return true end
	local ok, result = pcall(function()
		local data = Collection:Snapshot()
		if not force and lastSaved and Collection:Equal(data, lastSaved) then return end
		writefile(profilePath, HttpService:JSONEncode(data))
		lastSaved = data
	end)
	if not ok then
		if tostring(result) ~= lastError then Collection:Notify("Config save failed: " .. tostring(result)) end
		lastError = tostring(result)
		return false, tostring(result)
	end
	lastError = nil
	return true
end
function Collection:LoadProfile()
	if not canPersist then return false, "Required file APIs are unavailable." end
	restoring = true
	local ok, problem = pcall(function()
		if not isfile(profilePath) then return end
		local data = HttpService:JSONDecode(readfile(profilePath))
		assert(type(data) == "table" and data.Version == 1 and type(data.Options) == "table", "Invalid config format")
		local pending = {}
		-- Validate every known value before applying any callbacks.
		for id, saved in pairs(data.Options) do
			local option = VaderUI.Options[id]
			if option then
				assert(type(saved) == "table" and saved.Type == option.Type, "Invalid control: " .. id)
				local value = saved.Value
				if option.Type == "Toggle" then
					assert(type(value) == "boolean", "Invalid toggle: " .. id)
				elseif option.Type == "Slider" then
					assert(type(value) == "number" and value == value and math.abs(value) ~= math.huge, "Invalid slider: " .. id)
					value = math.clamp(value, option.Min, option.Max)
				elseif option.Type == "Input" then
					assert(type(value) == "string", "Invalid input: " .. id)
				elseif option.Type == "Keybind" then
					assert(type(value) == "string" and (value == "None" or Enum.KeyCode[value] ~= nil), "Invalid keybind: " .. id)
					assert(saved.Mode == nil or saved.Mode == "Toggle" or saved.Mode == "Hold" or saved.Mode == "Always", "Invalid keybind mode")
				elseif option.Type == "Priority" then
					assert(type(value) == "table", "Invalid priority list: " .. id)
				elseif option.Type == "Dropdown" then
					if option.Multi then
						assert(type(value) == "table", "Invalid dropdown: " .. id)
					elseif value ~= nil and not table.find(option.Values, value) then
						value = option.Value
					end
				else
					error("Unsupported config control: " .. id)
				end
				-- reroll toggles open a confirm dialog and a resumed recording would overwrite a macro
				if id == "AutoTraitReroll" or id == "AutoStatReroll" or id == "RecordMacro" then value = false end
				table.insert(pending, { Option = option, Value = value, Mode = saved.Mode })
			end
		end
		-- Restore enabling toggles last so callbacks see restored parameters.
		for _, item in ipairs(pending) do
			if item.Option.Type ~= "Toggle" then item.Option:SetValue(item.Value, item.Mode) end
		end
		for _, item in ipairs(pending) do
			if item.Option.Type == "Toggle" then item.Option:SetValue(item.Value) end
		end
	end)
	restoring = false
	profileReady = ok
	if ok then lastSaved = nil end
	return ok, problem
end

local AFK = Tabs.Settings:AddSection("Anti-AFK")
AFK:AddToggle("AntiAFK", {
	Title = "Anti-AFK", Default = true,
	Description = "Prevent idle disconnections while the UI is open.",
	Callback = function(value) antiAFK = value end,
})
Collection:Track(Players.LocalPlayer.Idled:Connect(function()
	if closed or not antiAFK then return end
	pcall(function()
		local virtualUser = game:GetService("VirtualUser")
		virtualUser:CaptureController()
		virtualUser:ClickButton2(Vector2.new())
	end)
end))

local secCommunity = Tabs.Settings:AddSection("Community & Support")
secCommunity:AddParagraph({
	Title = "Vader Script Official Discord",
	Content = "Vader updates, support and community.\nDiscord: https://discord.gg/sghjJ7WyWJ",
})
secCommunity:AddButton({
	Title = "Copy Discord Invite",
	Description = "Copy the Discord invite to your clipboard.",
	Callback = function()
		local copy = setclipboard or toclipboard or (Clipboard and Clipboard.set)
		if type(copy) == "function" then
			local ok = pcall(copy, "https://discord.gg/sghjJ7WyWJ")
			VaderUI:Notify({
				Title = "Vader Script",
				Content = ok and "Discord invite copied to the clipboard." or "Could not copy the invite. Discord: discord.gg/sghjJ7WyWJ",
				Duration = 3,
			})
		else
			VaderUI:Notify({ Title = "Vader Script", Content = "Discord: discord.gg/sghjJ7WyWJ", Duration = 4 })
		end
	end,
})

-- every slider's value doubles as a text box: type a number, then Enter or click away. It goes through the slider's
-- own SetValue, so it's clamped and rounded like a drag, and dragging still updates the box.
function Collection:TypeableSliders()
	for _, option in VaderUI.Options do
		if option.Type == "Slider" and option.Frame then
			for _, label in option.Frame:GetDescendants() do
				if label:IsA("TextLabel") and label.TextXAlignment == Enum.TextXAlignment.Right then
					local box = Collection:Instance("TextBox", {
						Text = label.Text, ClearTextOnFocus = false, Font = label.Font, TextSize = label.TextSize,
						TextColor3 = label.TextColor3, TextXAlignment = Enum.TextXAlignment.Right, BackgroundTransparency = 1,
						AnchorPoint = label.AnchorPoint, Position = label.Position, Size = label.Size, ZIndex = label.ZIndex + 1,
						Parent = label.Parent,
					})
					label.TextTransparency = 1
					label:GetPropertyChangedSignal("Text"):Connect(function()
						if not box:IsFocused() then box.Text = label.Text end
					end)
					label:GetPropertyChangedSignal("TextColor3"):Connect(function() box.TextColor3 = label.TextColor3 end)
					box.FocusLost:Connect(function()
						local value = tonumber(box.Text)
						if value then option:SetValue(value) end
						box.Text = label.Text
					end)
					break
				end
			end
		end
	end
end
Collection:TypeableSliders()

if canPersist then
	local ok, problem = Collection:LoadProfile()
	if ok then Collection:SaveProfile() else Collection:Notify("Config load failed; auto-save paused to preserve the file: " .. tostring(problem)) end
else
	Collection:Notify("Auto-save unavailable: this environment does not provide file APIs.")
end
Collection:Track(Players.PlayerRemoving:Connect(function(player)
	if player == Players.LocalPlayer then Collection:SaveProfile() end
end))
task.spawn(function()
	while not closed and Env.VaderMapStarter == VaderUI do
		task.wait(2)
		if not closed and Env.VaderMapStarter == VaderUI then Collection:SaveProfile() end
	end
end)
Window:SelectTab(1)

return {
	UI = VaderUI, Window = Window, Tabs = Tabs, State = State, Track = function(connection) return Collection:Track(connection) end,
	-- every hub function, for checking the hub from the console
	Collection = Collection,
}
