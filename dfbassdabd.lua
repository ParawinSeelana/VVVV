---------------------------------------------- [ Configs ] ----------------------------------------------

local Debug = true
repeat task.wait() until game:IsLoaded()
local GlobalEnv = getgenv()

---------------------------------------------- [ Prepare Project ] ----------------------------------------------

local Collection = {}; Collection.__index = Collection
local SkillTree = {}; SkillTree.__index = SkillTree
local Dungeon = {}; Dungeon.__index = Dungeon
local Boss = {}; Boss.__index = Boss
local Schematics = {}; Schematics.__index = Schematics

local Services = setmetatable({}, {
    __index = function(_, k)
        return game:GetService(k)
    end
})

local Debug_Log = function(...)
    if Debug then print(...) end
end

---------------------------------------------- [ Exploits Variables ] ----------------------------------------------

_queue_on_teleport = (typeof(queue_on_teleport) == "function" and queue_on_teleport)
    or (typeof(queueonteleport) == "function" and queueonteleport)
    or (typeof(syn) == "table" and syn.queue_on_teleport)
_clear_teleport_queue = (typeof(clear_teleport_queue) == "function" and clear_teleport_queue)
    or (typeof(clearteleportqueue) == "function" and clearteleportqueue)
    or (typeof(clearqueueonteleport) == "function" and clearqueueonteleport)
_http_request = (typeof(request) == "function" and request)
    or (typeof(http_request) == "function" and http_request)
    or (typeof(syn) == "table" and syn.request)
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
local FluentLoaded, Fluent, Checker, Combat_presets, Character_info_provider, Items, Utility, QuestsModule
local DialogueModule, CamRoot, Event
local Signals, SpinFunction, ClansModule
local Window, Tabs

--------------------------- [[ Session ]] ---------------------------

if type(GlobalEnv.vaderhug_conns) == "table" then
    pcall(function()
        for _, Connection in GlobalEnv.vaderhug_conns do
            pcall(function() Connection:Disconnect() end)
        end
    end)
end
GlobalEnv.vaderhug_conns = {}

RandomID = {}
GlobalEnv.vaderhug_run = RandomID

--------------------------- [[ Anti Idle ]] ---------------------------

do
    if _G.__kaitunAntiIdle ~= nil then
        pcall(function() _G.__kaitunAntiIdle:Disconnect() end)
        _G.__kaitunAntiIdle = nil
    end

    local ok, VirtualUser = pcall(game.GetService, game, "VirtualUser")
    if ok and VirtualUser ~= nil then
        _G.__kaitunAntiIdle = LocalPlayer.Idled:Connect(function()
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end)
    end
end

function Collection:Track(Connection)
    table.insert(GlobalEnv.vaderhug_conns, Connection)
    return Connection
end

function Collection:RaiseIdentity()
    if _setthreadidentity then
        pcall(_setthreadidentity, 8)
    end
end

-- Remove the network pause overlay
task.spawn(function()
    local ok, CoreGui = pcall(game.GetService, game, "CoreGui")
    if not ok or CoreGui == nil then return end

    local Node = CoreGui:FindFirstChild("RobloxNetworkPauseNotification")
        or CoreGui:WaitForChild("RobloxNetworkPauseNotification", 20)
    if Node == nil then return end

    for _, Child in Node:GetChildren() do
        pcall(function() Child:Destroy() end)
    end

    Collection:Track(Node.ChildAdded:Connect(function(Child)
        pcall(function() Child:Destroy() end)
    end))
end)

Collection:RaiseIdentity()

--------------------------- [[ Fluent ]] ---------------------------

-- VaderUI in place of Fluent (same API); source lives in vaderui/VaderUI.lua
FluentLoaded, Fluent = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/DONUT6599/ddgdhdf/refs/heads/main/VaderUI.lua"))()
end)

if not FluentLoaded or Fluent == nil then
    warn("[hub] couldn't load Fluent: " .. tostring(Fluent))
    return
end

function Collection:IsAlive()
    return GlobalEnv.vaderhug_run == RandomID and not Fluent.Unloaded
end

local _, SaveManager = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
end)

local _, InterfaceManager = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
end)

--------------------------- [[ Game Modules ]] ---------------------------

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

Checker = Collection:TryRequire("CAM", "Global", "Checker")
Combat_presets = Collection:TryRequire("CAM", "Global", "Combat_presets")
Character_info_provider = Collection:TryRequire("CAM", "Global", "Character_info_provider")
Items = Collection:TryRequire("CAM", "Global", "Collectibles", "Items")
Utility = Collection:TryRequire("CAM", "Global", "Utility")
QuestsModule = Collection:TryRequire("CAM", "Global", "Subsets", "Gameplay", "Quests")
DialogueModule = Collection:TryRequire("CAM", "Client", "Modules", "GamePlay", "Dialogue")

CamRoot = ReplicatedStorage:FindFirstChild("CAM")
Collection.CurPower = CamRoot and CamRoot.Client.Controllers.Skills_Provider:FindFirstChild("CurPower")
Collection.Animations = ReplicatedStorage:FindFirstChild("Assets")
    and ReplicatedStorage.Assets:FindFirstChild("Animations")

Event = ReplicatedStorage
    :WaitForChild("Communication")
    :WaitForChild("ServerAndClient")
    :WaitForChild("Signals")
    :WaitForChild("SignalEvent")
    :WaitForChild("Event")

--------------------------- [[ State ]] ---------------------------

Collection.CombatState = {
    Auto = false,
    Status = "off",
    Shielded = false,
    BackoffUntil = 0,
    ComboBackoff = true,
    AvoidShield = true,
    RagdollWait = true,
    AutoBlock = true,
    LastRetarget = 0,
    LastPunch = 0,
    LastCombo = 0,
}

Collection.PositionState = {
    On = false,
    Stance = "Over",
    Targets = { ["Bandit"] = true },
}

Collection.EquipState = {
    Auto = false,
    UseBest = false,
    Item = nil,
    Category = "Stats",
}

Collection.LootState = {
    On = false,
    Busy = false,
    Range = 150, -- studs; drops further away are not teleported to
    Tries = setmetatable({}, { __mode = "k" }),
}

--------------------------- [[ Combat ]] ---------------------------

Collection.PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts", 15)
Collection.ClientRoot = Collection.PlayerScripts and Collection.PlayerScripts:WaitForChild("CU", 10)
Collection.CombatScript = Collection.ClientRoot and Collection.ClientRoot:FindFirstChild("Combat")

Collection.ComboValue = Collection.CombatScript and Collection.CombatScript:FindFirstChild("ComboValue")

if Collection.CombatScript ~= nil then
    if typeof(getsenv) == "function" then
        local ok, Env = pcall(getsenv, Collection.CombatScript)
        if ok and type(Env) == "table" and type(rawget(Env, "punch")) == "function" then
            Collection.Punch = rawget(Env, "punch")
        end
    end

    local CombatModule = Collection.CombatScript:FindFirstChild("Main_Combat_Script_Client")
    if CombatModule ~= nil then
        local ok, Loaded = pcall(require, CombatModule)
        if ok and type(Loaded) == "table" and type(Loaded.Do) == "function" then
            Collection.Do = Loaded.Do
        end
    end
end

-- 1 = punch() via getsenv, 2 = Do() via require, 3 = raw FireServer
Collection.CombatRoute = Collection.Punch and 1 or Collection.Do and 2 or 3
Collection.CombatRouteName = Collection.CombatRoute == 1 and "punch() via getsenv"
    or Collection.CombatRoute == 2 and "Do() via require"
    or "raw FireServer"

function Collection:GetEquippedCombat()
    if LocalPlayer.Character == nil or Collection.Animations == nil then
        return nil
    end

    if Collection.CurPower ~= nil then
        for _, Power in ipairs(string.split(Collection.CurPower.Value, ",")) do
            if Collection.Animations:FindFirstChild(Power .. "_Combat_Anims") then
                return Power
            end
        end
    end

    if Character_info_provider ~= nil then
        local ok, Tool = pcall(Character_info_provider.Get_equipped_tool, LocalPlayer)
        if ok and Tool ~= nil then
            local Item = Items and Items[Tool.Name]
            if (Item ~= nil and Item.HasCombat) or Collection.Animations:FindFirstChild(Tool.Name .. "_Combat_Anims") then
                return Tool.Name
            end
        end
    end

    return nil
end

function Collection:GetPresetFromTools()
    if Combat_presets == nil then
        return nil
    end

    local HumanoidsFolder = Workspace:FindFirstChild("Humanoids")
    local PlayerCharacter = (HumanoidsFolder and HumanoidsFolder:FindFirstChild(LocalPlayer.Name))
        or LocalPlayer.Character
    local ToolFolder = PlayerCharacter and PlayerCharacter:FindFirstChild("Tool_Accessories")
    if ToolFolder == nil then
        return nil
    end

    local ToolModels = ToolFolder:GetChildren()
    if #ToolModels == 0 then
        return Combat_presets.Presets["Combat"] and "Combat" or nil
    end

    local function PresetFor(Name)
        if Combat_presets.Presets[Name] then
            return Name
        end
        local Item = Items and Items[Name]
        local Mapped = Item and Item.CombatPreset
        if Mapped and Combat_presets.Presets[Mapped] then
            return Mapped
        end
    end

    for _, Model in ToolModels do
        if not string.find(Model.Name, "Sheathed") then
            local Found = PresetFor(Model.Name)
            if Found then
                return Found
            end
        end
    end

    for _, Model in ToolModels do
        local Found = PresetFor((string.gsub(Model.Name, "Sheathed%d*$", "")))
        if Found then
            return Found
        end
    end

    return nil
end

function Collection:ResolvePreset()
    if Combat_presets == nil then
        return nil
    end

    local FromTools = Collection:GetPresetFromTools()
    if FromTools ~= nil then
        return Combat_presets.Presets[FromTools], FromTools, nil
    end

    local Equipped = Collection:GetEquippedCombat()
    if Equipped == nil then
        return nil
    end

    local Preset = Combat_presets.Presets[Equipped]
    if Preset ~= nil then
        return Preset, Equipped, nil
    end

    local Item = Items and Items[Equipped]
    local PresetName, PowerName
    if Item == nil or (Item.Breathing == nil and not Item.HasCombat and Item.CombatPreset == nil) then
        PresetName, PowerName = Equipped, nil
    else
        PresetName, PowerName = Item.CombatPreset or "Regular Katana", Equipped
    end

    return Combat_presets.Presets[PresetName], PresetName, PowerName
end

function Collection:GetGapFor(Preset)
    local MaxCombo = Preset.Max or 5
    local Gap = Preset.default or 0.25
    local Current = Collection.ComboValue and Collection.ComboValue.Value or 1
    if Collection.CombatState.LastCombo >= MaxCombo and Current < MaxCombo then
        Gap = Preset.final or Gap
    end
    return Gap
end

function Collection:CombatStep()
    local Preset, PresetName, PowerName = Collection:ResolvePreset()
    if Preset == nil or PresetName == nil then
        Collection.CombatState.Status = "no combat equipped"
        return nil
    end
    if Collection.ComboValue == nil then
        Collection.CombatState.Status = "no ComboValue - is CU.Combat running?"
        return nil
    end

    local Gap = Collection:GetGapFor(Preset)
    local Since = tick() - Collection.CombatState.LastPunch
    if Gap >= Since then
        Collection.CombatState.Status = string.format("cooling down (%.2fs)", Gap - Since)
        return Gap - Since
    end

    if Checker ~= nil and Checker.check(LocalPlayer, "combat") ~= true then
        Collection.CombatState.Status = "blocked by Checker (stun / ragdoll / cutscene)"
        return nil
    end

    local MaxCombo = Preset.Max or 5
    local Value = Collection.ComboValue.Value

    if Collection.CombatRoute == 2 then
        local ok, Result = pcall(Collection.Do, Collection.ComboValue, Preset, PresetName, PowerName)
        if not ok then
            return nil
        end
        Collection.CombatState.LastCombo = (type(Result) == "table" and Result.combovalue) or Value
    else
        local BeforeSwing = (Preset.delay_before_swing and Preset.delay_before_swing[Value])
            or Preset.default_before_swing
            or (Combat_presets and Combat_presets.Default_Swing_Wait)
            or 0
        local BeforeHit = (Preset.delay_before_hit and Preset.delay_before_hit[Value])
            or Preset.default_before_hit
            or BeforeSwing

        local SpeedMultiplier = 1
        if Combat_presets and type(Combat_presets.attackSpeedMult) == "function" then
            local OkMult, Multiplier = pcall(Combat_presets.attackSpeedMult, LocalPlayer)
            if OkMult and type(Multiplier) == "number" and Multiplier > 0 then
                SpeedMultiplier = Multiplier
            end
        end

        local OkFire, FireError = pcall(function()
            Event:FireServer("Combat_Service", PresetName, Value, false,
                (BeforeHit - BeforeSwing) / SpeedMultiplier, false, nil)
        end)
        if not OkFire then
            Collection.CombatState.Status = "error: " .. tostring(FireError)
            return nil
        end

        Collection.CombatState.LastCombo = Value
    end

    if Combat_presets then
        Combat_presets.Last_Combo = Value
    end
    Collection.ComboValue.Value = (Value == MaxCombo or Value == 7) and 1 or Value + 1
    Collection.CombatState.LastPunch = tick()
    Collection.CombatState.Status = string.format("punching %s combo %d/%d", PresetName, Value, MaxCombo)

    return Collection:GetGapFor(Preset)
end

coroutine.wrap(function()
    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            if Collection.CombatState.Auto and tick() < Collection.CombatState.BackoffUntil then
                Collection.CombatState.Status = "finisher landed - backing off"
                task.wait(0.1)
            elseif Collection.CombatState.Auto and Collection.BlockState.Holding then
                Collection.CombatState.Status = "blocking a predicted attack"
                task.wait(0.05)
            elseif Collection.CombatState.Auto and Collection.CombatState.RagdollWait and Collection:IsRagdolled() then
                Collection.CombatState.Status = "ragdolled - waiting to get up"
                task.wait(0.1)
            elseif Collection.CombatState.Auto and Collection.CombatState.Shielded then
                Collection.CombatState.Status = "waiting - target still blocking"
                task.wait(0.2)
            elseif Collection.CombatState.Auto and Collection.PositionState.On and not Collection:IsTargetValid() then
                Collection.CombatState.Status = "waiting - no selected NPC nearby"
                task.wait(0.25)
            elseif Collection.CombatState.Auto then
                local ok, NextGap
                if Collection.CombatRoute == 1 then
                    ok, NextGap = pcall(Collection.Punch)
                    if not ok then
                        Collection.CombatState.Status = "punch() errored: " .. tostring(NextGap)
                    elseif NextGap == nil then
                        Collection.CombatState.Status = "punch() refused (nothing equipped, or Checker)"
                    else
                        Collection.CombatState.Status = string.format("punching (next in %.2fs)", NextGap)
                    end
                else
                    ok, NextGap = pcall(Collection.CombatStep, Collection)
                    if not ok then
                        Collection.CombatState.Status = "error: " .. tostring(NextGap)
                    end
                end
                task.wait((ok and NextGap) or 0.25)
            else
                Collection.CombatState.Status = "off"
                task.wait(0.1)
            end
        end)
        if err then
            if Debug then warn("[Combat] Caught Error:", err) end
            task.wait(1)
        end
    end
end)()

--------------------------- [[ Targets ]] ---------------------------

Collection.RegionsFolder = Workspace:WaitForChild("Humanoids", 15)
Collection.RegionsFolder = Collection.RegionsFolder and Collection.RegionsFolder:WaitForChild("Regions", 10)

function Collection:GetRegionNames()
    local Names = {}
    if Collection.RegionsFolder ~= nil then
        for _, Region in Collection.RegionsFolder:GetChildren() do
            table.insert(Names, Region.Name)
        end
    end
    table.sort(Names)
    return Names
end

function Collection:GetNpcFolders()
    local Found = {}
    for _, Region in (Collection.RegionsFolder and Collection.RegionsFolder:GetChildren() or {}) do
        local ActiveNpcs = Region:FindFirstChild("ActiveNpcs")
        if ActiveNpcs ~= nil and #ActiveNpcs:GetChildren() > 0 then
            table.insert(Found, ActiveNpcs)
        end
    end
    return Found
end

function Collection:Normalise(Text)
    return (string.gsub(string.lower(tostring(Text)), "[^%a%d]", ""))
end

function Collection:GetNpcNames()
    local Names, Seen = {}, {}

    for _, Active in Collection:GetNpcFolders() do
        for _, Folder in Active:GetChildren() do
            if Folder:IsA("Folder") and not Seen[Folder.Name] then
                Seen[Folder.Name] = true
                table.insert(Names, Folder.Name)
            end
        end
    end

    table.sort(Names)
    return Names
end

function Collection:GetRoot()
    local PlayerCharacter = LocalPlayer.Character
    local PlayerHumanoid = PlayerCharacter and PlayerCharacter:FindFirstChildOfClass("Humanoid")
    if PlayerHumanoid == nil or PlayerHumanoid.Health <= 0 then
        return nil
    end
    return PlayerCharacter:FindFirstChild("HumanoidRootPart")
end

function Collection:IsShielded(Model)
    if Model == nil then
        return false
    end

    local Overhead = Model:FindFirstChild("OverHead", true)
    local Holder = Overhead and Overhead:FindFirstChild("Holder")
    return Holder ~= nil and Holder:FindFirstChild("Frame") ~= nil
end

function Collection:IsRagdolled()
    local Body = Workspace:FindFirstChild("Humanoids")
    Body = Body and Body:FindFirstChild(LocalPlayer.Name)
    local Constraints = Body and Body:FindFirstChild("RagdollConstraints")
    local Wrist = Constraints and Constraints:FindFirstChild("RightWristRagdollConstraint")
    return Wrist ~= nil and Wrist.Active == true
end

--------------------------- [[ Attack Prediction ]] ---------------------------

-- Workspace.Humanoids.<me>.NpcsFollowing holds one ObjectValue per NPC that has aggro on us.
-- Every animation such an NPC starts (and every tick of its Combo value) is a "signal".
-- Player_Service.Values.<me>.DMG has a LastAttacked attribute that changes on every hit we
-- take, blocked or not, so each signal can be scored on whether a hit followed it. Signals
-- that turn out to hit are blocked for as long as their hits kept coming; the rest get ignored.
Collection.Attackers = {}

Collection.BlockState = {
    Until = 0,
    Holding = false,
    LastTry = 0,
    Blocks = 0,
    Events = {},
    -- [signal] = { n = times seen, h = times a hit followed, lead = s to first hit, tail = s to last hit }
    Learned = {},
    Dirty = false,
    File = "vaderhug_block_learned_v2.json",
}

pcall(function()
    Collection.BlockState.Learned = Services.HttpService:JSONDecode(readfile(Collection.BlockState.File))
end)

function Collection:OnEnemySignal(Model, Key)
    local RootPart = Collection:GetRoot()
    local NpcRoot = Model:FindFirstChild("HumanoidRootPart")
    if RootPart == nil or NpcRoot == nil or (NpcRoot.Position - RootPart.Position).Magnitude > 25 then
        return
    end
    -- an NPC that is being hit, knocked down or blocking is not attacking
    if Model:FindFirstChild("CombatStun") ~= nil or Model:FindFirstChild("RagDoll") ~= nil
        or Model:FindFirstChild("Blocking") ~= nil then
        return
    end

    local State = Collection.BlockState
    table.insert(State.Events, { key = Key, at = tick(), hits = 0 })

    -- unknown signals are blocked too: a blocked hit still registers, so it keeps learning
    local Known = State.Learned[Key]
    local Dangerous = Known == nil or Known.n < 3 or Known.h / Known.n >= 0.25
    if Collection.CombatState.AutoBlock and Dangerous then
        -- only hold until the first hit is due; OnEnemyHit keeps it up while hits keep landing,
        -- so a move that never connects costs one short block instead of its whole animation
        local Hold = Known ~= nil and Known.h > 0 and Known.lead + 0.5 or 0.9
        State.Until = math.max(State.Until, tick() + math.clamp(Hold, 0.5, 3))
    end
end

function Collection:OnEnemyHit()
    local State = Collection.BlockState
    local Now = tick()

    -- blame only the newest signal (and anything that fired in the same instant, like the
    -- Combo tick that comes with a swing animation). Its first hit has to arrive within 2.5s;
    -- after that, hits chain onto it while they keep coming less than 0.8s apart
    local Latest = State.Events[#State.Events]
    if Latest ~= nil then
        local Fresh = Now - Latest.at <= 2.5
        local Chained = Latest.last ~= nil and Now - (Latest.at + Latest.last) <= 0.8
        if Fresh or Chained then
            for Index = #State.Events, 1, -1 do
                local Event = State.Events[Index]
                if Latest.at - Event.at > 0.15 then
                    break
                end
                local Since = Now - Event.at
                Event.hits = Event.hits + 1
                Event.first = Event.first or Since
                Event.last = Since
            end
        end
    end

    -- still being hit: the attack is not done, keep the block up
    if State.Holding then
        State.Until = math.max(State.Until, Now + 0.45)
    end
end

function Collection:ScoreEnemySignals()
    local State = Collection.BlockState
    local Now = tick()
    for Index = #State.Events, 1, -1 do
        local Event = State.Events[Index]
        if Now - Event.at > 4 and (Event.last == nil or Now - (Event.at + Event.last) > 0.8) then
            local Entry = State.Learned[Event.key] or { n = 0, h = 0, lead = 0, tail = 0 }
            Entry.n = Entry.n + 1
            if Event.hits > 0 then
                Entry.h = Entry.h + 1
                Entry.lead = Entry.h == 1 and Event.first or Entry.lead * 0.7 + Event.first * 0.3
                Entry.tail = math.max(Entry.tail * 0.9, Event.last)
            end
            -- halve old history so a move the game changes can be relearned
            if Entry.n > 40 then
                Entry.n, Entry.h = Entry.n / 2, Entry.h / 2
            end
            State.Learned[Event.key] = Entry
            State.Dirty = true
            table.remove(State.Events, Index)
        end
    end
end

function Collection:WatchAttacker(Model)
    local Connections = {}
    local Combo = Model:FindFirstChild("Combo")
    if Combo ~= nil then
        table.insert(Connections, Combo.Changed:Connect(function()
            Collection:OnEnemySignal(Model, "combo")
        end))
    end

    local NpcHumanoid = Model:FindFirstChildOfClass("Humanoid")
    local Animator = NpcHumanoid and NpcHumanoid:FindFirstChildOfClass("Animator")
    if Animator ~= nil then
        table.insert(Connections, Animator.AnimationPlayed:Connect(function(Track)
            local Priority = Track.Priority
            if Priority == Enum.AnimationPriority.Core or Priority == Enum.AnimationPriority.Idle
                or Priority == Enum.AnimationPriority.Movement then
                return
            end
            local Id = Track.Animation and string.match(Track.Animation.AnimationId, "%d+")
            if Id ~= nil then
                task.defer(Collection.OnEnemySignal, Collection, Model, Id)
            end
        end))
    end
    return Connections
end

coroutine.wrap(function()
    local Wired, LastSave = nil, tick()

    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            local Body = Workspace:FindFirstChild("Humanoids")
            Body = Body and Body:FindFirstChild(LocalPlayer.Name)
            local Following = Body and Body:FindFirstChild("NpcsFollowing")

            local Present = {}
            for _, Link in (Following and Following:GetChildren() or {}) do
                local Model = Link:IsA("ObjectValue") and Link.Value
                if Model ~= nil and Model.Parent ~= nil then
                    Present[Model] = true
                    if Collection.Attackers[Model] == nil then
                        Collection.Attackers[Model] = Collection:WatchAttacker(Model)
                    end
                end
            end

            for Model, Connections in pairs(Collection.Attackers) do
                if not Present[Model] then
                    for _, Connection in Connections do
                        Connection:Disconnect()
                    end
                    Collection.Attackers[Model] = nil
                end
            end

            local Values = ReplicatedStorage:FindFirstChild("Player_Service")
            Values = Values and Values:FindFirstChild("Values")
            Values = Values and Values:FindFirstChild(LocalPlayer.Name)
            local Damage = Values and Values:FindFirstChild("DMG")
            if Damage ~= nil and Damage ~= Wired then
                Wired = Damage
                Collection:Track(Damage:GetAttributeChangedSignal("LastAttacked"):Connect(function()
                    Collection:OnEnemyHit()
                end))
            end

            Collection:ScoreEnemySignals()
            if Collection.BlockState.Dirty and tick() - LastSave > 30 then
                Collection.BlockState.Dirty, LastSave = false, tick()
                pcall(function()
                    writefile(Collection.BlockState.File, Services.HttpService:JSONEncode(Collection.BlockState.Learned))
                end)
            end
            task.wait(0.25)
        end)
        if err then
            if Debug then warn("[Attack Prediction] Caught Error:", err) end
            task.wait(1)
        end
    end

    for _, Connections in pairs(Collection.Attackers) do
        for _, Connection in Connections do
            Connection:Disconnect()
        end
    end
end)()

-- The skill controller drops a block the moment its key (Skills_1st) reads as up, so
-- holding a block means making that one key read as down for as long as we want it.
Collection.InputHandler = Collection:TryRequire("CAM", "Client", "Components", "Client", "InputHandler")
if Collection.InputHandler ~= nil then
    GlobalEnv.vaderhug_IsDown = GlobalEnv.vaderhug_IsDown or Collection.InputHandler.IsDown
    Collection.InputHandler.IsDown = function(Name, ...)
        if Name == "Skills_1st" and Collection.BlockState.Holding then
            return true
        end
        return GlobalEnv.vaderhug_IsDown(Name, ...)
    end
end

coroutine.wrap(function()
    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            local State = Collection.BlockState
            local Want = Collection.CombatState.AutoBlock and Collection.InputHandler ~= nil
                and Collection.SkillController ~= nil and tick() < State.Until

            if Want then
                local Values = ReplicatedStorage.Player_Service.Values:FindFirstChild(LocalPlayer.Name)
                local Up = Values ~= nil and Values:FindFirstChild("Blocking") ~= nil
                if not State.Holding then
                    State.Holding = true
                    State.Blocks = State.Blocks + 1
                end
                -- the first try is refused if we were mid-swing; keep asking until it is up
                if not Up and tick() - State.LastTry > 0.15 then
                    State.LastTry = tick()
                    pcall(Collection.SkillController.Attempt_Hold, "Blocking")
                end
            else
                State.Holding = false
            end
            task.wait(0.03)
        end)
        if err then
            if Debug then warn("[Auto Block] Caught Error:", err) end
            task.wait(1)
        end
    end

    Collection.BlockState.Holding = false
    if Collection.InputHandler ~= nil and GlobalEnv.vaderhug_IsDown ~= nil then
        Collection.InputHandler.IsDown = GlobalEnv.vaderhug_IsDown
    end
end)()

function Collection:PickTarget()
    local RootPart = Collection:GetRoot()
    if RootPart == nil then
        return nil
    end

    local Best, BestDist, BestRoot
    local Alternative, AlternativeDist, AlternativeRoot
    local BossTarget, BossDist, BossRoot

    for _, Active in Collection:GetNpcFolders() do
        for _, Folder in Active:GetChildren() do
            local Wanted = next(Collection.PositionState.Targets) == nil or Collection.PositionState.Targets[Folder.Name]

            if Folder:IsA("Folder") and Wanted then
                local Model = Folder:FindFirstChild(Folder.Name)
                if Model ~= nil and Model:IsA("Model") then
                    local NpcHumanoid = Model:FindFirstChildOfClass("Humanoid")
                    local NpcRoot = Model:FindFirstChild("HumanoidRootPart")
                    if NpcHumanoid ~= nil and NpcRoot ~= nil and NpcHumanoid.Health > 0 then
                        local Distance = (NpcRoot.Position - RootPart.Position).Magnitude
                        if Collection.PositionState.Targets[Folder.Name] and Folder:FindFirstChild("BossInfo") ~= nil then
                            -- a named boss outranks every mob, blocking or not
                            if BossDist == nil or Distance < BossDist then
                                BossTarget, BossDist, BossRoot = Model, Distance, NpcRoot
                            end
                        elseif Collection:IsShielded(Model) then
                            if AlternativeDist == nil or Distance < AlternativeDist then
                                Alternative, AlternativeDist, AlternativeRoot = Model, Distance, NpcRoot
                            end
                        elseif BestDist == nil or Distance < BestDist then
                            Best, BestDist, BestRoot = Model, Distance, NpcRoot
                        end
                    end
                end
            end
        end
    end

    if BossTarget ~= nil then
        return BossTarget, BossRoot
    end
    if Best == nil then
        return Alternative, AlternativeRoot
    end
    return Best, BestRoot
end

Collection.BossVisit = {}

-- boss models only stream in near their spawn, so a wanted boss with no model may just be out of range
function Collection:GetFarBossSpot(Wanted)
    local RootPart = Collection:GetRoot()
    if RootPart == nil or Wanted == nil then
        return nil
    end

    for _, Active in Collection:GetNpcFolders() do
        for _, Folder in Active:GetChildren() do
            local Info = Wanted[Folder.Name] == true and Folder:FindFirstChild("BossInfo")
            local Center = Info and Info:GetAttribute("Center")
            if typeof(Center) == "Vector3" and Folder:FindFirstChild(Folder.Name) == nil
                and (Center - RootPart.Position).Magnitude > 150
                and tick() - (Collection.BossVisit[Folder.Name] or 0) > 30 then
                return Center, Folder.Name
            end
        end
    end
end

-- Back off after the finisher lands
function Collection:HookComboTracker()
    local Service = ReplicatedStorage:FindFirstChild("Player_Service")
    local Values = Service and Service:FindFirstChild("Values")
    local Mine = Values and Values:FindFirstChild(LocalPlayer.Name)
    if Mine == nil then return end

    local function Bind(Tracker)
        if not Tracker:IsA("IntValue") then return end
        Collection:Track(Tracker.Changed:Connect(function(Value)
            if Value >= 5 then
                Collection.CombatState.BackoffUntil = Collection.CombatState.ComboBackoff and tick() + 1.5 or 0
            end
        end))
    end

    local Existing = Mine:FindFirstChild("ComboTrackerClient")
    if Existing then
        Bind(Existing)
    else
        Collection:Track(Mine.ChildAdded:Connect(function(Child)
            if Child.Name == "ComboTrackerClient" then Bind(Child) end
        end))
    end
end

task.spawn(function()
    pcall(Collection.HookComboTracker, Collection)
end)

function Collection:IsTargetValid()
    if Collection.CurrentTarget == nil or Collection.CurrentTargetRoot == nil then
        return false
    end
    if Collection.CurrentTarget.Parent == nil or Collection.CurrentTargetRoot.Parent == nil then
        return false
    end
    local NpcHumanoid = Collection.CurrentTarget:FindFirstChildOfClass("Humanoid")
    return NpcHumanoid ~= nil and NpcHumanoid.Health > 0
end

--------------------------- [[ Positioning ]] ---------------------------

coroutine.wrap(function()
    while RunService.Heartbeat:Wait() do
        if Collection.BreakLoop or not Collection:IsAlive() then break end
        local ok, err = pcall(function()
            if not Collection.PositionState.On or Collection.LootState.Busy or Collection.Shrine.Busy
                or Collection.PositionState.Travel or not Collection:IsAlive() then
                return
            end

            local RootPart = Collection:GetRoot()
            if RootPart == nil then
                Collection.CurrentTarget, Collection.CurrentTargetRoot = nil, nil
                Collection.CombatState.Shielded = false
                return
            end

            local Stale = (tick() - Collection.CombatState.LastRetarget) > 0.5

            if not Collection:IsTargetValid() or Stale then
                local NewTarget, NewRoot = Collection:PickTarget()
                if NewTarget ~= nil then
                    Collection.CurrentTarget, Collection.CurrentTargetRoot = NewTarget, NewRoot
                    Collection.CombatState.LastRetarget = tick()
                elseif not Collection:IsTargetValid() then
                    Collection.CurrentTarget, Collection.CurrentTargetRoot = nil, nil
                    Collection.CombatState.Shielded = false
                    return
                end
            end

            Collection.CombatState.Shielded = Collection.CombatState.AvoidShield and Collection:IsShielded(Collection.CurrentTarget)
            local ComboResting = tick() < Collection.CombatState.BackoffUntil

            local Distance = 3.5
                + (Collection.CombatState.Shielded and 10 or 0)
                + ((ComboResting or (Collection.CombatState.RagdollWait and Collection:IsRagdolled())) and 14 or 0)

            local Spot
            if Collection.PositionState.Stance == "Above" then
                Spot = Collection.CurrentTargetRoot.CFrame * CFrame.new(0, Distance, 0)
            elseif Collection.PositionState.Stance == "Underground" then
                Spot = Collection.CurrentTargetRoot.CFrame * CFrame.new(0, -Distance, 0)
            else
                Spot = Collection.CurrentTargetRoot.CFrame * CFrame.new(0, 0, Distance)
            end

            local UpVector = Collection.CurrentTargetRoot.CFrame.UpVector
            local Direction = Collection.CurrentTargetRoot.Position - Spot.Position
            if Direction.Magnitude < 0.05 then
                Direction = Collection.CurrentTargetRoot.CFrame.LookVector
            end
            if math.abs(Direction.Unit:Dot(UpVector)) > 0.99 then
                UpVector = Collection.CurrentTargetRoot.CFrame.LookVector
            end
            -- a target this far off is a trip, not a nudge: go the shrine way first
            if (RootPart.Position - Spot.Position).Magnitude > Collection.Shrine.Far
                and Collection:ShrineTravel(Spot.Position) then
                return
            end
            if (RootPart.Position - Spot.Position).Magnitude > 30 then
                Collection.Stuck.OwnAt = tick()
            end
            RootPart.CFrame = CFrame.lookAt(Spot.Position, Spot.Position + Direction, UpVector)

            RootPart.AssemblyLinearVelocity = Vector3.zero
            RootPart.AssemblyAngularVelocity = Vector3.zero
        end)
        if err and Debug then warn("[Positioning] Caught Error:", err) end
    end
end)()


--------------------------- [[ Quests ]] ---------------------------

function Collection:GetQuestsFolder()
    if Utility ~= nil and type(Utility.GetData) == "function" then
        local ok, Data = pcall(Utility.GetData, LocalPlayer)
        if ok and Data ~= nil then
            local Quests = Data:FindFirstChild("Quests")
            if Quests ~= nil then
                return Quests
            end
        end
    end

    local Service = ReplicatedStorage:FindFirstChild("Player_Service")
    local AllData = Service and Service:FindFirstChild("Data")
    local Mine    = AllData and AllData:FindFirstChild(LocalPlayer.Name)
    local Slots   = Mine and Mine:FindFirstChild("slots")

    if Slots ~= nil then
        for _, Slot in Slots:GetChildren() do
            local Quests = Slot:FindFirstChild("Quests")
            if Quests ~= nil and Quests:FindFirstChild("Holder") ~= nil then
                return Quests
            end
        end
    end
end

Collection.QuestByLabel = {}

function Collection:GetQuestKeys()
    local Entries = {}
    if QuestsModule ~= nil and type(QuestsModule.Holder) == "table" then
        for Key, Definition in pairs(QuestsModule.Holder) do
            local Giver = type(Definition.OfferNpc) == "string" and Definition.OfferNpc or "-"
            local Level = tonumber(string.match(Key, "%(Lv (%d+)%)")) or 0
            local Label = ("[%s] [Lv %d] %s"):format(
                Giver, Level, tostring(Definition.QuestInstance or Key))
            Collection.QuestByLabel[Label] = Key
            table.insert(Entries, { label = Label, level = Level })
        end
    end

    table.sort(Entries, function(A, B)
        if A.level ~= B.level then
            return A.level < B.level
        end
        return A.label < B.label
    end)

    local Labels = {}
    for _, Entry in Entries do
        table.insert(Labels, Entry.label)
    end
    return Labels
end

function Collection:GetActiveQuestCount()
    local Folder = Collection:GetQuestsFolder()
    local Holder = Folder and Folder:FindFirstChild("Holder")
    return Holder and #Holder:GetChildren() or 0
end

function Collection:GetQuestCooldownLeft()
    local Folder = Collection:GetQuestsFolder()
    local LastTime = Folder and Folder:FindFirstChild("LastTime")
    local Cooldown = (QuestsModule and QuestsModule.QuestCD) or 30

    if LastTime == nil or LastTime.Value <= 0 then
        return 0
    end

    local Elapsed = os.time() - LastTime.Value
    if Elapsed < 0 or Elapsed > 86400 then
        return 0
    end

    return math.max(0, Cooldown - Elapsed)
end

function Collection:AcceptQuest(Name)
    local AddQuest = DialogueModule and DialogueModule.Functions and DialogueModule.Functions.AddQuest
    if type(AddQuest) ~= "function" then
        return false, "NoAddQuestFunction"
    end

    local ok, Reason = pcall(AddQuest, Name)
    if not ok then
        return false, tostring(Reason)
    end
    if Reason ~= nil then
        return false, tostring(Reason)
    end
    return true
end

-- Where to stand when talking to a giver: touching distance, on its level, facing it.
-- ponytail: 1.5 studs leaves about half a stud between the two torsos; widen if we get shoved
Collection.GiverOffset = Vector3.new(0, 0.5, 1.5)

function Collection:FindGiver(NpcName)
    if NpcName == nil then
        return nil
    end

    local Debree = Workspace:FindFirstChild("Debree")
    local StaticRegions = Debree and Debree:FindFirstChild("Regions")
    if StaticRegions == nil then
        return nil
    end

    for _, Region in StaticRegions:GetChildren() do
        local Folder = Region:FindFirstChild("StationaryNpcs")
        local Npc    = Folder and Folder:FindFirstChild(NpcName)
        if Npc ~= nil then
            local Part = Npc:IsA("Model") and (Npc.PrimaryPart or Npc:FindFirstChild("HumanoidRootPart"))
                or (Npc:IsA("BasePart") and Npc)
            if Part ~= nil then
                return Part.Position, Region.Name
            end
        end
    end
end

function Collection:GetQuestDef(QuestName)
    return QuestsModule and type(QuestsModule.Holder) == "table"
        and QuestsModule.Holder[QuestName] or nil
end

function Collection:GetQuestGiverName(QuestName)
    local Definition = Collection:GetQuestDef(QuestName)
    return Definition ~= nil and type(Definition.OfferNpc) == "string" and Definition.OfferNpc or nil
end

function Collection:GetQuestObjective(QuestName)
    local Definition = Collection:GetQuestDef(QuestName)
    return Definition ~= nil and typeof(Definition.Position) == "Vector3" and Definition.Position or nil
end

function Collection:GetAcceptKeyFor(DisplayName)
    if QuestsModule == nil or type(QuestsModule.Holder) ~= "table" then
        return nil
    end

    for Key, Definition in pairs(QuestsModule.Holder) do
        if Key == DisplayName then
            return Key
        end
        local QuestInstance = Definition ~= nil and Definition.QuestInstance
        if typeof(QuestInstance) == "Instance" and QuestInstance.Name == DisplayName then
            return Key
        end
    end
end

--------------------------- [[ Quest Waypoints ]] ---------------------------

Collection.QuestPositions = {
    ["Ill help clear them out"] = Vector3.new(-607, 1245, -1110),

    ["Ill bring him the notes"] = Vector3.new(-515, 1245, -1251),
}

function Collection:FindNpcAnywhere(NpcName)
    if NpcName == nil then
        return nil
    end

    local function PositionOf(Object)
        local Model = Object:IsA("Model") and Object or Object:FindFirstChild(Object.Name)
        local Part = Model and (Model.PrimaryPart or Model:FindFirstChild("HumanoidRootPart"))
        return Part and Part.Position or nil
    end

    local HumanoidsFolder = Workspace:FindFirstChild("Humanoids")
    local RegionRoot = HumanoidsFolder and HumanoidsFolder:FindFirstChild("Regions")
    for _, Region in (RegionRoot and RegionRoot:GetChildren() or {}) do
        local ActiveNpcs = Region:FindFirstChild("ActiveNpcs")
        local Hit = ActiveNpcs and ActiveNpcs:FindFirstChild(NpcName)
        if Hit then
            local Position = PositionOf(Hit)
            if Position then
                return Position, Region.Name
            end
        end
    end

    local Position, RegionName = Collection:FindGiver(NpcName)
    return Position, RegionName
end

function Collection:GetMarkerPosition(AcceptKey)
    local Definition = Collection:GetQuestDef(AcceptKey)
    local Markers = Definition ~= nil and Definition.Markers
    if type(Markers) ~= "table" then
        return nil
    end

    for Label, Marker in pairs(Markers) do
        if type(Marker) == "table" and typeof(Marker.Position) == "Vector3" then
            return Marker.Position, tostring(Label)
        end
    end

    for Label, Marker in pairs(Markers) do
        if type(Marker) == "table" and type(Marker.Npc) == "string" then
            local Position = Collection:FindNpcAnywhere(Marker.Npc)
            if Position ~= nil then
                return Position, tostring(Label) .. " (" .. Marker.Npc .. ")"
            end
        end
    end

    return nil
end

function Collection:GetQuestWaypoint(AcceptKey)
    if AcceptKey == nil then
        return nil
    end

    local Hardcoded = Collection.QuestPositions[AcceptKey]
    if Hardcoded ~= nil then
        return Hardcoded, "hardcoded"
    end

    local Position = Collection:GetQuestObjective(AcceptKey)
    if Position ~= nil then
        return Position, "Position"
    end

    local MarkerPos, Label = Collection:GetMarkerPosition(AcceptKey)
    if MarkerPos ~= nil then
        return MarkerPos, "marker: " .. tostring(Label)
    end

    return nil
end

-- RequestStreamAroundAsync has been seen never returning, which froze the whole farm loop.
-- It runs on its own thread here and the caller waits at most Timeout + 1 seconds for it.
function Collection:StreamAround(Position, Timeout)
    local Done = false
    task.spawn(function()
        pcall(function() LocalPlayer:RequestStreamAroundAsync(Position, Timeout) end)
        Done = true
    end)
    local Deadline = tick() + Timeout + 1
    repeat
        task.wait(0.1)
    until Done or tick() > Deadline
end

-- Teleports to a quest's giver. When the giver is not loaded, go to the quest's objective
-- first: that brings its region in, and the giver with it.
function Collection:GoToGiver(Key, Giver)
    local Position = Collection:FindGiver(Giver)
    if Position == nil then
        local Objective = Collection:GetQuestWaypoint(Key)
        if Objective ~= nil then
            Collection:TeleportTo(Objective)
            Collection:StreamAround(Objective, 5)
            local Deadline = tick() + 4
            repeat
                task.wait(0.5)
                Position = Collection:FindGiver(Giver)
            until Position ~= nil or tick() > Deadline
        end
    end
    if Position ~= nil then
        Collection:TeleportTo(Position, Collection.GiverOffset)
        task.wait(0.5)
    end
    return Position
end

function Collection:GetActiveObjective()
    local Folder = Collection:GetQuestsFolder()
    local Holder = Folder and Folder:FindFirstChild("Holder")

    for _, Quest in (Holder and Holder:GetChildren() or {}) do
        local Key = Collection:GetAcceptKeyFor(Quest.Name)
        local Position, Source = Collection:GetQuestWaypoint(Key)
        if Position ~= nil then
            return Position, Quest.Name, Source
        end
    end
end

--------------------------- [[ Quest Cancel ]] ---------------------------

-- What the quest panel's X button sends: RemoveQuest plus the quest's display name.
function Collection:AbandonQuest(DisplayName)
    local Before = Collection:GetActiveQuestCount()
    pcall(function() Event:FireServer("RemoveQuest", DisplayName) end)

    local Deadline = tick() + 3
    repeat
        task.wait(0.2)
    until Collection:GetActiveQuestCount() < Before or tick() > Deadline
    return Collection:GetActiveQuestCount() < Before
end

-- Drops every held quest except the server-issued "Eliminate X" boss hunts (no giver, cannot
-- be taken again) and, when KeepKey is given, the quest with that accept key.
function Collection:AbandonHeldQuests(KeepKey)
    local Folder = Collection:GetQuestsFolder()
    local Holder = Folder and Folder:FindFirstChild("Holder")
    local Dropped = 0
    for _, Quest in (Holder and Holder:GetChildren() or {}) do
        local Keep = string.find(Quest.Name, "^Eliminate ") ~= nil
            or (KeepKey ~= nil and Collection:GetAcceptKeyFor(Quest.Name) == KeepKey)
        if not Keep and Collection:AbandonQuest(Quest.Name) then
            Dropped = Dropped + 1
        end
    end
    return Dropped
end

-- The quest Auto Farm is about to assign, by the level rule alone. The game refuses every
-- quest while one is held, so this cannot ask CanAddQuest the way GetNextEligibleQuest does.
function Collection:GetWantedQuest()
    if not Collection.AutoPickQuest then
        return Collection.SelectedQuest
    end

    local Level = Collection:GetPlayerLevel()
    local Best, BestLevel
    local function Consider(Key)
        local QuestLevel = tonumber(string.match(Key, "%(Lv (%d+)%)")) or 0
        if QuestLevel <= Level and (BestLevel == nil or QuestLevel > BestLevel)
            and not Collection.QuestSkip[Key] and string.find(Key, "^Ill learn") == nil
            and Collection:GetQuestDef(Key) ~= nil then
            Best, BestLevel = Key, QuestLevel
        end
    end
    for _, Key in Collection.QuestPriority do
        Consider(Key)
    end
    for _, Entry in Collection:GetQuestPlan() do
        Consider(Entry.key)
    end
    return Best
end

--------------------------- [[ Fishing Permit ]] ---------------------------

-- Dock Master Sofen's "Earn a Fishing Permit" quest, replayed from a recorded run:
-- drop the held quest -> Sofen -> AddQuest -> pick up the Permit Stamp -> back to Sofen
-- -> QuestProgress "Return to Sofen".
Collection.Permit = {
    Key = "Ill find the permit stamp(Lv 45)",
    Quest = "Earn a Fishing Permit",
    Giver = "Dock Master Sofen",
    GiverSpot = Vector3.new(-160.81, 798.75, 703.29),
    StampSpot = Vector3.new(-449.76, 800.36, 750.01),
    Busy = false,
    Status = "idle",
}

function Collection:TweenTo(Position, Speed, Lift)
    local RootPart = Collection:GetRoot()
    if RootPart == nil or Position == nil then
        return false
    end
    -- far away: respawn at the nearest crystal first and only glide the rest
    if Collection:ShrineTravel(Position) then
        RootPart = Collection:GetRoot()
        if RootPart == nil then
            return false
        end
    end

    local Time = math.max((Position - RootPart.Position).Magnitude / (Speed or 90), 0.2)
    local Hold = RunService.Heartbeat:Connect(function()
        RootPart.AssemblyLinearVelocity = Vector3.zero
        RootPart.AssemblyAngularVelocity = Vector3.zero
    end)
    local Tween = Services.TweenService:Create(RootPart, TweenInfo.new(Time, Enum.EasingStyle.Linear),
        { CFrame = CFrame.new(Position + Vector3.new(0, Lift or 3, 0)) })
    Tween:Play()
    Tween.Completed:Wait()
    Hold:Disconnect()
    return true
end

function Collection:RunPermitQuest()
    local State = Collection.Permit
    if State.Busy then
        return false, "already running"
    end
    State.Busy = true

    local function Finish(ok, Detail)
        State.Busy, State.Status = false, Detail
        return ok, Detail
    end
    local function Held()
        local Folder = Collection:GetQuestsFolder()
        local Holder = Folder and Folder:FindFirstChild("Holder")
        return Holder and Holder:FindFirstChild(State.Quest) or nil
    end
    local function WaitFor(Check, Seconds)
        local Deadline = tick() + Seconds
        while not Check() and tick() < Deadline do
            task.wait(0.2)
        end
        return Check()
    end

    if Held() == nil then
        -- one quest at a time: clear what is held first, as the recorded run did
        Collection:AbandonHeldQuests()
        local Good, Allowed = pcall(QuestsModule.CanAddQuest, State.Key)
        if not (Good and Allowed) then
            return Finish(false, "the game will not offer this quest (already done, or under Lv 45)")
        end

        State.Status = "going to " .. State.Giver
        Collection:TweenTo(Collection:FindGiver(State.Giver) or State.GiverSpot)
        local _, Why = Collection:AcceptQuest(State.Key)
        if not WaitFor(function() return Held() ~= nil end, 3) then
            return Finish(false, "quest not granted: " .. tostring(Why))
        end
    end

    local Tasks = Held():FindFirstChild("Tasks")
    local Found = Tasks and Tasks:FindFirstChild("Permit Stamp found")
    local FoundValue = Found and Found:FindFirstChild("Value")
    if FoundValue == nil or FoundValue.Value < 1 then
        State.Status = "going to the Permit Stamp"
        Collection:TweenTo(State.StampSpot)

        local Prompt
        WaitFor(function()
            for _, Child in Workspace:GetChildren() do
                if string.find(Child.Name, "^Permit Stamp") then
                    Prompt = Child:FindFirstChildWhichIsA("ProximityPrompt", true)
                end
            end
            return Prompt ~= nil
        end, 5)
        if Prompt == nil then
            return Finish(false, "no Permit Stamp at its usual spot")
        end

        Collection:FirePrompt(Prompt)
        if FoundValue ~= nil and not WaitFor(function() return FoundValue.Value >= 1 end, 3) then
            return Finish(false, "the pick up did not register")
        end
    end

    State.Status = "returning to " .. State.Giver
    Collection:TweenTo(Collection:FindGiver(State.Giver) or State.GiverSpot)
    pcall(function() Event:FireServer("QuestProgress", State.Key, "Return to Sofen") end)

    if WaitFor(function() return Held() == nil end, 4) then
        return Finish(true, "fishing permit quest complete")
    end
    -- the hand-in normally happens from his dialogue: open it so it can be finished by hand
    Collection:TalkTo(State.Giver)
    return Finish(false, "back at Sofen, but the quest is still open - finish his dialogue")
end

--------------------------- [[ Auto Fish ]] ---------------------------

-- Replays a recorded fishing run:
--   draw the rod through the client's own toolbar value (a raw Item_Equip skips the client
--   setup, and then the bite never arrives) -> Tool_Mouse Down/Up on open water -> the server
--   sends a bite -> the bar minigame reports a win -> hold the Collect prompt on the catch.
-- The server throws out a win reported under 4.5s after the bite and reports one under 2.5s
-- to its anticheat (the bar takes 5.0s at best), so wins are reported 5.6-6.8s after the bite.
Collection.Fish = {
    On = false,
    Status = "off",
    Caught = 0,
    Slot = "Five",
    Rods = { "Rare Fishing Rod", "Basic Fishing Rod" },
    Line = nil,
    CastAt = 0,
    -- where to stand: the Mistfall Harbor dock by default, or whatever the Fishing spot box says
    Spot = Vector3.new(-198, 803, 570),
    ShopSpot = Vector3.new(-196.63, 797.99, 595.36), -- Fisherman Jeso's Basic Fishing Rod
}

function Collection:GetFishingSpot()
    local Option = Fluent.Options ~= nil and Fluent.Options.FishSpot or nil
    local Numbers = {}
    for Number in string.gmatch(tostring(Option and Option.Value or ""), "-?%d+%.?%d*") do
        table.insert(Numbers, tonumber(Number))
    end
    if #Numbers >= 3 then
        return Vector3.new(Numbers[1], Numbers[2], Numbers[3])
    end
    return Collection.Fish.Spot
end

function Collection:OwnsFishingRod()
    for _, Name in Collection.Fish.Rods do
        if Boss:IsOwned(Name) then
            return true
        end
    end
    return false
end

-- No rod yet: earn the permit if it is missing (Jeso will not sell without it), then buy
-- the Basic Fishing Rod the way the recorded purchase did.
function Collection:GetFishingGear()
    local State = Collection.Fish
    if not Boss:IsOwned("Fishing Permit") then
        State.Status = "no fishing permit - running Dock Master Sofen's quest"
        local ok, Detail = Collection:RunPermitQuest()
        if not ok and not Boss:IsOwned("Fishing Permit") then
            return false, "fishing permit: " .. tostring(Detail)
        end
        task.wait(1)
    end

    State.Status = "buying a Basic Fishing Rod"
    Collection:TweenTo(State.ShopSpot)
    pcall(function() Event:FireServer("PurchaseFromShop", "Basic Fishing Rod", 1) end)

    local Deadline = tick() + 4
    repeat
        task.wait(0.3)
    until Collection:OwnsFishingRod() or tick() > Deadline
    if Collection:OwnsFishingRod() then
        return true, "bought a Basic Fishing Rod"
    end
    return false, "could not buy a Basic Fishing Rod (it costs 3,500 Wen)"
end

function Collection:HookFishingBar()
    local Scripts = ReplicatedStorage:FindFirstChild("ToolScripts")
    local Folder = Scripts and Scripts:FindFirstChild("Rare Fishing Rod")
    local Module = Folder and Folder:FindFirstChild("Rare Fishing Rod")
    local Real = GlobalEnv.vaderhug_fishBar
        or Collection:TryRequire("CAM", "Client", "Components", "NonePackagedMisc", "Minigames", "BarKeepup")
    if Module == nil or Real == nil or debug.getupvalues == nil or debug.setupvalue == nil then
        return false
    end
    GlobalEnv.vaderhug_fishBar = Real

    local Fake = function(Gui, Options)
        if not Collection.Fish.On then
            return Real(Gui, Options)
        end
        task.delay(5.6 + math.random() * 1.2, function()
            pcall(Options.Stop, true)
        end)
    end

    -- the rod module keeps BarKeepup as an upvalue a few closures down from Equipped
    local Previous = GlobalEnv.vaderhug_fishFake
    local function Patch(Function, Depth, Seen)
        for Index, Value in pairs(debug.getupvalues(Function)) do
            if Value == Real or (Previous ~= nil and Value == Previous) then
                debug.setupvalue(Function, Index, Fake)
                return true
            elseif type(Value) == "function" and Depth < 4 and not Seen[Value] and not iscclosure(Value) then
                Seen[Value] = true
                if Patch(Value, Depth + 1, Seen) then
                    return true
                end
            end
        end
        return false
    end

    local ok, Done = pcall(function()
        return Patch(require(Module).Equipped, 0, {})
    end)
    if ok and Done then
        GlobalEnv.vaderhug_fishFake = Fake
        return true
    end
    return false
end

function Collection:IsRodDrawn()
    local Body = Workspace:FindFirstChild("Humanoids")
    Body = Body and Body:FindFirstChild(LocalPlayer.Name)
    local Accessories = Body and Body:FindFirstChild("Tool_Accessories")
    return Accessories ~= nil and string.find(tostring(Accessories:GetAttribute("Value")), "Fishing Rod", 1, true) ~= nil
end

function Collection:DrawRod()
    local Rod, Identifier
    for _, Name in Collection.Fish.Rods do
        Identifier = Collection:FindItemId(Name)
        if Identifier ~= nil then
            Rod = Name
            break
        end
    end
    if Rod == nil then
        return false, "no fishing rod in your inventory"
    end

    local Slot = Collection.Fish.Slot
    if Collection:GetToolbarSlots()[Slot] ~= Identifier then
        local ok, Why = Collection:EquipToolbar(Rod, Slot)
        if not ok then
            return false, "could not put the rod on the toolbar: " .. tostring(Why)
        end
    end

    if not Collection:IsRodDrawn() then
        local Equipped = Collection:GetEquippedSlotValue()
        local Number = table.find(Collection.SlotNames, Slot)
        if Equipped == nil then
            return false, "no toolbar state to draw the rod with"
        end
        if Equipped.Value == Number then
            Equipped.Value = 0
            task.wait(0.6)
        end
        Equipped.Value = Number

        local Deadline = tick() + 3
        repeat
            task.wait(0.2)
        until Collection:IsRodDrawn() or tick() > Deadline
        task.wait(0.5)
    end
    return Collection:IsRodDrawn(), Rod
end

-- A point on open water within reach, judged the way the server judges a cast.
function Collection:FindFishingWater()
    local RootPart = Collection:GetRoot()
    if RootPart == nil then
        return nil
    end

    local Swim = {}
    for _, Part in Services.CollectionService:GetTagged("SwimParts") do
        table.insert(Swim, Part.Parent or Part)
    end
    local WaterParams = RaycastParams.new()
    WaterParams.FilterType = Enum.RaycastFilterType.Include
    WaterParams.BruteForceAllSlow = true
    WaterParams.FilterDescendantsInstances = Swim

    local SolidParams = RaycastParams.new()
    SolidParams.FilterType = Enum.RaycastFilterType.Exclude
    SolidParams.FilterDescendantsInstances = { Workspace:FindFirstChild("Debree"), RootPart.Parent }

    for _, Reach in { 18, 26, 12 } do
        for Step = 0, 11 do
            local Angle = math.rad(Step * 30)
            local Origin = RootPart.Position + Vector3.new(math.cos(Angle) * Reach, 50, math.sin(Angle) * Reach)
            local Hit = Workspace:Raycast(Origin, Vector3.new(0, -140, 0), WaterParams)
            if Hit ~= nil and (Hit.Instance.Name == "TouchPart" or Hit.Instance.Name == "Texture") then
                local Block = Workspace:Raycast(Origin, Vector3.new(0, -140, 0), SolidParams)
                if Block == nil or Block.Position.Y <= Hit.Position.Y then
                    return Hit.Position
                end
            end
        end
    end
    return nil
end

-- Our catch hangs off the rod tip; other players' catches sit in the same folder.
function Collection:CollectCatch()
    local RootPart = Collection:GetRoot()
    local Debree = Workspace:FindFirstChild("Debree")
    for _, Child in (Debree and RootPart and Debree:GetChildren() or {}) do
        if string.find(Child.Name, "^FishingCatch_") then
            local Prompt = Child:FindFirstChildWhichIsA("ProximityPrompt", true)
            local Holder = Prompt and Prompt.Parent
            local Spot = Holder and ((Holder:IsA("BasePart") and Holder.Position)
                or (Holder:IsA("Attachment") and Holder.WorldPosition)) or (Child:IsA("BasePart") and Child.Position)
            if Prompt ~= nil and Prompt.Enabled and Spot and (Spot - RootPart.Position).Magnitude <= Prompt.MaxActivationDistance + 4 then
                local Item = Child:GetAttribute("CatchItem") or Prompt.ObjectText
                -- the prompt has a real hold time; firing it without holding does nothing
                Prompt:InputHoldBegin()
                task.wait(Prompt.HoldDuration + 0.4)
                Prompt:InputHoldEnd()
                task.wait(1)
                if Child.Parent == nil then
                    return true, tostring(Item)
                end
                return false, "could not collect " .. tostring(Item)
            end
        end
    end
    return nil
end

coroutine.wrap(function()
    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            local State = Collection.Fish
            if not State.On then
                State.Status, State.Line = "off", nil
                task.wait(0.5)
                return
            end
            if not State.Hooked then
                State.Hooked = Collection:HookFishingBar()
                if not State.Hooked then
                    State.Status = "could not hook the bar minigame - play the bar yourself"
                end
            end

            if not Collection:OwnsFishingRod() then
                local Got, Why = Collection:GetFishingGear()
                State.Status = tostring(Why)
                if not Got then
                    task.wait(5)
                    return
                end
            end

            -- always fish from the chosen spot; with the line out we are pinned there anyway
            local Spot, RootNow = Collection:GetFishingSpot(), Collection:GetRoot()
            if RootNow ~= nil and (State.Line == nil or State.Line.Parent == nil)
                and (RootNow.Position - Spot).Magnitude > 4 then
                State.Status = "going to the fishing spot"
                Collection:TweenTo(Spot, nil, 0)
                task.wait(0.3)
            end

            local Drawn, Detail = Collection:DrawRod()
            if not Drawn then
                State.Status = tostring(Detail or "could not draw the rod")
                task.wait(3)
                return
            end

            if State.Line ~= nil and State.Line.Parent ~= nil then
                if LocalPlayer:GetAttribute("FishingBite") then
                    State.Status = "bite - reeling it in"
                elseif tick() - State.CastAt > 60 then
                    -- no bite for a minute: a click with the line out reels it back in
                    local RootPart = Collection:GetRoot()
                    Event:FireServer("Tool_Mouse", "Down", RootPart.Position)
                    task.wait(0.12)
                    Event:FireServer("Tool_Mouse", "Up", RootPart.Position)
                    State.Line = nil
                    State.Status = "no bite for 60s - recasting"
                    task.wait(2)
                else
                    State.Status = ("waiting for a bite (%ds)"):format(tick() - State.CastAt)
                end
                task.wait(0.3)
                return
            end
            -- the line just came in: the catch takes a few seconds to be reeled up to the rod,
            -- and casting again before taking it throws it away, so wait for it to arrive
            local Got, What
            local Until = tick() + (State.Line ~= nil and 8 or 0.5)
            State.Line = nil
            repeat
                Got, What = Collection:CollectCatch()
                if Got == nil then
                    task.wait(0.4)
                end
            until Got ~= nil or tick() > Until
            if Got == true then
                State.Caught = State.Caught + 1
                State.Status = ("caught %s (%d this session)"):format(What, State.Caught)
                task.wait(0.5)
            elseif Got == false then
                State.Status = tostring(What)
                task.wait(1)
                return
            end

            local Water = Collection:FindFishingWater()
            if Water == nil then
                State.Status = "no open water within reach - stand at the water's edge"
                task.wait(2)
                return
            end

            -- face the water we are about to cast at
            local RootPart = Collection:GetRoot()
            if RootPart ~= nil then
                RootPart.CFrame = CFrame.lookAt(RootPart.Position,
                    Vector3.new(Water.X, RootPart.Position.Y, Water.Z))
            end

            local Debree = Workspace:FindFirstChild("Debree")
            local Watch = Debree and Debree.ChildAdded:Connect(function(Child)
                if State.Line == nil and string.find(Child.Name, "^FishingLine_") then
                    State.Line = Child
                end
            end)
            State.Water = Water
            Event:FireServer("Tool_Mouse", "Down", Water)
            task.wait(0.12)
            Event:FireServer("Tool_Mouse", "Up", Water)
            State.CastAt = tick()

            local Deadline = tick() + 2
            repeat
                task.wait(0.1)
            until State.Line ~= nil or tick() > Deadline
            if Watch ~= nil then
                Watch:Disconnect()
            end
            if State.Line == nil then
                State.Status = "the cast did not go out - retrying"
                task.wait(2)
            end
        end)
        if err then
            if Debug then warn("[Auto Fish] Caught Error:", err) end
            Collection.Fish.Status = "error: " .. tostring(err)
            task.wait(2)
        end
    end
end)()

--------------------------- [[ Staff Watch ]] ---------------------------

-- The game hands out admin commands by rank in its owning group (OCIFolder.Configuration):
-- 5 = Admin (ban, kick, spectate, join), 6 / 254 / 255 = developers, partners, owner.
-- The id list is those ranks as of 2026-10-03, used when the rank lookup fails.
Collection.Staff = {
    On = true,
    Group = 12851171,
    MinRank = 5,
    Reason = "Saftly kick : Admin Found",
    Ids = {
        [444366594] = true,  -- Ouw2204
        [79188833] = true,   -- Knoxity
        [102087038] = true,  -- Diabolicah
        [69019592] = true,   -- TokensArk
        [393468218] = true,  -- AznLynx
        [4886900128] = true, -- a_climax
        [1404193459] = true, -- wp_Kiwii
        [135176226] = true,  -- trulyretsu
        [7918869207] = true, -- koyuzei
        [2725772030] = true, -- KazuSolaris
        [663795667] = true,  -- OnHalls
        [2002358262] = true, -- Faldize
    },
}

function Collection:IsStaff(Player)
    if Player == LocalPlayer then
        return false
    end
    if Collection.Staff.Ids[Player.UserId] then
        return true, "listed"
    end
    local ok, Rank = pcall(Player.GetRankInGroup, Player, Collection.Staff.Group)
    if ok and Rank >= Collection.Staff.MinRank then
        return true, "rank " .. tostring(Rank)
    end
    return false
end

function Collection:CheckStaff(Player)
    if not (Collection.Staff.On) then
        return
    end
    local Found, Why = Collection:IsStaff(Player)
    if Found then
        warn(("[hub] staff in server: %s (%s) - leaving"):format(Player.Name, tostring(Why)))
        LocalPlayer:Kick(Collection.Staff.Reason)
    end
end

function Collection:CheckAllStaff()
    for _, Player in Players:GetPlayers() do
        task.spawn(Collection.CheckStaff, Collection, Player)
    end
end

Collection:Track(Players.PlayerAdded:Connect(function(Player)
    Collection:CheckStaff(Player)
end))
Collection:CheckAllStaff()

--------------------------- [[ Stuck Watchdog ]] ---------------------------

-- Kicks us out of the game when the character ends up somewhere it should not be:
-- off the map, or yanked back to the same spot again and again by something that is not us.
Collection.Stuck = {
    On = true,
    OwnAt = 0,       -- last time one of our own teleports moved the character
    Last = nil,      -- position on the previous frame
    Root = nil,
    Landings = {},   -- where each jump we did not cause ended up
    VoidSince = nil,
    Hopping = false,
    Hold = 1.5,      -- seconds TeleportTo keeps a long jump pinned so it is not pulled back
    Status = "watching",
    Lobby = 16205713724, -- "Slayers 2", the universe's root place (main menu)
}

-- Feed it the position every frame. Returns a reason once the character looks lost.
function Collection:CheckStuck(Position, Now, Own)
    local State = Collection.Stuck

    -- ponytail: "nowhere" = an 8000-stud box around the origin, or near the kill height.
    -- Widen the box if a real area turns out to sit outside it
    local Lost = Position.Y < Workspace.FallenPartsDestroyHeight + 150 or Position.Y > 8000
        or math.abs(Position.X) > 8000 or math.abs(Position.Z) > 8000
    if Lost then
        State.VoidSince = State.VoidSince or Now
        if Now - State.VoidSince > 2 then
            return "outside the map"
        end
    else
        State.VoidSince = nil
    end

    local Last = State.Last
    State.Last = Position
    if Last ~= nil and not Own and (Position - Last).Magnitude > 40 then
        table.insert(State.Landings, { at = Now, position = Position })
        local Same = 0
        for Index = #State.Landings, 1, -1 do
            local Landing = State.Landings[Index]
            if Now - Landing.at > 45 then
                table.remove(State.Landings, Index)
            elseif (Landing.position - Position).Magnitude < 25 then
                Same = Same + 1
            end
        end
        if Same >= 3 then
            return ("pulled back to the same spot %d times"):format(Same)
        end
    end
    return nil
end

function Collection:ServerHop(Reason)
    local State = Collection.Stuck
    if State.Hopping then
        return
    end
    State.Hopping = true
    State.Status = "kicked: " .. tostring(Reason)
    warn("[hub] kicking self - " .. tostring(Reason))

    -- no rejoin: leave the game and stay out
    pcall(function()
        LocalPlayer:Kick("Safety kick : please rejoin (" .. tostring(Reason) .. ")")
    end)

    -- the kick can fail quietly; allow another attempt
    task.delay(25, function()
        State.Hopping = false
        State.Landings = {}
        State.VoidSince = nil
    end)
end

coroutine.wrap(function()
    while RunService.Heartbeat:Wait() do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            local State = Collection.Stuck
            local RootPart = Collection:GetRoot()
            if RootPart == nil or not (State.On) or State.Hopping then
                State.Last, State.VoidSince = nil, nil
                return
            end
            -- a respawn is a new root, not a teleport
            if RootPart ~= State.Root then
                State.Root, State.Last = RootPart, nil
            end

            local Reason = Collection:CheckStuck(RootPart.Position, tick(), tick() - State.OwnAt < 0.35)
            if Reason ~= nil then
                task.spawn(Collection.ServerHop, Collection, Reason)
            end
        end)
        if err and Debug then warn("[Stuck Watchdog] Caught Error:", err) end
    end
end)()

--------------------------- [[ Shrine Travel ]] ---------------------------

-- Long trips are made the game's own way instead of a raw teleport: press Set Spawn on the
-- crystal of the region we are heading for, reset the character, and respawn there.
Collection.Shrine = {
    On = true,
    -- ponytail: fixed 500 studs. Trips shorter than this stay plain teleports; lower it if
    -- those start being pulled back too
    Far = 500,
    Busy = false,
    Status = "idle",
}

function Collection:GetSpawnRegion()
    local Data = Collection:GetPlayerData()
    local Spawn = Data and Data:FindFirstChild("Spawn")
    local Equipped = Spawn and Spawn:FindFirstChild("Equipped")
    return Equipped and Equipped.Value or nil
end

-- The spawn crystal closest to a position: its model and how far it is from that position.
function Collection:GetNearestCrystal(Position)
    local Debree = Workspace:FindFirstChild("Debree")
    local StaticRegions = Debree and Debree:FindFirstChild("Regions")
    local Best, BestDistance
    for _, Region in (StaticRegions and StaticRegions:GetChildren() or {}) do
        for _, Child in Region:GetChildren() do
            if string.find(Child.Name, "SpawnCrystal") and Child:IsA("Model") then
                local ok, Pivot = pcall(function() return Child:GetPivot().Position end)
                if ok and (BestDistance == nil or (Pivot - Position).Magnitude < BestDistance) then
                    Best, BestDistance = Child, (Pivot - Position).Magnitude
                end
            end
        end
    end
    return Best, BestDistance
end

function Collection:SetSpawnAt(Crystal)
    local Goal = Crystal:GetPivot().Position
    local Region = tostring(Crystal:GetAttribute("SpawnArea") or Crystal.Parent.Name)

    for _ = 1, 3 do
        if Collection:GetSpawnRegion() == Region then
            return true, Region
        end
        local RootPart = Collection:GetRoot()
        if RootPart == nil then
            return false, Region
        end

        Collection.Stuck.OwnAt = tick()
        RootPart.CFrame = CFrame.new(Goal + Vector3.new(0, 3, 4))
        RootPart.AssemblyLinearVelocity = Vector3.zero
        Collection:StreamAround(Goal, 3)

        -- the crystal only gets its prompt once its region has loaded in
        local Prompt
        local Deadline = tick() + 4
        repeat
            Prompt = Crystal:FindFirstChildWhichIsA("ProximityPrompt", true)
            if Prompt == nil then
                task.wait(0.05)
            end
        until Prompt ~= nil or tick() > Deadline

        if Prompt ~= nil then
            Region = Prompt.ObjectText ~= "" and Prompt.ObjectText or Region
            Prompt:InputHoldBegin()
            local Until = tick() + Prompt.HoldDuration + 0.25
            while tick() < Until do
                if (RootPart.Position - Goal).Magnitude > 20 then
                    Collection.Stuck.OwnAt = tick()
                    RootPart.CFrame = CFrame.new(Goal + Vector3.new(0, 3, 4))
                end
                task.wait()
            end
            Prompt:InputHoldEnd()

            local Settle = tick() + 1.5
            repeat
                task.wait(0.1)
            until Collection:GetSpawnRegion() == Region or tick() > Settle
        end
    end
    return Collection:GetSpawnRegion() == Region, Region
end

function Collection:ResetCharacter()
    local Old = Collection:GetRoot()
    local Humanoid = Old and Old.Parent:FindFirstChildOfClass("Humanoid")
    if Humanoid == nil then
        return false
    end

    Humanoid.Health = 0
    task.wait(1)
    if Humanoid.Health > 0 then
        pcall(function() Humanoid:ChangeState(Enum.HumanoidStateType.Dead) end)
    end

    -- GetRoot is nil while dead, and a different part once the new character is up
    local Deadline = tick() + 25
    repeat
        task.wait(0.25)
    until (Collection:GetRoot() ~= nil and Collection:GetRoot() ~= Old) or tick() > Deadline
    task.wait(2)
    return Collection:GetRoot() ~= nil and Collection:GetRoot() ~= Old
end

-- Called at the start of every teleport. Returns true when it carried us most of the way.
function Collection:ShrineTravel(Position)
    local State = Collection.Shrine
    local RootPart = Collection:GetRoot()
    if not State.On or State.Busy or RootPart == nil then
        return false
    end

    local Distance = (Position - RootPart.Position).Magnitude
    if Distance <= State.Far then
        return false
    end
    -- the destination's own region may have no crystal; the nearest crystal to it is used
    -- either way, and only when it sits clearly closer to the destination than we do
    local Crystal, CrystalDistance = Collection:GetNearestCrystal(Position)
    if Crystal == nil or CrystalDistance > Distance - 200 then
        return false
    end

    return Collection:ShrineGo(Crystal)
end

-- Sets spawn at a crystal and respawns there, whatever the distance. True when we arrived.
function Collection:ShrineGo(Crystal)
    local State = Collection.Shrine
    if State.Busy or Crystal == nil then
        return false
    end

    State.Busy = true
    local Went = false
    local ok, err = pcall(function()
        State.Status = "setting spawn"
        local Set, Region = Collection:SetSpawnAt(Crystal)
        if not Set then
            State.Status = "could not set spawn at " .. tostring(Region)
            return
        end
        State.Status = "resetting to " .. tostring(Region)
        Went = Collection:ResetCharacter()
        State.Status = Went and ("respawned at " .. tostring(Region)) or "reset did not respawn"
    end)
    State.Busy = false
    if not ok then
        State.Status = "error: " .. tostring(err)
    end
    return Went
end

-- Offset is where to land relative to Position. Passing one also turns us to face Position.
function Collection:TeleportTo(Position, Offset)
    local RootPart = Collection:GetRoot()
    if RootPart == nil or Position == nil then
        return false
    end

    -- far away: respawn at the nearest crystal first, then cover what is left
    if Collection:ShrineTravel(Position) then
        RootPart = Collection:GetRoot()
        if RootPart == nil then
            return false
        end
    end

    local ok = pcall(function()
        local Spot = Position + (Offset or Vector3.new(0, 3, 4))
        local Goal = Offset ~= nil and CFrame.lookAt(Spot, Vector3.new(Position.X, Spot.Y, Position.Z))
            or CFrame.new(Spot)
        -- The game checks position about twice a second and puts a jump back where it came
        -- from. Writing the position every frame through that outlasts it: measured on a
        -- 608-stud jump, 0.6s held 0 of 3 times, 1.0s 2 of 3, 1.5s 3 of 3.
        local Until = tick() + ((RootPart.Position - Spot).Magnitude > 40 and Collection.Stuck.Hold or 0)
        -- One hold at a time. Two loops each pinning their own spot flipped the character
        -- 663 studs every frame for a second and a half; the newer trip takes over instead.
        local Mine = (Collection.Stuck.HoldId or 0) + 1
        Collection.Stuck.HoldId, Collection.Stuck.HoldUntil = Mine, Until
        repeat
            Collection.Stuck.OwnAt = tick()
            RootPart.CFrame = Goal
            RootPart.AssemblyLinearVelocity  = Vector3.zero
            RootPart.AssemblyAngularVelocity = Vector3.zero
            if tick() >= Until or Collection.Stuck.HoldId ~= Mine then
                break
            end
            RunService.Heartbeat:Wait()
        until RootPart.Parent == nil
    end)
    return ok
end

--------------------------- [[ Quest Farm State ]] ---------------------------

Collection.CodeOverrides = {
    VillageSpy = { "*Civilian*" },
}

Collection.QuestFarm       = false
Collection.QuestFarmStatus = "off"

Collection.AutoAll       = false
Collection.AutoAllStatus = "off"
Collection.AutoPickQuest = true

Collection.AutoBreathing = false
Collection.BreathingStyle = "Cheapest"
Collection.AutoTraining  = false

function Collection:GetActiveQuestKey()
    local Folder = Collection:GetQuestsFolder()
    local Holder = Folder and Folder:FindFirstChild("Holder")
    for _, Quest in (Holder and Holder:GetChildren() or {}) do
        return Collection:GetAcceptKeyFor(Quest.Name), Quest.Name
    end
end

Collection.QuestSkip = { ["Ill help clear them out"] = true }

Collection.QuestPriority = {
    "Ill take 3 bandits",
    "Ill take the bandit boss(Lv 7)",
    "Ill drive the bears back(Lv 10)",
    "Ill fell the Mother Bear(Lv 18)",
    "Ill clear out his subordinates(Lv 26)",
    "Ill deal with Kaiden(Lv 34)",
    "I will clear out his guards(Lv 40)",
    "Ill drive them off(Lv 47)",
    "I will take care of Hoyuzo(Lv 50)",
    "Ill clear the cave(Lv 62)",
    "Ill eliminate the Mizunoto(Lv 62)",
    "Ill learn the Soryu Style(Lv 62)",
    "Ill learn the Tai Chi Style(Lv 65)",
    "Ill break their watch(Lv 75)",
    "Ill thin them out(Lv 75)",
    "Ill go up after the greater ones(Lv 83)",
    "Ill help you defeat them(Lv 90)",
    "Theyre not welcome here(Lv 90)",
    "Ill learn the Reaping Blades Style(Lv 100)",
    "Ill drive back the frost(Lv 105)",
    "Ill see you to Windy Peak(Lv 105)",
    "Ill put out the blaze(Lv 115)",
}

Collection.QuestPlanCache = { List = nil, Key = nil }

function Collection:GetQuestPlan()
    if Collection.QuestPlanCache.List ~= nil and Collection.QuestPlanCache.Key == "combat" then
        return Collection.QuestPlanCache.List
    end

    local List = {}
    if QuestsModule ~= nil and type(QuestsModule.Holder) == "table" then
        for Key, Definition in pairs(QuestsModule.Holder) do
            local Category = tostring(Definition.Category or "")
            local Giver = type(Definition.OfferNpc) == "string" and Definition.OfferNpc or nil
            local Wanted = Category ~= "BossHunt" and Category ~= "Muzan"
                and not Collection.QuestSkip[Key]
                and Category == "Combat"
            if Giver ~= nil and Wanted then
                local Level = tonumber(string.match(Key, "%(Lv (%d+)%)")) or 0
                table.insert(List, { key = Key, level = Level, giver = Giver })
            end
        end
    end

    table.sort(List, function(A, B)
        if A.level ~= B.level then
            return A.level < B.level
        end
        return A.key < B.key
    end)

    Collection.QuestPlanCache.List = List
    Collection.QuestPlanCache.Key = "combat"
    return List
end

--------------------------- [[ Player Data ]] ---------------------------

function Collection:GetActiveSlot(Slots, Mine)
    local Equipped = Mine and Mine:FindFirstChild("slotEquipped")
    if Equipped ~= nil and Slots ~= nil then
        local Named = Slots:FindFirstChild("Slot" .. tostring(math.floor(Equipped.Value)))
        if Named ~= nil and Named:FindFirstChild("Inventory") ~= nil then
            return Named
        end
    end

    for _, Slot in (Slots and Slots:GetChildren() or {}) do
        if Slot:FindFirstChild("Inventory") ~= nil then
            return Slot
        end
    end
end

function Collection:GetPlayerData()
    if Utility ~= nil and type(Utility.GetData) == "function" then
        local ok, Data = pcall(Utility.GetData, LocalPlayer)
        if ok and Data ~= nil then
            return Data
        end
    end

    local Service = ReplicatedStorage:FindFirstChild("Player_Service")
    local AllData = Service and Service:FindFirstChild("Data")
    local Mine    = AllData and AllData:FindFirstChild(LocalPlayer.Name)
    local Slots   = Mine and Mine:FindFirstChild("slots")
    return Collection:GetActiveSlot(Slots, Mine)
end

function Collection:GetPlayerLevel()
    local Data = Collection:GetPlayerData()
    local Experience = Data and Data:FindFirstChild("Exp")
    local Goal = Experience and Experience:FindFirstChild("Goal")
    local PerLevel = 60
    local OkSettings, GameSettings = pcall(require, ReplicatedStorage.CAM.Global.gameSettings)
    if OkSettings and type(GameSettings) == "table" and tonumber(GameSettings.expPerLevel) then
        PerLevel = GameSettings.expPerLevel
    end
    if Goal == nil or PerLevel == 0 then
        return 0
    end
    return math.floor(Goal.Value / PerLevel)
end

function Collection:HasBreathing()
    local Data = Collection:GetPlayerData()
    local Powers = Data and Data:FindFirstChild("Powers")
    local Breathing = Powers and Powers:FindFirstChild("Breathing")
    return Breathing ~= nil and tostring(Breathing.Value) ~= ""
end

--------------------------- [[ Breathing ]] ---------------------------

Collection.BreathingStyles = {
    "Serpent", "Wind", "Insect", "Sound", "Stone", "Water", "Flame", "Thunder",
}

function Collection:GetBreathingQuestKey(Style)
    if Style == nil or Style == "" then
        return nil
    end
    return ("Ill learn %s Breathing(Lv 25)"):format(Style)
end

function Collection:GetQuestCost(Key)
    local Definition = QuestsModule and QuestsModule.Holder and QuestsModule.Holder[Key]
    if Definition == nil then
        return nil
    end
    return Definition.WenCostOnAccept, Definition.ItemCostOnAccept
end

function Collection:GetBreathingLabels()
    local Labels = { "Cheapest" }

    for _, Style in Collection.BreathingStyles do
        local Key = Collection:GetBreathingQuestKey(Style)
        local WenCost, ItemCosts = Collection:GetQuestCost(Key)

        local Bits = { ("Lv %d"):format(tonumber(string.match(Key or "", "%(Lv (%d+)%)")) or 25) }
        if WenCost ~= nil then
            table.insert(Bits, ("%d Wen"):format(WenCost))
        end

        local Costs = {}
        for ItemName, Count in pairs(type(ItemCosts) == "table" and ItemCosts or {}) do
            table.insert(Costs, ("%dx %s"):format(Count, ItemName))
        end
        table.sort(Costs)
        for _, Cost in Costs do
            table.insert(Bits, Cost)
        end

        table.insert(Labels, ("%s (%s)"):format(Style, table.concat(Bits, " - ")))
    end

    return Labels
end

function Collection:CanAfford(Key)
    local WenCost, ItemCost = Collection:GetQuestCost(Key)
    if WenCost == nil and ItemCost == nil then
        return true
    end

    local Data = Collection:GetPlayerData()
    if Data == nil then
        return false, "no player data"
    end

    if WenCost ~= nil then
        local Wen = Data:FindFirstChild("Wen")
        local Have = Wen and Wen.Value or 0
        if Have < WenCost then
            return false, ("need %d Wen, have %d"):format(WenCost, Have)
        end
    end

    if type(ItemCost) == "table" then
        local Have = {}
        local OuterInventory = Data:FindFirstChild("Inventory")
        local InnerInventory = OuterInventory and OuterInventory:FindFirstChild("Inventory")
        for _, Item in (InnerInventory and InnerInventory:GetChildren() or {}) do
            local Amount = Item:FindFirstChild("Amount")
            Have[Item.Name] = (Have[Item.Name] or 0) + (Amount and Amount.Value or 1)
        end

        for ItemName, Need in pairs(ItemCost) do
            if (Have[ItemName] or 0) < Need then
                return false, ("need %dx %s, have %d"):format(Need, tostring(ItemName), Have[ItemName] or 0)
            end
        end
    end

    return true
end

function Collection:IsQuestUsable(Key)
    if Key == nil or QuestsModule == nil or type(QuestsModule.CanAddQuest) ~= "function" then
        return false
    end
    local Definition = QuestsModule.Holder and QuestsModule.Holder[Key]
    if Definition == nil then
        return false
    end
    local Good, Allowed = pcall(QuestsModule.CanAddQuest, Key)
    if not (Good and Allowed) then
        return false
    end
    local Giver = type(Definition.OfferNpc) == "string" and Definition.OfferNpc or nil
    if Giver == nil then
        return false
    end
    -- givers only exist in the region you are standing in, so an unloaded giver is fine
    -- as long as the quest has an objective we can travel to (see GoToGiver)
    if Collection:FindGiver(Giver) == nil and Collection:GetQuestWaypoint(Key) == nil then
        return false
    end
    return true, Giver
end

--------------------------- [[ Item Farm ]] ---------------------------

Collection.FarmQuestSkip = {}

Collection.ItemFarm = {
    ["Demon Horns"] = {
        targets  = { ["Hoyuzo"] = true, ["Hoyuzo Subordinate"] = true },
        position = Vector3.new(651, 1001, -1023),
        quests   = {
            "I will clear out his guards(Lv 40)",
            "I will take care of Hoyuzo(Lv 50)",
        },
    },
    ["Beast Core"] = {
        targets  = { ["Beast Born Demon"] = true },
        position = Vector3.new(171, 889, 604),
        quests   = { "Ill drive them off(Lv 47)" },
    },
}

function Collection:GetItemCount(ItemName)
    local Data = Collection:GetPlayerData()
    local OuterInventory = Data and Data:FindFirstChild("Inventory")
    local InnerInventory = OuterInventory and OuterInventory:FindFirstChild("Inventory")
    local Total = 0
    for _, Item in (InnerInventory and InnerInventory:GetChildren() or {}) do
        if Item.Name == ItemName then
            local Amount = Item:FindFirstChild("Amount")
            Total = Total + (Amount and Amount.Value or 1)
        end
    end
    return Total
end

function Collection:GetBreathingItemGap(Style)
    local Key = Collection:GetBreathingQuestKey(Style)
    local _, ItemCost = Collection:GetQuestCost(Key)
    if type(ItemCost) ~= "table" then
        return nil
    end

    for ItemName, Need in pairs(ItemCost) do
        if Collection.ItemFarm[ItemName] then
            local Have = Collection:GetItemCount(ItemName)
            if Have < Need then
                return ItemName, Need, Have
            end
        end
    end
end

--------------------------- [[ Quest Selection ]] ---------------------------

function Collection:GetNextEligibleQuest()
    if QuestsModule == nil or type(QuestsModule.CanAddQuest) ~= "function" then
        return nil
    end

    local Usable = function(...) return Collection:IsQuestUsable(...) end

    if Collection.AutoBreathing and Collection:GetPlayerLevel() >= 25 and not Collection:HasBreathing() then
        local Order = {}
        if Collection.BreathingStyle ~= nil and Collection.BreathingStyle ~= "Cheapest" then
            table.insert(Order, Collection.BreathingStyle)
        else
            for _, Style in Collection.BreathingStyles do
                table.insert(Order, Style)
            end
        end

        for _, Style in Order do
            local Key = Collection:GetBreathingQuestKey(Style)
            local Fine, Giver = Usable(Key)
            if Fine then
                local Afford, Why = Collection:CanAfford(Key)
                if Afford then
                    return Key, Giver
                end
            end
        end
    end

    -- the highest-level quest the character qualifies for, wherever its giver is.
    -- "Ill learn ..." style quests need items, so they are left to the fallback below
    local Level = Collection:GetPlayerLevel()
    local Best, BestGiver, BestLevel
    local function Consider(Key)
        local QuestLevel = tonumber(string.match(Key, "%(Lv (%d+)%)")) or 0
        if QuestLevel <= Level and (BestLevel == nil or QuestLevel > BestLevel)
            and not Collection.QuestSkip[Key] and string.find(Key, "^Ill learn") == nil then
            local Fine, Giver = Usable(Key)
            if Fine then
                Best, BestGiver, BestLevel = Key, Giver, QuestLevel
            end
        end
    end
    for _, Key in Collection.QuestPriority do
        Consider(Key)
    end
    for _, Entry in Collection:GetQuestPlan() do
        Consider(Entry.key)
    end
    if Best ~= nil then
        return Best, BestGiver
    end

    for _, Key in Collection.QuestPriority do
        if not Collection.QuestSkip[Key] then
            local Fine, Giver = Usable(Key)
            if Fine then
                return Key, Giver
            end
        end
    end

    for _, Entry in Collection:GetQuestPlan() do
        local Fine, Giver = Usable(Entry.key)
        if Fine then
            return Entry.key, Giver
        end
    end
end

function Collection:IsAllTasksComplete()
    local Folder = Collection:GetQuestsFolder()
    local Holder = Folder and Folder:FindFirstChild("Holder")
    local Any, Complete = false, true

    for _, Quest in (Holder and Holder:GetChildren() or {}) do
        local Tasks = Quest:FindFirstChild("Tasks")
        for _, QuestTask in (Tasks and Tasks:GetChildren() or {}) do
            Any = true
            local Value = QuestTask:FindFirstChild("Value")
            local Maximum = QuestTask:FindFirstChild("Max")
            if not (Value and Maximum and Maximum.Value > 0 and Value.Value >= Maximum.Value) then
                Complete = false
            end
        end
    end

    return Any and Complete
end

function Collection:GetActiveTaskCodes()
    local Folder = Collection:GetQuestsFolder()
    local Holder = Folder and Folder:FindFirstChild("Holder")
    local Codes = {}

    for _, Quest in (Holder and Holder:GetChildren() or {}) do
        local Tasks = Quest:FindFirstChild("Tasks")
        for _, QuestTask in (Tasks and Tasks:GetChildren() or {}) do
            local Code    = QuestTask:FindFirstChild("Code")
            local Value   = QuestTask:FindFirstChild("Value")
            local Maximum = QuestTask:FindFirstChild("Max")
            local Done    = Value and Maximum and Maximum.Value > 0 and Value.Value >= Maximum.Value

            if Code ~= nil and Code.Value ~= "" and not Done then
                table.insert(Codes, Code.Value)
            end
        end
    end

    return Codes
end

function Collection:ResolveQuestTargets()
    local Codes = Collection:GetActiveTaskCodes()
    if #Codes == 0 then
        return {}, "no unfinished quest task"
    end

    local Present, BossByCode = {}, {}
    for _, Active in Collection:GetNpcFolders() do
        for _, Folder in Active:GetChildren() do
            if Folder:IsA("Folder") then
                Present[Folder.Name] = true
                local Info = Folder:FindFirstChild("BossInfo")
                local NpcCode = Info and Info:GetAttribute("NpcCode")
                if NpcCode ~= nil then
                    BossByCode[tostring(NpcCode)] = Folder.Name
                end
            end
        end
    end

    if next(Present) == nil then
        return {}, "no NPCs loaded anywhere"
    end

    local Picked = {}

    for _, Code in Codes do
        local FlatCode = Collection:Normalise(Code)

        -- a boss task's code is the boss folder's NpcCode: take the boss alone, not its subordinates
        if BossByCode[Code] ~= nil then
            Picked[BossByCode[Code]] = true
            continue
        end

        if Present[Code] then
            Picked[Code] = true
        end

        for _, Name in (Collection.CodeOverrides[Code] or {}) do
            if Present[Name] then
                Picked[Name] = true
            end
        end

        for Name in pairs(Present) do
            local Flat = Collection:Normalise(Name)
            if #Flat > 2 and (string.find(FlatCode, Flat, 1, true)
                or string.find(Flat, FlatCode, 1, true)) then
                Picked[Name] = true
            end
        end
    end

    if next(Picked) == nil then
        return {}, "no NPC here matches " .. table.concat(Codes, "/")
    end

    local Names = {}
    for Name in pairs(Picked) do
        table.insert(Names, Name)
    end
    table.sort(Names)

    return Picked, table.concat(Names, ", ") .. "  <- " .. table.concat(Codes, "/")
end

coroutine.wrap(function()
    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            if Collection.QuestFarm then
                local ok, Picked, Note = pcall(Collection.ResolveQuestTargets, Collection)
                if ok then
                    Collection.QuestFarmStatus = Note
                    if next(Picked) ~= nil then
                        Collection.PositionState.Targets = Picked
                    else
                        Collection.PositionState.Targets = { ["__no_target__"] = true }
                    end

                    local BossSpot, BossName = Collection:GetFarBossSpot(Collection.PositionState.Targets)
                    if BossSpot ~= nil and Collection.PositionState.On then
                        Collection.BossVisit[BossName] = tick()
                        Collection.PositionState.Travel = true
                        Collection.CurrentTarget, Collection.CurrentTargetRoot = nil, nil
                        pcall(Collection.TeleportTo, Collection, BossSpot)
                        task.wait(1.5)
                        Collection.PositionState.Travel = false
                    end
                else
                    Collection.QuestFarmStatus = "error: " .. tostring(Picked)
                end
                task.wait(2)
            else
                Collection.QuestFarmStatus = "off"
                task.wait(0.5)
            end
        end)
        if err then
            if Debug then warn("[Quest Targets] Caught Error:", err) end
            task.wait(1)
        end
    end
end)()

--------------------------- [[ Loot ]] ---------------------------

function Collection:FirePrompt(Prompt)
    if _fireproximityprompt then
        return pcall(_fireproximityprompt, Prompt)
    end

    return pcall(function()
        local Hold = Prompt.HoldDuration
        Prompt.HoldDuration = 0
        Prompt:InputHoldBegin()
        Prompt:InputHoldEnd()
        Prompt.HoldDuration = Hold
    end)
end

function Collection:LootOnce()
    local RootPart = Collection:GetRoot()
    local Fired = 0

    -- another trip is still pinning its landing spot: leave the drops for the next pass
    if tick() < (Collection.Stuck.HoldUntil or 0) then
        return 0
    end

    local function TryPrompt(Prompt)
        if Prompt == nil or not Prompt.Enabled then
            return
        end

        if Collection:FirePrompt(Prompt) then
            Fired = Fired + 1
        end
    end

    -- walk every drop: teleport onto it, fire its prompt, then go back where we were
    local Origin = RootPart and RootPart.CFrame
    local Drops = Workspace:FindFirstChild("LootDrops")
    for _, Drop in (Drops and Drops:GetChildren() or {}) do
        local Prompt = Drop:FindFirstChildWhichIsA("ProximityPrompt", true)
        local Tries = Collection.LootState.Tries[Drop] or 0
        -- ponytail: 3 visits per drop, so one we cannot pick up does not pin us there forever
        local Holder = Prompt and Prompt.Parent
        local Spot = Holder and (Holder:IsA("BasePart") and Holder.Position
            or Holder:IsA("Attachment") and Holder.WorldPosition
            or Drop:IsA("PVInstance") and Drop:GetPivot().Position)
        -- drops further than Range from where we started are left alone, and cost no visit
        local InRange = not (Spot and Origin) or (Origin.Position - Spot).Magnitude <= Collection.LootState.Range
        -- private drops belong to one player; someone else's cannot be claimed
        local Owner = Drop:GetAttribute("DropOwnerUserId")
        -- no character means no visit: while dead this used to fire from wherever the body lay
        -- and use up all three tries in a second
        if RootPart ~= nil and RootPart.Parent ~= nil and Prompt ~= nil and Prompt.Enabled and Tries < 3 and InRange
            and (Owner == nil or Owner == LocalPlayer.UserId) then
            Collection.LootState.Tries[Drop] = Tries + 1

            if Spot and (RootPart.Position - Spot).Magnitude > 6 then
                Collection.LootState.Busy = true
                -- stand on the drop itself (the prompt only reaches 10 studs)
                Collection:TeleportTo(Spot, Vector3.new(0, 3, 1))
                task.wait(0.2)
            end

            TryPrompt(Prompt)
            -- the claim takes a moment to come back; leaving at once looked like a failed visit
            local Deadline = tick() + 0.6
            repeat
                task.wait(0.05)
            until Drop.Parent == nil or tick() > Deadline
        end
    end
    if Collection.LootState.Busy then
        Collection.LootState.Busy = false
        if Origin ~= nil and RootPart.Parent ~= nil then
            Collection.Stuck.OwnAt = tick()
            RootPart.CFrame = Origin
        end
    end

    local Chests = Workspace:FindFirstChild("Chests")
    for _, Chest in (Chests and Chests:GetChildren() or {}) do
        TryPrompt(Chest:FindFirstChildWhichIsA("ProximityPrompt", true))
    end

    return Fired
end

coroutine.wrap(function()
    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            if Collection.LootState.On then
                local Good, Why = pcall(Collection.LootOnce, Collection)
                Collection.LootState.Busy = false
                if not Good and Debug then warn("[Loot] Caught Error:", Why) end
                task.wait(0.3)
            else
                task.wait(0.3)
            end
        end)
        if err then
            if Debug then warn("[Loot] Caught Error:", err) end
            task.wait(1)
        end
    end
end)()


--------------------------- [[ Inventory & Equip ]] ---------------------------

Collection.SlotNames = { "One", "Two", "Three", "Four", "Five" }

function Collection:GetInventoryItems()
    local Data = Collection:GetPlayerData()
    local OuterInventory = Data and Data:FindFirstChild("Inventory")
    local InnerInventory = OuterInventory and OuterInventory:FindFirstChild("Inventory")
    local ItemList = {}

    if InnerInventory ~= nil then
        for _, Item in InnerInventory:GetChildren() do
            local Identifier = Item:FindFirstChild("Id")
            local Amount = Item:FindFirstChild("Amount")
            table.insert(ItemList, {
                name = Item.Name,
                id = Identifier and Identifier.Value or nil,
                amount = Amount and Amount.Value or 1,
            })
        end
    end

    table.sort(ItemList, function(A, B)
        return (A.id or 0) < (B.id or 0)
    end)

    return ItemList
end

function Collection:FindItemId(Name)
    for _, Item in Collection:GetInventoryItems() do
        if Item.name == Name then
            return Item.id
        end
    end
end

function Collection:GetEquippedSlots(Category)
    local Data = Collection:GetPlayerData()
    local Inventory = Data and Data:FindFirstChild("Inventory")
    local Accessories = Inventory and Inventory:FindFirstChild("Accessories")
    local Folder = Accessories and Accessories:FindFirstChild(Category or "Stats")
    local Out = {}

    if Folder ~= nil then
        for _, Slot in Folder:GetChildren() do
            Out[Slot.Name] = Slot.Value
        end
    end

    return Out
end

function Collection:EquipAccessory(Item, Slot, Category)
    Slot = Slot or "One"
    Category = Category or "Stats"

    local Identifier = Item
    if type(Item) == "string" then
        Identifier = Collection:FindItemId(Item)
        if Identifier == nil then
            return false, "not in inventory: " .. tostring(Item)
        end
    end

    if type(Identifier) ~= "number" then
        return false, "item must be a name or numeric id"
    end

    local ok, Reason = pcall(function()
        Event:FireServer("AccessoryEquip", Slot, Identifier, Category)
    end)
    if not ok then
        return false, tostring(Reason)
    end
    return true
end

function Collection:EquipAndWait(Item, Slot, Category, Timeout)
    Slot = Slot or "One"
    Category = Category or "Stats"

    local Before = Collection:GetEquippedSlots(Category)[Slot]
    local ok, Reason = Collection:EquipAccessory(Item, Slot, Category)
    if not ok then
        return false, Reason
    end

    local Deadline = tick() + (Timeout or 2)
    repeat
        task.wait(0.1)
    until Collection:GetEquippedSlots(Category)[Slot] ~= Before or tick() > Deadline

    if Collection:GetEquippedSlots(Category)[Slot] ~= Before then
        return true
    end
    return false, "NotApplied"
end

function Collection:GetToolbarSlots()
    local Data = Collection:GetPlayerData()
    local Inventory = Data and Data:FindFirstChild("Inventory")
    local Toolbar = Inventory and Inventory:FindFirstChild("Toolbar")
    local Out = {}
    for _, Slot in (Toolbar and Toolbar:GetChildren() or {}) do
        Out[Slot.Name] = Slot.Value
    end
    return Out
end

function Collection:GetCombatItems()
    local Names = {}
    for _, Item in Collection:GetInventoryItems() do
        local Definition = Items and Items[Item.name]
        if Definition ~= nil and Definition.HasCombat then
            table.insert(Names, Item.name)
        end
    end
    table.sort(Names)
    if #Names == 0 then
        table.insert(Names, "<none>")
    end
    return Names
end

function Collection:GetEquippedSlotValue()
    local Folder = LocalPlayer:FindFirstChild("Items_Config")
    return Folder and Folder:FindFirstChild("Equipped") or nil
end

function Collection:IsWeaponDrawn()
    local Equipped = Collection:GetEquippedSlotValue()
    return Equipped ~= nil and Equipped.Value ~= 0
end

function Collection:PressSlotKey(SlotName)
    local Number = table.find(Collection.SlotNames, SlotName) or tonumber(SlotName)
    if Number == nil then
        return false, "bad slot " .. tostring(SlotName)
    end

    local Equipped = Collection:GetEquippedSlotValue()
    if Equipped ~= nil then
        if Equipped.Value ~= Number then
            local ok = pcall(function() Equipped.Value = Number end)
            return ok, ok and "equipped" or "could not set Items_Config.Equipped"
        end
        return true, "already equipped"
    end

    local ok = pcall(function()
        Event:FireServer("Item_Equip", Number)
    end)
    return ok, ok and "equipped (direct)" or "FireServer failed"
end

function Collection:EquipToolbar(ItemName, Slot)
    Slot = Slot or "One"

    local Identifier = Collection:FindItemId(ItemName)
    if Identifier == nil then
        return false, "not in inventory: " .. tostring(ItemName)
    end

    local Before = Collection:GetToolbarSlots()[Slot]
    local FireOk, FireError = pcall(function()
        Event:FireServer("Toolbar_Equip", Slot, Identifier)
    end)
    if not FireOk then
        return false, tostring(FireError)
    end

    local Deadline = tick() + 2
    repeat
        task.wait(0.1)
    until Collection:GetToolbarSlots()[Slot] ~= Before or tick() > Deadline

    if Collection:GetToolbarSlots()[Slot] ~= Before then
        return true
    end
    return false, "NotApplied"
end

--------------------------- [[ Best Gear ]] ---------------------------

Collection.EquipModes = {
    balanced = {
        ["Additional Damage Factor"] = 1000, ["Additional Damage"] = 10,
        ["Damage Reduction Factor"] = 800, ["Damage Reduction"] = 8,
        ["Max Health Factor"] = 600, ["Max Health"] = 1,
        ["Max Stamina"] = 0.8, ["Movement Speed Factor"] = 600,
        ["Health Regen Speed"] = 4, ["Stamina Regen Speed"] = 3,
        ["Block Points"] = 4, ["Block Regen"] = 4,
    },
    damage = { ["Additional Damage Factor"] = 1000, ["Additional Damage"] = 10 },
    tank = {
        ["Max Health"] = 1, ["Max Health Factor"] = 600,
        ["Damage Reduction Factor"] = 800, ["Damage Reduction"] = 8,
        ["Health Regen Speed"] = 4, ["Block Points"] = 4, ["Block Regen"] = 4,
    },
    stamina = { ["Max Stamina"] = 1, ["Stamina Regen Speed"] = 4 },
    speed = { ["Movement Speed Factor"] = 1000 },
}

function Collection:GetWeaponScore(Name, Mode)
    local Definition = Items and Items[Name]
    local Stats = Definition and Definition.ActiveToolStats
    if type(Stats) ~= "table" then
        return nil
    end

    local Weights = Collection.EquipModes[Mode or "balanced"] or Collection.EquipModes.balanced
    local Score = 0
    for StatName, StatValue in pairs(Stats) do
        if type(StatValue) == "number" then
            Score = Score + StatValue * (Weights[StatName] or 0)
        end
    end
    return Score
end

function Collection:GetBestWeapon(Mode)
    local BestName, BestScore
    for _, Item in Collection:GetInventoryItems() do
        local Definition = Items and Items[Item.name]
        if Definition ~= nil and Definition.HasCombat then
            local Score = Collection:GetWeaponScore(Item.name, Mode) or 0
            if BestScore == nil or Score > BestScore then
                BestName, BestScore = Item.name, Score
            end
        end
    end
    return BestName, BestScore
end

function Collection:ScoreItem(Name, Mode)
    local Definition = Items and Items[Name]
    local Stats = Definition and Definition.Stats
    if type(Stats) ~= "table" then
        return nil
    end

    local Weights = Collection.EquipModes[Mode or "balanced"] or Collection.EquipModes.balanced
    local Score = 0
    for StatName, StatValue in pairs(Stats) do
        if type(StatValue) == "number" then
            Score = Score + StatValue * (Weights[StatName] or 0)
        end
    end
    return Score
end

function Collection:GetRankedItems(Mode)
    local Ranked = {}
    for _, Item in Collection:GetInventoryItems() do
        local Score = Collection:ScoreItem(Item.name, Mode)
        if Score ~= nil then
            table.insert(Ranked, { name = Item.name, id = Item.id, score = Score })
        end
    end
    table.sort(Ranked, function(A, B)
        return A.score > B.score
    end)
    return Ranked
end

function Collection:EquipBest(Mode, Category, DryRun)
    Category = Category or "Stats"
    local Ranked = Collection:GetRankedItems(Mode)

    if #Ranked == 0 then
        return { note = "no owned item has a Stats field", equipped = {}, failed = {}, skipped = {} }
    end

    local Already = Collection:GetEquippedSlots(Category)
    local Taken = {}
    for _, Value in pairs(Already) do
        if Value ~= 0 then
            Taken[Value] = true
        end
    end

    local Report = { equipped = {}, failed = {}, skipped = {} }
    local Index = 1

    for _, Slot in Collection.SlotNames do
        while Index <= #Ranked and Taken[Ranked[Index].id] do
            table.insert(Report.skipped, Ranked[Index].name)
            Index = Index + 1
        end
        if Index > #Ranked then
            break
        end

        local Pick = Ranked[Index]

        if Already[Slot] == Pick.id then
            table.insert(Report.skipped, Pick.name)
        elseif DryRun then
            table.insert(Report.equipped, Pick.name .. " -> " .. Slot)
        else
            local ok, Reason = Collection:EquipAndWait(Pick.id, Slot, Category)
            if ok then
                table.insert(Report.equipped, Pick.name .. " -> " .. Slot)
                Taken[Pick.id] = true
            else
                table.insert(Report.failed, Pick.name .. " -> " .. Slot .. ": " .. tostring(Reason))
            end
        end

        Index = Index + 1
    end

    return Report
end

--------------------------- [[ Dialogue & Hubs ]] ---------------------------

function Collection:FindDialoguePrompt(NpcName)
    if NpcName == nil then return nil end

    local Debree = Workspace:FindFirstChild("Debree")
    local StaticRegions = Debree and Debree:FindFirstChild("Regions")

    for _, Region in (StaticRegions and StaticRegions:GetChildren() or {}) do
        local Stationary = Region:FindFirstChild("StationaryNpcs")
        local Npc = Stationary and Stationary:FindFirstChild(NpcName)
        if Npc then
            for _, Descendant in Npc:GetDescendants() do
                if Descendant:IsA("ProximityPrompt") and Descendant.Enabled then
                    return Descendant
                end
            end
        end
    end
end

function Collection:AllowPrompts()
    local CamFolder = ReplicatedStorage:FindFirstChild("CAM")
    local Layout = CamFolder and CamFolder.Client and CamFolder.Client:FindFirstChild("Components")
    Layout = Layout and Layout:FindFirstChild("Layout")
    local Visibility = Layout and Layout:FindFirstChild("Visibility")
    local Prompts = Visibility and Visibility:FindFirstChild("Prompts")
    if Prompts ~= nil and Prompts.Value == false then
        pcall(function() Prompts.Value = true end)
    end
end

function Collection:TalkTo(NpcName)
    local Prompt = Collection:FindDialoguePrompt(NpcName)
    if Prompt == nil then
        return false, "no dialogue prompt on " .. tostring(NpcName)
    end

    local Part = Prompt.Parent
    if Part and Part:IsA("BasePart") then
        Collection:TeleportTo(Part.Position, Collection.GiverOffset)
        task.wait(0.3)
    end

    Collection:AllowPrompts()

    local ok = Collection:FirePrompt(Prompt)
    return ok and true or false, ok and "talked" or "fire failed"
end

function Collection:GetRegionHubs()
    local Out, Order = {}, {}
    local Debree = Workspace:FindFirstChild("Debree")
    local StaticRegions = Debree and Debree:FindFirstChild("Regions")

    for _, Region in (StaticRegions and StaticRegions:GetChildren() or {}) do
        for _, Child in Region:GetChildren() do
            if string.find(Child.Name, "SpawnCrystal") and Child:IsA("Model") then
                local ok, Pivot = pcall(function() return Child:GetPivot() end)
                if ok then
                    local Label = tostring(Child:GetAttribute("SpawnArea") or Region.Name)
                    if Out[Label] == nil then
                        Out[Label] = Pivot.Position
                        table.insert(Order, Label)
                    end
                end
            end
        end
    end

    table.sort(Order)
    return Out, Order
end

--------------------------- [[ Breathing Trainers ]] ---------------------------

Collection.BreathingTrainers = {
    "Flame Trainer Rengu", "Insect Trainer Shinora", "Serpent Trainer Obari",
    "Sound Trainer Tengai", "Stone Trainer Gyorei", "Thunder Trainer Zentaro",
    "Water Trainer Urokodaki", "Wind Trainer Saneri",
}

Collection.TrainerPositions = {
    ["Flame Trainer Rengu"] = Vector3.new(-967, 1025, 1188),
    ["Serpent Trainer Obari"] = Vector3.new(36, 1307, -1179),
    ["Insect Trainer Shinora"] = Vector3.new(-1798.93994, 350.16803, -189.343994),
    ["Sound Trainer Tengai"] = Vector3.new(464.881012, 1487.79883, -3272.79712),
    ["Stone Trainer Gyorei"] = Vector3.new(2578.58301, 1091.5, -828.401001),
    ["Thunder Trainer Zentaro"] = Vector3.new(1970.1803, 1662.5, -609.810913),
    ["Water Trainer Urokodaki"] = Vector3.new(667.17395, 1021, -228.240005),
    ["Wind Trainer Saneri"] = Vector3.new(-275.575989, 1189.98682, -3436.65308),
}

function Collection:ScanTrainers()
    local Learned = {}
    for _, Name in Collection.BreathingTrainers do
        if Collection.TrainerPositions[Name] == nil then
            local Position = Collection:FindNpcAnywhere(Name)
            if Position ~= nil then
                Collection.TrainerPositions[Name] = Position
                table.insert(Learned, Name)
            end
        end
    end
    return Learned
end

--------------------------- [[ Clan Spin ]] ---------------------------

Signals = ReplicatedStorage
    :WaitForChild("Communication")
    :WaitForChild("ServerAndClient")
    :WaitForChild("Signals")

SpinFunction = Signals:WaitForChild("SignalFunction"):WaitForChild("Function")

ClansModule = nil
do
    local CamFolder = ReplicatedStorage:FindFirstChild("CAM")
    local Node = CamFolder and CamFolder:FindFirstChild("Clans")
    if Node then
        local ok, Module = pcall(require, Node)
        ClansModule = ok and Module or nil
    end
end

Collection.SpinCost = 1
do
    local ok, ClanSpinner = pcall(function()
        return require(ReplicatedStorage.CAM.Global.Spinners.Clan)
    end)
    if ok and type(ClanSpinner) == "table" and type(ClanSpinner.Cost) == "number" then
        Collection.SpinCost = math.max(1, ClanSpinner.Cost)
    end
end

Collection.RarityOrder = { "1 Common", "2 Uncommon", "3 Rare", "5 Legendary", "6 Mythic", "7 Supreme" }

Collection.SpinState = {
    Auto = false,
    MinRarity = 5,
    Status = "off",
    Last = "-",
}

function Collection:GetSpinningFolder()
    local Data = Collection:GetPlayerData()
    return Data and Data:FindFirstChild("Spinning") or nil
end

function Collection:GetSpinsLeft()
    local Spinning = Collection:GetSpinningFolder()
    local Paid = Spinning and Spinning:FindFirstChild("Spins")
    local Free = Spinning and Spinning:FindFirstChild("FreeClanSpins")
    return (Paid and Paid.Value or 0) + (Free and Free.Value or 0)
end

function Collection:GetCurrentClan()
    local Data = Collection:GetPlayerData()
    local Clan = Data and Data:FindFirstChild("Clan")
    return Clan and tostring(Clan.Value) or "?"
end

function Collection:GetClanTier(Name)
    if ClansModule == nil or type(ClansModule.TierOf) ~= "function" then
        return 0, "?"
    end
    local ok, Tier = pcall(ClansModule.TierOf, Name)
    if ok and type(Tier) == "table" then
        return tonumber(Tier.rarity) or 0, tostring(Tier.name)
    end
    return 0, "?"
end

function Collection:SpinOnce()
    local ok, Result = pcall(function()
        return SpinFunction:InvokeServer("ClanSpin")
    end)

    if not ok then
        return false, tostring(Result)
    end

    pcall(function()
        Event:FireServer("ClanSpinComplete")
    end)

    local Name = tostring(Result)
    local Rarity, Label = Collection:GetClanTier(Name)

    if Rarity == 0 then
        Name = Collection:GetCurrentClan()
        Rarity, Label = Collection:GetClanTier(Name)
    end

    return true, Name, Rarity, Label
end

coroutine.wrap(function()
    local Stalls = 0

    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            if Collection.SpinState.Auto then
                local Before = Collection:GetSpinsLeft()

                if Before < Collection.SpinCost then
                    Collection.SpinState.Status = "out of spins"
                    Collection.SpinState.Auto = false
                else
                    local ok, Name, Rarity, Label = Collection:SpinOnce()

                    if not ok then
                        Collection.SpinState.Status = "invoke failed: " .. tostring(Name)
                        Collection.SpinState.Auto = false
                    else
                        Collection.SpinState.Last = Name .. " [" .. tostring(Label) .. "]"
                        Collection.SpinState.Status = string.format("%d left - last %s", Collection:GetSpinsLeft(), Collection.SpinState.Last)

                        if Rarity >= Collection.SpinState.MinRarity then
                            Collection.SpinState.Status = "FOUND " .. Collection.SpinState.Last .. " - stopped"
                            Collection.SpinState.Auto = false
                        elseif Collection:GetSpinsLeft() >= Before then
                            Stalls = Stalls + 1
                            if Stalls >= 3 then
                                Collection.SpinState.Status = "spin count never dropped - stopped"
                                Collection.SpinState.Auto = false
                            end
                        else
                            Stalls = 0
                        end
                    end
                end

                task.wait(0.35)
            else
                task.wait(0.4)
            end
        end)
        if err then
            if Debug then warn("[Auto Spin] Caught Error:", err) end
            task.wait(1)
        end
    end
end)()

--------------------------- [[ Diagnostic ]] ---------------------------

function Collection:RunDiagnostic()
    local Pass, Fail = 0, 0

    local function ReportOk(Name, Detail)
        Pass = Pass + 1
        print(("[ok]   %-30s %s"):format(Name, Detail or ""))
    end

    local function ReportBad(Name, Detail)
        Fail = Fail + 1
        warn(("[FAIL] %-30s %s"):format(Name, Detail or ""))
    end

    local function Check(Name, Fn)
        local Good, Result, Detail = pcall(Fn)
        if not Good then
            ReportBad(Name, "errored: " .. tostring(Result))
        elseif Result then
            ReportOk(Name, Detail)
        else
            ReportBad(Name, Detail)
        end
    end

    print("=========== diagnostic ===========")

    local Data = Collection:GetPlayerData()

    Check("player data", function()
        return Data ~= nil, Data and Data:GetFullName() or "GetData returned nil"
    end)

    Check("combat route", function()
        return true, Collection.CombatRouteName
    end)

    Check("ComboValue", function()
        return Collection.ComboValue ~= nil, Collection.ComboValue and ("= " .. tostring(Collection.ComboValue.Value)) or "missing"
    end)

    Check("preset", function()
        local Name = Collection:GetPresetFromTools()
        local Preset = Name and Combat_presets and Combat_presets.Presets[Name]
        if Preset == nil then
            return false, "unresolved - nothing equipped?"
        end
        return true, ("%s default=%s final=%s"):format(Name, tostring(Preset.default), tostring(Preset.final))
    end)

    Check("Checker.check(combat)", function()
        if Checker == nil then return false, "no Checker" end
        local Good, Result = pcall(Checker.check, LocalPlayer, "combat")
        return Good, Good and ("returns " .. tostring(Result)) or tostring(Result)
    end)

    Check("weapon drawn", function()
        local Slot = Collection:GetEquippedSlotValue()
        if Slot == nil then return false, "Items_Config.Equipped missing" end
        return true, ("slot %d%s"):format(Slot.Value, Slot.Value == 0 and " - NOTHING DRAWN" or "")
    end)

    Check("toolbar", function()
        local ById = {}
        for _, Item in Collection:GetInventoryItems() do
            if Item.id then ById[Item.id] = Item.name end
        end
        local Bits = {}
        for Slot, Identifier in pairs(Collection:GetToolbarSlots()) do
            if Identifier ~= 0 then
                Bits[#Bits + 1] = Slot .. "=" .. (ById[Identifier] or ("id" .. Identifier))
            end
        end
        return #Bits > 0, #Bits > 0 and table.concat(Bits, " ") or "empty - nothing to draw"
    end)

    Check("quests", function()
        local Known = 0
        for _ in pairs((QuestsModule and QuestsModule.Holder) or {}) do Known = Known + 1 end
        return Known > 0, ("%d known, %d held"):format(Known, Collection:GetActiveQuestCount())
    end)

    Check("AddQuest", function()
        local AddQuest = DialogueModule and DialogueModule.Functions and DialogueModule.Functions.AddQuest
        return type(AddQuest) == "function", type(AddQuest) == "function" and "present" or "missing"
    end)

    Check("active tasks", function()
        local Holder = Data and Data:FindFirstChild("Quests")
        Holder = Holder and Holder:FindFirstChild("Holder")
        local Bits = {}
        for _, Quest in (Holder and Holder:GetChildren() or {}) do
            local Tasks = Quest:FindFirstChild("Tasks")
            for _, QuestTask in (Tasks and Tasks:GetChildren() or {}) do
                local Value = QuestTask:FindFirstChild("Value")
                local Maximum = QuestTask:FindFirstChild("Max")
                local Code = QuestTask:FindFirstChild("Code")
                Bits[#Bits + 1] = ("%s %s/%s code=%s"):format(QuestTask.Name,
                    tostring(Value and Value.Value), tostring(Maximum and Maximum.Value),
                    tostring(Code and Code.Value))
            end
        end
        return true, #Bits > 0 and table.concat(Bits, " | ") or "none held"
    end)

    Check("npcs here", function()
        local Total, Shielded = 0, 0
        for _, Active in Collection:GetNpcFolders() do
            for _, Folder in Active:GetChildren() do
                Total = Total + 1
                local Model = Folder:FindFirstChild(Folder.Name)
                if Model and Collection:IsShielded(Model) then Shielded = Shielded + 1 end
            end
        end
        if Total == 0 then return false, "no NPCs loaded anywhere" end
        return Total > 0, ("%d npcs, %d blocking"):format(Total, Shielded)
    end)

    Check("giver lookup", function()
        local Debree = Workspace:FindFirstChild("Debree")
        local StaticRegions = Debree and Debree:FindFirstChild("Regions")
        local Total, Prompts = 0, 0
        for _, Region in (StaticRegions and StaticRegions:GetChildren() or {}) do
            local Stationary = Region:FindFirstChild("StationaryNpcs")
            for _, Npc in (Stationary and Stationary:GetChildren() or {}) do
                Total = Total + 1
                if Npc:FindFirstChildWhichIsA("ProximityPrompt", true) then Prompts = Prompts + 1 end
            end
        end
        return Total > 0, ("%d loaded, %d with Dialogue prompt"):format(Total, Prompts)
    end)

    Check("loot", function()
        local Folder = Workspace:FindFirstChild("LootDrops")
        if Folder == nil then return false, "LootDrops missing" end
        return true, #Folder:GetChildren() .. " drop(s) on the ground"
    end)

    Check("spins", function()
        return true, Collection:GetSpinsLeft() .. " left"
    end)

    print(("=========== %d ok, %d failed ==========="):format(Pass, Fail))
    return Pass, Fail
end

--------------------------- [[ Training ]] ---------------------------

Collection.TrainingFolder = {
    ["Meditation"] = "Meditation",
    ["Pushups"] = "Pushups",
    ["Boulder Split"] = "Boulder Split",
    ["Target Shooting"] = "Aim Training",
    ["Cup Game"] = "Cup Game",
    ["Squat"] = "Squat Rack",
    ["Boulder Push"] = "Boulder Push",
    ["Parkour Dungeon"] = "Parkour Dungeon",
}

function Collection:GetTrainingMarker(Code)
    local ok, GameSettings = pcall(require, ReplicatedStorage.CAM.Global.gameSettings)
    if not ok or type(GameSettings) ~= "table" then
        return nil
    end
    local AllMarkers = GameSettings.TrainingMarkerPositions
    local Set = AllMarkers and (AllMarkers[game.PlaceId] or AllMarkers.Default)
    local Entry = Set and Set[Code]
    return Entry and typeof(Entry.Position) == "Vector3" and Entry.Position or nil
end

function Collection:GetTrainingSpots(Code)
    local Spots = {}
    local Training = Workspace:FindFirstChild("Training")
    local Folder = Training and Collection.TrainingFolder[Code] and Training:FindFirstChild(Collection.TrainingFolder[Code])

    for _, Mat in (Folder and Folder:GetChildren() or {}) do
        if Mat:IsA("Model") and Mat.Name ~= "Sign" then
            local Good, Pivot = pcall(function() return Mat:GetPivot() end)
            if Good then
                table.insert(Spots, { pos = Pivot.Position, model = Mat })
            end
        end
    end

    if #Spots == 0 then
        local Marker = Collection:GetTrainingMarker(Code)
        if Marker then
            table.insert(Spots, { pos = Marker, model = nil })
        end
    end

    return Spots
end

function Collection:SkipTraining()
    return pcall(function()
        Event:FireServer("training_signaler", "Stop", true)
    end)
end

function Collection:GetTaskProgress(Code)
    local Folder = Collection:GetQuestsFolder()
    local Holder = Folder and Folder:FindFirstChild("Holder")
    for _, Quest in (Holder and Holder:GetChildren() or {}) do
        local Tasks = Quest:FindFirstChild("Tasks")
        for _, QuestTask in (Tasks and Tasks:GetChildren() or {}) do
            local TaskCode = QuestTask:FindFirstChild("Code")
            if TaskCode and TaskCode.Value == Code then
                local Value = QuestTask:FindFirstChild("Value")
                local Maximum = QuestTask:FindFirstChild("Max")
                return (Value and Value.Value or 0), (Maximum and Maximum.Value or 0), QuestTask.Name
            end
        end
    end
end

function Collection:RunTrainingTask(Code)
    local Before, Maximum, Label = Collection:GetTaskProgress(Code)
    if Before == nil then
        return false, "not a task on the held quest"
    end
    if Maximum > 0 and Before >= Maximum then
        return true, (Label or Code) .. " already done"
    end

    local Spots = Collection:GetTrainingSpots(Code)
    if #Spots == 0 then
        return false, "no mats or marker for " .. Code
    end

    for _, Spot in Spots do
        Collection:TeleportTo(Spot.pos)
        task.wait(0.6)

        local Prompt
        local Deadline = tick() + 3
        repeat
            if Spot.model then
                Prompt = Spot.model:FindFirstChildWhichIsA("ProximityPrompt", true)
            end
            if Prompt == nil then
                task.wait(0.2)
            end
        until Prompt ~= nil or tick() > Deadline

        if Prompt ~= nil and Prompt.Enabled then
            Collection:FirePrompt(Prompt)
            task.wait(0.8)
            Collection:SkipTraining()
            task.wait(1.2)

            local After = Collection:GetTaskProgress(Code)
            if After ~= nil and After > Before then
                return true, (Label or Code) .. " " .. After .. "/" .. Maximum
            end
        end
    end

    return false, (Label or Code) .. " did not credit"
end

function Collection:GetPendingTrainingCodes()
    local Folder = Collection:GetQuestsFolder()
    local Holder = Folder and Folder:FindFirstChild("Holder")
    local Codes = {}

    for _, Quest in (Holder and Holder:GetChildren() or {}) do
        local Tasks = Quest:FindFirstChild("Tasks")
        for _, QuestTask in (Tasks and Tasks:GetChildren() or {}) do
            local Code = QuestTask:FindFirstChild("Code")
            local Value = QuestTask:FindFirstChild("Value")
            local Maximum = QuestTask:FindFirstChild("Max")
            local Done = Value and Maximum and Maximum.Value > 0 and Value.Value >= Maximum.Value
            if Code and not Done and (Collection.TrainingFolder[Code.Value] or Collection:GetTrainingMarker(Code.Value)) then
                table.insert(Codes, Code.Value)
            end
        end
    end

    return Codes
end

--------------------------- [[ Skills ]] ---------------------------

Collection.SkillController = Collection:TryRequire("CAM", "Client", "Controllers", "Skill_Controller")

Collection.SkillState = { On = false, Last = {} }

function Collection:GetCurrentPower()
    local Data = Collection:GetPlayerData()
    local Powers = Data and Data:FindFirstChild("Powers")
    for _, Key in { "Breathing", "FightingStyle", "DemonArt" } do
        local Value = Powers and Powers:FindFirstChild(Key)
        if Value ~= nil and Value.Value ~= nil and Value.Value ~= "" then
            return Value.Value
        end
    end
end

function Collection:GetSkillNames()
    local Folder = ReplicatedStorage:FindFirstChild("Skills")
    local Power = Collection:GetCurrentPower()
    local Set = Power ~= nil and Folder ~= nil and Folder:FindFirstChild(Power) or nil

    local Names = {}
    for _, Technique in (Set and Set:GetChildren() or {}) do
        table.insert(Names, Technique.Name)
    end
    table.sort(Names)
    return Names
end

-- One entry per skill slot the HUD is showing. The slot's KeyLabel is the key the game
-- expects for it, so pressing that key casts whatever is bound there.
function Collection:GetSkillKeys()
    local Holder = LocalPlayer:FindFirstChild("PlayerGui")
    for _, Name in { "ComponentsHolder", "BottomHolder", "SkillsHolder" } do
        Holder = Holder and Holder:FindFirstChild(Name)
    end

    local Keys = {}
    for _, Slot in (Holder and Holder:GetChildren() or {}) do
        if Slot:IsA("GuiObject") and Slot.Visible and string.find(Slot.Name, "%-Skill$") then
            local Label = Slot:FindFirstChild("KeyLabel", true)
            local Text = Label and string.upper(Label.Text) or ""
            -- F is block, which Auto block owns
            if Text ~= "" and Text ~= "F" then
                local ok, KeyCode = pcall(function() return Enum.KeyCode[Text] end)
                if ok and KeyCode ~= nil then
                    table.insert(Keys, { slot = Slot.Name, key = KeyCode })
                end
            end
        end
    end
    table.sort(Keys, function(A, B) return A.slot < B.slot end)
    return Keys
end

function Collection:PressSkillKey(KeyCode)
    local Input = Services.VirtualInputManager
    Input:SendKeyEvent(true, KeyCode, false, game)
    task.wait(0.15)
    Input:SendKeyEvent(false, KeyCode, false, game)
    Collection.SkillState.Last[KeyCode] = tick()
    return true
end

coroutine.wrap(function()
    local SkillGap = 8

    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            if not Collection.SkillState.On or not Collection.CombatState.Auto or not Collection:IsTargetValid()
                or Collection.BlockState.Holding then
                task.wait(0.5)
            else
                local Cast = false
                for _, Entry in Collection:GetSkillKeys() do
                    if tick() - (Collection.SkillState.Last[Entry.key] or 0) > SkillGap then
                        Collection:PressSkillKey(Entry.key)
                        Cast = true
                        break
                    end
                end
                task.wait(Cast and 0.6 or 1)
            end
        end)
        if err then
            if Debug then warn("[Auto Skill] Caught Error:", err) end
            task.wait(1)
        end
    end
end)()


--------------------------- [[ Skill Tree ]] ---------------------------

SkillTree.Focus = {
    Health   = { "Health Regen Speed", "Max Health", "Max Stamina" },
    Damage   = { "Health Regen Speed", "Additional Damage", "Max Health" },
    Stamina  = { "Health Regen Speed", "Max Stamina", "Stamina Regen Speed" },
    Tank     = { "Health Regen Speed", "Block Regen", "Block Points", "Max Health" },
    Balanced = { "Health Regen Speed", "Max Stamina", "Max Health",
                 "Additional Damage", "Stamina Regen Speed" },
}
SkillTree.Order = { "Balanced", "Health", "Damage", "Stamina", "Tank" }

function SkillTree:GetRemote()
    local Communication = ReplicatedStorage:FindFirstChild("Communication")
    local ServerAndClient = Communication and Communication:FindFirstChild("ServerAndClient")
    local SignalsFolder = ServerAndClient and ServerAndClient:FindFirstChild("Signals")
    local SignalFunction = SignalsFolder and SignalsFolder:FindFirstChild("SignalFunction")
    return SignalFunction and SignalFunction:FindFirstChild("Function")
end

function SkillTree:GetSlot()
    return Collection:GetPlayerData()
end

function SkillTree:GetPoints()
    local Slot = SkillTree:GetSlot()
    local Points = Slot and Slot:FindFirstChild("SkillPoints")
    return Points and Points.Value or 0
end

function SkillTree:GetRank(Name)
    local Slot = SkillTree:GetSlot()
    local List = Slot and Slot:FindFirstChild("SkillTreeUnlockedList")
    local Entry = List and List:FindFirstChild(Name)
    return Entry and Entry.Value or 0
end

function SkillTree:GetConfig()
    local ok, CamFolder = pcall(function() return ReplicatedStorage.CAM end)
    if not ok then return nil end
    local OkConfig, ConfigTable = pcall(function()
        return require(CamFolder.Global.SkillService.SkillTreeholder.SkillTreeConfig)
    end)
    return OkConfig and type(ConfigTable) == "table" and ConfigTable or nil
end

function SkillTree:GetTiers(Name)
    local ok, CamFolder = pcall(function() return ReplicatedStorage.CAM end)
    if not ok then return 0 end
    local OkHolder, Holder = pcall(function()
        return require(CamFolder.Global.SkillService.SkillTreeholder)
    end)
    if not OkHolder or type(Holder) ~= "table" or type(Holder.GetBranches) ~= "function" then
        return 0
    end

    local Good, Branches = pcall(Holder.GetBranches)
    if not Good or type(Branches) ~= "table" then return 0 end

    for _, Branch in Branches do
        local BranchIndex = 1
        while Branch[BranchIndex] ~= nil do
            local Sub = Branch[BranchIndex]
            if Sub.Name == "Stats" then
                local StatIndex = 1
                while Sub[StatIndex] ~= nil do
                    if Sub[StatIndex].Name == Name then
                        local TierCount = 0
                        while Sub[StatIndex][TierCount + 1] ~= nil do
                            TierCount = TierCount + 1
                        end
                        return TierCount
                    end
                    StatIndex = StatIndex + 1
                end
            end
            BranchIndex = BranchIndex + 1
        end
    end
    return 0
end

function SkillTree:GetCost(Name, NextTier)
    local ConfigTable = SkillTree:GetConfig()
    local Rule = ConfigTable and ConfigTable[Name] and ConfigTable[Name].Rule
    if Rule == nil or Rule.Start == nil then
        return 3
    end
    return Rule.Start + (NextTier - 1) * (Rule.IncrementAmount or 0)
end

function SkillTree:Buy(Name)
    local Remote = SkillTree:GetRemote()
    if Remote == nil then
        return false, "SignalFunction missing"
    end
    local ok, Result = pcall(function()
        return Remote:InvokeServer("UnlockSkillTreeNode", Name)
    end)
    if not ok then
        return false, "remote threw"
    end
    return Result == true
end

function SkillTree:Spend(FocusName, Budget)
    local List = SkillTree.Focus[FocusName] or SkillTree.Focus.Balanced
    local Bought, Spent = 0, 0
    local Before = SkillTree:GetPoints()
    Budget = Budget or Before

    local Progressed = true
    while Progressed do
        Progressed = false
        for _, Name in List do
            local Have = SkillTree:GetRank(Name)
            local Cap  = SkillTree:GetTiers(Name)
            if Cap == 0 or Have < Cap then
                local Price = SkillTree:GetCost(Name, Have + 1)
                local Left  = SkillTree:GetPoints()
                if Price <= Left and Spent + Price <= Budget then
                    if SkillTree:Buy(Name) then
                        Bought = Bought + 1
                        Spent  = Spent + Price
                        Progressed = true
                        task.wait(0.35)
                    end
                end
            end
        end
        task.wait()
    end

    return Bought, Spent, ("%s: %d node%s, %d sp (%d left)"):format(
        FocusName, Bought, Bought == 1 and "" or "s", Spent, SkillTree:GetPoints())
end

function SkillTree:TrySkills()
    local ok, CamFolder = pcall(function() return ReplicatedStorage.CAM end)
    if not ok then return 0, "no CAM" end
    local OkHolder, Holder = pcall(function()
        return require(CamFolder.Global.SkillService.SkillTreeholder)
    end)
    if not OkHolder or type(Holder) ~= "table" then return 0, "no holder" end

    local Good, Branches = pcall(Holder.GetBranches)
    if not Good or type(Branches) ~= "table" then return 0, "no branches" end

    local Got = 0
    for _, Branch in Branches do
        if Branch.Name ~= "Character" then
            local Index = 1
            while Branch[Index] ~= nil do
                if SkillTree:GetPoints() >= 3 and SkillTree:Buy(Branch[Index].Name) then
                    Got = Got + 1
                    task.wait(0.35)
                end
                Index = Index + 1
            end
        end
    end
    return Got, Got > 0 and ("unlocked " .. Got) or "none available (mastery gated)"
end

--------------------------- [[ Window ]] ---------------------------

Collection.CachedLists = {
    Regions = Collection:GetRegionNames(),
    Npcs    = Collection:GetNpcNames(),
    Quests  = Collection:GetQuestKeys(),
    Skills  = Collection:GetSkillNames(),
}
Collection.CachedLists.Combat = Collection:GetCombatItems()
Collection:RaiseIdentity()

Window = Fluent:CreateWindow({
    Title = "Project Slayer 2",
    SubTitle = "by vaderhug",
    TabWidth = 150,
    Size = UDim2.fromOffset(560, 440),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl,
})

--------------------------- [[ Dungeon Entry ]] ---------------------------

Dungeon.Quest = "Ill find the forge(Lv 65)"
Dungeon.Portal = Vector3.new(-1594, 1003, 1145)
Dungeon.Pad = "OuwigaharaPromptPad"
Dungeon.Auto = false
Dungeon.Status = "idle"
Dungeon.HubFile = "hub_dungeon_v2_VaderUI.lua"
Dungeon.MainFile = "Main_v2_VaderUI.lua"

function Dungeon:QueueRouter()
    if _queue_on_teleport == nil then
        return "no queue_on_teleport"
    end

    if _clear_teleport_queue ~= nil then
        pcall(_clear_teleport_queue)
    end

    local Chunk = ("task.wait(8) if game.PlaceId == %d then loadstring(readfile(%q))() else loadstring(readfile(%q))() end")
        :format(75556147183481, Dungeon.HubFile, Dungeon.MainFile)
    local ok = pcall(_queue_on_teleport, Chunk)
    return ok and "armed" or "refused by the executor"
end

function Dungeon:GetQuestState()
    -- existence test only (old code tested the function field, never called it)
    local Slot = Collection["GetActiveSlot"] and Collection:GetPlayerData()
    local Quests = Slot and Slot:FindFirstChild("Quests")
    if Quests == nil then
        return "unknown"
    end

    for _, FolderName in { "Completed", "Holder" } do
        local Folder = Quests:FindFirstChild(FolderName)
        for _, Entry in (Folder and Folder:GetChildren() or {}) do
            if Entry.Name == Dungeon.Quest then
                return FolderName == "Completed" and "completed" or "held"
            end
        end
    end
    return "none"
end

function Dungeon:GetPortalPrompt()
    local Map = Workspace:FindFirstChild("Map")
    for _, Name in { Dungeon.Pad, "OuwigaharaPortal" } do
        local Node = Map and Map:FindFirstChild(Name)
        local Prompt = Node and Node:FindFirstChildWhichIsA("ProximityPrompt", true)
        if Prompt ~= nil then
            return Prompt
        end
    end

    for _, Descendant in Workspace:GetDescendants() do
        if Descendant:IsA("ProximityPrompt") and Descendant.Name == "Ouwigahara"
            and Descendant.ActionText == "Enter" then
            return Descendant
        end
    end
end

function Dungeon:Enter()
    if game.PlaceId == 75556147183481 then
        return true, "already in Ouwigahara"
    end

    local State = Dungeon:GetQuestState()
    if State == "none" then
        return false, "forge quest not done - talk to Blacksmith Togane"
    end

    local RootPart = Collection:GetRoot()
    if RootPart == nil then
        return false, "no character"
    end

    Collection:TeleportTo(Dungeon.Portal)
    RootPart = Collection:GetRoot() or RootPart
    Collection:StreamAround(Dungeon.Portal, 5)

    local Prompt
    local Deadline = tick() + 8
    repeat
        Prompt = Dungeon:GetPortalPrompt()
        if Prompt == nil then
            task.wait(0.3)
        end
    until Prompt ~= nil or tick() > Deadline

    if Prompt == nil then
        return false, "portal prompt never streamed in"
    end
    if not Prompt.Enabled then
        return false, "portal disabled - forge quest not completed?"
    end

    Dungeon:QueueRouter()

    if _fireproximityprompt then
        pcall(_fireproximityprompt, Prompt)
    else
        pcall(function()
            local Hold = Prompt.HoldDuration
            Prompt.HoldDuration = 0
            Prompt:InputHoldBegin()
            Prompt:InputHoldEnd()
            Prompt.HoldDuration = Hold
        end)
    end

    return true, "portal fired"
end

coroutine.wrap(function()
    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            if Dungeon.Auto and game.PlaceId ~= 75556147183481 then
                local ok, Detail = Dungeon:Enter()
                Dungeon.Status = tostring(Detail)
                task.wait(ok and 12 or 6)
            else
                task.wait(2)
            end
        end)
        if err then
            if Debug then warn("[Dungeon Entry] Caught Error:", err) end
            task.wait(1)
        end
    end
end)()

--------------------------- [[ Boss Farm ]] ---------------------------

Boss.List = {
    { weapon = "Cutlass",       boss = "Zuko",   level = 10,  drop = 20, respawn = 135, spot = Vector3.new(-296.7, 1224.2, -1022.2) },
    { weapon = "Sickles",       boss = "Hoyuzo", level = 50,  drop = 15, respawn = 180, spot = Vector3.new(746.9, 1001, -1413) },
    { weapon = "Bladed Wagasa", boss = "Fujiko", level = 50,  drop = 5,  respawn = 180, spot = Vector3.new(-2459.5, 37.9, 1119) },
    { weapon = "Blood Sickles", boss = "Gyutai", level = 125, drop = 7,  respawn = 300, spot = Vector3.new(-266.1, 1043.2, -1139.7) },
    { weapon = "War Fans",      boss = "Domae",  level = 125, drop = 7,  respawn = 300, spot = Vector3.new(-296.5, 1350.5, -3451.3) },
    { weapon = "Flame Katana",  boss = "Rengu",  level = 125, drop = 5,  respawn = 300, spot = Vector3.new(-712.9, 965, 883.8) },
    { weapon = "Wind Katana",    boss = "Saneri",  level = 125, respawn = 300, spot = Vector3.new(-379.1, 1093.5, -422.4) },
    { weapon = "Water Katana",   boss = "Giyen",   level = 125, respawn = 300, spot = Vector3.new(388.9, 1018, -85.1) },
    { weapon = "Thunder Katana", boss = "Zentaro", level = 125, respawn = 300, spot = Vector3.new(1332.1, 821.5, -1017.6) },
    { weapon = "Sound Katanas",  boss = "Tengai",  level = 125, respawn = 300, spot = Vector3.new(-133.5, 1349, -2631.3) },
    { weapon = "Serpent Katana", boss = "Obari",   level = 125, respawn = 300, spot = Vector3.new(770.5, 1121, -1047) },
    { weapon = "Claws",          boss = "Kaiden",  level = 50,  respawn = 165, spot = Vector3.new(585.7, 1146.5, -1314.9) },
}
Boss.On = false
Boss.QuestOn = false
Boss.Picks = {}
Boss.KeepFarming = false
Boss.IgnoreRace = false
Boss.Active = nil
Boss.Status = "off"

function Boss:GetLabel(Entry)
    return ("%s - %s (Lv %d+, %s%%)"):format(Entry.weapon, Entry.boss, Entry.level, tostring(Entry.drop or "?"))
end

function Boss:IsOwned(Weapon)
    local Slot = Collection:GetPlayerData()
    local Inventory = Slot and Slot:FindFirstChild("Inventory")
    Inventory = Inventory and Inventory:FindFirstChild("Inventory")
    return Inventory ~= nil and Inventory:FindFirstChild(Weapon) ~= nil
end

function Boss:GetRaceBlock(Weapon)
    local Definition = Items and Items[Weapon]
    local Requirements = Definition and Definition.EquipRequirements
    local Races = Requirements and Requirements.Race
    if type(Races) ~= "table" then
        return nil
    end
    local Slot = Collection:GetPlayerData()
    local Race = Slot and Slot:FindFirstChild("Race")
    Race = Race and tostring(Race.Value) or "?"
    for _, Allowed in Races do
        if Allowed == Race then
            return nil
        end
    end
    return ("%s is %s only (you are %s)"):format(Weapon, table.concat(Races, "/"), Race)
end

function Boss:GetBlockReason(Entry)
    if Collection:GetPlayerLevel() < Entry.level then
        return ("Lv %d needed for %s"):format(Entry.level, Entry.boss)
    end
    if not Boss.IgnoreRace then
        local Why = Boss:GetRaceBlock(Entry.weapon)
        if Why then
            return Why
        end
    end
    if not Boss.KeepFarming and Boss:IsOwned(Entry.weapon) then
        return Entry.weapon .. " already owned"
    end
    return nil
end

-- BossHunt quests are named "Eliminate X"; their task Code is the boss folder's BossInfo NpcCode
Boss.QuestEntries = {}

function Boss:GetQuestBosses()
    local Folder = Collection:GetQuestsFolder()
    local Holder = Folder and Folder:FindFirstChild("Holder")
    local Codes, Found = {}, {}

    for _, Quest in (Holder and Holder:GetChildren() or {}) do
        local Tasks = string.find(Quest.Name, "^Eliminate ") and Quest:FindFirstChild("Tasks")
        for _, QuestTask in (Tasks and Tasks:GetChildren() or {}) do
            local Code    = QuestTask:FindFirstChild("Code")
            local Value   = QuestTask:FindFirstChild("Value")
            local Maximum = QuestTask:FindFirstChild("Max")
            local Done    = Value and Maximum and Maximum.Value > 0 and Value.Value >= Maximum.Value
            if Code ~= nil and not Done then
                Codes[Code.Value] = true
            end
        end
    end

    if next(Codes) == nil then
        return Found
    end

    for _, Active in Collection:GetNpcFolders() do
        for _, NpcFolder in Active:GetChildren() do
            local Info = NpcFolder:FindFirstChild("BossInfo")
            if Info ~= nil and Codes[Info:GetAttribute("NpcCode")] then
                local Entry = Boss.QuestEntries[NpcFolder.Name]
                if Entry == nil then
                    for _, Known in Boss.List do
                        if Known.boss == NpcFolder.Name then
                            Entry = Known
                        end
                    end
                    Entry = Entry or {
                        weapon = "quest", boss = NpcFolder.Name, level = 0,
                        respawn = Info:GetAttribute("SpawnTime") or 300,
                        spot = Info:GetAttribute("Center"),
                    }
                    Boss.QuestEntries[NpcFolder.Name] = Entry
                end
                Found[Entry] = true
            end
        end
    end

    return Found
end

function Boss:GetEligible()
    local List = {}
    local Quest = Boss.QuestOn and Boss:GetQuestBosses() or {}
    for Entry in pairs(Quest) do
        table.insert(List, Entry)
    end
    table.sort(List, function(A, B) return A.boss < B.boss end)
    for _, Entry in Boss.List do
        if not Quest[Entry] and Boss.On and Boss.Picks[Entry.weapon] and Boss:GetBlockReason(Entry) == nil then
            table.insert(List, Entry)
        end
    end
    return List
end

function Boss:FindAlive(Name)
    for _, Active in Collection:GetNpcFolders() do
        local Folder = Active:FindFirstChild(Name)
        local Model = Folder and Folder:FindFirstChild(Name)
        local NpcHumanoid = Model and Model:FindFirstChildOfClass("Humanoid")
        if NpcHumanoid ~= nil and NpcHumanoid.Health > 0 then
            return Model
        end
    end
    return nil
end

function Boss:Release()
    if Boss.Active ~= nil then
        Boss.Active = nil
        Collection.PositionState.On, Collection.CombatState.Auto = false, false
        Collection.EquipState.Auto = Collection.AutoAll
        Collection.PositionState.Targets = {}
        Collection.CurrentTarget, Collection.CurrentTargetRoot = nil, nil
    end
end

function Boss:GetReport()
    local Lines = {}
    for _, Entry in Boss.List do
        local Why = Boss:GetBlockReason(Entry)
        table.insert(Lines, ("%s %s: %s"):format(
            Boss.Picks[Entry.weapon] and "[x]" or "[ ]",
            Entry.weapon, Why or "ready"))
    end
    return table.concat(Lines, "\n")
end

coroutine.wrap(function()
    local WaitingSince, WaitingFor = 0, nil
    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            local On = Boss.On or Boss.QuestOn
            if not On or game.PlaceId ~= 136406881576517
                or (Schematics ~= nil and Schematics.Active) then
                Boss:Release()
                Boss.Status = On and "only runs in Ouwland" or "off"
                task.wait(1)
                return
            end

            local List = Boss:GetEligible()
            if #List == 0 then
                Boss:Release()
                Boss.Status = Boss.On and "nothing eligible - pick a weapon, or check the list below"
                    or "no Eliminate quest held"
                task.wait(3)
                return
            end

            local Entry = List[1]
            for _, Candidate in List do
                if Boss:FindAlive(Candidate.boss) then
                    Entry = Candidate
                    break
                end
            end

            if WaitingFor ~= Entry then
                WaitingFor, WaitingSince = Entry, tick()
            end

            if Boss.Active ~= Entry then
                Collection.CurrentTarget, Collection.CurrentTargetRoot = nil, nil
            end
            Boss.Active = Entry
            Collection.QuestFarm = false
            Collection.PositionState.Targets = { [Entry.boss] = true }
            Collection.PositionState.On, Collection.CombatState.Auto, Collection.LootState.On = true, true, true
            -- nothing else draws a weapon while Auto Farm is off or paused
            Collection.EquipState.Auto = true

            if Boss:FindAlive(Entry.boss) == nil then
                local RootPart = Collection:GetRoot()
                if RootPart ~= nil and Entry.spot ~= nil and (RootPart.Position - Entry.spot).Magnitude > 60 then
                    Collection:TeleportTo(Entry.spot)
                end
                Boss.Status = ("waiting for %s to spawn (%s, %s%% drop)"):format(
                    Entry.boss, Entry.weapon, tostring(Entry.drop or "?"))

                -- stuck on a dead spawn: rotate it to the back of the list
                if #List > 1 and table.find(Boss.List, Entry) and tick() - WaitingSince > Entry.respawn + 45 then
                    table.insert(Boss.List,
                        table.remove(Boss.List, table.find(Boss.List, Entry)))
                    WaitingFor = nil
                end
                task.wait(1)
            else
                Boss.Status = ("fighting %s for %s"):format(Entry.boss, Boss.Picks[Entry.weapon] and Entry.weapon or "quest")
                WaitingSince = tick()
                task.wait(1)
                if Boss:FindAlive(Entry.boss) == nil then
                    task.wait(4)
                    if Boss:IsOwned(Entry.weapon) then
                        Fluent:Notify({ Title = "Boss", Content = Entry.weapon .. " obtained", Duration = 8 })
                    end
                end
            end
        end)
        if err then
            if Debug then warn("[Boss Farm] Caught Error:", err) end
            task.wait(1)
        end
    end
    Boss:Release()
end)()

--------------------------- [[ Schematics ]] ---------------------------

Schematics.On = false
Schematics.Active = false
Schematics.Status = "off"
Schematics.Done = {}
Schematics.Results = {}

function Schematics:GetTargets()
    local Map = Workspace:FindFirstChild("Map")
    local Puzzles = Map and Map:FindFirstChild("Puzzles")
    local List = {}
    for _, Model in (Puzzles and Puzzles:GetChildren() or {}) do
        if Model:IsA("Model") and not Schematics.Done[Model] then
            local Anchor = Model
            local Wanted = string.lower(Model.Name)
            for _, Child in Model:GetChildren() do
                if Child:IsA("Model") and string.lower(Child.Name) == Wanted then
                    Anchor = Child
                    break
                end
            end
            local ok, Pivot = pcall(function() return Anchor:GetPivot().Position end)
            if ok and Pivot.Magnitude > 1 then
                table.insert(List, { model = Model, position = Pivot })
            end
        end
    end
    local RootPart = Collection:GetRoot()
    if RootPart ~= nil then
        table.sort(List, function(A, B)
            return (A.position - RootPart.Position).Magnitude < (B.position - RootPart.Position).Magnitude
        end)
    end
    return List
end

function Schematics:GetPrompts(Model)
    local Found = {}
    for _, Descendant in Model:GetDescendants() do
        if Descendant:IsA("ProximityPrompt") and Descendant.Enabled then
            table.insert(Found, Descendant)
        end
    end
    return Found
end

function Schematics:Visit(Entry)
    -- prompt already visible: go straight to it. Otherwise teleport once so the model
    -- streams in, look once more, and move on if there is still nothing to press
    local Prompts = Schematics:GetPrompts(Entry.model)
    if #Prompts == 0 then
        Collection:TeleportTo(Entry.position)
        Collection:StreamAround(Entry.position, 5)
        task.wait(0.5)
        Prompts = Schematics:GetPrompts(Entry.model)
    end

    local Fired = {}
    for _, Prompt in Prompts do
        local Holder = Prompt.Parent
        local Spot = Holder and ((Holder:IsA("BasePart") and Holder.Position)
            or (Holder:IsA("Attachment") and Holder.WorldPosition))
        if Spot then
            Collection:TeleportTo(Spot)
            task.wait(0.3)
        end
        if Collection:FirePrompt(Prompt) then
            table.insert(Fired, ("%s %s"):format(Prompt.ActionText, Prompt.ObjectText))
        end
        task.wait(0.5)
    end
    return Fired
end

coroutine.wrap(function()
    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            if not Schematics.On or game.PlaceId ~= 136406881576517 then
                Schematics.Active = false
                if Schematics.On then
                    Schematics.Status = "only runs in Ouwland"
                end
                task.wait(1)
                return
            end

            local List = Schematics:GetTargets()
            if #List == 0 then
                Schematics.Active = false
                Schematics.On = false
                Schematics.Status = "done"
                if Collection.UIHandles and Collection.UIHandles.Schematics then
                    pcall(function() Collection.UIHandles.Schematics:SetValue(false) end)
                end
                Fluent:Notify({ Title = "Schematics", Content = "every puzzle model visited", Duration = 6 })
                return
            end

            Schematics.Active = true
            Collection.QuestFarm = false
            Collection.PositionState.On, Collection.CombatState.Auto = false, false
            Collection.CurrentTarget, Collection.CurrentTargetRoot = nil, nil

            local Entry = List[1]
            Schematics.Status = ("visiting %s (%d left)"):format(Entry.model.Name, #List)
            local ok, Fired = pcall(Schematics.Visit, Schematics, Entry)
            Schematics.Done[Entry.model] = true
            table.insert(Schematics.Results, ("%s: %s"):format(Entry.model.Name,
                not ok and ("error " .. tostring(Fired))
                or #Fired > 0 and table.concat(Fired, ", ")
                or "no prompt"))
            task.wait(0.5)
        end)
        if err then
            if Debug then warn("[Schematics] Caught Error:", err) end
            task.wait(1)
        end
    end
    Schematics.Active = false
end)()


--------------------------- [[ Tabs ]] ---------------------------

Collection.Tabs = {
    Farm     = Window:AddTab({ Title = "Farming",  Icon = "swords" }),
    Loadout  = Window:AddTab({ Title = "Loadout",  Icon = "crosshair" }),
    Training = Window:AddTab({ Title = "Training", Icon = "wind" }),
    Travel   = Window:AddTab({ Title = "Travel",   Icon = "map" }),
    Bosses   = Window:AddTab({ Title = "Bosses",   Icon = "skull" }),
    Extras   = Window:AddTab({ Title = "Extras",   Icon = "dices" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
}

-- a loop body started further down can leave this thread at game identity, and Fluent
-- then fails to build the next control; raise it again on every tab lookup
Tabs = setmetatable({}, { __index = function(_, Key)
    Collection:RaiseIdentity()
    return Collection.Tabs[Key]
end })

Collection.UIHandles = {}

--------------------------- [[ Farm Status ]] ---------------------------

Collection.UIHandles.Status = Tabs.Farm:AddParagraph({
    Title = "Status",
    Content = "off",
})

coroutine.wrap(function()
    local Shown
    while true do
        task.wait(0.5)
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            if Collection.AutoAllStatus ~= Shown then
                Shown = Collection.AutoAllStatus
                pcall(function() Collection.UIHandles.Status:SetDesc(tostring(Shown)) end)
            end
        end)
        if err then
            if Debug then warn("[Status] Caught Error:", err) end
            task.wait(1)
        end
    end
end)()

Collection.UIHandles.AutoAll = Tabs.Farm:AddToggle("AutoAll", {
    Title = "Enabled",
    Description = "Quests, travels and fights on its own",
    Default = false,
})

Collection.UIHandles.AutoAll:OnChanged(function(Value)
    Collection.AutoAll = Value
    if Value then
        -- drop a held quest only when it is not the one Auto Farm would assign next;
        -- a held quest that already matches is kept and carried on with
        task.spawn(function()
            local Wanted = Collection:GetWantedQuest()
            if Wanted == nil then
                return
            end
            -- a finished quest is handed in, never dropped: dropping one threw away a boss kill
            if Collection:IsAllTasksComplete() then
                return
            end
            -- The level rule can name a quest the game will not offer yet, and the farm then
            -- re-takes the one just dropped. A held quest from the Smart list is carried on with.
            local Held = Collection:GetActiveQuestKey()
            if Collection.AutoPickQuest and Held ~= nil then
                if table.find(Collection.QuestPriority, Held) then
                    return
                end
                for _, Entry in Collection:GetQuestPlan() do
                    if Entry.key == Held then
                        return
                    end
                end
            end
            local Dropped = Collection:AbandonHeldQuests(Wanted)
            if Dropped > 0 then
                Collection.AutoAllStatus = ("dropped %d held quest%s that did not match %s")
                    :format(Dropped, Dropped == 1 and "" or "s", Wanted)
            end
        end)
    end
    if not Value then
        Collection.CombatState.Auto, Collection.PositionState.On, Collection.LootState.On, Collection.QuestFarm = false, false, false, false
        Collection.EquipState.Auto = false
        Collection.CurrentTarget, Collection.CurrentTargetRoot = nil, nil
    end
end)

--------------------------- [[ Skill Points ]] ---------------------------

Tabs.Training:AddDropdown("SkillFocus", {
    Title = "Skill Focus",
    Description = "Which stats to sink skill points into, in priority order",
    Values = SkillTree.Order,
    Multi = false,
    Default = 1,
}):OnChanged(function(Value)
    SkillTree.Pick = tostring(Value)
end)

Collection.SkillStatus = Tabs.Training:AddParagraph({
    Title = "Skill Points",
    Content = "press Refresh",
})

function Collection:GetSkillSummary()
    local Focus = SkillTree.Focus[SkillTree.Pick or "Balanced"] or SkillTree.Focus.Balanced
    local Lines = { ("Available: %d"):format(SkillTree:GetPoints()) }
    for _, Name in Focus do
        local Have, Cap = SkillTree:GetRank(Name), SkillTree:GetTiers(Name)
        local NextCost = SkillTree:GetCost(Name, Have + 1)
        if Cap > 0 and Have >= Cap then
            table.insert(Lines, ("%s  MAX (%d/%d)"):format(Name, Have, Cap))
        else
            table.insert(Lines, ("%s  %d/%d  next %dsp"):format(Name, Have, Cap, NextCost))
        end
    end
    return table.concat(Lines, "\n")
end

Tabs.Training:AddButton({
    Title = "Refresh Skill Points",
    Description = "Show what the focus would buy and what it costs",
    Callback = function()
        Collection:RaiseIdentity()
        local ok, Text = pcall(Collection.GetSkillSummary, Collection)
        Collection.SkillStatus:SetDesc(ok and Text or ("read failed: " .. tostring(Text)))
    end,
})

Tabs.Training:AddToggle("AutoSkillPoints", {
    Title = "Auto Spend Skill Points",
    Description = "Buys down the focus list whenever you have points. Not reversible",
    Default = false,
}):OnChanged(function(Value)
    SkillTree.Auto = Value
end)

coroutine.wrap(function()
    local LastPoints
    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            local Points = SkillTree.Auto and SkillTree:GetPoints() or 0
            if not SkillTree.Auto then
                LastPoints = nil
            elseif Points > 0 and Points ~= LastPoints then
                -- only retry once the balance moves, so leftover points we cannot spend do not loop
                local _, _, Detail = SkillTree:Spend(SkillTree.Pick or "Balanced", nil)
                local _, Why = SkillTree:TrySkills()
                LastPoints = SkillTree:GetPoints()
                Collection:RaiseIdentity()
                Collection.SkillStatus:SetDesc(("%s\nskills: %s\n\n%s"):format(
                    tostring(Detail), tostring(Why), Collection:GetSkillSummary()))
                print("[hub] skilltree:", tostring(Detail), "| skills:", tostring(Why))
            end
            task.wait(3)
        end)
        if err then
            if Debug then warn("[Skill Points] Caught Error:", err) end
            task.wait(1)
        end
    end
end)()

--------------------------- [[ Breathing ]] ---------------------------

-- The "!!" features ask before they switch on. Confirmed once per session; restoring saved
-- settings and autostart stay silent (Collection.RiskQuiet).
Collection.RiskOk = {}

function Collection:WarnRisky(Id, Name, Value, Apply)
    if not Value or Collection.RiskOk[Id] or Collection.RiskQuiet then
        Apply(Value)
        return
    end

    Apply(false)
    Collection:RaiseIdentity()
    Window:Dialog({
        Title = "Warning",
        Content = Name .. " may get you banned. Turn it on anyway?",
        Buttons = {
            {
                Title = "Turn on",
                Callback = function()
                    Collection.RiskOk[Id] = true
                    Apply(true)
                end,
            },
            {
                Title = "Cancel",
                Callback = function()
                    Collection:RaiseIdentity()
                    pcall(function() Fluent.Options[Id]:SetValue(false) end)
                end,
            },
        },
    })
end

Tabs.Training:AddToggle("AutoBreathing", {
    Title = "!! Auto Learn Breathing",
    Description = "!! May get you banned. Accepts the training quest once you meet level, Wen and items, then clears its minigames",
    Default = false,
}):OnChanged(function(Value)
    Collection:WarnRisky("AutoBreathing", "Auto Learn Breathing", Value, function(On)
        Collection.AutoBreathing = On
        Collection.AutoTraining  = On
    end)
end)

Tabs.Training:AddDropdown("BreathingStyle", {
    Title = "Style",
    Description = "Which style to pursue. Cheapest picks whatever you can afford first",
    Values = Collection:GetBreathingLabels(),
    Multi = false,
    Default = 1,
}):OnChanged(function(Value)
    Collection.BreathingStyle = tostring(Value):match("^(%S+)") or "Cheapest"
    if Collection.BreathingStyle ~= "Cheapest" then
    end
end)

--------------------------- [[ Loadout ]] ---------------------------

Collection.TargetDropdown = Tabs.Loadout:AddDropdown("Target", {
    Title = "Targets",
    Description = "Pick any number. None = nearest of anything. Ignored while Auto Farm Quest is on.",
    Values = Collection.CachedLists.Npcs,
    Multi = true,
    Default = {},
})

Collection.TargetDropdown:OnChanged(function(Value)
    local Picked = {}
    if type(Value) == "table" then
        for Name, On in pairs(Value) do
            if On then
                Picked[Name] = true
            end
        end
    end
    Collection.PositionState.Targets = Picked
    Collection.CurrentTarget, Collection.CurrentTargetRoot = nil, nil
end)

if table.find(Collection.CachedLists.Npcs, "Bandit") then
    Collection.TargetDropdown:SetValue({ ["Bandit"] = true })
end

Tabs.Loadout:AddDropdown("BehindStance", {
    Title = "Stance Mode",
    Description = "Above and Underground sit on the target\'s Y axis - the one side they cannot turn to face",
    Values = { "Behind", "Above", "Underground" },
    Multi = false,
    Default = 1,
}):OnChanged(function(Value)
    Collection.PositionState.Stance = Value
end)

for _, Spec in {
    { "ComboBackoff", "Back off after finisher", "Step back and hold swings for 1.5s once the combo finisher lands" },
    { "AvoidShield",  "Wait out blocks",         "Stand off and hold swings while the target is blocking" },
    { "RagdollWait",  "Wait while ragdolled",    "Stand off and hold swings until you are back on your feet" },
    { "AutoBlock",    "Auto block (self-learning)", "Holds block when an NPC following you starts an attack, until it ends. Learns which moves actually hit and saves that to vaderhug_block_learned_v2.json" },
} do
    Tabs.Loadout:AddToggle(Spec[1], { Title = Spec[2], Description = Spec[3], Default = Collection.CombatState[Spec[1]] })
        :OnChanged(function(Value)
            Collection.CombatState[Spec[1]] = Value
        end)
end

Tabs.Loadout:AddToggle("AutoSkillsOn", {
    Title = "Auto Skills",
    Description = "Presses the key of every skill on your skill bar while fighting (block's F is left to Auto block)",
    Default = false,
}):OnChanged(function(Value)
    Collection.SkillState.On = Value
end)

--------------------------- [[ Quest Selection ]] ---------------------------

Collection.SelectedQuest = Collection.QuestByLabel[Collection.CachedLists.Quests[1]]

Collection.UIHandles.Quest = Tabs.Farm:AddDropdown("QuestPick", {
    Title = "Quest Selection",
    Description = "Smart works down the list by level, or pin one of the "
        .. #Collection.CachedLists.Quests .. " below",
    Values = (function()
        local Values = { "Smart" }
        for _, Label in Collection.CachedLists.Quests do
            table.insert(Values, Label)
        end
        return Values
    end)(),
    Multi = false,
    Default = 1,
})

Collection.UIHandles.Quest:OnChanged(function(Value)
    if Value == "Smart" then
        Collection.AutoPickQuest = true
    else
        Collection.AutoPickQuest = false
        Collection.SelectedQuest = Collection.QuestByLabel[Value] or Collection.SelectedQuest
    end
end)

--------------------------- [[ Auto Quest ]] ---------------------------

Collection.AutoQuest = false

coroutine.wrap(function()
    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            if Collection.AutoQuest and Collection.SelectedQuest ~= nil then
                local Active = Collection:GetActiveQuestCount()
                local MaxQuests = (QuestsModule and QuestsModule.MaxQuestsPerPlayer) or 1

                if Active >= MaxQuests then
                    task.wait(1)
                else
                    local Left = Collection:GetQuestCooldownLeft()
                    if Left > 0 then
                        task.wait(math.min(Left, 5))
                    else
                        local Position = Collection:FindGiver(Collection:GetQuestGiverName(Collection.SelectedQuest))
                        if Position ~= nil then
                            Collection:TeleportTo(Position, Collection.GiverOffset)
                            task.wait(0.4)
                        end

                        local Before = Collection:GetActiveQuestCount()
                        local ok, Reason = Collection:AcceptQuest(Collection.SelectedQuest)

                        if not ok then
                            Collection:RaiseIdentity()
                            task.wait(3)
                        else
                            local Deadline = tick() + 2
                            repeat
                                task.wait(0.1)
                            until Collection:GetActiveQuestCount() > Before or tick() > Deadline

                            Collection:RaiseIdentity()

                            if Collection:GetActiveQuestCount() > Before then
                                task.wait(1)
                            else
                                task.wait(5)
                            end
                        end
                    end
                end
            else
                task.wait(0.5)
            end
        end)
        if err then
            if Debug then warn("[Auto Quest] Caught Error:", err) end
            task.wait(1)
        end
    end
end)()

--------------------------- [[ Auto All ]] ---------------------------

coroutine.wrap(function()
    local LastTravel = 0
    local EquippedOnce = false

    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            if not Collection.AutoAll or Boss.Active ~= nil or Schematics.Active then
                Collection.Shrine.WaitQuest = nil
                task.wait(0.5)
            else
                Collection.LootState.On = true
                Collection.QuestFarm = true
                Collection.EquipState.Auto = true

                if Collection.EquipState.Accessories ~= false and not EquippedOnce then
                    EquippedOnce = true
                    pcall(Collection.EquipBest, Collection, "balanced", "Stats", false)
                    Collection:RaiseIdentity()
                end

                if not Collection:IsWeaponDrawn() then
                    Collection:RaiseIdentity()

                    local Slot = "One"
                    local Slots = Collection:GetToolbarSlots()
                    local Want = Collection.EquipState.Item
                    if Collection.EquipState.UseBest then
                        Want = Collection:GetBestWeapon("balanced") or Want
                    end

                    if Want ~= nil and Want ~= "<none>"
                        and (Slots[Slot] or 0) == 0 then
                        local OkEquip, WhyEquip = pcall(Collection.EquipToolbar, Collection, Want, Slot)
                        if not OkEquip then
                            Collection.AutoAllStatus = "toolbar equip errored: " .. tostring(WhyEquip)
                        end
                    end

                    local OkDraw, WhyDraw = pcall(Collection.PressSlotKey, Collection, Slot)
                    if not OkDraw then
                        Collection.AutoAllStatus = "draw errored: " .. tostring(WhyDraw)
                        warn("[hub] draw errored: " .. tostring(WhyDraw))
                    elseif not Collection:IsWeaponDrawn() then
                        Collection.AutoAllStatus = "draw did not stick (slot " .. tostring(Slot)
                            .. ", item " .. tostring(Want) .. ")"
                        warn("[hub] " .. Collection.AutoAllStatus)
                    end
                end

                local Active = Collection:GetActiveQuestCount()

                if Active == 0 then
                    local GapItem, GapNeed, GapHave
                    if Collection.AutoBreathing and Collection:GetPlayerLevel() >= 25 and not Collection:HasBreathing() then
                        local Style = Collection.BreathingStyle
                        if Style == nil or Style == "Cheapest" then
                            Style = Collection.BreathingStyles[1]
                        end
                        GapItem, GapNeed, GapHave = Collection:GetBreathingItemGap(Style)
                    end

                    if GapItem ~= nil then
                        -- short on a breathing material: farm it
                        local Spec = Collection.ItemFarm[GapItem]

                        local FarmKey, FarmGiver
                        for _, Key in (Spec.quests or {}) do
                            if (Collection.FarmQuestSkip[Key] or 0) <= tick() then
                                local Fine, Giver = Collection:IsQuestUsable(Key)
                                if Fine then
                                    FarmKey, FarmGiver = Key, Giver
                                    break
                                end
                            end
                        end

                        if FarmKey ~= nil then
                            Collection.CombatState.Auto, Collection.PositionState.On = false, false

                            Collection:GoToGiver(FarmKey, FarmGiver)

                            local Before = Collection:GetActiveQuestCount()
                            local OkQuest, Reason = Collection:AcceptQuest(FarmKey)

                            if OkQuest then
                                local Deadline = tick() + 2
                                repeat
                                    task.wait(0.1)
                                until Collection:GetActiveQuestCount() > Before or tick() > Deadline
                            end

                            if Collection:GetActiveQuestCount() > Before then
                                Collection.SelectedQuest = FarmKey
                                LastTravel = 0
                                Collection.AutoAllStatus = ("accepted %s for %s"):format(FarmKey, GapItem)
                            else
                                Collection.FarmQuestSkip[FarmKey] = tick() + 120
                                Collection.AutoAllStatus = ("farm quest %s refused: %s")
                                    :format(FarmKey, tostring(Reason or "not granted"))
                            end

                            task.wait(1)
                        else
                            Collection.PositionState.Targets = Spec.targets
                            Collection.CombatState.Auto, Collection.PositionState.On = true, true

                            if not Collection:IsTargetValid() and tick() - LastTravel > 5 then
                                Collection:TeleportTo(Spec.position)
                                LastTravel = tick()
                            end

                            Collection.AutoAllStatus = ("farming %s %d/%d"):format(GapItem, GapHave, GapNeed)
                            task.wait(1)
                        end
                    else
                        Collection.CombatState.Auto, Collection.PositionState.On = false, false

                        local Left = Collection:GetQuestCooldownLeft()
                        if Left > 0 then
                            Collection.AutoAllStatus = string.format("quest cooldown %ds", math.ceil(Left))
                            task.wait(math.min(Left, 5))
                        else
                            local QuestKey = Collection.SelectedQuest
                            if Collection.AutoPickQuest then
                                local NextKey = Collection:GetNextEligibleQuest()
                                if NextKey ~= nil then
                                    QuestKey = NextKey
                                end
                            end

                            if QuestKey == nil then
                                Collection.AutoAllStatus = "nothing eligible - check level / givers nearby"
                                task.wait(3)
                            else
                                Collection.SelectedQuest = QuestKey
                                local Giver = Collection:GetQuestGiverName(Collection.SelectedQuest)
                                Collection:GoToGiver(Collection.SelectedQuest, Giver)

                                local Before = Collection:GetActiveQuestCount()
                                local ok, Reason = Collection:AcceptQuest(Collection.SelectedQuest)

                                if not ok then
                                    Collection.AutoAllStatus = "refused: " .. tostring(Reason)
                                    task.wait(3)
                                else
                                    local Deadline = tick() + 2
                                    repeat
                                        task.wait(0.1)
                                    until Collection:GetActiveQuestCount() > Before or tick() > Deadline

                                    if Collection:GetActiveQuestCount() > Before then
                                        Collection.AutoAllStatus = "accepted " .. tostring(Collection.SelectedQuest)
                                        LastTravel = 0
                                    else
                                        Collection.AutoAllStatus = "not granted - could not reach " .. tostring(Giver or "giver")
                                        task.wait(4)
                                    end
                                end
                            end
                        end
                    end

                elseif Collection:IsAllTasksComplete() then
                    Collection.CombatState.Auto, Collection.PositionState.On = false, false
                    Collection.Shrine.WaitQuest = nil

                    local HeldKey = Collection:GetActiveQuestKey()
                    local Giver = Collection:GetQuestGiverName(HeldKey or Collection.SelectedQuest)

                    if tick() - LastTravel > 4 then
                        local ok, Why = Collection:TalkTo(Giver)
                        if not ok then
                            -- giver not loaded: travel there and talk on the next pass
                            Collection:GoToGiver(HeldKey or Collection.SelectedQuest, Giver)
                        end
                        LastTravel = tick()
                        Collection.AutoAllStatus = "turning in at " .. tostring(Giver or "?")
                            .. " - " .. tostring(Why)
                    end

                    task.wait(2)

                else
                    Collection.CombatState.Auto, Collection.PositionState.On = true, true

                    if not Collection:IsTargetValid() then
                        -- quest enemies are not spawned: respawn at the shrine nearest the objective,
                        -- once per quest, then stand there and wait
                        local Position, Which = Collection:GetActiveObjective()
                        local RootPart = Collection:GetRoot()
                        local Crystal = Position ~= nil and Collection.Shrine.On
                            and Collection:GetNearestCrystal(Position) or nil

                        -- WaitQuest only stops a second shrine trip. Dying while we wait respawns us
                        -- wherever spawn is set, so being away from both spots still means travel
                        if Position == nil or RootPart == nil
                            or (RootPart.Position - Position).Magnitude <= 80
                            or (Crystal ~= nil and (RootPart.Position - Crystal:GetPivot().Position).Magnitude <= 80) then
                            Collection.AutoAllStatus = "waiting for quest enemies to spawn: "
                                .. tostring(Collection.QuestFarmStatus)
                            -- enemies that are up but out of streaming range look the same as not spawned
                            if Position ~= nil and tick() - (Collection.Shrine.StreamAt or 0) > 10 then
                                Collection.Shrine.StreamAt = tick()
                                Collection:StreamAround(Position, 2)
                            end
                        elseif tick() - LastTravel > 5 then
                            if Crystal ~= nil and Collection.Shrine.WaitQuest ~= Which then
                                Collection.AutoAllStatus = "going to the shrine near " .. tostring(Which)
                                if Collection:ShrineGo(Crystal) then
                                    Collection.Shrine.WaitQuest = Which
                                else
                                    Collection.AutoAllStatus = "shrine trip failed: " .. tostring(Collection.Shrine.Status)
                                end
                            else
                                Collection:TeleportTo(Position)
                                Collection.AutoAllStatus = "travelling to " .. tostring(Which)
                            end
                            LastTravel = tick()
                        end
                    else
                        Collection.AutoAllStatus = "farming: " .. tostring(Collection.QuestFarmStatus)
                    end
                end

                task.wait(1)
            end
        end)
        if err then
            if Debug then warn("[Auto All] Caught Error:", err) end
            task.wait(1)
        end
    end
end)()


Tabs.Farm:AddToggle("ShrineTravel", {
    Title = "Travel by spawn shrine",
    Description = "Every trip over 500 studs (quests, bosses, regions, dungeon, fishing): sets your spawn at the crystal nearest the destination, resets your character and respawns there",
    Default = true,
}):OnChanged(function(Value)
    Collection.Shrine.On = Value
end)

Tabs.Farm:AddToggle("KickOnStaff", {
    Title = "Leave when an admin is here",
    Description = "Kicks you out the moment a game admin or developer (group rank 5+) is in the server or joins it",
    Default = true,
}):OnChanged(function(Value)
    Collection.Staff.On = Value
    if Value then
        Collection:CheckAllStaff()
    end
end)

Tabs.Farm:AddToggle("ServerHopWhenStuck", {
    Title = "Kick self when stuck",
    Description = "Kicks you out of the game (no rejoin) if you end up outside the map, or get pulled back to the same spot 3 times in 45s",
    Default = true,
}):OnChanged(function(Value)
    Collection.Stuck.On = Value
end)

Tabs.Farm:AddToggle("AutoLoot", {
    Title = "Auto Loot",
    Description = "Teleports to every drop under Workspace.LootDrops, picks it up, then returns",
    Default = false,
}):OnChanged(function(Value)
    Collection.LootState.On = Value
end)

Tabs.Farm:AddSlider("LootRange", {
    Title = "Auto Loot distance limit",
    Description = "Studs. Drops further than this from where you stand are left on the ground",
    Default = Collection.LootState.Range,
    Min = 10,
    Max = 1000,
    Rounding = 0,
    Callback = function(Value)
        Collection.LootState.Range = Value
    end,
})

--------------------------- [[ Loadout ]] ---------------------------

Collection.EquipState.Item = Collection.CachedLists.Combat[1]

Collection.EquipState.UseBest = true

Tabs.Loadout:AddToggle("AutoBestWeapon", {
    Title = "Auto Equip Best Weapon",
    Description = "Ranks your owned weapons on ActiveToolStats and puts the top one in slot 1, replacing a worse one. Off: uses Combat Style below, only when slot 1 is empty",
    Default = true,
}):OnChanged(function(Value)
    Collection.EquipState.UseBest = Value
end)

Tabs.Loadout:AddToggle("AutoBestAccessories", {
    Title = "Auto Equip Best Accessories",
    Description = "Once, when Auto Farm starts: ranks your owned accessories on their stats and fills the five accessory slots with the best",
    Default = true,
}):OnChanged(function(Value)
    Collection.EquipState.Accessories = Value
end)

Tabs.Loadout:AddDropdown("ToolbarItem", {
    Title = "Combat Style",
    Description = "Used when Auto Equip Best Weapon is off",
    Values = Collection.CachedLists.Combat,
    Multi = false,
    Default = 1,
}):OnChanged(function(Value)
    Collection.EquipState.Item = Value
end)

coroutine.wrap(function()
    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            if Collection.EquipState.Auto and Collection.EquipState.Item ~= nil and Collection.EquipState.Item ~= "<none>" then
                local Slots = Collection:GetToolbarSlots()
                local Want = Collection.EquipState.Item
                if Collection.EquipState.UseBest then
                    Want = Collection:GetBestWeapon("balanced") or Want
                end
                -- with the toggle on, a worse weapon already in slot One is swapped out too.
                -- ponytail: one swap per weapon name, in case the slot value is not the item id
                local Swap = Collection.EquipState.UseBest and Collection.EquipState.Swapped ~= Want
                    and Slots["One"] ~= Collection:FindItemId(Want)
                if (Slots["One"] or 0) == 0 or Swap then
                    Collection.EquipState.Swapped = Want
                    pcall(Collection.EquipToolbar, Collection, Want, "One")
                    Collection:RaiseIdentity()
                elseif not Collection:IsWeaponDrawn() then
                    pcall(Collection.PressSlotKey, Collection, "One")
                    Collection:RaiseIdentity()
                end
            end

            task.wait(5)
        end)
        if err then
            if Debug then warn("[Auto Equip] Caught Error:", err) end
            task.wait(1)
        end
    end
end)()

--------------------------- [[ Training ]] ---------------------------

coroutine.wrap(function()
    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            pcall(Collection.ScanTrainers, Collection)
            Collection:RaiseIdentity()
            task.wait(5)
        end)
        if err then
            if Debug then warn("[Trainer Scan] Caught Error:", err) end
            task.wait(1)
        end
    end
end)()

coroutine.wrap(function()
    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            if Collection.AutoTraining then
                local Codes = Collection:GetPendingTrainingCodes()
                if #Codes > 0 then
                    for _, Code in Codes do
                        if not Collection.AutoTraining or not Collection:IsAlive() then break end
                        pcall(Collection.RunTrainingTask, Collection, Code)
                    end
                    Collection:RaiseIdentity()
                end
                task.wait(2)
            else
                task.wait(1)
            end
        end)
        if err then
            if Debug then warn("[Auto Training] Caught Error:", err) end
            task.wait(1)
        end
    end
end)()

--------------------------- [[ Travel ]] ---------------------------

Collection.NetModules = {
    Teleporter = Collection:TryRequire("CAM", "Client", "Modules", "Teleporter"),
    Worlds     = Collection:TryRequire("CAM", "Worlds"),
    SignalFn   = Collection:TryRequire("Communication", "ServerAndClient", "Signals", "SignalFunction"),
}

Collection.TravelState = { Owner = "", AutoOuwland = false, AutoPrivate = false }

function Collection:ServerRequest(Settings, UI)
    if Collection.NetModules.Teleporter ~= nil and type(Collection.NetModules.Teleporter.Request) == "function" then
        local Requested, ok, Detail = pcall(Collection.NetModules.Teleporter.Request, Settings, UI)
        if not Requested then
            return false, "Teleporter.Request errored: " .. tostring(ok)
        end
        return ok == true, tostring(Detail or (ok and "teleporting" or "refused"))
    end
    if Collection.NetModules.SignalFn ~= nil and type(Collection.NetModules.SignalFn.ToServer) == "function" then
        local Fired, ok, Detail = pcall(Collection.NetModules.SignalFn.ToServer, "TeleportServer", Settings)
        if not Fired then
            return false, "TeleportServer errored: " .. tostring(ok)
        end
        return ok == true, tostring(Detail or "sent")
    end
    return false, "Teleporter module missing"
end

function Collection:JoinWorld(Which)
    local PlaceId = tonumber(Which)
    if PlaceId == nil and Collection.NetModules.Worlds ~= nil and type(Collection.NetModules.Worlds.ByName) == "table" then
        local World = Collection.NetModules.Worlds.ByName[Which]
        PlaceId = type(World) == "table" and World.Id or nil
    end
    if PlaceId == nil then
        return false, "unknown world " .. tostring(Which)
    end
    if PlaceId == game.PlaceId then
        return false, "already there"
    end
    return Collection:ServerRequest({ placeId = PlaceId, allowFallback = true },
        { Title = "Travelling", SubTitle = tostring(Which) })
end

function Collection:JoinPrivateServer(Owner, PlaceId)
    if type(Owner) ~= "string" or Owner == "" then
        return false, "no owner username"
    end
    return Collection:ServerRequest(
        { placeId = PlaceId or game.PlaceId, privateOwner = Owner },
        { Title = "Private Server", SubTitle = Owner })
end

Collection.HubPositions, Collection.HubOrder = Collection:GetRegionHubs()
Collection:RaiseIdentity()

Collection.SelectedHub = Collection.HubOrder[1]

Tabs.Travel:AddDropdown("TravelRegion", {
    Title = "Region",
    Values = Collection.HubOrder,
    Multi = false,
    Default = 1,
}):OnChanged(function(Value)
    Collection.SelectedHub = Value
end)

Tabs.Travel:AddButton({
    Title = "Teleport to region",
    Callback = function()
        local Position = Collection.HubPositions[Collection.SelectedHub]
        local ok = Collection:TeleportTo(Position)
        Collection:RaiseIdentity()
        Fluent:Notify({
            Title = "Travel",
            Content = Position == nil and "unknown region" or (ok and tostring(Collection.SelectedHub) or "no character"),
            Duration = 4,
        })
    end,
})

Tabs.Travel:AddInput("PrivateOwner", {
    Title = "Private server owner",
    Description = "Their username, not their display name",
    Default = "",
    Placeholder = "username",
    Finished = true,
    Callback = function(Value)
        Collection.TravelState.Owner = tostring(Value or "")
    end,
})

Tabs.Travel:AddToggle("AutoPrivateServer", {
    Title = "Join private server",
    Description = "From the lobby, joins the owner's Ouwland private server. Does nothing once you are in a world",
    Default = false,
}):OnChanged(function(Value)
    Collection.TravelState.AutoPrivate = Value
end)

Tabs.Travel:AddToggle("AutoEnterDungeon", {
    Title = "!! Auto Enter Dungeon",
    Description = "!! May get you banned. Travels to the Ouwigahara portal and goes in. Needs the forge quest done",
    Default = false,
}):OnChanged(function(Value)
    Collection:WarnRisky("AutoEnterDungeon", "Auto Enter Dungeon", Value, function(On)
        Dungeon.Auto = On
    end)
end)

--------------------------- [[ Bosses ]] ---------------------------

Collection.UIHandles.BossStatus = Tabs.Bosses:AddParagraph({
    Title = "Boss Farm",
    Content = "off",
})

do
    local Labels, ByLabel = {}, {}
    for _, Entry in Boss.List do
        local Label = Boss:GetLabel(Entry)
        table.insert(Labels, Label)
        ByLabel[Label] = Entry.weapon
    end

    Tabs.Bosses:AddDropdown("BossWeapons", {
        Title = "Weapons",
        Description = "Boss-only drops. The farm camps each boss until its weapon is in your inventory",
        Values = Labels,
        Multi = true,
        Default = {},
    }):OnChanged(function(Value)
        local Picks = {}
        if type(Value) == "table" then
            for Label, On in pairs(Value) do
                if On and ByLabel[Label] then
                    Picks[ByLabel[Label]] = true
                end
            end
        end
        Boss.Picks = Picks
    end)
end

Tabs.Bosses:AddToggle("AutoBoss", {
    Title = "Auto Boss Farm",
    Description = "Turns Auto Farm off while it runs. Skips bosses above your level",
    Default = false,
}):OnChanged(function(Value)
    Boss.On = Value
    if Value and Collection.AutoAll and Collection.UIHandles.AutoAll then
        pcall(function() Collection.UIHandles.AutoAll:SetValue(false) end)
    end
end)

Tabs.Bosses:AddToggle("AutoQuestBoss", {
    Title = "Auto Farm Quest Bosses",
    Description = "Only fights the boss of a held Eliminate quest. Works alongside Auto Farm",
    Default = false,
}):OnChanged(function(Value)
    Boss.QuestOn = Value
end)

Tabs.Bosses:AddToggle("BossKeepFarming", {
    Title = "Keep farming owned weapons",
    Description = "Off: a weapon is dropped from the list once you own one",
    Default = false,
}):OnChanged(function(Value)
    Boss.KeepFarming = Value
end)

Tabs.Bosses:AddToggle("BossIgnoreRace", {
    Title = "Ignore race requirement",
    Description = "Also farm weapons your race cannot equip",
    Default = false,
}):OnChanged(function(Value)
    Boss.IgnoreRace = Value
end)

coroutine.wrap(function()
    local Shown
    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            local ok, Report = pcall(Boss.GetReport, Boss)
            local Text = ("%s\n\n%s"):format(tostring(Boss.Status),
                ok and Report or ("read failed: " .. tostring(Report)))
            if Text ~= Shown then
                Shown = Text
                pcall(function() Collection.UIHandles.BossStatus:SetDesc(Text) end)
            end
            task.wait(1)
        end)
        if err then
            if Debug then warn("[Boss Status] Caught Error:", err) end
            task.wait(1)
        end
    end
end)()

--------------------------- [[ Extras ]] ---------------------------

Collection.UIHandles.FishStatus = Tabs.Extras:AddParagraph({
    Title = "Fishing",
    Content = "off",
})

Collection.UIHandles.Fish = Tabs.Extras:AddToggle("AutoFish", {
    Title = "Auto Fish",
    Description = "Goes to the fishing spot, gets the permit and a rod if you have none, then casts, wins the bar and collects, over and over. Turns Auto Farm off",
    Default = false,
})

Collection.UIHandles.Fish:OnChanged(function(Value)
    Collection.Fish.On = Value
    if not Value and Collection.Fish.Line ~= nil and Collection.Fish.Line.Parent ~= nil then
        -- reel the line back in, or the character stays pinned in place with it out
        task.spawn(function()
            local RootPart = Collection:GetRoot()
            if RootPart ~= nil then
                Event:FireServer("Tool_Mouse", "Down", RootPart.Position)
                task.wait(0.12)
                Event:FireServer("Tool_Mouse", "Up", RootPart.Position)
            end
        end)
    end
    if Value and Collection.AutoAll and Collection.UIHandles.AutoAll then
        pcall(function() Collection.UIHandles.AutoAll:SetValue(false) end)
    end
end)

coroutine.wrap(function()
    local Shown
    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            local Text = tostring(Collection.Fish.Status)
            if Text ~= Shown then
                Shown = Text
                Collection:RaiseIdentity()
                pcall(function() Collection.UIHandles.FishStatus:SetDesc(Text) end)
            end
            task.wait(0.5)
        end)
        if err then
            if Debug then warn("[Fish Status] Caught Error:", err) end
            task.wait(1)
        end
    end
end)()

Tabs.Extras:AddInput("FishSpot", {
    Title = "Fishing spot",
    Description = "Where Auto Fish stands, as x, y, z. Default is the Mistfall Harbor dock",
    Default = "-198, 803, 570",
    Placeholder = "x, y, z",
    Finished = true,
})

Tabs.Extras:AddButton({
    Title = "Use my position as the fishing spot",
    Description = "Stand where you want to fish, facing any way, and press this",
    Callback = function()
        local RootPart = Collection:GetRoot()
        if RootPart ~= nil then
            Collection:RaiseIdentity()
            local Text = ("%.1f, %.1f, %.1f"):format(RootPart.Position.X, RootPart.Position.Y, RootPart.Position.Z)
            pcall(function() Fluent.Options.FishSpot:SetValue(Text) end)
            Fluent:Notify({ Title = "Fishing", Content = "fishing spot set to " .. Text, Duration = 5 })
        end
    end,
})

Collection.UIHandles.SchematicStatus = Tabs.Extras:AddParagraph({
    Title = "Schematics",
    Content = "off",
})

Collection.UIHandles.Schematics = Tabs.Extras:AddToggle("AutoSchematics", {
    Title = "Auto collect schematics",
    Description = "Visits every model in Map.Puzzles, loads it in and fires its prompts. Pauses Auto Farm while it runs",
    Default = false,
})

Collection.UIHandles.Schematics:OnChanged(function(Value)
    Collection:WarnRisky("AutoSchematics", "Auto collect schematics", Value, function(On)
        if On then
            Schematics.Done, Schematics.Results = {}, {}
            Schematics.Status = "starting"
        end
        Schematics.On = On
    end)
end)

coroutine.wrap(function()
    local Shown
    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            local Results = Schematics.Results
            local Text = tostring(Schematics.Status)
            if #Results > 0 then
                Text = Text .. "\n\n" .. table.concat(Results, "\n")
            end
            if Text ~= Shown then
                Shown = Text
                pcall(function() Collection.UIHandles.SchematicStatus:SetDesc(Text) end)
            end
            task.wait(1)
        end)
        if err then
            if Debug then warn("[Schematic Status] Caught Error:", err) end
            task.wait(1)
        end
    end
end)()

Tabs.Travel:AddButton({
    Title = "!! Enter dungeon now",
    Description = "Fires the Ouwigahara portal once",
    Callback = function()
        Collection:WarnRisky("EnterDungeonNow", "Enter dungeon now", true, function(On)
            if not On then
                return
            end
            task.spawn(function()
                Collection:RaiseIdentity()
                local ok, Detail = Dungeon:Enter()
                Dungeon.Status = tostring(Detail)
                print("[hub] dungeon enter: " .. tostring(ok) .. " - " .. tostring(Detail))
            end)
        end)
    end,
})

Tabs.Travel:AddToggle("AutoOuwland", {
    Title = "Auto join Ouwland",
    Description = "From the lobby, joins Ouwland. Does nothing once you are in a world",
    Default = false,
}):OnChanged(function(Value)
    Collection.TravelState.AutoOuwland = Value
end)

coroutine.wrap(function()
    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            task.wait(5)
            local Owner = Collection.TravelState.Owner
            if Owner == "" and Fluent.Options.PrivateOwner ~= nil then
                Owner = tostring(Fluent.Options.PrivateOwner.Value or "")
            end
            -- both auto-joins only ever leave from the lobby; anywhere else we stay where we are
            if game.PlaceId ~= Collection.Stuck.Lobby then
                return
            end
            if Collection.TravelState.AutoPrivate and Owner ~= "" then
                local ok, Detail = Collection:JoinPrivateServer(Owner, 136406881576517)
                if ok then
                    Fluent:Notify({ Title = "Server", Content = "joining " .. Owner .. "'s private server", Duration = 5 })
                else
                    Collection.TravelState.PrivateStatus = tostring(Detail)
                    warn("[hub] private server: " .. tostring(Detail))
                end
            elseif Collection.TravelState.AutoOuwland then
                local ok, Detail = Collection:JoinWorld("Ouwland")
                if ok then
                    Fluent:Notify({ Title = "Server", Content = "returning to Ouwland", Duration = 5 })
                elseif Detail ~= "already there" then
                    warn("[hub] auto Ouwland: " .. tostring(Detail))
                end
            end
        end)
        if err then
            if Debug then warn("[Auto Ouwland] Caught Error:", err) end
            task.wait(1)
        end
    end
end)()

Collection.UIHandles.Rarity = Tabs.Extras:AddDropdown("SpinMinRarity", {
    Title = "Stop at",
    Description = "Stops as soon as a clan of this tier or better is rolled",
    Values = Collection.RarityOrder,
    Multi = false,
    Default = 4,
})

Collection.UIHandles.Rarity:OnChanged(function(Value)
    Collection.SpinState.MinRarity = tonumber(tostring(Value):match("^%d")) or 5
end)

Collection.UIHandles.Rarity:SetValue("5 Legendary")

Tabs.Extras:AddToggle("AutoSpin", {
    Title = "Auto Spin",
    Description = "Rolls until the chosen tier is hit, or spins run out",
    Default = false,
}):OnChanged(function(Value)
    Collection.SpinState.Auto = Value
end)

--------------------------- [[ Settings ]] ---------------------------

if SaveManager ~= nil and InterfaceManager ~= nil then
    pcall(function()
        SaveManager:SetLibrary(Fluent)
        InterfaceManager:SetLibrary(Fluent)
        SaveManager:IgnoreThemeSettings()
        SaveManager:SetIgnoreIndexes({})
        InterfaceManager:SetFolder("Vaderhug")
        SaveManager:SetFolder("Vaderhug/Vaderhug")
        InterfaceManager:BuildInterfaceSection(Tabs.Settings)
        if Fluent.SetMascotTransparency ~= nil then
            Tabs.Settings:AddSlider("MascotTransparency", {
                Title = "Mascot transparency",
                Description = "0 is solid, 100 hides her",
                Default = math.floor((Fluent.MascotTransparency or 0.5) * 100 + 0.5),
                Min = 0,
                Max = 100,
                Rounding = 0,
                Callback = function(Value)
                    Fluent:SetMascotTransparency(Value / 100)
                end,
            })
        end
        SaveManager:BuildConfigSection(Tabs.Settings)
    end)
end

if type(GlobalEnv.vaderhug_QUEST) == "string" then
    local Pinned
    for Label, Key in pairs(Collection.QuestByLabel) do
        if Key == GlobalEnv.vaderhug_QUEST then
            Pinned = Label
            break
        end
    end
    if Pinned ~= nil then
        Collection.UIHandles.Quest:SetValue(Pinned)
    end
end

if GlobalEnv.vaderhug_AUTOSTART then
    task.delay(1, function()
        Collection.UIHandles.AutoAll:SetValue(true)
        Fluent:Notify({
            Title = "vaderhug",
            Content = "Auto farm started",
            SubContent = tostring(GlobalEnv.vaderhug_QUEST or "quest: first in list"),
            Duration = 5,
        })
    end)
end

--------------------------- [[ Auto Save ]] ---------------------------

-- Every toggle, dropdown and slider value, kept per account in Vaderhug/Slayer2/<username>.json.
-- Loaded once here, after all the controls exist, then written whenever something changes.
Collection.AutoSave = {
    File = "Vaderhug/Slayer2/" .. LocalPlayer.Name .. ".json",
    Last = nil,
}

function Collection:ReadOptions()
    local Values = {}
    for Id, Option in pairs(Fluent.Options) do
        local Value = Option.Value
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
    if not isfolder("Vaderhug/Slayer2") then
        makefolder("Vaderhug/Slayer2")
    end
end)
Collection.RiskQuiet = true
Collection:LoadOptions()
Collection.RiskQuiet = false

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

Window:SelectTab(1)

Fluent:Notify({
    Title = "vaderhug",
    Content = "Loaded - combat route: " .. Collection.CombatRouteName,
    Duration = 6,
})

