---------------------------------------------- [ Configs ] ----------------------------------------------

local Debug = true
repeat task.wait() until game:IsLoaded()
local GlobalEnv = getgenv()

---------------------------------------------- [ Prepare Project ] ----------------------------------------------

local Collection = {}; Collection.__index = Collection
local Dungeon = {}; Dungeon.__index = Dungeon
local Lobby = {}; Lobby.__index = Lobby

local Services = setmetatable({}, {
    __index = function(_, k)
        return game:GetService(k)
    end
})

local Debug_Log = function(...)
    if Debug then print(...) end
end

---------------------------------------------- [ Exploits Variables ] ----------------------------------------------

_http_request = (typeof(request) == "function" and request)
    or (typeof(http_request) == "function" and http_request)
    or (typeof(syn) == "table" and syn.request)
_getconnections = (typeof(getconnections) == "function" and getconnections)
    or (typeof(get_signal_cons) == "function" and get_signal_cons)
_fireproximityprompt = (typeof(fireproximityprompt) == "function" and fireproximityprompt)
    or (typeof(fireprox) == "function" and fireprox)
    or (typeof(syn) == "table" and syn.fireproximityprompt)
_setthreadidentity = (typeof(setthreadidentity) == "function" and setthreadidentity)
    or (typeof(setidentity) == "function" and setidentity)
    or (typeof(syn) == "table" and syn.set_thread_identity)
    or (typeof(set_thread_identity) == "function" and set_thread_identity)

--------------------------- [[ Services ]] ---------------------------

local Players = Services.Players
local ReplicatedStorage = Services.ReplicatedStorage
local RunService = Services.RunService
local Workspace = Services.Workspace
local LocalPlayer = Players.LocalPlayer

--------------------------- [[ Forward Declarations ]] ---------------------------

local RandomID
local FluentLoaded, Fluent
local Inputs, KnitServices
local Window, Tabs

--------------------------- [[ Game Modules ]] ---------------------------

-- This file also sits in the executor's autoexec folder, so it runs in every game that is
-- joined. Anything that is not this game is left alone before a single thing is loaded.
function Collection:WaitForPath(Timeout, ...)
    local Node = ReplicatedStorage
    for _, Name in { ... } do
        Node = Node and Node:WaitForChild(Name, Timeout)
    end
    return Node
end

Inputs = Collection:WaitForPath(15, "Player", "Remotes", "Inputs")
KnitServices = Inputs and Collection:WaitForPath(15, "Packages", "_Index", "sleitnick_knit@1.7.0", "knit", "Services")

if Inputs == nil or KnitServices == nil then
    Debug_Log("[Dungeon Lootr] not this game - nothing loaded")
    return
end

Collection.Attack = Inputs:WaitForChild("Attack", 15)
Collection.Skill = Inputs:WaitForChild("Skill", 15)

Dungeon.RunService = KnitServices:WaitForChild("DungeonRunService", 15)
Dungeon.BuffService = KnitServices:WaitForChild("DungeonBuffService", 15)

if Collection.Attack == nil or Collection.Skill == nil or Dungeon.RunService == nil or Dungeon.BuffService == nil then
    warn("[Dungeon Lootr] the game's remotes are missing - nothing loaded")
    return
end

Dungeon.RunEvents = Dungeon.RunService:WaitForChild("RE", 15)
Dungeon.RunFunctions = Dungeon.RunService:WaitForChild("RF", 15)
Dungeon.BuffEvents = Dungeon.BuffService:WaitForChild("RE", 15)
Dungeon.BuffFunctions = Dungeon.BuffService:WaitForChild("RF", 15)

function Collection:TryRequire(...)
    local Node = ReplicatedStorage
    for _, Name in { ... } do
        Node = Node and Node:FindFirstChild(Name)
    end
    if Node == nil then
        return nil
    end
    local ok, Module = pcall(require, Node)
    return ok and Module or nil
end

-- Common = 1 ... Celestial = 7
Collection.RarityData = Collection:TryRequire("GameInfo", "RarityData")
Collection.RarityIndex = Collection.RarityData and Collection.RarityData.RarityIndex or {}

-- the game's own Knit controllers (reward screen, blessing cards); nil until Knit has started
function Collection:GetController(Name)
    local Knit = Collection:TryRequire("Packages", "Knit")
    if Knit == nil then
        return nil
    end
    local ok, Controller = pcall(Knit.GetController, Name)
    return ok and Controller or nil
end

-- The lobby and the dungeon places share these services, so the lobby half is loaded
-- everywhere; a remote that is missing only makes its own call fail.
Lobby.QueueService = KnitServices:WaitForChild("DungeonQueueService", 5)
Lobby.QueueFunctions = Lobby.QueueService and Lobby.QueueService:WaitForChild("RF", 5)

Lobby.DungeonData = Collection:TryRequire("GameInfo", "DungeonData")

Lobby.SummonService = KnitServices:WaitForChild("SummoningService", 5)
Lobby.SummonFunctions = Lobby.SummonService and Lobby.SummonService:WaitForChild("RF", 5)
Lobby.SummoningData = Collection:TryRequire("GameInfo", "SummoningData")
Lobby.ClassData = Collection:TryRequire("Classes", "Class_Data")
Lobby.RarityIndex = Collection.RarityIndex

-- InvokeServer on <Service>.RF.<Name>; returns pcall's ok followed by what the server returned
function Lobby:Call(Service, Name, ...)
    local Folder = KnitServices:FindFirstChild(Service)
    local Functions = Folder and Folder:FindFirstChild("RF")
    local Remote = Functions and Functions:FindFirstChild(Name)
    if Remote == nil then
        return false, ("no remote %s.%s"):format(Service, Name)
    end
    return pcall(Remote.InvokeServer, Remote, ...)
end

-- the player's saved data as the game's own client holds it (quests, battlepass, gear, points)
function Lobby:GetPlayerData()
    local Knit = Collection:TryRequire("Packages", "Knit")
    local ok, Data = pcall(function()
        return Knit.Registry:Get("PlayerData").Data
    end)
    return ok and type(Data) == "table" and Data or nil
end

--------------------------- [[ Session ]] ---------------------------

if type(GlobalEnv.dungeonlootr_conns) == "table" then
    pcall(function()
        for _, Connection in GlobalEnv.dungeonlootr_conns do
            pcall(function() Connection:Disconnect() end)
        end
    end)
end
GlobalEnv.dungeonlootr_conns = {}

-- running the script again takes the previous window down with it
if GlobalEnv.dungeonlootr_fluent ~= nil then
    pcall(function() GlobalEnv.dungeonlootr_fluent:Destroy() end)
    GlobalEnv.dungeonlootr_fluent = nil
end

RandomID = {}
GlobalEnv.dungeonlootr_run = RandomID

--------------------------- [[ Anti Idle ]] ---------------------------

Collection.AntiIdle = { On = true }

do
    if _G.__dungeonlootrAntiIdle ~= nil then
        pcall(function() _G.__dungeonlootrAntiIdle:Disconnect() end)
        _G.__dungeonlootrAntiIdle = nil
    end

    local ok, VirtualUser = pcall(game.GetService, game, "VirtualUser")
    if ok and VirtualUser ~= nil then
        _G.__dungeonlootrAntiIdle = LocalPlayer.Idled:Connect(function()
            if not Collection.AntiIdle.On then
                return
            end
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end)
    end
end

function Collection:Track(Connection)
    table.insert(GlobalEnv.dungeonlootr_conns, Connection)
    return Connection
end

function Collection:RaiseIdentity()
    if _setthreadidentity then
        pcall(_setthreadidentity, 8)
    end
end

Collection:RaiseIdentity()

--------------------------- [[ Fluent ]] ---------------------------

-- VaderUI in place of Fluent (same API)
FluentLoaded, Fluent = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/DONUT6599/ddgdhdf/refs/heads/main/VaderUI.lua"))()
end)

if not FluentLoaded or Fluent == nil then
    warn("[Dungeon Lootr] couldn't load Fluent: " .. tostring(Fluent))
    return
end

GlobalEnv.dungeonlootr_fluent = Fluent

function Collection:IsAlive()
    return GlobalEnv.dungeonlootr_run == RandomID and not Fluent.Unloaded
end

-- Calling into the game's modules leaves a thread at game identity, where Fluent cannot
-- create the notification; raise it first.
function Collection:Notify(Options)
    Collection:RaiseIdentity()
    local Library = Fluent
    pcall(Library.Notify, Library, Options)
end

--------------------------- [[ State ]] ---------------------------

-- Auto Farm always teleports to its target (which leaves it facing the target's back) and
-- always moves on to the next room; those are not separate settings.
Collection.FarmState = {
    On = false,
    Interval = 0.2, -- seconds between attacks
    Stance = "Behind", -- "Behind" | "Above" | "Under": where to stand relative to the target
    Distance = 4, -- studs from the target in that direction
    Target = nil, -- the enemy root being fought; the positioning loop pins us to it
    LastTargetPosition = nil, -- where the last target stood, to climb back out from "Under"
}

Collection.SkillState = {
    Auto = true,
    Slots = { ["1"] = true, ["2"] = true, ["3"] = true, ["4"] = true },
    Retry = 1, -- minimum seconds between fires of the same slot
    Last = {},
}

Dungeon.State = {
    Loot = true,
    Blessing = true,
    Replay = true,
    Return = false,
    Refill = true,
    Pick = true,
    -- the boss has no RoomIndex, so its phase is remembered and the last room is headed for
    BossPhase = false,
    -- true while the farm loop still has an unlocked chest to open
    LootPending = false,
    -- the boss is dead: nothing is left to fight, so the chests can be collected
    Cleared = false,
}

Dungeon.Tuning = {
    RefillCooldown = 10, -- seconds before the same potion station is triggered again
    RoomOffset = Vector3.new(0, 3, 0), -- stand this far above a room's spawn marker
    ReplayDelay = 3, -- seconds after the completion screen before asking for a replay
    ReplayLootWait = 120, -- longest the replay waits for leftover chests to be opened
    PromptOffset = Vector3.new(0, 4, 0), -- stand this far above a chest or altar prompt
    PromptRetry = 1, -- seconds between fires of the altar prompt
    PromptMaxTries = 4, -- give up on the altar prompt if it keeps not working
    ChestStep = 1.5, -- studs closer to a chest on each try
    ChestRetry = 0.4, -- seconds between tries on the same chest
    ChestMaxTries = 10, -- a chest that has not opened after this many tries is skipped
    AltarRange = 200, -- only detour to the Blessing Altar when it is this close
}

Collection.WebhookState = {
    On = false,
    ClassOn = false, -- post the result of a class spin session too
    Url = "",
    RoomsCleared = 0, -- counted from RoomCleared events; the completion data does not carry it
    Asset = "https://raw.githubusercontent.com/DONUT6599/ddgdhdf/refs/heads/main/Asset_1.png",
    Image = "https://tr.rbxcdn.com/180DAY-b66e174062594ed5da7a955daebde110/768/432/Image/Webp/noFilter",
}

Dungeon.PromptTries = setmetatable({}, { __mode = "k" })
Dungeon.LastPrompt = setmetatable({}, { __mode = "k" })
Dungeon.ChestApproach = setmetatable({}, { __mode = "k" })

Lobby.State = {
    Auto = false,
    Dungeon = "Bandits Den",
    Difficulty = "Easy",
    Delay = 5, -- seconds in the lobby before an automatic start, so there is time to switch it off
    RetryWait = 15, -- seconds before trying again after the server refuses a start
    Busy = false,
    Started = false, -- the server accepted a start; the teleport is on its way
    Status = "off",
    ArrivedAt = tick(),
}

Lobby.Difficulties = { "Easy", "Normal", "Hard", "Nightmare", "Endless" }

Lobby.SpinState = {
    Auto = false,
    Type = "Normal", -- "Normal" | "Lucky"
    MinRarity = "Legendary", -- stop once the class in the active slot is at least this rare
    Wanted = {}, -- [ClassName] = true: stop on any of these too, whatever their rarity
    Only = nil, -- [ClassName] = true from _G.Class: stop on these and nothing else
    Gap = 1.5, -- seconds between spins
    Busy = false,
    Spins = 0,
    Last = nil, -- the newest spin's result: { ClassName, Rarity, Aspect, Left }
    Status = "off",
}

Lobby.AccountState = {
    Quests = true,
    Battlepass = true,
    EquipBest = true,
    Allocate = true,
    Busy = false,
    Done = false, -- the arrival pass has finished; Auto start waits for it
    Status = "waiting",
}

-- lowest to highest, as the summoning screen lists them
Lobby.RarityOrder = (Lobby.SummoningData and type(Lobby.SummoningData.RarityOrder) == "table" and Lobby.SummoningData.RarityOrder)
    or { "Rare", "Epic", "Legendary", "Mythic", "Celestial", "Exotic" }

--------------------------- [[ Targets ]] ---------------------------

function Collection:GetRoot()
    local PlayerCharacter = LocalPlayer.Character
    local PlayerHumanoid = PlayerCharacter and PlayerCharacter:FindFirstChildOfClass("Humanoid")
    if PlayerHumanoid == nil or PlayerHumanoid.Health <= 0 then
        return nil
    end
    return PlayerCharacter:FindFirstChild("HumanoidRootPart")
end

-- the dungeon folder is named Generated_<dungeon>_<id> and the id changes every run
function Dungeon:GetFolder()
    for _, Child in Workspace:GetChildren() do
        if string.match(Child.Name, "^Generated_") and Child:FindFirstChild("NPCs") then
            return Child
        end
    end
end

-- Only some enemies have a Humanoid, and none of them show their health to the client, so
-- "still in the NPCs folder and awake" is the alive check. Far-away enemies are not streamed
-- in and have no HumanoidRootPart.
function Collection:GetNearestEnemy(RootPart, Folder)
    local Nearest, NearestDist
    for _, Npc in Folder.NPCs:GetChildren() do
        local NpcRoot = Npc:FindFirstChild("HumanoidRootPart")
        if NpcRoot ~= nil and not Npc:GetAttribute("IsDormant") then
            local Distance = (NpcRoot.Position - RootPart.Position).Magnitude
            if NearestDist == nil or Distance < NearestDist then
                Nearest, NearestDist = NpcRoot, Distance
            end
        end
    end
    return Nearest, NearestDist
end

-- Where to stand for the chosen stance, turned to look at the target.
function Collection:GetSpot(Target)
    local State = Collection.FarmState

    local Spot
    if State.Stance == "Above" then
        Spot = Target.CFrame * CFrame.new(0, State.Distance, 0)
    elseif State.Stance == "Under" then
        Spot = Target.CFrame * CFrame.new(0, -State.Distance, 0)
    else
        Spot = Target.CFrame * CFrame.new(0, 0, State.Distance)
    end

    -- looking straight up or down needs a different up vector, or lookAt has nothing to roll around
    local UpVector = Target.CFrame.UpVector
    local Direction = Target.Position - Spot.Position
    if math.abs(Direction.Unit:Dot(UpVector)) > 0.99 then
        UpVector = Target.CFrame.LookVector
    end
    return CFrame.lookAt(Spot.Position, Spot.Position + Direction, UpVector)
end

-- "Under" leaves the character below the floor with nothing holding it once the target is
-- gone; put it back on top of where the target stood before it falls out of the map.
function Collection:Surface(RootPart)
    local State = Collection.FarmState
    local Last = State.LastTargetPosition
    State.Target, State.LastTargetPosition = nil, nil
    if Last ~= nil and RootPart ~= nil and RootPart.Position.Y < Last.Y - 1 then
        RootPart.CFrame = CFrame.new(Last + Vector3.new(0, 3, 0))
        RootPart.AssemblyLinearVelocity = Vector3.zero
    end
end

--------------------------- [[ Skills ]] ---------------------------

-- One skill per call. The game publishes each slot's cooldown as a Skill<N>_OnCooldown
-- player attribute, which is nil right after a run starts.
function Collection:UseSkill()
    local State = Collection.SkillState
    for Slot = 1, 6 do
        if State.Slots[tostring(Slot)]
            and not LocalPlayer:GetAttribute("Skill" .. Slot .. "_OnCooldown")
            and tick() - (State.Last[Slot] or 0) >= State.Retry then
            State.Last[Slot] = tick()
            Collection.Skill:FireServer(Slot, "tap", Vector3.zero)
            return
        end
    end
end

--------------------------- [[ Rooms ]] ---------------------------

function Dungeon:IsInZone(Zone, Position)
    local Offset = Zone.CFrame:PointToObjectSpace(Position)
    return math.abs(Offset.X) <= Zone.Size.X / 2 and math.abs(Offset.Z) <= Zone.Size.Z / 2
end

function Dungeon:GetRoomAt(Folder, Position)
    for _, Room in Folder:GetChildren() do
        local Zone = string.match(Room.Name, "^Room_%d+$") and Room:FindFirstChild("Zone")
        if Zone and Dungeon:IsInZone(Zone, Position) then
            return Room
        end
    end
end

-- A room's Door stays solid until the server marks the room cleared. Enemy counts are not
-- reliable: reinforcements spawn mid-fight and dead models linger.
function Dungeon:IsRoomInProgress(Room)
    local Door = Room and Room:FindFirstChild("Door")
    return Door ~= nil and Door.CanCollide
end

-- the lowest-numbered room that still has sleeping enemies; they wake when its zone is entered
function Dungeon:GetNextRoom(Folder)
    local NextIndex
    for _, Npc in Folder.NPCs:GetChildren() do
        local Index = Npc:GetAttribute("RoomIndex")
        if Index and Npc:GetAttribute("IsDormant") and (NextIndex == nil or Index < NextIndex) then
            NextIndex = Index
        end
    end

    if NextIndex == nil and Dungeon.State.BossPhase then
        for _, Room in Folder:GetChildren() do
            local Index = tonumber(string.match(Room.Name, "^Room_(%d+)$"))
            if Index and (NextIndex == nil or Index > NextIndex) then
                NextIndex = Index
            end
        end
    end

    return NextIndex and Folder:FindFirstChild("Room_" .. NextIndex)
end

--------------------------- [[ Potions ]] ---------------------------

Dungeon.LastRefill = setmetatable({}, { __mode = "k" })

-- the prompt is handled by the engine (no remote), and the server ignores it outside MaxActivationDistance
function Dungeon:RefillPotions(RootPart, Folder)
    for _, Station in Folder:GetChildren() do
        if Station.Name == "Potion_Station" then
            local Part = Station:FindFirstChild("Part")
            local Prompt = Part and Part:FindFirstChildOfClass("ProximityPrompt")
            if Prompt ~= nil and Prompt.Enabled
                and (Part.Position - RootPart.Position).Magnitude <= Prompt.MaxActivationDistance
                and tick() - (Dungeon.LastRefill[Prompt] or 0) >= Dungeon.Tuning.RefillCooldown then
                Dungeon.LastRefill[Prompt] = tick()
                _fireproximityprompt(Prompt)
            end
        end
    end
end

--------------------------- [[ Chests ]] ---------------------------

-- key-locked side rooms are Locked_N models; their chests also carry a LockedRoom attribute
function Dungeon:IsInLockedArea(Folder, Chest)
    if Chest:GetAttribute("LockedRoom") then
        return true
    end

    local Position = Chest:GetPivot().Position
    for _, Room in Folder:GetChildren() do
        local Zone = string.match(Room.Name, "^Locked_") and Room:FindFirstChild("Zone")
        if Zone and Dungeon:IsInZone(Zone, Position) then
            return true
        end
    end
    return false
end

-- A chest can only be looted once its Chest_Lock is gone (key chests stay locked). Some chests
-- show no lock before their room is cleared and the server still refuses them, so every enemy
-- of the chest's room, asleep or awake, has to be dead first.
function Dungeon:GetChestPrompt(RootPart, Folder)
    local RoomsWithEnemies = {}
    for _, Npc in Folder.NPCs:GetChildren() do
        local Index = Npc:GetAttribute("RoomIndex")
        if Index then
            RoomsWithEnemies[Index] = true
        end
    end

    local Nearest, NearestDist
    for _, Chest in Folder:GetChildren() do
        if string.match(Chest.Name, "^DungeonChest_")
            and Chest:FindFirstChild("Chest_Lock") == nil
            and not Dungeon:IsInLockedArea(Folder, Chest)
            and not RoomsWithEnemies[Chest:GetAttribute("RoomIndex")] then
            local Prompt = Chest:FindFirstChild("ChestPrompt", true)
            if Prompt ~= nil and Prompt.Enabled
                and (Dungeon.PromptTries[Prompt] or 0) < Dungeon.Tuning.ChestMaxTries then
                local Distance = (Prompt.Parent.WorldPosition - RootPart.Position).Magnitude
                if NearestDist == nil or Distance < NearestDist then
                    Nearest, NearestDist = Prompt, Distance
                end
            end
        end
    end
    return Nearest
end

-- Starts at the edge of the prompt's reach and steps closer on every try until the chest is
-- gone (a looted chest is removed from the dungeon, so GetChestPrompt stops returning it).
function Dungeon:LootChest(RootPart, Prompt)
    if tick() - (Dungeon.LastPrompt[Prompt] or 0) < Dungeon.Tuning.ChestRetry then
        return
    end
    Dungeon.LastPrompt[Prompt] = tick()
    Dungeon.PromptTries[Prompt] = (Dungeon.PromptTries[Prompt] or 0) + 1

    local Position = Prompt.Parent.WorldPosition
    local Distance = Dungeon.ChestApproach[Prompt] or Prompt.MaxActivationDistance
    Dungeon.ChestApproach[Prompt] = math.max(Distance - Dungeon.Tuning.ChestStep, 0)

    -- come in from the side we are already on
    local Away = (RootPart.Position - Position) * Vector3.new(1, 0, 1)
    Away = Away.Magnitude > 0.1 and Away.Unit or Vector3.xAxis
    local Spot = Position + Away * Distance + Dungeon.Tuning.PromptOffset
    RootPart.CFrame = CFrame.lookAt(Spot, Vector3.new(Position.X, Spot.Y, Position.Z) - Away * 0.01)
    _fireproximityprompt(Prompt)
end

--------------------------- [[ Blessing Altar ]] ---------------------------

function Dungeon:GetAltarPrompt(RootPart, Folder)
    local Altar = Folder:FindFirstChild("Blessing_Altar")
    local Prompt = Altar and Altar:FindFirstChildWhichIsA("ProximityPrompt", true)
    if Prompt == nil or not Prompt.Enabled
        or (Dungeon.PromptTries[Prompt] or 0) >= Dungeon.Tuning.PromptMaxTries
        or (Prompt.Parent.WorldPosition - RootPart.Position).Magnitude > Dungeon.Tuning.AltarRange then
        return nil
    end

    -- Stepping onto an altar that stands in a room full of sleeping enemies wakes that room
    -- out of turn, on top of the one being fought. Leave it until its room has been cleared.
    local Room = Dungeon:GetRoomAt(Folder, Prompt.Parent.WorldPosition)
    local RoomIndex = Room and tonumber(string.match(Room.Name, "%d+"))
    for _, Npc in Folder.NPCs:GetChildren() do
        if RoomIndex ~= nil and Npc:GetAttribute("RoomIndex") == RoomIndex then
            return nil
        end
    end
    return Prompt
end

-- Teleports onto the prompt first. The server ignores a prompt fired from outside
-- MaxActivationDistance, so the fire happens on a later tick once the position has replicated.
function Dungeon:UsePrompt(RootPart, Prompt)
    local Position = Prompt.Parent.WorldPosition
    if (Position - RootPart.Position).Magnitude > Prompt.MaxActivationDistance - 2 then
        RootPart.CFrame = CFrame.new(Position + Dungeon.Tuning.PromptOffset)
        Dungeon.LastPrompt[Prompt] = tick()
    elseif tick() - (Dungeon.LastPrompt[Prompt] or 0) >= Dungeon.Tuning.PromptRetry then
        Dungeon.LastPrompt[Prompt] = tick()
        Dungeon.PromptTries[Prompt] = (Dungeon.PromptTries[Prompt] or 0) + 1
        _fireproximityprompt(Prompt)
    end
end

-- The altar opens a blessing choice; this is the call the game's cards make when clicked.
-- Blessings carry no Rarity (only Id, Title, Description), so the first one is taken.
function Dungeon:PickBlessing(Options, OfferId)
    if not Dungeon.State.Blessing or type(Options) ~= "table" or #Options == 0 then
        return
    end

    local Best, BestRarity = 1, -1
    for Index, Option in ipairs(Options) do
        local Rarity = type(Option) == "table" and Collection.RarityIndex[Option.Rarity] or 0
        if Rarity > BestRarity then
            Best, BestRarity = Index, Rarity
        end
    end

    task.wait(1)
    local SelectBuff = Dungeon.BuffFunctions.SelectBuff
    local ok, Success, Reason = pcall(SelectBuff.InvokeServer, SelectBuff, Best, OfferId)
    if ok and Success then
        local Controller = Collection:GetController("BoostSelectionController")
        if Controller ~= nil then
            pcall(function() Controller:_Reset() end)
        end
    end

    local Option = Options[Best]
    local Name = type(Option) == "table" and (Option.Title or Option.Name or Option.Id) or Option
    Collection:Notify({
        Title = (ok and Success) and "Blessing picked" or "Blessing pick failed",
        Content = (ok and Success) and tostring(Name or ("option " .. Best)) or tostring(ok and Reason or Success),
        Duration = 6,
    })
end

--------------------------- [[ Reward Chests ]] ---------------------------

function Dungeon:DescribeChest(Chest)
    local Name = Chest.Id or Chest.Type or "?"
    if Chest.Amount and Chest.Amount > 1 then
        Name = Name .. " x" .. Chest.Amount
    end
    return Chest.Rarity and (Chest.Rarity .. " " .. Name) or Name
end

-- The server sends every chest's contents up front; the game only sends the picks when Finish
-- is pressed. Chests are numbered left to right, and entries without a Rarity (spins, stars)
-- rank lowest.
function Dungeon:PickChests(Chests, OwnsExtraLoot, SelectRemote)
    if not Dungeon.State.Pick or type(Chests) ~= "table" or #Chests == 0 then
        return
    end

    local Order = {}
    for Index in ipairs(Chests) do
        Order[Index] = Index
    end
    table.sort(Order, function(A, B)
        local RarityA = Collection.RarityIndex[Chests[A].Rarity] or 0
        local RarityB = Collection.RarityIndex[Chests[B].Rarity] or 0
        if RarityA ~= RarityB then
            return RarityA > RarityB
        end
        return A < B
    end)

    -- picking more than the limit is rejected (the game's own UI opens a purchase prompt instead)
    local MaxPicks = OwnsExtraLoot == true and 3 or 2
    local Picks, Names = {}, {}
    for Index = 1, math.min(MaxPicks, #Order) do
        Picks[Index] = Order[Index]
        Names[Index] = Dungeon:DescribeChest(Chests[Order[Index]])
    end

    task.wait(1)
    local ok, Success, Reason = pcall(SelectRemote.InvokeServer, SelectRemote, Picks)
    if ok and Success then
        -- close the game's reward screen the way its own Finish button does
        local Controller = Collection:GetController("ChestSelectionController")
        if Controller ~= nil then
            pcall(function() Controller:_Reset() end)
        end
        Collection:Notify({ Title = "Chests picked", Content = table.concat(Names, ", "), Duration = 6 })
    else
        Collection:Notify({
            Title = "Chest pick failed",
            Content = tostring(ok and Reason or Success),
            SubContent = "Pick them yourself on the reward screen",
            Duration = 8,
        })
    end
end

--------------------------- [[ Run End ]] ---------------------------

-- What the completion screen's REPLAY and Return to Lobby buttons call. Either one teleports
-- to another server, which wipes this script; the copy in the executor's autoexec folder
-- starts it again there, and Auto Save brings the settings back.
function Dungeon:FinishRun()
    if not Dungeon.State.Replay and not Dungeon.State.Return then
        return
    end
    task.wait(Dungeon.Tuning.ReplayDelay)

    -- the boss is killed before the last room's chests are looted, so let the farm loop finish them
    local Deadline = tick() + Dungeon.Tuning.ReplayLootWait
    while Dungeon.State.LootPending and Collection.FarmState.On and tick() < Deadline do
        task.wait(0.5)
    end
    if not Collection:IsAlive() then
        return
    end

    if Dungeon.State.Replay then
        local ok, Reason = pcall(function()
            return Dungeon.RunFunctions.RequestReplay:InvokeServer()
        end)
        Collection:Notify({
            Title = ok and "Replay requested" or "Replay failed",
            Content = ok and "Starting the dungeon again" or tostring(Reason),
            Duration = 5,
        })
    elseif Dungeon.State.Return then
        local ok, Reason = Dungeon:PressReturn()
        Collection:Notify({
            Title = ok and "Returning to lobby" or "Return to lobby failed",
            Content = ok and "The run is over" or tostring(Reason),
            Duration = 5,
        })
    end
end

-- Presses the completion screen's Return to Lobby button, which runs the game's own handler
-- (fade out, then RequestReturn). That lands in the lobby place, 106484206883664. If the
-- button cannot be reached, the remote behind it is called directly.
function Dungeon:PressReturn()
    local Found, Button = pcall(function()
        return LocalPlayer.PlayerGui.Main.HUD.Dungeon_Container.Completion_Info.Content.ActionButtons.ReturnButton
    end)
    if Found and Button ~= nil and _getconnections ~= nil then
        local ok, Connections = pcall(_getconnections, Button.Activated)
        if ok and type(Connections) == "table" and #Connections > 0 then
            for _, Connection in Connections do
                pcall(function() Connection:Fire() end)
            end
            return true
        end
    end

    return pcall(function()
        return Dungeon.RunFunctions.RequestReturn:InvokeServer()
    end)
end

--------------------------- [[ Webhook ]] ---------------------------

function Collection:FormatNumber(Value)
    local Text = tostring(math.floor((tonumber(Value) or 0) + 0.5))
    local Count
    repeat
        Text, Count = string.gsub(Text, "^(-?%d+)(%d%d%d)", "%1,%2")
    until Count == 0
    return Text
end

function Collection:FormatTime(Seconds)
    Seconds = math.floor((tonumber(Seconds) or 0) + 0.5)
    return ("%d:%02d"):format(Seconds // 60, Seconds % 60)
end

-- Data is what the server sends with DungeonComplete (DungeonName, Difficulty, Status,
-- MobsKilled, TimeElapsed, TotalDamage, TotalEXP, IsVictory, ...).
function Collection:SendWebhook(Data)
    local State = Collection.WebhookState
    if _http_request == nil then
        return false, "this executor has no request function"
    end
    if string.match(State.Url, "^https://[%w%.%-]*discord[%w%.%-]*/api/webhooks/") == nil then
        return false, "that is not a Discord webhook URL"
    end
    Data = type(Data) == "table" and Data or {}

    local Map = tostring(Data.DungeonName or LocalPlayer:GetAttribute("CurrentDungeon") or "?")
    if Data.Difficulty ~= nil then
        Map = Map .. " (" .. tostring(Data.Difficulty) .. ")"
    end
    local Title = tostring(Data.Status or (Data.IsVictory == false and "Failed" or "Extracted")) .. " !"

    local Body = Services.HttpService:JSONEncode({
        embeds = {
            {
                title = Title,
                description = table.concat({
                    "Map : " .. Map,
                    "Mobs killed : " .. Collection:FormatNumber(Data.MobsKilled),
                    "Rooms Cleared : " .. tostring(Data.RoomsCleared or State.RoomsCleared),
                    "Total Time : " .. Collection:FormatTime(Data.TimeElapsed),
                    "Total Damage : " .. Collection:FormatNumber(Data.TotalDamage),
                    "Total EXP : " .. Collection:FormatNumber(Data.TotalEXP),
                }, "\n"),
                author = { name = "Dungeon Lootr" },
                footer = { text = "VaderHug", icon_url = State.Asset },
                timestamp = DateTime.now():ToIsoDate(),
                image = { url = State.Image },
                thumbnail = { url = State.Asset },
            },
        },
        username = "VaderHug",
        avatar_url = State.Asset,
        attachments = {},
    })

    local ok, Response = pcall(_http_request, {
        Url = State.Url,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = Body,
    })
    if not ok then
        return false, tostring(Response)
    end

    local Code = type(Response) == "table" and tonumber(Response.StatusCode) or nil
    if Code ~= nil and (Code < 200 or Code >= 300) then
        return false, "Discord answered " .. Code
    end
    return true
end

--------------------------- [[ Between Fights ]] ---------------------------

-- Runs whenever no enemy is awake: the altar, then the next room, and the chests once the
-- whole dungeon is dead.
function Dungeon:BetweenFights(RootPart, Folder)
    local Current = Dungeon:GetRoomAt(Folder, RootPart.Position)
    if Dungeon:IsRoomInProgress(Current) then
        return
    end

    -- Chests are left for the very end. Going for one mid-run teleports across rooms that are
    -- still asleep, so nothing is looted until the boss is dead or no enemy is left at all.
    local LootNow = Dungeon.State.Loot and (Dungeon.State.Cleared or #Folder.NPCs:GetChildren() == 0)
    local ChestPrompt = LootNow and Dungeon:GetChestPrompt(RootPart, Folder) or nil
    Dungeon.State.LootPending = ChestPrompt ~= nil
    if ChestPrompt ~= nil then
        Dungeon:LootChest(RootPart, ChestPrompt)
        return
    end

    local AltarPrompt = Dungeon.State.Blessing and Dungeon:GetAltarPrompt(RootPart, Folder) or nil
    if AltarPrompt ~= nil then
        Dungeon:UsePrompt(RootPart, AltarPrompt)
        return
    end

    local NextRoom = Dungeon:GetNextRoom(Folder)
    if NextRoom == nil or NextRoom == Current then
        return
    end

    local Spawns = NextRoom:FindFirstChild("Spawns")
    local Marker = (Spawns and Spawns:FindFirstChildWhichIsA("BasePart")) or NextRoom:FindFirstChild("Zone")
    if Marker ~= nil then
        RootPart.CFrame = CFrame.new(Marker.Position + Dungeon.Tuning.RoomOffset)
    end
end

--------------------------- [[ Positioning ]] ---------------------------

-- While the farm loop has a target, the character is pinned behind it every frame.
coroutine.wrap(function()
    while RunService.Heartbeat:Wait() do
        if Collection.BreakLoop or not Collection:IsAlive() then break end
        local ok, err = pcall(function()
            local State = Collection.FarmState
            local Target = State.Target
            if not State.On or Target == nil or Target.Parent == nil then
                return
            end

            local RootPart = Collection:GetRoot()
            if RootPart == nil then
                return
            end

            RootPart.CFrame = Collection:GetSpot(Target)
            RootPart.AssemblyLinearVelocity = Vector3.zero
            RootPart.AssemblyAngularVelocity = Vector3.zero
        end)
        if err and Debug then warn("[Positioning] Caught Error:", err) end
    end
end)()

--------------------------- [[ Farm ]] ---------------------------

function Collection:FarmStep()
    local State = Collection.FarmState
    local RootPart = Collection:GetRoot()
    local Folder = RootPart and Dungeon:GetFolder()
    if Folder == nil then
        Collection:Surface(RootPart)
        return
    end

    if Dungeon.State.Refill then
        Dungeon:RefillPotions(RootPart, Folder)
    end

    if not State.On then
        Collection:Surface(RootPart)
        return
    end

    -- every awake enemy dies before any chest is touched
    local Target = Collection:GetNearestEnemy(RootPart, Folder)
    if Target == nil then
        Collection:Surface(RootPart)
        Dungeon:BetweenFights(RootPart, Folder)
        return
    end

    State.Target, State.LastTargetPosition = Target, Target.Position
    RootPart.CFrame = Collection:GetSpot(Target)
    if Collection.SkillState.Auto then
        Collection:UseSkill()
    end
    Collection.Attack:FireServer(Vector3.zero)
end

coroutine.wrap(function()
    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(Collection.FarmStep, Collection)
        if err then
            if Debug then warn("[Farm] Caught Error:", err) end
            task.wait(1)
        end
        task.wait(Collection.FarmState.Interval)
    end

    Collection.FarmState.Target = nil
    -- unloaded (not replaced by a newer run, which owns the list now): stop listening to the game
    if GlobalEnv.dungeonlootr_run == RandomID then
        for _, Connection in GlobalEnv.dungeonlootr_conns do
            pcall(function() Connection:Disconnect() end)
        end
    end
end)()

--------------------------- [[ Dungeons ]] ---------------------------

-- the dungeon ids the lobby's own picker shows, in its order
function Lobby:GetDungeonNames()
    local Names = {}
    local Data = Lobby.DungeonData
    if Data ~= nil and type(Data.DisplayOrder) == "table" then
        for _, Name in ipairs(Data.DisplayOrder) do
            table.insert(Names, tostring(Name))
        end
    end
    if #Names == 0 and Data ~= nil and type(Data.Dungeons) == "table" then
        for Name in pairs(Data.Dungeons) do
            table.insert(Names, tostring(Name))
        end
        table.sort(Names)
    end
    if #Names == 0 then
        Names = { "Bandits Den" }
    end
    return Names
end

function Lobby:Invoke(Name, ...)
    local Remote = Lobby.QueueFunctions and Lobby.QueueFunctions:FindFirstChild(Name)
    if Remote == nil then
        return false, "no remote " .. Name
    end
    return pcall(Remote.InvokeServer, Remote, ...)
end

-- nil when the dungeon and difficulty can be entered, otherwise the server's reason
function Lobby:GetLockReason(DungeonId, Difficulty)
    local ok, Access = Lobby:Invoke("GetDungeonAccessState", DungeonId)
    if ok and type(Access) == "table" and Access.Unlocked == false then
        return tostring(Access.Reason or (DungeonId .. " is locked"))
    end

    local okDiff, Unlocked = Lobby:Invoke("GetUnlockedDifficulties", DungeonId)
    local Entry = okDiff and type(Unlocked) == "table" and Unlocked[Difficulty] or nil
    if type(Entry) == "table" and Entry.Unlocked == false then
        return tostring(Entry.Reason or (Difficulty .. " is locked"))
    end
    return nil
end

--------------------------- [[ Start Run ]] ---------------------------

-- The same calls, in the same order, as the lobby's ENTER button for a solo run:
-- mode -> dungeon -> difficulty -> modifiers -> RequestStartSoloRun.
function Lobby:StartRun()
    local State = Lobby.State
    if State.Busy or State.Started then
        return false, "already starting"
    end
    State.Busy = true

    local function Finish(ok, Detail)
        State.Busy, State.Status = false, Detail
        return ok, Detail
    end

    local DungeonId, Difficulty = State.Dungeon, State.Difficulty
    State.Status = ("checking %s (%s)"):format(DungeonId, Difficulty)

    local Locked = Lobby:GetLockReason(DungeonId, Difficulty)
    if Locked ~= nil then
        return Finish(false, ("%s (%s) cannot be entered: %s"):format(DungeonId, Difficulty, Locked))
    end

    State.Status = ("selecting %s (%s)"):format(DungeonId, Difficulty)
    for _, Step in {
        { "RequestSelectMode", "Dungeon" },
        { "RequestSelectDungeon", DungeonId },
        { "RequestSelectDifficulty", Difficulty },
    } do
        -- these three return nothing; the game's own button only checks that the call went through
        local ok, Reason = Lobby:Invoke(Step[1], Step[2])
        if not ok then
            return Finish(false, ("%s(%s) failed: %s"):format(Step[1], Step[2], tostring(Reason)))
        end
    end

    -- the server's party data is the proof that the selection took
    local okParty, Party = Lobby:Invoke("RequestPartyData")
    if okParty and type(Party) == "table"
        and (Party.SelectedDungeon ~= DungeonId or Party.SelectedDifficulty ~= Difficulty) then
        return Finish(false, ("the server kept %s (%s) selected"):format(
            tostring(Party.SelectedDungeon), tostring(Party.SelectedDifficulty)))
    end

    -- no modifiers: Hardcore is never switched on from here
    local okMods, ModsAccepted = Lobby:Invoke("RequestSelectModifiers", {})
    if not (okMods and ModsAccepted == true) then
        return Finish(false, "the server did not confirm the selection: " .. tostring(ModsAccepted))
    end

    State.Status = "starting the run"
    local ok, Success, Reason = Lobby:Invoke("RequestStartSoloRun")
    if not (ok and Success) then
        return Finish(false, "start refused: " .. tostring(ok and Reason or Success))
    end

    State.Started = true
    return Finish(true, ("entering %s (%s)"):format(DungeonId, Difficulty))
end

--------------------------- [[ Quests ]] ---------------------------

-- Claims every daily / weekly / limited quest the game marks Completed and not yet Claimed,
-- once each: the same call as the quest panel's Claim button.
function Lobby:ClaimQuests()
    local Data = Lobby:GetPlayerData()
    local Claimed = 0
    for Category, Group in pairs(Data and type(Data.Quests) == "table" and Data.Quests or {}) do
        for Index, Slot in pairs(type(Group) == "table" and type(Group.Active) == "table" and Group.Active or {}) do
            if type(Slot) == "table" and Slot.Completed and not Slot.Claimed then
                local ok, Result = Lobby:Call("QuestService", "ClaimQuest", Category, Index)
                if ok and Result ~= false then
                    Claimed = Claimed + 1
                end
                task.wait(0.3)
            end
        end
    end
    return Claimed
end

--------------------------- [[ Battlepass ]] ---------------------------

-- Claims completed battlepass quests, then every reached tier's reward that is still unclaimed
-- (the Free track, and the Premium track only when the pass is owned).
function Lobby:ClaimBattlepass()
    local Claimed = 0

    local Data = Lobby:GetPlayerData()
    local Pass = Data and Data.Battlepass
    for Index, Slot in pairs(type(Pass) == "table" and type(Pass.Quests) == "table" and Pass.Quests or {}) do
        if type(Slot) == "table" and Slot.Completed and not Slot.Claimed then
            local ok, Result = Lobby:Call("BattlepassService", "ClaimQuest", Index)
            if ok and Result then
                Claimed = Claimed + 1
            end
            task.wait(0.3)
        end
    end

    -- claiming quests can raise the tier, so read the pass again
    task.wait(0.5)
    Data = Lobby:GetPlayerData()
    Pass = Data and Data.Battlepass
    if type(Pass) ~= "table" then
        return Claimed
    end

    local Tracks = { { "Free", Pass.ClaimedFree } }
    if Pass.HasPremium then
        table.insert(Tracks, { "Premium", Pass.ClaimedPremium })
    end
    for _, Track in Tracks do
        local Taken = {}
        for _, Tier in pairs(type(Track[2]) == "table" and Track[2] or {}) do
            Taken[tonumber(Tier) or Tier] = true
        end
        for Tier = 1, tonumber(Pass.Tier) or 0 do
            if not Taken[Tier] then
                local ok, Result = Lobby:Call("BattlepassService", "ClaimReward", Tier, Track[1])
                if ok and Result ~= false then
                    Claimed = Claimed + 1
                end
                task.wait(0.3)
            end
        end
    end
    return Claimed
end

--------------------------- [[ Best Gear ]] ---------------------------

-- the inventory screen's own Equip Best scoring
function Lobby:ScoreItem(Item)
    local Score = (Lobby.RarityIndex[Item.Rarity or "Common"] or 0) * 1000

    if Item.Slot == "Ring" then
        Score = Score + (Item.BaseDamage or 0) * 10
    elseif (Item.Slot == "Body" or Item.Slot == "Head") and type(Item.GuaranteedStat) == "table" then
        Score = Score + (Item.GuaranteedStat.Value or 0) * 10
    end
    for _, Value in pairs(type(Item.Stats) == "table" and Item.Stats or {}) do
        Score = Score + math.abs(tonumber(Value) or 0) * 2
    end
    if (Item.EnchantLevel or 0) > 0 then
        Score = Score + Item.EnchantLevel * 50
    end
    return Score
end

-- Equips the best Head, Body and Ring, as the Equip Best button does: locked, unidentified
-- and too-high-level items are skipped, and a slot is left alone when what is worn already wins.
function Lobby:EquipBest()
    local Data = Lobby:GetPlayerData()
    if Data == nil or type(Data.EquipmentInventory) ~= "table" then
        return 0
    end
    local Level = Data.PlayerLevel or 1
    local Worn = type(Data.Equipment) == "table" and Data.Equipment or {}

    local Equipped = 0
    for _, Slot in { "Head", "Body", "Ring" } do
        local Best, BestScore = nil, -1
        local Current = Worn[Slot]
        if type(Current) == "table" and Current.GUID and Current.Identified ~= false then
            BestScore = Lobby:ScoreItem(Current)
        end

        for _, Item in pairs(Data.EquipmentInventory) do
            if type(Item) == "table" and Item.GUID and Item.Slot == Slot and not Item.Locked
                and Item.Identified ~= false and not (Item.LevelReq and Level < Item.LevelReq) then
                local Score = Lobby:ScoreItem(Item)
                if Score > BestScore then
                    Best, BestScore = Item, Score
                end
            end
        end

        if Best ~= nil then
            local ok, Result = Lobby:Call("EquipmentService", "Equip", Best.GUID)
            if ok and Result ~= false then
                Equipped = Equipped + 1
            end
            task.wait(0.3)
        end
    end
    return Equipped
end

--------------------------- [[ Stat Points ]] ---------------------------

-- the stat screen's Auto Allocate button; only sent when there are points to spend
function Lobby:AllocateStats()
    local Data = Lobby:GetPlayerData()
    local Unspent = Data and tonumber(Data.UnspentSkillPoints) or 0
    if Unspent <= 0 then
        return 0
    end
    local ok, Result = Lobby:Call("StatService", "AutoAllocate")
    return (ok and Result ~= false) and Unspent or 0
end

--------------------------- [[ Account Pass ]] ---------------------------

-- Everything above that is switched on, in one go. Each part only acts when there is
-- something to do, so running it again is harmless.
function Lobby:RunAccountPass()
    local State = Lobby.AccountState
    if State.Busy then
        return State.Status
    end
    State.Busy = true

    local Parts = {}
    local function Run(Enabled, Label, Method)
        if not Enabled then
            return
        end
        State.Status = Label .. "..."
        local ok, Count = pcall(Method, Lobby)
        if not ok then
            if Debug then warn("[Account] " .. Label .. " failed:", Count) end
            table.insert(Parts, Label .. ": error")
        elseif (tonumber(Count) or 0) > 0 then
            table.insert(Parts, ("%s: %d"):format(Label, Count))
        end
    end

    Run(State.Quests, "quests claimed", Lobby.ClaimQuests)
    Run(State.Battlepass, "battlepass claims", Lobby.ClaimBattlepass)
    Run(State.EquipBest, "items equipped", Lobby.EquipBest)
    Run(State.Allocate, "stat points spent", Lobby.AllocateStats)

    State.Status = #Parts > 0 and table.concat(Parts, ", ") or "nothing to do"
    State.Busy, State.Done = false, true
    return State.Status
end

--------------------------- [[ Class Webhook ]] ---------------------------

-- Result is { ClassName, Rarity, Aspect, Left }; Spins is how many the session used.
function Collection:SendClassWebhook(Result, Spins, Outcome)
    local State = Collection.WebhookState
    if _http_request == nil then
        return false, "this executor has no request function"
    end
    local Url = State.Url
    if string.match(Url, "^https://[%w%.%-]*discord[%w%.%-]*/api/webhooks/") == nil then
        return false, "no Discord webhook URL is set"
    end
    Result = type(Result) == "table" and Result or {}

    local Lines = {
        "Class : " .. tostring(Result.ClassName or "?"),
        "Rarity : " .. tostring(Result.Rarity or "?"),
    }
    if type(Result.Aspect) == "string" and Result.Aspect ~= "" then
        table.insert(Lines, "Aspect : " .. Result.Aspect)
    end
    table.insert(Lines, "Spins Used : " .. tostring(Spins or 0))
    table.insert(Lines, ("%s Spins Left : %s"):format(Lobby.SpinState.Type, tostring(Result.Left or "?")))
    if Outcome ~= nil then
        table.insert(Lines, "Result : " .. tostring(Outcome))
    end

    local Body = Services.HttpService:JSONEncode({
        embeds = {
            {
                title = "Class Spin !",
                description = table.concat(Lines, "\n"),
                author = { name = "Dungeon Lootr" },
                footer = { text = "VaderHug", icon_url = State.Asset },
                timestamp = DateTime.now():ToIsoDate(),
                thumbnail = { url = State.Asset },
            },
        },
        username = "VaderHug",
        avatar_url = State.Asset,
        attachments = {},
    })

    local ok, Response = pcall(_http_request, {
        Url = Url,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = Body,
    })
    if not ok then
        return false, tostring(Response)
    end

    local Code = type(Response) == "table" and tonumber(Response.StatusCode) or nil
    if Code ~= nil and (Code < 200 or Code >= 300) then
        return false, "Discord answered " .. Code
    end
    return true
end

--------------------------- [[ Class Spin ]] ---------------------------

function Lobby:GetRarityRank(Rarity)
    return table.find(Lobby.RarityOrder, Rarity) or 0
end

function Lobby:GetClassRarity(ClassName)
    local Data = Lobby.ClassData
    if Data == nil or type(Data.GetRarity) ~= "function" or ClassName == nil then
        return nil
    end
    local ok, Rarity = pcall(Data.GetRarity, ClassName)
    return ok and Rarity or nil
end

-- every class a spin can give, lowest rarity first
function Lobby:GetClassNames()
    local Names = {}
    local Data = Lobby.ClassData
    if Data ~= nil and type(Data.GetSummonableClassesByRarity) == "function" then
        for _, Rarity in ipairs(Lobby.RarityOrder) do
            local ok, Classes = pcall(Data.GetSummonableClassesByRarity, Rarity)
            for _, ClassName in ipairs(ok and type(Classes) == "table" and Classes or {}) do
                table.insert(Names, tostring(ClassName))
            end
        end
    end
    return Names
end

function Lobby:Summon(Name, ...)
    local Remote = Lobby.SummonFunctions and Lobby.SummonFunctions:FindFirstChild(Name)
    if Remote == nil then
        return false, "no remote " .. Name
    end
    return pcall(Remote.InvokeServer, Remote, ...)
end

-- true when the class is one worth keeping under the current settings
function Lobby:IsWantedClass(ClassName, Rarity)
    local State = Lobby.SpinState
    if State.Only ~= nil then
        return ClassName ~= nil and State.Only[ClassName] == true
    end
    if ClassName ~= nil and State.Wanted[ClassName] then
        return true
    end
    Rarity = Rarity or Lobby:GetClassRarity(ClassName)
    return Lobby:GetRarityRank(Rarity) >= math.max(Lobby:GetRarityRank(State.MinRarity), 1)
end

-- One spin of the active class slot. A spin replaces the class in that slot, so nothing is
-- spun while the slot already holds a wanted class. Spins are never bought with coins: the
-- second argument of Spin is the game's "pay 1500 coins" flag and stays false.
-- Returns "spun", "done" (nothing left to do) or "failed", plus a line for the status.
function Lobby:SpinOnce()
    local State = Lobby.SpinState

    local okSlots, Slots = Lobby:Summon("GetSlotData")
    if not okSlots or type(Slots) ~= "table" then
        return "failed", "could not read the class slots"
    end
    local Index = Slots.ActiveIndex or 1
    local Current = type(Slots.Slots) == "table" and Slots.Slots[Index] or nil
    if type(Slots.SlotLocks) == "table" and Slots.SlotLocks[Index] == true then
        return "done", "the active slot is locked - unlock it to spin"
    end
    if Current ~= nil and Lobby:IsWantedClass(Current) then
        return "done", ("keeping %s (%s)"):format(tostring(Current), tostring(Lobby:GetClassRarity(Current) or "?"))
    end

    local okCounts, Counts = Lobby:Summon("GetSpinCounts")
    local Left = okCounts and type(Counts) == "table" and tonumber(Counts[State.Type]) or 0
    if Left <= 0 then
        return "done", ("out of %s spins"):format(State.Type)
    end

    local ok, Result = Lobby:Summon("Spin", State.Type, false)
    if not ok or type(Result) ~= "table" or Result.ClassName == nil then
        return "failed", "spin refused: " .. tostring(Result)
    end

    State.Spins = State.Spins + 1
    State.Last = { ClassName = Result.ClassName, Rarity = Result.Rarity, Aspect = Result.Aspect, Left = Left - 1 }
    local Line = ("spin %d: %s (%s)"):format(State.Spins, tostring(Result.ClassName), tostring(Result.Rarity))
    if Lobby:IsWantedClass(Result.ClassName, Result.Rarity) then
        return "done", Line .. " - keeping it"
    end
    return "spun", Line .. (" - %d %s left"):format(Left - 1, State.Type)
end

coroutine.wrap(function()
    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            local State = Lobby.SpinState
            if not State.Auto then
                State.Busy = false
                task.wait(0.3)
                return
            end

            State.Busy = true
            local Outcome, Line = Lobby:SpinOnce()
            State.Status = Line
            if Outcome ~= "spun" then
                -- finished or refused: switch the toggle back off so it cannot carry on by itself
                State.Auto, State.Busy = false, false
                Collection:Notify({ Title = "Class spin", Content = tostring(Line), Duration = 8 })
                -- one post per session, and only when it actually spun something
                if Collection.WebhookState.ClassOn and State.Spins > 0 and State.Last ~= nil then
                    local Sent, Reason = Collection:SendClassWebhook(State.Last, State.Spins, Line)
                    if not Sent then
                        Collection:Notify({ Title = "Webhook", Content = "Not sent: " .. tostring(Reason), Duration = 6 })
                    end
                end
                Collection:RaiseIdentity()
                pcall(function() Collection.UIHandles.AutoSpin:SetValue(false) end)
                return
            end
            task.wait(State.Gap)
        end)
        if err then
            if Debug then warn("[Class Spin] Caught Error:", err) end
            Lobby.SpinState.Busy = false
            task.wait(1)
        end
    end
end)()

--------------------------- [[ Auto Start ]] ---------------------------

coroutine.wrap(function()
    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            local State = Lobby.State
            if not State.Auto or State.Busy or State.Started then
                if not State.Auto and not State.Busy and not State.Started then
                    State.Status = "off"
                end
                task.wait(0.5)
                return
            end

            -- already inside a run: there is nothing to start
            if Dungeon:GetFolder() ~= nil then
                State.Status = "in a dungeon"
                State.ArrivedAt = tick()
                task.wait(0.5)
                return
            end

            -- claims, gear and stat points are sorted out before leaving the lobby
            if not Lobby.AccountState.Done or Lobby.AccountState.Busy then
                State.Status = "waiting for the account pass to finish"
                State.ArrivedAt = tick()
                task.wait(0.5)
                return
            end

            -- a run is not started in the middle of spinning for a class
            if Lobby.SpinState.Auto or Lobby.SpinState.Busy then
                State.Status = "waiting for the class spin to finish"
                State.ArrivedAt = tick()
                task.wait(0.5)
                return
            end

            local Left = State.Delay - (tick() - State.ArrivedAt)
            if Left > 0 then
                State.Status = ("starting %s (%s) in %ds"):format(State.Dungeon, State.Difficulty, math.ceil(Left))
                task.wait(0.5)
                return
            end

            local Started, Detail = Lobby:StartRun()
            if not Started then
                Collection:Notify({ Title = "Lobby", Content = tostring(Detail), Duration = 8 })
                -- wait out the retry, but stop waiting the moment Auto start is switched off
                local Deadline = tick() + State.RetryWait
                while State.Auto and tick() < Deadline and Collection:IsAlive() do
                    task.wait(0.5)
                end
            end
        end)
        if err then
            if Debug then warn("[Auto Start] Caught Error:", err) end
            task.wait(1)
        end
    end
end)()

--------------------------- [[ Window ]] ---------------------------

-- Built before any control: calling into the game's modules drops this thread to game
-- identity, and Fluent cannot create instances from there until it is raised again.
Lobby.CachedLists = {
    Dungeons = Lobby:GetDungeonNames(),
    Classes  = Lobby:GetClassNames(),
}
Collection:RaiseIdentity()

Window = Fluent:CreateWindow({
    Title = "Dungeon Lootr",
    SubTitle = "by vaderhug",
    TabWidth = 150,
    Size = UDim2.fromOffset(560, 440),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl,
})

--------------------------- [[ Tabs ]] ---------------------------

Collection.Tabs = {
    Farm     = Window:AddTab({ Title = "Farming",  Icon = "swords" }),
    Dungeon  = Window:AddTab({ Title = "Dungeon",  Icon = "map" }),
    Lobby    = Window:AddTab({ Title = "Lobby",    Icon = "map" }),
    Class    = Window:AddTab({ Title = "Class",    Icon = "dices" }),
    Webhook  = Window:AddTab({ Title = "Webhook",  Icon = "bell" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
}

-- a loop body started further up can leave this thread at game identity, and Fluent
-- then fails to build the next control; raise it again on every tab lookup
Tabs = setmetatable({}, { __index = function(_, Key)
    Collection:RaiseIdentity()
    return Collection.Tabs[Key]
end })

Collection.UIHandles = {}

--------------------------- [[ Farming ]] ---------------------------

Collection.UIHandles.Enabled = Tabs.Farm:AddToggle("Enabled", {
    Title = "Auto Farm",
    Description = "Teleports to each enemy, kills it, and moves to the next room once the current one is cleared",
    Default = false,
})

Collection.UIHandles.Enabled:OnChanged(function(Value)
    Collection.FarmState.On = Value
    if not Value then
        Collection.FarmState.Target = nil
    end
end)

Tabs.Farm:AddKeybind("EnabledKey", {
    Title = "Farm keybind",
    Description = "Click, then press a key (Esc cancels)",
    Default = "F",
    Callback = function(Toggled)
        Collection.UIHandles.Enabled:SetValue(Toggled)
    end,
})

Tabs.Farm:AddDropdown("Stance", {
    Title = "Stance",
    Description = "Where to stand relative to the enemy being fought",
    Values = { "Behind", "Above", "Under" },
    Multi = false,
    Default = "Behind",
}):OnChanged(function(Value)
    if type(Value) == "string" then
        Collection.FarmState.Stance = Value
    end
end)

Tabs.Farm:AddSlider("AttackInterval", {
    Title = "Attack interval",
    Description = "Seconds between attacks",
    Default = 0.2,
    Min = 0.05,
    Max = 1,
    Rounding = 2,
}):OnChanged(function(Value)
    Collection.FarmState.Interval = Value
end)

Tabs.Farm:AddToggle("AutoSkill", {
    Title = "Auto skill",
    Description = "Use skills that are off cooldown while attacking",
    Default = true,
}):OnChanged(function(Value)
    Collection.SkillState.Auto = Value
end)

Tabs.Farm:AddDropdown("SkillSlots", {
    Title = "Skill slots",
    Description = "5 and 6 are the potion slots on the HUD",
    Values = { "1", "2", "3", "4", "5", "6" },
    Multi = true,
    Default = { "1", "2", "3", "4" },
}):OnChanged(function(Picked)
    if type(Picked) == "table" then
        Collection.SkillState.Slots = Picked
    end
end)

--------------------------- [[ Dungeon ]] ---------------------------

for _, Entry in {
    { "AutoLoot",     "Loot",     "Auto loot chests",    "Open every unlocked chest after the boss is dead, before the replay. Chests in locked areas are never touched" },
    { "AutoBlessing", "Blessing", "Auto blessing",       "Use the Blessing Altar when passing it and take the first blessing" },
    { "AutoPick",     "Pick",     "Auto pick chests",    "Take the highest rarity chests on the reward screen" },
    { "AutoReplay",   "Replay",   "Auto replay",         "Request a replay when the dungeon is completed" },
    { "AutoRefill",   "Refill",   "Auto refill potions", "Use a Potion Station whenever one is in reach" },
} do
    Collection.UIHandles[Entry[1]] = Tabs.Dungeon:AddToggle(Entry[1], { Title = Entry[3], Description = Entry[4], Default = true })
    Collection.UIHandles[Entry[1]]:OnChanged(function(Value)
        Dungeon.State[Entry[2]] = Value
    end)
end

Collection.UIHandles.AutoReturn = Tabs.Dungeon:AddToggle("AutoReturn", {
    Title = "Auto back to lobby",
    Description = "Return to the lobby when the dungeon is completed. Turns Auto replay off",
    Default = false,
})

-- a finished run can only do one of the two, so switching one on switches the other off
Collection.UIHandles.AutoReturn:OnChanged(function(Value)
    Dungeon.State.Return = Value
    if Value and Dungeon.State.Replay then
        Collection.UIHandles.AutoReplay:SetValue(false)
    end
end)

Collection.UIHandles.AutoReplay:OnChanged(function(Value)
    Dungeon.State.Replay = Value
    if Value and Dungeon.State.Return then
        Collection.UIHandles.AutoReturn:SetValue(false)
    end
end)

--------------------------- [[ Lobby Status ]] ---------------------------

Collection.UIHandles.Status = Tabs.Lobby:AddParagraph({
    Title = "Status",
    Content = "off",
})

coroutine.wrap(function()
    local Shown
    while true do
        task.wait(0.5)
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            if Lobby.State.Status ~= Shown then
                Shown = Lobby.State.Status
                pcall(function() Collection.UIHandles.Status:SetDesc(tostring(Shown)) end)
            end
        end)
        if err then
            if Debug then warn("[Status] Caught Error:", err) end
            task.wait(1)
        end
    end
end)()

--------------------------- [[ Lobby ]] ---------------------------

Collection.UIHandles.AutoStart = Tabs.Lobby:AddToggle("AutoStart", {
    Title = "Auto start",
    Description = "Start a solo run of the dungeon below a few seconds after arriving in the lobby",
    Default = false,
})

Collection.UIHandles.AutoStart:OnChanged(function(Value)
    Lobby.State.Auto = Value
end)

Tabs.Lobby:AddDropdown("Dungeon", {
    Title = "Dungeon",
    Values = Lobby.CachedLists.Dungeons,
    Multi = false,
    Default = "Bandits Den",
}):OnChanged(function(Value)
    if type(Value) == "string" then
        Lobby.State.Dungeon = Value
    end
end)

Tabs.Lobby:AddDropdown("Difficulty", {
    Title = "Difficulty",
    Description = "A difficulty you have not unlocked is refused, with the game's reason",
    Values = Lobby.Difficulties,
    Multi = false,
    Default = "Easy",
}):OnChanged(function(Value)
    if type(Value) == "string" then
        Lobby.State.Difficulty = Value
    end
end)

Tabs.Lobby:AddSlider("StartDelay", {
    Title = "Start delay",
    Description = "Seconds to wait in the lobby before an automatic start",
    Default = 5,
    Min = 0,
    Max = 60,
    Rounding = 0,
}):OnChanged(function(Value)
    Lobby.State.Delay = Value
end)

Tabs.Lobby:AddButton({
    Title = "Start now",
    Description = "Start a solo run of the dungeon above right away",
    Callback = function()
        task.spawn(function()
            local ok, Detail = Lobby:StartRun()
            Collection:Notify({ Title = "Lobby", Content = tostring(Detail), Duration = ok and 5 or 8 })
        end)
    end,
})

--------------------------- [[ Account ]] ---------------------------

-- each of these runs once on arriving in the lobby, before Auto start leaves it
for _, Entry in {
    { "ClaimQuests",     "Quests",     "Claim quests",      "Claim every completed daily, weekly and limited quest" },
    { "ClaimBattlepass", "Battlepass", "Claim battlepass",  "Claim completed battlepass quests and every reached tier's reward" },
    { "EquipBest",       "EquipBest",  "Equip best gear",   "Wear the best Head, Body and Ring you can use, as the Equip Best button does" },
    { "AllocateStats",   "Allocate",   "Auto allocate stats", "Spend unspent stat points with the game's Auto Allocate" },
} do
    Tabs.Lobby:AddToggle(Entry[1], { Title = Entry[3], Description = Entry[4], Default = true })
        :OnChanged(function(Value)
            Lobby.AccountState[Entry[2]] = Value
        end)
end

--------------------------- [[ Class ]] ---------------------------

Collection.UIHandles.SpinStatus = Tabs.Class:AddParagraph({
    Title = "Status",
    Content = "off",
})

coroutine.wrap(function()
    local Shown
    while true do
        task.wait(0.5)
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            if Lobby.SpinState.Status ~= Shown then
                Shown = Lobby.SpinState.Status
                pcall(function() Collection.UIHandles.SpinStatus:SetDesc(tostring(Shown)) end)
            end
        end)
        if err then
            if Debug then warn("[Spin Status] Caught Error:", err) end
            task.wait(1)
        end
    end
end)()

-- Never saved: it spends spins and replaces the class in the active slot, so it only ever
-- runs because it was switched on in this session.
Collection.UIHandles.AutoSpin = Tabs.Class:AddToggle("AutoSpin", {
    Title = "Auto Spin",
    Description = "Spins the active class slot until a class you want comes up, or the spins run out. Each spin replaces the class in that slot",
    Default = false,
})

Collection.UIHandles.AutoSpin:OnChanged(function(Value)
    Lobby.SpinState.Auto = Value
    if Value then
        Lobby.SpinState.Spins = 0
    end
end)

Tabs.Class:AddDropdown("SpinType", {
    Title = "Spin type",
    Description = "Spins are never bought with coins; it stops when this kind runs out",
    Values = { "Normal", "Lucky" },
    Multi = false,
    Default = "Normal",
}):OnChanged(function(Value)
    if type(Value) == "string" then
        Lobby.SpinState.Type = Value
    end
end)

Tabs.Class:AddDropdown("SpinRarity", {
    Title = "Stop at rarity",
    Description = "Stops on any class of this rarity or higher",
    Values = Lobby.RarityOrder,
    Multi = false,
    Default = "Legendary",
}):OnChanged(function(Value)
    if type(Value) == "string" then
        Lobby.SpinState.MinRarity = Value
    end
end)

Tabs.Class:AddDropdown("SpinClasses", {
    Title = "Also stop on",
    Description = "Optional: stop on any of these classes too, whatever their rarity",
    Values = Lobby.CachedLists.Classes,
    Multi = true,
    Default = {},
}):OnChanged(function(Picked)
    if type(Picked) == "table" then
        Lobby.SpinState.Wanted = Picked
    end
end)

--------------------------- [[ Webhook ]] ---------------------------

Tabs.Webhook:AddToggle("Webhook", {
    Title = "Webhook notification",
    Description = "Post a summary to Discord every time a dungeon run ends",
    Default = false,
}):OnChanged(function(Value)
    Collection.WebhookState.On = Value
end)

Tabs.Webhook:AddInput("WebhookUrl", {
    Title = "Webhook URL",
    Placeholder = "https://discord.com/api/webhooks/...",
    Default = "",
    Numeric = false,
    Finished = true,
}):OnChanged(function(Text)
    Collection.WebhookState.Url = string.gsub(tostring(Text or ""), "%s", "")
end)

Tabs.Webhook:AddButton({
    Title = "Send test",
    Description = "Posts a sample run to the URL above",
    Callback = function()
        local ok, Reason = Collection:SendWebhook({
            DungeonName = "Test", Status = "Extracted", MobsKilled = 44, TimeElapsed = 157,
            TotalDamage = 25999, TotalEXP = 2152, RoomsCleared = 4,
        })
        Collection:Notify({
            Title = "Webhook",
            Content = ok and "Test sent" or ("Not sent: " .. tostring(Reason)),
            Duration = 6,
        })
    end,
})

Tabs.Webhook:AddToggle("ClassWebhook", {
    Title = "Class spin notification",
    Description = "Post the class a spin session ended on to the same URL",
    Default = false,
}):OnChanged(function(Value)
    Collection.WebhookState.ClassOn = Value
end)

Tabs.Webhook:AddButton({
    Title = "Send class test",
    Description = "Posts a sample spin result to the URL above",
    Callback = function()
        task.spawn(function()
            local ok, Reason = Collection:SendClassWebhook(
                { ClassName = "Test", Rarity = "Legendary", Aspect = "", Left = 26 }, 1, "test message")
            Collection:Notify({
                Title = "Webhook",
                Content = ok and "Test sent" or ("Not sent: " .. tostring(Reason)),
                Duration = 6,
            })
        end)
    end,
})

--------------------------- [[ Settings ]] ---------------------------

local ThemeSection = Tabs.Settings:AddSection("Theme Settings")

ThemeSection:AddDropdown("Theme", {
    Title = "Theme",
    Values = Fluent.Themes,
    Multi = false,
    Default = "Dark",
}):OnChanged(function(Value)
    if type(Value) == "string" then
        Fluent:SetTheme(Value)
    end
end)

Fluent.MinimizeKeybind = ThemeSection:AddKeybind("MinimizeKey", {
    Title = "Show / Hide Key",
    Mode = "Toggle",
    Default = "LeftControl",
})

ThemeSection:AddButton({
    Title = "Unload UI",
    Callback = function()
        Fluent:Destroy()
    end,
})

local AntiAfkSection = Tabs.Settings:AddSection("Anti-AFK")

AntiAfkSection:AddToggle("AntiAFK", {
    Title = "Anti-AFK",
    Description = "Prevent idle disconnections while the UI is open.",
    Default = true,
}):OnChanged(function(Value)
    Collection.AntiIdle.On = Value
end)

local CommunitySection = Tabs.Settings:AddSection("Community & Support")

CommunitySection:AddParagraph({
    Title = "Vader Script Official Discord",
    Content = "Vader updates, support and community.\nDiscord: https://discord.gg/sghjJ7WyWJ",
})

CommunitySection:AddButton({
    Title = "Copy Discord Invite",
    Description = "Copy the Discord invite to your clipboard.",
    Callback = function()
        local Copy = setclipboard or toclipboard
        local ok = type(Copy) == "function" and pcall(Copy, "https://discord.gg/sghjJ7WyWJ")
        Collection:Notify({
            Title = "Vader Script",
            Content = ok and "Discord invite copied to the clipboard." or "Could not copy the invite. Discord: discord.gg/sghjJ7WyWJ",
            Duration = 4,
        })
    end,
})

--------------------------- [[ Auto Save ]] ---------------------------

-- Every toggle, dropdown and slider value, kept per account in Vaderhug/DungeonLootr/<username>.json.
-- Loaded once here, after all the controls exist, then written whenever something changes.
Collection.AutoSave = {
    File = "Vaderhug/DungeonLootr/" .. LocalPlayer.Name .. ".json",
    Last = nil,
}

function Collection:ReadOptions()
    local Values = {}
    for Id, Option in pairs(Fluent.Options) do
        local Value = Option.Value
        if Id == "AutoSpin" then
            -- see the Class section: Auto Spin always starts switched off
            Value = nil
        end
        if type(Value) == "table" then
            -- multi dropdown: keep only what is ticked
            local Picked = {}
            for Key, On in pairs(Value) do
                if On then
                    Picked[tostring(Key)] = true
                end
            end
            Values[Id] = Picked
        elseif type(Value) == "boolean" or type(Value) == "number" or type(Value) == "string" then
            Values[Id] = Value
        end
    end
    return Values
end

function Collection:LoadOptions()
    local ok, Saved = pcall(function()
        return Services.HttpService:JSONDecode(readfile(Collection.AutoSave.File))
    end)
    if not ok or type(Saved) ~= "table" then
        return 0
    end

    local Applied = 0
    for Id, Value in pairs(Saved) do
        local Option = Fluent.Options[Id]
        if Option ~= nil and (type(Value) == "table" or Option.Value ~= Value) then
            Collection:RaiseIdentity()
            if pcall(function() Option:SetValue(Value) end) then
                Applied = Applied + 1
            end
        end
    end
    return Applied
end

pcall(function()
    if not isfolder("Vaderhug") then
        makefolder("Vaderhug")
    end
    if not isfolder("Vaderhug/DungeonLootr") then
        makefolder("Vaderhug/DungeonLootr")
    end
end)
Collection:LoadOptions()

--------------------------- [[ Script Config ]] ---------------------------

-- Optional settings written above the script, applied after the saved ones so they win:
--   _G.Class = "Cyborg"          (or a list of names) spin until the active slot holds it
--   _G.webhookURL = "https://discord.com/api/webhooks/..."
function Collection:ApplyScriptConfig()
    local Url = _G.webhookURL
    if type(Url) == "string" and Url ~= "" then
        Url = string.gsub(Url, "%s", "")
        Collection.WebhookState.Url = Url
        Collection:RaiseIdentity()
        pcall(function() Fluent.Options.WebhookUrl:SetValue(Url) end)
        pcall(function() Fluent.Options.Webhook:SetValue(true) end)
        pcall(function() Fluent.Options.ClassWebhook:SetValue(true) end)
    end

    local Names = _G.Class
    if type(Names) == "string" then
        Names = { Names }
    end
    if type(Names) ~= "table" or #Names == 0 then
        return
    end

    -- a name the game does not know would never come up and would burn every spin
    local Only, Missing = {}, {}
    for _, Name in ipairs(Names) do
        local Found = nil
        for _, ClassName in ipairs(Lobby.CachedLists.Classes) do
            if string.lower(ClassName) == string.lower(tostring(Name)) then
                Found = ClassName
                break
            end
        end
        if Found ~= nil then
            Only[Found] = true
        else
            table.insert(Missing, tostring(Name))
        end
    end
    if #Missing > 0 then
        Lobby.SpinState.Status = "_G.Class: no class named " .. table.concat(Missing, ", ")
        Collection:Notify({ Title = "Class spin", Content = Lobby.SpinState.Status .. " - not spinning", Duration = 10 })
        return
    end

    Lobby.SpinState.Only = Only
    Collection:RaiseIdentity()
    pcall(function() Collection.UIHandles.AutoSpin:SetValue(true) end)
end
Collection:ApplyScriptConfig()

-- the start delay counts from here, once the saved settings are in
Lobby.State.ArrivedAt = tick()

-- the arrival pass: the player's data arrives a moment after the lobby does
task.spawn(function()
    local Deadline = tick() + 20
    while Lobby:GetPlayerData() == nil and tick() < Deadline and Collection:IsAlive() do
        task.wait(0.5)
    end
    if not Collection:IsAlive() then
        return
    end

    local Summary = Lobby:RunAccountPass()
    if Summary ~= "nothing to do" then
        Collection:Notify({ Title = "Account", Content = tostring(Summary), Duration = 6 })
    end
end)

coroutine.wrap(function()
    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            local Encoded = Services.HttpService:JSONEncode(Collection:ReadOptions())
            if Encoded ~= Collection.AutoSave.Last then
                writefile(Collection.AutoSave.File, Encoded)
                Collection.AutoSave.Last = Encoded
            end
            task.wait(2)
        end)
        if err then
            if Debug then warn("[Auto Save] Caught Error:", err) end
            task.wait(5)
        end
    end
end)()

--------------------------- [[ Game Events ]] ---------------------------

-- Connected last, so the saved settings are already in place when the first event arrives.
Collection:Track(Dungeon.BuffEvents.BuffSelection.OnClientEvent:Connect(function(Options, OfferId)
    Dungeon:PickBlessing(Options, OfferId)
end))

Collection:Track(Dungeon.RunEvents.ChestSelection.OnClientEvent:Connect(function(Chests, OwnsExtraLoot)
    Dungeon:PickChests(Chests, OwnsExtraLoot, Dungeon.RunFunctions.SelectChests)
end))

Collection:Track(Dungeon.RunEvents.MidRunChestSelection.OnClientEvent:Connect(function(Chests, OwnsExtraLoot)
    Dungeon:PickChests(Chests, OwnsExtraLoot, Dungeon.RunFunctions.SelectMidRunChests)
end))

Collection:Track(Dungeon.RunEvents.PhaseChange.OnClientEvent:Connect(function(Phase, Info)
    if Phase == "BossPhase" then
        Dungeon.State.BossPhase = true
    elseif Phase == "BossDefeated" then
        Dungeon.State.BossPhase = false
        Dungeon.State.Cleared = true
    elseif Phase == "RoomCleared" then
        -- the last enemy room also reports the empty boss room (RoomIndex == TotalRooms) as
        -- cleared in the same instant; that one is not a room that was fought through
        if type(Info) ~= "table" or Info.RoomIndex ~= Info.TotalRooms then
            Collection.WebhookState.RoomsCleared = Collection.WebhookState.RoomsCleared + 1
        end
    end
end))

Collection:Track(Dungeon.RunEvents.ReplayStarting.OnClientEvent:Connect(function()
    Dungeon.State.BossPhase = false
    Dungeon.State.Cleared = false
    Collection.WebhookState.RoomsCleared = 0
end))

Collection:Track(Dungeon.RunEvents.DungeonComplete.OnClientEvent:Connect(function(Data)
    Dungeon.State.Cleared = true
    -- sent first: the replay that follows teleports away and takes this script with it
    if Collection.WebhookState.On then
        task.spawn(function()
            local ok, Reason = Collection:SendWebhook(Data)
            if not ok then
                Collection:Notify({ Title = "Webhook", Content = "Not sent: " .. tostring(Reason), Duration = 6 })
            end
        end)
    end
    Dungeon:FinishRun()
end))

-- A reward or completion screen that was already up when this script loaded has sent its event
-- too. Chests clicked by hand on that screen were never sent to the server.
task.spawn(function()
    local Controller = Collection:GetController("ChestSelectionController")
    if Controller ~= nil and Controller._active and Controller._candidates then
        if Controller._source == "Dungeon" then
            Dungeon:PickChests(Controller._candidates, Controller._ownsExtraLoot, Dungeon.RunFunctions.SelectChests)
        elseif Controller._source == "MidRun" then
            Dungeon:PickChests(Controller._candidates, Controller._ownsExtraLoot, Dungeon.RunFunctions.SelectMidRunChests)
        end
    end

    local ok, ReplayButton = pcall(function()
        local Completion = LocalPlayer.PlayerGui.Main.HUD.Dungeon_Container.Completion_Info
        return Completion.Visible and Completion.Content.ActionButtons.ReplayButton
    end)
    if ok and ReplayButton and ReplayButton.Visible then
        Dungeon.State.Cleared = true
        Dungeon:FinishRun()
    end
end)

Window:SelectTab(1)

Collection:Notify({
    Title = "vaderhug",
    Content = ("Loaded - farm is %s, auto start is %s"):format(
        Collection.FarmState.On and "on" or "off", Lobby.State.Auto and "on" or "off"),
    Duration = 6,
})
