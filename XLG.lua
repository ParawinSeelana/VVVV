---------------------------------------------- [ Anime Mysterious - vaderhug hub ] ----------------------------------------------
-- Lobby: party, auto join, summon, units, missions, shop.
-- Match: vote / speed / spawn / upgrade automation and record-and-play macros.
-- Queues itself on every teleport, so it follows you lobby -> match -> lobby.

local Debug = true
repeat task.wait() until game:IsLoaded()
local GlobalEnv = getgenv()

---------------------------------------------- [ Prepare Project ] ----------------------------------------------

local Collection = {}
local Party = {}
local Play = {}
local Summon = {}
local Claim = {}
local Shop = {}
local Units = {}
local Macro = {}
local Profile = {} -- config save/load, filled in under [[ Config ]]
local Challenge = {}

local Services = setmetatable({}, {
    __index = function(_, k)
        return game:GetService(k)
    end
})

local Players = Services.Players
local ReplicatedStorage = Services.ReplicatedStorage
local HttpService = Services.HttpService
local LocalPlayer = Players.LocalPlayer

-- Anime Mysterious' universe. Place ids can move with game updates, so they're only hints:
-- the lobby is recognised by its remotes, and the match place id is read from the game's Play button.
Collection.GameId = 10116272705
Collection.LobbyPlace = 117949143041402
Collection.MatchPlace = 97246719761307 -- fallback for Collection:FindMatchPlace()
Collection.SelfFile = "AnimeMys_Hub.lua" -- this file, in the executor workspace
Collection.Folder = "Vaderhug/AnimeMys"
Collection.ConfigFile = Collection.Folder .. "/" .. LocalPlayer.Name .. ".json"

local function Log(...)
    if Debug then print("[vaderhug]", ...) end
end

---------------------------------------------- [ Exploits Variables ] ----------------------------------------------

local _queue_on_teleport = (typeof(queue_on_teleport) == "function" and queue_on_teleport)
    or (typeof(queueonteleport) == "function" and queueonteleport)
local _http_request = (typeof(request) == "function" and request)
    or (typeof(http_request) == "function" and http_request)
    or (typeof(syn) == "table" and syn.request)
local _setthreadidentity = (typeof(setthreadidentity) == "function" and setthreadidentity)
    or (typeof(setidentity) == "function" and setidentity)

--------------------------- [[ Session ]] ---------------------------

if type(GlobalEnv.vaderhug_conns) == "table" then
    for _, Connection in GlobalEnv.vaderhug_conns do
        pcall(function() Connection:Disconnect() end)
    end
end
GlobalEnv.vaderhug_conns = {}

local RunId = {}
GlobalEnv.vaderhug_run = RunId

function Collection:Track(Connection)
    table.insert(GlobalEnv.vaderhug_conns, Connection)
    return Connection
end

function Collection:RaiseIdentity()
    if _setthreadidentity then
        pcall(_setthreadidentity, 8)
    end
end

--------------------------- [[ Files ]] ---------------------------

function Collection:EnsureFolders()
    pcall(function()
        for _, Path in ipairs({ "Vaderhug", self.Folder, self.Folder .. "/Presence", self.Folder .. "/Macros" }) do
            if not isfolder(Path) then
                makefolder(Path)
            end
        end
    end)
end

function Collection:ReadJson(Path)
    local ok, Data = pcall(function()
        if not isfile(Path) then return nil end
        return HttpService:JSONDecode(readfile(Path))
    end)
    return ok and Data or nil
end

function Collection:WriteJson(Path, Data)
    pcall(function()
        writefile(Path, HttpService:JSONEncode(Data))
    end)
end

-- Where this account is right now, so alts on the same PC can follow it between lobby servers.
function Collection:WritePresence()
    self:WriteJson(self.Folder .. "/Presence/" .. LocalPlayer.Name .. ".json", {
        JobId = game.JobId,
        PlaceId = game.PlaceId,
        InLobby = self.InLobby,
        Time = os.time(),
    })
end

-- Once per server: re-running the hub here must not queue a second copy for the next teleport.
function Collection:QueueSelf()
    if not _queue_on_teleport or GlobalEnv.vaderhug_animemys_queued then return end
    GlobalEnv.vaderhug_animemys_queued = true
    pcall(_queue_on_teleport, ("task.wait(3) if isfile(%q) then loadstring(readfile(%q))() end"):format(self.SelfFile, self.SelfFile))
end

Collection:EnsureFolders()

--------------------------- [[ Place ]] ---------------------------

-- Matches run in their own place (seen: 107610426295102); anything that isn't the lobby is a match.
-- The lobby is the place that has the party remotes, whatever its id is today.
do
    local Remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
    Collection.InLobby = game.PlaceId == Collection.LobbyPlace
        or (Remotes ~= nil and Remotes:FindFirstChild("RequestJoinLobby") ~= nil)
end

-- The lobby's Play button sends TeleportRequest:FireServer(<match place>, ...) with the id written
-- into the game's PlayModule. Its handler is the function holding the "Teleporting..." text.
function Collection:FindMatchPlace()
    local GetConstants = (debug and debug.getconstants) or getconstants
    if not (GetConstants and getgc) then return nil end
    for _, Fn in ipairs(getgc(false)) do
        if type(Fn) == "function" then
            local ok, Constants = pcall(GetConstants, Fn)
            if ok and type(Constants) == "table" then
                local Marked, Id = false, nil
                for _, Value in pairs(Constants) do
                    if Value == "Teleporting..." then
                        Marked = true
                    elseif type(Value) == "number" and Value > 1e9 and Value % 1 == 0 then
                        Id = Value
                    end
                end
                if Marked and Id then return Id end
            end
        end
    end
    return nil
end

Collection.MatchPlaceSource = "fallback"
if Collection.InLobby then
    task.spawn(function()
        local ok, Found = pcall(Collection.FindMatchPlace, Collection)
        if ok and Found then
            Collection.MatchPlace = Found
            Collection.MatchPlaceSource = "read from the game's Play button"
        end
        Log("match place", Collection.MatchPlace, Collection.MatchPlaceSource)
    end)
end

if not Collection.InLobby then
    Collection:WritePresence()

    -- read before the UI exists: Version 1 config ({ Options = { SpyMatch = { Value } } }) or an older flat one
    local Saved = Collection:ReadJson(Collection.ConfigFile)
    local Spy = type(Saved) == "table" and (type(Saved.Options) == "table"
        and type(Saved.Options.SpyMatch) == "table" and Saved.Options.SpyMatch.Value or Saved.SpyMatch)
    if Spy == true then
        pcall(function()
            if isfile("claude_spy_src.lua") then
                loadstring(readfile("claude_spy_src.lua"))()
            end
        end)
    end
end

--------------------------- [[ Game References ]] ---------------------------

Collection.Remotes = {}
Collection.Modules = {}

-- Game config tables; a missing one just turns its feature off. The match place only has some
-- of them (units, items, traits, quests, capsules), so there it looks once instead of waiting.
do
    local Modules = ReplicatedStorage:WaitForChild("Modules")
    for Key, Path in pairs({
        SummonConfig = { "SummonConfig" },
        FateSummonData = { "Data", "FateSummonData" },
        UnitConfig = { "UnitConfig" },
        ItemDatabase = { "ItemDatabase" },
        QuestData = { "Data", "QuestData" },
        SpecialQuestData = { "Data", "SpecialQuestData" },
        LevelItemConfig = { "LevelMileStoneModule", "LevelItemConfig" },
        RedeemConfig = { "RedeemCodeModule", "RedeemConfig" },
        ShopConfig = { "ShopModule", "ShopConfig" },
        HalloweenEventConfig = { "HalloweenEventConfig" },
        BossEventConfig = { "BossEventConfig" },
        MerchantData = { "Data", "MerchantData" },
        TraitsData = { "Data", "TraitsData" },
        UnitLevelData = { "Data", "UnitLevelData" },
        UpgradeConfig = { "UpgradeStats", "UpgradeConfig" },
        CapsuleData = { "Data", "CapsuleData" },
        CalculateUnitsStats = { "CalculateUnitsStats" },
        GameplayMapConfig = { "Gameplay", "MapConfig" }, -- match place: map key -> name
        ChallangeData = { "Data", "ChallangeData" }, -- (sic) reset length of each challenge
    }) do
        -- only lobby modules are worth waiting for in the lobby; match-only ones would just time out
        local Wait = Collection.InLobby and Key ~= "GameplayMapConfig"
        local Loaded, Module = pcall(function()
            local Node = Modules
            for _, Name in ipairs(Path) do
                Node = Wait and Node:WaitForChild(Name, 10) or Node:FindFirstChild(Name)
            end
            return require(Node)
        end)
        Collection.Modules[Key] = Loaded and Module or nil
    end
end

if Collection.InLobby then
    local Remotes = ReplicatedStorage:WaitForChild("Remotes")
    for _, Name in ipairs({
        "RequestJoinLobby", "UpdateLobbySettings", "LeaveLobbyEvent", "UpdatePartyEvent",
        "LobbyInvite", "GetLobbyList", "GetChallengeData", "TeleportRequest",
        "SummonRequest", "GetBannerInfo",
        "ClaimQuest", "ClaimAllQuests", "SpecialQuest", "ClaimDaily", "ClaimBattlepass",
        "ClaimLevelReward", "ClaimUnitIndexReward", "RedeemCode",
        "BuyItem", "BuyHalloweenEventItem", "BuyYutaEventItem", "GetMerchantState", "SellToMerchant",
        "RerollTrait", "RerollStatRequest", "RerollAllStatsRequest", "FeedUnit", "EvolveUnitEvent",
        "RequestUpgrade", "OpenCapsule",
    }) do
        Collection.Remotes[Name] = Remotes:WaitForChild(Name, 10)
    end

    local Modules = ReplicatedStorage:WaitForChild("Modules")
    local PlayingModule = Modules:WaitForChild("PlayingModule")
    Play.MapConfig = require(PlayingModule:WaitForChild("MapConfig"))
    Play.RewardFolder = PlayingModule.MapConfig:WaitForChild("MapStageReward")
    local ok, Helper = pcall(require, PlayingModule:WaitForChild("StageUnlockHelper"))
    Play.Unlock = ok and Helper or nil
end

-- Lists the lobby tabs show (maps, shop stock, merchant wants). The lobby has the game modules and
-- writes them here; a match has none of those modules, so its lobby tabs read them back.
Collection.ListsFile = Collection.Folder .. "/LobbyLists.json"

function Collection:LobbyLists()
    if not self.InLobby and self.Lists == nil then
        self.Lists = self:ReadJson(self.ListsFile) or {}
    end
    return self.Lists or {}
end

-- The PlayerData replica (ClearedStages, PlayerLevel, ...). The game keeps it on _G.
function Collection:GetData()
    local Replica = self.Replica
    if not (Replica and type(Replica.Data) == "table") then
        Replica = nil
        pcall(function()
            local Env = getrenv and getrenv()._G
            Replica = (Env and Env.PlayerDataReplica) or _G.PlayerDataReplica
        end)
        if Replica == nil and os.clock() - (self.LastGcScan or -99) > 30 then
            self.LastGcScan = os.clock()
            for _, Value in ipairs(getgc(true)) do
                if type(Value) == "table" and type(rawget(Value, "Data")) == "table" and type(rawget(Value, "Tags")) == "table"
                    and rawget(Value.Tags, "Player") == LocalPlayer and rawget(Value.Data, "ClearedStages") ~= nil then
                    Replica = Value
                    break
                end
            end
        end
        self.Replica = Replica
    end
    return Replica and Replica.Data
end

--------------------------- [[ Play ]] ---------------------------

Play.Modes = { "Story", "Raids", "Mysterios", "Infinite", "Event" } -- "Mysterios" is the game's spelling
Play.ChallengeKinds = { "Daily", "Weekly", "Regular" }
Play.Difficulties = { "Normal", "Hard", "Nightmare" }

-- How far down the unlock chain a map is (Namek World = 0). MapConfig's own order isn't
-- progression order: Tokyo Jujutsu High sits first in Raids but needs Scepter Tower.
function Play:Depth(MapToCreate, Seen)
    self.DepthCache = self.DepthCache or {}
    if self.DepthCache[MapToCreate] then return self.DepthCache[MapToCreate] end
    Seen = Seen or {}
    if Seen[MapToCreate] then return 0 end
    Seen[MapToCreate] = true
    local Depth = 0
    for _, Map in ipairs(self.MapConfig) do
        if type(Map) == "table" and Map.MapToCreate == MapToCreate and Map.RequireMap then
            Depth = self:Depth(Map.RequireMap, Seen) + 1
            break
        end
    end
    self.DepthCache[MapToCreate] = Depth
    return Depth
end

-- Maps of one mode, easiest first.
function Play:MapsFor(Mode)
    local List = {}
    for Index, Map in ipairs(self.MapConfig) do
        if type(Map) == "table" and Map.Mode == Mode then
            table.insert(List, { Map = Map, Depth = self:Depth(Map.MapToCreate), Index = Index })
        end
    end
    table.sort(List, function(A, B)
        if A.Depth ~= B.Depth then return A.Depth < B.Depth end
        return A.Index < B.Index
    end)
    for Index, Entry in ipairs(List) do
        List[Index] = Entry.Map
    end
    return List
end

-- Furthest map and highest stage this account can play in a mode.
function Play:BestStage(Mode)
    local Data = Collection:GetData()
    if not (Data and self.Unlock) then return nil end
    local Maps = self:MapsFor(Mode)
    for Index = #Maps, 1, -1 do
        local Map = Maps[Index]
        for Stage = Map.TotalStages or 1, 1, -1 do
            local ok, Allowed = pcall(self.Unlock.CheckPlay, Data, Map.MapToCreate, Stage, Mode)
            if ok and Allowed then
                return Map, Stage
            end
        end
    end
    return nil
end

-- Maps of a mode as { Name, Stages }: from the game in the lobby, from the cache in a match.
function Play:MapList(Mode)
    if not self.MapConfig then
        return (Collection:LobbyLists().Maps or {})[Mode] or {}
    end
    local List = {}
    for _, Map in ipairs(self:MapsFor(Mode)) do
        table.insert(List, { Name = Map.Name, Stages = Map.TotalStages or 1 })
    end
    return List
end

function Play:MapNames(Mode)
    if Mode == "Challenge" then
        return table.clone(self.ChallengeKinds)
    end
    local Names = {}
    for _, Map in ipairs(self:MapList(Mode)) do
        table.insert(Names, Map.Name)
    end
    return Names
end

function Play:FindMap(Mode, Name)
    for _, Map in ipairs(self:MapsFor(Mode)) do
        if Map.Name == Name then
            return Map
        end
    end
    return nil
end

function Play:StageNames(Mode, MapName)
    local Total = 1
    for _, Map in ipairs(Mode ~= "Challenge" and self:MapList(Mode) or {}) do
        if Map.Name == MapName then
            Total = Map.Stages or 1
        end
    end
    local Names = {}
    for Stage = 1, Total do
        table.insert(Names, tostring(Stage))
    end
    return Names
end

function Play:StageRewards(MapToCreate, Stage)
    local ok, Rewards = pcall(function()
        return require(self.RewardFolder:FindFirstChild(MapToCreate))[Stage].Rewards
    end)
    return ok and Rewards or {}
end

function Play:IsCleared(Data, MapToCreate, Stage)
    local Cleared = Data and Data.ClearedStages and Data.ClearedStages[MapToCreate]
    return type(Cleared) == "table" and (Cleared[Stage] == true or Cleared[tostring(Stage)] == true)
end

-- First stage that is unlocked and not cleared yet, starting from the picked map, same mode.
function Play:NextStage(Mode, StartMap, StartStage)
    local Data = Collection:GetData()
    if not (Data and self.Unlock) then
        return StartMap, StartStage
    end

    local Maps = self:MapsFor(Mode)
    local From = table.find(Maps, StartMap) or 1
    for Index = From, #Maps do
        local Map = Maps[Index]
        for Stage = 1, Map.TotalStages or 1 do
            local ok, Unlocked = pcall(self.Unlock.IsStageUnlocked, Map.MapToCreate, Stage, Data.ClearedStages, Data.ClearedChallenges, Mode)
            if ok and Unlocked and not self:IsCleared(Data, Map.MapToCreate, Stage) then
                return Map, Stage
            end
        end
    end
    return StartMap, StartStage
end

function Play:GetChallenges()
    if self.Challenges == nil or os.clock() - (self.ChallengesAt or 0) > 60 then
        local ok, Data = pcall(function()
            return Collection.Remotes.GetChallengeData:InvokeServer()
        end)
        if ok and type(Data) == "table" then
            self.Challenges = Data
            self.ChallengesAt = os.clock()
        end
    end
    return self.Challenges
end

-- What the host should queue: the same values the game's own Play button sends.
function Play:Resolve()
    local Options = Collection.Options
    local Mode = Options.PlayMode.Value

    if Mode == "Challenge" then -- an older saved setting; challenges have their own tab now
        return nil, "Challenges moved to the Challenge tab - pick a Play mode"
    end

    local Map = self:FindMap(Mode, Options.PlayMap.Value)
    local Stage = tonumber(Options.PlayStage.Value) or 1
    if Options.BestChapter.Value then
        local Best, BestStage = self:BestStage(Mode)
        if Best then
            Map, Stage = Best, BestStage
        end
    end
    if not Map then
        return nil, "pick a map"
    end
    if Options.AutoProgress.Value and not Options.BestChapter.Value then
        Map, Stage = self:NextStage(Mode, Map, Stage)
    end

    return {
        Mode = Mode,
        MapToCreate = Map.MapToCreate,
        MapName = Map.Name,
        Stage = Stage,
        Difficulty = Options.PlayDifficulty.Value or "Normal",
        Rewards = self:StageRewards(Map.MapToCreate, Stage),
    }
end

-- Same check the server runs (map unlocked, stage order, level, event window, challenge period).
function Play:Check(Selection)
    local Data = Collection:GetData()
    if not (Data and self.Unlock) then
        return true
    end
    local ok, Allowed, Reason = pcall(self.Unlock.ValidatePlayRequest, Data, Selection.MapToCreate, Selection.Stage, Selection.Mode, Selection.Difficulty)
    if not ok or Allowed then
        return true -- on a helper error, let the server decide
    end
    return false, Reason
end

function Play:Describe(Selection)
    return ("%s - %s stage %s (%s)"):format(Selection.Mode, Selection.MapName, tostring(Selection.Stage), Selection.Difficulty)
end

--------------------------- [[ Challenge ]] ---------------------------

-- Daily / Weekly / Regular challenges run on their own schedule next to Play. Each resets on a fixed
-- clock (ChallangeData Duration: Regular 1800s = 30 min, Daily a day, Weekly a week); clearing one
-- stores that reset's index in Data.ClearedChallenges[Kind]. The lobby starts them, the match sends
-- you back to the lobby afterwards, and Play carries on from there.
Challenge.Kinds = { "Weekly", "Daily", "Regular" } -- the rarer one first when several are up
Challenge.Durations = { Weekly = 604800, Daily = 86400, Regular = 1800 }
Challenge.SessionFile = Collection.Folder .. "/Session_" .. LocalPlayer.Name .. ".json"

function Challenge:Duration(Kind)
    local Info = Collection.Modules.ChallangeData and Collection.Modules.ChallangeData[Kind]
    return Info and tonumber(Info.Duration) or self.Durations[Kind]
end

function Challenge:Period(Kind)
    return math.floor(os.time() / self:Duration(Kind))
end

function Challenge:SecondsLeft(Kind)
    local Duration = self:Duration(Kind)
    return Duration - os.time() % Duration
end

function Challenge:Cleared(Kind)
    local Data = Collection:GetData()
    local Done = Data and Data.ClearedChallenges and tonumber(Data.ClearedChallenges[Kind]) or 0
    return self:Period(Kind) <= Done
end

-- Shared by the lobby and the match (same account): tries per reset, which upcoming challenges
-- the lobby found unlocked, and what was last started.
function Challenge:Session()
    if not self.SessionCache or os.clock() - (self.SessionAt or 0) > 2 then
        local Saved = Collection:ReadJson(self.SessionFile)
        self.SessionCache = type(Saved) == "table" and Saved or {}
        self.SessionAt = os.clock()
    end
    return self.SessionCache
end

function Challenge:SaveSession(Session)
    self.SessionCache, self.SessionAt = Session, os.clock()
    Collection:WriteJson(self.SessionFile, Session)
end

function Challenge:Key(Kind, Offset)
    return Kind .. ":" .. (self:Period(Kind) + (Offset or 0))
end

function Challenge:Tries(Kind)
    return tonumber((self:Session().Tries or {})[self:Key(Kind)]) or 0
end

function Challenge:AddTry(Kind)
    local Session = self:Session()
    local Tries = {}
    for _, Each in ipairs(self.Kinds) do -- drop counts from earlier resets
        local Key = self:Key(Each)
        Tries[Key] = (Session.Tries or {})[Key]
    end
    Tries[self:Key(Kind)] = (Tries[self:Key(Kind)] or 0) + 1
    Session.Tries = Tries
    self:SaveSession(Session)
end

-- Lobby: room settings for a challenge, built like the game's challenge card does it.
function Challenge:Selection(Kind)
    local Data = Play:GetChallenges()
    local Info = Data and Data[Kind]
    if not Info then return nil, "no " .. Kind .. " challenge data" end
    local Rewards = { Items = {} }
    for _, Reward in ipairs(Info.Rewards or {}) do
        if Reward.Id == "Coins" then
            Rewards.Coins = Reward.Amount
        elseif Reward.Id == "Gems" then
            Rewards.Gems = Reward.Amount
        else
            table.insert(Rewards.Items, { Chance = 100, Id = Reward.Id, Count = Reward.Amount })
        end
    end
    return {
        Mode = Kind .. "Challenge",
        MapToCreate = Info.MapToCreate,
        MapName = ("%s Challenge (%s)"):format(Kind, tostring(Info.MapName)),
        Stage = Info.StageName,
        Difficulty = "Nightmare",
        Rewards = Rewards,
        ChallengeKind = Kind,
    }
end

-- Lobby: is this map/stage unlocked, ignoring whether this reset's challenge is already cleared.
function Challenge:Unlocked(MapToCreate, Stage, Kind)
    local Data = Collection:GetData()
    if not (Data and Play.Unlock) then return true end
    local Fresh = setmetatable({ ClearedChallenges = {} }, { __index = Data })
    local ok, Allowed, Reason = pcall(Play.Unlock.CheckPlay, Fresh, MapToCreate, Stage, Kind .. "Challenge")
    if not ok then return true end
    return Allowed == true, Reason
end

-- Why a picked challenge can't run right now, or nil when it can. A match can't check unlocks,
-- so it uses what the lobby worked out for this reset's challenge (Playable).
function Challenge:Block(Kind)
    if not Collection.Options.ChallengePick.Value[Kind] then return "off" end
    if self:Cleared(Kind) then
        return "done, resets in " .. Collection:FormatTime(self:SecondsLeft(Kind))
    end
    local Tries = self:Tries(Kind)
    if Tries >= Collection.Options.ChallengeTries.Value then
        return ("lost %d tries, resets in %s"):format(Tries, Collection:FormatTime(self:SecondsLeft(Kind)))
    end
    if Collection.InLobby then
        local Selection, Why = self:Selection(Kind)
        if not Selection then return Why end
        local Unlocked, Reason = self:Unlocked(Selection.MapToCreate, Selection.Stage, Kind)
        if not Unlocked then return "locked: " .. tostring(Reason) end
    elseif (self:Session().Playable or {})[self:Key(Kind)] == false then
        return "locked"
    end
    return nil
end

-- The challenge to run next: (Selection, Kind) in the lobby, (true, Kind) in a match, or nil.
function Challenge:Next()
    if not Collection.Options.AutoChallenge.Value then return nil end
    for _, Kind in ipairs(self.Kinds) do
        if not self:Block(Kind) then
            if Collection.InLobby then
                return self:Selection(Kind), Kind
            end
            return true, Kind
        end
    end
    return nil
end

-- Lobby, every 30s: which challenge each kind rolls this reset and next (the game picks them from
-- the clock), and whether it's unlocked; a match reads that to decide if it's worth leaving.
function Challenge:RememberUnlocks()
    if not (Play.Unlock and Play.Unlock.GetChallenge) then return end
    local Session = self:Session()
    local Playable = {}
    for _, Kind in ipairs(self.Kinds) do
        for Offset = 0, 1 do
            local ok, Pick = pcall(Play.Unlock.GetChallenge, Kind, Offset)
            if ok and type(Pick) == "table" then
                Playable[self:Key(Kind, Offset)] = (self:Unlocked(Pick.MapToCreate, Pick.Stage, Kind))
            end
        end
    end
    Session.Playable = Playable
    self:SaveSession(Session)
end

function Challenge:Describe()
    local Data = Collection.InLobby and Play:GetChallenges() or nil
    local Lines = {}
    for _, Kind in ipairs({ "Regular", "Daily", "Weekly" }) do
        local Info = Data and Data[Kind]
        local Where = Info and (" - %s stage %s"):format(tostring(Info.MapName), tostring(Info.StageName)) or ""
        table.insert(Lines, ("%s%s: %s"):format(Kind, Where, self:Block(Kind) or "ready"))
    end
    if not Collection.Options.AutoChallenge.Value then
        table.insert(Lines, "Auto challenge is off")
    end
    return table.concat(Lines, "\n")
end

function Challenge:Refresh()
    if Collection.InLobby and Collection:Due("ChallengeUnlocks", 30) then
        pcall(self.RememberUnlocks, self)
    end
    Collection:SetPara("ChallengeStatus", self:Describe())
end

--------------------------- [[ Party ]] ---------------------------

Party.MaxPlayers = 5
Party.SharedFile = Collection.Folder .. "/Party.json"
Party.Ready = false   -- set after saved options are loaded
Party.Applying = false

function Party:Reset()
    self.InRoom = false      -- host: our room exists
    self.InParty = false     -- member: we are in the host's room
    self.RoomPlayers = {}
    self.SettingsKey = nil
    self.WaitSince = nil
    self.AllInSince = nil
    self.StartedAt = nil
    self.ForceStart = false
    self.LastInvite = {}
    self.LastKick = {}
    self.LastJoin = 0
    self.LastVerify = os.clock()
end
Party:Reset()
Party.LastHop = 0
Party.LastPresence = 0

-- Party mode decides when it's on; otherwise Play > Auto join runs us as a one-player room.
function Party:Role()
    local Options = Collection.Options
    local Host = Options.PartyHost.Value
    if Options.PartyEnabled.Value and Host ~= nil and Host ~= "" then
        return Host == LocalPlayer.Name and "Host" or "Member"
    end
    -- a due challenge runs a room even with Auto join off
    if Options.AutoJoin.Value or Challenge:Next() then
        return "Solo"
    end
    return "Off"
end

function Party:RoomNames()
    local Set = {}
    for _, Entry in ipairs(self.RoomPlayers or {}) do
        if typeof(Entry) == "Instance" then
            Set[Entry.Name] = true
        elseif type(Entry) == "string" then
            Set[Entry] = true
        end
    end
    return Set
end

function Party:Wanted()
    local Set = {}
    local Host = Collection.Options.PartyHost.Value
    for Name, On in pairs(Collection.Options.PartyMembers.Value) do
        if On and Name ~= Host then
            Set[Name] = true
        end
    end
    return Set
end

-- Returns the room, or nil plus true when the list could not be read.
function Party:FindRoom(HostName)
    local ok, List = pcall(function()
        return Collection.Remotes.GetLobbyList:InvokeServer()
    end)
    if not ok or type(List) ~= "table" then
        return nil, true
    end
    for _, Room in ipairs(List) do
        if Room.RoomId == HostName .. "_Room" or Room.HostName == HostName then
            return Room
        end
    end
    return nil
end

function Party:Leave()
    pcall(function() Collection.Remotes.LeaveLobbyEvent:FireServer() end)
    self:Reset()
end

function Party:SetStatus(Text)
    if self.Status == Text then return end
    self.Status = Text
    Log(Text)
    Collection:RaiseIdentity()
    pcall(function() Collection.UI.Status:SetDesc(Text) end)
    pcall(function() Collection.UI.JoinStatus:SetDesc(Text) end)
end

function Party:Host()
    local Remotes = Collection.Remotes
    local Solo = self:Role() == "Solo"
    local Who = Solo and "Auto join" or "Host"
    -- a due challenge goes first; Play's pick resumes once it's done
    local Selection, Why = Challenge:Next()
    if Selection then
        Who = Selection.ChallengeKind .. " challenge"
    else
        Selection, Why = Play:Resolve()
    end
    if not Selection then
        return self:SetStatus(Who .. ": " .. Why)
    end
    local Allowed, Reason = Play:Check(Selection)
    if not Allowed then
        return self:SetStatus(Who .. ": can't play " .. Play:Describe(Selection) .. " - " .. tostring(Reason))
    end

    if not self.InRoom then
        local ok, Created, List = pcall(function()
            return Remotes.RequestJoinLobby:InvokeServer("Create")
        end)
        if not (ok and Created) then
            return self:SetStatus("Host: couldn't create a room")
        end
        self.InRoom = true
        self.RoomPlayers = type(List) == "table" and List or { LocalPlayer }
        self.SettingsKey = nil -- Create resets the room to "Selecting Map..."
        self.WaitSince = os.clock()
        self.LastVerify = os.clock()
    end

    local Key = table.concat({ Selection.Mode, Selection.MapToCreate, tostring(Selection.Stage), Selection.Difficulty }, "|")
    if self.SettingsKey ~= Key then
        Remotes.UpdateLobbySettings:FireServer(Selection.MapName, Selection.Stage, Selection.Rewards, Selection.Difficulty, Selection.MapToCreate, Selection.Mode)
        self.SettingsKey = Key
    end

    if os.clock() - self.LastVerify > 10 then
        self.LastVerify = os.clock()
        local Room, Unknown = self:FindRoom(LocalPlayer.Name)
        if Room == nil and not Unknown and #self.RoomPlayers < self.MaxPlayers then
            self.InRoom = false
            return self:SetStatus("Host: room closed, making a new one")
        end
    end

    local Wanted = Solo and {} or self:Wanted()
    local Present = self:RoomNames()

    if Collection.Options.KickStrangers.Value then
        for _, Entry in ipairs(self.RoomPlayers) do
            if typeof(Entry) == "Instance" and Entry ~= LocalPlayer and not Wanted[Entry.Name]
                and os.clock() - (self.LastKick[Entry.Name] or 0) > 3 then
                self.LastKick[Entry.Name] = os.clock()
                pcall(function() Remotes.RequestJoinLobby:InvokeServer("Kick", Entry) end)
            end
        end
    end

    local Missing = {}
    for Name in pairs(Wanted) do
        if not Present[Name] then
            table.insert(Missing, Name)
            local Member = Players:FindFirstChild(Name)
            if Member and os.clock() - (self.LastInvite[Name] or 0) > 15 then
                self.LastInvite[Name] = os.clock()
                pcall(function() Remotes.LobbyInvite:FireServer(Member) end)
            end
        end
    end
    table.sort(Missing)

    local Count = 0
    for _ in pairs(Present) do Count += 1 end
    local Summary = ("%s: %s | room %d/%d"):format(Who, Play:Describe(Selection), Count, self.MaxPlayers)

    if not (Solo or Collection.Options.AutoStart.Value or self.ForceStart) then
        return self:SetStatus(Summary .. " | auto start off")
    end
    if self.StartedAt and os.clock() - self.StartedAt < 25 then
        return self:SetStatus(Summary .. " | teleporting...")
    end

    local Timeout = Collection.Options.WaitTimeout.Value
    local Waited = os.clock() - (self.WaitSince or os.clock())
    if #Missing > 0 and not self.ForceStart and (Timeout <= 0 or Waited < Timeout) then
        self.AllInSince = nil
        local Left = Timeout > 0 and (" (%ds left)"):format(math.ceil(Timeout - Waited)) or ""
        return self:SetStatus(Summary .. " | waiting for " .. table.concat(Missing, ", ") .. Left)
    end

    -- give the last joiner a moment to settle
    self.AllInSince = self.AllInSince or os.clock()
    if os.clock() - self.AllInSince < 2 and not self.ForceStart then
        return self:SetStatus(Summary .. " | starting...")
    end

    self.ForceStart = false
    self.StartedAt = os.clock()
    local Session = Challenge:Session()
    Session.Last = { Kind = Selection.ChallengeKind and "Challenge" or "Play", Type = Selection.ChallengeKind, At = os.time() }
    Challenge:SaveSession(Session)
    Remotes.TeleportRequest:FireServer(Collection.MatchPlace, Selection.Mode, Selection.MapToCreate, Selection.Stage, Selection.Difficulty)
    self:SetStatus(Summary .. " | start sent")
end

function Party:Member()
    local Remotes = Collection.Remotes
    local Host = Collection.Options.PartyHost.Value

    if not Players:FindFirstChild(Host) then
        if Collection.Options.FollowHost.Value then
            local Presence = Collection:ReadJson(Collection.Folder .. "/Presence/" .. Host .. ".json")
            if type(Presence) == "table" and Presence.InLobby and Presence.PlaceId == game.PlaceId and Presence.JobId ~= game.JobId
                and os.time() - (Presence.Time or 0) < 60 then
                if os.clock() - self.LastHop > 30 then
                    self.LastHop = os.clock()
                    self:SetStatus("Member: hopping to " .. Host .. "'s server")
                    pcall(function()
                        Services.TeleportService:TeleportToPlaceInstance(game.PlaceId, Presence.JobId, LocalPlayer)
                    end)
                end
                return
            end
        end
        return self:SetStatus("Member: " .. Host .. " isn't in this server")
    end

    if self.InParty then
        if os.clock() - self.LastVerify > 10 then
            self.LastVerify = os.clock()
            local Room, Unknown = self:FindRoom(Host)
            if Room == nil and not Unknown and #self.RoomPlayers < self.MaxPlayers then
                self.InParty = false
            end
        end
        local Count = 0
        for _ in pairs(self:RoomNames()) do Count += 1 end
        return self:SetStatus(("Member: in %s's party (%d/%d)"):format(Host, Count, self.MaxPlayers))
    end

    if os.clock() - self.LastJoin < 3 then return end
    self.LastJoin = os.clock()

    local ok, Joined, List, _, Err = pcall(function()
        return Remotes.RequestJoinLobby:InvokeServer("Join", Host .. "_Room")
    end)
    if ok and Joined then
        self.InParty = true
        self.RoomPlayers = type(List) == "table" and List or {}
        self.LastVerify = os.clock()
        self:SetStatus("Member: joined " .. Host .. "'s party")
    elseif ok and Err == "StageLocked" then
        self:SetStatus("Member: this account hasn't unlocked the host's stage")
    else
        self:SetStatus("Member: waiting for " .. Host .. "'s room")
    end
end

function Party:Tick()
    self:PullShared()

    if os.clock() - self.LastPresence > 10 then
        self.LastPresence = os.clock()
        Collection:WritePresence()
    end

    -- switching role or host drops whatever room we were in
    local Role = self:Role()
    local Signature = Role .. "|" .. tostring(Collection.Options.PartyHost.Value)
    if Signature ~= self.Signature then
        if self.InRoom or self.InParty then
            self:Leave()
        else
            self:Reset()
        end
        self.Signature = Signature
    end

    if Role == "Off" then
        return self:SetStatus("Auto join and Party mode are off")
    elseif Role == "Host" or Role == "Solo" then
        return self:Host()
    end
    return self:Member()
end

--------------------------- [[ Party Sharing ]] ---------------------------

-- Host and members live in one file every account on this PC reads,
-- so picking a host on any account moves all of them.
function Party:PublishShared()
    if not (self.Ready and not self.Applying and Collection.Options.ShareParty.Value) then return end
    local Members = {}
    for Name, On in pairs(Collection.Options.PartyMembers.Value) do
        if On then table.insert(Members, Name) end
    end
    local Stamp = DateTime.now().UnixTimestampMillis
    self.SharedSeen = Stamp
    Collection:WriteJson(self.SharedFile, {
        Host = Collection.Options.PartyHost.Value,
        Members = Members,
        Stamp = Stamp,
        By = LocalPlayer.Name,
    })
end

function Party:PullShared()
    if not (self.Ready and Collection.Options.ShareParty.Value) then return end
    local Data = Collection:ReadJson(self.SharedFile)
    if type(Data) ~= "table" or type(Data.Stamp) ~= "number" or Data.Stamp <= (self.SharedSeen or 0) then return end
    self.SharedSeen = Data.Stamp
    self.Applying = true
    Collection:RaiseIdentity()
    pcall(function()
        if type(Data.Host) == "string" and Data.Host ~= "" then
            Collection:SetDropdown(Collection.Options.PartyHost, Data.Host)
        end
        Collection:SetDropdown(Collection.Options.PartyMembers, type(Data.Members) == "table" and Data.Members or {})
    end)
    self.Applying = false
end

--------------------------- [[ Helpers ]] ---------------------------

-- Runs Fn forever on its own thread; Fn returns how long to sleep.
function Collection:Loop(Name, Fn)
    coroutine.wrap(function()
        while Collection:IsAlive() do
            local ok, Wait = pcall(Fn)
            if not ok then
                Log(Name .. " error: " .. tostring(Wait))
                Wait = 5
            end
            task.wait(type(Wait) == "number" and Wait or 1)
        end
    end)()
end

function Collection:WaitFor(Check, Seconds)
    local Deadline = os.clock() + Seconds
    repeat
        if Check() then return true end
        task.wait(0.05)
    until os.clock() > Deadline
    return Check() and true or false
end

-- true once every Seconds per key
function Collection:Due(Key, Seconds)
    self.DueAt = self.DueAt or {}
    if os.clock() < (self.DueAt[Key] or 0) then return false end
    self.DueAt[Key] = os.clock() + Seconds
    return true
end

function Collection:SetPara(Key, Text)
    self.ParaText = self.ParaText or {}
    if self.ParaText[Key] == Text then return end
    self.ParaText[Key] = Text
    self:RaiseIdentity()
    pcall(function() self.UI[Key]:SetDesc(Text) end)
end

function Collection:Invoke(Name, ...)
    local Remote = self.Remotes[Name]
    if not Remote then return false end
    local Args = table.pack(...)
    return pcall(function()
        return Remote:InvokeServer(table.unpack(Args, 1, Args.n))
    end)
end

function Collection:Fire(Name, ...)
    local Remote = self.Remotes[Name]
    if Remote then
        local Args = table.pack(...)
        pcall(function() Remote:FireServer(table.unpack(Args, 1, Args.n)) end)
    end
end

-- Currency: Coins and Gems sit on Data; event coins sit in ItemInventory.
function Collection:Balance(Key)
    local Data = self:GetData()
    if Data then
        if Key == "Coins" or Key == "Gems" then
            return tonumber(Data[Key]) or 0
        end
        return Data.ItemInventory and tonumber(Data.ItemInventory[Key]) or 0
    end
    return tonumber(LocalPlayer:GetAttribute(Key)) or 0
end

function Collection:ItemName(Id)
    local Database = self.Modules.ItemDatabase
    local ok, Item = pcall(function()
        return (Database.GetItem and Database.GetItem(Id)) or Database.Items[Id]
    end)
    return ok and type(Item) == "table" and (Item.DisplayName or Item.Name) or tostring(Id)
end

-- "Trait Reroll (Trait)" style labels for item pickers, with the way back to the id.
function Collection:ItemLabels(List)
    local Labels, ToId = {}, {}
    for _, Item in ipairs(List or {}) do
        local Name = Item.DisplayName or self:ItemName(Item.ID)
        local Label = Name == Item.ID and Item.ID or (Name .. " (" .. Item.ID .. ")")
        table.insert(Labels, Label)
        ToId[Label] = Item.ID
    end
    return Labels, ToId
end

--------------------------- [[ Webhook ]] ---------------------------

Collection.WebhookIcon = "https://github.com/DONUT6599/ddgdhdf/blob/main/Asset_1.png?raw=true"

function Collection:Comma(Value)
    local Text = tostring(math.floor((tonumber(Value) or 0) + 0.5))
    return (Text:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^(%-?),", "%1"))
end

function Collection:FormatTime(Seconds)
    Seconds = math.floor(tonumber(Seconds) or 0)
    local Clock = ("%02d:%02d"):format(math.floor(Seconds % 3600 / 60), Seconds % 60)
    local Hours = math.floor(Seconds / 3600)
    return Hours > 0 and (Hours .. ":" .. Clock) or Clock
end

function Collection:MapDisplayName(Key)
    local Name
    pcall(function() Name = self.Modules.GameplayMapConfig.getData(Key).Name end)
    if not Name and Play.MapConfig then
        for _, Map in ipairs(Play.MapConfig) do
            if type(Map) == "table" and Map.MapToCreate == Key then Name = Map.Name end
        end
    end
    return Name or tostring(Key or "?")
end

-- Posts the match result in the VaderHug embed format.
-- Result: { Won, Map, Stage, Difficulty, Time, Exp = per-unit rows, Rewards, Stats } (EndGameEvent's args).
function Collection:SendResult(Result, Test)
    local Url = self.Options.WebhookUrl.Value or ""
    if not Url:match("^https://") then return false, "paste a webhook URL first" end
    if not _http_request then return false, "this executor has no request()" end

    local Stats = type(Result.Stats) == "table" and Result.Stats or {}
    local Exp = 0
    for _, Row in ipairs(type(Result.Exp) == "table" and Result.Exp or {}) do
        Exp += tonumber(Row.GainedExp) or 0
    end
    local Map = self:MapDisplayName(Result.Map)
    if Result.Stage then Map ..= " - Stage " .. tostring(Result.Stage) end
    if Result.Difficulty then Map ..= " (" .. tostring(Result.Difficulty) .. ")" end

    local Lines = {
        "Map : " .. Map,
        "Mobs killed : " .. self:Comma(Stats.Takedowns),
        "Total Time : " .. self:FormatTime(Result.Time),
        "Total Damage : " .. self:Comma(Stats.TotalDmg),
        "Total EXP : " .. self:Comma(Exp),
    }
    local Rewards, Given = {}, type(Result.Rewards) == "table" and Result.Rewards or {}
    if (tonumber(Given.Coins) or 0) > 0 then table.insert(Rewards, self:Comma(Given.Coins) .. " Coins") end
    if (tonumber(Given.Gems) or 0) > 0 then table.insert(Rewards, self:Comma(Given.Gems) .. " Gems") end
    for _, Item in ipairs(Given.Items or {}) do
        table.insert(Rewards, ("%sx %s"):format(tostring(Item.Count or Item.Amount or 1), self:ItemName(Item.Id)))
    end
    for _, Unit in ipairs(Given.Units or {}) do
        local Info = Summon:UnitInfo(Unit.Id)
        table.insert(Rewards, (Info and (Info.DisplayName or Info.Name) or tostring(Unit.Id)) .. (Unit.IsShiny and " (shiny)" or ""))
    end
    if #Rewards > 0 then
        table.insert(Lines, "Rewards : " .. table.concat(Rewards, ", "))
    end

    local Body = HttpService:JSONEncode({
        username = "VaderHug",
        embeds = { {
            title = (Test and "[Test] " or "") .. (Result.Won and "Victory!" or "Lost!"),
            description = table.concat(Lines, "\n"),
            color = Result.Won and 5763719 or 15548997, -- green / red
            author = { name = "Anime Mysterious" },
            footer = { text = "VaderHug", icon_url = self.WebhookIcon },
            timestamp = DateTime.now():ToIsoDate(),
            thumbnail = { url = self.WebhookIcon },
        } },
    })
    local ok, Response = pcall(_http_request, {
        Url = Url,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = Body,
    })
    local Code = ok and type(Response) == "table" and tonumber(Response.StatusCode or Response.Status) or nil
    if Code and Code >= 200 and Code < 300 then
        return true, "sent"
    end
    return false, ok and ("Discord answered " .. tostring(Code)) or tostring(Response)
end

--------------------------- [[ Summon ]] ---------------------------

Summon.Banners = { "Standard", "Fate" }
Summon.Amounts = { "1", "10", "50" }
Summon.SellKeys = { "Common", "Rare", "Epic", "Legendary", "Rare_Shiny", "Epic_Shiny", "Legendary_Shiny" }
Summon.StopRarities = { "Epic", "Legendary", "Mythic", "Tactical" }
Summon.Done = 0

function Summon:Price(Banner)
    local Config = Banner == "Fate" and Collection.Modules.FateSummonData or Collection.Modules.SummonConfig
    return Config and tonumber(Config.Price) or 50
end

function Summon:Currency(Banner)
    return Banner == "Fate" and "FateCoins" or "Gems"
end

-- Unit storage: how many more units fit (MaxStorage is 50 on a fresh account).
function Collection:FreeStorage()
    local Data = self:GetData()
    if not Data then return math.huge end
    local Max = tonumber(Data.MaxStorage) or tonumber(LocalPlayer:GetAttribute("MaxStorage")) or 50
    return Max - #(Data.Inventory or {}), Max
end

function Summon:UnitInfo(Id)
    local ok, Unit = pcall(function()
        return Collection.Modules.UnitConfig.GetUnitData(Id)
    end)
    return ok and type(Unit) == "table" and Unit or nil
end

function Summon:Step()
    local Options = Collection.Options
    if not Options.AutoSummon.Value then return 1 end

    local Banner = Options.SummonBanner.Value or "Standard"
    local Currency = self:Currency(Banner)
    local Price = self:Price(Banner)
    local Reserve = Currency == "Gems" and Options.GemReserve.Value or 0
    local Balance = Collection:Balance(Currency)
    local Amount = tonumber(Options.SummonAmount.Value) or 10

    -- can't afford the multi: drop to singles, then stop
    if Balance - Price * Amount < Reserve then
        Amount = Balance - Price >= Reserve and 1 or 0
    end
    if Amount == 0 then
        Collection:SetPara("SummonStatus", ("Out of %s: %d (keeping %d) | %d summoned this session"):format(Currency, Balance, Reserve, self.Done))
        return 10
    end

    -- every pull needs a free storage slot; a short multi drops to singles
    local Free, MaxStorage = Collection:FreeStorage()
    if Free < Amount then
        Amount = Free >= 1 and 1 or 0
    end
    if Amount == 0 then
        Collection:SetPara("SummonStatus", ("Storage full (%d/%d) - sell or feed units to make room | %d summoned this session"):format(MaxStorage - Free, MaxStorage, self.Done))
        return 10
    end

    local AutoSell = {}
    for _, Key in ipairs(self.SellKeys) do
        AutoSell[Key] = Options.SummonAutoSell.Value[Key] == true
    end

    local ok, Success, Results, _, SoldCount, SoldFor, Err = Collection:Invoke("SummonRequest", Amount, AutoSell, Banner)
    if not (ok and Success) then
        Collection:SetPara("SummonStatus", "Summon failed: " .. tostring(ok and Err or Success))
        return 5
    end
    self.Done += Amount

    local Hits = {}
    for _, Entry in ipairs(type(Results) == "table" and Results or {}) do
        local Id = type(Entry) == "table" and (Entry.Id or Entry.UnitId) or Entry
        local Shiny = type(Entry) == "table" and Entry.IsShiny == true
        local Unit = self:UnitInfo(Id)
        local Rarity = Unit and Unit.Rarity
        if (Rarity and Options.SummonStopRarity.Value[Rarity]) or (Shiny and Options.SummonStopShiny.Value) then
            table.insert(Hits, (Unit and (Unit.DisplayName or Unit.Name) or tostring(Id)) .. " [" .. tostring(Rarity) .. (Shiny and ", shiny" or "") .. "]")
        end
    end

    local Sold = (tonumber(SoldCount) or 0) > 0 and (" | auto-sold %d for %s"):format(SoldCount, tostring(SoldFor)) or ""
    Collection:SetPara("SummonStatus", ("%d summoned this session | %s left: %d%s"):format(self.Done, Currency, Collection:Balance(Currency), Sold))

    if #Hits > 0 then
        Collection:RaiseIdentity()
        Options.AutoSummon:SetValue(false)
        Collection.Library:Notify({ Title = "Summon stopped", Content = table.concat(Hits, ", "), Duration = 15 })
    end
    return Options.SummonDelay.Value
end

--------------------------- [[ Missions ]] ---------------------------

function Claim:Quests(Data, Done)
    local QuestData = Collection.Modules.QuestData
    if not QuestData then return end
    for Id, State in pairs(Data.Quests or {}) do
        local Quest = QuestData[Id]
        if Quest and Quest.Type ~= "Special" and type(State) == "table" and not State.Claimed
            and (State.Progress or 0) >= (Quest.Goal or math.huge) then
            Collection:Fire("ClaimAllQuests", "ALL") -- the game's own Claim All; skips Special
            table.insert(Done, "quests")
            return
        end
    end
end

-- Guidebook chapters: each quest is claimed on its own, then the chapter.
function Claim:Special(Data, Done)
    local Special = Collection.Modules.SpecialQuestData
    if not (Special and Special.Chapters) then return end
    if Collection:Due("SpecialSync", 300) then
        Collection:Invoke("SpecialQuest", "Sync")
    end

    local Quests = Data.Quests or {}
    local Level = tonumber(Data.PlayerLevel) or 1
    local Chapters = Data.SpecialChapters or {}
    for _, Chapter in ipairs(Special.Chapters) do
        if Level >= (Chapter.RequireLevel or 1) and Chapters[Chapter.Id] ~= true then
            for _, Quest in ipairs(Chapter.Quests or {}) do
                local State = Quests[Quest.Id]
                if type(State) == "table" and not State.Claimed and (State.Progress or 0) >= (Quest.Goal or math.huge) then
                    Collection:Fire("ClaimQuest", Quest.Id)
                    table.insert(Done, Quest.Name or Quest.Id)
                end
            end
            local ok, Finished, Total = pcall(Special.CountCompleted, Chapter, Quests)
            if ok and Total and Finished >= Total then
                Collection:Invoke("SpecialQuest", "ClaimChapter", Chapter.Id)
                table.insert(Done, Chapter.Name or Chapter.Id)
            end
        end
    end
end

-- Same "already claimed today" test the daily login screen uses.
function Claim:Daily(Data, Done)
    local Today = math.floor(os.time() / 86400)
    local Types = Data.DailyClaimedType or {}
    local Day = Data.CurrentDay or 1
    if not (Types.Free == true or Today <= (Data.FreeLastClaimEpoch or 0)) then
        local ok, Success = Collection:Invoke("ClaimDaily", "Free", Day)
        if ok and Success then table.insert(Done, "daily") end
    end
    local Vip = Data.OwnedGamePasses and Data.OwnedGamePasses.VIP == true
    if Vip and not (Types.Vip == true or Today <= (Data.VipLastClaimEpoch or 0)) then
        local ok, Success = Collection:Invoke("ClaimDaily", "Vip", Day)
        if ok and Success then table.insert(Done, "daily VIP") end
    end
end

function Claim:Levels(Data, Done)
    local Config = Collection.Modules.LevelItemConfig
    if not (Config and Config.GetSortedLevels) then return end
    local Level = tonumber(Data.PlayerLevel) or 1
    local Claimed = Data.ClaimedLevelRewards or {}
    for _, Milestone in ipairs(Config.GetSortedLevels()) do
        if Milestone <= Level and not Claimed[tostring(Milestone)] then
            local ok, Success = Collection:Invoke("ClaimLevelReward", Milestone)
            if ok and Success then table.insert(Done, "level " .. Milestone) end
        end
    end
end

function Claim:Step()
    local Options = Collection.Options
    if not Options.AutoClaim.Value then return 2 end
    local Data = Collection:GetData()
    if not Data then return 5 end

    local Done = {}
    if Options.ClaimQuests.Value then
        self:Quests(Data, Done)
        self:Special(Data, Done)
    end
    if Options.ClaimDaily.Value then
        self:Daily(Data, Done)
    end
    if Options.ClaimRewards.Value then
        self:Levels(Data, Done)
        -- claim-all for both of these; nothing to claim is a no-op on the server
        if Collection:Due("Battlepass", 300) then Collection:Fire("ClaimBattlepass", nil, nil, true) end
        if Collection:Due("UnitIndex", 300) then Collection:Invoke("ClaimUnitIndexReward", "All") end
    end

    if #Done > 0 then
        self.Last = os.date("%H:%M") .. " claimed " .. table.concat(Done, ", ")
    end
    Collection:SetPara("ClaimStatus", self.Last or "Nothing to claim yet")
    return 30
end

-- Active public codes; CC1-style codes locked to a role are skipped.
function Claim:RedeemAll()
    local Config = Collection.Modules.RedeemConfig
    local Lines = {}
    for Code, Info in pairs(Config and Config.Codes or {}) do
        if type(Info) == "table" and Info.Active ~= false and Info.RequireID == nil then
            local ok, Success, Message = Collection:Invoke("RedeemCode", Code)
            table.insert(Lines, Code .. ": " .. ((ok and Success) and "ok" or tostring(Message or Success or "failed")))
        end
    end
    table.sort(Lines)
    return Lines
end

--------------------------- [[ Shop ]] ---------------------------

-- Each shop: its items, the PurchasedItems bucket, the currency and the buy call.
Shop.Shops = {
    {
        Key = "Gold", Title = "Coin shop", Currency = "Coins", Bucket = "Coins", Hourly = true,
        Items = function() return Collection.Modules.ShopConfig and Collection.Modules.ShopConfig.GoldShopItems end,
        Buy = function(Id, Amount) return Collection:Invoke("BuyItem", Id, Amount, "Coins") end,
    },
    {
        Key = "Gems", Title = "Gem shop", Currency = "Gems", Bucket = "Gems", Hourly = true,
        Items = function() return Collection.Modules.ShopConfig and Collection.Modules.ShopConfig.GemsShopItems end,
        Buy = function(Id, Amount) return Collection:Invoke("BuyItem", Id, Amount, "Gems") end,
    },
    {
        Key = "Halloween", Title = "Halloween shop", Currency = "HalloweenCoin",
        Bucket = function() return Collection.Modules.HalloweenEventConfig and Collection.Modules.HalloweenEventConfig.EventName or "HalloweenEvent" end,
        Items = function() return Collection.Modules.HalloweenEventConfig and Collection.Modules.HalloweenEventConfig.ShopItems end,
        Buy = function(Id, Amount) return Collection:Invoke("BuyHalloweenEventItem", Id, Amount) end,
    },
    {
        Key = "Fate", Title = "Fate event shop", Currency = "FateCoins",
        Bucket = function() return Collection.Modules.BossEventConfig and Collection.Modules.BossEventConfig.EventName or "BossEvent" end,
        Items = function() return Collection.Modules.BossEventConfig and Collection.Modules.BossEventConfig.ShopItems end,
        Buy = function(Id, Amount) return Collection:Invoke("BuyYutaEventItem", Id, Amount) end,
    },
}

function Shop:StockLeft(Data, Info, Item)
    local ShopData = Data.ShopData
    if not ShopData then return Item.MaxStock end
    -- coin/gem shops restock every hour; a stale cycle means full stock
    if Info.Hourly then
        local Cycle = math.floor(os.time() / ((Collection.Modules.ShopConfig and Collection.Modules.ShopConfig.RestockDuration) or 3600))
        if ShopData.LastCycle and ShopData.LastCycle < Cycle then return Item.MaxStock end
    end
    local Bucket = type(Info.Bucket) == "function" and Info.Bucket() or Info.Bucket
    local Bought = ShopData.PurchasedItems and ShopData.PurchasedItems[Bucket]
    return math.max(0, (Item.MaxStock or 0) - (Bought and Bought[Item.ID] or 0))
end

function Shop:BuyFrom(Info, Data, Done)
    local Picked = Collection.Options["Shop" .. Info.Key].Value
    local ToId = self.LabelToId[Info.Key] or {}
    local Reserve = Info.Currency == "Gems" and Collection.Options.GemReserve.Value or 0
    for Label, On in pairs(Picked) do
        local Id = ToId[Label]
        local Item
        for _, Entry in ipairs(Info.Items() or {}) do
            if Entry.ID == Id then Item = Entry break end
        end
        if On and Item and (Item.Price or 0) > 0 then
            if Info.Currency == "Coins" then Reserve = Collection.Options.CoinReserve.Value end
            local Afford = math.floor((Collection:Balance(Info.Currency) - Reserve) / Item.Price)
            local Amount = math.min(self:StockLeft(Data, Info, Item), Afford)
            if Amount > 0 then
                local ok, Success, Err = Info.Buy(Item.ID, Amount)
                if ok and Success then
                    table.insert(Done, ("%dx %s"):format(Amount, Label))
                else
                    Log("buy failed", Item.ID, tostring(ok and Err or Success))
                end
            end
        end
    end
end

-- The merchant buys materials off you for Coins; quotas reset hourly.
function Shop:SellToMerchant(Done)
    local Picked = {}
    for Label, On in pairs(Collection.Options.MerchantSell.Value) do
        local Id = (self.LabelToId.Merchant or {})[Label]
        if On and Id then Picked[Id] = true end
    end
    if next(Picked) == nil then return end
    local ok, State = Collection:Invoke("GetMerchantState")
    if not (ok and type(State) == "table" and type(State.Items) == "table") then return end
    for _, Item in ipairs(State.Items) do
        if Picked[Item.ID] then
            local Amount = math.min(tonumber(Item.Owned) or 0, tonumber(Item.RemainingQuota) or 0)
            if Amount > 0 then
                local Sold, Success = Collection:Invoke("SellToMerchant", Item.ID, Amount)
                if Sold and Success then
                    table.insert(Done, ("sold %dx %s"):format(Amount, Item.DisplayName or Item.ID))
                end
            end
        end
    end
end

-- The "Mysterious" panel: permanent battle stats bought with Coins (cost and max from UpgradeConfig).
Shop.UpgradeStats = {
    { Key = "MaxMoney", Label = "Maximum Yen" },
    { Key = "MoneyGen", Label = "Yen Generation" },
    { Key = "TowerHealth", Label = "Tower Health" },
}

function Shop:UpgradeLevel(Data, Key)
    return tonumber(Data and Data.Upgrades and Data.Upgrades[Key]) or 1
end

-- One level per tick, cheapest picked stat first, each one confirmed before the next.
function Shop:UpgradeStep()
    local Options = Collection.Options
    local Config = Collection.Modules.UpgradeConfig
    local Data = Collection:GetData()
    if not (Config and Config.GetCost and Data) then return 5 end

    local Cap = Options.UpgradeMaxLevel.Value
    local Coins = Collection:Balance("Coins") - Options.CoinReserve.Value
    local Pick, PickCost, Lines = nil, math.huge, {}
    for _, Stat in ipairs(self.UpgradeStats) do
        local Level = self:UpgradeLevel(Data, Stat.Key)
        local Max = math.min(Cap, Config.MaxStats and Config.MaxStats[Stat.Key] or 50)
        local Cost = Config.GetCost(Stat.Key, Level)
        table.insert(Lines, ("%s: level %d / %d%s"):format(Stat.Label, Level, Max, Level < Max and (" - next costs " .. Cost) or " - done"))
        if Options.UpgradeStatsPick.Value[Stat.Label] and Level < Max and Cost <= Coins and Cost < PickCost then
            Pick, PickCost = Stat, Cost
        end
    end
    local Summary = table.concat(Lines, "\n")

    if not Options.AutoUpgrade.Value then
        Collection:SetPara("UpgradeStatus", Summary)
        return 2
    end
    if not Pick then
        Collection:SetPara("UpgradeStatus", Summary .. "\nWaiting for Coins (or everything picked is at the cap)")
        return 3
    end

    local Before = self:UpgradeLevel(Data, Pick.Key)
    Collection:Fire("RequestUpgrade", Pick.Key)
    if not Collection:WaitFor(function() return self:UpgradeLevel(Collection:GetData(), Pick.Key) > Before end, 3) then
        Collection:SetPara("UpgradeStatus", Summary .. "\nThe server didn't take the " .. Pick.Label .. " upgrade - trying again in 30s")
        return 30
    end
    Collection:SetPara("UpgradeStatus", Summary)
    return 0.3
end

function Shop:OpenCapsules(Done)
    for Label, On in pairs(Collection.Options.CapsulePick.Value) do
        local Id = (self.LabelToId.Capsule or {})[Label]
        local Have = Id and Collection:Balance(Id) or 0
        if On and Have > 0 then
            -- a capsule can drop a unit, so never open more than storage has room for
            local Free, MaxStorage = Collection:FreeStorage()
            if Free <= 0 then
                table.insert(Done, ("capsules waiting: storage full (%d/%d)"):format(MaxStorage, MaxStorage))
                return
            end
            local Amount = math.min(Have, 100, Free) -- 100 is the game's own cap per open
            local ok, Result = Collection:Invoke("OpenCapsule", Id, Amount)
            if ok and type(Result) == "table" and Result.Success then
                table.insert(Done, ("opened %dx %s"):format(Amount, Label))
            else
                Log("capsule open failed", Id, ok and type(Result) == "table" and tostring(Result.Message) or tostring(Result))
            end
        end
    end
end

function Shop:Step()
    local Options = Collection.Options
    if not (Options.AutoBuy.Value or Options.AutoMerchant.Value or Options.AutoCapsule.Value) then
        return 2
    end
    local Data = Collection:GetData()
    if not Data then return 5 end

    local Done = {}
    if Options.AutoBuy.Value then
        for _, Info in ipairs(self.Shops) do
            if Options["Shop" .. Info.Key] then
                self:BuyFrom(Info, Data, Done)
            end
        end
    end
    if Options.AutoMerchant.Value then
        self:SellToMerchant(Done)
    end
    if Options.AutoCapsule.Value then
        self:OpenCapsules(Done)
    end

    if #Done > 0 then
        self.Last = os.date("%H:%M") .. " " .. table.concat(Done, ", ")
    end
    Collection:SetPara("ShopStatus", self.Last or "Nothing bought yet")
    return 60
end

--------------------------- [[ Units ]] ---------------------------

Units.Grades = { "D", "C", "B", "A", "S", "SS", "SSS", "神" } -- worst to best
Units.Stats = { "Attack", "Health", "Speed", "Cooldown", "Range" }
Units.RarityRank = { Mythic = 1, Legendary = 2, Epic = 3, Rare = 4 }
Units.LabelToUUID = {}
Units.TraitRolls = 0
Units.PotentialRolls = 0

function Units:List()
    local Data = Collection:GetData()
    return Data and Data.Inventory or {}
end

function Units:Name(Unit)
    local Info = Summon:UnitInfo(Unit.UnitId)
    return Info and (Info.DisplayName or Info.Name) or tostring(Unit.UnitId)
end

-- Stable across level-ups so the saved pick still matches: name, shiny mark, short id.
function Units:Label(Unit)
    return ("%s%s #%s"):format(self:Name(Unit), Unit.IsShiny and " (shiny)" or "", tostring(Unit.UUID):sub(1, 6))
end

function Units:Refresh()
    local Labels, Map = {}, {}
    for _, Unit in ipairs(self:List()) do
        if Unit.UUID then
            local Label = self:Label(Unit)
            table.insert(Labels, Label)
            Map[Label] = Unit.UUID
        end
    end
    table.sort(Labels)
    self.LabelToUUID = Map
    local Key = table.concat(Labels, "|")
    if Key ~= self.ListKey then
        self.ListKey = Key
        Collection:RaiseIdentity()
        local Option = Collection.Options.UnitPick
        local Current = Option.Value
        Option:SetValues(Labels)
        if Current and not Map[Current] then
            Option:SetValue(nil)
        end
    end
end

function Units:Selected()
    local UUID = self.LabelToUUID[Collection.Options.UnitPick.Value or ""]
    if not UUID then return nil end
    for _, Unit in ipairs(self:List()) do
        if Unit.UUID == UUID then return Unit end
    end
    return nil
end

function Units:GradeRank(Grade)
    return table.find(self.Grades, Grade) or 0
end

function Units:TraitName(Key)
    local Info = Collection.Modules.TraitsData and Collection.Modules.TraitsData.TraitsData[Key]
    return Info and Info.TraitDisplayName or tostring(Key or "None")
end

-- Picker labels for traits, best rarity first.
function Units:TraitLabels()
    local Entries = {}
    for Key, Info in pairs(Collection.Modules.TraitsData and Collection.Modules.TraitsData.TraitsData or {}) do
        if Key ~= "None" and type(Info) == "table" then
            table.insert(Entries, { Key = Key, Label = ("%s (%s)"):format(Info.TraitDisplayName or Key, Info.RarityName or "?"), Rank = self.RarityRank[Info.RarityName] or 9 })
        end
    end
    table.sort(Entries, function(A, B)
        if A.Rank ~= B.Rank then return A.Rank < B.Rank end
        return A.Key < B.Key
    end)
    local Labels, ToKey = {}, {}
    for _, Entry in ipairs(Entries) do
        table.insert(Labels, Entry.Label)
        ToKey[Entry.Label] = Entry.Key
    end
    return Labels, ToKey
end

function Units:Describe(Unit)
    if not Unit then return "Pick a unit" end
    local Potential = {}
    for _, Stat in ipairs(self.Stats) do
        local Entry = Unit.Potential and Unit.Potential[Stat]
        table.insert(Potential, Stat .. " " .. tostring(Entry and Entry.Grade or "-"))
    end
    local MaxLevel = self:MaxLevel(Unit)
    local Trait = self:TraitName(Unit.Trait) .. (Unit.SubTrait and Unit.SubTrait ~= "None" and (" + " .. self:TraitName(Unit.SubTrait)) or "")
    local Ready, Why = self:CanEvolve(Unit)
    return ("Lv %d/%d | Trait: %s%s\nPotential: %s\nEvolve: %s"):format(
        Unit.Level or 1, MaxLevel, Trait, Unit.Locked and " | locked" or "",
        table.concat(Potential, ", "), Ready and "ready" or tostring(Why))
end

function Units:Stop(Option, Title, Text)
    Collection:RaiseIdentity()
    Collection.Options[Option]:SetValue(false)
    Collection:SetPara("UnitStatus", Text)
    Collection.Library:Notify({ Title = Title, Content = Text, Duration = 10 })
end

-- Your own stop lists from the game's reroll screens (Data.Config): TraitConfig marks traits to
-- stop on, RestatsConfig marks potential grades to keep (S, SS, SSS and 神 by default).
function Units:GameStops(Kind)
    local Set = {}
    if Collection.Options.UseGameStops.Value then
        local Data = Collection:GetData()
        for Key, On in pairs(Data and Data.Config and Data.Config[Kind] or {}) do
            if On == true then Set[Key] = true end
        end
    end
    return Set
end

-- The first stat whose grade is on the keep list, so we never roll it away.
function Units:KeptStat(Potential, OnlyStat)
    local Keep = self:GameStops("RestatsConfig")
    for _, Name in ipairs(OnlyStat and { OnlyStat } or self.Stats) do
        local Entry = type(Potential) == "table" and Potential[Name]
        if Entry and Keep[Entry.Grade] then
            return Name, Entry.Grade
        end
    end
    return nil
end

function Units:TraitStep(Unit)
    local Targets = self:GameStops("TraitConfig")
    for Label, On in pairs(Collection.Options.TraitTargets.Value) do
        local Key = self.TraitToKey[Label]
        if On and Key then Targets[Key] = true end
    end
    if next(Targets) == nil then
        return Collection:SetPara("UnitStatus", "Trait roll: pick at least one trait to stop on")
    end
    if Targets[Unit.Trait] or Targets[Unit.SubTrait] then
        return self:Stop("AutoTrait", "Trait roll done", self:Name(Unit) .. " has " .. self:TraitName(Targets[Unit.Trait] and Unit.Trait or Unit.SubTrait))
    end
    if Collection:Balance("Trait") < 1 then
        return self:Stop("AutoTrait", "Trait roll stopped", "Out of Trait Reroll items after " .. self.TraitRolls .. " rolls")
    end

    local ok, Success, Trait, SubTrait = Collection:Invoke("RerollTrait", Unit.UUID)
    if not (ok and Success) then
        return Collection:SetPara("UnitStatus", "Trait roll failed: " .. tostring(ok and Trait or Success))
    end
    self.TraitRolls += 1
    if Targets[Trait] or Targets[SubTrait] then
        return self:Stop("AutoTrait", "Trait roll done", ("%s rolled %s after %d rolls"):format(self:Name(Unit), self:TraitName(Targets[Trait] and Trait or SubTrait), self.TraitRolls))
    end
    Collection:SetPara("UnitStatus", ("Trait roll %d: %s (%d Trait items left)"):format(self.TraitRolls, self:TraitName(Trait), Collection:Balance("Trait")))
end

function Units:PotentialGood(Potential)
    local Options = Collection.Options
    local Target = self:GradeRank(Options.PotentialGrade.Value)
    local Stat = Options.PotentialStat.Value
    if type(Potential) ~= "table" then return false end
    if Stat ~= "All" then
        return self:GradeRank(Potential[Stat] and Potential[Stat].Grade) >= Target
    end
    local Count = 0
    for _, Name in ipairs(self.Stats) do
        if self:GradeRank(Potential[Name] and Potential[Name].Grade) >= Target then Count += 1 end
    end
    return Count >= Options.PotentialCount.Value
end

function Units:PotentialStep(Unit)
    local Stat = Collection.Options.PotentialStat.Value
    if self:PotentialGood(Unit.Potential) then
        return self:Stop("AutoPotential", "Potential roll done", self:Name(Unit) .. " reached the target")
    end
    -- rolling would replace a grade on your keep list (All rerolls every stat)
    local Kept, Grade = self:KeptStat(Unit.Potential, Stat ~= "All" and Stat or nil)
    if Kept then
        return self:Stop("AutoPotential", "Potential roll stopped",
            ("%s's %s is %s, which is on your in-game keep list - not rerolling it"):format(self:Name(Unit), Kept, Grade))
    end
    local Item = Stat == "All" and "StatRerollAll" or "StatReroll"
    if Collection:Balance(Item) < 1 then
        return self:Stop("AutoPotential", "Potential roll stopped", "Out of " .. Item .. " after " .. self.PotentialRolls .. " rolls")
    end

    local ok, Success, Updated
    if Stat == "All" then
        ok, Success, Updated = Collection:Invoke("RerollAllStatsRequest", Unit.UUID)
    else
        ok, Success, Updated = Collection:Invoke("RerollStatRequest", Unit.UUID, Stat)
    end
    if not (ok and Success) then
        return Collection:SetPara("UnitStatus", "Potential roll failed: " .. tostring(ok and Updated or Success))
    end
    self.PotentialRolls += 1
    local Potential = type(Updated) == "table" and Updated.Potential or Unit.Potential
    if self:PotentialGood(Potential) then
        return self:Stop("AutoPotential", "Potential roll done", ("%s reached the target after %d rolls"):format(self:Name(Unit), self.PotentialRolls))
    end
    local Hit, HitGrade = self:KeptStat(Potential, Stat ~= "All" and Stat or nil)
    if Hit then
        return self:Stop("AutoPotential", "Potential roll done",
            ("%s rolled %s on %s (your keep list) after %d rolls"):format(self:Name(Unit), HitGrade, Hit, self.PotentialRolls))
    end
    local Shown = Stat == "All" and "all stats" or (Stat .. " " .. tostring(Potential and Potential[Stat] and Potential[Stat].Grade))
    Collection:SetPara("UnitStatus", ("Potential roll %d: %s (%d %s left)"):format(self.PotentialRolls, Shown, Collection:Balance(Item), Item))
end

function Units:MaxLevel(Unit)
    local LevelData = Collection.Modules.UnitLevelData or {}
    return (LevelData.MaxLevel or 50) + (Unit.Star or 0) * 5
end

-- Exp still needed to reach max level, same curve the feed screen uses.
function Units:ExpToMax(Unit)
    local LevelData = Collection.Modules.UnitLevelData or {}
    local Base, Mult = LevelData.BaseExp or 50, LevelData.Multiplier or 1.15
    local Level, Max = Unit.Level or 1, self:MaxLevel(Unit)
    if Level >= Max then return 0 end
    local Need = 0
    for Step = Level, Max - 1 do
        Need += Base * Mult ^ (Step - 1)
    end
    return math.max(0, math.ceil(Need - (Unit.Exp or 0)))
end

-- Feed items and their exp, cheapest first.
function Units:FeedItems()
    local Items = {}
    local ok, All = pcall(function() return Collection.Modules.ItemDatabase.Items end)
    for Id, Item in pairs(ok and All or {}) do
        if type(Item) == "table" and tonumber(Item.ExpValue) then
            table.insert(Items, { ID = Id, Exp = tonumber(Item.ExpValue), DisplayName = Item.Name })
        end
    end
    table.sort(Items, function(A, B) return A.Exp < B.Exp end)
    return Items
end

function Units:FeedStep(Unit)
    local Need = self:ExpToMax(Unit)
    if Need <= 0 then
        return Collection:SetPara("UnitStatus", self:Name(Unit) .. " is max level")
    end
    local Picked = {}
    for Label, On in pairs(Collection.Options.FeedItems.Value) do
        local Id = self.FeedToId[Label]
        if On and Id then Picked[Id] = true end
    end

    local Queue, Fed = {}, 0
    for _, Item in ipairs(self:FeedItems()) do
        local Have = Collection:Balance(Item.ID)
        if Picked[Item.ID] and Have > 0 and Need > 0 then
            local Amount = math.min(Have, math.ceil(Need / Item.Exp))
            Queue[Item.ID] = Amount
            Need -= Amount * Item.Exp
            Fed += Amount
        end
    end
    if Fed == 0 then
        return Collection:SetPara("UnitStatus", "Feed: none of the picked food items in the bag")
    end
    Collection:Fire("FeedUnit", Unit.UUID, Queue)
    Collection:SetPara("UnitStatus", ("Fed %d items to %s"):format(Fed, self:Name(Unit)))
end

function Units:CanEvolve(Unit)
    local Info = Summon:UnitInfo(Unit.UnitId)
    local Evolution = Info and Info.Evolution
    if not Evolution then return false, "this unit has no evolution" end
    local Missing = {}
    if (Unit.Level or 1) < (Evolution.RequiredLevel or 1) then
        table.insert(Missing, "level " .. Evolution.RequiredLevel)
    end
    local Cost = Evolution.Cost or 0
    if Collection:Balance("Coins") < Cost then
        table.insert(Missing, ("Coins %d/%d"):format(Collection:Balance("Coins"), Cost))
    end
    for Id, Amount in pairs(Evolution.RequiredItems or {}) do
        local Have = Collection:Balance(Id)
        if Have < Amount then
            table.insert(Missing, ("%s %d/%d"):format(Collection:ItemName(Id), Have, Amount))
        end
    end
    if #Missing > 0 then return false, "needs " .. table.concat(Missing, ", ") end
    return true
end

function Units:Evolve(Unit)
    local Ready, Why = self:CanEvolve(Unit)
    if not Ready then
        Collection:SetPara("UnitStatus", "Can't evolve: " .. tostring(Why))
        return false
    end
    Collection:Fire("EvolveUnitEvent", Unit.UUID)
    Collection:SetPara("UnitStatus", "Evolve sent for " .. self:Name(Unit))
    return true
end

function Units:Step()
    local Options = Collection.Options
    if Collection:Due("UnitList", 15) then self:Refresh() end

    local Unit = self:Selected()
    Collection:SetPara("UnitInfo", self:Describe(Unit))
    if not Unit then return 1 end

    local Rolling = Options.AutoTrait.Value or Options.AutoPotential.Value
    if Options.AutoTrait.Value then
        self:TraitStep(Unit)
    elseif Options.AutoPotential.Value then
        self:PotentialStep(Unit)
    end
    if Options.AutoFeed.Value and Collection:Due("Feed", 10) then
        self:FeedStep(Unit)
    end
    if Options.AutoEvolve.Value and Collection:Due("Evolve", 10) and self:CanEvolve(Unit) then
        if self:Evolve(Unit) then
            Collection:RaiseIdentity()
            Options.AutoEvolve:SetValue(false)
        end
    end
    return Rolling and Options.RollDelay.Value or 1
end

--------------------------- [[ Match ]] ---------------------------

-- Lane battle: units spawn from slots 1-6 at your base and walk the road. Units on the field
-- (workspace.<Map>.PlayerFolder, owned via OwnerID) can be upgraded, sold, ulted and switched Hunt/Defend.
local Match = {
    Money = 0,
    MaxMoney = 0,
    Units = {},      -- { Model, Seq } in spawn order
    Seq = 0,
    Cooldowns = {},  -- slot -> os.clock() when ready
    SpawnCount = {}, -- slot -> spawns the server accepted (it starts a cooldown for each)
    Ended = false,
}

function Match:WaitFor(Check, Seconds)
    local Deadline = os.clock() + Seconds
    repeat
        if Check() then return true end
        task.wait(0.05)
    until os.clock() > Deadline
    return Check() and true or false
end

function Match:Remote(Name)
    self.RemoteCache = self.RemoteCache or {}
    local Cached = self.RemoteCache[Name]
    if Cached and Cached.Parent then return Cached end
    for _, Folder in ipairs({ "Remotes", "GameEvents" }) do
        local Holder = ReplicatedStorage:FindFirstChild(Folder)
        local Remote = Holder and Holder:FindFirstChild(Name)
        if Remote then
            self.RemoteCache[Name] = Remote
            return Remote
        end
    end
    return nil
end

function Match:Fire(Name, ...)
    local Remote = self:Remote(Name)
    if not Remote then return false end
    local Args = table.pack(...)
    pcall(function() Remote:FireServer(table.unpack(Args, 1, Args.n)) end)
    return true
end

-- GameStarted stays true on the results screen, so the open EndGame gui counts as over too.
function Match:Started()
    return LocalPlayer:GetAttribute("GameStarted") == true and not self.Ended and not self:OnEndScreen()
end

-- SimulatedTime keeps counting across retries; StartSim marks this match's start.
function Match:Sim()
    return tonumber(workspace:GetAttribute("SimulatedTime")) or 0
end

function Match:Elapsed()
    return self:Sim() - (self.StartSim or self:Sim())
end

function Match:PlayerFolder()
    local Map = workspace:FindFirstChild(workspace:GetAttribute("MapName") or "")
    return Map and Map:FindFirstChild("PlayerFolder")
end

function Match:IsMine(Unit)
    if not (typeof(Unit) == "Instance" and Unit:IsA("Model")) then return false end
    return Unit:GetAttribute("Owner") == LocalPlayer.Name
        or (Unit:GetAttribute("OwnerId") or Unit:GetAttribute("OwnerID")) == LocalPlayer.UserId
end

-- My units still on the field, oldest first; one type or all.
function Match:Alive(UnitId)
    local List = {}
    for _, Entry in ipairs(self.Units) do
        if Entry.Model.Parent and (UnitId == nil or Entry.Model:GetAttribute("UnitId") == UnitId) then
            table.insert(List, Entry.Model)
        end
    end
    return List
end

-- Which one of its type a unit is, so a macro can find "the 2nd Naruta" again.
function Match:NthOf(Model)
    local List = self:Alive(Model:GetAttribute("UnitId"))
    return table.find(List, Model) or #List
end

function Match:FindUnit(UnitId, Nth)
    local List = self:Alive(UnitId)
    return List[Nth or 1] or List[#List]
end

function Match:AddUnit(Model)
    task.wait(0.2) -- owner attributes land just after the model
    if not self:IsMine(Model) then return end
    self.Seq += 1
    table.insert(self.Units, { Model = Model, Seq = self.Seq })
    if Collection.Options.AutoUltimate.Value then
        self:Fire("ToggleAutoUltimateRequest", Model, true)
    end
end

function Match:WatchField()
    local Folder = self:PlayerFolder()
    if not Folder or Folder == self.WatchedFolder then return end
    self.WatchedFolder = Folder
    for _, Child in ipairs(Folder:GetChildren()) do
        task.spawn(self.AddUnit, self, Child)
    end
    Collection:Track(Folder.ChildAdded:Connect(function(Child)
        self:AddUnit(Child)
    end))
end

-- Fires a spawn and waits for the server to start that slot's cooldown (= it spawned).
function Match:Spawn(Slot)
    local Before = self.SpawnCount[Slot] or 0
    self:Fire("SpawnUnitRequest", Slot)
    return self:WaitFor(function() return (self.SpawnCount[Slot] or 0) > Before end, 1)
end

-- The EndGame gui itself stays enabled for the whole session; what shows the results is its
-- EndGameFrame, and ResultBtn is the "reopen results" button left once that closes.
function Match:OnEndScreen()
    local EndGui = LocalPlayer.PlayerGui:FindFirstChild("EndGame")
    if not EndGui then return false end
    local Frame = EndGui:FindFirstChild("EndGameFrame")
    local Bg = EndGui:FindFirstChild("Bg")
    local Reopen = Bg and Bg:FindFirstChild("ResultBtn")
    return (Frame ~= nil and Frame.Visible) or (Reopen ~= nil and Reopen.Visible)
end

-- What a slot holds and its limits. The game's own stat calculation gives the field cap
-- (base UnitCap plus trait/potential boosts) and the real yen cost after reductions.
function Match:SlotInfo(Slot)
    self.SlotCache = self.SlotCache or {}
    local Cached = self.SlotCache[Slot]
    if Cached and os.clock() - Cached.At < 30 then return Cached.Info end

    local Info = nil
    local Data = Collection:GetData()
    local Slots = Data and Data.EquippedSlots or {}
    local UUID = Slots[Slot] or Slots[tostring(Slot)]
    if type(UUID) == "string" then
        for _, Unit in ipairs(Data.Inventory or {}) do
            if Unit.UUID == UUID then
                local Stats
                pcall(function() Stats = Collection.Modules.CalculateUnitsStats.Calculate(Unit) end)
                local Base = Summon:UnitInfo(Unit.UnitId) or {}
                Info = {
                    UnitId = Unit.UnitId,
                    Cap = Stats and Stats.unitsCapp or Base.UnitCap or 99,
                    Cost = Stats and Stats.Cost or Base.Cost or 0,
                }
                break
            end
        end
    end
    self.SlotCache[Slot] = { Info = Info, At = os.clock() }
    return Info
end

-- Why a slot can't spawn right now, or nil when it can.
function Match:SpawnBlock(Slot)
    local Info = self:SlotInfo(Slot)
    if not Info then return "empty slot" end
    if #self:Alive(Info.UnitId) >= Info.Cap then return ("at its cap of %d"):format(Info.Cap) end
    if self.Money < Info.Cost then return ("needs ¥%d"):format(Info.Cost) end
    if os.clock() < (self.Cooldowns[Slot] or 0) then return "on cooldown" end
    return nil
end

-- Slots with a priority (1 = first), best first; ties go by slot number. "Off" slots are left out.
function Match:SpawnOrder()
    local List = {}
    for Slot = 1, 6 do
        local Option = Collection.Options["SpawnPriority" .. Slot]
        local Rank = Option and tonumber(Option.Value)
        if Rank then
            table.insert(List, { Slot = Slot, Rank = Rank })
        end
    end
    table.sort(List, function(A, B)
        if A.Rank ~= B.Rank then return A.Rank < B.Rank end
        return A.Slot < B.Slot
    end)
    return List
end

-- One spawn per tick, top priority first. With "Save yen" on, a higher slot that's only short on yen
-- holds the lower ones back so they don't spend what it's waiting for; a capped, cooling or empty
-- slot just passes its turn down.
function Match:SpawnByPriority()
    for _, Entry in ipairs(self:SpawnOrder()) do
        local Block = self:SpawnBlock(Entry.Slot)
        if not Block then
            if Collection:Due("Spawn" .. Entry.Slot, 0.5) then
                self:Fire("SpawnUnitRequest", Entry.Slot)
            end
            return
        end
        if Block:find("^needs") and Collection.Options.SpawnSaveYen.Value then
            return
        end
    end
end

function Match:SlotText(Slot)
    local Info = self:SlotInfo(Slot)
    if not Info then return "empty" end
    local Unit = Summon:UnitInfo(Info.UnitId)
    return ("%s - cap %d, ¥%d"):format(Unit and (Unit.DisplayName or Unit.Name) or tostring(Info.UnitId), Info.Cap, Info.Cost)
end

-- "1. Slot 2 Naruta: ready" lines for the Spawn tab, plus each slot row's unit.
function Match:ShowSpawnOrder()
    local Lines = {}
    for Index, Entry in ipairs(self:SpawnOrder()) do
        local Info = self:SlotInfo(Entry.Slot)
        local Unit = Info and Summon:UnitInfo(Info.UnitId)
        local Name = Info and (Unit and (Unit.DisplayName or Unit.Name) or tostring(Info.UnitId)) or "empty"
        local State = Collection.InLobby and "" or (": " .. (self:SpawnBlock(Entry.Slot) or "ready"))
        if Info and not Collection.InLobby then
            State ..= (" (%d/%d on field)"):format(#self:Alive(Info.UnitId), Info.Cap)
        end
        table.insert(Lines, ("%d. Slot %d %s%s"):format(Index, Entry.Slot, Name, State))
    end
    Collection:SetPara("SpawnStatus", #Lines > 0 and table.concat(Lines, "\n") or "Every slot is Off")

    if Collection:Due("SlotRows", 10) then
        Collection:RaiseIdentity()
        for Slot = 1, 6 do
            pcall(function() Collection.Options["SpawnPriority" .. Slot]:SetDesc(self:SlotText(Slot)) end)
        end
    end
end

-- "Team: 2 Naruta" from the equipped slots, so an empty slot is obvious.
function Match:TeamText()
    local Data = Collection:GetData()
    local Slots = Data and Data.EquippedSlots or {}
    local Parts = {}
    for Slot = 1, 6 do
        local UUID = Slots[Slot] or Slots[tostring(Slot)]
        if type(UUID) == "string" then
            local Name = UUID:sub(1, 6)
            for _, Unit in ipairs(Data.Inventory or {}) do
                if Unit.UUID == UUID then
                    Name = Units:Name(Unit)
                    break
                end
            end
            table.insert(Parts, Slot .. " " .. Name)
        end
    end
    return #Parts > 0 and ("Team: " .. table.concat(Parts, ", ")) or "Team: empty - equip units in the lobby"
end

function Match:MaxUpgrade(Model)
    local Info = Summon:UnitInfo(Model:GetAttribute("UnitId"))
    return Info and Info.MaxUpgradeLevel or 5
end

-- The lobby hands every match its mode in the teleport data (the game's MainClient reads the same
-- GameMode); "RegularChallenge" / "DailyChallenge" / "WeeklyChallenge" are the challenges.
function Match:GameMode()
    if self.Mode == nil then
        local ok, Data = pcall(function()
            return Services.TeleportService:GetLocalPlayerTeleportData()
        end)
        self.Mode = ok and type(Data) == "table" and tostring(Data.GameMode or "") or ""
        if self.Mode == "" then -- no teleport data: trust what the lobby said it started
            local Last = Challenge:Session().Last
            if type(Last) == "table" and Last.Kind == "Challenge" and os.time() - (Last.At or 0) < 7200 then
                self.Mode = tostring(Last.Type) .. "Challenge"
            end
        end
    end
    return self.Mode
end

function Match:ChallengeKind()
    return self:GameMode():match("^(%a+)Challenge$")
end

function Match:OnStart()
    self.Ended = false
    self.StartSim = self:Sim()
    self.Units = {}
    self.Cooldowns = {}
    self.SlotCache = {}
    self.WatchedFolder = nil
    self:WatchField()
    Macro:OnMatchStart()
    if self:ChallengeKind() then
        Challenge:AddTry(self:ChallengeKind())
    end
end

-- Forfeits a running match first (the game's own Leave flow), then goes back to the lobby.
function Match:ReturnToLobby()
    if Collection.InLobby then return end
    self.Leaving = true
    if self:Started() then
        self:Fire("ForceEndGameRequest", "Lose")
        Collection:WaitFor(function() return self.Ended or self:OnEndScreen() end, 10)
        task.wait(1)
    end
    self:Fire("LeaveGameRequest")
end

-- EndGameEvent: won, map key, stage, seconds, per-unit EXP rows, can-next, rewards, difficulty, stats
function Match:OnEnd(Won, Map, Stage, Seconds, ExpRows, _, Rewards, Difficulty, Stats)
    Won = Won == true
    self.Ended = true
    Macro:OnMatchEnd()

    self.LastResult = {
        Won = Won, Map = Map, Stage = Stage, Difficulty = Difficulty, Time = Seconds,
        Exp = ExpRows, Rewards = Rewards, Stats = Stats,
    }
    if Collection.Options.WebhookOnEnd.Value then
        task.spawn(function()
            local Sent, Why = Collection:SendResult(self.LastResult)
            Collection:SetPara("WebhookStatus", (Sent and "Sent " or "Not sent: " .. tostring(Why) .. " - ") .. os.date("%H:%M") .. " result")
        end)
    end

    local Action = Collection.Options.AfterMatch.Value or "Nothing"
    local Kind = self:ChallengeKind()
    if self.Leaving then
        return -- Return to Lobby is already on its way out
    elseif Kind then
        -- a challenge runs once per reset: back to the lobby, where Play picks up again
        Action = "Back to lobby"
        self.ChallengeNote = Kind .. " challenge " .. (Won and "cleared" or "lost") .. " - back to the lobby"
    else
        local Due, DueKind = Challenge:Next()
        if Due and Collection.Options.ChallengeLeave.Value then
            Action = "Back to lobby"
            self.ChallengeNote = DueKind .. " challenge is up - back to the lobby to run it"
        end
    end
    if Action == "Nothing" then return end
    task.delay(3, function() -- same pause the game's own auto retry uses
        if not Collection:IsAlive() then return end
        if Action == "Retry" or (Action == "Next stage (retry if lost)" and not Won) then
            self:Fire("RetryGameRequest")
        elseif Action == "Next stage (retry if lost)" then
            self:Fire("NextStageRequest")
        elseif Action == "Back to lobby" then
            self:Fire("LeaveGameRequest")
        end
    end)
end

Match.Speeds = { ["Don't change"] = nil, ["1x"] = 1, ["1.5x"] = 1.5, ["3x (gamepass)"] = 3 }

function Match:Step()
    local Options = Collection.Options
    if Collection.InLobby then return 2 end

    self:WatchField()
    -- GameStarted goes false when a retry/next round opens its start vote
    local Voting = LocalPlayer:GetAttribute("GameStarted") ~= true
    if self.Ended and Voting then
        self.Ended = false
    end
    local Started = self:Started()

    if Collection:Due("ChallengeView", 2) then
        Challenge:Refresh()
        -- "Don't wait": forfeit a non-challenge match as soon as a challenge is up
        if Started and not self:ChallengeKind() and not self.Leaving
            and Options.ChallengeLeave.Value and Options.ChallengeLeaveNow.Value then
            local Due, DueKind = Challenge:Next()
            if Due then
                self.ChallengeNote = DueKind .. " challenge is up - leaving this match for it"
                task.spawn(self.ReturnToLobby, self)
            end
        end
    end

    if Options.AutoVoteStart.Value and Voting
        and LocalPlayer:GetAttribute("HasVotedStart") ~= true and Collection:Due("VoteStart", 2) then
        self:Fire("VoteStartRequest", LocalPlayer)
    end

    local Speed = self.Speeds[Options.GameSpeed.Value or ""]
    if Started and Speed and workspace:GetAttribute("GameSpeed") ~= Speed and Collection:Due("Speed", 5) then
        self:Fire("ChangeGameSpeedRequest", Speed)
    end

    -- A macro owns the yen while it records or plays: the game's autoplay and Auto spawn step aside.
    local MacroBusy = Macro.Playing or Macro.Recording ~= nil
    local GameAutoplayOn = LocalPlayer:GetAttribute("AutoPlay") == true
    if MacroBusy and GameAutoplayOn and Collection:Due("AutoplayOff", 3) then
        self:Fire("ToggleAutoplay", false)
    elseif not MacroBusy and Options.GameAutoplay.Value and not GameAutoplayOn and Collection:Due("Autoplay", 3) then
        self:Fire("ToggleAutoplay", true)
    end

    if Started and Options.AutoSpawn.Value and not MacroBusy then
        self:SpawnByPriority()
    end
    if Collection:Due("SpawnOrder", 1) then
        self:ShowSpawnOrder()
    end

    if Started and Options.AutoUpgradeUnits.Value and Collection:Due("UpgradeUnits", 0.8) then
        local Pick, Lowest = nil, math.huge
        for _, Model in ipairs(self:Alive()) do
            local Level = Model:GetAttribute("UpgradeLevel") or 0
            if Level < self:MaxUpgrade(Model) and Level < Lowest then
                Pick, Lowest = Model, Level
            end
        end
        if Pick then self:Fire("UpgradeUnitRequest", Pick) end
    end

    local Status
    if Started then
        Status = ("%ds in | ¥%d / %d | %d units on the field | speed %sx"):format(
            math.floor(self:Elapsed()), math.floor(self.Money), math.floor(self.MaxMoney), #self:Alive(),
            tostring(workspace:GetAttribute("GameSpeed") or 1))
    elseif Voting then
        Status = LocalPlayer:GetAttribute("HasVotedStart") == true and "Voted - waiting for the match to start" or "Vote to start"
    else
        Status = "Match over"
    end
    if Collection:Due("TeamText", 5) or not self.Team then
        self.Team = self:TeamText()
    end
    local Kind = self:ChallengeKind()
    local Note = self.ChallengeNote or (Kind and (Kind .. " challenge match - back to the lobby when it ends"))
    Collection:SetPara("MatchStatus", Status .. "\n" .. self.Team .. (Note and ("\n" .. Note) or ""))
    return 0.25
end

function Match:Init()
    local function On(Name, Fn)
        local Remote = self:Remote(Name)
        if Remote then Collection:Track(Remote.OnClientEvent:Connect(Fn)) end
    end

    On("UpdateBattleMoney", function(Money, Max)
        self.Money = tonumber(Money) or self.Money
        if tonumber(Max) and Max > 0 then self.MaxMoney = Max end
    end)
    On("UnitCooldownStart", function(Slot, Seconds)
        self.SpawnCount[Slot] = (self.SpawnCount[Slot] or 0) + 1
        self.Cooldowns[Slot] = os.clock() + (tonumber(Seconds) or 0) / (workspace:GetAttribute("GameSpeed") or 1)
    end)
    On("ResetUnitUIEvent", function()
        self.Cooldowns = {}
    end)
    On("WaveCountdownEvent", function()
        if Collection.Options.AutoSkipWave.Value then
            task.delay(0.5, function() self:Fire("VoteSkipWave") end)
        end
    end)
    On("EndGameEvent", function(...)
        self:OnEnd(...)
    end)

    Collection:Track(LocalPlayer:GetAttributeChangedSignal("GameStarted"):Connect(function()
        if LocalPlayer:GetAttribute("GameStarted") == true then
            self:OnStart()
        else
            self.Ended = false -- back to voting for the next round
        end
    end))
    if self:Started() then
        self:OnStart() -- loaded mid-match: the clock starts now
    end
end

--------------------------- [[ Macro ]] ---------------------------

-- A macro is the list of battle actions you made, each stamped with match time and yen.
-- Unit-targeted actions store the unit type and which one of that type it was.
Macro.Folder = Collection.Folder .. "/Macros"
Macro.Kinds = {
    SpawnUnitRequest = "Spawn",
    UpgradeUnitRequest = "Upgrade",
    SellUnitRequest = "Sell",
    UseUltimateEvent = "Ultimate",
    ToggleBehaviorModeRequest = "Behavior",
    SetAutoUpgradePriority = "Priority",
    ToggleAutoUltimateRequest = "AutoUltimate",
    VoteSkipWave = "SkipWave",
    ChangeGameSpeedRequest = "Speed",
}
Macro.Timings = { "Time + Yen", "Time", "Yen" }

function Macro:Path(Name)
    return self.Folder .. "/" .. Name .. ".json"
end

function Macro:List()
    local Names = {}
    pcall(function()
        for _, Path in ipairs(listfiles(self.Folder)) do
            local Name = Path:match("([^/\\]+)%.json$")
            if Name then table.insert(Names, Name) end
        end
    end)
    table.sort(Names)
    return Names
end

function Macro:RefreshList()
    Collection:RaiseIdentity()
    Collection.Options.MacroPick:SetValues(self:List())
end

function Macro:Describe(Name)
    local Data = Name and Collection:ReadJson(self:Path(Name))
    if type(Data) ~= "table" or type(Data.Steps) ~= "table" then return "No macro picked" end
    local Counts = {}
    for _, Step in ipairs(Data.Steps) do
        Counts[Step.Kind] = (Counts[Step.Kind] or 0) + 1
    end
    local Parts = {}
    for Kind, Count in pairs(Counts) do table.insert(Parts, Count .. " " .. Kind) end
    table.sort(Parts)
    return ("%d steps (%s) | %s | %ds long"):format(#Data.Steps, table.concat(Parts, ", "), tostring(Data.Map or "?"),
        math.floor(Data.Steps[#Data.Steps] and Data.Steps[#Data.Steps].T or 0))
end

function Macro:Status(Text)
    Collection:SetPara("MacroStatus", Text)
end

-- The take is written to its .json from the moment recording starts and after every step,
-- so leaving or teleporting mid-match keeps everything up to that point.
function Macro:Save()
    local Take = self.Recording
    if not Take then return end
    Collection:EnsureFolders()
    Collection:WriteJson(self:Path(Take.Name), {
        Name = Take.Name,
        Map = Take.Map or workspace:GetAttribute("MapName"),
        Created = Take.Created,
        Steps = Take.Steps,
    })
end

function Macro:RecordingText(Extra)
    local Take = self.Recording
    return ("Recording %s: %d steps%s\nFile: %s"):format(Take.Name, #Take.Steps, Extra or "", self:Path(Take.Name))
end

-- Steps go in match-time order (a spawn is only kept once the server confirms it, a moment later).
function Macro:Commit(Take, Step)
    if self.Recording ~= Take then return end
    local At = #Take.Steps + 1
    while At > 1 and (Take.Steps[At - 1].T or 0) > Step.T do
        At -= 1
    end
    table.insert(Take.Steps, At, Step)
    self:Save()
    self:Status(self:RecordingText((" (last: %s at %.1fs)"):format(Step.Kind, Step.T)))
end

-- Called (deferred) for every FireServer the game's own scripts make.
function Macro:OnRemote(Name, Args)
    local Kind = self.Kinds[Name]
    local Take = self.Recording
    if not (Kind and Take and Match:Started()) then return end

    local Step = { Kind = Kind, T = math.floor(Match:Elapsed() * 100) / 100, Money = Match.Money }
    if Kind == "Spawn" then
        -- only keep spawns the server accepted: an empty slot, cooldown or short yen just bounces
        Step.Slot = Args[1]
        local Before = Match.SpawnCount[Step.Slot] or 0
        task.spawn(function()
            if Match:WaitFor(function() return (Match.SpawnCount[Step.Slot] or 0) > Before end, 1.5) then
                self:Commit(Take, Step)
            elseif self.Recording == Take then
                self:Status(self:RecordingText(("\nSlot %s didn't spawn (empty slot, cooldown or not enough yen) - not saved"):format(tostring(Step.Slot))))
            end
        end)
        return
    elseif Kind == "Priority" then
        Step.UnitId, Step.Value = Args[1], Args[2]
    elseif Kind == "Speed" then
        Step.Value = Args[1]
    elseif Kind ~= "SkipWave" then
        local Model = Args[1]
        if typeof(Model) ~= "Instance" then return end
        Step.UnitId = Model:GetAttribute("UnitId")
        Step.Nth = Match:NthOf(Model)
        if Kind == "Behavior" then
            Step.From = Model:GetAttribute("BehaviorMode") or "Hunt"
        elseif Kind == "AutoUltimate" then
            Step.Value = Args[2]
        elseif Kind == "Upgrade" then
            local Before = Model:GetAttribute("UpgradeLevel") or 0
            task.spawn(function()
                if Match:WaitFor(function() return (Model:GetAttribute("UpgradeLevel") or 0) > Before end, 1.5) then
                    self:Commit(Take, Step)
                elseif self.Recording == Take then
                    self:Status(self:RecordingText("\nAn upgrade didn't go through (max level or not enough yen) - not saved"))
                end
            end)
            return
        end
    end
    self:Commit(Take, Step)
end

function Macro:StartRecording()
    local Name = (Collection.Options.MacroName.Value or ""):gsub("%.json$", ""):gsub("[^%w _%-]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if Name == "" then
        self:Status("Type a macro name first")
        Collection:RaiseIdentity()
        Collection.Options.MacroRecord:SetValue(false)
        return
    end
    -- an existing macro of that name is only replaced once the new take has a step
    local Existed = isfile and isfile(self:Path(Name)) or false
    self.Recording = { Name = Name, Steps = {}, Created = os.date("%Y-%m-%d %H:%M"), Map = workspace:GetAttribute("MapName"), Existed = Existed }
    if not Existed then
        self:Save()
    end
    self:Status(self:RecordingText((Match:Started() and " - play now" or " - starts when the match starts")
        .. (Existed and "\n(replaces the old " .. Name .. " once a step is recorded)" or "")))
    task.defer(function() self:RefreshList() end)
end

function Macro:StopRecording()
    local Take = self.Recording
    if not Take then return end
    if #Take.Steps > 0 then self:Save() end
    self.Recording = nil
    if #Take.Steps == 0 then
        if not Take.Existed then pcall(delfile, self:Path(Take.Name)) end
        self:Status("Recording stopped - nothing went through, so nothing was saved. Spawn from a slot that has a unit.")
        task.defer(function() self:RefreshList() end)
        return
    end
    self:Status(("Saved %s: %d steps\nFile: %s"):format(Take.Name, #Take.Steps, self:Path(Take.Name)))
    task.defer(function()
        self:RefreshList()
        Collection:RaiseIdentity()
        pcall(function() Collection:SetDropdown(Collection.Options.MacroPick, Take.Name) end)
    end)
end

-- Spawns and upgrades can bounce (cooldown, short on yen), so they retry for a few seconds.
function Macro:Execute(Step)
    local Kind = Step.Kind
    if Kind == "Spawn" then
        -- wait out the cap / yen / cooldown (a unit at its cap frees up when one dies)
        local Deadline = os.clock() + 15
        repeat
            local Block = Match:SpawnBlock(Step.Slot)
            if Block == "empty slot" then return false end
            if not Block and Match:Spawn(Step.Slot) then return true end
            task.wait(0.3)
        until os.clock() > Deadline or Match.Ended
        return false
    elseif Kind == "Priority" then
        return Match:Fire("SetAutoUpgradePriority", Step.UnitId, Step.Value)
    elseif Kind == "Speed" then
        return Match:Fire("ChangeGameSpeedRequest", Step.Value)
    elseif Kind == "SkipWave" then
        return Match:Fire("VoteSkipWave")
    end

    local Unit = Match:FindUnit(Step.UnitId, Step.Nth)
    if not Unit then return false end
    if Kind == "Upgrade" then
        local Before = Unit:GetAttribute("UpgradeLevel") or 0
        if Before >= Match:MaxUpgrade(Unit) then return true end
        local Deadline = os.clock() + 8
        repeat
            Match:Fire("UpgradeUnitRequest", Unit)
            task.wait(0.6)
            if (Unit:GetAttribute("UpgradeLevel") or 0) > Before then return true end
        until os.clock() > Deadline or not Unit.Parent or Match.Ended
        return false
    elseif Kind == "Sell" then
        return Match:Fire("SellUnitRequest", Unit)
    elseif Kind == "Ultimate" then
        return Match:Fire("UseUltimateEvent", Unit)
    elseif Kind == "Behavior" then
        -- recorded as "switch away from X": only switch if it's still in X
        if (Unit:GetAttribute("BehaviorMode") or "Hunt") == Step.From then
            return Match:Fire("ToggleBehaviorModeRequest", Unit)
        end
        return true
    elseif Kind == "AutoUltimate" then
        return Match:Fire("ToggleAutoUltimateRequest", Unit, Step.Value)
    end
    return false
end

function Macro:Play(Name)
    local Data = Name and Collection:ReadJson(self:Path(Name))
    if type(Data) ~= "table" or type(Data.Steps) ~= "table" then
        return self:Status("Pick a macro to play")
    end
    local Token = {}
    self.PlayToken = Token
    self.Playing = true
    local Done, Missed = 0, 0
    for Index, Step in ipairs(Data.Steps) do
        -- wait for this step's moment; only spawns and upgrades cost yen
        while true do
            if self.PlayToken ~= Token or not Collection.Options.MacroPlay.Value or Match.Ended or not Collection:IsAlive() then
                self.Playing = false
                return
            end
            local Timing = Collection.Options.MacroTiming.Value or "Time + Yen"
            local Costs = Step.Kind == "Spawn" or Step.Kind == "Upgrade"
            local TimeOk = Timing == "Yen" or Match:Elapsed() >= (Step.T or 0)
            local Need = math.min(Step.Money or 0, Match.MaxMoney > 0 and Match.MaxMoney or math.huge)
            local MoneyOk = Timing == "Time" or not Costs or Match.Money >= Need
            if TimeOk and MoneyOk then break end
            self:Status(("Playing %s %d/%d: %s%s - waiting for %s"):format(Name, Index, #Data.Steps, Step.Kind,
                Step.Slot and (" slot " .. Step.Slot) or (Step.UnitId and (" " .. tostring(Step.UnitId)) or ""),
                TimeOk and ("¥" .. Need) or (("%.0fs"):format(Step.T or 0))))
            task.wait(0.1)
        end
        if self:Execute(Step) then Done += 1 else Missed += 1 end
        self:Status(("Playing %s %d/%d (%d missed)"):format(Name, Index, #Data.Steps, Missed))
    end
    self.Playing = false
    self:Status(("Finished %s: %d done, %d missed"):format(Name, Done, Missed))
end

function Macro:OnMatchStart()
    if Collection.Options.MacroRecord.Value and not self.Recording then
        self:StartRecording()
    elseif self.Recording then
        self.Recording.Steps = {} -- a fresh match restarts the take
        self.Recording.Map = workspace:GetAttribute("MapName")
    end
    if Collection.Options.MacroPlay.Value then
        task.spawn(self.Play, self, Collection.Options.MacroPick.Value)
    end
end

function Macro:OnMatchEnd()
    self.PlayToken = nil
    if self.Recording then
        self:StopRecording()
        Collection:RaiseIdentity()
        Collection.Options.MacroRecord:SetValue(false)
    end
end

-- One __namecall hook per game session; reloading the hub swaps the listener, not the hook.
function Macro:InstallHook()
    GlobalEnv.vaderhug_remote_listener = function(Name, Args)
        if Collection:IsAlive() then
            Macro:OnRemote(Name, Args)
        end
    end
    if GlobalEnv.vaderhug_namecall_hooked or not hookmetamethod then return end
    GlobalEnv.vaderhug_namecall_hooked = true
    local Old
    Old = hookmetamethod(game, "__namecall", newcclosure(function(Self, ...)
        if not checkcaller() and getnamecallmethod() == "FireServer" and typeof(Self) == "Instance" then
            local Listener = GlobalEnv.vaderhug_remote_listener
            if Listener then
                task.defer(Listener, Self.Name, table.pack(...))
            end
        end
        return Old(Self, ...)
    end))
end

--------------------------- [[ VaderUI (embedded) ]] ---------------------------

-- Verbatim copy of C:\Users\EvilCEE\Downloads\VaderUI.lua (with sidebar folders), so the hub
-- needs no other file. To update it, replace everything between this line and the matching end.
local function EmbeddedVaderUI()


local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Env = (getgenv and getgenv()) or _G

if type(Env.VaderUI_Instance) == "table" and Env.VaderUI_Instance.Destroy then
    pcall(Env.VaderUI_Instance.Destroy, Env.VaderUI_Instance)
end

local DefaultLogo = "https://github.com/DONUT6599/ddgdhdf/blob/main/Asset_1.png?raw=true"
local DefaultMascot = "https://github.com/DONUT6599/ddgdhdf/blob/main/%E0%B9%84%E0%B8%A1%E0%B9%88%E0%B8%A1%E0%B8%B5%E0%B8%8A%E0%B8%B7%E0%B9%88%E0%B8%AD%20114_20260915013214.png?raw=true"

local Palettes = {
    Dark = {
        Window = Color3.fromRGB(14, 12, 20),
        Work = Color3.fromRGB(22, 19, 31),
        Card = Color3.fromRGB(31, 27, 44),
        CardHover = Color3.fromRGB(40, 35, 58),
        Stroke = Color3.fromRGB(54, 46, 78),
        Field = Color3.fromRGB(17, 14, 25),
        Text = Color3.fromRGB(240, 236, 250),
        SubText = Color3.fromRGB(160, 152, 184),
        Accent = Color3.fromRGB(132, 88, 240),
        AccentText = Color3.fromRGB(255, 255, 255),
        ToggleOff = Color3.fromRGB(62, 55, 84),
    },
    Amethyst = {
        Window = Color3.fromRGB(30, 18, 56),
        Work = Color3.fromRGB(40, 25, 72),
        Card = Color3.fromRGB(54, 36, 94),
        CardHover = Color3.fromRGB(66, 45, 112),
        Stroke = Color3.fromRGB(88, 64, 142),
        Field = Color3.fromRGB(28, 17, 52),
        Text = Color3.fromRGB(244, 240, 255),
        SubText = Color3.fromRGB(190, 176, 224),
        Accent = Color3.fromRGB(168, 128, 255),
        AccentText = Color3.fromRGB(255, 255, 255),
        ToggleOff = Color3.fromRGB(82, 62, 128),
    },
    Light = {
        Window = Color3.fromRGB(236, 232, 245),
        Work = Color3.fromRGB(255, 255, 255),
        Card = Color3.fromRGB(245, 242, 251),
        CardHover = Color3.fromRGB(236, 231, 247),
        Stroke = Color3.fromRGB(220, 213, 238),
        Field = Color3.fromRGB(255, 255, 255),
        Text = Color3.fromRGB(24, 18, 38),
        SubText = Color3.fromRGB(105, 96, 128),
        Accent = Color3.fromRGB(112, 68, 224),
        AccentText = Color3.fromRGB(255, 255, 255),
        ToggleOff = Color3.fromRGB(205, 198, 222),
    },
}

local Library = {
    Version = "1.0.0",
    Options = {},
    Themes = { "Dark", "Amethyst", "Light" },
    Theme = "Dark",
    Unloaded = false,
    UseAcrylic = false,
    MascotTransparency = 0.5,
    MinimizeKey = Enum.KeyCode.RightControl,
    MinimizeKeybind = nil,
    Logo = nil,
    Window = nil,
    GUI = nil,
    Connections = {},
}

local Theme = Palettes.Dark
local Registry = {}   -- { instance, { Property = "ThemeKey" } }
local Refreshers = {} -- repaint functions for state-dependent colours

local function Bind(Inst, Map)
    table.insert(Registry, { Inst, Map })
    for Property, Key in pairs(Map) do
        Inst[Property] = Theme[Key]
    end
end

local function New(Class, Props, Children)
    local Inst = Instance.new(Class)
    if Inst:IsA("GuiObject") then
        Inst.BorderSizePixel = 0
    end
    if Inst:IsA("GuiButton") then
        Inst.AutoButtonColor = false
    end
    if Props then
        for Key, Value in pairs(Props) do
            if Key ~= "Parent" and Key ~= "Theme" then
                Inst[Key] = Value
            end
        end
        if Props.Theme then
            Bind(Inst, Props.Theme)
        end
    end
    if Children then
        for _, Child in ipairs(Children) do
            Child.Parent = Inst
        end
    end
    if Props and Props.Parent then
        Inst.Parent = Props.Parent
    end
    return Inst
end

local function Corner(Radius)
    return New("UICorner", { CornerRadius = UDim.new(0, Radius) })
end

local function Tween(Inst, Time, Props, Style)
    local Info = TweenInfo.new(Time, Style or Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local Created = TweenService:Create(Inst, Info, Props)
    Created:Play()
    return Created
end

local function Track(Connection)
    table.insert(Library.Connections, Connection)
    return Connection
end

local function IsPress(Input)
    return Input.UserInputType == Enum.UserInputType.MouseButton1
        or Input.UserInputType == Enum.UserInputType.Touch
end

local function IsMove(Input)
    return Input.UserInputType == Enum.UserInputType.MouseMovement
        or Input.UserInputType == Enum.UserInputType.Touch
end

local function ResolveImage(Source, CacheName)
    if type(Source) == "number" then
        return "rbxassetid://" .. Source
    end
    if type(Source) ~= "string" or Source == "" then
        return nil
    end
    if Source:match("^rbx") then
        return Source
    end
    if tonumber(Source) then
        return "rbxassetid://" .. Source
    end

    local GetAsset = getcustomasset or getsynasset
    if GetAsset == nil or isfile == nil then
        return nil
    end

    local Path = Source
    if Source:match("^https?://") then
        Path = CacheName
        if not isfile(Path) then
            local ok, Data = pcall(game.HttpGet, game, Source)
            if not ok or writefile == nil then
                return nil
            end
            writefile(Path, Data)
        end
    elseif not isfile(Path) then
        return nil
    end

    local ok, Asset = pcall(GetAsset, Path)
    return ok and Asset or nil
end

local function GetGuiParent()
    if gethui then
        local ok, Hui = pcall(gethui)
        if ok and Hui then
            return Hui
        end
    end
    local ok, CoreGui = pcall(function()
        local Service = game:GetService("CoreGui")
        local _ = Service.Name
        return Service
    end)
    if ok and CoreGui then
        return CoreGui
    end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function EnsureGui()
    if Library.GUI then
        return Library.GUI
    end
    local Gui = New("ScreenGui", {
        Name = "VaderUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 999999,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    Gui.Parent = GetGuiParent()
    Library.GUI = Gui

    Library.NotifyHolder = New("Frame", {
        Name = "Notifications",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -16, 0, 16),
        Size = UDim2.new(0, 300, 1, -32),
        ZIndex = 100,
        Parent = Gui,
    }, {
        New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
    })
    return Gui
end

-- A logo image, or a drawn "V" badge when no image can be resolved
local function MakeLogo(Parent, Size, Props)
    local Image = Library.LogoImage
    local Inst
    if Image then
        Inst = New("ImageLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(Size, Size),
            Image = Image,
            ScaleType = Enum.ScaleType.Fit,
        })
    else
        Inst = New("TextLabel", {
            Size = UDim2.fromOffset(Size, Size),
            Font = Enum.Font.GothamBold,
            Text = "V",
            TextSize = math.floor(Size * 0.6),
            Theme = { BackgroundColor3 = "Accent", TextColor3 = "AccentText" },
        }, { Corner(math.floor(Size / 4)) })
    end
    for Key, Value in pairs(Props or {}) do
        Inst[Key] = Value
    end
    Inst.Parent = Parent
    return Inst
end

function Library:SafeCallback(Callback, ...)
    if type(Callback) ~= "function" then
        return
    end
    local ok, Problem = pcall(Callback, ...)
    if not ok then
        warn("[VaderUI] callback error: " .. tostring(Problem))
    end
end

function Library:SetTheme(Name)
    if Palettes[Name] == nil then
        Name = "Dark"
    end
    self.Theme = Name
    Theme = Palettes[Name]
    for _, Entry in ipairs(Registry) do
        for Property, Key in pairs(Entry[2]) do
            pcall(function()
                Entry[1][Property] = Theme[Key]
            end)
        end
    end
    for _, Refresh in ipairs(Refreshers) do
        pcall(Refresh)
    end
end

function Library:ToggleAcrylic() end

function Library:ToggleTransparency(Value)
    self.Transparent = Value and true or false
    if self.Window then
        self.Window.Main.BackgroundTransparency = self.Transparent and 0.12 or 0
    end
end

-- 0 is solid, 1 hides her; remembered in VaderUI_mascot_alpha.txt
function Library:SetMascotTransparency(Value)
    Value = math.clamp(tonumber(Value) or 0.5, 0, 1)
    self.MascotTransparency = Value
    if self.Window and self.Window.Mascot then
        self.Window.Mascot.ImageTransparency = Value
    end
    if writefile then
        pcall(writefile, "VaderUI_mascot_alpha.txt", tostring(Value))
    end
end

function Library:Notify(Config)
    Config = Config or {}
    EnsureGui()

    self.NotifyCount = (self.NotifyCount or 0) + 1
    local Card = New("CanvasGroup", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Card,
        GroupTransparency = 1,
        LayoutOrder = self.NotifyCount,
        Parent = self.NotifyHolder,
    }, {
        Corner(12),
        New("UIStroke", { Color = Theme.Stroke }),
        New("UIPadding", {
            PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
        }),
    })
    MakeLogo(Card, 30)

    local Texts = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(40, 0),
        Size = UDim2.new(1, -40, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = Card,
    }, {
        New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
    })

    for Order, Line in ipairs({
        { Config.Title, Enum.Font.GothamBold, 13, Theme.Text },
        { Config.Content, Enum.Font.Gotham, 12, Theme.Text },
        { Config.SubContent, Enum.Font.Gotham, 12, Theme.SubText },
    }) do
        if Line[1] ~= nil and tostring(Line[1]) ~= "" then
            New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Font = Line[2],
                Text = tostring(Line[1]),
                TextSize = Line[3],
                TextColor3 = Line[4],
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = Order,
                Parent = Texts,
            })
        end
    end

    Tween(Card, 0.25, { GroupTransparency = 0 })

    local Notification = { Closed = false }
    function Notification:Close()
        if self.Closed then
            return
        end
        self.Closed = true
        Tween(Card, 0.25, { GroupTransparency = 1 })
        task.delay(0.3, function()
            Card:Destroy()
        end)
    end

    task.delay(Config.Duration or 5, function()
        Notification:Close()
    end)
    return Notification
end

function Library:Destroy()
    if self.Unloaded then
        return
    end
    self.Unloaded = true
    for _, Connection in ipairs(self.Connections) do
        pcall(Connection.Disconnect, Connection)
    end
    if self.GUI then
        self.GUI:Destroy()
    end
    if Env.VaderUI_Instance == self then
        Env.VaderUI_Instance = nil
    end
end

function Library:CreateWindow(Config)
    Config = Config or {}

    local Gui = EnsureGui()
    self.MinimizeKey = Config.MinimizeKey or self.MinimizeKey
    self.LogoImage = ResolveImage(Config.Logo or self.Logo or Env.VaderUI_Logo or DefaultLogo, "VaderUI_logo.png")
    local MascotImage
    if Config.Mascot ~= false then
        MascotImage = ResolveImage(Config.Mascot or self.Mascot or DefaultMascot, "VaderUI_mascot.png")
    end
    if Palettes[Config.Theme] then
        self.Theme = Config.Theme
        Theme = Palettes[Config.Theme]
    end

    local Requested = Config.Size or UDim2.fromOffset(600, 460)
    local Viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local Width = math.clamp(Requested.X.Offset, 520, math.max(520, Viewport.X - 20))
    local Height = math.clamp(Requested.Y.Offset, 380, math.max(380, Viewport.Y - 20))
    local SideWidth = math.max(Config.TabWidth or 180, 180)

    local Window = { Tabs = {}, Folders = {}, SidebarOrder = 0, Minimized = false, Zoomed = false }
    self.Window = Window

    local Holder = New("Frame", {
        Name = "Window",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 1.5, Height),
        Size = UDim2.fromOffset(Width, Height),
        Parent = Gui,
    })

    New("ImageLabel", {
        Name = "Shadow",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1.2, 1.2),
        Image = "rbxassetid://313486536",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.35,
        Parent = Holder,
    })

    local Main = New("Frame", {
        Name = "Main",
        Size = UDim2.fromScale(1, 1),
        ZIndex = 2,
        Theme = { BackgroundColor3 = "Window" },
        Parent = Holder,
    }, {
        Corner(14),
        New("UIStroke", { Theme = { Color = "Stroke" } }),
    })
    Window.Main = Main
    Window.Root = Holder

    --------------------------- [[ Dragging ]] ---------------------------

    local ShownPosition = UDim2.fromScale(0.5, 0.5)
    local Drag = { Active = false }

    local function HookDrag(Handle)
        Handle.InputBegan:Connect(function(Input)
            if not IsPress(Input) or Window.Minimized then
                return
            end
            Drag.Active, Drag.Start, Drag.Origin = true, Input.Position, Holder.Position
        end)
    end

    -- ends here rather than on the input object: mouse input objects are reused, so a
    -- listener left on one would later save the minimized, off-screen spot as "shown"
    Track(UserInputService.InputEnded:Connect(function(Input)
        if Drag.Active and IsPress(Input) then
            Drag.Active = false
            if not Window.Minimized then
                ShownPosition = Holder.Position
            end
        end
    end))

    Track(UserInputService.InputChanged:Connect(function(Input)
        if Drag.Active and IsMove(Input) then
            local Delta = Input.Position - Drag.Start
            Holder.Position = UDim2.new(
                Drag.Origin.X.Scale, Drag.Origin.X.Offset + Delta.X,
                Drag.Origin.Y.Scale, Drag.Origin.Y.Offset + Delta.Y
            )
        end
    end))

    --------------------------- [[ Work Area ]] ---------------------------

    local Work = New("Frame", {
        Name = "Work",
        Position = UDim2.fromOffset(SideWidth, 0),
        Size = UDim2.new(1, -SideWidth, 1, 0),
        Theme = { BackgroundColor3 = "Work" },
        Parent = Main,
    }, { Corner(14) })

    -- squares off the work area's left corners where it meets the sidebar
    New("Frame", {
        Size = UDim2.new(0, 14, 1, 0),
        Theme = { BackgroundColor3 = "Work" },
        Parent = Work,
    })

    -- cards go part see-through so the mascot reads behind them
    local CardAlpha = MascotImage and 0.3 or 0
    if MascotImage then
        -- explicit config wins, then the remembered setting, then the default
        local Saved
        if isfile and readfile and isfile("VaderUI_mascot_alpha.txt") then
            local ok, Text = pcall(readfile, "VaderUI_mascot_alpha.txt")
            Saved = ok and tonumber(Text) or nil
        end
        self.MascotTransparency = math.clamp(Config.MascotTransparency or Saved or self.MascotTransparency, 0, 1)

        Window.Mascot = New("ImageLabel", {
            Name = "Mascot",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -4, 1, 0),
            Size = UDim2.new(1, -8, 1, -8),
            Image = MascotImage,
            ImageTransparency = self.MascotTransparency,
            ScaleType = Enum.ScaleType.Fit,
            Parent = Work,
        }, {
            New("UIAspectRatioConstraint", {
                AspectRatio = 1462 / 2000,
                DominantAxis = Enum.DominantAxis.Height,
            }),
        })
    end

    local Header = New("TextLabel", {
        Name = "Header",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(18, 12),
        Size = UDim2.new(1, -36, 0, 26),
        Font = Enum.Font.GothamBold,
        Text = "",
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 2,
        Theme = { TextColor3 = "Text" },
        Parent = Work,
    })

    local Pages = New("Frame", {
        Name = "Pages",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 48),
        Size = UDim2.new(1, -22, 1, -58),
        ZIndex = 2,
        Parent = Work,
    })

    HookDrag(New("Frame", {
        Name = "DragBar",
        Active = true,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 40),
        ZIndex = 3,
        Parent = Main,
    }))

    --------------------------- [[ Sidebar ]] ---------------------------

    local Lights = New("Frame", {
        Name = "Lights",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 14),
        Size = UDim2.fromOffset(60, 12),
        ZIndex = 4,
        Parent = Main,
    }, {
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })

    local function MakeLight(Order, Color)
        return New("TextButton", {
            Text = "",
            BackgroundColor3 = Color,
            Size = UDim2.fromOffset(12, 12),
            LayoutOrder = Order,
            ZIndex = 4,
            Parent = Lights,
        }, { Corner(6) })
    end

    local CloseLight = MakeLight(1, Color3.fromRGB(254, 94, 86))
    local MinimizeLight = MakeLight(2, Color3.fromRGB(255, 189, 46))
    local ZoomLight = MakeLight(3, Color3.fromRGB(39, 200, 63))

    local Brand = New("Frame", {
        Name = "Brand",
        Active = true,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 38),
        Size = UDim2.new(0, SideWidth - 24, 0, 36),
        ZIndex = 3,
        Parent = Main,
    })
    HookDrag(Brand)
    MakeLogo(Brand, 36)

    New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(44, 2),
        Size = UDim2.new(1, -44, 0, 16),
        Font = Enum.Font.GothamBold,
        Text = tostring(Config.Title or "VaderUI"),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Theme = { TextColor3 = "Text" },
        Parent = Brand,
    })

    New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(44, 19),
        Size = UDim2.new(1, -44, 0, 14),
        Font = Enum.Font.Gotham,
        Text = tostring(Config.SubTitle or ""),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Theme = { TextColor3 = "SubText" },
        Parent = Brand,
    })

    local Search = New("Frame", {
        Name = "Search",
        Position = UDim2.fromOffset(12, 84),
        Size = UDim2.new(0, SideWidth - 24, 0, 28),
        Theme = { BackgroundColor3 = "Card" },
        Parent = Main,
    }, { Corner(8) })

    New("ImageLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8, 7),
        Size = UDim2.fromOffset(14, 14),
        Image = "rbxassetid://2804603863",
        ScaleType = Enum.ScaleType.Fit,
        Theme = { ImageColor3 = "SubText" },
        Parent = Search,
    })

    local SearchBox = New("TextBox", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(28, 0),
        Size = UDim2.new(1, -34, 1, 0),
        ClearTextOnFocus = false,
        ClipsDescendants = true,
        Font = Enum.Font.Gotham,
        PlaceholderText = "Search",
        Text = "",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Theme = { TextColor3 = "Text", PlaceholderColor3 = "SubText" },
        Parent = Search,
    })

    local TabList = New("ScrollingFrame", {
        Name = "Tabs",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 122),
        Size = UDim2.new(0, SideWidth - 24, 1, -134),
        CanvasSize = UDim2.new(),
        ScrollBarThickness = 2,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Theme = { ScrollBarImageColor3 = "Stroke" },
        Parent = Main,
    })
    local TabLayout = New("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = TabList,
    })
    TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabList.CanvasSize = UDim2.fromOffset(0, TabLayout.AbsoluteContentSize.Y)
    end)

    --------------------------- [[ Dropdown Popup ]] ---------------------------

    -- one popup shared by every dropdown; its list is rebuilt each time it opens
    local Overlay = New("TextButton", {
        Name = "Overlay",
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        ZIndex = 50,
        Parent = Gui,
    })

    local Popup = New("Frame", {
        Name = "Popup",
        Active = true,
        Size = UDim2.fromOffset(200, 100),
        ZIndex = 51,
        Theme = { BackgroundColor3 = "Card" },
        Parent = Overlay,
    }, {
        Corner(9),
        New("UIStroke", { Theme = { Color = "Stroke" } }),
    })

    local PopupSearch = New("TextBox", {
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.new(1, -12, 0, 26),
        ClearTextOnFocus = false,
        ClipsDescendants = true,
        Font = Enum.Font.Gotham,
        PlaceholderText = "Search",
        Text = "",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 52,
        Theme = { BackgroundColor3 = "Field", TextColor3 = "Text", PlaceholderColor3 = "SubText" },
        Parent = Popup,
    }, {
        Corner(6),
        New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
    })

    local PopupList = New("ScrollingFrame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(6, 38),
        Size = UDim2.new(1, -12, 1, -44),
        CanvasSize = UDim2.new(),
        ScrollBarThickness = 3,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ZIndex = 52,
        Theme = { ScrollBarImageColor3 = "Stroke" },
        Parent = Popup,
    }, {
        New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
    })

    local PopupState = { Owner = nil, Anchor = nil }

    local function ClosePopup()
        Overlay.Visible = false
        if PopupState.Owner then
            PopupState.Owner.Opened = false
        end
        PopupState.Owner, PopupState.Anchor = nil, nil
    end

    local function FillPopup()
        for _, Child in ipairs(PopupList:GetChildren()) do
            if Child:IsA("TextButton") then
                Child:Destroy()
            end
        end

        local Dropdown, Anchor = PopupState.Owner, PopupState.Anchor
        if Dropdown == nil or Anchor == nil then
            return
        end

        local Query = PopupSearch.Text:lower()
        local Count = 0
        for Index, Value in ipairs(Dropdown.Values) do
            local Label = tostring(Value)
            if Query == "" or Label:lower():find(Query, 1, true) then
                Count += 1

                local Option = New("TextButton", {
                    BackgroundColor3 = Theme.CardHover,
                    Size = UDim2.new(1, -5, 0, 26),
                    Font = Enum.Font.Gotham,
                    Text = Label,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    LayoutOrder = Index,
                    ZIndex = 53,
                    Parent = PopupList,
                }, {
                    Corner(6),
                    New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 22) }),
                })

                local Dot = New("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 14, 0.5, 0),
                    Size = UDim2.fromOffset(8, 8),
                    BackgroundColor3 = Theme.Accent,
                    ZIndex = 54,
                    Parent = Option,
                }, { Corner(4) })

                local function Paint()
                    local Selected
                    if Dropdown.Multi then
                        Selected = Dropdown.Value[Value] == true
                    else
                        Selected = Dropdown.Value == Value
                    end
                    Dot.Visible = Selected
                    Option.BackgroundTransparency = Selected and 0 or 1
                    Option.TextColor3 = Selected and Theme.Accent or Theme.Text
                    Option.Font = Selected and Enum.Font.GothamMedium or Enum.Font.Gotham
                end
                Paint()

                Option.MouseEnter:Connect(function()
                    Option.BackgroundTransparency = 0
                end)
                Option.MouseLeave:Connect(Paint)

                Option.MouseButton1Click:Connect(function()
                    if Dropdown.Multi then
                        local Picked = table.clone(Dropdown.Value)
                        Picked[Value] = (not Picked[Value]) or nil
                        Dropdown:SetValue(Picked)
                        Paint()
                    else
                        if Dropdown.Value ~= Value then
                            Dropdown:SetValue(Value)
                        elseif Dropdown.AllowNull then
                            Dropdown:SetValue(nil)
                        end
                        ClosePopup()
                    end
                end)
            end
        end

        local ListHeight = math.clamp(Count * 28 - 2, 26, 196)
        PopupList.CanvasSize = UDim2.fromOffset(0, math.max(Count * 28 - 2, 0))

        local PopupWidth = math.max(Anchor.AbsoluteSize.X, 210)
        local PopupHeight = ListHeight + 44
        local Origin = Anchor.AbsolutePosition - Overlay.AbsolutePosition
        local X = Origin.X + Anchor.AbsoluteSize.X - PopupWidth
        local Y = Origin.Y + Anchor.AbsoluteSize.Y + 4
        if Y + PopupHeight > Overlay.AbsoluteSize.Y - 8 then
            Y = math.max(Origin.Y - PopupHeight - 4, 8)
        end
        Popup.Size = UDim2.fromOffset(PopupWidth, PopupHeight)
        Popup.Position = UDim2.fromOffset(math.max(X, 8), Y)
    end

    local function OpenPopup(Dropdown, Anchor)
        ClosePopup()
        PopupState.Owner, PopupState.Anchor = Dropdown, Anchor
        Dropdown.Opened = true
        PopupSearch.Text = ""
        PopupList.CanvasPosition = Vector2.zero
        FillPopup()
        Overlay.Visible = true
    end

    Overlay.MouseButton1Click:Connect(ClosePopup)
    PopupSearch:GetPropertyChangedSignal("Text"):Connect(FillPopup)

    --------------------------- [[ Dialog ]] ---------------------------

    local Dim = New("TextButton", {
        Name = "Dialog",
        Text = "",
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.45,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        ZIndex = 20,
        Parent = Main,
    }, { Corner(14) })

    local DialogCard = New("Frame", {
        Active = true,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(300, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 21,
        Theme = { BackgroundColor3 = "Card" },
        Parent = Dim,
    }, {
        Corner(14),
        New("UIStroke", { Theme = { Color = "Stroke" } }),
        New("UIPadding", {
            PaddingTop = UDim.new(0, 18), PaddingBottom = UDim.new(0, 14),
            PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16),
        }),
        New("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
        }),
    })

    MakeLogo(DialogCard, 48, { LayoutOrder = 1, ZIndex = 22 })

    local DialogTitle = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextWrapped = true,
        LayoutOrder = 2,
        ZIndex = 22,
        Theme = { TextColor3 = "Text" },
        Parent = DialogCard,
    })

    local DialogContent = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextWrapped = true,
        LayoutOrder = 3,
        ZIndex = 22,
        Theme = { TextColor3 = "SubText" },
        Parent = DialogCard,
    })

    local DialogButtons = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 4,
        ZIndex = 22,
        Parent = DialogCard,
    }, {
        New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
        New("UIPadding", { PaddingTop = UDim.new(0, 6) }),
    })

    function Window:Dialog(Options)
        Options = Options or {}
        DialogTitle.Text = tostring(Options.Title or "Notice")
        DialogContent.Text = tostring(Options.Content or "")
        for _, Child in ipairs(DialogButtons:GetChildren()) do
            if Child:IsA("TextButton") then
                Child:Destroy()
            end
        end

        for Order, Spec in ipairs(Options.Buttons or { { Title = "OK" } }) do
            local Primary = Order == 1
            local Button = New("TextButton", {
                BackgroundColor3 = Primary and Theme.Accent or Theme.CardHover,
                Size = UDim2.new(1, 0, 0, 32),
                Font = Enum.Font.GothamMedium,
                Text = tostring(Spec.Title or "OK"),
                TextColor3 = Primary and Theme.AccentText or Theme.Text,
                TextSize = 13,
                LayoutOrder = Order,
                ZIndex = 23,
                Parent = DialogButtons,
            }, { Corner(8) })
            Button.MouseButton1Click:Connect(function()
                Dim.Visible = false
                Library:SafeCallback(Spec.Callback)
            end)
        end
        Dim.Visible = true
    end

    --------------------------- [[ Minimize ]] ---------------------------

    local Reopen = New("TextButton", {
        Name = "Reopen",
        Text = "",
        Position = UDim2.new(0, 16, 0.5, -24),
        Size = UDim2.fromOffset(48, 48),
        Visible = false,
        ZIndex = 10,
        Theme = { BackgroundColor3 = "Window" },
        Parent = Gui,
    }, {
        Corner(24),
        New("UIStroke", { Thickness = 2, Theme = { Color = "Accent" } }),
    })
    MakeLogo(Reopen, 36, { Position = UDim2.fromOffset(6, 6), ZIndex = 11 })

    local Motion = 0

    function Window:Minimize()
        self.Minimized = not self.Minimized
        Motion += 1
        local Token = Motion
        ClosePopup()

        if self.Minimized then
            Reopen.Visible = true
            Tween(Holder, 0.4, {
                Position = UDim2.new(ShownPosition.X.Scale, ShownPosition.X.Offset, 1.5, Holder.AbsoluteSize.Y),
            }, Enum.EasingStyle.Quart)
            task.delay(0.4, function()
                if Motion == Token then
                    Holder.Visible = false
                end
            end)
            if not self.MinimizeHintShown then
                self.MinimizeHintShown = true
                local Bind = Library.MinimizeKeybind
                local Key = Bind and type(Bind.Value) == "string" and Bind.Value or Library.MinimizeKey.Name
                Library:Notify({
                    Title = "Interface",
                    Content = ("Press %s or the logo button to bring it back."):format(Key),
                    Duration = 6,
                })
            end
        else
            Reopen.Visible = false
            Holder.Visible = true
            Tween(Holder, 0.4, { Position = ShownPosition })
        end
    end

    Reopen.MouseButton1Click:Connect(function()
        Window:Minimize()
    end)
    MinimizeLight.MouseButton1Click:Connect(function()
        Window:Minimize()
    end)

    ZoomLight.MouseButton1Click:Connect(function()
        Window.Zoomed = not Window.Zoomed
        ClosePopup()
        Tween(Holder, 0.3, {
            Size = Window.Zoomed
                and UDim2.fromOffset(math.min(Width + 160, Viewport.X - 20), math.min(Height + 140, Viewport.Y - 20))
                or UDim2.fromOffset(Width, Height),
        })
    end)

    CloseLight.MouseButton1Click:Connect(function()
        Window:Dialog({
            Title = "Close",
            Content = "Unload the interface? Anything it is running stops.",
            Buttons = {
                { Title = "Unload", Callback = function() Library:Destroy() end },
                { Title = "Cancel" },
            },
        })
    end)

    Track(UserInputService.InputBegan:Connect(function(Input)
        if Library.Picking or UserInputService:GetFocusedTextBox() then
            return
        end
        if Input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end
        local Bind = Library.MinimizeKeybind
        local Hit
        if Bind and type(Bind.Value) == "string" and Bind.Value ~= "None" then
            Hit = Input.KeyCode.Name == Bind.Value
        else
            Hit = Input.KeyCode == Library.MinimizeKey
        end
        if Hit then
            Window:Minimize()
        end
    end))

    --------------------------- [[ Search ]] ---------------------------

    local function ApplySearch()
        local Query = SearchBox.Text:lower()
        for _, Tab in ipairs(Window.Tabs) do
            local TitleHit = Query == "" or Tab.Title:lower():find(Query, 1, true) ~= nil
            local AnyHit = false
            for _, Item in ipairs(Tab.Items) do
                local Hit = TitleHit or Item.Text:find(Query, 1, true) ~= nil
                Item.Row.Visible = Hit
                AnyHit = AnyHit or Hit
            end
            Tab.Button.Visible = TitleHit or AnyHit
        end
        -- a folder shows while any tab in it matches, and opens up during a search
        for _, Folder in ipairs(Window.Folders) do
            local FolderHit = Query == "" or Folder.Title:lower():find(Query, 1, true) ~= nil
            local AnyChild = false
            for _, Tab in ipairs(Folder.Tabs) do
                if FolderHit and Query ~= "" then
                    Tab.Button.Visible = true
                end
                AnyChild = AnyChild or Tab.Button.Visible
            end
            Folder.Frame.Visible = FolderHit or AnyChild
            Folder.Children.Visible = Folder.Expanded or Query ~= ""
        end
    end
    SearchBox:GetPropertyChangedSignal("Text"):Connect(ApplySearch)

    --------------------------- [[ Elements ]] ---------------------------

    local function Fire(Element, ...)
        Library:SafeCallback(Element.Callback, ...)
        Library:SafeCallback(Element.Changed, ...)
    end

    -- A card row: title and description on the left, room for a control on the right
    local function MakeRow(Tab, Title, Description, ControlWidth, Clickable, TitleKey)
        Tab.Order += 1

        local Row = New(Clickable and "TextButton" or "Frame", {
            Size = UDim2.new(1, -8, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = CardAlpha,
            LayoutOrder = Tab.Order,
            Theme = { BackgroundColor3 = "Card" },
            Parent = Tab.Page,
        }, {
            Corner(9),
            New("UIPadding", {
                PaddingTop = UDim.new(0, 11), PaddingBottom = UDim.new(0, 11),
                PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
            }),
        })
        if Clickable then
            Row.Text = ""
        end

        local Texts = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, ControlWidth > 0 and -(ControlWidth + 10) or 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = Row,
        }, {
            New("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }),
        })

        local TitleLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = Enum.Font.GothamMedium,
            Text = tostring(Title or ""),
            TextSize = 13,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 1,
            Visible = Title ~= nil and tostring(Title) ~= "",
            Theme = { TextColor3 = TitleKey or "Text" },
            Parent = Texts,
        })

        local DescLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Font = Enum.Font.Gotham,
            Text = tostring(Description or ""),
            TextSize = 12,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 2,
            Visible = Description ~= nil and tostring(Description) ~= "",
            Theme = { TextColor3 = "SubText" },
            Parent = Texts,
        })

        Row.MouseEnter:Connect(function()
            Tween(Row, 0.15, { BackgroundColor3 = Theme.CardHover })
        end)
        Row.MouseLeave:Connect(function()
            Tween(Row, 0.15, { BackgroundColor3 = Theme.Card })
        end)

        table.insert(Tab.Items, {
            Row = Row,
            Text = (tostring(Title or "") .. " " .. tostring(Description or "")):lower(),
        })

        local Element = { Frame = Row }
        function Element:SetTitle(Text)
            TitleLabel.Text = tostring(Text or "")
            TitleLabel.Visible = TitleLabel.Text ~= ""
        end
        function Element:SetDesc(Text)
            DescLabel.Text = tostring(Text or "")
            DescLabel.Visible = DescLabel.Text ~= ""
        end
        function Element:OnChanged(Callback)
            self.Changed = Callback
            Library:SafeCallback(Callback, self.Value)
        end
        function Element:Destroy()
            Row:Destroy()
        end
        return Row, Element
    end

    local function ControlProps(Width, Height, Extra)
        local Props = {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(Width, Height),
        }
        for Key, Value in pairs(Extra or {}) do
            Props[Key] = Value
        end
        return Props
    end

    local function MakeContainer(Tab)
        local Container = {}

        function Container:AddSection(Title)
            Tab.Order += 1
            New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -8, 0, 28),
                Font = Enum.Font.GothamBold,
                Text = tostring(Title or ""),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Bottom,
                LayoutOrder = Tab.Order,
                Theme = { TextColor3 = "Text" },
                Parent = Tab.Page,
            }, { New("UIPadding", { PaddingLeft = UDim.new(0, 2), PaddingBottom = UDim.new(0, 4) }) })
            return MakeContainer(Tab)
        end

        function Container:AddParagraph(Options)
            Options = Options or {}
            local _, Element = MakeRow(Tab, Options.Title, Options.Content, 0, false)
            Element.Type = "Paragraph"
            return Element
        end

        function Container:AddButton(Options)
            Options = Options or {}
            local Row, Element = MakeRow(Tab, Options.Title, Options.Description, 0, true, "Accent")
            Element.Type = "Button"
            Element.Callback = Options.Callback
            Row.MouseButton1Click:Connect(function()
                Row.BackgroundColor3 = Theme.Stroke
                Tween(Row, 0.3, { BackgroundColor3 = Theme.CardHover })
                Library:SafeCallback(Element.Callback)
            end)
            return Element
        end

        function Container:AddToggle(Id, Options)
            Options = Options or {}
            local Row, Element = MakeRow(Tab, Options.Title, Options.Description, 38, true)
            Element.Type = "Toggle"
            Element.Value = Options.Default and true or false
            Element.Callback = Options.Callback

            local Switch = New("Frame", ControlProps(38, 20, { Parent = Row }), { Corner(10) })
            local Knob = New("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                Position = UDim2.fromOffset(2, 2),
                Size = UDim2.fromOffset(16, 16),
                Parent = Switch,
            }, { Corner(8) })

            local function Paint(Animate)
                local Color = Element.Value and Theme.Accent or Theme.ToggleOff
                local Position = Element.Value and UDim2.fromOffset(20, 2) or UDim2.fromOffset(2, 2)
                if Animate then
                    Tween(Switch, 0.15, { BackgroundColor3 = Color })
                    Tween(Knob, 0.15, { Position = Position })
                else
                    Switch.BackgroundColor3 = Color
                    Knob.Position = Position
                end
            end
            table.insert(Refreshers, Paint)

            function Element:SetValue(Value)
                self.Value = Value and true or false
                Paint(true)
                Fire(self, self.Value)
            end

            Row.MouseButton1Click:Connect(function()
                Element:SetValue(not Element.Value)
            end)

            Paint(false)
            if Id then
                Library.Options[Id] = Element
            end
            Fire(Element, Element.Value)
            return Element
        end

        function Container:AddDropdown(Id, Options)
            Options = Options or {}
            local Row, Element = MakeRow(Tab, Options.Title, Options.Description, 150, false)
            Element.Type = "Dropdown"
            Element.Values = Options.Values or {}
            Element.Multi = Options.Multi and true or false
            Element.AllowNull = Options.AllowNull and true or false
            Element.Opened = false
            Element.Callback = Options.Callback
            Element.Value = Element.Multi and {} or nil

            local Button = New("TextButton", ControlProps(150, 28, {
                Font = Enum.Font.Gotham,
                Text = "--",
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Theme = { BackgroundColor3 = "Field", TextColor3 = "Text" },
                Parent = Row,
            }), {
                Corner(7),
                New("UIStroke", {
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    Theme = { Color = "Stroke" },
                }),
                New("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 24) }),
            })

            New("ImageLabel", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 18, 0.5, 0),
                Size = UDim2.fromOffset(14, 14),
                Image = "rbxassetid://10709790948",
                Theme = { ImageColor3 = "SubText" },
                Parent = Button,
            })

            function Element:Display()
                local Text
                if self.Multi then
                    local Names = {}
                    for _, Value in ipairs(self.Values) do
                        if self.Value[Value] then
                            table.insert(Names, tostring(Value))
                        end
                    end
                    Text = table.concat(Names, ", ")
                else
                    Text = self.Value ~= nil and tostring(self.Value) or ""
                end
                Button.Text = Text ~= "" and Text or "--"
            end

            -- Multi takes { Name = true } or { "Name", ... }; names outside Values are dropped
            function Element:SetValue(Value)
                if self.Multi then
                    local Picked = {}
                    if type(Value) == "table" then
                        for Key, Entry in pairs(Value) do
                            local Name
                            if type(Key) == "number" then
                                Name = Entry
                            elseif Entry then
                                Name = Key
                            end
                            if Name ~= nil and table.find(self.Values, Name) then
                                Picked[Name] = true
                            end
                        end
                    end
                    self.Value = Picked
                elseif Value == nil then
                    self.Value = nil
                elseif table.find(self.Values, Value) then
                    self.Value = Value
                end
                self:Display()
                Fire(self, self.Value)
            end

            function Element:SetValues(Values)
                self.Values = Values or {}
                if PopupState.Owner == self then
                    FillPopup()
                end
            end

            Button.MouseButton1Click:Connect(function()
                if PopupState.Owner == Element then
                    ClosePopup()
                else
                    OpenPopup(Element, Button)
                end
            end)

            -- set without firing: a default is not a change
            local Default = Options.Default
            if Element.Multi then
                if type(Default) == "string" then
                    Default = { Default }
                end
                if type(Default) == "table" then
                    for Key, Entry in pairs(Default) do
                        local Name
                        if type(Key) == "number" then
                            Name = Entry
                        elseif Entry then
                            Name = Key
                        end
                        if Name ~= nil and table.find(Element.Values, Name) then
                            Element.Value[Name] = true
                        end
                    end
                end
            elseif type(Default) == "number" and Element.Values[Default] ~= nil then
                Element.Value = Element.Values[Default]
            elseif Default ~= nil and table.find(Element.Values, Default) then
                Element.Value = Default
            end
            Element:Display()

            if Id then
                Library.Options[Id] = Element
            end
            return Element
        end

        function Container:AddInput(Id, Options)
            Options = Options or {}
            local Row, Element = MakeRow(Tab, Options.Title, Options.Description, 150, false)
            Element.Type = "Input"
            Element.Callback = Options.Callback
            Element.Value = tostring(Options.Default or "")

            local Box = New("TextBox", ControlProps(150, 28, {
                ClearTextOnFocus = false,
                ClipsDescendants = true,
                Font = Enum.Font.Gotham,
                PlaceholderText = tostring(Options.Placeholder or ""),
                Text = Element.Value,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Theme = { BackgroundColor3 = "Field", TextColor3 = "Text", PlaceholderColor3 = "SubText" },
                Parent = Row,
            }), {
                Corner(7),
                New("UIStroke", {
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    Theme = { Color = "Stroke" },
                }),
                New("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9) }),
            })

            function Element:SetValue(Text)
                Text = tostring(Text or "")
                if Options.MaxLength and #Text > Options.MaxLength then
                    Text = Text:sub(1, Options.MaxLength)
                end
                if Options.Numeric and Text ~= "" and tonumber(Text) == nil then
                    Text = self.Value
                end
                self.Value = Text
                Box.Text = Text
                Fire(self, Text)
            end

            if Options.Finished then
                Box.FocusLost:Connect(function()
                    Element:SetValue(Box.Text)
                end)
            else
                Box:GetPropertyChangedSignal("Text"):Connect(function()
                    if Box.Text ~= Element.Value then
                        Element:SetValue(Box.Text)
                    end
                end)
            end

            if Id then
                Library.Options[Id] = Element
            end
            return Element
        end

        function Container:AddSlider(Id, Options)
            Options = Options or {}
            local Row, Element = MakeRow(Tab, Options.Title, Options.Description, 150, false)
            local Min, Max = Options.Min or 0, Options.Max or 100
            Element.Type = "Slider"
            Element.Min, Element.Max, Element.Rounding = Min, Max, Options.Rounding or 0
            Element.Callback = Options.Callback

            local Control = New("Frame", ControlProps(150, 20, { BackgroundTransparency = 1, Parent = Row }))

            local ValueLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.new(0, 38, 1, 0),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right,
                Theme = { TextColor3 = "SubText" },
                Parent = Control,
            })

            local Hit = New("TextButton", {
                Text = "",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -46, 1, 0),
                Parent = Control,
            })

            local Bar = New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.new(1, 0, 0, 4),
                Theme = { BackgroundColor3 = "ToggleOff" },
                Parent = Hit,
            }, { Corner(2) })

            local Fill = New("Frame", {
                Size = UDim2.fromScale(0, 1),
                Theme = { BackgroundColor3 = "Accent" },
                Parent = Bar,
            }, { Corner(2) })

            local Knob = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.new(1, 1, 1),
                Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.fromOffset(12, 12),
                Parent = Bar,
            }, { Corner(6) })

            function Element:SetValue(Value)
                Value = math.clamp(tonumber(Value) or Min, Min, Max)
                local Factor = 10 ^ self.Rounding
                Value = math.floor(Value * Factor + 0.5) / Factor
                self.Value = Value

                local Alpha = Max > Min and (Value - Min) / (Max - Min) or 0
                Fill.Size = UDim2.fromScale(Alpha, 1)
                Knob.Position = UDim2.fromScale(Alpha, 0.5)
                ValueLabel.Text = tostring(Value)
                Fire(self, Value)
            end

            local Sliding = false
            local function SlideTo(Input)
                local Alpha = math.clamp((Input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                local Before = Element.Value
                local Factor = 10 ^ Element.Rounding
                local Value = math.floor((Min + (Max - Min) * Alpha) * Factor + 0.5) / Factor
                if Value ~= Before then
                    Element:SetValue(Value)
                end
            end

            Hit.InputBegan:Connect(function(Input)
                if IsPress(Input) then
                    Sliding = true
                    SlideTo(Input)
                end
            end)
            Track(UserInputService.InputChanged:Connect(function(Input)
                if Sliding and IsMove(Input) then
                    SlideTo(Input)
                end
            end))
            Track(UserInputService.InputEnded:Connect(function(Input)
                if IsPress(Input) then
                    Sliding = false
                end
            end))

            if Id then
                Library.Options[Id] = Element
            end
            Element:SetValue(Options.Default or Min)
            return Element
        end

        function Container:AddKeybind(Id, Options)
            Options = Options or {}
            local Row, Element = MakeRow(Tab, Options.Title, Options.Description, 96, false)
            Element.Type = "Keybind"
            Element.Value = tostring(Options.Default or "None")
            Element.Mode = Options.Mode or "Toggle"
            Element.Toggled = false
            Element.Callback = Options.Callback

            local Button = New("TextButton", ControlProps(96, 28, {
                Font = Enum.Font.GothamMedium,
                Text = Element.Value,
                TextSize = 12,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Theme = { BackgroundColor3 = "Field", TextColor3 = "Text" },
                Parent = Row,
            }), {
                Corner(7),
                New("UIStroke", {
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    Theme = { Color = "Stroke" },
                }),
            })

            function Element:SetValue(Key, Mode)
                self.Value = tostring(Key or self.Value)
                self.Mode = Mode or self.Mode
                Button.Text = self.Value
            end

            function Element:GetState()
                return self.Toggled
            end

            function Element:OnClick(Callback)
                self.Clicked = Callback
            end

            Button.MouseButton1Click:Connect(function()
                if Library.Picking then
                    return
                end
                Library.Picking = true
                Button.Text = "..."

                local Listener
                Listener = UserInputService.InputBegan:Connect(function(Input)
                    if Input.UserInputType ~= Enum.UserInputType.Keyboard then
                        return
                    end
                    Listener:Disconnect()
                    if Input.KeyCode ~= Enum.KeyCode.Escape then
                        Element:SetValue(Input.KeyCode.Name)
                        Library:SafeCallback(Options.ChangedCallback, Input.KeyCode)
                        Library:SafeCallback(Element.Changed, Element.Value)
                    else
                        Button.Text = Element.Value
                    end
                    task.defer(function()
                        Library.Picking = false
                    end)
                end)
                Track(Listener)
            end)

            Track(UserInputService.InputBegan:Connect(function(Input)
                if Library.Picking or Library.MinimizeKeybind == Element or UserInputService:GetFocusedTextBox() then
                    return
                end
                if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Element.Value then
                    Element.Toggled = not Element.Toggled
                    Library:SafeCallback(Element.Callback, Element.Toggled)
                    Library:SafeCallback(Element.Clicked, Element.Toggled)
                end
            end))

            if Id then
                Library.Options[Id] = Element
            end
            return Element
        end

        return Container
    end

    --------------------------- [[ Tabs ]] ---------------------------

    local function PaintTabs()
        for _, Tab in ipairs(Window.Tabs) do
            local Selected = Tab == Window.Selected
            Tab.Button.BackgroundTransparency = Selected and 0 or 1
            Tab.Button.BackgroundColor3 = Theme.Accent
            Tab.Button.TextColor3 = Selected and Theme.AccentText or Theme.Text
            Tab.Page.Visible = Selected
            if Tab.Icon then
                Tab.Icon.ImageColor3 = Tab.Button.TextColor3
            end
        end
        if Window.Selected then
            Header.Text = Window.Selected.Folder
                and (Window.Selected.Folder.Title .. "  /  " .. Window.Selected.Title)
                or Window.Selected.Title
        end
        -- a closed folder that holds the open tab is tinted so you can still find it
        for _, Folder in ipairs(Window.Folders) do
            local Holds = Window.Selected ~= nil and Window.Selected.Folder == Folder
            Folder.Label.TextColor3 = (Holds and not Folder.Expanded) and Theme.Accent or Theme.Text
            Folder.Chevron.ImageColor3 = (Holds and not Folder.Expanded) and Theme.Accent or Theme.SubText
            if Folder.Icon then
                Folder.Icon.ImageColor3 = Folder.Label.TextColor3
            end
        end
    end
    table.insert(Refreshers, PaintTabs)

    function Window:SelectTab(Index)
        local Tab = self.Tabs[Index]
        if Tab == nil then
            return
        end
        ClosePopup()
        self.Selected = Tab
        if Tab.Folder and not Tab.Folder.Expanded then
            Tab.Folder:SetExpanded(true)
        end
        PaintTabs()
    end

    local function NextSidebarOrder()
        Window.SidebarOrder += 1
        return Window.SidebarOrder
    end

    -- Shared by Window:AddTab and Folder:AddTab; Parent is the sidebar list or a folder's children.
    local function MakeTab(Options, Parent, Folder)
        Options = Options or {}
        local Index = #Window.Tabs + 1
        local HasIcon = type(Options.Icon) == "string" and Options.Icon:match("^rbx") ~= nil

        local Tab = MakeContainer(nil)
        Tab.Title = tostring(Options.Title or ("Tab " .. Index))
        Tab.Items = {}
        Tab.Order = 0
        Tab.Folder = Folder

        Tab.Button = New("TextButton", {
            Size = UDim2.new(1, -4, 0, 30),
            Font = Enum.Font.GothamMedium,
            Text = Tab.Title,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            LayoutOrder = NextSidebarOrder(),
            Parent = Parent,
        }, {
            Corner(8),
            New("UIPadding", { PaddingLeft = UDim.new(0, HasIcon and 32 or 10), PaddingRight = UDim.new(0, 8) }),
        })

        if HasIcon then
            Tab.Icon = New("ImageLabel", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, -24, 0.5, 0),
                Size = UDim2.fromOffset(16, 16),
                Image = Options.Icon,
                Parent = Tab.Button,
            })
        end

        Tab.Page = New("ScrollingFrame", {
            Name = Tab.Title,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.new(),
            ScrollBarThickness = 3,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Visible = false,
            ZIndex = 2,
            Theme = { ScrollBarImageColor3 = "Stroke" },
            Parent = Pages,
        })
        local Layout = New("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Tab.Page,
        })
        Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Tab.Page.CanvasSize = UDim2.fromOffset(0, Layout.AbsoluteContentSize.Y + 8)
        end)

        -- the container was built before the tab table existed; point its methods at it
        local Methods = MakeContainer(Tab)
        for Name, Method in pairs(Methods) do
            Tab[Name] = Method
        end

        Tab.Button.MouseButton1Click:Connect(function()
            Window:SelectTab(Index)
        end)

        table.insert(Window.Tabs, Tab)
        if Folder then
            table.insert(Folder.Tabs, Tab)
        end
        if Window.Selected == nil then
            Window.Selected = Tab
        end
        PaintTabs()
        return Tab
    end

    function Window:AddTab(Options)
        return MakeTab(Options, TabList, nil)
    end

    -- A collapsible group in the sidebar, like a folder in a file tree:
    --   local Lobby = Window:AddFolder({ Title = "Lobby", Icon = "rbxassetid://...", Expanded = true })
    --   local Party = Lobby:AddTab({ Title = "Party" })
    function Window:AddFolder(Options)
        Options = Options or {}
        local HasIcon = type(Options.Icon) == "string" and Options.Icon:match("^rbx") ~= nil
        local Folder = {
            Title = tostring(Options.Title or "Folder"),
            Expanded = Options.Expanded ~= false,
            Tabs = {},
        }

        Folder.Frame = New("Frame", {
            Name = Folder.Title,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = NextSidebarOrder(),
            Parent = TabList,
        }, {
            New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
        })

        Folder.Header = New("TextButton", {
            Text = "",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -4, 0, 28),
            LayoutOrder = 1,
            Theme = { BackgroundColor3 = "CardHover" },
            Parent = Folder.Frame,
        }, { Corner(8) })

        Folder.Chevron = New("ImageLabel", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, 14, 0.5, 0),
            Size = UDim2.fromOffset(14, 14),
            Image = "rbxassetid://10709790948",
            Rotation = Folder.Expanded and 0 or -90,
            Theme = { ImageColor3 = "SubText" },
            Parent = Folder.Header,
        })

        if HasIcon then
            Folder.Icon = New("ImageLabel", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 26, 0.5, 0),
                Size = UDim2.fromOffset(16, 16),
                Image = Options.Icon,
                Theme = { ImageColor3 = "Text" },
                Parent = Folder.Header,
            })
        end

        Folder.Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(HasIcon and 48 or 28, 0),
            Size = UDim2.new(1, HasIcon and -52 or -32, 1, 0),
            Font = Enum.Font.GothamBold,
            Text = Folder.Title,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Theme = { TextColor3 = "Text" },
            Parent = Folder.Header,
        })

        -- Children holds a guide line down the left (like a file tree) and, beside it,
        -- the indented list the tabs go in. Only the inner list has a layout, so the line stays put.
        Folder.Children = New("Frame", {
            Name = "Children",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 2,
            Visible = Folder.Expanded,
            Parent = Folder.Frame,
        })

        Folder.List = New("Frame", {
            Name = "List",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = Folder.Children,
        }, {
            New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
            New("UIPadding", { PaddingLeft = UDim.new(0, 22) }),
        })

        local Guide = New("Frame", {
            Name = "Guide",
            Position = UDim2.fromOffset(13, 2),
            Size = UDim2.fromOffset(1, 0),
            Theme = { BackgroundColor3 = "Stroke" },
            Parent = Folder.Children,
        })
        Folder.List:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            Guide.Size = UDim2.fromOffset(1, math.max(0, Folder.List.AbsoluteSize.Y - 4))
        end)

        function Folder:SetExpanded(Value)
            self.Expanded = Value and true or false
            self.Children.Visible = self.Expanded or SearchBox.Text ~= ""
            Tween(self.Chevron, 0.15, { Rotation = self.Expanded and 0 or -90 })
            PaintTabs()
        end

        function Folder:Toggle()
            self:SetExpanded(not self.Expanded)
        end

        function Folder:AddTab(TabOptions)
            return MakeTab(TabOptions, self.List, self)
        end

        Folder.Header.MouseEnter:Connect(function()
            Tween(Folder.Header, 0.15, { BackgroundTransparency = 0 })
        end)
        Folder.Header.MouseLeave:Connect(function()
            Tween(Folder.Header, 0.15, { BackgroundTransparency = 1 })
        end)
        Folder.Header.MouseButton1Click:Connect(function()
            Folder:Toggle()
        end)

        table.insert(self.Folders, Folder)
        return Folder
    end

    Tween(Holder, 0.6, { Position = ShownPosition })
    return Window
end

Env.VaderUI_Instance = Library
return Library
end -- EmbeddedVaderUI

--------------------------- [[ VaderUI ]] ---------------------------

Collection:RaiseIdentity()

local LibraryLoaded, Library = pcall(EmbeddedVaderUI)
if not LibraryLoaded or Library == nil then
    warn("[vaderhug] couldn't load VaderUI: " .. tostring(Library))
    return
end

Collection.Options = Library.Options
Collection.Library = Library
Collection.UI = {}

function Collection:IsAlive()
    return GlobalEnv.vaderhug_run == RunId and not Library.Unloaded
end

-- SetValue drops names that aren't in Values (players who haven't loaded in yet), so add them first.
function Collection:SetDropdown(Option, Value)
    local Values = table.clone(Option.Values)
    local Changed = false
    local function Add(Name)
        if Name ~= nil and not table.find(Values, Name) then
            table.insert(Values, Name)
            Changed = true
        end
    end
    if Option.Multi then
        if type(Value) == "table" then
            for Key, Entry in pairs(Value) do
                if type(Key) == "number" then Add(Entry) elseif Entry then Add(Key) end
            end
        end
    else
        Add(Value)
    end
    if Changed then
        Option:SetValues(Values)
    end
    Option:SetValue(Value)
end

function Party:ServerNames()
    local Names = {}
    for _, Player in ipairs(Players:GetPlayers()) do
        table.insert(Names, Player.Name)
    end
    table.sort(Names)
    return Names
end

-- Server players, plus whoever is already picked even if they left.
function Party:RefreshLists()
    local Options = Collection.Options
    local Hosts = self:ServerNames()
    local Host = Options.PartyHost.Value
    if Host and not table.find(Hosts, Host) then
        table.insert(Hosts, Host)
    end
    Options.PartyHost:SetValues(Hosts)

    local Members = self:ServerNames()
    for Name, On in pairs(Options.PartyMembers.Value) do
        if On and not table.find(Members, Name) then
            table.insert(Members, Name)
        end
    end
    Options.PartyMembers:SetValues(Members)
end

local Window = Library:CreateWindow({
    Title = "Anime Mysterious",
    SubTitle = "by vaderhug",
    TabWidth = 150,
    Size = UDim2.fromOffset(560, 440),
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl,
})

-- Sidebar folders; an older VaderUI without AddFolder gets flat "Lobby / Party" style tabs instead.
function Collection:AddFolder(Title)
    if Window.AddFolder then
        return Window:AddFolder({ Title = Title })
    end
    return {
        AddTab = function(_, Options)
            Options.Title = Title .. " / " .. Options.Title
            return Window:AddTab(Options)
        end,
    }
end

-- Both folders in both places. Lobby tabs only act in the lobby and In-Game tabs only in a match,
-- but either can be set up from anywhere.
do
    Collection.Tabs = {}
    local Lobby = Collection:AddFolder("Lobby")
    for _, Name in ipairs({ "Party", "Play", "Challenge", "Summon", "Units", "Missions", "Shop" }) do
        Collection.Tabs[Name] = Lobby:AddTab({ Title = Name })
    end
    local InGame = Collection:AddFolder("In-Game")
    Collection.Tabs.Match = InGame:AddTab({ Title = "Match" })
    Collection.Tabs.Spawn = InGame:AddTab({ Title = "Spawn" })
    Collection.Tabs.Macro = InGame:AddTab({ Title = "Macro" })
    Collection.Tabs.Webhook = Window:AddTab({ Title = "Webhook" })
    Collection.Tabs.Settings = Window:AddTab({ Title = "Settings" })
end

--------------------------- [[ Party Tab ]] ---------------------------

do
    local Tab = Collection.Tabs.Party

    Collection.UI.Status = Tab:AddParagraph({ Title = "Status", Content = "Party off" })

    local Setup = Tab:AddSection("Party")

    Setup:AddToggle("PartyEnabled", {
        Title = "Party mode",
        Description = "The host makes the room and starts; everyone else joins it. Host with no members = solo auto start.",
        Default = false,
    })

    Setup:AddDropdown("PartyHost", {
        Title = "Party host",
        Description = "Pick the leader. Set it on any account and the others follow (with sharing on).",
        Values = Party:ServerNames(),
        Default = LocalPlayer.Name,
        Callback = function()
            Party:PublishShared()
        end,
    })

    Setup:AddDropdown("PartyMembers", {
        Title = "Members",
        Description = "Who the host waits for. Anyone else who joins gets kicked (if on).",
        Values = Party:ServerNames(),
        Multi = true,
        Default = {},
        Callback = function()
            Party:PublishShared()
        end,
    })

    Setup:AddButton({
        Title = "Refresh player list",
        Callback = function()
            Party:RefreshLists()
        end,
    })

    Setup:AddToggle("ShareParty", {
        Title = "Share with my other accounts",
        Description = "Host and members sync through Vaderhug/AnimeMys/Party.json for every account on this PC",
        Default = true,
    })

    Setup:AddToggle("FollowHost", {
        Title = "Follow host to their server",
        Description = "Members on this PC hop to the host's lobby server when the host isn't here",
        Default = true,
    })

    local Host = Tab:AddSection("Host")

    Host:AddToggle("AutoStart", {
        Title = "Auto start",
        Description = "Start the match once every member is in the room",
        Default = false,
    })

    Host:AddSlider("WaitTimeout", {
        Title = "Wait for members (s)",
        Description = "Start anyway after this long. 0 waits forever.",
        Min = 0,
        Max = 300,
        Default = 90,
        Rounding = 0,
    })

    Host:AddToggle("KickStrangers", {
        Title = "Kick strangers",
        Description = "Kick anyone in the room who isn't a picked member",
        Default = true,
    })

    Host:AddButton({
        Title = "Start now",
        Description = "Start with whoever is in the room",
        Callback = function()
            Party.ForceStart = true
            Party.StartedAt = nil
        end,
    })

    Host:AddButton({
        Title = "Leave room",
        Callback = function()
            Party:Leave()
        end,
    })
end

--------------------------- [[ Play Tab ]] ---------------------------

do
    local Tab = Collection.Tabs.Play
    local Options = Collection.Options

    Collection.UI.PlayInfo = Tab:AddParagraph({ Title = "Next match", Content = "-" })
    Collection.UI.JoinStatus = Tab:AddParagraph({ Title = "Status", Content = "Party off" })

    local Join = Tab:AddSection("Auto join")

    Join:AddToggle("AutoJoin", {
        Title = "Auto join",
        Description = "Makes a room for the stage below and starts it, again after every match. With Party mode on, the party host does this instead.",
        Default = false,
    })

    Join:AddToggle("BestChapter", {
        Title = "Best chapter",
        Description = "Always pick the furthest map and highest stage you've unlocked in this mode",
        Default = false,
        Callback = function(Value)
            if Value and Options.AutoProgress and Options.AutoProgress.Value then
                Options.AutoProgress:SetValue(false)
            end
        end,
    })

    Join:AddToggle("AutoProgress", {
        Title = "Auto next stage",
        Description = "Play the first uncleared stage from the picked map onward (same mode)",
        Default = false,
        Callback = function(Value)
            if Value and Options.BestChapter and Options.BestChapter.Value then
                Options.BestChapter:SetValue(false)
            end
        end,
    })

    local Pick = Tab:AddSection("Stage")
    local StartMaps = Play:MapNames("Story")

    Pick:AddDropdown("PlayMode", {
        Title = "Mode",
        Values = Play.Modes,
        Default = "Story",
        Callback = function(Mode)
            local Names = Play:MapNames(Mode)
            Options.PlayMap:SetValues(Names)
            if not table.find(Names, Options.PlayMap.Value) then
                Options.PlayMap:SetValue(Names[1])
            end
        end,
    })

    Pick:AddDropdown("PlayMap", {
        Title = "Map",
        Description = "For Challenge: which challenge",
        Values = StartMaps,
        Default = 1,
        Callback = function(MapName)
            local Names = Play:StageNames(Options.PlayMode.Value, MapName)
            Options.PlayStage:SetValues(Names)
            if not table.find(Names, Options.PlayStage.Value) then
                Options.PlayStage:SetValue(Names[1])
            end
        end,
    })

    Pick:AddDropdown("PlayStage", {
        Title = "Stage",
        Values = Play:StageNames("Story", StartMaps[1]),
        Default = 1,
    })

    Pick:AddDropdown("PlayDifficulty", {
        Title = "Difficulty",
        Description = "Challenges are always Nightmare",
        Values = Play.Difficulties,
        Default = "Normal",
    })
end

--------------------------- [[ Challenge Tab ]] ---------------------------

do
    local Tab = Collection.Tabs.Challenge

    Collection.UI.ChallengeStatus = Tab:AddParagraph({ Title = "Challenges", Content = "-" })

    local Main = Tab:AddSection("Auto challenge")

    Main:AddToggle("AutoChallenge", {
        Title = "Auto challenge",
        Description = "Plays each picked challenge once per reset, then goes back to whatever Play is set to (e.g. an Event). Works with or without Auto join.",
        Default = false,
    })

    Main:AddDropdown("ChallengePick", {
        Title = "Challenges",
        Description = "Regular resets every 30 minutes, Daily every day, Weekly every week",
        Values = { "Regular", "Daily", "Weekly" },
        Multi = true,
        Default = { "Regular", "Daily", "Weekly" },
    })

    Main:AddSlider("ChallengeTries", {
        Title = "Tries per reset",
        Description = "A challenge you keep losing is skipped until it resets",
        Min = 1,
        Max = 5,
        Default = 2,
        Rounding = 0,
    })

    local Leave = Tab:AddSection("Leaving other matches")

    Leave:AddToggle("ChallengeLeave", {
        Title = "Return to lobby for a challenge",
        Description = "When a challenge resets while you're in another match, go back to the lobby when that match ends, run the challenge, then Play takes you back.",
        Default = true,
    })

    Leave:AddToggle("ChallengeLeaveNow", {
        Title = "Don't wait for the match to end",
        Description = "Forfeits the current match (a loss) to start the challenge right away",
        Default = false,
    })
end

--------------------------- [[ Summon Tab ]] ---------------------------

do
    local Tab = Collection.Tabs.Summon

    Collection.UI.SummonStatus = Tab:AddParagraph({ Title = "Status", Content = "Auto summon off" })

    local Main = Tab:AddSection("Summon")

    Main:AddToggle("AutoSummon", {
        Title = "Auto summon",
        Description = "Keeps summoning until the currency runs out or a stop rule hits",
        Default = false,
    })

    Main:AddDropdown("SummonBanner", {
        Title = "Banner",
        Description = "Standard costs Gems, Fate costs Fate Coins",
        Values = Summon.Banners,
        Default = "Standard",
    })

    Main:AddDropdown("SummonAmount", {
        Title = "Summons per roll",
        Values = Summon.Amounts,
        Default = "10",
    })

    Main:AddSlider("SummonDelay", {
        Title = "Delay between rolls (s)",
        Min = 0.5,
        Max = 10,
        Default = 1.5,
        Rounding = 1,
    })

    local Rules = Tab:AddSection("Rules")

    Rules:AddDropdown("SummonAutoSell", {
        Title = "Auto sell",
        Description = "Sold by the server as they drop",
        Values = Summon.SellKeys,
        Multi = true,
        Default = {},
    })

    Rules:AddDropdown("SummonStopRarity", {
        Title = "Stop on rarity",
        Values = Summon.StopRarities,
        Multi = true,
        Default = { "Mythic", "Tactical" },
    })

    Rules:AddToggle("SummonStopShiny", {
        Title = "Stop on shiny",
        Default = true,
    })
end

--------------------------- [[ Units Tab ]] ---------------------------

do
    local Tab = Collection.Tabs.Units

    Collection.UI.UnitInfo = Tab:AddParagraph({ Title = "Unit", Content = "Pick a unit" })
    Collection.UI.UnitStatus = Tab:AddParagraph({ Title = "Status", Content = "Idle" })

    local Pick = Tab:AddSection("Unit")

    Pick:AddDropdown("UnitPick", {
        Title = "Unit",
        Description = "Everything below works on this unit",
        Values = {},
    })

    Pick:AddButton({
        Title = "Refresh units",
        Callback = function()
            Units.ListKey = nil
            Units:Refresh()
        end,
    })

    Pick:AddToggle("UseGameStops", {
        Title = "Use my in-game stop lists",
        Description = "Also stops on the traits ticked in the game's Auto Reroll settings, and never rerolls a potential grade ticked there (S, SS, SSS, 神 by default)",
        Default = true,
    })

    Pick:AddSlider("RollDelay", {
        Title = "Delay between rolls (s)",
        Min = 0.2,
        Max = 5,
        Default = 0.5,
        Rounding = 1,
    })

    local Trait = Tab:AddSection("Trait reroll")
    local TraitLabels, TraitToKey = Units:TraitLabels()
    Units.TraitToKey = TraitToKey

    Trait:AddToggle("AutoTrait", {
        Title = "Auto trait reroll",
        Description = "Uses 1 Trait Reroll per roll; stops on a picked trait (main or sub)",
        Default = false,
    })

    Trait:AddDropdown("TraitTargets", {
        Title = "Stop on trait",
        Values = TraitLabels,
        Multi = true,
        Default = {},
    })

    local Potential = Tab:AddSection("Potential reroll")

    Potential:AddToggle("AutoPotential", {
        Title = "Auto potential reroll",
        Description = "One stat uses Stat Reroll, All uses Stat Reroll All. Runs when trait reroll is off.",
        Default = false,
    })

    Potential:AddDropdown("PotentialStat", {
        Title = "Stat",
        Values = { "All", "Attack", "Health", "Speed", "Cooldown", "Range" },
        Default = "Attack",
    })

    Potential:AddDropdown("PotentialGrade", {
        Title = "Target grade",
        Description = "D, C, B, A, S, SS, SSS, 神 (worst to best)",
        Values = Units.Grades,
        Default = "S",
    })

    Potential:AddSlider("PotentialCount", {
        Title = "Stats at target (All only)",
        Description = "With All: stop once this many stats reach the target",
        Min = 1,
        Max = 5,
        Default = 2,
        Rounding = 0,
    })

    local Feed = Tab:AddSection("Feed")
    local FeedLabels, FeedToId = Collection:ItemLabels(Units:FeedItems())
    Units.FeedToId = FeedToId

    Feed:AddToggle("AutoFeed", {
        Title = "Auto feed to max level",
        Description = "Feeds the picked food, cheapest first, only as much as max level needs",
        Default = false,
    })

    Feed:AddDropdown("FeedItems", {
        Title = "Food to use",
        Values = FeedLabels,
        Multi = true,
        Default = {},
    })

    local Evolve = Tab:AddSection("Evolve")

    Evolve:AddToggle("AutoEvolve", {
        Title = "Evolve when ready",
        Description = "Evolves once the level, Coins and items are all there, then turns itself off",
        Default = false,
    })

    Evolve:AddButton({
        Title = "Evolve now",
        Callback = function()
            local Unit = Units:Selected()
            if Unit then
                task.spawn(function() Units:Evolve(Unit) end)
            end
        end,
    })
end

--------------------------- [[ Match Tab ]] ---------------------------

do
    local Tab = Collection.Tabs.Match

    Collection.UI.MatchStatus = Tab:AddParagraph({
        Title = "Status",
        Content = Collection.InLobby and "In the lobby - these settings apply in your next match" or "Waiting for the match to start",
    })

    local Start = Tab:AddSection("Start")

    Start:AddToggle("AutoVoteStart", {
        Title = "Auto vote start",
        Default = false,
    })

    Start:AddDropdown("GameSpeed", {
        Title = "Game speed",
        Description = "3x needs the game's 3x speed pass",
        Values = { "Don't change", "1x", "1.5x", "3x (gamepass)" },
        Default = "Don't change",
    })

    Start:AddToggle("AutoSkipWave", {
        Title = "Auto skip wave",
        Description = "Votes skip whenever the next-wave countdown shows",
        Default = false,
    })

    local Fight = Tab:AddSection("Units")

    Fight:AddToggle("GameAutoplay", {
        Title = "Game autoplay",
        Description = "The game's own built-in autoplay (the server spawns for you). Paused while a macro records or plays.",
        Default = false,
        Callback = function(Value)
            if not Value and not Collection.InLobby and LocalPlayer:GetAttribute("AutoPlay") == true then
                Match:Fire("ToggleAutoplay", false)
            end
        end,
    })

    Fight:AddToggle("AutoUpgradeUnits", {
        Title = "Auto upgrade units",
        Description = "Keeps upgrading your lowest-level unit on the field",
        Default = false,
    })

    Fight:AddToggle("AutoUltimate", {
        Title = "Auto ultimate",
        Description = "Turns on the game's auto ultimate for every unit you spawn",
        Default = false,
    })

    local After = Tab:AddSection("After the match")

    After:AddDropdown("AfterMatch", {
        Title = "When it ends",
        Description = "Back to lobby pairs with Play > Auto join. Challenge matches always go back to the lobby.",
        Values = { "Nothing", "Retry", "Next stage (retry if lost)", "Back to lobby" },
        Default = "Nothing",
    })

    After:AddButton({
        Title = "Return to Lobby",
        Description = "Leaves now. During a match this forfeits it first (counts as a loss).",
        Callback = function()
            if Collection.InLobby then
                Collection.Library:Notify({ Title = "vaderhug", Content = "You're already in the lobby", Duration = 3 })
                return
            end
            task.spawn(Match.ReturnToLobby, Match)
        end,
    })

    local Dev = Tab:AddSection("Developer")

    Dev:AddToggle("SpyMatch", {
        Title = "Log match remotes",
        Description = "Runs claude_spy_src.lua in the match place (log: claude_spy.log)",
        Default = false,
    })
end

--------------------------- [[ Spawn Tab ]] ---------------------------

do
    local Tab = Collection.Tabs.Spawn

    Collection.UI.SpawnStatus = Tab:AddParagraph({ Title = "Spawn order", Content = "-" })

    local Main = Tab:AddSection("Auto spawn")

    Main:AddToggle("AutoSpawn", {
        Title = "Auto spawn",
        Description = "Spawns by the priorities below whenever a slot is off cooldown, under its unit cap and affordable. Pauses while a macro records or plays.",
        Default = false,
    })

    Main:AddToggle("SpawnSaveYen", {
        Title = "Save yen for higher priority",
        Description = "When the top slot is only short on yen, lower slots wait instead of spending it. Off: whatever is affordable spawns.",
        Default = true,
    })

    local Order = Tab:AddSection("Priority (1 = first, Off = never)")
    local Ranks = { "Off", "1", "2", "3", "4", "5", "6" }
    for Slot = 1, 6 do
        Order:AddDropdown("SpawnPriority" .. Slot, {
            Title = "Slot " .. Slot,
            Description = Match:SlotText(Slot),
            Values = Ranks,
            Default = tostring(Slot),
            Callback = function()
                pcall(Match.ShowSpawnOrder, Match)
            end,
        })
    end
end

--------------------------- [[ Webhook Tab ]] ---------------------------

do
    local Tab = Collection.Tabs.Webhook

    Collection.UI.WebhookStatus = Tab:AddParagraph({ Title = "Status", Content = "Nothing sent yet" })

    local Hook = Tab:AddSection("Discord")

    Hook:AddInput("WebhookUrl", {
        Title = "Webhook URL",
        Description = "Discord channel > Edit > Integrations > Webhooks > Copy URL. Saved in your config file.",
        Placeholder = "https://discord.com/api/webhooks/...",
        Default = "",
        Finished = true,
    })

    Hook:AddToggle("WebhookOnEnd", {
        Title = "Send result when a match ends",
        Description = "Victory!/Lost! with map, mobs killed, time, damage, EXP and rewards",
        Default = false,
    })

    Hook:AddButton({
        Title = "Send test",
        Description = "Sends your last match result, or a sample one",
        Callback = function()
            task.spawn(function()
                local Result = Match.LastResult or {
                    Won = true, Map = "GreenForest", Stage = 1, Difficulty = "Normal", Time = 135,
                    Exp = { { GainedExp = 120 }, { GainedExp = 80 } },
                    Rewards = { Coins = 50, Gems = 5 },
                    Stats = { Takedowns = 42, TotalDmg = 12345 },
                }
                local Sent, Why = Collection:SendResult(Result, true)
                Collection:SetPara("WebhookStatus", Sent and ("Test sent " .. os.date("%H:%M")) or ("Test failed: " .. tostring(Why)))
            end)
        end,
    })
end

--------------------------- [[ Macro Tab ]] ---------------------------

do
    local Tab = Collection.Tabs.Macro

    Collection.UI.MacroStatus = Tab:AddParagraph({ Title = "Status", Content = "Idle" })
    Collection.UI.MacroInfo = Tab:AddParagraph({ Title = "Picked macro", Content = "No macro picked" })

    local Record = Tab:AddSection("Record")

    Record:AddInput("MacroName", {
        Title = "Macro name",
        Placeholder = "e.g. namek-1",
        Default = "",
        MaxLength = 40,
        Finished = true,
    })

    Record:AddToggle("MacroRecord", {
        Title = "Record",
        Description = "Turn on, then play a match yourself. Spawns, upgrades, sells, ultimates, Hunt/Defend, skips and speed are saved when the match ends (or when you turn this off).",
        Default = false,
        Callback = function(Value)
            if not Macro.Ready then return end
            if Value then
                Macro:StartRecording()
            else
                Macro:StopRecording()
            end
        end,
    })

    local PlaySection = Tab:AddSection("Play")

    PlaySection:AddDropdown("MacroPick", {
        Title = "Macro",
        Values = Macro:List(),
        Callback = function(Name)
            Collection:SetPara("MacroInfo", Macro:Describe(Name))
        end,
    })

    PlaySection:AddToggle("MacroPlay", {
        Title = "Play macro",
        Description = "Plays the picked macro from the start of every match",
        Default = false,
        Callback = function(Value)
            if Value and Macro.Ready and Match:Started() and not Macro.Playing then
                task.spawn(Macro.Play, Macro, Collection.Options.MacroPick.Value)
            elseif not Value then
                Macro.PlayToken = nil
            end
        end,
    })

    PlaySection:AddDropdown("MacroTiming", {
        Title = "Step timing",
        Description = "Time: same second as the recording. Yen: as soon as you have the yen it had. Time + Yen: both.",
        Values = Macro.Timings,
        Default = "Time + Yen",
    })

    PlaySection:AddButton({
        Title = "Refresh macros",
        Callback = function()
            Macro:RefreshList()
        end,
    })

    PlaySection:AddButton({
        Title = "Delete picked macro",
        Callback = function()
            local Name = Collection.Options.MacroPick.Value
            if not Name then return end
            Window:Dialog({
                Title = "Delete macro",
                Content = "Delete " .. Name .. "?",
                Buttons = {
                    {
                        Title = "Delete",
                        Callback = function()
                            pcall(delfile, Macro:Path(Name))
                            Collection.Options.MacroPick:SetValue(nil)
                            Macro:RefreshList()
                        end,
                    },
                    { Title = "Cancel" },
                },
            })
        end,
    })
end

--------------------------- [[ Missions Tab ]] ---------------------------

do
    local Tab = Collection.Tabs.Missions

    Collection.UI.ClaimStatus = Tab:AddParagraph({ Title = "Status", Content = "Auto claim off" })

    local Main = Tab:AddSection("Auto claim")

    Main:AddToggle("AutoClaim", {
        Title = "Auto claim",
        Description = "Checks every 30 seconds",
        Default = false,
    })

    Main:AddToggle("ClaimQuests", {
        Title = "Quests",
        Description = "Daily / weekly / story quests and the guidebook chapters",
        Default = true,
    })

    Main:AddToggle("ClaimDaily", {
        Title = "Daily login reward",
        Default = true,
    })

    Main:AddToggle("ClaimRewards", {
        Title = "Level, battle pass and unit index rewards",
        Default = true,
    })

    local Codes = Tab:AddSection("Codes")

    Codes:AddButton({
        Title = "Redeem all codes",
        Description = "Every active code in the game's list (they need group membership)",
        Callback = function()
            task.spawn(function()
                local Lines = Claim:RedeemAll()
                Collection:RaiseIdentity()
                Library:Notify({
                    Title = "Codes",
                    Content = #Lines > 0 and table.concat(Lines, "\n") or "No active codes",
                    Duration = 10,
                })
            end)
        end,
    })
end

--------------------------- [[ Shop Tab ]] ---------------------------

do
    local Tab = Collection.Tabs.Shop

    Collection.UI.ShopStatus = Tab:AddParagraph({ Title = "Status", Content = "Auto buy off" })

    local Main = Tab:AddSection("Auto buy")

    Main:AddToggle("AutoBuy", {
        Title = "Auto buy",
        Description = "Buys the picked items whenever stock and currency allow (checks every minute)",
        Default = false,
    })

    Main:AddSlider("GemReserve", {
        Title = "Keep at least this many Gems",
        Description = "Gem shop and Standard summons won't spend below it",
        Min = 0,
        Max = 50000,
        Default = 0,
        Rounding = 0,
    })

    Main:AddSlider("CoinReserve", {
        Title = "Keep at least this many Coins",
        Description = "Coin shop and base upgrades won't spend below it",
        Min = 0,
        Max = 200000,
        Default = 0,
        Rounding = 0,
    })

    Shop.LabelToId = {}
    for _, Info in ipairs(Shop.Shops) do
        local Items = Info.Items()
        local Labels = (Collection:LobbyLists().Shops or {})[Info.Key] or {}
        if type(Items) == "table" and #Items > 0 then
            local ToId
            Labels, ToId = Collection:ItemLabels(Items)
            Shop.LabelToId[Info.Key] = ToId
        end
        if #Labels > 0 then
            Main:AddDropdown("Shop" .. Info.Key, {
                Title = Info.Title,
                Description = "Paid with " .. Info.Currency,
                Values = Labels,
                Multi = true,
                Default = {},
            })
        end
    end

    local Merchant = Tab:AddSection("Merchant")

    Merchant:AddToggle("AutoMerchant", {
        Title = "Auto sell to merchant",
        Description = "Sells the picked materials for Coins, up to the merchant's hourly quota",
        Default = false,
    })

    local Keys = {}
    pcall(function() Keys = Collection.Modules.MerchantData.GetItemKeys() end)
    local MerchantItems = {}
    for _, Id in ipairs(Keys) do
        table.insert(MerchantItems, { ID = Id })
    end
    local Labels, ToId = Collection:ItemLabels(MerchantItems)
    Shop.LabelToId.Merchant = ToId
    if #Labels == 0 then
        Labels = Collection:LobbyLists().Merchant or {}
    end

    Merchant:AddDropdown("MerchantSell", {
        Title = "Sell these",
        Description = "Careful: some are evolution or crafting materials",
        Values = Labels,
        Multi = true,
        Default = {},
    })

    local Upgrades = Tab:AddSection("Base upgrades (Mysterious panel)")

    Collection.UI.UpgradeStatus = Upgrades:AddParagraph({ Title = "Levels", Content = "-" })

    Upgrades:AddToggle("AutoUpgrade", {
        Title = "Auto upgrade",
        Description = "Buys levels with Coins as soon as you can afford them, cheapest first. Respects the Coins you keep and the level cap below.",
        Default = false,
    })

    local UpgradeLabels = {}
    for _, Stat in ipairs(Shop.UpgradeStats) do
        table.insert(UpgradeLabels, Stat.Label)
    end
    Upgrades:AddDropdown("UpgradeStatsPick", {
        Title = "Upgrade these",
        Description = "Maximum Yen = yen cap, Yen Generation = yen per second, Tower Health = base HP",
        Values = UpgradeLabels,
        Multi = true,
        Default = UpgradeLabels,
    })

    Upgrades:AddSlider("UpgradeMaxLevel", {
        Title = "Stop at level",
        Description = "50 is the game's max",
        Min = 1,
        Max = 50,
        Default = 50,
        Rounding = 0,
    })

    local Capsules = Tab:AddSection("Capsules")

    Capsules:AddToggle("AutoCapsule", {
        Title = "Auto open capsules",
        Description = "Opens up to 100 at a time. Units need room in storage.",
        Default = false,
    })

    local CapsuleItems = {}
    for Id, Info in pairs(Collection.Modules.CapsuleData and Collection.Modules.CapsuleData.Capsules or {}) do
        table.insert(CapsuleItems, { ID = Id, DisplayName = type(Info) == "table" and Info.Name or nil })
    end
    table.sort(CapsuleItems, function(A, B) return A.ID < B.ID end)
    local CapsuleLabels, CapsuleToId = Collection:ItemLabels(CapsuleItems)
    Shop.LabelToId.Capsule = CapsuleToId

    Capsules:AddDropdown("CapsulePick", {
        Title = "Capsules to open",
        Values = CapsuleLabels,
        Multi = true,
        Default = {},
    })
end

--------------------------- [[ Settings Tab ]] ---------------------------

-- Saves once more, leaves any party room, stops every loop and closes the UI.
function Collection:Unload()
    pcall(Profile.Save, Profile, true)
    Party:Leave()
    GlobalEnv.vaderhug_run = nil
    for _, Connection in GlobalEnv.vaderhug_conns do
        pcall(function() Connection:Disconnect() end)
    end
    Library:Destroy()
end

do
    local Tab = Collection.Tabs.Settings

    local Theme = Tab:AddSection("Theme Settings")

    Theme:AddDropdown("Theme", {
        Title = "Theme",
        Values = Library.Themes,
        Default = "Dark",
        Callback = function(Value)
            Library:SetTheme(Value)
        end,
    })

    Library.MinimizeKeybind = Theme:AddKeybind("MinimizeKey", {
        Title = "Show / Hide Key",
        Default = "RightControl",
        Mode = "Toggle",
    })

    Theme:AddButton({
        Title = "Unload UI",
        Description = "Leaves any party room and stops every loop",
        Callback = function()
            Collection:Unload()
        end,
    })

    local AFK = Tab:AddSection("Anti-AFK")

    AFK:AddToggle("AntiAFK", {
        Title = "Anti-AFK",
        Description = "Prevent idle disconnections while the UI is open.",
        Default = true,
    })

    Collection:Track(LocalPlayer.Idled:Connect(function()
        if not (Collection:IsAlive() and Collection.Options.AntiAFK.Value) then return end
        pcall(function()
            local VirtualUser = game:GetService("VirtualUser")
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end))

    local Community = Tab:AddSection("Community & Support")

    Community:AddParagraph({
        Title = "Vader Script Official Discord",
        Content = "Vader updates, support and community.\nDiscord: https://discord.gg/sghjJ7WyWJ",
    })

    Community:AddButton({
        Title = "Copy Discord Invite",
        Description = "Copy the Discord invite to your clipboard.",
        Callback = function()
            local Copy = setclipboard or toclipboard or (Clipboard and Clipboard.set)
            if type(Copy) == "function" then
                local ok = pcall(Copy, "https://discord.gg/sghjJ7WyWJ")
                Library:Notify({
                    Title = "Vader Script",
                    Content = ok and "Discord invite copied to the clipboard." or "Could not copy the invite. Discord: discord.gg/sghjJ7WyWJ",
                    Duration = 3,
                })
            else
                Library:Notify({ Title = "Vader Script", Content = "Discord: discord.gg/sghjJ7WyWJ", Duration = 4 })
            end
        end,
    })
end

--------------------------- [[ Events ]] ---------------------------

if Collection.InLobby then
    local Remotes = Collection.Remotes

    Collection:Track(Remotes.UpdatePartyEvent.OnClientEvent:Connect(function(List)
        if type(List) ~= "table" then return end
        Party.RoomPlayers = List
        if Party:Role() == "Member" and not Party:RoomNames()[LocalPlayer.Name] then
            Party.InParty = false -- kicked
        end
    end))

    -- the server closed our room or kicked us
    Collection:Track(Remotes.LeaveLobbyEvent.OnClientEvent:Connect(function()
        Party.InRoom = false
        Party.InParty = false
        Party.RoomPlayers = {}
    end))

    -- the game still shows its popup; we join straight away when it's from our host
    Collection:Track(Remotes.LobbyInvite.OnClientEvent:Connect(function(From, RoomId)
        if Party:Role() ~= "Member" or Party.InParty then return end
        if typeof(From) ~= "Instance" or From.Name ~= Collection.Options.PartyHost.Value then return end
        task.spawn(function()
            local ok, Joined, List = pcall(function()
                return Remotes.RequestJoinLobby:InvokeServer("Join", RoomId)
            end)
            if ok and Joined then
                Party.InParty = true
                Party.RoomPlayers = type(List) == "table" and List or {}
                Party.LastVerify = os.clock()
            end
        end)
    end))

    Collection:Track(Players.PlayerAdded:Connect(function()
        Collection:RaiseIdentity()
        pcall(function() Party:RefreshLists() end)
    end))
    Collection:Track(Players.PlayerRemoving:Connect(function()
        task.defer(function()
            Collection:RaiseIdentity()
            pcall(function() Party:RefreshLists() end)
        end)
    end))
end

--------------------------- [[ Config ]] ---------------------------

-- Every option, per account, in Vaderhug/AnimeMys/<username>.json, in the Vader map-starter format:
-- { Version = 1, Options = { [Id] = { Type, Value, Mode } } }.
Profile.Ready = false      -- false after a failed load (or no file APIs): saving pauses to protect the file
Profile.Restoring = false
Profile.LastSaved = nil
Profile.LastError = nil
Profile.Extra = {}         -- saved options this place didn't build, carried along on every save
Profile.FirstIds = { "PlayMode", "PlayMap", "PlayStage" } -- the map/stage lists depend on these
Profile.CanPersist = type(isfile) == "function" and type(readfile) == "function"
    and type(writefile) == "function" and type(makefolder) == "function"
    and type(isfolder) == "function"

function Profile:Notify(Text)
    pcall(function() Library:Notify({ Title = "vaderhug", Content = Text, Duration = 6 }) end)
end

local function Equal(A, B)
    if type(A) ~= type(B) then return false end
    if type(A) ~= "table" then return A == B end
    for Key, Value in pairs(A) do
        if not Equal(Value, B[Key]) then return false end
    end
    for Key in pairs(B) do
        if A[Key] == nil then return false end
    end
    return true
end

function Profile:Snapshot()
    local Data = { Version = 1, Options = {} }
    for Id, Saved in pairs(self.Extra) do
        Data.Options[Id] = Saved
    end
    for Id, Option in pairs(Library.Options) do
        if Option.SetValue and Option.Type ~= "Button" and Option.Type ~= "Paragraph" then
            local Value = Option.Value
            if Option.Type == "Dropdown" and Option.Multi then
                local Picked = {} -- only what's ticked, as { Name = true }
                for Key, On in pairs(Value or {}) do
                    if On then Picked[tostring(Key)] = true end
                end
                Value = Picked
            end
            Data.Options[Id] = { Type = Option.Type, Value = Value, Mode = Option.Mode }
        end
    end
    -- JSON round-trip detaches tables from live dropdown values.
    return HttpService:JSONDecode(HttpService:JSONEncode(Data))
end

function Profile:Save(Force)
    if self.Restoring or not self.Ready then
        return false, "Config storage is unavailable or paused."
    end
    local ok, Problem = pcall(function()
        local Data = self:Snapshot()
        if not Force and self.LastSaved and Equal(Data, self.LastSaved) then return end
        writefile(Collection.ConfigFile, HttpService:JSONEncode(Data))
        self.LastSaved = Data
    end)
    if not ok then
        if tostring(Problem) ~= self.LastError then
            self:Notify("Config save failed: " .. tostring(Problem))
        end
        self.LastError = tostring(Problem)
        return false, tostring(Problem)
    end
    self.LastError = nil
    return true
end

-- Earlier versions of this hub saved a flat { Id = Value } file; read it as Version 1.
function Profile:Migrate(Data)
    if type(Data) ~= "table" or Data.Version ~= nil or Data.Options ~= nil then return Data end
    local Options = {}
    for Id, Value in pairs(Data) do
        local Option = Library.Options[Id]
        if Option then
            Options[Id] = { Type = Option.Type, Value = Value }
        end
    end
    return { Version = 1, Options = Options }
end

local function ValidKey(Name)
    if Name == "None" then return true end
    local ok, Key = pcall(function() return Enum.KeyCode[Name] end)
    return ok and Key ~= nil
end

function Profile:Load()
    if not self.CanPersist then return false, "Required file APIs are unavailable." end
    self.Restoring = true
    local ok, Problem = pcall(function()
        Collection:EnsureFolders()
        if not isfile(Collection.ConfigFile) then return end
        local Data = self:Migrate(HttpService:JSONDecode(readfile(Collection.ConfigFile)))
        assert(type(Data) == "table" and Data.Version == 1 and type(Data.Options) == "table", "Invalid config format")

        -- Validate every known value before applying any callbacks.
        local Pending = {}
        for Id, Saved in pairs(Data.Options) do
            local Option = Library.Options[Id]
            if not Option then
                self.Extra[Id] = Saved
            else
                assert(type(Saved) == "table" and Saved.Type == Option.Type, "Invalid control: " .. Id)
                local Value = Saved.Value
                if Option.Type == "Toggle" then
                    assert(type(Value) == "boolean", "Invalid toggle: " .. Id)
                elseif Option.Type == "Slider" then
                    assert(type(Value) == "number" and Value == Value and math.abs(Value) ~= math.huge, "Invalid slider: " .. Id)
                    Value = math.clamp(Value, Option.Min, Option.Max)
                elseif Option.Type == "Input" then
                    assert(type(Value) == "string", "Invalid input: " .. Id)
                elseif Option.Type == "Keybind" then
                    assert(type(Value) == "string" and ValidKey(Value), "Invalid keybind: " .. Id)
                    assert(Saved.Mode == nil or Saved.Mode == "Toggle" or Saved.Mode == "Hold" or Saved.Mode == "Always", "Invalid keybind mode")
                elseif Option.Type == "Dropdown" then
                    if Option.Multi then
                        assert(type(Value) == "table", "Invalid dropdown: " .. Id)
                    else
                        -- names that aren't listed yet (a party host who hasn't joined, a macro) are added back
                        assert(Value == nil or type(Value) == "string", "Invalid dropdown: " .. Id)
                    end
                else
                    error("Unsupported config control: " .. Id)
                end
                table.insert(Pending, { Id = Id, Option = Option, Value = Value, Mode = Saved.Mode })
            end
        end

        -- Map/stage first, then the rest; enabling toggles last so callbacks see restored parameters.
        local function Rank(Item)
            return table.find(self.FirstIds, Item.Id) or (Item.Option.Type == "Toggle" and 1000 or 100)
        end
        table.sort(Pending, function(A, B) return Rank(A) < Rank(B) end)
        for _, Item in ipairs(Pending) do
            Collection:RaiseIdentity()
            if Item.Option.Type == "Dropdown" then
                Collection:SetDropdown(Item.Option, Item.Value)
            elseif Item.Option.Type == "Keybind" then
                Item.Option:SetValue(Item.Value, Item.Mode)
            else
                Item.Option:SetValue(Item.Value)
            end
        end
    end)
    self.Restoring = false
    self.Ready = ok
    if ok then self.LastSaved = nil end
    return ok, Problem
end

Party.Applying = true -- loading saved values isn't a new pick to share
if Profile.CanPersist then
    local ok, Problem = Profile:Load()
    if ok then
        Profile:Save()
    else
        Profile:Notify("Config load failed; auto-save paused to preserve the file: " .. tostring(Problem))
    end
else
    Profile:Notify("Auto-save unavailable: this environment does not provide file APIs.")
end
Party.Applying = false
Party.Ready = true
Macro.Ready = true
Collection:QueueSelf()

Collection:Track(Players.PlayerRemoving:Connect(function(Player)
    if Player == LocalPlayer then Profile:Save() end
end))

coroutine.wrap(function()
    while Collection:IsAlive() do
        task.wait(2)
        if Collection:IsAlive() then Profile:Save() end
    end
end)()

--------------------------- [[ Main Loop ]] ---------------------------

if Collection.InLobby then
coroutine.wrap(function()
    while Collection:IsAlive() do
        local ok, err = pcall(function()
            Party:Tick()
            if Collection:Due("ChallengeView", 2) then
                Challenge:Refresh()
            end

            local Selection, Why = Play:Resolve()
            local Text
            if Selection then
                local Allowed, Reason = Play:Check(Selection)
                Text = Play:Describe(Selection) .. (Allowed and "" or ("\nlocked: " .. tostring(Reason)))
            else
                Text = tostring(Why)
            end
            local Due = Challenge:Next()
            if Due then
                Text = "First: " .. Play:Describe(Due) .. "\nThen: " .. Text
            end
            if Text ~= Collection.PlayInfoText then
                Collection.PlayInfoText = Text
                Collection:RaiseIdentity()
                Collection.UI.PlayInfo:SetDesc(Text)
            end
        end)
        if not ok then
            Party:SetStatus("Error: " .. tostring(err))
            task.wait(4)
        end
        task.wait(1)
    end
end)()

Collection:Loop("Summon", function() return Summon:Step() end)
Collection:Loop("Claim", function() return Claim:Step() end)
Collection:Loop("Shop", function() return Shop:Step() end)
Collection:Loop("Upgrade", function() return Shop:UpgradeStep() end)
Collection:Loop("Units", function() return Units:Step() end)

-- remember the lobby-only lists for the lobby tabs inside a match
do
    local Lists = { Maps = {}, Shops = {}, Merchant = Collection.Options.MerchantSell.Values }
    for _, Mode in ipairs(Play.Modes) do
        if Mode ~= "Challenge" then
            Lists.Maps[Mode] = Play:MapList(Mode)
        end
    end
    for _, Info in ipairs(Shop.Shops) do
        local Option = Collection.Options["Shop" .. Info.Key]
        if Option then Lists.Shops[Info.Key] = Option.Values end
    end
    Collection:WriteJson(Collection.ListsFile, Lists)
end
else
    Macro:InstallHook()
    Match:Init()
    Collection:Loop("Match", function() return Match:Step() end)

    local Note = "Lobby only - set it up here, it runs when you're back in the lobby"
    for _, Key in ipairs({ "Status", "JoinStatus", "PlayInfo", "SummonStatus", "UnitStatus", "ClaimStatus", "ShopStatus", "UpgradeStatus" }) do
        Collection:SetPara(Key, Note)
    end
    pcall(function()
        Units:Refresh()
        Collection:SetPara("UnitInfo", Units:Describe(Units:Selected()))
    end)
end

Collection:SetPara("MacroInfo", Macro:Describe(Collection.Options.MacroPick.Value))
pcall(Match.ShowSpawnOrder, Match)

-- handle for debugging from another script
GlobalEnv.vaderhug_animemys = {
    Collection = Collection, Party = Party, Play = Play, Match = Match, Macro = Macro, Challenge = Challenge,
    Summon = Summon, Claim = Claim, Shop = Shop, Units = Units, Library = Library, Window = Window,
}

Window:SelectTab(1)

Library:Notify({
    Title = "vaderhug",
    Content = "Anime Mysterious loaded" .. (Collection.InLobby and "" or " (match)"),
    SubContent = Collection.InLobby and "Play tab: Auto join | In-Game: macros" or "In-Game: Match and Macro",
    Duration = 5,
})
