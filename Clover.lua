repeat task.wait() until game:IsLoaded()
task.wait(1)

-- +1 Stone Skipping hub. Every action goes through ReplicatedStorage.SkippingNetwork.Request.
local MAP_NAME = "+1 Stone Skipping"
local Env = (getgenv and getgenv()) or _G
if Env.VaderMapStarter then pcall(function() Env.VaderMapStarter:Destroy() end) end

local VaderUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/DONUT6599/ddgdhdf/refs/heads/main/VaderUI.lua"))()
local State = {
    AutoFarm = false, FarmMode = "Smart", TrainZone = "Best Unlocked", SmartWindow = 60,
    AutoRebirth = false, PauseRebirthForWorld = true, AutoWorld = false,
    AutoStone = false, AutoTrail = false, AutoBoosts = false, Boosts = {},
    AutoHatch = false, MultiHatch = true, Eggs = {}, HatchesPerTrip = 10, FarmBetweenTrips = 10, OpenInventoryEggs = false,
    AutoDelete = false, DeleteRarities = { Common = true, Uncommon = true }, DeleteOnlyWeaker = true, KeepVariants = true, KeepBest = 10,
    AutoPetIndex = false, AutoGifts = false, AutoDaily = false, AutoOffline = false, AutoCodes = false,
    LowGraphics = false, World = "World1",
}
local Connections = {}
local closed = false
local saveProfile = function() return false end
local Window = VaderUI:CreateWindow({
    Title = MAP_NAME,
    SubTitle = "by vaderhug",
    TabWidth = 180,
    Size = UDim2.fromOffset(600, 460),
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl,
})
Env.VaderMapStarter = VaderUI

local function notify(message)
    VaderUI:Notify({ Title = MAP_NAME, Content = tostring(message), Duration = 3 })
end

-- Register your own event connections here so closing/reloading disconnects them.
local function track(connection)
    table.insert(Connections, connection)
    return connection
end
local originalDestroy = VaderUI.Destroy
function VaderUI:Destroy()
    if closed then return end
    pcall(saveProfile)
    closed = true
    State.AutoFarm, State.AutoRebirth, State.AutoHatch, State.AutoDelete = false, false, false, false
    for _, connection in ipairs(Connections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(Connections)
    if Env.VaderMapStarter == self then Env.VaderMapStarter = nil end
    originalDestroy(self)
end

---------------------------------------------------------------- game hooks
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = game:GetService("Players").LocalPlayer
local Net = ReplicatedStorage:WaitForChild("SkippingNetwork")
local Request = Net:WaitForChild("Request")
local GameEvent = Net:WaitForChild("Event")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameBalance = require(Shared.Config.GameBalance)
local GiftRewards = require(Shared.Util.GiftRewards)
local DailyRewards = require(Shared.Util.DailyRewards)
local LaunchZone = require(Shared.Util.LaunchZone)
local Worlds = require(Shared.Config.Worlds)
local WorldUnlocks = require(Shared.Util.WorldUnlocks)
local PetIndex = require(Shared.Util.PetIndex)
local Progression = require(Shared.Util.Progression)
local Trajectory = require(Shared.Util.Trajectory)
local TrailCatalog = require(Shared.Util.TrailCatalog)
local okCatalog, PetCatalogData = pcall(function()
    return require(Shared.Util.PetCatalog).Read(ReplicatedStorage.Assets.Pets, GameBalance.PetFusion)
end)
local okFormat, NumberFormat = pcall(require, Shared.Util.NumberFormat)

local Live = nil
local Session = { Throws = 0, Wins = 0, Hatches = 0, Deleted = 0, LastDelete = "-", Started = os.clock() }
local lastHatch = nil
local lastCodeResult = nil
local moving = false -- true while an errand (hatch, stone, rebirth, equip, delete) has the character
local zoneBlocked = {} -- zone name -> os.clock() until which the server refused it
local lastZoneTp = { Name = nil, At = 0 }

local function send(action, payload) Request:FireServer(action, payload) end
local function compact(n)
    if okFormat and type(NumberFormat) == "table" and NumberFormat.Compact then
        local ok, s = pcall(NumberFormat.Compact, n)
        if ok then return s end
    end
    return tostring(n)
end
local function duration(seconds)
    if seconds ~= seconds or seconds == math.huge then return "forever" end
    if seconds < 90 then return string.format("%ds", math.max(0, math.ceil(seconds))) end
    if seconds < 5400 then return string.format("%dm", math.ceil(seconds / 60)) end
    return string.format("%.1fh", seconds / 3600)
end
local function activity() return LP:GetAttribute("SkippingActivity") or (Live and Live.Activity) or "Idle" end
local function serverNow() return workspace:GetServerTimeNow() end
local function root()
    local character = LP.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end
local function tp(position)
    local hrp = root()
    if hrp then
        hrp.CFrame = CFrame.new(position)
        hrp.AssemblyLinearVelocity = Vector3.zero
    end
end
local function worldModel()
    local worlds = workspace:FindFirstChild("SkippingWorlds")
    if not worlds then return nil end
    return worlds:FindFirstChild(LP:GetAttribute("SkippingWorld") or "World1") or worlds:FindFirstChildWhichIsA("Model")
end

-- The client cancels any throw it did not start itself, so throws go through the game's own beginThrow.
local beginThrow
local function getBeginThrow()
    if beginThrow or type(getgc) ~= "function" then return beginThrow end
    for _, fn in ipairs(getgc(false)) do
        if type(fn) == "function" and (not islclosure or islclosure(fn)) then
            local ok, name = pcall(debug.info, fn, "n")
            if ok and name == "beginThrow" then
                local source = debug.info(fn, "s")
                if source and source:find("GameplayController") then
                    beginThrow = fn
                    break
                end
            end
        end
    end
    return beginThrow
end

-- State packets leave out collections (OwnedStones, Pets, ...) that did not change, so the
-- complete state is read from the game's own merged table (an upvalue of canThrow).
local stateHolder, stateIndex
local function gameState()
    if not stateHolder and type(debug.getupvalues) == "function" then
        local throw = getBeginThrow()
        for _, upvalue in pairs(throw and debug.getupvalues(throw) or {}) do
            if type(upvalue) == "function" then
                for index, value in pairs(debug.getupvalues(upvalue)) do
                    if type(value) == "table" and rawget(value, "TutorialStep") ~= nil and rawget(value, "Wins") ~= nil then
                        stateHolder, stateIndex = upvalue, index
                    end
                end
            end
        end
    end
    if stateHolder then
        local ok, value = pcall(debug.getupvalue, stateHolder, stateIndex)
        if ok and type(value) == "table" then return value end
    end
    return nil
end
local Merged = {}

track(GameEvent.OnClientEvent:Connect(function(kind, data)
    if type(data) ~= "table" then return end
    if kind == "State" then
        for key, value in pairs(data) do Merged[key] = value end
        Live = Merged
        task.defer(function() Live = gameState() or Merged end)
    elseif kind == "ThrowFinished" and data.UserId == LP.UserId then
        Session.Throws += 1
        Session.Wins += tonumber(data.Wins) or 0
    elseif kind == "HatchResult" then
        lastHatch = data
        if data.Success then Session.Hatches += 1 end
    elseif kind == "CodeResult" then
        lastCodeResult = data
    elseif kind == "Notice" and data.Success == false and tostring(data.Message):lower():find("train here")
        and lastZoneTp.Name and os.clock() - lastZoneTp.At < 4 then
        -- e.g. "Requires 2 rebirths to train here." -> skip that zone for a while
        zoneBlocked[lastZoneTp.Name] = os.clock() + 120
        lastZoneTp.Name = nil
    end
end))
send("Sync")

---------------------------------------------------------------- world, zones, throw math
local function worldId() return LP:GetAttribute("SkippingWorld") or "World1" end
local function worldConfig() return Worlds.ById[worldId()] or Worlds.ById.World1 end
local function nextWorldLocked()
    local nextWorld = worldConfig().NextWorldId
    return nextWorld ~= nil and Live ~= nil and not WorldUnlocks.IsUnlocked(Live, nextWorld), nextWorld
end

-- Distance comes from total skill through the world's throw level curve (same math as Trajectory.Plan).
local function throwLevel(skill)
    local ok, level = pcall(Progression.Get, skill or 0, worldConfig().Throw.Progression)
    return ok and level or 1
end
local function distanceForLevel(level)
    local config = worldConfig().Throw
    local step, base, previous = math.max(0, level - 1), config.BaseDistance, 1
    for i, milestone in ipairs(config.DistanceMilestones) do
        if step + 1 <= milestone.Level or i == #config.DistanceMilestones then
            return base + (milestone.Distance - base) * ((step + 1 - previous) / (milestone.Level - previous))
        end
        previous, base = milestone.Level, milestone.Distance
    end
    return base
end
local function portalDistance()
    local milestones = worldConfig().Throw.DistanceMilestones
    return milestones[#milestones].Distance
end
local function zoneAt(distance)
    local current
    for _, zone in ipairs(worldConfig().Zones) do
        if zone.Start <= distance then current = zone end
    end
    return current
end
local function skillForDistance(distance)
    local config = worldConfig().Throw
    return Progression.Threshold(Trajectory.LevelForDistance(distance, config), config.Progression)
end
local function currentDistance()
    return math.min(distanceForLevel(throwLevel(Live and Live.TotalSkill or 0)), portalDistance())
end

-- Training zones, best bonus first. Bonuses and rebirth requirements differ per world.
local function zoneBonus(name)
    local practice = worldConfig().Practice
    local event = practice.EventZones and practice.EventZones[name]
    return practice.ZoneBonuses[event and event.BonusOf or name] or 0
end
local function findZone(name)
    local world = worldModel()
    local zones = world and world:FindFirstChild("TrainingZones")
    return (zones and zones:FindFirstChild(name)) or (world and world:FindFirstChild(name, true))
end
local function zoneNames()
    local practice = worldConfig().Practice
    local names = {}
    for name in pairs(practice.ZoneRequiredRebirths) do table.insert(names, name) end
    -- Event zones (the Hacker zone during Hacker weather) only exist while the event runs.
    for name in pairs(practice.EventZones or {}) do
        if findZone(name) then table.insert(names, name) end
    end
    table.sort(names, function(a, b) return zoneBonus(a) > zoneBonus(b) end)
    return names
end
local function zoneUnlocked(name)
    if (zoneBlocked[name] or 0) > os.clock() then return false end
    local events = worldConfig().Practice.EventZones
    if events and events[name] then return true end
    if not Live then return name == "TrainingZone" end
    local owned = Live.OwnedTrainingZones or {}
    if owned[name] or table.find(owned, name) then return true end
    if GameBalance.TrainingPasses[name] then return false end
    local rebirths = (Live.Rebirths or 0) + (Live.BonusRebirths or 0)
    return rebirths >= (worldConfig().Practice.ZoneRequiredRebirths[name] or math.huge)
end
local function pickZone()
    if State.TrainZone ~= "Best Unlocked" then return State.TrainZone end
    for _, name in ipairs(zoneNames()) do
        if zoneUnlocked(name) then return name end
    end
    return "TrainingZone"
end
local function standPosition(name)
    local zone = findZone(name)
    local stand = zone and zone:FindFirstChild("TrainingStand", true)
    return stand and stand.Position + Vector3.new(0, 3, 0)
end

---------------------------------------------------------------- stones, trails
local StoneById = {}
for _, stone in ipairs(GameBalance.Stones) do StoneById[stone.Id] = stone end
local function bestOwnedStoneMultiplier()
    local best = 0
    for id in pairs((Live and Live.OwnedStones) or {}) do
        local stone = StoneById[id]
        if stone and not stone.ProductId then best = math.max(best, stone.Multiplier or 1) end
    end
    return best
end
local function bestAffordableStone()
    if not Live then return nil end
    local owned, wins, bestOwned = Live.OwnedStones or {}, Live.Wins or 0, bestOwnedStoneMultiplier()
    local pick
    for _, id in ipairs(worldConfig().StoneIds or {}) do
        local stone = StoneById[id]
        if stone and not stone.ProductId and not owned[id] and (stone.Price or math.huge) <= wins
            and (stone.Multiplier or 0) > bestOwned and (not pick or stone.Multiplier > pick.Multiplier) then
            pick = stone
        end
    end
    return pick
end
local function worldStonesDone()
    local owned = (Live and Live.OwnedStones) or {}
    for _, id in ipairs(worldConfig().StoneIds or {}) do
        local stone = StoneById[id]
        if stone and not stone.ProductId and not owned[id] then return false end
    end
    return true
end
local function stonePrompt(id)
    local world = worldModel()
    local shop = world and world:FindFirstChild("StoneShop")
    local displays = shop and shop:FindFirstChild("Displays")
    local display = displays and displays:FindFirstChild(id)
    return display and display:FindFirstChild("StonePrompt", true)
end

local TrailById = {}
for _, trail in ipairs(GameBalance.Trails) do TrailById[trail.Id] = trail end
local function bestOwnedTrail()
    local bestId, bestMultiplier = nil, 0
    for id, owned in pairs((Live and Live.OwnedTrails) or {}) do
        local trail = TrailById[id]
        if owned and trail and trail.WinsMultiplier > bestMultiplier then bestId, bestMultiplier = id, trail.WinsMultiplier end
    end
    return bestId
end
-- Trails cost wins, multiply wins, and the server allows buying them mid-throw.
local function upgradeTrail()
    if not Live then return false end
    local changed = false
    local buy = TrailCatalog.BestUpgrade(GameBalance.Trails, Live.OwnedTrails or {}, Live.Wins or 0)
    if buy then
        send("BuyTrail", { Id = buy })
        notify("Buying " .. TrailById[buy].Name .. " (x" .. TrailById[buy].WinsMultiplier .. " wins)")
        task.wait(0.6)
        Live = gameState() or Live
        changed = true
    end
    local best = bestOwnedTrail()
    if best and Live.EquippedTrail ~= best then
        send("SetTrail", { Id = best, Equipped = true })
        changed = true
    end
    return changed
end

---------------------------------------------------------------- eggs, pets
local function eggPrompt(name)
    local world = worldModel()
    local displays = world and world:FindFirstChild("EggShop") and world.EggShop:FindFirstChild("Displays")
    local display = displays and displays:FindFirstChild(name)
    return display and display:FindFirstChild("EggPrompt", true)
end
-- Wins eggs carry their price ("Wins") and tier ("DisplayOrder") as attributes; robux eggs have neither.
local function eggDisplays()
    local world = worldModel()
    local shop = world and world:FindFirstChild("EggShop")
    local displays = shop and shop:FindFirstChild("Displays")
    local list = {}
    for _, display in ipairs(displays and displays:GetChildren() or {}) do
        if type(display:GetAttribute("Wins")) == "number" then table.insert(list, display) end
    end
    table.sort(list, function(a, b) return (a:GetAttribute("DisplayOrder") or 0) < (b:GetAttribute("DisplayOrder") or 0) end)
    return list
end
-- Every wins egg in the game, from each world's config (robux eggs left out). Prices only exist on the
-- loaded world's displays, and the server makes you stand next to the egg, so hatching uses the current world.
local PremiumEggIds = {}
for _, offer in ipairs(GameBalance.PremiumEggs or {}) do PremiumEggIds[offer.EggId] = true end
local EggOptions, EggByLabel = {}, {}
for index, world in ipairs(Worlds.Definitions) do
    for _, id in ipairs(world.EggIds or {}) do
        if not PremiumEggIds[id] then
            local origin = GameBalance.PetIndex.Origins and GameBalance.PetIndex.Origins[id]
            local name = origin and origin:gsub(" Egg$", "") or id:gsub("(%l)(%u)", "%1 %2")
            local label = name .. " · W" .. index
            table.insert(EggOptions, label)
            EggByLabel[label] = { Id = id, World = world.Id }
        end
    end
end
local function selectedEggIds()
    local ids, any = {}, false
    for label, on in pairs(State.Eggs) do
        local egg = on and EggByLabel[label]
        if egg then ids[egg.Id], any = egg.World, true end
    end
    return ids, any
end
local function eggPrice(name)
    for _, display in ipairs(eggDisplays()) do
        if display.Name == name then return display:GetAttribute("Wins") end
    end
    return math.huge
end
-- Highest-tier affordable egg in this world among the selected ones (nothing selected = every egg).
local function pickEgg()
    local ids, any = selectedEggIds()
    local wins, best = (Live and Live.Wins) or 0, nil
    for _, display in ipairs(eggDisplays()) do
        if (not any or ids[display.Name]) and display:GetAttribute("Wins") <= wins then best = display.Name end
    end
    return best
end
-- What Auto Hatch will do next, for the Eggs tab.
local function eggStatus()
    local egg = pickEgg()
    if egg then return egg .. " (" .. compact(eggPrice(egg)) .. " wins)" end
    local ids, any = selectedEggIds()
    local here = false
    for _, display in ipairs(eggDisplays()) do
        if not any or ids[display.Name] then here = true end
    end
    if any and not here then
        local worlds, list = {}, {}
        for _, world in pairs(ids) do worlds[world] = true end
        for world in pairs(worlds) do table.insert(list, world) end
        table.sort(list)
        return "picked eggs are in " .. table.concat(list, "/") .. " (hatching needs you there)"
    end
    return "not enough wins yet"
end

-- Hatched pets start "Discovered"; they only count toward the index once revealed (the game batches 50).
local function discoveredPets()
    local ids = {}
    for id, stage in pairs((Live and Live.PetIndex) or {}) do
        if stage == PetIndex.Discovered then
            table.insert(ids, id)
            if #ids >= 50 then break end
        end
    end
    return ids
end
local function petIndexClaimable()
    if not (Live and okCatalog and Live.PetIndex) then return 0 end
    local config = GameBalance.PetIndex
    local ok, count = pcall(PetIndex.RevealedCount, Live.PetIndex, PetCatalogData.ById, config)
    if not ok then return 0 end
    return PetIndex.Claimable(count, Live.PetIndexClaimed or 0, config)
end

local function petEntry(pet) return okCatalog and PetCatalogData.ById[pet.PetId] or nil end
local function petPower(pet)
    local entry = petEntry(pet)
    return pet.Power or (entry and entry.SkillMultiplier) or 0
end
local RarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "Divine", "Ascended", "Eternal",
    "Celestial", "Transcendent", "Empyrean", "Primordial", "Titan", "Infinity", "Oracle", "Arcane", "Eldritch", "Rainbow", "Exclusive" }
local function rarityList()
    local present = {}
    for _, entry in pairs(okCatalog and PetCatalogData.ById or {}) do
        if entry.Rarity then present[entry.Rarity] = true end
    end
    local list = {}
    for _, name in ipairs(RarityOrder) do
        if present[name] then table.insert(list, name) present[name] = nil end
    end
    for name in pairs(present) do table.insert(list, name) end
    return list
end
-- Pets that match the delete filters. Equipped pets and the strongest N are never touched.
local function junkPets()
    if not (Live and okCatalog and Live.Pets) then return {} end
    local equipped = {}
    for _, id in ipairs(Live.EquippedPets or {}) do equipped[id] = true end
    local teamWeakest = math.huge
    for _, pet in ipairs(Live.Pets) do
        if equipped[pet.Id] then teamWeakest = math.min(teamWeakest, petPower(pet)) end
    end
    if teamWeakest == math.huge then teamWeakest = 0 end -- no team equipped: "only weaker" protects everything
    local sorted = table.clone(Live.Pets)
    table.sort(sorted, function(a, b) return petPower(a) > petPower(b) end)
    local keep = {}
    for i = 1, math.min(State.KeepBest, #sorted) do keep[sorted[i].Id] = true end
    local ids = {}
    for _, pet in ipairs(Live.Pets) do
        local entry = petEntry(pet)
        if entry and not equipped[pet.Id] and not keep[pet.Id] and State.DeleteRarities[entry.Rarity]
            and not (State.KeepVariants and entry.Variant and entry.Variant ~= "Normal")
            and not (State.DeleteOnlyWeaker and petPower(pet) >= teamWeakest) then
            table.insert(ids, pet.Id)
        end
    end
    return ids
end

---------------------------------------------------------------- errands
local function loop(interval, body)
    task.spawn(function()
        while not closed do
            local ok, err = pcall(body)
            if not ok then warn("[" .. MAP_NAME .. "] " .. tostring(err)) end
            task.wait(type(interval) == "function" and interval() or interval)
        end
    end)
end
local function stopPractice()
    if activity() ~= "Practice" then return end
    send("StopPractice")
    local started = os.clock()
    repeat task.wait(0.05) until activity() ~= "Practice" or os.clock() - started > 3
end
-- Pause the farm loops, let the current throw land (and leave training unless allowed), then run fn.
local function errand(fn, allowPractice)
    while moving do task.wait(0.05) end
    moving = true
    local deadline = os.clock() + 25
    while activity() == "Throw" and os.clock() < deadline do task.wait(0.05) end
    if not allowPractice then stopPractice() end
    local act = activity()
    local ok, err = true, nil
    if act == "Idle" or (allowPractice and act == "Practice") then ok, err = pcall(fn) end
    moving = false
    if not ok then warn("[" .. MAP_NAME .. "] " .. tostring(err)) end
end
local function goToLaunch()
    local zone = worldModel() and worldModel():FindFirstChild("LaunchZone")
    if zone and not LaunchZone.Contains(LP.Character) then
        tp(zone.Position + Vector3.new(0, 3, 0))
        task.wait(0.3) -- let the server see the new position before throwing
    end
end
local function travelTo(target)
    errand(function()
        send("TravelWorld", target)
        local started = os.clock()
        repeat task.wait(0.1) until worldId() == target or os.clock() - started > 8
        task.wait(1) -- let the new world's map load before the farm loops look for it
    end)
end
local function rebirthPaused()
    if not State.PauseRebirthForWorld then return false end
    return nextWorldLocked() and worldStonesDone()
end
local function deleteJunk()
    local ids = junkPets()
    if #ids == 0 then return 0 end
    local before = Live and #Live.Pets or 0
    errand(function()
        for start = 1, #ids, 50 do
            send("PetEquipment", { Kind = "DeleteSelected", Ids = table.move(ids, start, math.min(start + 49, #ids), 1, {}) })
            task.wait(0.4)
        end
        task.wait(0.4)
    end)
    Live = gameState() or Live
    local removed = math.max(0, before - (Live and #Live.Pets or before))
    Session.Deleted += removed
    Session.LastDelete = removed .. " at " .. os.date("%H:%M")
    return removed
end

---------------------------------------------------------------- farm brain
-- Smart: train while the next zone (more wins per throw) or the next-world portal is close,
-- otherwise throw for wins. Uses the game's own distance math and your live training rate.
local Smart = { Want = "Train", Reason = "waiting for state" }
local function smartDecide()
    if not Live then return "Train", "waiting for state" end
    local distance = currentDistance()
    local locked, nextWorld = nextWorldLocked()
    if locked and distance >= portalDistance() then
        return "Throw", "portal in reach, throwing to unlock " .. nextWorld
    end
    local target, label
    for _, zone in ipairs(worldConfig().Zones) do
        if zone.Start > distance then target, label = zone.Start, zone.Name .. " (" .. compact(zone.Wins) .. " wins)" break end
    end
    if not target and locked then target, label = portalDistance(), nextWorld .. " portal" end
    if not target then return "Throw", "max distance in this world" end
    local seconds = (skillForDistance(target) - (Live.TotalSkill or 0)) / math.max(Live.TrainingRate or 0, 1)
    if seconds <= State.SmartWindow then
        return "Train", label .. " after " .. duration(seconds) .. " of training"
    end
    return "Throw", label .. " needs " .. duration(seconds) .. " of training"
end
local function farmWants()
    if not State.AutoFarm then return nil end
    if State.FarmMode == "Throw" or State.FarmMode == "Train" then return State.FarmMode end
    return Smart.Want
end
local function farming() return State.AutoFarm end

---------------------------------------------------------------- tabs
local Tabs = {
    Main = Window:AddTab({ Title = "Main" }),
    Upgrades = Window:AddTab({ Title = "Upgrades" }),
    Eggs = Window:AddTab({ Title = "Eggs" }),
    Pets = Window:AddTab({ Title = "Pets" }),
    Rewards = Window:AddTab({ Title = "Rewards" }),
    Teleport = Window:AddTab({ Title = "Teleport" }),
    Settings = Window:AddTab({ Title = "Settings" }),
}

-- Main
local FarmSection = Tabs.Main:AddSection("Auto Farm")
FarmSection:AddToggle("AutoFarm", {
    Title = "Auto Farm", Default = false,
    Description = "Earns skill and wins without stopping.",
    Callback = function(value)
        State.AutoFarm = value
        if not value and activity() == "Practice" then send("StopPractice") end
    end,
})
FarmSection:AddDropdown("FarmMode", {
    Title = "Farm Mode", Values = { "Smart", "Train", "Throw" }, Default = "Smart", Multi = false,
    Description = "Smart: trains while a better zone or the next world is close, otherwise throws for wins.",
    Callback = function(value) State.FarmMode = value end,
})
FarmSection:AddSlider("SmartWindow", {
    Title = "Smart: Train If Next Zone Within (s)", Default = 60, Min = 10, Max = 600, Rounding = 0,
    Callback = function(value) State.SmartWindow = value end,
})
local zoneValues = { "Best Unlocked" }
for _, name in ipairs(zoneNames()) do table.insert(zoneValues, name) end
FarmSection:AddDropdown("TrainZone", {
    Title = "Training Zone", Values = zoneValues, Default = "Best Unlocked", Multi = false,
    Description = "Best Unlocked follows new unlocks and event zones automatically.",
    Callback = function(value) State.TrainZone = value end,
})
local StatusLabel = FarmSection:AddParagraph({ Title = "Status", Content = "Waiting for server state..." })

local RebirthSection = Tabs.Main:AddSection("Rebirth & Worlds")
RebirthSection:AddToggle("AutoRebirth", {
    Title = "Auto Rebirth", Default = false,
    Description = "Rebirths as soon as your level is high enough.",
    Callback = function(value) State.AutoRebirth = value end,
})
RebirthSection:AddToggle("AutoWorld", {
    Title = "Auto Next World", Default = false,
    Description = "Moves to your highest unlocked world as soon as it unlocks.",
    Callback = function(value) State.AutoWorld = value end,
})
RebirthSection:AddToggle("PauseRebirthForWorld", {
    Title = "Pause Rebirth for Next World", Default = true,
    Description = "Once this world's stones are all bought, stop rebirthing so skill builds up to reach the portal.",
    Callback = function(value) State.PauseRebirthForWorld = value end,
})

local Performance = Tabs.Main:AddSection("Performance")
local function setGameSetting(name, value)
    local current = Live and Live.Settings and Live.Settings[name]
    if current ~= value then send("UpdateSetting", { Name = name, Value = value }) end
end
Performance:AddToggle("LowGraphics", {
    Title = "Low Graphics (more FPS)", Default = false,
    Description = "Uses the game's own settings: effects off, other pets hidden.",
    Callback = function(value)
        -- Ignore the initial "off" so the player's own game settings are left alone.
        if not value and not State.LowGraphics then return end
        State.LowGraphics = value
        setGameSetting("EffectsEnabled", not value)
        setGameSetting("HideAllPetsEnabled", value)
    end,
})

-- Upgrades
local StoneSection = Tabs.Upgrades:AddSection("Stones")
StoneSection:AddToggle("AutoStone", {
    Title = "Auto Buy Best Stone", Default = false,
    Description = "Buys the strongest stone you can afford (skill multiplier). Buying also equips it.",
    Callback = function(value) State.AutoStone = value end,
})
local TrailSection = Tabs.Upgrades:AddSection("Trails")
TrailSection:AddToggle("AutoTrail", {
    Title = "Buy Trails", Default = false,
    Description = "Buys and equips the best trail you can afford (wins multiplier). Works mid-throw.",
    Callback = function(value) State.AutoTrail = value end,
})
local BoostSection = Tabs.Upgrades:AddSection("Auto Use Boosts (Potions)")
BoostSection:AddToggle("AutoBoosts", {
    Title = "Auto Use Boosts", Default = false,
    Description = "Uses a potion whenever that boost runs out.",
    Callback = function(value) State.AutoBoosts = value end,
})
BoostSection:AddDropdown("Boosts", {
    Title = "Selected Boosts", Values = { "Skill", "Win", "Luck" }, Default = { "Skill", "Win", "Luck" }, Multi = true,
    Callback = function(value) State.Boosts = value end,
})
State.Boosts = { Skill = true, Win = true, Luck = true }

-- Eggs
local EggSection = Tabs.Eggs:AddSection("Hatching")
EggSection:AddToggle("AutoHatch", {
    Title = "Auto Hatch", Default = false,
    Description = "Hatches the best selected egg you can afford, at the server's cooldown (~0.8s).",
    Callback = function(value) State.AutoHatch = value end,
})
EggSection:AddDropdown("Eggs", {
    Title = "Eggs (none = all)", Values = EggOptions, Default = {}, Multi = true,
    Description = "Every egg in the game (W = world). Hatches the highest picked egg you can afford in the world you're in.",
    Callback = function(value) State.Eggs = value end,
})
local EggStatus = EggSection:AddParagraph({ Title = "Hatching", Content = "-" })
EggSection:AddToggle("MultiHatch", {
    Title = "Multi Hatch", Default = true,
    Description = "Hatch your max at once (2 free, more with multi-hatch passes). Off = 1 egg.",
    Callback = function(value) State.MultiHatch = value end,
})
EggSection:AddSlider("HatchesPerTrip", {
    Title = "Hatches Per Trip", Default = 10, Min = 1, Max = 50, Rounding = 0,
    Description = "While Auto Farm is on: hatches per visit before going back to farm.",
    Callback = function(value) State.HatchesPerTrip = value end,
})
EggSection:AddSlider("FarmBetweenTrips", {
    Title = "Farm Seconds Between Trips", Default = 10, Min = 0, Max = 120, Rounding = 0,
    Description = "While Auto Farm is on: how long to farm before the next hatch trip.",
    Callback = function(value) State.FarmBetweenTrips = value end,
})
EggSection:AddToggle("OpenInventoryEggs", {
    Title = "Open Inventory Eggs", Default = false,
    Description = "Opens eggs sitting in your inventory (from gifts, codes, daily rewards).",
    Callback = function(value) State.OpenInventoryEggs = value end,
})

-- Pets
local DeleteSection = Tabs.Pets:AddSection("Auto Delete Pets")
DeleteSection:AddToggle("AutoDelete", {
    Title = "Auto Delete Pets", Default = false,
    Description = "Deletes pets that match the filters below. Equipped pets are never deleted.",
    Callback = function(value) State.AutoDelete = value end,
})
DeleteSection:AddDropdown("DeleteRarities", {
    Title = "Delete Rarities", Values = rarityList(), Default = { "Common", "Uncommon" }, Multi = true,
    Callback = function(value) State.DeleteRarities = value end,
})
DeleteSection:AddToggle("DeleteOnlyWeaker", {
    Title = "Only Weaker Than My Team", Default = true,
    Description = "Only delete pets weaker than your weakest equipped pet.",
    Callback = function(value) State.DeleteOnlyWeaker = value end,
})
DeleteSection:AddToggle("KeepVariants", {
    Title = "Keep Golden, Diamond and Void", Default = true,
    Callback = function(value) State.KeepVariants = value end,
})
DeleteSection:AddSlider("KeepBest", {
    Title = "Always Keep Best", Default = 10, Min = 0, Max = 100, Rounding = 0,
    Description = "Your strongest N pets are never deleted.",
    Callback = function(value) State.KeepBest = value end,
})
local DeleteStats = DeleteSection:AddParagraph({ Title = "Delete Statistics", Content = "Deleted: 0" })
local IndexSection = Tabs.Pets:AddSection("Pet Index")
IndexSection:AddToggle("AutoPetIndex", {
    Title = "Auto Reveal + Claim Pet Index", Default = false,
    Description = "Reveals newly hatched pets so they count, then claims the luck bonus (+1% per 10).",
    Callback = function(value) State.AutoPetIndex = value end,
})

-- Rewards
local RewardSection = Tabs.Rewards:AddSection("Auto Claim")
RewardSection:AddToggle("AutoGifts", {
    Title = "Auto Claim Playtime Gifts", Default = false,
    Callback = function(value) State.AutoGifts = value end,
})
RewardSection:AddToggle("AutoDaily", {
    Title = "Auto Claim Daily Reward", Default = false,
    Callback = function(value) State.AutoDaily = value end,
})
RewardSection:AddToggle("AutoOffline", {
    Title = "Auto Claim Offline Earnings", Default = false,
    Callback = function(value) State.AutoOffline = value end,
})
-- Codes: read the list from tryhardguides in-game, redeem the ones not tried yet, remember the results.
local CODES_URL = "https://tryhardguides.com/1-stone-skipping-codes/"
-- Active codes on that page when this was written; used if the page can't be fetched or parsed.
local FALLBACK_CODES = { "40MVISITS", "30MVISITS", "2MGROUP", "40KLIKES", "1MFAV", "20MVISITS", "3KMEMBERS", "2KSPECIAL",
    "500KFAV", "10MVISITS", "10KLIKES", "50KCCU", "40KCCU", "WORLD5", "SECRET", "10KCCU", "5KCCU", "WORLD4", "WELCOME" }
local codesFile = "Vaderhug/1StoneSkipping/" .. LP.Name .. "_codes.json"
local CodeLog = {} -- code -> the server's answer; codes in here are not sent again
pcall(function()
    if isfile and isfile(codesFile) then CodeLog = game:GetService("HttpService"):JSONDecode(readfile(codesFile)) end
end)
local function saveCodeLog()
    pcall(function()
        if not isfolder("Vaderhug") then makefolder("Vaderhug") end
        if not isfolder("Vaderhug/1StoneSkipping") then makefolder("Vaderhug/1StoneSkipping") end
        writefile(codesFile, game:GetService("HttpService"):JSONEncode(CodeLog))
    end)
end
local function fetchCodes()
    local ok, html = pcall(game.HttpGet, game, CODES_URL)
    if not ok or type(html) ~= "string" then return FALLBACK_CODES, "site unreachable, used built-in list" end
    -- Only the "Active ... Codes" list, not the expired one or the tips further down.
    local first = html:find("Active[^<]*Codes")
    local last = first and html:find("Expired[^<]*Codes", first)
    local codes = {}
    for code in html:sub(first or 1, last or #html):gmatch("<li[^>]*>%s*<strong>%s*([^<]-)%s*</strong>") do
        if code:match("^[%w_%-]+$") and not table.find(codes, code) then table.insert(codes, code) end
    end
    if #codes == 0 then return FALLBACK_CODES, "no codes found on the page, used built-in list" end
    return codes, #codes .. " active codes on the site"
end
local codeBusy, codeSummary = false, "Not checked yet."
local function redeemCode(code)
    lastCodeResult = nil
    local sentAt = os.clock()
    send("RedeemCode", code)
    repeat task.wait(0.05) until lastCodeResult or os.clock() - sentAt > 4
    return lastCodeResult
end
local function redeemAllCodes()
    if codeBusy then return end
    codeBusy = true
    local codes, source = fetchCodes()
    local tried, redeemed, names = 0, 0, {}
    for _, code in ipairs(codes) do
        if CodeLog[code] == nil and not closed then
            local result = redeemCode(code)
            local message = result and tostring(result.Message) or ""
            -- Remember the answer unless the server asked us to slow down (or never answered).
            if result and not message:lower():find("wait") and not message:lower():find("try again") then
                CodeLog[code] = message
                tried += 1
                if result.Success then
                    redeemed += 1
                    table.insert(names, code)
                end
            end
            task.wait(1)
        end
    end
    saveCodeLog()
    codeBusy = false
    codeSummary = string.format("Last check %s: %s. New tried: %d, redeemed: %d%s", os.date("%H:%M"), source, tried, redeemed,
        #names > 0 and " (" .. table.concat(names, ", ") .. ")" or "")
    if redeemed > 0 then notify("Redeemed " .. redeemed .. " code(s): " .. table.concat(names, ", ")) end
end

local CodeSection = Tabs.Rewards:AddSection("Codes")
CodeSection:AddToggle("AutoCodes", {
    Title = "Auto Redeem Codes", Default = false,
    Description = "Checks tryhardguides.com every 15 min and redeems any new code.",
    Callback = function(value) State.AutoCodes = value end,
})
local CodeStatus = CodeSection:AddParagraph({ Title = "Code Status", Content = codeSummary })
local nextCodeCheck = 0
loop(5, function()
    CodeStatus:SetDesc(codeSummary)
    if State.AutoCodes and os.clock() >= nextCodeCheck then
        nextCodeCheck = os.clock() + 900
        redeemAllCodes()
    end
end)

-- Teleport
local Places = Tabs.Teleport:AddSection("Places")
Places:AddButton({
    Title = "Launch Zone",
    Callback = function()
        local zone = worldModel() and worldModel():FindFirstChild("LaunchZone")
        if zone then tp(zone.Position + Vector3.new(0, 3, 0)) end
    end,
})
Places:AddButton({
    Title = "Best Training Stand",
    Callback = function()
        local position = standPosition(pickZone())
        if position then tp(position) end
    end,
})
Places:AddButton({
    Title = "Egg Shop",
    Callback = function()
        local first = eggDisplays()[1]
        local prompt = eggPrompt(pickEgg() or (first and first.Name) or "Common")
        if prompt and prompt.Parent:IsA("Attachment") then tp(prompt.Parent.WorldPosition + Vector3.new(0, 1, 0)) end
    end,
})
Places:AddButton({
    Title = "Stone Shop",
    Callback = function()
        local shop = worldModel() and worldModel():FindFirstChild("StoneShop")
        if shop then tp(shop:GetPivot().Position + Vector3.new(0, 5, 0)) end
    end,
})
local Travel = Tabs.Teleport:AddSection("Worlds")
Travel:AddDropdown("World", {
    Title = "World", Values = { "World1", "World2", "World3", "World4", "World5", "World6" }, Default = "World1", Multi = false,
    Callback = function(value) State.World = value end,
})
Travel:AddButton({
    Title = "Travel", Description = "World must already be unlocked.",
    Callback = function() task.spawn(travelTo, State.World) end,
})

---------------------------------------------------------------- workers
-- Smart brain: re-decide every second.
loop(1, function()
    if State.AutoFarm and State.FarmMode == "Smart" then
        Smart.Want, Smart.Reason = smartDecide()
    end
end)

-- Throw: checks every 0.05s so the next throw goes out the moment the 0.8s cooldown ends.
loop(0.05, function()
    if farmWants() ~= "Throw" or moving then return end
    local act = activity()
    if act == "Practice" then
        stopPractice()
    elseif act == "Idle" then
        goToLaunch()
        local throw = getBeginThrow()
        if throw then throw() end
    end
end)

-- Train: stand on the best stand; the server keeps practising while you're on it.
loop(0.3, function()
    if farmWants() ~= "Train" or moving then return end
    local act = activity()
    if act == "Throw" then return end
    local zone = pickZone()
    local position = standPosition(zone)
    local hrp = root()
    if position and hrp and (act ~= "Practice" or (hrp.Position - position).Magnitude > 6) then
        lastZoneTp.Name, lastZoneTp.At = zone, os.clock()
        tp(position)
        task.wait(0.5)
    end
end)

-- Rebirth (the game allows rebirthing while training)
loop(0.5, function()
    if not State.AutoRebirth or not Live or rebirthPaused() then return end
    if (Live.Level or 0) >= (Live.NextRebirthLevel or math.huge) and (Live.Rebirths or 0) < GameBalance.Rebirth.MaxRebirths then
        errand(function() send("Rebirth", Live.Rebirths) end, true)
        task.wait(2)
    end
end)

-- Hatch. Server rules (measured): stand next to the egg, not throwing or training,
-- and one hatch per ~0.75s ("Please wait before hatching again" otherwise; rejections don't extend it).
local HATCH_COOLDOWN = 0.8
local hatchId = 50000
local hatchPausedUntil = 0
local function hatchCount(egg)
    -- Use the full multi-hatch only when every egg in it is affordable.
    local count = State.MultiHatch and math.max(1, (Live and Live.MultiHatchCount) or GameBalance.MultiHatch.BaseCount) or 1
    if count > 1 and eggPrice(egg) * count > ((Live and Live.Wins) or 0) then count = 1 end
    return count
end
loop(0.1, function()
    if not State.AutoHatch or os.clock() < hatchPausedUntil then return end
    local first = pickEgg()
    if not (first and eggPrompt(first) and root()) then return end
    errand(function()
        local hrp = root()
        local back = hrp.CFrame
        -- When farming, come back after a few hatches; otherwise stay, but release the errand
        -- lock now and then so stones / rebirth / deletes still get a turn.
        local limit = farming() and State.HatchesPerTrip or 40
        local done, nextAt, misses = 0, 0, 0
        while done < limit and State.AutoHatch and not closed do
            local egg = pickEgg()
            local prompt = egg and eggPrompt(egg)
            if not (prompt and prompt.Parent:IsA("Attachment")) then break end
            local spot = prompt.Parent.WorldPosition + Vector3.new(0, 1, 0)
            if (hrp.Position - spot).Magnitude > 4 or misses > 0 then
                tp(spot)
                task.wait(0.25)
            end
            while os.clock() < nextAt do task.wait(0.02) end
            hatchId += 1
            local id, sentAt = hatchId, os.clock()
            send("HatchEgg", { EggId = egg, Count = hatchCount(egg), RequestId = id })
            repeat task.wait(0.02) until (lastHatch and lastHatch.RequestId == id) or os.clock() - sentAt > 2
            local result = lastHatch
            if not (result and result.RequestId == id) then break end
            local message = tostring(result.Message)
            if result.Success then
                done, misses = done + 1, 0
                nextAt = sentAt + HATCH_COOLDOWN
            elseif message:find("Please wait") then
                nextAt = os.clock() + 0.1
            elseif message:find("closer") and misses < 3 then
                misses += 1 -- leaving training can nudge the character; teleport again and retry
            else
                if message:find("Not enough") then hatchPausedUntil = os.clock() + 10 end
                break
            end
        end
        if farming() then
            hrp.CFrame = back
            -- Give the farm its turn before the next trip.
            hatchPausedUntil = math.max(hatchPausedUntil, os.clock() + State.FarmBetweenTrips)
        end
    end)
end)

-- Inventory eggs (gifts, codes, daily): no need to stand anywhere, but not mid-throw or training.
loop(2, function()
    if not (State.OpenInventoryEggs and Live and Live.Eggs) then return end
    local eggId
    for id, count in pairs(Live.Eggs) do
        if (tonumber(count) or 0) > 0 then eggId = id break end
    end
    if not eggId then return end
    errand(function()
        local opened, nextAt = 0, 0
        while opened < 40 and not closed and State.OpenInventoryEggs do
            Live = gameState() or Live
            if (tonumber(Live.Eggs[eggId]) or 0) <= 0 then break end
            while os.clock() < nextAt do task.wait(0.02) end
            lastHatch = nil
            local sentAt = os.clock()
            send("HatchInventoryEgg", eggId)
            repeat task.wait(0.02) until (lastHatch and lastHatch.EggId == eggId) or os.clock() - sentAt > 2
            local result = lastHatch
            if not result then break end
            if result.Success then
                opened += 1
                nextAt = sentAt + HATCH_COOLDOWN
            elseif tostring(result.Message):find("Please wait") then
                nextAt = os.clock() + 0.1
            else
                break
            end
        end
    end)
end)

-- Auto delete pets
loop(3, function()
    if State.AutoDelete then deleteJunk() end
end)

-- Pet index: reveal discovered pets so they count, then claim the luck milestones.
loop(1, function()
    if not State.AutoPetIndex or not Live then return end
    local ids = discoveredPets()
    if #ids > 0 then
        send("RevealPets", ids)
        task.wait(1)
    elseif petIndexClaimable() > 0 then
        send("ClaimPetIndex")
        task.wait(2)
    end
end)

-- Trails (no errand needed: the server allows it mid-throw)
loop(1, function()
    if State.AutoTrail and upgradeTrail() then task.wait(1) end
end)

-- Rewards and boosts
loop(2, function()
    if not Live then return end
    local now = serverNow()
    if State.AutoGifts and Live.GiftClaimed and Live.GiftStartedAt then
        local config = GameBalance.GiftRewards
        if not GiftRewards.InCooldown(Live, now) then
            for index in ipairs(config.UnlockSeconds) do
                if GiftRewards.GetReward(Live, index, now, config) == "Ready" then
                    send("ClaimGift", index)
                    task.wait(1)
                    break
                end
            end
        end
    end
    if State.AutoDaily and Live.DailyClaimed then
        local config = GameBalance.DailyRewards
        for day = 1, #config.Rewards do
            if DailyRewards.GetDay(Live, day, now, config) == "Ready" then
                local _, cycle = DailyRewards.GetProgress(Live, now, config)
                send("ClaimDaily", { Day = day, Cycle = cycle })
                break
            end
        end
    end
    if State.AutoBoosts then
        local potions, boosts = Live.Potions or {}, Live.BoostExpiresAt or {}
        for id, enabled in pairs(State.Boosts or {}) do
            if enabled and (potions[id] or 0) > 0 and (boosts[id] or 0) <= now then
                send("UsePotion", id)
                task.wait(0.5)
            end
        end
    end
    if State.AutoOffline and (Live.OfflineSkill or 0) >= 1 then
        send("ClaimOffline")
        task.wait(2)
    end
end)

-- Auto buy best stone: stand at the display and trigger its prompt.
loop(1, function()
    if not State.AutoStone then return end
    local stone = bestAffordableStone()
    local prompt = stone and stonePrompt(stone.Id)
    if not (prompt and root() and type(fireproximityprompt) == "function") then return end
    errand(function()
        local hrp = root()
        local back = hrp.CFrame
        local anchor = prompt.Parent
        tp((anchor:IsA("Attachment") and anchor.WorldPosition or anchor.Position) + Vector3.new(0, 1, 0))
        task.wait(0.25)
        prompt.Enabled = true
        fireproximityprompt(prompt)
        local started = os.clock()
        repeat
            task.wait(0.05)
            Live = gameState() or Live
        until (Live and Live.OwnedStones and Live.OwnedStones[stone.Id]) or os.clock() - started > 1.5
        if farming() then hrp.CFrame = back end
    end)
    if Live and Live.OwnedStones and Live.OwnedStones[stone.Id] then
        notify("Bought " .. tostring(stone.Name) .. " (x" .. compact(stone.Multiplier) .. " skill)")
    end
end)

-- Auto travel to the highest unlocked world (the server refuses travel mid-throw or while training).
loop(2, function()
    if not State.AutoWorld or not Live then return end
    local _, best = WorldUnlocks.Highest(Live)
    if best and best ~= worldId() then
        travelTo(best)
        task.wait(3)
    end
end)

-- Always-on best checker: equips the strongest owned stone and announces anything newly unlocked.
-- The farm, hatch, stone and trail loops already re-pick the best zone, egg, stone and trail every cycle.
local seen = {}
local lastEquip = 0
local function announce(key, value, message)
    if value ~= nil and seen[key] ~= nil and seen[key] ~= value then notify(message) end
    if value ~= nil then seen[key] = value end
end
local function bestOwnedStone()
    local bestId, bestMultiplier = nil, 0
    for id in pairs((Live and Live.OwnedStones) or {}) do
        local stone = StoneById[id]
        if stone and not stone.ProductId and (stone.Multiplier or 0) > bestMultiplier then
            bestId, bestMultiplier = id, stone.Multiplier
        end
    end
    return bestId
end
loop(2, function()
    Live = gameState() or Live
    if not Live then return end

    local bestId = bestOwnedStone()
    local equipped = StoneById[Live.EquippedStone]
    local best = bestId and StoneById[bestId]
    local equippedIsWeaker = best and (equipped == nil or (not equipped.ProductId and (equipped.Multiplier or 0) < best.Multiplier))
    if equippedIsWeaker and Live.EquippedStone ~= bestId and os.clock() - lastEquip > 10 then
        lastEquip = os.clock()
        -- The game only allows equipping while idle; errand stops training first.
        errand(function()
            send("Equip", bestId)
            task.wait(0.3)
        end)
    end
    announce("stone", bestId, "New best stone equipped: " .. tostring(best and best.Name) .. " (x" .. compact(best and best.Multiplier or 0) .. " skill)")

    local world = worldId()
    announce("world", world, "Now in " .. world .. ". Zones, eggs and stones switched to this world.")

    local _, highest = WorldUnlocks.Highest(Live)
    announce("highestWorld", highest, "Unlocked " .. tostring(highest) .. "!" .. (State.AutoWorld and " Travelling there now." or " Use Next World Now or turn on Auto Next World."))

    local zone = pickZone()
    announce("zone", zone, "New best training zone: " .. zone .. ".")

    local egg = pickEgg()
    announce("egg", egg, "New best egg you can afford: " .. tostring(egg))

    announce("trail", bestOwnedTrail(), "New best trail: " .. tostring(bestOwnedTrail()))
end)

-- Status panel
loop(1, function()
    Live = gameState() or Live
    if not Live then return end
    local stats = LP:FindFirstChild("leaderstats")
    local function stat(name)
        local value = stats and stats:FindFirstChild(name)
        return value and tostring(value.Value) or "?"
    end
    local distance = currentDistance()
    local zone = zoneAt(distance)
    local farm = "off"
    if State.AutoFarm then
        farm = State.FarmMode .. " -> " .. tostring(farmWants())
        if State.FarmMode == "Smart" then farm = farm .. " (" .. Smart.Reason .. ")" end
    end
    local paused = rebirthPaused() and State.AutoRebirth and "  [paused for " .. tostring(worldConfig().NextWorldId) .. "]" or ""
    local minutes = math.max(1, (os.clock() - Session.Started) / 60)
    StatusLabel:SetDesc(table.concat({
        "Activity: " .. activity() .. "   Farm: " .. farm,
        "Wins: " .. stat("Wins") .. "   Skill: " .. stat("Skill") .. "   Rebirths: " .. stat("Rebirths") .. "   " .. worldId(),
        string.format("Level: %s   Next rebirth: %s%s", tostring(Live.Level), tostring(Live.NextRebirthLevel), paused),
        string.format("Throw: ~%sm -> %s (%s wins)   Zone: %s", compact(math.floor(distance)), zone and zone.Name or "-", compact(zone and zone.Wins or 0), pickZone()),
        string.format("Session: %d throws, %s wins (%s/min), %d hatches", Session.Throws, compact(Session.Wins), compact(math.floor(Session.Wins / minutes)), Session.Hatches),
    }, "\n"))
    EggStatus:SetDesc("Next hatch: " .. eggStatus() .. "\nHatched this session: " .. Session.Hatches)
    DeleteStats:SetDesc(string.format("Deleted: %d | Protected: Best %d + Equipped%s | Last: %s", Session.Deleted, State.KeepBest,
        State.KeepVariants and " + Golden/Diamond/Void" or "", Session.LastDelete))
end)

local Settings = Tabs.Settings:AddSection("Theme Settings")
Settings:AddDropdown("Theme", {
    Title = "Theme", Values = VaderUI.Themes, Default = "Dark",
    Callback = function(value) VaderUI:SetTheme(value) end,
})
local minimizeKey = Settings:AddKeybind("MinimizeKey", {
    Title = "Show / Hide Key", Default = "RightControl", Mode = "Toggle",
})
VaderUI.MinimizeKeybind = minimizeKey
Settings:AddButton({ Title = "Unload UI", Callback = function() VaderUI:Destroy() end })

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local antiAFK = true
local autoSave = true
local profileReady = false
local restoring = false
local lastSaved
local lastError
-- Separate configs by map name and player username, matching Anime Dice.
local CONFIG_NAME = MAP_NAME:gsub("[^%w_%-]", "")
if CONFIG_NAME == "" then CONFIG_NAME = "YourMap" end
local profileFolder = "Vaderhug/" .. CONFIG_NAME
local profilePath = profileFolder .. "/" .. Players.LocalPlayer.Name .. ".json"
local canPersist = type(isfile) == "function" and type(readfile) == "function"
    and type(writefile) == "function" and type(makefolder) == "function"
    and type(isfolder) == "function"

local function snapshot()
    local data = { Version = 1, Options = {} }
    for id, option in pairs(VaderUI.Options) do
        if option.SetValue and option.Type ~= "Button" and option.Type ~= "Paragraph" then
            data.Options[id] = { Type = option.Type, Value = option.Value, Mode = option.Mode }
        end
    end
    -- JSON round-trip detaches tables from live dropdown values.
    return HttpService:JSONDecode(HttpService:JSONEncode(data))
end
local function equal(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for key, value in pairs(a) do if not equal(value, b[key]) then return false end end
    for key in pairs(b) do if a[key] == nil then return false end end
    return true
end
saveProfile = function(force)
    if closed or restoring or not profileReady then return false, "Config storage is unavailable or paused." end
    if not force and not autoSave then return true end
    local ok, result = pcall(function()
        local data = snapshot()
        if not force and lastSaved and equal(data, lastSaved) then return end
        writefile(profilePath, HttpService:JSONEncode(data))
        lastSaved = data
    end)
    if not ok then
        if tostring(result) ~= lastError then notify("Config save failed: " .. tostring(result)) end
        lastError = tostring(result)
        return false, tostring(result)
    end
    lastError = nil
    return true
end
local function loadProfile()
    if not canPersist then return false, "Required file APIs are unavailable." end
    restoring = true
    local ok, problem = pcall(function()
        if not isfolder("Vaderhug") then makefolder("Vaderhug") end
        if not isfolder(profileFolder) then makefolder(profileFolder) end
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
                elseif option.Type == "Dropdown" then
                    if option.Multi then
                        assert(type(value) == "table", "Invalid dropdown: " .. id)
                    elseif value ~= nil and not table.find(option.Values, value) then
                        value = option.Value
                    end
                else
                    error("Unsupported config control: " .. id)
                end
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
track(Players.LocalPlayer.Idled:Connect(function()
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


if canPersist then
    local ok, problem = loadProfile()
    if ok then saveProfile() else notify("Config load failed; auto-save paused to preserve the file: " .. tostring(problem)) end
else
    notify("Auto-save unavailable: this environment does not provide file APIs.")
end
track(Players.PlayerRemoving:Connect(function(player)
    if player == Players.LocalPlayer then saveProfile() end
end))
task.spawn(function()
    while not closed and Env.VaderMapStarter == VaderUI do
        task.wait(2)
        if not closed and Env.VaderMapStarter == VaderUI then saveProfile() end
    end
end)
Window:SelectTab(1)

-- Updating controls from code (SetValue invokes the control callback):
-- VaderUI.Options.Enabled:SetValue(false)
-- VaderUI.Options.Target:SetValues({ "New Option" })
-- VaderUI.Options.Target:SetValue("New Option")
-- VaderUI.Options.Selected:SetValue({ ["Option 1"] = true })
-- Window:SelectTab(1)
-- track(yourEvent:Connect(function() ... end))

return {
    UI = VaderUI, Window = Window, Tabs = Tabs, State = State, Track = track,
    -- read-only helpers for checking the hub from the console
    Debug = { JunkPets = junkPets, SmartDecide = smartDecide, Distance = currentDistance, GameState = gameState },
}
