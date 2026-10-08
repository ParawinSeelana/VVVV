---------------------------------------------- [ Configs ] ----------------------------------------------

local Debug = true
repeat task.wait() until game:IsLoaded()
local GlobalEnv = getgenv()

---------------------------------------------- [ Prepare Project ] ----------------------------------------------

local Collection = {}; Collection.__index = Collection
local Dungeon = {}; Dungeon.__index = Dungeon
local Cards = {}; Cards.__index = Cards
local Shop = {}; Shop.__index = Shop

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
local FluentLoaded, Fluent, Checker, Combat_presets, Character_info_provider, Items, Utility
local CamRoot, Event
local Window, Tabs

--------------------------- [[ Session ]] ---------------------------

-- the dungeon scripts share these names, so loading one stops the other
if type(_G.__dhConns) == "table" then
    pcall(function()
        for _, Connection in _G.__dhConns do
            pcall(function() Connection:Disconnect() end)
        end
    end)
end
_G.__dhConns = {}

RandomID = {}
_G.__dhRun = RandomID

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
    table.insert(_G.__dhConns, Connection)
    return Connection
end

function Collection:RaiseIdentity()
    if _setthreadidentity then
        pcall(_setthreadidentity, 8)
    end
end

Collection:RaiseIdentity()

--------------------------- [[ Fluent ]] ---------------------------

-- VaderUI in place of Fluent (same API); source lives in vaderui/VaderUI.lua.
-- Loading it destroys the window of whichever script loaded it before.
FluentLoaded, Fluent = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/DONUT6599/ddgdhdf/refs/heads/main/VaderUI.lua"))()
end)

if not FluentLoaded or Fluent == nil then
    warn("[dungeon] couldn't load Fluent: " .. tostring(Fluent))
    return
end

function Collection:IsAlive()
    return _G.__dhRun == RandomID and not Fluent.Unloaded
end

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

CamRoot = ReplicatedStorage:FindFirstChild("CAM")
pcall(function()
    Collection.CurPower = CamRoot.Client.Controllers.Skills_Provider:FindFirstChild("CurPower")
end)
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
    ShieldCheckedAt = 0,
    BackoffUntil = 0,
    ComboBackoff = true,
    AvoidShield = true,
    LastPunch = 0,
    LastCombo = 0,
}

Collection.PositionState = {
    Stance = "Behind",
    Distance = 3.5,
    Reach = 500, -- studs; enemies further away are ignored
}

Collection.EquipState = {
    Auto = true,
    Slot = "One",
    Status = "idle",
    Numbers = { One = 1, Two = 2, Three = 3, Four = 4, Five = 5 },
}

Collection.LootState = {
    On = true,
}

Collection.TargetLabel = "-"

Dungeon.PlaceId = 75556147183481
Dungeon.HubFile = "hub_dungeon_v2_VaderUI.lua"
Dungeon.MainFile = "Main_v2_VaderUI.lua"
Dungeon.Auto = false
Dungeon.Runs = 0
Dungeon.LastReady = "idle"

Cards.Auto = false
Cards.SkipAll = false
Cards.Fallback = "Skip"
Cards.Picks = 0
Cards.LastHand = "none yet"
Cards.LastPick = "none yet"
-- kept across reloads, so the catalogue survives a re-run of the script
Cards.Seen = (type(_G.__dhSeen) == "table" and _G.__dhSeen) or {}
Cards.Hands = tonumber(_G.__dhHands) or 0
_G.__dhSeen = Cards.Seen

-- best first: with several wanted cards on the board, the earliest one here wins
Cards.Order = {
    "Second Wind", "Extra Life", "Vampiric", "Second Chance", "Reincarnation",
    "Adrenaline", "Bulwark", "Second Skin",
    "Momentum", "Frenzy", "Heavy Hitter", "Berserk", "Streak",
    "Wildfire", "Deep Freeze", "Plague Bearer", "Venom Fang",
    "Damage", "Max Health", "Max Stamina", "Block Points", "Thick Blood",
    "Endurance Training",
    "Fortune", "Trophy", "Points", "Bounty", "Headhunter",
    "Rerolls", "Loaded Dice", "Lucky Draw", "Prodigy", "Ticket Pack",
    "Mulligan", "Jackpot Floor", "Cheap Seats", "Double Down",
    "Quartermaster", "Hoarder", "Bloodbank", "Medic", "Potion",
    "Weapon Master", "Twin Weapons", "Arsenal", "Twin Souls", "Clan Heir",
    "Forbidden Art", "Skill", "Weapon", "Clan",
    "Skip Floor", "Warcry", "Ignition", "Chill", "Tainted Edge", "Envenomed",
    "Marathon", "Rally", "Split the Take", "Communal Heal", "Parting Gift",
    "Long Night", "Rush Hour", "Handoff", "Reshuffle", "Respec", "Lifeline",
    "Revive", "Skip",
    "Fair Fight", "Boss Hunt", "Elite Guard", "Champion", "Twin Bosses",
    "Ascension", "Boss Rush", "Gold Rush", "Cursed Coin", "Blood Moon",
    "The Horde", "Berserkers", "Thick Skin", "Double Time", "Time Attack",
    "Iron Discipline", "Bleeding Floor", "Bare Hands",
    "Fog of War", "Lights Out", "Heavy Air", "Thin Air", "No Guard",
    "Iron Tower", "Last Stand", "Lone Wolf", "Focused Mind", "Last Rites",
    "Sacrifice", "Blood Pact", "Wager", "Tribute", "Toll Gate",
    "Featherweight", "Glass Cannon", "Glass Floor", "Reincarnated",
    "Tectonic Shift", "Grounded", "Pacifist",
}

Cards.Priority = {
    ["Second Wind"] = true, ["Extra Life"] = true, ["Vampiric"] = true,
    ["Momentum"] = true, ["Frenzy"] = true, ["Damage"] = true,
    ["Max Health"] = true, ["Fortune"] = true, ["Trophy"] = true,
    ["Points"] = true, ["Rerolls"] = true,
}

Cards.Avoid = {
    ["Pacifist"] = true, ["Grounded"] = true, ["Tectonic Shift"] = true,
    ["Glass Cannon"] = true, ["Glass Floor"] = true,
    ["Featherweight"] = true, ["Reincarnated"] = true,
    ["Wager"] = true, ["Tribute"] = true, ["Toll Gate"] = true,
}

Shop.On = false
Shop.Status = "idle"
Shop.Spent = false
Shop.Keep = 0 -- points left unspent
Shop.Order = { "1,000 Exp", "1,000 Wen", "Refinement Ore", "Mythic Refinement Ore" }
Shop.Picked = {}
Shop.BuyList = {}
Shop.Prices = {
    ["1,000 Exp"]             = 3500,
    ["1,000 Wen"]             = 2500,
    ["Refinement Ore"]        = 1500,
    ["Mythic Refinement Ore"] = 30000,
}

--------------------------- [[ Combat ]] ---------------------------

-- CU.Combat can still be missing when this loads right after a teleport, so this is
-- run again from Collection:Swing() whenever the script or its ComboValue has gone
function Collection:ResolveCombat()
    Collection.Punch, Collection.Do = nil, nil

    Collection.PlayerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
    Collection.ClientRoot = Collection.PlayerScripts and Collection.PlayerScripts:FindFirstChild("CU")
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
    Collection.ResolvedAt = tick()
end

function Collection:IsCombatStale()
    return Collection.CombatScript == nil or Collection.ComboValue == nil
        or Collection.CombatScript.Parent == nil or Collection.ComboValue.Parent == nil
end

Collection:ResolveCombat()

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

-- one swing by the best route available; returns how long to wait before the next
function Collection:Swing()
    if Collection:IsCombatStale() and tick() - (Collection.ResolvedAt or 0) > 2 then
        Collection:ResolveCombat()
    end

    local ok, NextGap
    if Collection.CombatRoute == 1 then
        ok, NextGap = pcall(Collection.Punch)
        if not ok then
            Collection.CombatState.Status = "punch() errored: " .. tostring(NextGap)
            return 0.25
        end
        if NextGap ~= nil then
            Collection.CombatState.Status = string.format("punching (next in %.2fs)", NextGap)
            return NextGap
        end
        -- punch() refused (nothing equipped, or Checker): CombatStep says why in its status
    end

    ok, NextGap = pcall(Collection.CombatStep, Collection)
    if not ok then
        Collection.CombatState.Status = "error: " .. tostring(NextGap)
    end
    return (ok and NextGap) or 0.25
end

--------------------------- [[ Targets ]] ---------------------------

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

-- Back off after the finisher lands
function Collection:HookComboTracker()
    local Service = ReplicatedStorage:WaitForChild("Player_Service", 20)
    local Values = Service and Service:WaitForChild("Values", 20)
    local Mine = Values and Values:WaitForChild(LocalPlayer.Name, 20)
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
    end
    Collection:Track(Mine.ChildAdded:Connect(function(Child)
        if Child.Name == "ComboTrackerClient" then Bind(Child) end
    end))
end

task.spawn(function()
    pcall(Collection.HookComboTracker, Collection)
end)

function Collection:GetAllegiance()
    if Collection.AllegianceModule == nil then
        local Module = Collection:TryRequire("CAM", "Global", "Allegiance")
        if type(Module) == "table" and type(Module.AreFriendly) == "function" then
            Collection.AllegianceModule = Module
        end
    end
    return Collection.AllegianceModule
end

function Collection:IsFriendly(Model)
    if Players:GetPlayerFromCharacter(Model) ~= nil then
        return true
    end

    local PlayerCharacter = LocalPlayer.Character
    local Allegiance = Collection:GetAllegiance()
    if PlayerCharacter == nil or Allegiance == nil then
        return false
    end

    local ok, Friendly = pcall(Allegiance.AreFriendly, PlayerCharacter, Model)
    return ok and Friendly == true
end

function Collection:GetModelOf(Entry)
    if Entry:IsA("Model") then
        return Entry
    end

    local Named = Entry:FindFirstChild(Entry.Name)
    if Named ~= nil and Named:IsA("Model") then
        return Named
    end

    for _, Child in Entry:GetChildren() do
        if Child:IsA("Model") and Child:FindFirstChildOfClass("Humanoid") then
            return Child
        end
    end
end

-- the Regions folder is looked up once and again only if a new floor replaced it
function Collection:GetRegions()
    local Folder = Collection.RegionsFolder
    if Folder == nil or not Folder:IsDescendantOf(Workspace) then
        Folder = Workspace:FindFirstChild("Humanoids")
        Folder = Folder and Folder:FindFirstChild("Regions")
        Collection.RegionsFolder = Folder
    end
    return Folder
end

function Collection:GetNearestEnemy()
    local RootPart = Collection:GetRoot()
    if RootPart == nil then
        return nil
    end

    local Regions = Collection:GetRegions()
    local Best, BestDistance
    for _, Region in (Regions and Regions:GetChildren() or {}) do
        local ActiveNpcs = Region:FindFirstChild("ActiveNpcs")
        for _, Entry in (ActiveNpcs and ActiveNpcs:GetChildren() or {}) do
            local Model = Collection:GetModelOf(Entry)
            local Humanoid = Model and Model:FindFirstChildOfClass("Humanoid")
            if Humanoid ~= nil and Humanoid.Health > 0 then
                local ok, Pivot = pcall(function() return Model:GetPivot() end)
                local Distance = ok and (Pivot.Position - RootPart.Position).Magnitude
                -- the allegiance call is the costly test, so it runs last and only on a closer NPC
                if Distance and Distance <= Collection.PositionState.Reach
                    and (BestDistance == nil or Distance < BestDistance)
                    and not Collection:IsFriendly(Model) then
                    Best, BestDistance = Model, Distance
                end
            end
        end
    end

    return Best, BestDistance
end

--------------------------- [[ Positioning ]] ---------------------------

coroutine.wrap(function()
    while RunService.Heartbeat:Wait() do
        if Collection.BreakLoop or not Collection:IsAlive() then break end
        local ok, err = pcall(function()
            if not Collection.CombatState.Auto or not Collection:IsAlive() then
                return
            end

            local Target = Collection.CurrentTarget
            local Humanoid = Target and Target.Parent and Target:FindFirstChildOfClass("Humanoid")
            if Humanoid == nil or Humanoid.Health <= 0 then
                Collection.CurrentTarget = nil
                Collection.CombatState.Shielded = false
                return
            end

            local RootPart = Collection:GetRoot()
            if RootPart == nil then
                return
            end

            -- the shield test searches the whole model, so it runs ten times a second, not every frame
            if tick() - Collection.CombatState.ShieldCheckedAt > 0.1 then
                Collection.CombatState.ShieldCheckedAt = tick()
                Collection.CombatState.Shielded = Collection.CombatState.AvoidShield and Collection:IsShielded(Target)
            end
            local ComboResting = tick() < Collection.CombatState.BackoffUntil

            local Distance = Collection.PositionState.Distance
                + (Collection.CombatState.Shielded and 10 or 0)
                + ((ComboResting or Collection:IsRagdolled()) and 14 or 0)

            local TargetCFrame = Target:GetPivot()
            local Spot
            if Collection.PositionState.Stance == "Above" then
                Spot = TargetCFrame * CFrame.new(0, Distance, 0)
            elseif Collection.PositionState.Stance == "Underground" then
                Spot = TargetCFrame * CFrame.new(0, -Distance, 0)
            else
                Spot = TargetCFrame * CFrame.new(0, 0, Distance)
            end

            local UpVector = TargetCFrame.UpVector
            local Direction = TargetCFrame.Position - Spot.Position
            if Direction.Magnitude < 0.05 then
                Direction = TargetCFrame.LookVector
            end
            if math.abs(Direction.Unit:Dot(UpVector)) > 0.99 then
                UpVector = TargetCFrame.LookVector
            end
            RootPart.CFrame = CFrame.lookAt(Spot.Position, Spot.Position + Direction, UpVector)

            RootPart.AssemblyLinearVelocity = Vector3.zero
            RootPart.AssemblyAngularVelocity = Vector3.zero
        end)
        if err and Debug then warn("[Positioning] Caught Error:", err) end
    end
end)()

--------------------------- [[ Auto Combat ]] ---------------------------

coroutine.wrap(function()
    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            local Target, Distance
            if Collection.CombatState.Auto then
                Target, Distance = Collection:GetNearestEnemy()
            end
            Collection.CurrentTarget = Target
            Collection.TargetLabel = Target and ("%s (%.0f)"):format(Target.Name, Distance or -1) or "-"

            if not Collection.CombatState.Auto then
                Collection.CombatState.Status = "off"
                task.wait(0.5)
            elseif Target == nil then
                Collection.CombatState.Status = "waiting - no enemy in reach"
                task.wait(0.5)
            elseif tick() < Collection.CombatState.BackoffUntil then
                Collection.CombatState.Status = "finisher landed - backing off"
                task.wait(0.1)
            elseif Collection:IsRagdolled() then
                Collection.CombatState.Status = "ragdolled - waiting to get up"
                task.wait(0.1)
            elseif Collection.CombatState.Shielded then
                Collection.CombatState.Status = "waiting - target still blocking"
                task.wait(0.2)
            else
                task.wait(Collection:Swing())
            end
        end)
        if err then
            if Debug then warn("[Combat] Caught Error:", err) end
            task.wait(1)
        end
    end
end)()

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

--------------------------- [[ Inventory & Equip ]] ---------------------------

function Collection:GetEquippedSlotValue()
    local Folder = LocalPlayer:FindFirstChild("Items_Config")
    return Folder and Folder:FindFirstChild("Equipped") or nil
end

function Collection:IsWeaponDrawn()
    local Equipped = Collection:GetEquippedSlotValue()
    return Equipped ~= nil and Equipped.Value ~= 0
end

function Collection:GetFilledSlots()
    local Data = Collection:GetPlayerData()
    local Inventory = Data and Data:FindFirstChild("Inventory")
    local Toolbar = Inventory and Inventory:FindFirstChild("Toolbar")

    local Filled = {}
    for _, Name in { "One", "Two", "Three", "Four", "Five" } do
        local Entry = Toolbar and Toolbar:FindFirstChild(Name)
        if Entry ~= nil and tonumber(Entry.Value) ~= nil and Entry.Value ~= 0 then
            table.insert(Filled, Name)
        end
    end
    return Filled
end

function Collection:DrawWeapon()
    if Collection:IsWeaponDrawn() then
        return true, "already drawn"
    end

    local Want = Collection.EquipState.Slot
    local Filled = Collection:GetFilledSlots()
    if Collection.EquipState.Numbers[Want] == nil or not table.find(Filled, Want) then
        Want = Filled[1]
    end
    if Want == nil then
        return false, "toolbar is empty"
    end

    local Number = Collection.EquipState.Numbers[Want]
    local Equipped = Collection:GetEquippedSlotValue()
    if Equipped ~= nil then
        if not pcall(function() Equipped.Value = Number end) then
            return false, "could not set Items_Config.Equipped"
        end
    else
        pcall(function() Event:FireServer("Item_Equip", Number) end)
    end

    local Deadline = tick() + 3
    repeat
        task.wait(0.2)
    until Collection:IsWeaponDrawn() or tick() > Deadline

    if Collection:IsWeaponDrawn() then
        return true, "drew slot " .. Want
    end
    return false, "sent but nothing drew"
end

coroutine.wrap(function()
    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            if Collection.EquipState.Auto and (Collection.CombatState.Auto or Dungeon.Auto)
                and not Collection:IsWeaponDrawn() then
                local Drawn, Detail = Collection:DrawWeapon()
                Collection.EquipState.Status = tostring(Detail)
                task.wait(Drawn and 2 or 5)
            else
                task.wait(2)
            end
        end)
        if err then
            if Debug then warn("[Auto Equip] Caught Error:", err) end
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
    local Fired = 0
    for _, FolderName in { "LootDrops", "Chests" } do
        local Folder = Workspace:FindFirstChild(FolderName)
        for _, Drop in (Folder and Folder:GetChildren() or {}) do
            local Prompt = Drop:FindFirstChildWhichIsA("ProximityPrompt", true)
            if Prompt ~= nil and Prompt.Enabled and Collection:FirePrompt(Prompt) then
                Fired = Fired + 1
            end
        end
    end
    return Fired
end

coroutine.wrap(function()
    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            if Collection.LootState.On then
                pcall(Collection.LootOnce, Collection)
            end
            task.wait(1)
        end)
        if err then
            if Debug then warn("[Auto Loot] Caught Error:", err) end
            task.wait(1)
        end
    end
end)()

--------------------------- [[ Dungeon Run ]] ---------------------------

-- runs in the next place: the dungeon gets this hub, everything else the main script
function Dungeon:QueueRouter()
    if _queue_on_teleport == nil then
        return "no queue_on_teleport"
    end

    if _clear_teleport_queue ~= nil then
        pcall(_clear_teleport_queue)
    end

    local Chunk = ("task.wait(8) if game.PlaceId == %d then loadstring(readfile(%q))() else loadstring(readfile(%q))() end")
        :format(Dungeon.PlaceId, Dungeon.HubFile, Dungeon.MainFile)
    local ok = pcall(_queue_on_teleport, Chunk)
    return ok and "armed" or "refused by the executor"
end

function Dungeon:GetHearts()
    local Value = LocalPlayer:GetAttribute("Hearts")
    if Value == nil then
        return nil
    end
    return tonumber(Value) or 0
end

function Dungeon:IsOutOfLives()
    local Hearts = Dungeon:GetHearts()
    return Hearts ~= nil and Hearts <= 0
end

function Dungeon:GetState()
    return tostring(Workspace:GetAttribute("MinigameState") or "?")
end

function Dungeon:IsClimbing()
    return Dungeon:GetState() == "Climbing"
end

function Dungeon:IsReadied()
    return LocalPlayer:GetAttribute("Readied") == true
end

function Dungeon:GetText(Node)
    local ok, Value = pcall(function() return Node.Text end)
    if ok and type(Value) == "string" and Value ~= "" then
        return Value
    end
end

-- floor, clock and points as the top bar shows them
function Dungeon:GetPhase()
    if Dungeon.TopBar == nil or not Dungeon.TopBar:IsDescendantOf(LocalPlayer) then
        local Gui = LocalPlayer:FindFirstChild("PlayerGui")
        Dungeon.TopBar = Gui and Gui:FindFirstChild("OuwigaharaTopBar", true)
        Dungeon.TopBarNodes = {}
        for _, Name in { "Floor", "Clock", "Value" } do
            table.insert(Dungeon.TopBarNodes, Dungeon.TopBar and Dungeon.TopBar:FindFirstChild(Name, true))
        end
    end
    if Dungeon.TopBar == nil then
        return "no run"
    end

    local Parts = {}
    for _, Node in Dungeon.TopBarNodes do
        local Text = Dungeon:GetText(Node)
        if Text then
            table.insert(Parts, Text)
        end
    end
    return #Parts > 0 and table.concat(Parts, "  ") or "no run"
end

function Dungeon:GetStartPrompt()
    -- found once; the whole-workspace search below is too heavy to repeat on every try
    if Dungeon.StartPrompt ~= nil and Dungeon.StartPrompt:IsDescendantOf(Workspace) then
        return Dungeon.StartPrompt, Dungeon.StartPad
    end
    Dungeon.StartPrompt, Dungeon.StartPad = nil, nil

    local Map = Workspace:FindFirstChild("Map")
    local Lobby = Map and Map:FindFirstChild("Minigame Map")
    local Pad = Lobby and Lobby:FindFirstChild("StartPad", true)
    local Prompt = Pad and Pad:FindFirstChildWhichIsA("ProximityPrompt", true)

    if Prompt == nil then
        for _, Descendant in Workspace:GetDescendants() do
            if Descendant:IsA("ProximityPrompt") and Descendant:GetAttribute("PromptStyle") == "Card" then
                Prompt, Pad = Descendant, Descendant.Parent
                break
            end
        end
    end

    Dungeon.StartPrompt, Dungeon.StartPad = Prompt, Prompt and Pad
    return Dungeon.StartPrompt, Dungeon.StartPad
end

function Dungeon:ReadyUp()
    if Dungeon:IsReadied() then
        return true, "already readied"
    end
    if Dungeon:IsClimbing() then
        return false, "already climbing"
    end
    if Dungeon:IsOutOfLives() then
        return false, "out of lives - this run is finished"
    end

    local Prompt, Pad = Dungeon:GetStartPrompt()
    if Prompt == nil then
        return false, "no StartPad prompt - not in the lobby?"
    end

    local RootPart = Collection:GetRoot()
    if RootPart ~= nil and Pad ~= nil then
        local ok, Position = pcall(function()
            return Pad:IsA("PVInstance") and Pad:GetPivot().Position or Pad.WorldPosition
        end)
        if ok then
            RootPart.CFrame = CFrame.new(Position + Vector3.new(0, 4, 0))
            RootPart.AssemblyLinearVelocity = Vector3.zero
            task.wait(0.4)
        end
    end

    Collection:FirePrompt(Prompt)

    local Deadline = tick() + 4
    repeat
        task.wait(0.2)
    until Dungeon:IsReadied() or Dungeon:IsClimbing() or tick() > Deadline

    if Dungeon:IsReadied() or Dungeon:IsClimbing() then
        return true, "readied"
    end
    return false, "prompt fired but never readied"
end

coroutine.wrap(function()
    local WasClimbing = false
    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            if Dungeon.Auto and Dungeon:IsClimbing() then
                WasClimbing = true
            elseif Dungeon.Auto then
                if WasClimbing then
                    Dungeon.Runs = Dungeon.Runs + 1
                    WasClimbing = false
                    task.wait(3)
                end

                if Dungeon:IsOutOfLives() then
                    Dungeon.LastReady = "out of lives"
                    task.wait(5)
                elseif not Dungeon:IsReadied() then
                    local Readied, Detail = Dungeon:ReadyUp()
                    Dungeon.LastReady = tostring(Detail)
                    task.wait(Readied and 2 or 4)
                end
            end

            task.wait(1)
        end)
        if err then
            if Debug then warn("[Auto Run] Caught Error:", err) end
            task.wait(1)
        end
    end
end)()

--------------------------- [[ Cards ]] ---------------------------

function Cards:Send(Payload)
    return pcall(function()
        Event:FireServer("OuwigaharaRequest", Payload)
    end)
end

function Cards:GetOffers()
    local Gui = LocalPlayer:FindFirstChild("PlayerGui")
    local Holder = Gui and Gui:FindFirstChild("ComponentsHolder")
    local Main = Holder and Holder:FindFirstChild("MainNotificationFrame")
    return Main and Main:FindFirstChild("OuwigaharaOffers")
end

function Cards:GetHand()
    local Offers = Cards:GetOffers()
    if Offers == nil or not Offers.Visible then
        return nil
    end

    local Board = Offers:FindFirstChild("BBCards")
    local Folder = Board and Board:FindFirstChild("Cards")
    if Folder == nil then
        return nil
    end

    local Slots = {}
    for _, Slot in Folder:GetChildren() do
        if tonumber(Slot.Name) ~= nil and Slot:IsA("GuiObject") and Slot.Visible then
            table.insert(Slots, Slot)
        end
    end
    if #Slots == 0 then
        return nil
    end
    table.sort(Slots, function(A, B) return tonumber(A.Name) < tonumber(B.Name) end)

    local Hand = {}
    for _, Slot in Slots do
        local Title = Slot:FindFirstChild("Title", true)
        local Bottom = Slot:FindFirstChild("Bottom", true)
        table.insert(Hand, {
            id    = Slot.Name,
            title = Title and Dungeon:GetText(Title) or "?",
            desc  = Bottom and Dungeon:GetText(Bottom) or "",
        })
    end
    return Hand
end

-- a multi dropdown hands back { name = true } or a plain list, depending on who set it
function Cards:GetSelectedSet(Value)
    local Set = {}
    if type(Value) == "table" then
        for Key, Selected in pairs(Value) do
            if Selected == true then
                Set[Key] = true
            elseif type(Selected) == "string" then
                Set[Selected] = true
            end
        end
    end
    return Set
end

function Cards:GetDefaultList(Set)
    local List = {}
    for _, Title in Cards.Order do
        if Set[Title] then
            table.insert(List, Title)
        end
    end
    return List
end

function Cards:IsMatch(Title, Needle)
    return string.find(string.lower(Title), string.lower(Needle), 1, true) ~= nil
end

function Cards:GetNumberIn(Title)
    return tonumber(string.match(Title, "%+%s*(%d+%.?%d*)")) or 0
end

function Cards:Choose(Hand)
    local Allowed = {}
    for _, Card in Hand do
        local Banned = false
        for Title in pairs(Cards.Avoid) do
            if Cards:IsMatch(Card.title, Title) then
                Banned = true
                break
            end
        end
        if not Banned then
            table.insert(Allowed, Card)
        end
    end

    for _, Want in Cards.Order do
        if Cards.Priority[Want] then
            -- several copies of a wanted card: the bigger "+N" wins
            local Best
            for _, Card in Allowed do
                if Cards:IsMatch(Card.title, Want)
                    and (Best == nil or Cards:GetNumberIn(Card.title) > Cards:GetNumberIn(Best.title)) then
                    Best = Card
                end
            end
            if Best ~= nil then
                return Best, Want
            end
        end
    end

    if Cards.Fallback == "Take first" and Allowed[1] ~= nil then
        return Allowed[1], "first allowed"
    end
    return nil, "nothing wanted"
end

function Cards:Handle()
    local Hand = Cards:GetHand()
    if Hand == nil then
        Cards.LastKey = nil
        return false
    end

    -- the same board is answered once
    local Names = {}
    for _, Card in Hand do
        table.insert(Names, Card.id .. ":" .. Card.title)
    end
    local Key = table.concat(Names, "   ")
    if Key == Cards.LastKey then
        return false
    end
    Cards.LastKey = Key
    Cards.LastHand = Key

    for _, Card in Hand do
        if Cards.Seen[Card.title] == nil then
            Cards.Seen[Card.title] = { desc = Card.desc, count = 0 }
        end
        Cards.Seen[Card.title].count = Cards.Seen[Card.title].count + 1
    end
    Cards.Hands = Cards.Hands + 1
    _G.__dhHands = Cards.Hands

    local Pick, Why
    if Cards.SkipAll then
        Why = "auto skip"
    else
        Pick, Why = Cards:Choose(Hand)
    end

    if Pick ~= nil then
        Cards:Send({ action = "Pick", id = Pick.id })
        Cards.LastPick = ("%s (%s)"):format(Pick.title, Why)
        Cards.Picks = Cards.Picks + 1
    else
        Cards:Send({ action = "Skip" })
        Cards.LastPick = "Skip - " .. tostring(Why)
    end
    return true
end

-- answer as soon as the board opens; the loop below is the slow fallback
function Cards:Watch()
    local Offers = Cards:GetOffers()
    if Offers == nil or Offers == Cards.OffersRoot then
        return
    end

    Cards.OffersRoot = Offers
    Collection:Track(Offers:GetPropertyChangedSignal("Visible"):Connect(function()
        if Offers.Visible and Cards.Auto then
            task.wait(0.5)
            pcall(Cards.Handle, Cards)
        end
    end))
end

coroutine.wrap(function()
    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            Cards:Watch()
            if Cards.Auto then
                pcall(Cards.Handle, Cards)
            end
            task.wait(2)
        end)
        if err then
            if Debug then warn("[Cards] Caught Error:", err) end
            task.wait(1)
        end
    end
end)()

--------------------------- [[ Shop ]] ---------------------------

function Shop:Apply()
    local List = {}
    if Shop.On then
        for _, Item in Shop.Order do
            if Shop.Picked[Item] then
                table.insert(List, Item)
            end
        end
    end
    Shop.BuyList = List
end

function Shop:GetPriceOf(Item)
    local Price = Shop.Prices[Item]
    if Price == nil and string.sub(Item, -8) == " Mastery" then
        Price = 3000
    end
    return Price
end

function Shop:GetRunPoints()
    return tonumber(LocalPlayer:GetAttribute("RunPoints")) or 0
end

function Shop:GetRemote()
    if Shop.Remote == nil or Shop.Remote.Parent == nil then
        local Node = Event.Parent.Parent:FindFirstChild("SignalFunction")
        Shop.Remote = Node and Node:FindFirstChild("Function")
    end
    return Shop.Remote
end

function Shop:Spend(Reason)
    if #Shop.BuyList == 0 then
        return "nothing to buy configured"
    end
    if Workspace:GetAttribute("MinigameRunFreshStart") == true then
        Shop.Status = "roguelike run - the shops keep nothing"
        return Shop.Status
    end

    local Remote = Shop:GetRemote()
    if Remote == nil then
        Shop.Status = "SignalFunction missing"
        return Shop.Status
    end

    local Bought = {}
    for _, Item in Shop.BuyList do
        local Price = Shop:GetPriceOf(Item)
        local Count = Price and math.floor((Shop:GetRunPoints() - Shop.Keep) / Price) or 0
        if Count > 0 then
            local ok, Result = pcall(function()
                return Remote:InvokeServer("PurchaseSelection", { [Item] = Count })
            end)
            table.insert(Bought, ("%s x%d %s"):format(Item, Count,
                (ok and Result) and "bought" or ("refused (" .. tostring(Result) .. ")")))
            task.wait(0.5)
        end
    end

    Shop.Status = ("%s - %s, %d points left"):format(tostring(Reason),
        #Bought > 0 and table.concat(Bought, ", ") or "nothing affordable", Shop:GetRunPoints())
    return Shop.Status
end

-- spends once per run: when the hearts run out, or 3s after the climb stops
coroutine.wrap(function()
    local StoppedAt
    while true do
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            local Hearts = Dungeon:GetHearts()
            local OutOfHearts = Hearts ~= nil and Hearts <= 0
            if not Dungeon:IsClimbing() then
                StoppedAt = StoppedAt or tick()
            elseif not OutOfHearts then
                Shop.Spent, StoppedAt = false, nil
            end

            local Stopped = StoppedAt ~= nil and tick() - StoppedAt > 3
            if not Shop.Spent and #Shop.BuyList > 0 and Shop:GetRunPoints() > 0
                and (OutOfHearts or Stopped) then
                Shop.Spent = true
                Debug_Log("[dungeon] shop: " .. Shop:Spend(OutOfHearts and "out of hearts" or "climb ended"))
            end
            task.wait(0.5)
        end)
        if err then
            if Debug then warn("[Shop] Caught Error:", err) end
            task.wait(1)
        end
    end
end)()

--------------------------- [[ Window ]] ---------------------------

Collection:RaiseIdentity()

Window = Fluent:CreateWindow({
    Title = "vaderhug - Ouwigahara",
    SubTitle = "dungeon",
    TabWidth = 150,
    Size = UDim2.fromOffset(520, 360),
    Acrylic = false,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.RightControl,
})

--------------------------- [[ Tabs ]] ---------------------------

Collection.Tabs = {
    Run   = Window:AddTab({ Title = "Run",   Icon = "swords" }),
    Cards = Window:AddTab({ Title = "Cards", Icon = "layers" }),
}

-- a loop body started further up can leave this thread at game identity, and Fluent
-- then fails to build the next control; raise it again on every tab lookup
Tabs = setmetatable({}, { __index = function(_, Key)
    Collection:RaiseIdentity()
    return Collection.Tabs[Key]
end })

Collection.UIHandles = {}

--------------------------- [[ Run Status ]] ---------------------------

Collection.UIHandles.Status = Tabs.Run:AddParagraph({
    Title = "Status",
    Content = "idle",
})

coroutine.wrap(function()
    local Shown
    while true do
        task.wait(1)
        if Collection.BreakLoop or not Collection:IsAlive() then break end

        local ok, err = pcall(function()
            local Text = ("Place: %s\nState: %s%s\nHearts: %s\nRun: %s\nTarget: %s\nCombat: %s\nShop: %s\nRuns: %d   Picked: %d cards\nLast: %s")
                :format(game.PlaceId == Dungeon.PlaceId and "Ouwigahara" or tostring(game.PlaceId),
                    Dungeon:GetState(), Dungeon:IsReadied() and " (readied)" or "",
                    Dungeon:IsOutOfLives() and "0 - run finished" or tostring(Dungeon:GetHearts() or "-"),
                    Dungeon:GetPhase(), Collection.TargetLabel, Collection.CombatState.Status,
                    Shop.Status, Dungeon.Runs, Cards.Picks, Cards.LastPick)
            if Text ~= Shown then
                Shown = Text
                Collection:RaiseIdentity()
                pcall(function() Collection.UIHandles.Status:SetDesc(Text) end)
            end
        end)
        if err then
            if Debug then warn("[Status] Caught Error:", err) end
            task.wait(1)
        end
    end
end)()

--------------------------- [[ Run Controls ]] ---------------------------

Tabs.Run:AddToggle("AutoRun", {
    Title = "Auto Run",
    Description = "Readies up in the lobby and starts the next climb when one ends",
    Default = false,
}):OnChanged(function(Value)
    Dungeon.Auto = Value
end)

Tabs.Run:AddButton({
    Title = "Ready up now",
    Description = "Walks to the StartPad and triggers it once",
    Callback = function()
        task.spawn(function()
            Collection:RaiseIdentity()
            local ok, Detail = Dungeon:ReadyUp()
            Dungeon.LastReady = tostring(Detail)
            Debug_Log(("[dungeon] ready up: %s - %s"):format(tostring(ok), tostring(Detail)))
        end)
    end,
})

Tabs.Run:AddToggle("AutoEquip", {
    Title = "Auto Equip Weapon",
    Description = "Draws a weapon on arrival - the portal leaves you empty handed",
    Default = true,
}):OnChanged(function(Value)
    Collection.EquipState.Auto = Value
end)

Tabs.Run:AddDropdown("WeaponSlot", {
    Title = "Weapon slot",
    Description = "Which toolbar slot to draw. Falls back to the first filled one",
    Values = { "One", "Two", "Three", "Four", "Five" },
    Multi = false,
    Default = 1,
}):OnChanged(function(Value)
    Collection.EquipState.Slot = Value
end)

--------------------------- [[ Combat Controls ]] ---------------------------

Tabs.Run:AddToggle("AutoCombat", {
    Title = "Auto Combat",
    Description = "Attack the nearest enemy. Friendlies are never targeted",
    Default = false,
}):OnChanged(function(Value)
    Collection.CombatState.Auto = Value
end)

Tabs.Run:AddSlider("Reach", {
    Title = "Reach",
    Description = "Ignore enemies further away than this",
    Default = 500, Min = 50, Max = 2000, Rounding = 0,
}):OnChanged(function(Value)
    Collection.PositionState.Reach = tonumber(Value) or 500
end)

Tabs.Run:AddSlider("Distance", {
    Title = "Attack distance",
    Description = "How close to sit while swinging",
    Default = 3.5, Min = 1, Max = 15, Rounding = 1,
}):OnChanged(function(Value)
    Collection.PositionState.Distance = tonumber(Value) or 3.5
end)

Tabs.Run:AddDropdown("Stance", {
    Title = "Stance",
    Description = "Above and Underground sit on the target's Y axis - the one side they cannot turn to face",
    Values = { "Behind", "Above", "Underground" },
    Multi = false,
    Default = 1,
}):OnChanged(function(Value)
    Collection.PositionState.Stance = Value
end)

Tabs.Run:AddToggle("AvoidBlock", {
    Title = "Avoid block",
    Description = "Stand off and hold swings while the target is blocking",
    Default = true,
}):OnChanged(function(Value)
    Collection.CombatState.AvoidShield = Value
end)

Tabs.Run:AddToggle("ComboBackoff", {
    Title = "Wait for cooldown",
    Description = "Step back for the recovery after a combo finisher lands",
    Default = true,
}):OnChanged(function(Value)
    Collection.CombatState.ComboBackoff = Value
end)

Tabs.Run:AddToggle("AutoLoot", {
    Title = "Auto loot",
    Description = "Open mob drops and chests",
    Default = true,
}):OnChanged(function(Value)
    Collection.LootState.On = Value
end)

--------------------------- [[ Shop Controls ]] ---------------------------

Tabs.Run:AddDropdown("BuyItems", {
    Title = "Buy with tower points",
    Description = "Spent when the hearts run out, top of the list first",
    Values = Shop.Order,
    Multi = true,
    Default = { "1,000 Exp" },
}):OnChanged(function(Value)
    Shop.Picked = Cards:GetSelectedSet(Value)
    Shop:Apply()
end)

Tabs.Run:AddToggle("AutoBuy", {
    Title = "Auto buy",
    Description = "Spend the run's points on the items above when it ends",
    Default = false,
}):OnChanged(function(Value)
    Shop.On = Value
    Shop:Apply()
end)

--------------------------- [[ Card Controls ]] ---------------------------

Tabs.Cards:AddToggle("AutoCards", {
    Title = "Auto Pick Cards",
    Description = "Reads the board and picks by the priority list below",
    Default = false,
}):OnChanged(function(Value)
    Cards.Auto = Value
end)

Tabs.Cards:AddDropdown("Priority", {
    Title = "Want",
    Description = "Cards worth taking. Ranked by the built-in order, best first",
    Values = Cards.Order,
    Multi = true,
    Default = Cards:GetDefaultList(Cards.Priority),
}):OnChanged(function(Value)
    -- an empty pick keeps the last list: with nothing wanted every board would be skipped
    local Set = Cards:GetSelectedSet(Value)
    if next(Set) ~= nil then
        Cards.Priority = Set
    end
end)

Tabs.Cards:AddDropdown("Avoid", {
    Title = "Never take",
    Description = "Pacifist disables all skills for the whole run - never take it",
    Values = Cards.Order,
    Multi = true,
    Default = Cards:GetDefaultList(Cards.Avoid),
}):OnChanged(function(Value)
    Cards.Avoid = Cards:GetSelectedSet(Value)
end)

Tabs.Cards:AddDropdown("Fallback", {
    Title = "When nothing matches",
    Values = { "Skip", "Take first" },
    Multi = false,
    Default = 1,
}):OnChanged(function(Value)
    Cards.Fallback = Value
end)

Tabs.Cards:AddToggle("AutoSkip", {
    Title = "Skip everything",
    Description = "Takes no card at all. Overrides the priority list above",
    Default = false,
}):OnChanged(function(Value)
    Cards.SkipAll = Value
end)

Collection.UIHandles.CardStatus = Tabs.Cards:AddParagraph({
    Title = "Last board",
    Content = "none yet",
})

Tabs.Cards:AddButton({
    Title = "Dump card catalogue",
    Description = "Every distinct card seen so far, to the console",
    Callback = function()
        local Titles = {}
        for Title in pairs(Cards.Seen) do
            table.insert(Titles, Title)
        end
        table.sort(Titles)

        print(("[cards] ==== %d distinct cards over %d hands ===="):format(#Titles, Cards.Hands))
        for _, Title in Titles do
            local Entry = Cards.Seen[Title]
            print(("[cards] %3dx  %-28s | %s"):format(Entry.count, Title, Entry.desc))
        end

        Collection:RaiseIdentity()
        pcall(function()
            Collection.UIHandles.CardStatus:SetDesc(("%d distinct cards seen over %d hands - full list in the console")
                :format(#Titles, Cards.Hands))
        end)
    end,
})

Tabs.Cards:AddButton({
    Title = "Read board now",
    Description = "Shows the current hand without picking anything",
    Callback = function()
        Collection:RaiseIdentity()
        local Hand = Cards:GetHand()
        if Hand == nil then
            Collection.UIHandles.CardStatus:SetDesc("no board on screen")
            return
        end

        local Lines = {}
        for _, Card in Hand do
            table.insert(Lines, ("%s  %s"):format(Card.id, Card.title))
        end
        local Pick, Why = Cards:Choose(Hand)
        table.insert(Lines, "")
        table.insert(Lines, Pick
            and ("would pick: %s (%s)"):format(Pick.title, Why)
            or ("would skip - " .. tostring(Why)))
        Collection.UIHandles.CardStatus:SetDesc(table.concat(Lines, "\n"))
    end,
})

--------------------------- [[ Console Handles ]] ---------------------------

-- DgSet("AutoCombat", true): flips a control by its id, so the window and the state stay in step
_G.DgSet = function(Id, Value)
    local Option = Fluent.Options[Id]
    if Option == nil then
        return "no control called " .. tostring(Id)
    end
    Collection:RaiseIdentity()
    Option:SetValue(Value)
    return ("%s = %s"):format(tostring(Id), tostring(Value))
end

_G.DgGet = function()
    local Enemy, Distance = Collection:GetNearestEnemy()
    return ("cards=%s combat=%s reach=%s target=%s nearest=%s dist=%s route=%s status=%s hearts=%s"):format(
        tostring(Cards.Auto), tostring(Collection.CombatState.Auto), tostring(Collection.PositionState.Reach),
        tostring(Collection.TargetLabel),
        Enemy and Enemy.Name or "none",
        Distance and ("%.0f"):format(Distance) or "-",
        tostring(Collection.CombatRouteName), tostring(Collection.CombatState.Status),
        tostring(Dungeon:GetHearts() or "-"))
end

_G.DgEquip = function()
    local ok, Detail = Collection:DrawWeapon()
    return ("drawn=%s ok=%s %s"):format(tostring(Collection:IsWeaponDrawn()), tostring(ok), tostring(Detail))
end

--------------------------- [[ Auto Save ]] ---------------------------

-- Every toggle, dropdown and slider value, kept per account in Vaderhug/Slayer2/<username>_dungeon.json.
-- Loaded once here, after all the controls exist, then written whenever something changes.
Collection.AutoSave = {
    File = "Vaderhug/Slayer2/" .. LocalPlayer.Name .. "_dungeon.json",
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
Collection.AutoSave.Applied = Collection:LoadOptions()

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

--------------------------- [[ Startup ]] ---------------------------

-- leaving the dungeon by any door lands back in the main script
if game.PlaceId == Dungeon.PlaceId then
    Dungeon:QueueRouter()
end

Window:SelectTab(1)

if game.PlaceId ~= Dungeon.PlaceId then
    Fluent:Notify({
        Title = "Wrong place",
        Content = "This hub only works inside Ouwigahara. Main_v2 enters the dungeon from Ouwland.",
        Duration = 8,
    })
end

Fluent:Notify({
    Title = "Verderhug",
    Content = "Loaded - combat route: " .. Collection.CombatRouteName,
    SubContent = Collection.AutoSave.Applied > 0 and "your saved settings are back on" or "toggles start off",
    Duration = 6,
})
