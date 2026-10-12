---------------------------------------------- [ Configs ] ----------------------------------------------

local Debug = true
repeat task.wait() until game:IsLoaded()
local GlobalEnv = getgenv()

-- the lobby is its own place; script.lua covers the dungeon places
local LobbyPlaceId = 106484206883664
if game.PlaceId ~= LobbyPlaceId then
    return
end

---------------------------------------------- [ Prepare Project ] ----------------------------------------------

local Collection = {}; Collection.__index = Collection
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
_setthreadidentity = (typeof(setthreadidentity) == "function" and setthreadidentity)
    or (typeof(setidentity) == "function" and setidentity)
    or (typeof(syn) == "table" and syn.set_thread_identity)
    or (typeof(set_thread_identity) == "function" and set_thread_identity)

--------------------------- [[ Services ]] ---------------------------

local Players = Services.Players
local ReplicatedStorage = Services.ReplicatedStorage
local LocalPlayer = Players.LocalPlayer

--------------------------- [[ Forward Declarations ]] ---------------------------

local RandomID
local FluentLoaded, Fluent
local KnitServices
local Window, Tabs

--------------------------- [[ Game Modules ]] ---------------------------

function Collection:WaitForPath(Timeout, ...)
    local Node = ReplicatedStorage
    for _, Name in { ... } do
        Node = Node and Node:WaitForChild(Name, Timeout)
    end
    return Node
end

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

KnitServices = Collection:WaitForPath(15, "Packages", "_Index", "sleitnick_knit@1.7.0", "knit", "Services")
Lobby.QueueService = KnitServices and KnitServices:WaitForChild("DungeonQueueService", 15)
Lobby.QueueFunctions = Lobby.QueueService and Lobby.QueueService:WaitForChild("RF", 15)

if Lobby.QueueFunctions == nil then
    warn("[Dungeon Lootr Lobby] the queue remotes are missing - nothing loaded")
    return
end

Lobby.DungeonData = Collection:TryRequire("GameInfo", "DungeonData")

Lobby.SummonService = KnitServices:WaitForChild("SummoningService", 15)
Lobby.SummonFunctions = Lobby.SummonService and Lobby.SummonService:WaitForChild("RF", 15)
Lobby.SummoningData = Collection:TryRequire("GameInfo", "SummoningData")
Lobby.ClassData = Collection:TryRequire("Classes", "Class_Data")

-- Common = 1 ... Celestial = 7
Lobby.RarityData = Collection:TryRequire("GameInfo", "RarityData")
Lobby.RarityIndex = Lobby.RarityData and Lobby.RarityData.RarityIndex or {}

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

if type(GlobalEnv.lootrlobby_conns) == "table" then
    pcall(function()
        for _, Connection in GlobalEnv.lootrlobby_conns do
            pcall(function() Connection:Disconnect() end)
        end
    end)
end
GlobalEnv.lootrlobby_conns = {}

-- running the script again takes the previous window down with it
if GlobalEnv.lootrlobby_fluent ~= nil then
    pcall(function() GlobalEnv.lootrlobby_fluent:Destroy() end)
    GlobalEnv.lootrlobby_fluent = nil
end

RandomID = {}
GlobalEnv.lootrlobby_run = RandomID

--------------------------- [[ Anti Idle ]] ---------------------------

do
    if _G.__lootrlobbyAntiIdle ~= nil then
        pcall(function() _G.__lootrlobbyAntiIdle:Disconnect() end)
        _G.__lootrlobbyAntiIdle = nil
    end

    local ok, VirtualUser = pcall(game.GetService, game, "VirtualUser")
    if ok and VirtualUser ~= nil then
        _G.__lootrlobbyAntiIdle = LocalPlayer.Idled:Connect(function()
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end)
    end
end

function Collection:Track(Connection)
    table.insert(GlobalEnv.lootrlobby_conns, Connection)
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
    warn("[Dungeon Lootr Lobby] couldn't load Fluent: " .. tostring(Fluent))
    return
end

GlobalEnv.lootrlobby_fluent = Fluent

function Collection:IsAlive()
    return GlobalEnv.lootrlobby_run == RandomID and not Fluent.Unloaded
end

-- Calling into the game's modules leaves a thread at game identity, where Fluent cannot
-- create the notification; raise it first.
function Collection:Notify(Options)
    Collection:RaiseIdentity()
    local Library = Fluent
    pcall(Library.Notify, Library, Options)
end

local _, SaveManager = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
end)

local _, InterfaceManager = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
end)

--------------------------- [[ State ]] ---------------------------

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

Collection.WebhookState = {
    On = false,
    Url = "",
    -- script.lua's saved settings; its webhook URL is used when none is set here
    DungeonFile = "Vaderhug/DungeonLootr/" .. LocalPlayer.Name .. ".json",
    Asset = "https://raw.githubusercontent.com/DONUT6599/ddgdhdf/refs/heads/main/Asset_1.png",
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
    local Remote = Lobby.QueueFunctions:FindFirstChild(Name)
    if Remote == nil then
        return false, "no remote " .. Name
    end
    return pcall(Remote.InvokeServer, Remote, ...)
end

-- nil when the dungeon and difficulty can be entered, otherwise the server's reason
function Lobby:GetLockReason(Dungeon, Difficulty)
    local ok, Access = Lobby:Invoke("GetDungeonAccessState", Dungeon)
    if ok and type(Access) == "table" and Access.Unlocked == false then
        return tostring(Access.Reason or (Dungeon .. " is locked"))
    end

    local okDiff, Unlocked = Lobby:Invoke("GetUnlockedDifficulties", Dungeon)
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

    local Dungeon, Difficulty = State.Dungeon, State.Difficulty
    State.Status = ("checking %s (%s)"):format(Dungeon, Difficulty)

    local Locked = Lobby:GetLockReason(Dungeon, Difficulty)
    if Locked ~= nil then
        return Finish(false, ("%s (%s) cannot be entered: %s"):format(Dungeon, Difficulty, Locked))
    end

    State.Status = ("selecting %s (%s)"):format(Dungeon, Difficulty)
    for _, Step in {
        { "RequestSelectMode", "Dungeon" },
        { "RequestSelectDungeon", Dungeon },
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
        and (Party.SelectedDungeon ~= Dungeon or Party.SelectedDifficulty ~= Difficulty) then
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
    return Finish(true, ("entering %s (%s)"):format(Dungeon, Difficulty))
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

--------------------------- [[ Webhook ]] ---------------------------

-- the URL typed in this script, or failing that the one saved by script.lua
function Collection:GetWebhookUrl()
    local State = Collection.WebhookState
    if State.Url ~= "" then
        return State.Url
    end
    local ok, Saved = pcall(function()
        return Services.HttpService:JSONDecode(readfile(State.DungeonFile))
    end)
    local Url = ok and type(Saved) == "table" and Saved.WebhookUrl or nil
    return type(Url) == "string" and (string.gsub(Url, "%s", "")) or ""
end

-- Result is { ClassName, Rarity, Aspect, Left }; Spins is how many the session used.
function Collection:SendClassWebhook(Result, Spins, Outcome)
    local State = Collection.WebhookState
    if _http_request == nil then
        return false, "this executor has no request function"
    end
    local Url = Collection:GetWebhookUrl()
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
                if Collection.WebhookState.On and State.Spins > 0 and State.Last ~= nil then
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
    SubTitle = "lobby",
    TabWidth = 150,
    Size = UDim2.fromOffset(560, 440),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl,
})

--------------------------- [[ Tabs ]] ---------------------------

Collection.Tabs = {
    Lobby    = Window:AddTab({ Title = "Lobby",    Icon = "map" }),
    Class    = Window:AddTab({ Title = "Class",    Icon = "dices" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
}

-- a loop body started further up can leave this thread at game identity, and Fluent
-- then fails to build the next control; raise it again on every tab lookup
Tabs = setmetatable({}, { __index = function(_, Key)
    Collection:RaiseIdentity()
    return Collection.Tabs[Key]
end })

Collection.UIHandles = {}

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

Tabs.Class:AddToggle("ClassWebhook", {
    Title = "Webhook notification",
    Description = "Post the class a spin session ended on to Discord",
    Default = false,
}):OnChanged(function(Value)
    Collection.WebhookState.On = Value
end)

Tabs.Class:AddInput("ClassWebhookUrl", {
    Title = "Webhook URL",
    Description = "Leave empty to use the one set in the dungeon script",
    Placeholder = "https://discord.com/api/webhooks/...",
    Default = "",
    Numeric = false,
    Finished = true,
}):OnChanged(function(Text)
    Collection.WebhookState.Url = (string.gsub(tostring(Text or ""), "%s", ""))
end)

Tabs.Class:AddButton({
    Title = "Send test",
    Description = "Posts a sample spin result to the webhook",
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

if SaveManager ~= nil and InterfaceManager ~= nil then
    pcall(function()
        SaveManager:SetLibrary(Fluent)
        InterfaceManager:SetLibrary(Fluent)
        SaveManager:IgnoreThemeSettings()
        SaveManager:SetIgnoreIndexes({})
        InterfaceManager:SetFolder("Vaderhug")
        SaveManager:SetFolder("Vaderhug/DungeonLootrLobby")
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

Tabs.Settings:AddButton({
    Title = "Unload",
    Description = "Stops the auto start and destroys the UI",
    Callback = function()
        Fluent:Destroy()
    end,
})

--------------------------- [[ Auto Save ]] ---------------------------

-- Every toggle, dropdown and slider value, kept per account in Vaderhug/DungeonLootrLobby/<username>.json.
-- Loaded once here, after all the controls exist, then written whenever something changes.
Collection.AutoSave = {
    File = "Vaderhug/DungeonLootrLobby/" .. LocalPlayer.Name .. ".json",
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
    if not isfolder("Vaderhug/DungeonLootrLobby") then
        makefolder("Vaderhug/DungeonLootrLobby")
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
        Collection.WebhookState.On = true
        Collection:RaiseIdentity()
        pcall(function() Fluent.Options.ClassWebhookUrl:SetValue(Url) end)
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

Window:SelectTab(1)

Collection:Notify({
    Title = "vaderhug",
    Content = "Lobby loaded - auto start is " .. (Lobby.State.Auto and "on" or "off"),
    Duration = 6,
})
