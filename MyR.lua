-- Anime Adventures hub (VaderUI)
repeat task.wait() until game:IsLoaded()

-- the store's image for 5s before the hub loads (Roblox shows the site's .webp as is); skipped when it can't be shown
pcall(function()
	local getAsset = getcustomasset or getsynasset
	local data = game:HttpGet("https://vaderhug.4tunez.com/uploads/images/vaderhug/products/5837fd697f3e2ad393c7fa29d8dc2f86_1793075859.webp?w=750&q=90")
	if not (getAsset and writefile and makefolder and data ~= "") then return end
	if not isfolder("Vaderhug") then makefolder("Vaderhug") end
	writefile("Vaderhug/store.webp", data)
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn, gui.DisplayOrder = "VaderStore", true, false, 1000000
	-- a square image over a text strip, at most 400 wide and never past 70% of the screen
	local card = Instance.new("Frame")
	card.AnchorPoint, card.Position, card.Size = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.7, 0.7)
	card.BackgroundColor3 = Color3.fromRGB(17, 14, 25)
	card.Parent = gui
	Instance.new("UIAspectRatioConstraint", card).AspectRatio = 0.88
	Instance.new("UISizeConstraint", card).MaxSize = Vector2.new(400, 455)
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
	local stroke = Instance.new("UIStroke", card)
	stroke.Color, stroke.Thickness = Color3.fromRGB(132, 88, 240), 2
	local image = Instance.new("ImageLabel")
	image.Size, image.BackgroundTransparency, image.ScaleType = UDim2.fromScale(1, 0.88), 1, Enum.ScaleType.Fit
	image.Image = getAsset("Vaderhug/store.webp")
	image.Parent = card
	Instance.new("UICorner", image).CornerRadius = UDim.new(0, 10)
	local text = Instance.new("TextLabel")
	text.Position, text.Size, text.BackgroundTransparency = UDim2.fromScale(0.05, 0.88), UDim2.fromScale(0.9, 0.12), 1
	text.Text, text.TextColor3, text.Font, text.TextScaled = "Available At Vaderhug.4tunez.com", Color3.fromRGB(240, 236, 250), Enum.Font.GothamBold, true
	text.Parent = card
	Instance.new("UITextSizeConstraint", text).MaxTextSize = 20
	gui.Parent = gethui and gethui() or game:GetService("CoreGui")
	task.wait(5)
	gui:Destroy()
end)

---------------------------------------------- [ Configs ] ----------------------------------------------

local MAP_NAME = "Anime Adventures"
local VaderUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/DONUT6599/ddgdhdf/refs/heads/main/VaderUI.lua"))()
local Env = (getgenv and getgenv()) or _G

local State = {
	-- lobby
	Join = {}, JoinPriority = {}, Stage = {}, JoinBy = {}, Difficulty = "Normal", FriendsOnly = false,
	AutoJoinChallenge = false, AutoJoinDailyChallenge = false, DailyJoinBy = "Normal", ChallengeJoinBy = "Normal", Loadout = "Don't change", TeleportDelay = 0,
	AutoMansion = false, MansionDifficulty = "Normal",
	AutoPortal = false, Portals = {},
	-- event
	AutoJoinEvent = false, EventJoinBy = "Normal", AutoPickCards = false, CardPriority = {},
	AutoDiscard = false, DiscardSpells = {}, AutoSpells = false, UseSpells = {}, AutoKeepUnits = false, KeepMode = "Keep", KeepUnits = {}, UpgradeOnlyKept = false,
	AutoContract = false, ContractJoinBy = "Normal", ContractWeakTo = { Physical = true, Magic = true }, ContractTierMode = "Highest tier",
	ContractMaxTier = 10, SkipCompletedContracts = true,
	AutoEventShop = false, EventShopItems = {}, AutoMadokaShop = false, MadokaShopItems = {},
	-- dungeon
	AutoDungeon = false, DungeonStart = false, DungeonStopLastLife = false, DungeonChests = "Save for the end", DungeonShrine = "Accept if no curse",
	DungeonPickBy = "Rewards, then weakness", DungeonLookahead = true,
	DungeonRoomOrder = {}, DungeonWeakOrder = {}, DungeonShopOrder = {},
	-- macro
	MacroName = nil, AutoSwitchMacro = false, MacroSlotSpots = false,
	-- match
	LeaveOnChallenge = false, AutoStart = false, StartDelay = 10, AutoSkip = false,
	PlayMacro = false, RecordMacro = false, AutoUpgrade = false, UpgradeUntil = 13, UpgradePriority = {}, UpgradeOrder = "Cheapest first",
	UpgradeCaps = {}, -- unit name -> stop at this upgrade
	AutoAbility = false, AbilityIgnore = {}, LoopBuffs = false, AutoSell = false, SellWave = 20,
	AutoLobby = false, AutoRetry = false, AutoNext = false, AutoNextPortal = false,
	LobbyAtWave = false, LobbyWave = 30, LobbyFallback = false, LobbyFallbackWait = 15,
	-- auto play
	AutoPlace = false, ShowPlacePoint = true, ShowHolograms = true, PlaceBeforeUpgrade = true, FarmsFirst = false, ShowSpots = false,
	PlaceDistance = 50, FarmPlaceDistance = 50,
	Slots = {}, -- slot id -> { On, Mode, Max }
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
	LowGraphics = false, FPSCap = 30, HideName = false, WebhookUrl = "", WebhookSend = { ["Match results"] = true, ["Rare summons"] = true, ["Reroll hits"] = true },
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
	Collection:Elevate()
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
	if not toServer:FindFirstChild(name) then return nil end
	-- through the recorder, so Auto Place / Upgrade / Sell / Ability land in a macro being recorded
	local ok, result = pcall(Collection.RecordingInvoke, name, ...)
	return ok and result or nil
end

-- game code run on a hub thread strips the executor's permissions until the thread next yields, and UI writes
-- need them: put them back before touching the UI
Collection.Identity = getthreadidentity and getthreadidentity()
function Collection:Elevate()
	local set = setthreadidentity or set_thread_identity
	if set and Collection.Identity then pcall(set, Collection.Identity) end
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
-- money units (C.E.O., Bulby): the game gives them a farm_amount
function Collection:IsFarm(unitId) return Data.Units[unitId] ~= nil and Data.Units[unitId].farm_amount ~= nil end
-- a unit by uuid: yours, or one the match lends you (event stages that hand out random units)
function Collection:Unit(uuid) return Collection:Owned()[uuid] or (session.collection.temporary_units or {})[uuid] end
-- this match's team, slot -> uuid. Like the game's get_unit_in_equipped_slot: in events that hand out random units the
-- override is the team even when it's empty (everything placed, waiting for new ones)
function Collection:Equipped()
	return session.override_equipped_units or session.profile_data.collection.equipped_units
end
function Collection:UnitName(u) return (Data.Units[u.unit_id] and Data.Units[u.unit_id].name) or u.unit_id end
function Collection:Gems() return LP._stats.gem_amount.Value end
function Collection:Money() return LP._stats.resource.Value end
function Collection:InPad() return LP:FindFirstChild("AlreadyInLobby") and LP.AlreadyInLobby.Value end
-- the summon reveal waits for a real click (UserInputService.InputBegan) on every unit, and the game's auto-sell only
-- runs after the last one: click through until no reveal has been up for 2s. VirtualUser clicks don't reach InputBegan.
-- Overlapping summons share summon_ui.hatching and the first to finish clears it, so a unit still up (open_particles
-- on the character) or a star intro (star_particles in the camera) counts too
function Collection:SkipSummonReveal()
	local idle = 0
	while idle < 2 and not closed do
		local char, cam = LP.Character, workspace.CurrentCamera
		if Client.GUIService.summon_ui.hatching or (char and char:FindFirstChild("open_particles")) or cam:FindFirstChild("star_particles") then
			idle = 0
			local v = cam.ViewportSize
			Services.VirtualInputManager:SendMouseButtonEvent(v.X / 2, v.Y / 2, 0, true, game, 0)
			Services.VirtualInputManager:SendMouseButtonEvent(v.X / 2, v.Y / 2, 0, false, game, 0)
		else
			idle += 0.25
		end
		task.wait(0.25)
	end
end
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
local macroAssignPath = profileFolder .. "/macro_assignments.json"local challengePath = profileFolder .. "/" .. LP.Name .. "_challenge.json"
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

-- same embed as the Kaitun's
local httpRequest = request or http_request or (syn and syn.request)
local WebhookIcon = "https://github.com/DONUT6599/ddgdhdf/blob/main/Asset_1.png?raw=true"
local WebhookRN = "https://tr.rbxcdn.com/180DAY-ceec97df50507c3436e05dfca16cd467/256/256/Image/png/noFilter"

function Collection:Comma(amount)
	local formatted = tostring(math.floor(tonumber(amount) or 0))
	while true do
		local k
		formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then break end
	end
	return formatted
end

-- your avatar headshot for the embed image, looked up once
function Collection:Avatar()
	if not Collection.AvatarUrl then
		pcall(function()
			local res = httpRequest({ Url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. LP.UserId .. "&size=420x420&format=Png", Method = "GET" })
			Collection.AvatarUrl = HttpService:JSONDecode(res.Body).data[1].imageUrl
		end)
	end
	return Collection.AvatarUrl
end

function Collection:Webhook(kind, title, lines)
	if not State.WebhookSend[kind] or not State.WebhookUrl:match("^https://") or not httpRequest then return end
	task.spawn(pcall, function()
		local avatar = Collection:Avatar()
		httpRequest({
			Url = State.WebhookUrl,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode({
				username = "VaderHug",
				embeds = { {
					title = title,
					description = "Username : " .. LP.Name .. "\n" .. table.concat(lines, "\n"),
					footer = { text = "VaderHug", icon_url = WebhookIcon },
					timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
					image = avatar and { url = WebhookRN } or nil,
					thumbnail = { url = avatar },
				} },
			}),
		})
	end)
end

--------------------------- [[ Macro Recorder ]] ---------------------------

-- wraps the game's own endpoint wrapper so actions done by hand are captured
local MACRO_ACTIONS = { spawn_unit = "spawn", upgrade_unit_ingame = "upgrade", sell_unit_ingame = "sell", use_active_attack = "ability" }
local MACRO_MODES = { "Story", "Infinite", "Legend", "Raid", "Challenge", "Event", "Contract", "Infinity Mansion" }
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
function Collection:LoadMacro(name)
	local steps = name and Collection:ReadJson(Collection:MacroPath(name), {}).steps or {}
	-- older macros saved the recorder's uuid, which no other account has: swap in the unit id and save
	local converted = false
	for _, step in steps do
		local u = step.uuid and Collection:Owned()[step.uuid]
		if u then step.unit_id, step.uuid, converted = u.unit_id, nil, true end
	end
	if converted then Collection:SaveMacro(name, steps) end
	return steps
end
function Collection:SaveMacro(name, steps) Collection:WriteJson(Collection:MacroPath(name), { steps = steps }) end

function Collection:CurrentMode()
	local d = Loader.LevelData
	if not d then return nil end
	if d._event_contract then return "Contract" end
	if d._gamemode == "infinite_tower" then return "Infinity Mansion" end
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

-- your copy of a macro's unit: an equipped one with that unit id, the least placed copy first
function Collection:MacroUnit(unitId)
	local placed = {}
	for _, m in Collection:MyUnits() do placed[m._stats.uuid.Value] = (placed[m._stats.uuid.Value] or 0) + 1 end
	local best
	for _, uuid in Collection:Equipped() do
		local u = Collection:Unit(uuid)
		if u and u.unit_id == unitId and (not best or (placed[uuid] or 0) < (placed[best] or 0)) then best = uuid end
	end
	return best
end

-- which recorded spawn a unit model came from: same unit, closest to where it was placed
function Collection:SpawnIndexOf(steps, model)
	local st = typeof(model) == "Instance" and model:FindFirstChild("_stats")
	local u = st and st:FindFirstChild("uuid") and Collection:Unit(st.uuid.Value)
	if not u then return nil end
	local pos, best, bestDist = model:GetPivot().Position, nil, math.huge
	for i, step in steps do
		if step.type == "spawn" and step.unit_id == u.unit_id then
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

-- Astral Summon puts a unit into the slot it was cast from; Auto Keep / Discard Units never discards that one
Collection.SummonCast = {} -- slot -> when Astral Summon was cast from it
Collection.Summoned = {} -- uuid -> true for units Astral Summon put on the bar

-- a plain function (no self): it stands in for the game's EndpointsClient.invoke_server
function Collection.RecordingInvoke(name, ...)
	local slot = (...)
	if name == "use_ingame_spell" and (session.ingame_spells or {})[slot] == "summon" then Collection.SummonCast[tostring(slot)] = os.clock() end
	local action = State.RecordMacro and recording and Collection:MapKey() and MACRO_ACTIONS[name]
	local step
	if action == "spawn" then
		local uuid, cf = ...
		local u = Collection:Unit(uuid)
		step = u and { type = action, wave = Collection:Wave(), unit_id = u.unit_id, cf = { cf:GetComponents() } }
	elseif action and not (action == "ability" and Collection:IsBuffUnit((...))) then -- buff units are Loop Buffs' job
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
	State.DeleteEnemies = false
	pcall(Collection.ShowEnemies, Collection)
	State.DeleteMap = false
	pcall(Collection.ApplyDeleteMap, Collection)
	State.BoostFPS = false
	if State.WhiteScreen then pcall(Services.RunService.Set3dRenderingEnabled, Services.RunService, true) end
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

-- Madoka shop: picked by item name. The server sends the day's stock, so the known items are always listed: a pick
-- outside the list would be dropped by a config save in a match, where the shop may not be loaded
local function itemName(id) return Data.Items[id] and Data.Items[id].name or id end
local madokaShopValues = {}
for _, id in { "star_remnant_limited", "StarFruitCapsule", "dungeon_key" } do table.insert(madokaShopValues, itemName(id)) end
pcall(function()
	for _, entry in Client.MadokaShopServiceClient.shop_items_for_sale or {} do
		if not table.find(madokaShopValues, itemName(entry.id)) then table.insert(madokaShopValues, itemName(entry.id)) end
	end
end)

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

-- A box plus Import / Export buttons for these controls. Export copies them in the config file's format, so a whole
-- config pasted into the box imports too (only these controls are taken from it).
function Collection:AddShare(section, id, label, ids)
	local only = {}
	for _, k in ids do only[k] = true end
	section:AddInput(id, { Title = label .. " JSON", Placeholder = "Paste what Export copied", Default = "", Finished = false })
	section:AddButton({
		Title = "Import " .. label,
		Callback = function()
			local ok, problem = pcall(function()
				local data = HttpService:JSONDecode(VaderUI.Options[id].Value)
				assert(type(data) == "table" and type(data.Options) == "table", "That isn't an export.")
				assert(Collection:ApplyOptions(data.Options, only) > 0, "Nothing for " .. label .. " in it.")
			end)
			Collection:Notify(ok and ("Imported " .. label .. ".") or ("Import failed: " .. tostring(problem):gsub("^.-:%d+: ", "")))
		end,
	})
	section:AddButton({
		Title = "Export " .. label,
		Description = "Copies JSON to clipboard.",
		Callback = function()
			local all, out = Collection:Snapshot().Options, { Version = 1, Options = {} }
			for _, k in ids do out.Options[k] = all[k] end
			local copy = setclipboard or toclipboard or (Clipboard and Clipboard.set)
			if type(copy) ~= "function" or not pcall(copy, HttpService:JSONEncode(out)) then
				return Collection:Notify("Couldn't copy to the clipboard.")
			end
			Collection:Notify("Copied " .. label .. " settings.")
		end,
	})
end

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
		for i, entry in default do
			if not seen[entry.id] then table.insert(merged, math.min(i, #merged + 1), { id = entry.id, on = entry.on }) end
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
	Ability = Window:AddTab({ Title = "Ability" }),
	Macro = Window:AddTab({ Title = "Macro" }),
	Summon = Window:AddTab({ Title = "Summon" }),
	Traits = Window:AddTab({ Title = "Traits & Stats" }),
	Rewards = Window:AddTab({ Title = "Rewards" }),
	Misc = Window:AddTab({ Title = "Misc" }),
	Settings = Window:AddTab({ Title = "Settings" }),
}

-- VaderUI sizes these canvases from a changed signal that errors (lacking capability Plugin) once a hub thread has
-- called game code, which left the pages with nothing to scroll; let the engine size them instead
Collection:Elevate()
for _, tab in Tabs do tab.Page.AutomaticCanvasSize = Enum.AutomaticSize.Y end
VaderUI.GUI.Window.Main.Tabs.AutomaticCanvasSize = Enum.AutomaticSize.Y

--------------------------- [[ Main Tab ]] ---------------------------

local JoinSection = Tabs.Main:AddSection("Auto Join")
local JoinStatus = JoinSection:AddParagraph({
	Title = "Status",
	Content = IS_LOBBY and "Idle." or "In a match - joining runs in the lobby.",
})
JoinSection:AddToggle("FriendsOnly", {
	Title = "Friends Only", Default = false,
	Callback = function(value) State.FriendsOnly = value end,
})
JoinSection:AddDropdown("Loadout", {
	Title = "Team Loadout", Values = loadoutValues, Default = "Don't change", Multi = false,
	Description = "Set before joining.",
	Callback = function(value) State.Loadout = value end,
})
JoinSection:AddSlider("TeleportDelay", {
	Title = "Teleport Delay (seconds)", Default = 0, Min = 0, Max = 60, Rounding = 0,
	Description = "Wait before any teleport.",
	Callback = function(value) State.TeleportDelay = value end,
})
-- ids are the keys of the join loop's tries
Collection:AddPriorityList(JoinSection, "JoinPriority", {
	Title = "Join Priority",
	Description = "Top first. Unticked = skipped.",
	Rows = 11,
	Entries = {
		{ id = "Dungeon", label = "Dungeon Run" },
		{ id = "DailyChallenge", label = "Daily Challenge" },
		{ id = "Challenge", label = "Challenge" },
		{ id = "Contract", label = "Contract" },
		{ id = "Portal", label = "Portal" },
		{ id = "Event", label = "Event Stage" },
		{ id = "Mansion", label = "Infinity Mansion" },
		{ id = "Raid", label = "Raid" },
		{ id = "Legend", label = "Legend" },
		{ id = "Story", label = "Story" },
		{ id = "Infinite", label = "Infinite" },
	},
	Callback = function(value) State.JoinPriority = value end,
})

local MODE_INFO = {
	Story = "Story acts.",
	Infinite = "Always Hard.",
	Legend = "Always Hard.",
	Raid = "Always Hard. Skips if no tries.",
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
	section:AddDropdown(mode .. "JoinBy", {
		Title = "Join By", Values = { "Normal", "Matchmaking" }, Default = "Normal", Multi = false,
		Description = "Matchmaking only where the game offers it, else solo.",
		Callback = function(value) State.JoinBy[mode] = value end,
	})
	if mode == "Story" then
		section:AddDropdown("Difficulty", {
			Title = "Difficulty", Values = { "Normal", "Hard" }, Default = "Normal", Multi = false,
			Callback = function(value) State.Difficulty = value end,
		})
	end
end

local ChallengeSection = Tabs.Main:AddSection("Challenge")
ChallengeSection:AddToggle("AutoJoinDailyChallenge", {
	Title = "Auto Join Daily Challenge", Default = false,
	Description = "Joins the daily challenge once per reset.",
	Callback = function(value) State.AutoJoinDailyChallenge = value end,
})
ChallengeSection:AddDropdown("DailyJoinBy", {
	Title = "Daily Join By", Values = { "Normal", "Matchmaking" }, Default = "Normal", Multi = false,
	Description = "Normal = solo. Matchmaking = queue.",
	Callback = function(value) State.DailyJoinBy = value end,
})
ChallengeSection:AddToggle("AutoJoinChallenge", {
	Title = "Auto Join Challenge", Default = false,
	Description = "Joins the challenge if not cleared.",
	Callback = function(value) State.AutoJoinChallenge = value end,
})
ChallengeSection:AddDropdown("ChallengeJoinBy", {
	Title = "Challenge Join By", Values = { "Normal", "Matchmaking" }, Default = "Normal", Multi = false,
	Description = "Normal = solo. Matchmaking = queue.",
	Callback = function(value) State.ChallengeJoinBy = value end,
})
ChallengeSection:AddToggle("LeaveOnChallenge", {
	Title = "Leave When Challenge Changes", Default = false,
	Description = "Leaves when a new challenge starts.",
	Callback = function(value) State.LeaveOnChallenge = value end,
})

local MansionSection = Tabs.Main:AddSection("Infinity Mansion")
MansionSection:AddToggle("AutoMansion", {
	Title = "Auto Join Infinity Mansion", Default = false,
	Description = "Next uncleared room, then Next Room / Retry.",
	Callback = function(value) State.AutoMansion = value end,
})
MansionSection:AddDropdown("MansionDifficulty", {
	Title = "Difficulty", Values = { "Normal", "Hard" }, Default = "Normal", Multi = false,
	Description = "Hard needs room 100 last season.",
	Callback = function(value) State.MansionDifficulty = value end,
})

do
	-- every portal item in the game by name; some share one (the four Devil Portals)
	local portalNames = {}
	for _, item in Data.Items do
		if type(item) == "table" and item.usage and item.usage.type == "open_portal" and not table.find(portalNames, item.name) then
			table.insert(portalNames, item.name)
		end
	end
	table.sort(portalNames)
	local PortalSection = Tabs.Main:AddSection("Portal")
	PortalSection:AddToggle("AutoPortal", {
		Title = "Auto Join Portal", Default = false,
		Description = "Opens a picked portal from your inventory.",
		Callback = function(value) State.AutoPortal = value end,
	})
	PortalSection:AddDropdown("Portals", {
		Title = "Portals", Values = portalNames, Multi = true, Default = {},
		Description = "April Fools = Demon Academy Portal.",
		Callback = function(value) State.Portals = value end,
	})
end

--------------------------- [[ Event Tab ]] ---------------------------

local eventNote, contractPreview = "Idle", "Next contract: checking..."
local EventStatus = Tabs.Event:AddParagraph({ Title = "Status", Content = "-" })
function Collection:RefreshEventStatus()
	local res = Data.GameplaySettings.CURRENT_EVENT_RESOURCE
	EventStatus:SetDesc(string.format("%s: %d\n%s\n%s", tostring(res), Collection:EventResource(res), contractPreview, eventNote))
end
Collection:RefreshEventStatus()

local EventStageSection = Tabs.Event:AddSection("Event Stage")
EventStageSection:AddToggle("AutoJoinEvent", {
	Title = "Auto Join", Default = false,
	Description = "Joins the event stage.",
	Callback = function(value) State.AutoJoinEvent = value end,
})
EventStageSection:AddDropdown("EventJoinBy", {
	Title = "Join By", Values = { "Normal", "Matchmaking" }, Default = "Normal", Multi = false,
	Description = "Normal = solo. Matchmaking = queue.",
	Callback = function(value) State.EventJoinBy = value end,
})

-- ids are what Collection:CardKind gives a card; the game only reveals cards when it offers them, so kinds, not titles
local CardSection = Tabs.Event:AddSection("Event Cards")
CardSection:AddToggle("AutoPickCards", {
	Title = "Auto Pick Cards", Default = false,
	Description = "Votes by Card Priority.",
	Callback = function(value) State.AutoPickCards = value end,
})
Collection:AddPriorityList(CardSection, "CardPriority", {
	Title = "Card Priority",
	Description = "Top first. Unticked = never.",
	Rows = 8,
	Entries = {
		{ id = "stat:damage", label = "Attack" },
		{ id = "stat:attack_cooldown", label = "Attack Speed" },
		{ id = "stat:range", label = "Range" },
		{ id = "boss_damage", label = "Boss Damage" },
		{ id = "stat:active_attack_cooldown", label = "Ability Cooldown" },
		{ id = "resource_gain", label = "Yen", desc = "¥ now" },
		{ id = "random_blessings", label = "Random Blessings" },
		{ id = "secret_drop", label = "Secret Drop Rate" },
		{ id = "candy_multiplier", label = "Event Currency" },
		{ id = "enemy_stat_mul:health", label = "Enemy Health", desc = "curse" },
		{ id = "enemy_resistance_specific:all", label = "Resistant Enemies", desc = "curse: resist all damage" },
		{ id = "enemy_resistance_specific:physical", label = "Plated Enemies", desc = "curse: resist physical" },
		{ id = "enemy_resistance_specific:magic", label = "Spellproof Enemies", desc = "curse: resist magic" },
		{ id = "enemy_regen", label = "Enemy Regen", desc = "curse" },
		{ id = "enemy_shield", label = "Enemy Shield", desc = "curse" },
		{ id = "enemy_passive_chance", label = "Enemy Passives", desc = "curse" },
		{ id = "enemy_bomb", label = "Explosive Deaths", desc = "curse" },
		{ id = "enemy_speedup", label = "Enemy Speed", desc = "curse" },
		{ id = "unit_cost", label = "Unit Cost", desc = "curse" },
		{ id = "random_curses", label = "Random Curses", desc = "curse" },
		{ id = "new_path", label = "New Path", desc = "curse: an extra enemy lane" },
	},
	Callback = function(value) State.CardPriority = value end,
})
Collection:AddShare(CardSection, "CardShare", "Card Priority", { "CardPriority" })

-- events that hand out random units (April Fools' Fool's Hunt): the pool is server-side, so every unit is offered
do
	local unitNames = {}
	for _, unit in Data.Units do
		if type(unit) == "table" and unit.rarity and unit.name and not table.find(unitNames, unit.name) then table.insert(unitNames, unit.name) end
	end
	table.sort(unitNames)
	local KeepSection = Tabs.Event:AddSection("Event Units")
	KeepSection:AddToggle("AutoKeepUnits", {
		Title = "Auto Keep / Discard Units", Default = false,
		Description = "Filters handed-out units. Astral Summon's are always kept.",
		Callback = function(value) State.AutoKeepUnits = value end,
	})
	KeepSection:AddDropdown("KeepMode", {
		Title = "Mode", Values = { "Keep", "Discard" }, Default = "Keep", Multi = false,
		Description = "Keep = discard everything not picked. Discard = discard the picked ones.",
		Callback = function(value) State.KeepMode = value end,
	})
	KeepSection:AddDropdown("KeepUnits", {
		Title = "Units", Values = unitNames, Multi = true, Default = {},
		Description = "Nothing picked = nothing discarded.",
		Callback = function(value) State.KeepUnits = value end,
	})
	KeepSection:AddToggle("UpgradeOnlyKept", {
		Title = "Upgrade Only Kept", Default = false,
		Description = "Auto Upgrade skips units the list doesn't keep.",
		Callback = function(value) State.UpgradeOnlyKept = value end,
	})
end

-- events that hand out random units also hand out spells, each with an X that swaps it for something new
local spellNames = {}
for _, spell in Data.IngameSpells or {} do table.insert(spellNames, spell.name) end
table.sort(spellNames)
local SpellSection = Tabs.Event:AddSection("Event Spells")
SpellSection:AddToggle("AutoDiscard", {
	Title = "Auto Discard", Default = false,
	Description = "Discards picked spells.",
	Callback = function(value) State.AutoDiscard = value end,
})
SpellSection:AddDropdown("DiscardSpells", {
	Title = "Discard Spells", Values = spellNames, Multi = true, Default = {},
	Description = "Unpicked spells are kept.",
	Callback = function(value) State.DiscardSpells = value end,
})
SpellSection:AddToggle("AutoSpells", {
	Title = "Auto Use Spells", Default = false,
	Description = "Casts picked spells when their rule finds a target.",
	Callback = function(value) State.AutoSpells = value end,
})
do
	-- Refund has no safe automatic rule, so it isn't offered
	local useSpellNames = {}
	for _, name in spellNames do if name ~= "Refund" then table.insert(useSpellNames, name) end end
	SpellSection:AddDropdown("UseSpells", {
		Title = "Use Spells", Values = useSpellNames, Multi = true, Default = {},
		Callback = function(value) State.UseSpells = value end,
	})
	SpellSection:AddParagraph({
		Title = "Spell Rules",
		Content = "Merge : Fully upgraded unit with a non-upgraded copy of the same unit in its range.\n"
			.. "Clone / Random Buff / Ritual : Your strongest fully upgraded unit.\n"
			.. "Astral Gate / Astral Summon : Cast right away.",
	})
end

local ContractSection = Tabs.Event:AddSection("Event Contracts")
ContractSection:AddToggle("AutoContract", {
	Title = "Auto Contract", Default = false,
	Description = "Starts and votes contracts.",
	Callback = function(value) State.AutoContract = value end,
})
ContractSection:AddDropdown("ContractJoinBy", {
	Title = "Join By", Values = { "Normal", "Matchmaking" }, Default = "Normal", Multi = false,
	Description = "Normal = open a portal. Matchmaking = queue.",
	Callback = function(value) State.ContractJoinBy = value end,
})
ContractSection:AddDropdown("ContractWeakTo", {
	Title = "Weak To", Values = { "Physical", "Magic" }, Multi = true, Default = { "Physical", "Magic" },
	Description = "None picked = any.",
	Callback = function(value) State.ContractWeakTo = value end,
})
ContractSection:AddDropdown("ContractTierMode", {
	Title = "Tier", Values = { "Highest tier", "Highest up to Max Tier" }, Default = "Highest tier", Multi = false,
	Callback = function(value) State.ContractTierMode = value end,
})
ContractSection:AddSlider("ContractMaxTier", {
	Title = "Max Tier", Min = 1, Max = 30, Default = 10, Rounding = 0,
	Description = "For Highest up to Max Tier.",
	Callback = function(value) State.ContractMaxTier = value end,
})
ContractSection:AddToggle("SkipCompletedContracts", {
	Title = "Skip Completed Contracts", Default = true,
	Description = "No rewards until it rotates.",
	Callback = function(value) State.SkipCompletedContracts = value end,
})

local EventShopSection = Tabs.Event:AddSection("Event Shop")
EventShopSection:AddDropdown("EventShopItems", {
	Title = "Items", Values = eventShopValues, Multi = true, Default = {},
	Callback = function(value) State.EventShopItems = value end,
})
EventShopSection:AddToggle("AutoEventShop", {
	Title = "Auto Buy", Default = false,
	Description = "Buys picked items when affordable.",
	Callback = function(value) State.AutoEventShop = value end,
})

local MadokaShopSection = Tabs.Event:AddSection("Madoka Shop")
MadokaShopSection:AddDropdown("MadokaShopItems", {
	Title = "Items", Values = madokaShopValues, Multi = true, Default = {},
	Callback = function(value) State.MadokaShopItems = value end,
})
MadokaShopSection:AddToggle("AutoMadokaShop", {
	Title = "Auto Buy", Default = false,
	Description = "Buys picked items while in stock.",
	Callback = function(value) State.AutoMadokaShop = value end,
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
	Description = "Runs the whole dungeon.",
	Callback = function(value) State.AutoDungeon = value end,
})
DungeonSection:AddToggle("DungeonStart", {
	Title = "Auto Start Run", Default = false,
	Description = "Starts a run with a key.",
	Callback = function(value) State.DungeonStart = value end,
})
DungeonSection:AddToggle("DungeonStopLastLife", {
	Title = "Stop At Last Life", Default = false,
	Description = "1 heart left on a room: stops, so you retry it yourself.",
	Callback = function(value) State.DungeonStopLastLife = value end,
})
DungeonSection:AddDropdown("DungeonChests", {
	Title = "Open Chests", Values = { "Save for the end", "At every checkpoint" }, Default = "Save for the end", Multi = false,
	Description = "After the boss: Secret unit chance.",
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
	Description = "Counts rooms one step ahead.",
	Callback = function(value) State.DungeonLookahead = value end,
})
Collection:AddPriorityList(RoomSection, "DungeonRoomOrder", {
	Title = "Rewards", Entries = roomEntries, Rows = #roomEntries,
	Description = "Higher = wanted more. Off = avoided.",
	Callback = function(value) State.DungeonRoomOrder = value end,
})
Collection:AddPriorityList(RoomSection, "DungeonWeakOrder", {
	Title = "Weak Against", Entries = weakEntries, Rows = #weakEntries,
	Description = "Prefers enemies weak to these.",
	Callback = function(value) State.DungeonWeakOrder = value end,
})

local DungeonShopSection = Tabs.Dungeon:AddSection("Shop Priority")
Collection:AddPriorityList(DungeonShopSection, "DungeonShopOrder", {
	Title = "Items", Entries = shopEntries,
	Description = "Top first. Off = never.",
	Callback = function(value) State.DungeonShopOrder = value end,
})
Collection:AddShare(Tabs.Dungeon:AddSection("Share"), "DungeonShare", "Dungeon", {
	"DungeonStopLastLife", "DungeonChests", "DungeonShrine", "DungeonPickBy", "DungeonLookahead",
	"DungeonRoomOrder", "DungeonWeakOrder", "DungeonShopOrder",
})

--------------------------- [[ Match Tab ]] ---------------------------

local MatchSection = Tabs.Match:AddSection("Match")
local MatchStatus = MatchSection:AddParagraph({ Title = "Status", Content = IS_LOBBY and "In the lobby." or "Waiting..." })
MatchSection:AddToggle("AutoStart", {
	Title = "Auto Vote Start", Default = false,
	Description = "Votes start after Start Delay.",
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
MatchSection:AddToggle("AutoNextPortal", {
	Title = "Auto Next Portal", Default = false,
	Description = "Portals, host only. A picked portal first, else any that fits.",
	Callback = function(value) State.AutoNextPortal = value end,
})
MatchSection:AddToggle("AutoNext", {
	Title = "Auto Next", Default = false,
	Description = "Story wins: the next stage.",
	Callback = function(value) State.AutoNext = value end,
})
MatchSection:AddToggle("AutoRetry", {
	Title = "Auto Retry", Default = false,
	Callback = function(value) State.AutoRetry = value end,
})
MatchSection:AddToggle("AutoLobby", {
	Title = "Auto Return To Lobby", Default = false,
	Description = "When none of the above applies.",
	Callback = function(value) State.AutoLobby = value end,
})

-- a portal in your inventory the results screen's Pick Next Portal takes: a picked one (Portals) first, else any
function Collection:ReplayPortal()
	local any
	for _, it in session.inventory.inventory_profile_data.unique_items do
		local ok, valid = pcall(function() return Core.LevelServiceCore.is_valid_replay_portal_item(session, it.uuid) end)
		if ok and valid then
			local item = Data.Items[it.item_id]
			if item and State.Portals[item.name] then return it.uuid end
			any = any or it.uuid
		end
	end
	return any
end
-- what the results screen does next, the first that applies, by the game's own button rules: Next Portal (the host
-- on a portal), Next (a story win with a next stage), Retry (not on a portal), Return To Lobby. Its label and the call
function Collection:EndAction(victory)
	local level = Loader.LevelData
	if level._is_map_or_portal_level then
		local portal = State.AutoNextPortal and level._owner_player_userid == LP.UserId and Collection:ReplayPortal()
		if portal then
			return "Next portal", function() Collection:Invoke("set_game_finished_vote", "replay", { item_uuid = portal }) end
		end
	-- can't read the stage order: try Next anyway, like the old build did
	elseif State.AutoNext and victory and level._is_actual_storymode
		and select(2, pcall(function() return Core.ProgressionServiceCore.get_next_story_level(level.id) end)) then
		return "Next stage", function() Collection:Invoke("set_game_finished_vote", "next_story") end
	elseif State.AutoRetry then
		return "Retry", function() Collection:Invoke("set_game_finished_vote", "replay") end
	end
	if State.AutoLobby then return "Back to the lobby", function() Collection:Invoke("teleport_back_to_lobby") end end
end

local SellSection = Tabs.Match:AddSection("Sell")
SellSection:AddToggle("AutoSell", {
	Title = "Auto Sell Units At Wave", Default = false,
	Callback = function(value) State.AutoSell = value end,
})
SellSection:AddSlider("SellWave", {
	Title = "Sell At Wave", Default = 20, Min = 1, Max = 200, Rounding = 0,
	Callback = function(value) State.SellWave = value end,
})

local LeaveSection = Tabs.Match:AddSection("Leave")
LeaveSection:AddToggle("LobbyAtWave", {
	Title = "Teleport To Lobby At Wave", Default = false,
	Description = "Leaves at the wave below.",
	Callback = function(value) State.LobbyAtWave = value end,
})
LeaveSection:AddSlider("LobbyWave", {
	Title = "Lobby At Wave", Default = 30, Min = 1, Max = 200, Rounding = 0,
	Callback = function(value) State.LobbyWave = value end,
})
LeaveSection:AddToggle("LobbyFallback", {
	Title = "Lobby Fallback", Default = false,
	Description = "Stuck on the Victory/Defeat screen: teleports to the lobby.",
	Callback = function(value) State.LobbyFallback = value end,
})
LeaveSection:AddSlider("LobbyFallbackWait", {
	Title = "Fallback After (seconds)", Default = 15, Min = 10, Max = 60, Rounding = 0,
	Callback = function(value) State.LobbyFallbackWait = value end,
})

--------------------------- [[ Auto Play Tab ]] ---------------------------

local PlaceSection = Tabs.AutoPlay:AddSection("Auto Place")
local PlaceStatus = PlaceSection:AddParagraph({ Title = "Status", Content = IS_LOBBY and "In the lobby." or "Waiting..." })
PlaceSection:AddToggle("AutoPlace", {
	Title = "Auto Place", Default = false,
	Description = "Places each slot at its point. Stops at 20 units in events.",
	Callback = function(value) State.AutoPlace = value end,
})
PlaceSection:AddToggle("FarmsFirst", {
	Title = "Farms First", Default = false,
	Description = "Money units first.",
	Callback = function(value) State.FarmsFirst = value end,
})
PlaceSection:AddSlider("PlaceDistance", {
	Title = "Placement Distance %", Default = 50, Min = 0, Max = 100, Rounding = 0,
	Description = "0 = enemy spawn, 100 = your base.",
	Callback = function(value) State.PlaceDistance = value end,
})
PlaceSection:AddSlider("FarmPlaceDistance", {
	Title = "Farm Placement Distance %", Default = 50, Min = 0, Max = 100, Rounding = 0,
	Description = "Same, for money units.",
	Callback = function(value) State.FarmPlaceDistance = value end,
})
PlaceSection:AddToggle("ShowHolograms", {
	Title = "Show Holograms", Default = true,
	Description = "Shows planned spots.",
	Callback = function(value) State.ShowHolograms = value end,
})
PlaceSection:AddToggle("ShowPlacePoint", {
	Title = "Show Placement Points", Default = true,
	Description = "Ball at each slot's point.",
	Callback = function(value) State.ShowPlacePoint = value end,
})
PlaceSection:AddToggle("ShowSpots", {
	Title = "Show Valid Spots", Default = false,
	Description = "Dots where units can stand.",
	Callback = function(value) State.ShowSpots = value end,
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
	local cfg = { On = true, Mode = "Enemy path", Max = 6, UpgradeWave = 0 }
	State.Slots[slot] = cfg
	local equipped = Collection:Equipped()
	local u = Collection:Unit(equipped[slot] or equipped[tonumber(slot)] or "")
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
	section:AddSlider("Slot" .. slot .. "Max", {
		Title = "Max Placed", Default = 6, Min = 1, Max = 20, Rounding = 0,
		Description = cap and ("Max " .. cap .. ", none in Fool's Hunt.") or nil,
		Callback = function(value) cfg.Max = value end,
	})
	section:AddSlider("Slot" .. slot .. "UpgradeWave", {
		Title = "Upgrade After Wave", Default = 0, Min = 0, Max = 200, Rounding = 0,
		Description = "Auto Upgrade starts this slot at this wave. 0 = any time.",
		Callback = function(value) cfg.UpgradeWave = value end,
	})
	section:AddButton({
		Title = "Set Position Here",
		Description = "Saves your spot for this map.",
		Callback = function() Collection:SetSlotPosition(slot) end,
	})
end

local UpgradeSection = Tabs.AutoPlay:AddSection("Upgrade")
-- why Auto Upgrade is or isn't upgrading right now, so a customer's screenshot shows it
local UpgradeStatus = UpgradeSection:AddParagraph({ Title = "Status", Content = IS_LOBBY and "In the lobby." or "Waiting..." })
UpgradeSection:AddToggle("AutoUpgrade", {
	Title = "Auto Upgrade", Default = false,
	Description = "Waits for the macro to finish.",
	Callback = function(value) State.AutoUpgrade = value end,
})
UpgradeSection:AddSlider("UpgradeUntil", {
	Title = "Upgrade Until", Default = 13, Min = 1, Max = 13, Rounding = 0,
	Description = "Stops at this upgrade. 13 = max.",
	Callback = function(value) State.UpgradeUntil = value end,
})
do
	local entries = {}
	for _, name in equippedNames do table.insert(entries, { id = name, label = name, on = false }) end
	Collection:AddPriorityList(UpgradeSection, "UpgradePriority", {
		Title = "Upgrade Priority", Entries = entries,
		Description = "Ticked = maxed top first. Your team at hub load.",
		Callback = function(value) State.UpgradePriority = value end,
	})
end
UpgradeSection:AddDropdown("UpgradeOrder", {
	Title = "Upgrade Order", Values = { "Cheapest first", "Farms first", "Strongest first" }, Default = "Cheapest first", Multi = false,
	Description = "For units not ticked in Upgrade Priority.",
	Callback = function(value) State.UpgradeOrder = value end,
})
UpgradeSection:AddToggle("PlaceBeforeUpgrading", {
	Title = "Place Before Upgrading", Default = true,
	Description = "Upgrades wait for Auto Place.",
	Callback = function(value) State.PlaceBeforeUpgrade = value end,
})

-- Auto Upgrade stops each unit at its own cap (and never past Upgrade Until); your team at hub load, by name
if #equippedNames > 0 then
	local CapSection = Tabs.AutoPlay:AddSection("Upgrade Per Unit Cap")
	for _, name in equippedNames do
		CapSection:AddSlider("UpgradeCap_" .. name, {
			Title = name, Default = 13, Min = 0, Max = 13, Rounding = 0,
			Description = "Stops at this upgrade. 13 = max.",
			Callback = function(value) State.UpgradeCaps[name] = value end,
		})
	end
end
--------------------------- [[ Ability Tab ]] ---------------------------

local AbilitySection = Tabs.Ability:AddSection("Abilities")
AbilitySection:AddToggle("AutoAbility", {
	Title = "Auto Use Abilities", Default = false,
	Description = "Skips buff units.",
	Callback = function(value) State.AutoAbility = value end,
})
AbilitySection:AddDropdown("AbilityIgnore", {
	Title = "Ignore Units", Values = equippedNames, Multi = true, Default = {},
	Description = "Fusion units like Carrot, Vegito.",
	Callback = function(value) State.AbilityIgnore = value end,
})
local BuffSection = Tabs.Ability:AddSection("Buffs")
BuffSection:AddToggle("LoopBuffs", {
	Title = "Loop Buffs", Default = false,
	Description = "Buff units take turns. Keep game Auto off.",
	Callback = function(value) State.LoopBuffs = value end,
})

--------------------------- [[ Macro Tab ]] ---------------------------

local MacroMain = Tabs.Macro:AddSection("Macro")
MacroStatus = MacroMain:AddParagraph({ Title = "Status", Content = IS_LOBBY and "In the lobby." or "Waiting for the match..." })
MacroMain:AddDropdown("MacroName", {
	Title = "Macro", Values = Collection:ListMacros(), Multi = false,
	Description = "Auto Switch overrides this.",
	Callback = function(value) State.MacroName = value end,
})
MacroMain:AddToggle("RecordMacro", {
	Title = "Record Macro", Default = false,
	Description = "Records your actions, not buff units.",
	Callback = function(value)
		State.RecordMacro = value
		recording, recordTarget = value and {} or nil, nil
	end,
})
MacroMain:AddToggle("PlayMacro", {
	Title = "Play Macro", Default = false,
	Description = "Waits for money and waves.",
	Callback = function(value) State.PlayMacro = value end,
})
MacroMain:AddToggle("MacroSlotSpots", {
	Title = "Place At Auto Play Points", Default = false,
	Description = "Spawns at Auto Play points.",
	Callback = function(value) State.MacroSlotSpots = value end,
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
	Description = "Assignments follow it.",
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

local MacroInstall = Tabs.Macro:AddSection("Share")
MacroInstall:AddInput("MacroLink", {
	Title = "Link Or JSON", Placeholder = "https://...json or pasted macro JSON", Default = "", Finished = false,
})
-- a shared macro from a link or pasted JSON: its steps and saved name, or nil and why
function Collection:ReadSharedMacro(text)
	local isLink = text:match("^https?://") ~= nil
	if not isLink and text:sub(1, 1) ~= "{" then return nil, "Paste a link that starts with https:// or a macro's JSON." end
	local body = text
	if isLink then
		local ok, result = pcall(game.HttpGet, game, text)
		if not ok then return nil, "Download failed: " .. tostring(result) end
		body = result
	end
	local decoded, data = pcall(HttpService.JSONDecode, HttpService, body)
	if not decoded or type(data) ~= "table" or type(data.steps) ~= "table" then
		return nil, isLink and "That link isn't a macro file. Discord links expire after a day; copy a fresh one."
			or "That JSON isn't a macro. Paste everything Export copied."
	end
	return data.steps, data.name or (isLink and text:match("([^/?#]+)%.json"))
end
function Collection:InstallMacro(name, steps)
	Collection:SaveMacro(name, steps)
	steps = Collection:LoadMacro(name) -- converts old uuid steps when the units are yours
	local stale = 0
	for _, step in steps do
		if step.type == "spawn" and not step.unit_id then stale += 1 end
	end
	Collection:RefreshMacroLists()
	VaderUI.Options.MacroName:SetValue(name)
	Collection:Notify("Installed " .. name .. " - " .. Collection:MacroSummary(steps))
	if stale > 0 then
		Collection:Notify(stale .. " spawns were saved by an older hub version and will be skipped. Ask the sender to load it once in this version and share it again.")
	end
end
MacroInstall:AddButton({
	Title = "Install Macro",
	Description = "Uses Name, or its own.",
	Callback = function() task.spawn(function()
		local text = (VaderUI.Options.MacroLink.Value:gsub("^%s+", ""):gsub("%s+$", ""))
		local steps, sharedName = Collection:ReadSharedMacro(text)
		if not steps then return Collection:Notify(sharedName) end
		local name = Collection:CleanMacroName(VaderUI.Options.MacroNewName.Value)
		if name == "" then name = Collection:CleanMacroName(sharedName) end
		if name == "" then name = "Macro" end
		if not (canPersist and isfile(Collection:MacroPath(name))) then return Collection:InstallMacro(name, steps) end
		Window:Dialog({
			Title = "Replace macro?",
			Content = name .. " already exists. Replace it with the downloaded one?",
			Buttons = {
				{ Title = "Replace", Callback = function() Collection:InstallMacro(name, steps) end },
				{ Title = "Cancel" },
			},
		})
	end) end,
})
MacroInstall:AddButton({
	Title = "Export Selected Macro",
	Description = "Copies JSON to clipboard.",
	Callback = function()
		local name = State.MacroName
		if not name then return Collection:Notify("Pick a macro to export.") end
		local copy = setclipboard or toclipboard or (Clipboard and Clipboard.set)
		local steps = Collection:LoadMacro(name) -- old uuid steps become unit ids first
		if type(copy) ~= "function" or not pcall(copy, HttpService:JSONEncode({ name = name, steps = steps })) then
			return Collection:Notify("Couldn't copy to the clipboard.")
		end
		Collection:Notify("Copied " .. name .. " - " .. Collection:MacroSummary(steps))
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
	Description = "Per game mode and map.",
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
	Description = "From this match.",
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
	Collection:Elevate()
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
	Description = "Stops at reserve or full storage.",
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
	Description = "Game's auto-sell.",
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
	Description = "Keeps unpicked Mythics.",
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
	Description = "Rolls until a picked trait. No Robux.",
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
	Description = "All stats: every stat.",
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

local RollbackSection = Tabs.Traits:AddSection("RollBack Reroll")
-- a joke button: a skeleton runs across the screen (0:00-0:01.656 of the clip, green screen cut out). 30fps frames
-- cropped to the skeleton and packed in 3 sprite sheets, cached in the profile folder after the first download
local ROLLBACK_URL = "https://raw.githubusercontent.com/DONUT6599/Kneeguardseller/refs/heads/main/"
-- per frame: sheet, rect in the sheet (x, y, w, h), and where it sits in the 16:9 frame (x, y, w, h as 0-1), or false
-- while the skeleton is off screen
local ROLLBACK_FRAMES = {
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	{ 3, 1000, 0, 4, 10, 0.9961, 0.6806, 0.0039, 0.0181 },
	{ 3, 703, 0, 22, 154, 0.9766, 0.5222, 0.0234, 0.2861 },
	{ 3, 659, 0, 44, 248, 0.9547, 0.3556, 0.0453, 0.4597 },
	{ 3, 583, 0, 76, 249, 0.9211, 0.3486, 0.0789, 0.4611 },
	{ 3, 473, 0, 110, 265, 0.8859, 0.3389, 0.1141, 0.4903 },
	{ 3, 328, 0, 145, 277, 0.8492, 0.3319, 0.1508, 0.5125 },
	{ 3, 0, 0, 161, 284, 0.8242, 0.3264, 0.1680, 0.5250 },
	{ 2, 857, 684, 151, 292, 0.8055, 0.3208, 0.1570, 0.5417 },
	{ 2, 514, 684, 130, 298, 0.7852, 0.3181, 0.1359, 0.5514 },
	{ 2, 644, 684, 102, 297, 0.7664, 0.3208, 0.1062, 0.5500 },
	{ 2, 746, 684, 111, 295, 0.7320, 0.3222, 0.1156, 0.5458 },
	{ 2, 378, 684, 136, 301, 0.6867, 0.3139, 0.1414, 0.5569 },
	{ 2, 201, 684, 177, 308, 0.6367, 0.3028, 0.1844, 0.5708 },
	{ 2, 0, 684, 201, 317, 0.5914, 0.2958, 0.2094, 0.5875 },
	{ 2, 650, 350, 227, 327, 0.5367, 0.2917, 0.2367, 0.6056 },
	{ 2, 0, 350, 254, 334, 0.4734, 0.2889, 0.2648, 0.6181 },
	{ 2, 254, 350, 216, 334, 0.4570, 0.2917, 0.2250, 0.6181 },
	{ 2, 470, 350, 180, 334, 0.4414, 0.2958, 0.1875, 0.6194 },
	{ 2, 639, 0, 184, 335, 0.4164, 0.2986, 0.1922, 0.6208 },
	{ 2, 219, 0, 220, 338, 0.3633, 0.3028, 0.2289, 0.6264 },
	{ 2, 439, 0, 200, 338, 0.3117, 0.3056, 0.2078, 0.6264 },
	{ 2, 0, 0, 219, 350, 0.2508, 0.2931, 0.2281, 0.6486 },
	{ 1, 614, 403, 289, 364, 0.1891, 0.2819, 0.3008, 0.6736 },
	{ 1, 310, 403, 304, 381, 0.1242, 0.2708, 0.3172, 0.7056 },
	{ 1, 0, 403, 310, 394, 0.0789, 0.2625, 0.3234, 0.7306 },
	{ 1, 0, 0, 296, 403, 0.0352, 0.2542, 0.3086, 0.7458 },
	{ 1, 296, 0, 241, 403, 0.0266, 0.2542, 0.2508, 0.7458 },
	{ 1, 537, 0, 217, 402, 0.0000, 0.2556, 0.2258, 0.7444 },
	{ 3, 161, 0, 167, 278, 0.0000, 0.4847, 0.1742, 0.5153 },
	{ 3, 725, 0, 124, 60, 0.0000, 0.8889, 0.1289, 0.1111 },
	{ 3, 849, 0, 101, 53, 0.0000, 0.9014, 0.1055, 0.0986 },
	{ 3, 950, 0, 50, 33, 0.0000, 0.9389, 0.0523, 0.0611 },
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
}
function Collection:PlayRollback()
	if type(getcustomasset) ~= "function" then return Collection:Notify("Your executor can't show it.") end
	local folder = profileFolder .. "/rollback"
	if canPersist and not isfolder(folder) then makefolder(folder) end
	local sheets = {}
	for n = 1, 3 do
		local path = folder .. "/skeleton" .. n .. ".png"
		if not isfile(path) then
			local ok, body = pcall(game.HttpGet, game, ROLLBACK_URL .. "skeleton" .. n .. ".png")
			if not ok or #body < 1000 then return Collection:Notify("Couldn't download it.") end
			writefile(path, body)
		end
		local ok, id = pcall(getcustomasset, path)
		if not ok then return Collection:Notify("Couldn't load it.") end
		sheets[n] = id
	end
	Collection:Elevate()
	local gui = Collection:Instance("ScreenGui", {
		Name = "VaderRollback", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 100,
		Parent = gethui and gethui() or game:GetService("CoreGui"),
	})
	local stage = Collection:Instance("Frame", {
		Size = UDim2.fromScale(1, 1), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Parent = gui,
	})
	Collection:Instance("UIAspectRatioConstraint", { AspectRatio = 16 / 9, Parent = stage })
	local img = Collection:Instance("ImageLabel", { BackgroundTransparency = 1, Visible = false, Parent = stage })
	-- load every sheet before the first frame, so none flashes in empty
	local preload = {}
	for _, id in sheets do table.insert(preload, Collection:Instance("ImageLabel", { Image = id, Size = UDim2.fromOffset(1, 1), ImageTransparency = 1, BackgroundTransparency = 1, Parent = gui })) end
	pcall(Services.ContentProvider.PreloadAsync, Services.ContentProvider, preload)
	Collection:Elevate()
	local t0 = os.clock()
	while true do
		local i = math.floor((os.clock() - t0) * 30) + 1
		if i > #ROLLBACK_FRAMES then break end
		local f = ROLLBACK_FRAMES[i]
		img.Visible = f ~= false
		if f then
			img.Image = sheets[f[1]]
			img.ImageRectOffset, img.ImageRectSize = Vector2.new(f[2], f[3]), Vector2.new(f[4], f[5])
			img.Position, img.Size = UDim2.fromScale(f[6], f[7]), UDim2.fromScale(f[8], f[9])
		end
		Services.RunService.RenderStepped:Wait()
	end
	gui:Destroy()
end
RollbackSection:AddButton({
	Title = "RollBack Reroll",
	Callback = function() task.spawn(Collection.PlayRollback, Collection) end,
})

Tabs.Traits:AddButton({
	Title = "Refresh Unit Lists",
	Callback = function() Collection:RefreshUnitDropdowns() end,
})

--------------------------- [[ Rewards Tab ]] ---------------------------

local ClaimSection = Tabs.Rewards:AddSection("Auto Claim")
local RewardStatus = ClaimSection:AddParagraph({ Title = "Status", Content = "Checks every minute." })
for _, paragraph in { JoinStatus, EventStatus, DungeonStatus, MatchStatus, PlaceStatus, MacroStatus, AssignList, SummonStatus, TraitStatus, StatStatus, RewardStatus } do
	local setDesc = paragraph.SetDesc
	function paragraph:SetDesc(text) Collection:Elevate() return setDesc(self, text) end
end
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
	Description = "Game's low quality.",
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

-- enemies (pve_units) leave your client: nothing to render or animate, while the server still runs and kills them.
-- Parent = nil, not Destroy: the game's death handler still moves the model to _DEAD_UNITS, and Destroy locks Parent
Collection.HiddenEnemies = setmetatable({}, { __mode = "k" })
function Collection:HideEnemy(m)
	if State.DeleteEnemies and CollectionService:HasTag(m, "pve_units") then
		Collection.HiddenEnemies[m] = true
		m.Parent = nil
	end
end
-- the living ones come back; dead ones were destroyed or moved to _DEAD_UNITS
function Collection:ShowEnemies()
	for m in Collection.HiddenEnemies do
		if m.Parent == nil then pcall(function() m.Parent = workspace._UNITS end) end
	end
	table.clear(Collection.HiddenEnemies)
end
Performance:AddToggle("DeleteEnemies", {
	Title = "Delete Enemies (more FPS)", Default = false,
	Description = "Your screen only. The server still has them, so your units keep killing them.",
	Callback = function(value)
		State.DeleteEnemies = value
		if IS_LOBBY then return end
		if value then
			for _, m in workspace._UNITS:GetChildren() do Collection:HideEnemy(m) end
		else
			Collection:ShowEnemies()
		end
	end,
})
-- deferred so the game's own spawn handler sets the enemy up first
if not IS_LOBBY then
	Collection:Track(workspace._UNITS.ChildAdded:Connect(function(m) task.defer(Collection.HideEnemy, Collection, m) end))
end

-- the map's scenery (workspace._map, most of a map's parts) leaves your client; Auto Place only needs _terrain, _road and
-- _BASES, which stay. Parent = nil, not Destroy: the map's own scripts move parts they grabbed at load every frame
function Collection:ApplyDeleteMap()
	if IS_LOBBY then return end
	if State.DeleteMap then
		local map = workspace:FindFirstChild("_map")
		if map then Collection.HiddenMap, map.Parent = map, nil end
	elseif Collection.HiddenMap then
		Collection.HiddenMap.Parent = workspace
		Collection.HiddenMap = nil
	end
end
Performance:AddToggle("DeleteMap", {
	Title = "Delete Map (more FPS)", Default = false,
	Description = "Your screen only. Hides the scenery; the ground and road stay, so Auto Place still works.",
	Callback = function(value)
		State.DeleteMap = value
		-- wait for the map, so its own scripts have grabbed their parts first
		task.spawn(function()
			repeat task.wait(1) until closed or IS_LOBBY or workspace._MAP_CONFIG.MapLoaded.Value
			Collection:ApplyDeleteMap()
		end)
	end,
})

-- strips everything that glows or costs frames: lighting effects, sky, shadows, water, particles, lights, decals and
-- textures, and anything that spawns later; lowest saved quality level. The hub's own markers (workspace.Vader*) keep their looks
function Collection:BoostInstance(inst)
	local top = inst
	while top.Parent and top.Parent ~= workspace do top = top.Parent end
	if top.Name:find("^Vader") then return end
	if inst:IsA("BasePart") then
		inst.CastShadow = false
		inst.Material = Enum.Material.SmoothPlastic
		inst.Reflectance = 0
		if inst:IsA("MeshPart") then
			inst.RenderFidelity = Enum.RenderFidelity.Performance
			inst.CollisionFidelity = Enum.CollisionFidelity.Box
		end
	end
	if inst:IsA("Highlight") or inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") or inst:IsA("Smoke")
		or inst:IsA("Fire") or inst:IsA("Sparkles") or inst:IsA("Explosion") or inst:IsA("Clouds")
		or inst:IsA("Decal") or inst:IsA("Texture") or inst:IsA("ShirtGraphic") then
		inst:Destroy()
	elseif inst:IsA("Light") then
		inst.Enabled = false
	end
end
function Collection:BoostFPS()
	local Lighting = Services.Lighting
	pcall(function()
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 9e9
		Lighting.Technology = Enum.Technology.Compatibility
		Lighting.EnvironmentSpecularScale = 0
		Lighting.EnvironmentDiffuseScale = 0
		Lighting.Brightness = 1
		Lighting.ClockTime = 14
		for _, v in Lighting:GetChildren() do
			if v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Sky") or v:IsA("Clouds") then v:Destroy() end
		end
		local sky = Instance.new("Sky")
		sky.SunTextureId, sky.MoonTextureId, sky.StarCount = "", "", 0
		for _, face in { "Bk", "Dn", "Ft", "Lf", "Rt", "Up" } do sky["Skybox" .. face] = "rbxassetid://0" end
		sky.Parent = Lighting
	end)
	pcall(function()
		local terrain = workspace:FindFirstChildOfClass("Terrain")
		terrain.WaterWaveSize, terrain.WaterWaveSpeed, terrain.WaterReflectance, terrain.WaterTransparency = 0, 0, 0, 0
		terrain.Decoration = false
	end)
	for _, v in workspace:GetDescendants() do pcall(Collection.BoostInstance, Collection, v) end
	-- deferred so whatever made it (the game, or the hub naming its markers) finishes setting it up first
	Collection.BoostConnection = Collection.BoostConnection or Collection:Track(workspace.DescendantAdded:Connect(function(v)
		if State.BoostFPS then task.defer(pcall, Collection.BoostInstance, Collection, v) end
	end))
	pcall(function() UserSettings().GameSettings.SavedQualityLevel = Enum.SavedQualityLevel.Level1 end)
end
Performance:AddToggle("BoostFPS", {
	Title = "Boost FPS", Default = false,
	Description = "Matches only. Strips lighting, shadows, glow, particles, decals and textures. Rejoin to undo.",
	Callback = function(value)
		State.BoostFPS = value
		if not value or IS_LOBBY then return end -- the lobby keeps its looks
		task.spawn(function()
			repeat task.wait(1) until closed or workspace._MAP_CONFIG.MapLoaded.Value
			if not closed and State.BoostFPS then Collection:BoostFPS() end
		end)
	end,
})
Performance:AddToggle("WhiteScreen", {
	Title = "White Screen (more FPS)", Default = false,
	Description = "Stops 3D rendering. The hub still works.",
	Callback = function(value)
		-- Ignore the initial "off" so nothing else's rendering setting is touched.
		if not value and not State.WhiteScreen then return end
		State.WhiteScreen = value
		pcall(Services.RunService.Set3dRenderingEnabled, Services.RunService, not value)
	end,
})
-- off = Roblox's own 60
function Collection:ApplyFPSCap()
	if setfpscap then pcall(setfpscap, State.FPSLock and State.FPSCap or 60) end
end
Performance:AddToggle("FPSLock", {
	Title = "FPS Cap", Default = false,
	Description = "Caps your FPS at FPS Cap Value.",
	Callback = function(value)
		-- Ignore the initial "off" so the player's own FPS unlocker is left alone.
		if not value and not State.FPSLock then return end
		State.FPSLock = value
		Collection:ApplyFPSCap()
	end,
})
Performance:AddSlider("FPSCap", {
	Title = "FPS Cap Value", Default = 30, Min = 5, Max = 240, Rounding = 0,
	Callback = function(value)
		State.FPSCap = value
		if State.FPSLock then Collection:ApplyFPSCap() end
	end,
})
-- Roblox puts its own cap back now and then (window focus, menus, settings), so keep re-applying ours
task.spawn(function()
	while not closed do
		if State.FPSLock then Collection:ApplyFPSCap() end
		task.wait(1)
	end
end)

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
	Description = "Your screen only.",
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
		Collection:Webhook("Test", "Webhook connected", { "Total Gem : " .. Collection:Comma(Collection:Gems()) })
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

-- queue like the Matchmaking button; the queue holds the lobby loop until it ends, active() going false leaves it
function Collection:Matchmake(level, label, name, active)
	if not Collection:TeleportDelay("Matchmaking " .. name, active) then
		return nil, label .. ": matchmaking cancelled."
	end
	Collection:Invoke("request_matchmaking", level)
	JoinStatus:SetDesc(label .. ": matchmaking for " .. name .. "...")
	local queue, t0 = LP.PlayerGui:FindFirstChild("MatchmakingUI"), os.clock()
	while not closed and (os.clock() - t0 < 5 or (queue and queue.Enabled)) do
		if not active() then
			Collection:Invoke("leave_matchmaking")
			return nil, label .. ": left matchmaking."
		end
		task.wait(1)
	end
	task.wait(10) -- a match found teleports us during this
	return nil, label .. ": matchmaking ended without a match."
end

-- daily = the once-a-day challenge on _CHALLENGES.DailyChallenge, else the half-hourly one
function Collection:JoinChallenge(daily)
	local c = daily and Collection:Invoke("get_daily_challenge") or Collection:RefreshChallenge()
	local done = session.profile_data[daily and "last_completed_daily_challenge_uuid" or "last_completed_challenge_uuid"]
	if type(c) ~= "table" or c.current_uuid == done then return nil end
	local name, toggle = daily and "daily challenge" or "challenge", daily and "AutoJoinDailyChallenge" or "AutoJoinChallenge"
	local level = daily and type(c.current_level) == "table" and c.current_level.name or c.current_level_id
	-- the game's pads queue these two ids, not the level
	if State[daily and "DailyJoinBy" or "ChallengeJoinBy"] == "Matchmaking" then
		return Collection:Matchmake(daily and "__DAILY_CHALLENGE" or "__NORMAL_CHALLENGE", daily and "Daily challenge" or "Challenge",
			tostring(level), function() return State[toggle] end)
	end
	local folder = workspace:FindFirstChild("_CHALLENGES") and workspace._CHALLENGES:FindFirstChild(daily and "DailyChallenge" or "Challenges")
	for _, pad in folder and folder:GetChildren() or {} do
		local tele, players = pad:FindFirstChild("Teleporting"), pad:FindFirstChild("Players")
		if tele and not tele.Value and (not players or #players:GetChildren() == 0) and Collection:Invoke("request_join_lobby", pad.Name) then
			if not Collection:TeleportDelay("Starting the " .. name, function() return State[toggle] end) then
				Collection:Invoke("request_leave_lobby", pad.Name)
				return nil, name .. ": start cancelled."
			end
			Collection:Invoke("request_start_game", pad.Name)
			return pad, "Joined " .. name .. ": " .. tostring(c.current_challenge) .. " on " .. tostring(level)
		end
	end
	return nil, "No free " .. name .. " pad"
end

-- the event stage on the lobby's event pads: walk in like Play Solo, or queue like the Matchmaking button
function Collection:JoinEvent()
	local folder = workspace:FindFirstChild("_EVENT_CHALLENGES") and workspace._EVENT_CHALLENGES:FindFirstChild("Lobbies")
	local level
	for _, pad in folder and folder:GetChildren() or {} do
		if pad:FindFirstChild("Level") and pad.Level.Value ~= "" then level = pad.Level.Value break end
	end
	if not level then return nil, "Event: no event pad in this lobby." end
	local name = Data.Levels[level] and Data.Levels[level].name or level
	if State.EventJoinBy == "Matchmaking" then
		return Collection:Matchmake(level, "Event", name, function() return State.AutoJoinEvent end)
	end
	local pad = Collection:FreePad(folder)
	if not pad then return nil, "Event: no free pad." end
	if not Collection:Invoke("request_join_lobby", pad.Name) then return nil, "Event: couldn't join a pad." end
	if not Collection:TeleportDelay("Starting " .. name, function() return State.AutoJoinEvent end) then
		Collection:Invoke("request_leave_lobby", pad.Name)
		return nil, "Event: start cancelled."
	end
	Collection:Invoke("request_start_game", pad.Name)
	return pad, "Starting event: " .. name
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
	if State.ContractJoinBy == "Matchmaking" then
		return Collection:Matchmake(contract.id, "Contract", tostring(contract.name), function() return State.AutoContract end)
	end
	return Collection:StartPortal("Contract", tostring(contract.name), function() return State.AutoContract end,
		function() return Collection:Invoke("open_event_contract_portal", key) end)
end

-- open() opens a portal lobby for you; once the server hands over its pad, start it. wanted() is the feature's toggle
function Collection:StartPortal(mode, label, wanted, open)
	local created
	local conn = fromServer.portal_lobby_owner_created.OnClientEvent:Connect(function(pad) created = pad end)
	open()
	local t0 = os.clock()
	while not created and os.clock() - t0 < 5 do task.wait(0.1) end
	conn:Disconnect()
	if not created then return nil, mode .. ": couldn't open a portal." end
	if not Collection:TeleportDelay("Starting " .. label, wanted) then
		Collection:Invoke("request_leave_lobby", created.Name)
		return nil, mode .. ": start cancelled."
	end
	Collection:Invoke("request_start_game", created.Name)
	return created, mode .. ": starting " .. label
end

-- a picked portal from your inventory, opened like the inventory's Use button
function Collection:JoinPortal()
	for _, it in session.inventory.inventory_profile_data.unique_items do
		local item = Data.Items[it.item_id]
		if item and item.usage and item.usage.type == "open_portal" and State.Portals[item.name] then
			return Collection:StartPortal("Portal", item.name, function() return State.AutoPortal end,
				function() return Collection:Invoke("use_portal", it.uuid, State.FriendsOnly and { friends_only = true } or nil) end)
		end
	end
	return nil, "Portal: none of the picked portals in your inventory."
end

-- Infinity Mansion: the next room you haven't cleared, like the game's Start button. A started room teleports during the
-- wait; still here after it means the start didn't go through, so other modes get their turn
function Collection:JoinMansion()
	local tower = (session.profile_data.level_data or {}).infinite_tower
	local room = tower and tower.floor_reached or 1
	local difficulty = State.MansionDifficulty
	if difficulty == "Hard" and not Core.InfiniteTowerServiceCore.has_unlocked_difficulty(session, room, "Hard") then
		return nil, "Infinity Mansion: Hard is locked."
	end
	if not Collection:TeleportDelay("Starting Infinity Mansion room " .. room, function() return State.AutoMansion end) then
		return nil, "Infinity Mansion: start cancelled."
	end
	Collection:Invoke("request_start_infinite_tower", room, difficulty)
	JoinStatus:SetDesc(string.format("Infinity Mansion: starting room %d (%s)...", room, difficulty))
	task.wait(15)
	return nil, string.format("Infinity Mansion: room %d (%s) didn't start.", room, difficulty)
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
	-- the game only offers matchmaking on _MATCHMAKING levels; the rest stay solo
	if State.JoinBy[mode] == "Matchmaking" and Data.Levels[levelId]._MATCHMAKING then
		return Collection:Matchmake(levelId, mode, label, function() return State.Join[mode] end)
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

local dungeonTurn = false -- Join Priority reached Dungeon Run: the dungeon loop may start a run / enter a room from the lobby
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
			-- an auto dungeon run (or one about to start) gets the lobby when Join Priority reaches it
			local dungeonOn = State.AutoDungeon and (Collection:DungeonData()._started or State.DungeonStart)
			if (State.AutoJoinDailyChallenge or State.AutoJoinChallenge or State.AutoContract or State.AutoPortal or State.AutoJoinEvent or State.AutoMansion or dungeonOn or Collection:AnyModeOn())
				and not Collection:InPad() then
				local pad, msg, dungeon
				local notes = {}
				local tries = {
					Dungeon = { dungeonOn, function() dungeon = true return nil, "Dungeon Run: its turn (Dungeon tab)." end },
					DailyChallenge = { State.AutoJoinDailyChallenge, function() return Collection:JoinChallenge(true) end },
					Challenge = { State.AutoJoinChallenge, function() return Collection:JoinChallenge() end },
					Contract = { State.AutoContract, Collection.JoinContract },
					Portal = { State.AutoPortal, Collection.JoinPortal },
					Event = { State.AutoJoinEvent, Collection.JoinEvent },
					Mansion = { State.AutoMansion, Collection.JoinMansion },
				}
				for _, mode in MODES do tries[mode] = { State.Join[mode], function() return Collection:JoinStage(mode) end } end
				-- Join Priority: top first, unticked skipped
				for _, entry in State.JoinPriority do
					if pad or dungeon then break end
					local try = tries[entry.id]
					if entry.on and try[1] then
						pad, msg = try[2](Collection)
						if msg then table.insert(notes, msg) end
					end
				end
				dungeonTurn = dungeon == true
				if #notes > 0 then
					JoinStatus:SetDesc(table.concat(notes, "\n"))
					eventNote = table.concat(notes, "\n")
					Collection:RefreshEventStatus()
				end
				if pad then
					-- let the pad's own countdown (60s stages, 30s challenges) and the teleport finish; 120s caps a stuck pad
					local t0, timer, tele = os.clock(), pad:FindFirstChild("Timer"), pad:FindFirstChild("Teleporting")
					while not closed and Collection:InPad() and os.clock() - t0 < 120
						and (os.clock() - t0 < 20 or (timer and timer.Value > 0) or (tele and tele.Value)) do
						task.wait(1)
					end
					-- still here: the start didn't go through, free the pad and try again
					if not closed and Collection:InPad() then Collection:Invoke("request_leave_lobby", pad.Name) end
				end
			end
			task.wait(4)
		end
	end)
end

--------------------------- [[ Match ]] ---------------------------

-- placed units only: not minions, nor drones (Elyssia (Abyssal)'s eels carry her uuid and die every ~10s)
function Collection:MyUnits()
	local list = {}
	for _, m in workspace:FindFirstChild("_UNITS") and workspace._UNITS:GetChildren() or {} do
		local st = m:FindFirstChild("_stats")
		if st and st:FindFirstChild("player") and st.player.Value == LP and st:FindFirstChild("uuid")
			and not CollectionService:HasTag(m, "minion_units") and not CollectionService:HasTag(m, "player_drone_unit") then
			table.insert(list, m)
		end
	end
	return list
end

-- the buff an active ability gives allies ({ name, time } from the attack data), or nil when it isn't a buff
function Collection:BuffOf(attack)
	for _, aoe in attack and attack.aoe or {} do
		local buff = aoe.hit_allies and aoe.hit and aoe.hit.buffs and aoe.hit.buffs[1]
		if buff then return buff end
	end
end

-- a buff unit: its active ability buffs allies (Commander, Elfy, Windsong...)
function Collection:IsBuffUnit(m)
	local ok, id = pcall(Core.UnitServiceCore.get_active_id, m)
	return ok and id ~= nil and Collection:BuffOf(Data.Attacks[id]) ~= nil
end

function Collection:UpgradeCost(m)
	local ok, info, isMax = pcall(Client.GUIService.get_next_upgrade_info, m, Collection:Unit(m._stats.uuid.Value) or {})
	if ok and info and not isMax then return math.ceil(info.cost * Core.UnitServiceCore.calculate_upgrade_cost_multiplier(m, session)) end
end
function Collection:IsMaxed(m)
	local ok, _, isMax = pcall(Client.GUIService.get_next_upgrade_info, m, Collection:Unit(m._stats.uuid.Value) or {})
	return ok and isMax == true
end

-- an event card's kind: its first effect that isn't the event-currency bonus most curses carry
function Collection:CardKind(card)
	local main
	for _, e in card.effects or {} do
		if e.type ~= "candy_multiplier" then main = e break end
	end
	main = main or (card.effects or {})[1]
	if not main then return "?" end
	if main.type == "random_effects" then return main._type == "Good" and "random_blessings" or "random_curses" end
	if main.stat and main.type:match("^stat_") then return "stat:" .. main.stat end
	if main.type == "enemy_resistance_specific" then
		-- Plated Enemies resists one damage type, Resistant Enemies all of them
		local types = 0
		for _, e in card.effects do if e.type == main.type then types += 1 end end
		return main.type .. ":" .. (types > 1 and "all" or tostring(main.damage_type))
	end
	return main.type .. (main.stat and ":" .. main.stat or "")
end

-- the offered card highest in Card Priority; kinds the list doesn't know rank after every listed one
function Collection:PickCard(options)
	local rank = {}
	for i, entry in State.CardPriority do rank[entry.id] = entry.on and i end
	local bestKey, bestRank
	for key, card in options do
		local r = rank[Collection:CardKind(card)]
		if r == nil then r = #State.CardPriority + 1 end
		if r and (not bestRank or r < bestRank) then bestKey, bestRank = key, r end
	end
	return bestKey
end

--------------------------- [[ Auto Play ]] ---------------------------

local placePending = false -- Auto Place still has units to put down; Place Before Upgrading holds upgrades meanwhile
local EVENT_MAX_UNITS = 20 -- in events Auto Place stops at this many of your units on the map
local macroPending = false -- Play Macro still has steps left; Auto Upgrade waits so the macro gets the money

-- a slot's point: a spot along the first enemy lane at Placement Distance (Farm Placement Distance for money units),
-- or the position saved for this map and slot
function Collection:PlaceAnchor(slot, unitId)
	local cfg = State.Slots[slot]
	if cfg.Mode == "My position" then
		local p = placePositions[tostring(Collection:MapKey()) .. "|" .. slot]
		if not p then return nil, "no spot saved on this map" end
		return Vector3.new(p[1], p[2], p[3]), "saved spot"
	end
	local base, lanes, visible = Collection:Lanes()
	if not lanes then return nil, "enemy path not loaded yet" end
	local lane = visible[1]
	if not lane then return nil, "no enemy path on this map" end
	local percent = Collection:IsFarm(unitId) and State.FarmPlaceDistance or State.PlaceDistance
	local _, _, position = Core.PathService.get_path_position_by_distance_from_spawn(base, lane, lanes[lane].total_distance * percent / 100)
	return position, percent .. "% of the path"
end

-- the map's enemy lanes: the base, the game's path cache, and the visible lane folders by name
function Collection:Lanes()
	local PathService = Core.PathService
	local base = workspace:FindFirstChild("_BASES") and workspace._BASES:FindFirstChild("pve")
	local lanes = base and PathService.PATH_CACHE and PathService.PATH_CACHE[base]
	local visible = {}
	for laneFolder in lanes or {} do
		if not (PathService.HIDDEN_MOCK_LANES or {})[laneFolder.Name] then table.insert(visible, laneFolder) end
	end
	table.sort(visible, function(a, b) return a.Name < b.Name end)
	return base, lanes, visible
end

-- points every step studs (3 when not given) along one lane, spawn to base
function Collection:LanePoints(base, lanes, lane, step)
	local points = {}
	for d = 0, lanes[lane].total_distance, step or 3 do
		local _, _, position = Core.PathService.get_path_position_by_distance_from_spawn(base, lane, d)
		table.insert(points, position)
	end
	return points
end

-- the same along every visible lane (new lanes from event cards included), to measure distance to the road
function Collection:PathPoints()
	local base, lanes, visible = Collection:Lanes()
	local points = {}
	for _, lane in visible do
		for _, p in Collection:LanePoints(base, lanes, lane) do table.insert(points, p) end
	end
	return points
end

function Collection:PathDistance(points, x, z)
	local best = math.huge
	for _, p in points do
		local d = (p.X - x) ^ 2 + (p.Z - z) ^ 2
		if d < best then best = d end
	end
	return math.sqrt(best)
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

-- ground (or hill) the game accepts at x, z. Like the game's placement check (a thin stick through the new unit's
-- centre, PlacementServiceClient), only the centre has to stay off the road and outside other units' hitboxes, so units
-- can stand as close as the game allows. reserved { pos, radius } spots stand in for holograms not placed yet
local placeRay = RaycastParams.new()
placeRay.FilterType = Enum.RaycastFilterType.Include
local roadOverlap = OverlapParams.new()
roadOverlap.FilterType = Enum.RaycastFilterType.Include
function Collection:PlacementSpot(data, x, y, z, reserved)
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
		if #workspace:GetPartBoundsInBox(CFrame.new(hit.Position + Vector3.new(0, 2.5, 0)), Vector3.new(0.2, 5, 0.2), roadOverlap) > 0 then return nil end
	end
	for _, m in workspace._UNITS:GetChildren() do
		local box = m:FindFirstChild("_hitbox")
		if box and CollectionService:HasTag(m, "player_units") then
			-- placed units get an upright cylinder (Size = height, diameter, diameter); overrides can be a ball or a block
			local inside
			if box.Shape == Enum.PartType.Block then
				local rel = box.CFrame:PointToObjectSpace(Vector3.new(hit.Position.X, box.Position.Y, hit.Position.Z))
				inside = math.abs(rel.X) < box.Size.X / 2 and math.abs(rel.Z) < box.Size.Z / 2
			else
				inside = Vector2.new(box.Position.X - hit.Position.X, box.Position.Z - hit.Position.Z).Magnitude < box.Size.Z / 2
			end
			if inside then return nil end
		end
	end
	for _, r in reserved or {} do
		if Vector2.new(r.pos.X - hit.Position.X, r.pos.Z - hit.Position.Z).Magnitude < r.radius then return nil end
	end
	return hit.Position
end

-- points 1.5 studs apart across the tops of the map's hill parts, nearest to the anchor first
function Collection:HillPoints(anchor)
	local hill = workspace:FindFirstChild("_terrain") and workspace._terrain:FindFirstChild("hill")
	local points = {}
	for _, part in hill and hill:GetDescendants() or {} do
		if part:IsA("BasePart") then
			local size = part.Size
			for x = -size.X / 2 + 0.75, size.X / 2 - 0.75, 1.5 do
				for z = -size.Z / 2 + 0.75, size.Z / 2 - 0.75, 1.5 do
					table.insert(points, part.CFrame * Vector3.new(x, size.Y / 2, z))
				end
			end
		end
	end
	table.sort(points, function(a, b) return (a - anchor).Magnitude < (b - anchor).Magnitude end)
	return points
end

-- a free spot for a unit, the nearest to its target: the anchor, at (100 - hug)% of the unit's range from the road
-- when hug is given (100 on the enemy path: the road edge). Both count in studs (2-stud bands), so copies pack in a
-- tight group instead of running down the road. line (slots on the enemy path) takes spots beside the first lane;
-- otherwise rings within 30 studs of the anchor. Candidates are 1.5 studs apart so
-- units pack as tight as PlacementSpot allows. Hill units can only stand on hills, so they search the hill parts
-- instead. bad holds spots the server refused
function Collection:FindSpot(data, anchor, bad, reserved, hug, line)
	if data.hill_unit and workspace._terrain:FindFirstChild("hill") then
		for _, p in Collection:HillPoints(anchor) do
			local key = math.floor(p.X) .. "," .. math.floor(p.Z)
			if not bad[key] then
				local spot = Collection:PlacementSpot(data, p.X, p.Y, p.Z, reserved)
				if spot then return spot, key end
			end
		end
		return nil
	end
	local target = hug and (1 - hug / 100) * (data.range or 15)
	local function band(points, x, z)
		return #points > 0 and math.floor(math.abs(Collection:PathDistance(points, x, z) - target) / 2) or 0
	end
	local candidates = {}
	if line and target then
		local base, lanes, visible = Collection:Lanes()
		local road = visible[1] and Collection:LanePoints(base, lanes, visible[1], 1.5) or {}
		local all = #visible > 1 and Collection:PathPoints() or nil -- one lane: a spot's distance to it is its offset
		local at, nearest = 1, math.huge -- the sample at the slot's point
		for i, p in road do
			local d = (p - anchor).Magnitude
			if d < nearest then at, nearest = i, d end
		end
		for i, p in road do
			local dir = (road[math.min(i + 1, #road)] - road[math.max(i - 1, 1)]) * Vector3.new(1, 0, 1)
			if dir.Magnitude > 0 then
				local side = Vector3.new(-dir.Unit.Z, 0, dir.Unit.X)
				for offset = 1, target + 12 do
					for _, sign in { 1, -1 } do
						local q = p + side * offset * sign
						local b = all and band(all, q.X, q.Z) or math.floor(math.abs(offset - target) / 2)
						table.insert(candidates, { x = q.X, y = p.Y, z = q.Z, score = b * 2 + math.abs(i - at) * 1.5 + offset * 0.01 })
					end
				end
			end
		end
	else
		local maxR = math.max(30, (target or 0) + 9)
		local near = {}
		for _, p in target and Collection:PathPoints() or {} do
			if (p.X - anchor.X) ^ 2 + (p.Z - anchor.Z) ^ 2 < (maxR + 30) ^ 2 then table.insert(near, p) end
		end
		for r = 1.5, maxR, 1.5 do
			local steps = math.max(8, math.floor(2 * math.pi * r / 1.5))
			for k = 0, steps - 1 do
				local a = 2 * math.pi * k / steps
				local x, z = anchor.X + math.cos(a) * r, anchor.Z + math.sin(a) * r
				table.insert(candidates, { x = x, y = anchor.Y, z = z, score = band(near, x, z) * 2 + r })
			end
		end
	end
	table.sort(candidates, function(a, b) return a.score < b.score end)
	for _, c in candidates do
		local key = math.floor(c.x) .. "," .. math.floor(c.z)
		if not bad[key] then
			local spot = Collection:PlacementSpot(data, c.x, c.y, c.z, reserved)
			if spot then return spot, key end
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
	local counts, skip, reserved, spread = {}, {}, {}, {} -- spread: slot -> farthest planned spot from its point
	for _, s in slots do counts[s.slot] = s.count end
	for _ = 1, 36 do
		local pick
		for _, s in slots do
			if not full[s.uuid] and not skip[s.slot] and counts[s.slot] < s.cap and (not pick or counts[s.slot] < counts[pick.slot]) then
				pick = s
			end
		end
		if not pick then break end
		local spot = Collection:FindSpot(pick.data, pick.anchor, bad, reserved, pick.hug, pick.line)
		if spot then
			table.insert(reserved, { pos = spot, radius = pick.data.override_hitbox_radius or 2 })
			counts[pick.slot] += 1
			Collection:Hologram(pick, spot, counts[pick.slot], hologramFolder)
			spread[pick.slot] = math.max(spread[pick.slot] or 0, Vector2.new(spot.X - pick.anchor.X, spot.Z - pick.anchor.Z).Magnitude)
		else
			skip[pick.slot] = true
		end
		task.wait() -- one spot search a frame, so a rebuild doesn't freeze the game
	end
	-- each slot's area: a see-through disc around its point covering its placed units and planned spots, with a pin
	-- on every other spot in it the unit can stand on
	local units = Collection:MyUnits()
	for _, s in slots do
		local radius = spread[s.slot] or 0
		for _, m in units do
			if m._stats.uuid.Value == s.uuid then
				local p = m:GetPivot().Position
				radius = math.max(radius, Vector2.new(p.X - s.anchor.X, p.Z - s.anchor.Z).Magnitude)
			end
		end
		-- ponytail: 6-15 studs with pins 3 apart keeps it to ~80 ground checks a slot; reaching every unit lagged the game
		radius = math.clamp(radius + 3, 6, 15)
		placeRay.FilterDescendantsInstances = { workspace:FindFirstChild("_terrain") }
		local ground = workspace:Raycast(s.anchor + Vector3.new(0, 40, 0), Vector3.new(0, -120, 0), placeRay)
		Collection:Instance("Part", {
			Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, radius * 2, radius * 2), Anchored = true,
			CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.Neon,
			Color = HOLOGRAM_COLOR, Transparency = 0.8, Parent = hologramFolder,
			CFrame = CFrame.new(Vector3.new(s.anchor.X, (ground and ground.Position.Y or s.anchor.Y) + 0.1, s.anchor.Z)) * CFrame.Angles(0, 0, math.pi / 2),
		})
		for dx = -radius, radius, 3 do
			for dz = -radius, radius, 3 do
				local spot = dx * dx + dz * dz <= radius * radius and Collection:PlacementSpot(s.data, s.anchor.X + dx, s.anchor.Y, s.anchor.Z + dz, reserved)
				if spot then
					Collection:Instance("Part", {
						Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, 0.4, 0.4), Anchored = true,
						CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.Neon,
						Color = Color3.new(1, 1, 1), Transparency = 0.3, Parent = hologramFolder,
						CFrame = CFrame.new(spot + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, 0, math.pi / 2),
					})
				end
			end
		end
		task.wait() -- spread the raycasts over frames
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
	while not closed do
		task.wait(1)
		Collection:Elevate()
		local ok, problem = pcall(function()
			local placed, total = {}, 0
			for _, m in Collection:MyUnits() do
				placed[m._stats.uuid.Value] = (placed[m._stats.uuid.Value] or 0) + 1
				total += 1
			end
			local equipped = Collection:Equipped()
			local pick, lines, slots = nil, {}, {}
			for _, slot in Data.GameplaySettings.UNIT_SLOTS do
				local cfg = State.Slots[slot]
				local uuid = equipped[slot] or equipped[tonumber(slot)]
				local u = uuid and not Collection:Unwanted(uuid) and Collection:Unit(uuid) -- unwanted ones are about to be discarded
				local data = u and Data.Units[u.unit_id]
				local anchor, where
				if data and cfg.On then anchor, where = Collection:PlaceAnchor(slot, u.unit_id) end

				if anchor and State.ShowPlacePoint then
					markers[slot] = markers[slot] or Collection:PlaceMarker(slot)
					markers[slot].Position = anchor + Vector3.new(0, 1, 0)
				elseif markers[slot] then
					markers[slot]:Destroy()
					markers[slot] = nil
				end

				if data and cfg.On then
					-- Fool's Hunt has no per-unit cap (a unique places as often as any), only the 20-unit event limit
					local unitCap = (Loader.LevelData or {}).id ~= "april2_event" and data.spawn_cap or nil
					local count, cap = placed[uuid] or 0, math.min(cfg.Max, unitCap or cfg.Max)
					local farm = Collection:IsFarm(u.unit_id)
					table.insert(lines, string.format("%s %s%s: %d/%d%s", slot, Collection:UnitName(u), Collection:PlacementTag(data), count, cap,
						anchor and (" at " .. where) or (" - " .. where)))
					-- on the enemy path copies always pack along the road edge
					local line = cfg.Mode == "Enemy path"
					local hug = line and 100 or nil
					if anchor then
						table.insert(slots, { slot = slot, uuid = uuid, u = u, data = data, count = count, cap = cap, anchor = anchor, hug = hug, line = line })
					end
					-- fewest placed goes next; with Farms First, any farm goes before any other unit
					local before = not pick or (State.FarmsFirst and farm and not pick.farm)
						or ((not State.FarmsFirst or farm == pick.farm) and count < pick.count)
					if anchor and not full[uuid] and count < cap and before then
						pick = { slot = slot, uuid = uuid, u = u, data = data, count = count, anchor = anchor, farm = farm, hug = hug, line = line }
					end
				end
			end

			-- events: stop placing once EVENT_MAX_UNITS are on the map; upgrades and abilities carry on
			local eventFull = Collection:CurrentMode() == "Event" and total >= EVENT_MAX_UNITS
			if eventFull then pick = nil end
			placePending = State.AutoPlace and not State.PlayMacro and pick ~= nil
			local note
			if not State.AutoPlace then
				note = "Auto Place is off."
			elseif State.PlayMacro then
				note = "Paused while Play Macro is on."
			elseif eventFull then
				note = string.format("Event: %d units placed - stopped.", total)
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
					local spot, key = Collection:FindSpot(pick.data, pick.anchor, bad, nil, pick.hug, pick.line)
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
					table.insert(key, string.format("%s:%d/%d%s@%.0f,%.0f~%s", s.slot, s.count, s.cap, full[s.uuid] and "F" or "", s.anchor.X, s.anchor.Z, tostring(s.hug) .. (s.line and "L" or "C")))
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

-- Show Valid Spots: every 3-stud grid spot a ground unit can stand on within 30 studs of a lane, colored by distance
-- to the road; redrawn when a lane or a unit is added
if not IS_LOBBY then task.spawn(function()
	local folder, drawn
	while not closed do
		task.wait(2)
		local points = State.ShowSpots and Collection:PathPoints() or {}
		local key = #points > 0 and (#points .. "|" .. #CollectionService:GetTagged("player_units")) or nil
		if key ~= drawn then
			drawn = key
			if folder then folder:Destroy() folder = nil end
			if key then
				folder = Collection:Instance("Folder", { Name = "VaderSpots", Parent = workspace })
				local seen = {}
				for i, p in points do
					for dx = -30, 30, 3 do
						for dz = -30, 30, 3 do
							local x, z = math.floor((p.X + dx) / 3) * 3, math.floor((p.Z + dz) / 3) * 3
							local cell = x .. "," .. z
							if not seen[cell] then
								seen[cell] = true
								local d = Collection:PathDistance(points, x, z)
								local spot = d <= 30 and Collection:PlacementSpot({}, x, p.Y, z)
								if spot then
									Collection:Instance("Part", {
										Shape = Enum.PartType.Ball, Size = Vector3.new(0.7, 0.7, 0.7), Position = spot + Vector3.new(0, 0.4, 0),
										Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
										Material = Enum.Material.Neon, Color = Color3.fromHSV(0.33 * (1 - d / 30), 0.85, 1), Parent = folder,
									})
								end
							end
						end
					end
					if i % 5 == 0 then -- spread the raycasts over frames; turned off meanwhile = stop
						task.wait()
						if closed or not State.ShowSpots then break end
					end
				end
			end
		end
	end
	if folder then folder:Destroy() end
end) end

-- who an auto-used spell goes on: true = it needs no target, nil = nobody fits yet
function Collection:SpellTarget(id)
	if Data.IngameSpells[id].apply._t == "instant" then return true end
	local maxed = {}
	for _, m in Collection:MyUnits() do
		-- never Merge money units: the farms would eat each other
		if Collection:IsMaxed(m) and not (id == "sacrifice" and Collection:IsFarm(m._stats.id.Value)) then table.insert(maxed, m) end
	end
	-- Merge needs at least one copy; the rest take any maxed unit, strongest first
	local best, bestScore = nil, id == "sacrifice" and 0 or -1
	for _, m in maxed do
		local score = m._stats.damage.Value
		if id == "sacrifice" then
			-- Merge takes every same unit in the target's range: count the non-upgraded copies there
			local pos, range = m:GetPivot().Position, m._stats.range.Value
			score = 0
			for _, other in Collection:MyUnits() do
				local p = other:GetPivot().Position
				if other ~= m and other._stats.upgrade.Value == 0 and other._stats.id.Value == m._stats.id.Value
					and Vector2.new(p.X - pos.X, p.Z - pos.Z).Magnitude <= range then
					score += 1
				end
			end
		end
		if score > bestScore then best, bestScore = m, score end
	end
	return best
end

-- a unit the Keep list keeps: Keep mode the picked ones, Discard mode the rest; nothing picked keeps every unit
function Collection:Kept(u)
	return not next(State.KeepUnits) or (State.KeepUnits[Collection:UnitName(u)] == true) == (State.KeepMode == "Keep")
end

-- Auto Keep / Discard Units: a unit the event handed out that the list says to discard (Astral Summon's are always kept)
function Collection:Unwanted(uuid)
	local u = State.AutoKeepUnits and not Collection.Summoned[uuid] and (session.collection.temporary_units or {})[uuid]
	return u and not Collection:Kept(u) or false
end

-- random-unit events: X the unwanted units and picked spells as they're handed out, cast the auto-use spells
if not IS_LOBBY then task.spawn(function()
	while not closed do
		task.wait(0.5)
		for slot, uuid in session.override_equipped_units or {} do
			-- the unit that lands where Astral Summon was just cast is the summoned one
			local cast = Collection.SummonCast[tostring(slot)]
			if cast then
				if os.clock() - cast < 10 then Collection.Summoned[uuid] = true end
				Collection.SummonCast[tostring(slot)] = nil
			end
			if Collection:Unwanted(uuid) then Collection:Invoke("delete_ingame_temporary_unit", tostring(slot)) end
		end
		for slot, id in session.ingame_spells or {} do
			local spell = Data.IngameSpells[id]
			if spell and State.AutoDiscard and State.DiscardSpells[spell.name] then
				Collection:Invoke("delete_ingame_spell", slot)
			elseif spell and State.AutoSpells and State.UseSpells[spell.name] and Collection:Money() >= math.ceil(spell.cost) then
				local target = Collection:SpellTarget(id)
				if target == true then
					Collection:Invoke("use_ingame_spell", slot)
				elseif target then
					Collection:Invoke("use_ingame_spell", slot, target)
				end
			end
		end
	end
end) end

local dungeonMatchOver = false -- a dungeon room is only picked after its match ends
if not IS_LOBBY then task.spawn(function()
	while not Loader.LevelData and not closed do task.wait(0.5) end
	if closed then return end
	local matchStart = os.time()
	local startChallenge = (Collection:RefreshChallenge() or {}).current_uuid
	local gameStarted = workspace._DATA.GameStarted
	local soldThisMatch, leaving = false, false

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
		if State.LobbyAtWave and not leaving and wave >= State.LobbyWave then
			leaving = true
			task.spawn(function()
				if Collection:TeleportDelay("Back to the lobby at wave " .. wave, function() return State.LobbyAtWave end) then
					Collection:Invoke("teleport_back_to_lobby")
				else
					leaving = false -- cancelled: the next wave tries again if it's turned back on
				end
			end)
		end
	end))

	Collection:Track(fromServer.game_finished.OnClientEvent:Connect(function(results)
		dungeonMatchOver = true
		results = type(results) == "table" and results or {}
		local stats = type(results.stats) == "table" and results.stats or {}
		local secs = math.ceil(tonumber(stats.time_taken) or 0)
		Collection:Webhook("Match results", (results.victory and "Victory" or "Defeat") .. " !", {
			"Total Gem : " .. Collection:Comma(Collection:Gems()),
			"Total XP : " .. Collection:Comma(LP._stats.player_xp.Value),
			"",
			"Map : " .. tostring(results.title or Loader.LevelData.name or Loader.LevelData.id),
			"Wave : " .. tostring(stats.waves_completed or workspace._wave_num.Value),
			"Total Time : " .. string.format("%02d:%02d", secs // 60, secs % 60),
			"Gem Earn : " .. Collection:Comma(results.gem_reward),
			"XP Earn : " .. Collection:Comma(results.xp_reward),
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
			-- Infinity Mansion: the game's own Next Room (won) / Retry (lost) button
			if Loader.LevelData._gamemode == "infinite_tower" and State.AutoMansion then
				if Collection:TeleportDelay(results.victory and "Next room" or "Retrying the room", function() return State.AutoMansion end) then
					Collection:Invoke("request_start_infinite_tower_from_game")
				end
				return
			end
			local action, vote = Collection:EndAction(results.victory)
			if not action or not Collection:TeleportDelay(action, function() return (Collection:EndAction(results.victory)) == action end) then return end
			vote()
		end)
		-- Lobby Fallback: every way on from the results screen leaves this server, so still being here Fallback After
		-- seconds past the Auto Next/Retry/Lobby turn means the vote or teleport never went through. The game's Lobby button first, then a
		-- plain Roblox teleport to the lobby, again each wait. Only while the results screen (ResultsUI) is up, and only for the
		-- latest match end; the dungeon loop picks its own room
		local matchEnd = {}
		Collection.MatchEnd = matchEnd
		task.spawn(function()
			local due, tries = os.clock() + 3 + State.TeleportDelay + State.LobbyFallbackWait, 0
			while not closed and Collection.MatchEnd == matchEnd do
				task.wait(1)
				local results = LP.PlayerGui:FindFirstChild("ResultsUI")
				if State.LobbyFallback and os.clock() >= due and results and results.Enabled
					and not (Loader.LevelData._dungeon and State.AutoDungeon) then
					tries += 1
					Collection:Notify("Stuck after the match - back to the lobby")
					if tries == 1 then
						task.spawn(Collection.Invoke, Collection, "teleport_back_to_lobby") -- a stuck server never answers
					else
						pcall(function() Services.TeleportService:Teleport(8304191830, LP) end) -- the lobby place
					end
					due = os.clock() + State.LobbyFallbackWait
				end
			end
		end)
	end))

	-- event cards: vote as soon as they're offered
	Collection:Track(fromServer.show_roguelike_options.OnClientEvent:Connect(function(_, options)
		if not State.AutoPickCards or type(options) ~= "table" then return end
		local key = Collection:PickCard(options)
		if key then
			Collection:Invoke("select_roguelike_option", key)
			Collection:Notify("Card: voted " .. tostring(options[key].title))
		end
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
		local models, taken, bad = {}, {}, {} -- bad: slot-point spots the server refused
		local homes = {} -- spawn step -> { uuid, pos } of the model it placed
		local i, tries = 1, 0
		local function advance() i, tries = i + 1, 0 end
		local function retry(why)
			tries += 1
			if tries >= 5 then
				MacroStatus:SetDesc(string.format("Step %d/%d skipped: %s", i, #steps, why))
				advance()
			end
		end
		-- Place At Auto Play Points: a free spot around the unit's slot point, placed like Auto Place does; nil when
		-- the slot has no point or no free spot, so the recorded spot is used
		local function slotPlacement(uuid, unitId)
			local equipped = Collection:Equipped()
			for _, slot in Data.GameplaySettings.UNIT_SLOTS do
				if (equipped[slot] or equipped[tonumber(slot)]) == uuid then
					local cfg, anchor = State.Slots[slot], Collection:PlaceAnchor(slot, unitId)
					if not anchor then return nil end
					local path = cfg.Mode == "Enemy path"
					local spot, key = Collection:FindSpot(Data.Units[unitId], anchor, bad, nil, path and 100 or nil, path)
					if not spot then return nil end
					local pos = spot + Vector3.new(0, Collection:UnitHalfHeight(unitId), 0)
					return CFrame.lookAt(pos, Vector3.new(anchor.X, pos.Y, anchor.Z)), key
				end
			end
		end
		-- the unit a playback spawn produced: same unit, nearest to where it was placed
		local function spawnedModel(uuid, pos)
			local t0 = os.clock()
			repeat
				local best, bestDist
				for _, m in Collection:MyUnits() do
					if not taken[m] and m._stats.uuid.Value == uuid then
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
		-- the unit a step acts on. Fusion (Vego + Carrot -> Vegito) removes both models and adds one with the caster's
		-- uuid, always where Vego stood (fusion range is the whole map): follow the nearest new unit with that uuid
		local function stepModel(index)
			local m, home = models[index], homes[index]
			if m and not m.Parent and home then
				local best, bestDist
				for _, other in Collection:MyUnits() do
					local d = (other:GetPivot().Position - home.pos).Magnitude
					if not taken[other] and other._stats.uuid.Value == home.uuid and (not bestDist or d < bestDist) then best, bestDist = other, d end
				end
				if best then
					taken[best], models[index] = true, best
					return best
				end
			end
			return m
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
			macroPending = State.PlayMacro and not State.RecordMacro and i <= #steps
			if i > #steps then
				if #steps > 0 and not finished then
					finished = true
					MacroStatus:SetDesc(loaded .. " finished (" .. #steps .. " steps)")
				end
			elseif State.PlayMacro and not State.RecordMacro then
				local step = steps[i]
				local spawnStep = step.type == "spawn" and step or steps[step.unit]
				local uuid = step.type == "spawn" and step.unit_id and Collection:MacroUnit(step.unit_id)
				local m = step.unit and stepModel(step.unit)
				-- the unit on the map, so a fused Vegito shows as Fused Hero, not the Carrot it was recorded as
				local unitId = m and m.Parent and m._stats.id.Value or spawnStep and spawnStep.unit_id
				local name = unitId and Collection:UnitName({ unit_id = unitId }) or "?"
				local function status(note)
					MacroStatus:SetDesc(string.format("Step %d/%d: %s %s - %s", i, #steps, step.type, name, note))
				end
				if step.type == "spawn" and not uuid then
					MacroStatus:SetDesc(string.format("Step %d/%d skipped: %s isn't on your team", i, #steps, name))
					advance()
				elseif step.type == "spawn" then
					local cost = session.collection:get_upgraded_unit_data(step.unit_id).cost * Core.UnitServiceCore.calculate_spawn_cost_multiplier(session)
					if Collection:Money() < cost then
						status("waiting for " .. math.ceil(cost) .. "¥")
					else
						local cf, key
						if State.MacroSlotSpots then cf, key = slotPlacement(uuid, step.unit_id) end
						cf = cf or CFrame.new(table.unpack(step.cf))
						if Collection:Invoke("spawn_unit", uuid, cf) then
							models[i] = spawnedModel(uuid, cf.Position)
							homes[i] = models[i] and { uuid = uuid, pos = models[i]:GetPivot().Position }
							advance()
						else
							if key then bad[key] = true end
							retry("server refused the spawn")
						end
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
				elseif step.type == "ability" and Collection:IsBuffUnit(m) then
					advance() -- buff units are Loop Buffs' job
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
		local pendingBuff = {} -- active id -> true while a Loop Buffs recast is scheduled, and 1s after it lands
		-- how long each buff really lasts, from the server's own buff messages: upgrades and traits change it per player
		local buffTimes = {} -- active id -> seconds
		Collection:Track(fromServer.buff_on.OnClientEvent:Connect(function(_, _, _, params)
			local caster = type(params) == "table" and params.attacker_unit
			if typeof(caster) == "Instance" and type(params.buff_time) == "number" then
				local ok, id = pcall(Core.UnitServiceCore.get_active_id, caster)
				if ok and id then buffTimes[id] = params.buff_time end
			end
		end))
		while not closed do
			task.wait(1)
			-- one error in a tick must not end the loop: Auto Upgrade would stop for the rest of the match
			local ok, problem = pcall(function()
				local note
				if not State.AutoUpgrade then
					note = "Auto Upgrade is off."
				elseif macroPending then
					note = "Waiting for the macro to finish."
				elseif State.AutoPlace and State.PlaceBeforeUpgrade and placePending then
					note = "Waiting for Auto Place to place every slot (Place Before Upgrading is on)."
				else
					-- ticked Upgrade Priority units by their row, top first; the rest after them by Upgrade Order. Only what the
					-- money covers now: while a ticked unit saves up for its next upgrade, the money goes on down the list
					local rank, best, money, waiting = {}, nil, Collection:Money(), nil
					for i, entry in State.UpgradePriority do
						if entry.on then rank[entry.id] = i end
					end
					-- Upgrade After Wave: each slot's units wait for their slot's wave
					local equipped, slotWave, wave, held = Collection:Equipped(), {}, Collection:Wave(), nil
					for _, slot in Data.GameplaySettings.UNIT_SLOTS do
						local uuid = equipped[slot] or equipped[tonumber(slot)]
						if uuid then slotWave[uuid] = State.Slots[slot].UpgradeWave end
					end
					for _, m in Collection:MyUnits() do
						local cost = Collection:UpgradeCost(m)
						local u = Collection:Unit(m._stats.uuid.Value) or {}
						-- Upgrade Only Kept: units the Keep list wouldn't keep stay as they are; Upgrade Until: none past that upgrade
						local cap = math.min(State.UpgradeUntil, u.unit_id and State.UpgradeCaps[Collection:UnitName(u)] or 13)
						local after = slotWave[m._stats.uuid.Value] or 0
						if cost and wave < after then
							held = math.min(held or after, after)
						elseif cost and m._stats.upgrade.Value < cap and not (State.UpgradeOnlyKept and u.unit_id and not Collection:Kept(u)) then
							if cost > money then
								-- the cheapest one still saving up goes next
								if not waiting or cost < waiting.cost then waiting = { model = m, cost = cost } end
							else
								local r = u.unit_id and rank[Collection:UnitName(u)] or math.huge
								local score = State.UpgradeOrder == "Strongest first" and m._stats.damage.Value
									or -cost + (State.UpgradeOrder == "Farms first" and Collection:IsFarm(m._stats.id.Value) and 1e9 or 0)
								if not best or r < best.rank or (r == best.rank and score > best.score) then
									best = { model = m, cost = cost, score = score, rank = r }
								end
							end
						end
					end
					local function name(m) return Collection:UnitName({ unit_id = m._stats.id.Value }) end
					if best then
						local level = best.model._stats.upgrade.Value + 1
						note = string.format(Collection:Invoke("upgrade_unit_ingame", best.model) and "Upgraded %s to %d (%s¥)"
							or "Server refused upgrading %s to %d (%s¥)", name(best.model), level, Collection:Comma(best.cost))
					elseif waiting then
						note = string.format("Next: %s - waiting for %s¥", name(waiting.model), Collection:Comma(waiting.cost))
					elseif held then
						note = string.format("Waiting for wave %d (Upgrade After Wave).", held)
					else
						note = "Nothing to upgrade: every placed unit is maxed or at its cap."
					end
				end
				Collection:Elevate() -- the cost checks ran game code, which strips the UI write permission
				UpgradeStatus:SetDesc(note)

				local abilityDue = State.AutoAbility and os.clock() - lastAbility > 3
				if abilityDue then lastAbility = os.clock() end
				local buffs = {} -- active id -> { time, cooldown, lastCast, loopers }: one per buff unit, read each tick
				for _, m in Collection:MyUnits() do
					local ok, activeId = pcall(Core.UnitServiceCore.get_active_id, m)
					local attack = ok and activeId and Data.Attacks[activeId]
					-- the game's own auto-active check, so a recorded ability step is a real cast, not a 3s retry
					local st = m._stats
					local since = st:FindFirstChild("last_active_cast") and tick() - st.last_active_cast.Value
					local cd = st:FindFirstChild("active_attack_cooldown")
					local ready = since and cd and cd.Value - since <= 0
					local buff = Collection:BuffOf(attack)
					if buff and since and cd then
						local g = buffs[activeId] or { time = buffTimes[activeId] or buff.time, cooldown = 0, lastCast = -math.huge, loopers = {} }
						buffs[activeId] = g
						g.cooldown = math.max(g.cooldown, cd.Value)
						g.lastCast = math.max(g.lastCast, st.last_active_cast.Value)
						-- the game's own Auto casts it the moment it's ready, so the loop leaves it be
						if not m:GetAttribute("_auto_active") then
							table.insert(g.loopers, { m = m, readyAt = st.last_active_cast.Value + cd.Value })
						end
					end
					if abilityDue and attack and ready and not buff -- buff units are Loop Buffs' job
						and not (attack.custom_client_script and attack.custom_client_script.active_start)
						and not State.AbilityIgnore[Collection:UnitName(Collection:Unit(st.uuid.Value) or {})] then
						Collection:Invoke("use_active_attack", m)
					end
				end
				-- Loop Buffs: the copies take turns spread evenly over the cooldown (4 copies of a 64s cooldown: one every 16s), so
				-- each caster still holds the last buff when it casts and every unit gets recast right around its buff ending.
				-- Never closer than half a buff apart, or casts would land on units still holding one. All timings are read live.
				local now = tick()
				for id, g in buffs do
					if State.LoopBuffs and #g.loopers > 0 and not pendingBuff[id] then
						local spacing = math.max(g.cooldown / #g.loopers, (g.time + 0.3) / 2)
						table.sort(g.loopers, function(a, b) return a.readyAt < b.readyAt end)
						local pick = g.loopers[1] -- the copy that's waited longest
						local at = math.max(g.lastCast + spacing, pick.readyAt + 0.05, now)
						if at - now < 1.2 then
							pendingBuff[id] = true
							task.delay(at - now, function()
								if not closed and State.LoopBuffs and pick.m.Parent then Collection:Invoke("use_active_attack", pick.m) end
								-- the cast can take a moment to show in last_active_cast; until then the next turn reads as due
								task.wait(1)
								pendingBuff[id] = nil
							end)
						end
					end
				end
			end)
			if not ok then
				Collection:Elevate()
				UpgradeStatus:SetDesc("Error: " .. tostring(problem))
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
	-- the lobby is the dungeon's when Join Priority reaches Dungeon Run
	local function lobbyFree() return IS_LOBBY and dungeonTurn and not Collection:InPad() end
	while not closed do
		task.wait(1)
		local dd = Collection:DungeonData()
		local res = dd._resources or {}
		local shop = dd.current_shops and dd.current_shops[1]
		if State.AutoDungeon then
			-- died or the run ended in a dungeon match: straight to the lobby, the death screen is cleared there
			if not IS_LOBBY and Loader.LevelData and Loader.LevelData._dungeon and (dd._dead or (not dd._started and dungeonMatchOver)) then
				if os.clock() - lastLeave > 20 then
					lastLeave = os.clock()
					note = dd._dead and ("Died at depth " .. tostring(dd._dead.depth_reached) .. " - back to the lobby") or "Run over - back to the lobby"
					if Collection:TeleportDelay(note, function() return State.AutoDungeon end) then
						Collection:Invoke("teleport_back_to_lobby")
					end
				end
			elseif dd._dead then
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
			elseif dd._started and (dungeonMatchOver or lobbyFree()) and os.clock() - lastEnter > 20 then
				local choice, room = Collection:PickRoom(dd)
				-- a lost room stays picked and costs a heart per retry; at 0 the run is gone
				if State.DungeonStopLastLife and dd.selected_next and (dd.selected_next.lives or 5) <= 1 then
					note = "Room " .. tostring(choice) .. ": 1 heart left - stopped, retry it yourself"
				elseif choice and Collection:TeleportDelay("Entering room " .. choice, function() return State.AutoDungeon and (dungeonMatchOver or lobbyFree()) end) then
					lastEnter = os.clock()
					note = "Entering room " .. choice .. ": " .. Collection:DescribeRoom(room)
					act("dungeon_enter_room", choice)
				end
			elseif not dd._started and State.DungeonStart and lobbyFree() and os.clock() - lastStart > 10 then
				lastStart = os.clock()
				note = "Starting a run"
				act("dungeon_start")
				if not Collection:DungeonData()._started then
					VaderUI.Options.DungeonStart:SetValue(false)
					note = "Couldn't start a run (out of Dungeon Run Keys?)"
					Collection:Notify("Dungeon: " .. note)
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

--------------------------- [[ Madoka Shop ]] ---------------------------

-- one of each picked item per pass while the day's stock lasts and the cost item covers it
task.spawn(function()
	local refused = {} -- shop key -> the shop day the server refused it; tried again after the restock
	while not closed do
		task.wait(3)
		if State.AutoMadokaShop then
			pcall(function()
				local shop = Client.MadokaShopServiceClient
				local bought = (session.profile_data.madoka_shop_data or {}).bought_items or {}
				for key, entry in shop.shop_items_for_sale or {} do
					local cost = entry.item_cost
					local have = session.inventory:get_number_of_owned_item(cost.item_id) or 0
					if State.MadokaShopItems[itemName(entry.id)] and refused[key] ~= shop.madoka_shop_interval
						and (entry.stock or 0) > (bought[key] or 0) and have >= cost.amount then
						Collection:Invoke("buy_madoka_shop_item", key, "1")
						task.wait(1)
						if (session.inventory:get_number_of_owned_item(cost.item_id) or 0) < have then
							Collection:Notify("Bought " .. itemName(entry.id))
						else
							refused[key] = shop.madoka_shop_interval
						end
					end
				end
			end)
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
					-- two summons at once when gems and storage cover both: their reveals overlap, 20 a round on x10
					local calls = (Collection:Gems() - cost * 2 >= State.KeepGems and count + n * 2 <= capacity) and 2 or 1
					local beforeGems, before = Collection:Gems(), {}
					for uuid in Collection:Owned() do before[uuid] = true end
					for _ = 1, calls do task.spawn(Collection.Invoke, Collection, "buy_from_banner", State.Banner, payArg) end
					local t0, got = os.clock(), 0
					repeat
						task.wait(0.25)
						got = 0
						for uuid in Collection:Owned() do if not before[uuid] then got += 1 end end
					until got >= n * calls or os.clock() - t0 > 8 or closed
					if got == 0 and Collection:Gems() == beforeGems then
						stop("Summon didn't go through (banner currency, storage or cooldown).")
					else
						pulls += got
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
						Collection:SkipSummonReveal()
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
-- Validates every known value before applying any. only = a set of ids to take, the rest are ignored; returns how
-- many were applied
function Collection:ApplyOptions(options, only)
	local pending = {}
	-- older builds had one "When Match Ends" dropdown (EndAction); its pick turns into the toggles that replaced it
	local oldEnd = type(options.EndAction) == "table"
		and ({ Replay = { "AutoRetry" }, ["Next Stage"] = { "AutoNext", "AutoRetry" }, Lobby = { "AutoLobby" } })[options.EndAction.Value]
	if oldEnd and options.AutoLobby == nil and options.AutoRetry == nil and options.AutoNext == nil then
		for _, id in oldEnd do options[id] = { Type = "Toggle", Value = true } end
	end
	-- Validate every known value before applying any callbacks.
	for id, saved in pairs(options) do
		local option = VaderUI.Options[id]
		if option and (not only or only[id]) then
			-- a value this build can't read (saved by another build) keeps its default; the rest still loads
			pcall(function()
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
						if type(value) == "string" then value = { [value] = true } end -- older builds saved one pick
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
			end)
		end
	end
	-- Restore enabling toggles last so callbacks see restored parameters.
	for _, item in ipairs(pending) do
		if item.Option.Type ~= "Toggle" then item.Option:SetValue(item.Value, item.Mode) end
	end
	for _, item in ipairs(pending) do
		if item.Option.Type == "Toggle" then item.Option:SetValue(item.Value) end
	end
	return #pending
end
function Collection:LoadProfile()
	if not canPersist then return false, "Required file APIs are unavailable." end
	restoring = true
	local ok, problem = pcall(function()
		if not isfile(profilePath) then return end
		local data = HttpService:JSONDecode(readfile(profilePath))
		assert(type(data) == "table" and data.Version == 1 and type(data.Options) == "table", "Invalid config format")
		Collection:ApplyOptions(data.Options)
	end)
	restoring = false
	profileReady = ok
	if ok then lastSaved = nil end
	return ok, problem
end

local AFK = Tabs.Settings:AddSection("Anti-AFK")
AFK:AddToggle("AntiAFK", {
	Title = "Anti-AFK", Default = true,
	Description = "No idle kick.",
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
	Description = "Copies the invite.",
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
