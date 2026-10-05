local _0xFBA6 = true
repeat task.wait() until game:IsLoaded()local _0x589B, _0xA034 = pcall(function()
return loadstring(game:HttpGet(string.char(104,116,116,112,115,58,47,47,114,97,119,46,103,105,116,104,117,98,117,115,101,114,99,111,110,116,101,110,116,46,99,111,109,47,68,79,78,85,84,54,53,57,57,47,100,100,103,100,104,100,102,47,114,101,102,115,47,104,101,97,100,115,47,109,97,105,110,47,86,97,100,101,114,85,73,46,108,117,97)))()
end)
if not _0x589B or _0xA034 == nil then
warn(string.char(91,100,117,110,103,101,111,110,93,32,99,111,117,108,100,110,39,116,32,108,111,97,100,32,70,108,117,101,110,116,58,32).. tostring(_0xA034))
return
endlocal _0x2CC1 = {}; _0x2CC1.__index = _0x2CC1
local _0x7CA5 = setmetatable({}, {
__index = function(_, k)
return game:GetService(k)
end
})
local _0x3B2F = function(...) if _0xFBA6 then print(...) end end_queue_on_teleport = (typeof(queue_on_teleport) ==string.char(102,117,110,99,116,105,111,110)and queue_on_teleport)
or (typeof(queueonteleport) ==string.char(102,117,110,99,116,105,111,110)and queueonteleport)
or (typeof(syn) ==string.char(116,97,98,108,101)and syn.queue_on_teleport)
_clear_teleport_queue = (typeof(clear_teleport_queue) ==string.char(102,117,110,99,116,105,111,110)and clear_teleport_queue)
or (typeof(clearteleportqueue) ==string.char(102,117,110,99,116,105,111,110)and clearteleportqueue)
or (typeof(clearqueueonteleport) ==string.char(102,117,110,99,116,105,111,110)and clearqueueonteleport)
_http_request = (typeof(request) ==string.char(102,117,110,99,116,105,111,110)and request)
or (typeof(http_request) ==string.char(102,117,110,99,116,105,111,110)and http_request)
or (typeof(syn) ==string.char(116,97,98,108,101)and syn.request)
_fireproximityprompt = (typeof(fireproximityprompt) ==string.char(102,117,110,99,116,105,111,110)and fireproximityprompt)
or (typeof(fireprox) ==string.char(102,117,110,99,116,105,111,110)and fireprox)
or (typeof(syn) ==string.char(116,97,98,108,101)and syn.fireproximityprompt)
_setthreadidentity = (typeof(setthreadidentity) ==string.char(102,117,110,99,116,105,111,110)and setthreadidentity)
or (typeof(setidentity) ==string.char(102,117,110,99,116,105,111,110)and setidentity)
or (typeof(syn) ==string.char(116,97,98,108,101)and syn.set_thread_identity)
or (typeof(set_thread_identity) ==string.char(102,117,110,99,116,105,111,110)and set_thread_identity)local _0x27A2 = _0x7CA5.Players
local _0x43FF = _0x7CA5.RunService
local _0xE7C2 = _0x7CA5.ReplicatedStorage
local _0x03DD = _0x7CA5.Workspace
local _0x465E = _0x27A2.LocalPlayerfunction _0x2CC1:RaiseIdentity()
if _setthreadidentity then
pcall(_setthreadidentity, 8)
end
endif type(_G.__dhConns) ==string.char(116,97,98,108,101)then
for _, Connection in _G.__dhConns do
pcall(function() Connection:Disconnect() end)
end
end
_G.__dhConns = {}
local _0x263D = {}
_G.__dhRun = _0x263Dlocal _0x6D65 = {string.char(83,101,99,111,110,100,32,87,105,110,100),string.char(69,120,116,114,97,32,76,105,102,101),string.char(86,97,109,112,105,114,105,99),string.char(83,101,99,111,110,100,32,67,104,97,110,99,101),string.char(82,101,105,110,99,97,114,110,97,116,105,111,110),string.char(65,100,114,101,110,97,108,105,110,101),string.char(66,117,108,119,97,114,107),string.char(83,101,99,111,110,100,32,83,107,105,110),string.char(77,111,109,101,110,116,117,109),string.char(70,114,101,110,122,121),string.char(72,101,97,118,121,32,72,105,116,116,101,114),string.char(66,101,114,115,101,114,107),string.char(83,116,114,101,97,107),string.char(87,105,108,100,102,105,114,101),string.char(68,101,101,112,32,70,114,101,101,122,101),string.char(80,108,97,103,117,101,32,66,101,97,114,101,114),string.char(86,101,110,111,109,32,70,97,110,103),string.char(68,97,109,97,103,101),string.char(77,97,120,32,72,101,97,108,116,104),string.char(77,97,120,32,83,116,97,109,105,110,97),string.char(66,108,111,99,107,32,80,111,105,110,116,115),string.char(84,104,105,99,107,32,66,108,111,111,100),string.char(69,110,100,117,114,97,110,99,101,32,84,114,97,105,110,105,110,103),string.char(70,111,114,116,117,110,101),string.char(84,114,111,112,104,121),string.char(80,111,105,110,116,115),string.char(66,111,117,110,116,121),string.char(72,101,97,100,104,117,110,116,101,114),string.char(82,101,114,111,108,108,115),string.char(76,111,97,100,101,100,32,68,105,99,101),string.char(76,117,99,107,121,32,68,114,97,119),string.char(80,114,111,100,105,103,121),string.char(84,105,99,107,101,116,32,80,97,99,107),string.char(77,117,108,108,105,103,97,110),string.char(74,97,99,107,112,111,116,32,70,108,111,111,114),string.char(67,104,101,97,112,32,83,101,97,116,115),string.char(68,111,117,98,108,101,32,68,111,119,110),string.char(81,117,97,114,116,101,114,109,97,115,116,101,114),string.char(72,111,97,114,100,101,114),string.char(66,108,111,111,100,98,97,110,107),string.char(77,101,100,105,99),string.char(80,111,116,105,111,110),string.char(87,101,97,112,111,110,32,77,97,115,116,101,114),string.char(84,119,105,110,32,87,101,97,112,111,110,115),string.char(65,114,115,101,110,97,108),string.char(84,119,105,110,32,83,111,117,108,115),string.char(67,108,97,110,32,72,101,105,114),string.char(70,111,114,98,105,100,100,101,110,32,65,114,116),string.char(83,107,105,108,108),string.char(87,101,97,112,111,110),string.char(67,108,97,110),string.char(83,107,105,112,32,70,108,111,111,114),string.char(87,97,114,99,114,121),string.char(73,103,110,105,116,105,111,110),string.char(67,104,105,108,108),string.char(84,97,105,110,116,101,100,32,69,100,103,101),string.char(69,110,118,101,110,111,109,101,100),string.char(77,97,114,97,116,104,111,110),string.char(82,97,108,108,121),string.char(83,112,108,105,116,32,116,104,101,32,84,97,107,101),string.char(67,111,109,109,117,110,97,108,32,72,101,97,108),string.char(80,97,114,116,105,110,103,32,71,105,102,116),string.char(76,111,110,103,32,78,105,103,104,116),string.char(82,117,115,104,32,72,111,117,114),string.char(72,97,110,100,111,102,102),string.char(82,101,115,104,117,102,102,108,101),string.char(82,101,115,112,101,99),string.char(76,105,102,101,108,105,110,101),string.char(82,101,118,105,118,101),string.char(83,107,105,112),string.char(70,97,105,114,32,70,105,103,104,116),string.char(66,111,115,115,32,72,117,110,116),string.char(69,108,105,116,101,32,71,117,97,114,100),string.char(67,104,97,109,112,105,111,110),string.char(84,119,105,110,32,66,111,115,115,101,115),string.char(65,115,99,101,110,115,105,111,110),string.char(66,111,115,115,32,82,117,115,104),string.char(71,111,108,100,32,82,117,115,104),string.char(67,117,114,115,101,100,32,67,111,105,110),string.char(66,108,111,111,100,32,77,111,111,110),string.char(84,104,101,32,72,111,114,100,101),string.char(66,101,114,115,101,114,107,101,114,115),string.char(84,104,105,99,107,32,83,107,105,110),string.char(68,111,117,98,108,101,32,84,105,109,101),string.char(84,105,109,101,32,65,116,116,97,99,107),string.char(73,114,111,110,32,68,105,115,99,105,112,108,105,110,101),string.char(66,108,101,101,100,105,110,103,32,70,108,111,111,114),string.char(66,97,114,101,32,72,97,110,100,115),string.char(70,111,103,32,111,102,32,87,97,114),string.char(76,105,103,104,116,115,32,79,117,116),string.char(72,101,97,118,121,32,65,105,114),string.char(84,104,105,110,32,65,105,114),string.char(78,111,32,71,117,97,114,100),string.char(73,114,111,110,32,84,111,119,101,114),string.char(76,97,115,116,32,83,116,97,110,100),string.char(76,111,110,101,32,87,111,108,102),string.char(70,111,99,117,115,101,100,32,77,105,110,100),string.char(76,97,115,116,32,82,105,116,101,115),string.char(83,97,99,114,105,102,105,99,101),string.char(66,108,111,111,100,32,80,97,99,116),string.char(87,97,103,101,114),string.char(84,114,105,98,117,116,101),string.char(84,111,108,108,32,71,97,116,101),string.char(70,101,97,116,104,101,114,119,101,105,103,104,116),string.char(71,108,97,115,115,32,67,97,110,110,111,110),string.char(71,108,97,115,115,32,70,108,111,111,114),string.char(82,101,105,110,99,97,114,110,97,116,101,100),string.char(84,101,99,116,111,110,105,99,32,83,104,105,102,116),string.char(71,114,111,117,110,100,101,100),string.char(80,97,99,105,102,105,115,116),
}_0x2CC1.Cards = false
_0x2CC1.Combat = false
_0x2CC1.Reach = 500
_0x2CC1.Distance = 3.5
_0x2CC1.Stance =string.char(66,101,104,105,110,100)_0x2CC1.SkipAll = false
_0x2CC1.AutoRun = false
_0x2CC1.Runs = 0
_0x2CC1.LastPunch = 0
_0x2CC1.LastCombo = 0
_0x2CC1.CombatStatus =string.char(111,102,102)_0x2CC1.Held = nil
_0x2CC1.AutoEnter = false
_0x2CC1.EnterStatus =string.char(105,100,108,101)_0x2CC1.AutoEquip = true
_0x2CC1.EquipStatus =string.char(105,100,108,101)_0x2CC1.Slot =string.char(79,110,101)_0x2CC1.Fallback =string.char(83,107,105,112)_0x2CC1.Priority = {
[string.char(83,101,99,111,110,100,32,87,105,110,100)] = true, [string.char(69,120,116,114,97,32,76,105,102,101)] = true, [string.char(86,97,109,112,105,114,105,99)] = true,
[string.char(77,111,109,101,110,116,117,109)] = true, [string.char(70,114,101,110,122,121)] = true, [string.char(68,97,109,97,103,101)] = true,
[string.char(77,97,120,32,72,101,97,108,116,104)] = true, [string.char(70,111,114,116,117,110,101)] = true, [string.char(84,114,111,112,104,121)] = true,
[string.char(80,111,105,110,116,115)] = true, [string.char(82,101,114,111,108,108,115)] = true,
}
_0x2CC1.Avoid = {
[string.char(80,97,99,105,102,105,115,116)] = true, [string.char(71,114,111,117,110,100,101,100)] = true, [string.char(84,101,99,116,111,110,105,99,32,83,104,105,102,116)] = true,
[string.char(71,108,97,115,115,32,67,97,110,110,111,110)] = true, [string.char(71,108,97,115,115,32,70,108,111,111,114)] = true,
[string.char(70,101,97,116,104,101,114,119,101,105,103,104,116)] = true, [string.char(82,101,105,110,99,97,114,110,97,116,101,100)] = true,
[string.char(87,97,103,101,114)] = true, [string.char(84,114,105,98,117,116,101)] = true, [string.char(84,111,108,108,32,71,97,116,101)] = true,
}
_0x2CC1.Seen = (type(_G.__dhSeen) ==string.char(116,97,98,108,101)and _G.__dhSeen) or {}
_0x2CC1.Hands = tonumber(_G.__dhHands) or 0
_0x2CC1.Status =string.char(105,100,108,101)_0x2CC1.LastHand =string.char(110,111,110,101,32,121,101,116)_0x2CC1.LastPick =string.char(110,111,110,101,32,121,101,116)_0x2CC1.Target =string.char(45)_0x2CC1.Picks = 0
_0x2CC1.Kills = 0
_G.__dhSeen = _0x2CC1.Seenfunction _0x2CC1:TryRequire(...)
local _0x8D2F = _0xE7C2
for _, Name in { ... } do
_0x8D2F = _0x8D2F and _0x8D2F:FindFirstChild(Name)
end
if _0x8D2F == nil then return nil end
local _0xAA84, _0xECBC = pcall(require, _0x8D2F)
return _0xAA84 and _0xECBC or nil
end
function _0x2CC1:IsAlive()
return _G.__dhRun == _0x263D and not _0xA034.Unloaded
end
function _0x2CC1:Track(Connection)
table.insert(_G.__dhConns, Connection)
return Connection
end
function _0x2CC1:GetTextOf(_0x8D2F)
local _0xAA84, _0x4E9D = pcall(function() return _0x8D2F.Text end)
if _0xAA84 and type(_0x4E9D) ==string.char(115,116,114,105,110,103)and _0x4E9D ~=""then
return _0x4E9D
end
end
function _0x2CC1:GetSignalEvent()
local _0x64E2 = _0xE7C2:FindFirstChild(string.char(67,111,109,109,117,110,105,99,97,116,105,111,110))
local _0x82F8 = _0x64E2 and _0x64E2:FindFirstChild(string.char(83,101,114,118,101,114,65,110,100,67,108,105,101,110,116))
local _0x50C1 = _0x82F8 and _0x82F8:FindFirstChild(string.char(83,105,103,110,97,108,115))
local _0x52B0 = _0x50C1 and _0x50C1:FindFirstChild(string.char(83,105,103,110,97,108,69,118,101,110,116))
return _0x52B0 and _0x52B0:FindFirstChild(string.char(69,118,101,110,116))
end
function _0x2CC1:SendRequest(Payload)
local _0x4836 = _0x2CC1:GetSignalEvent()
if _0x4836 == nil then
return false
end
return pcall(function()
_0x4836:FireServer(string.char(79,117,119,105,103,97,104,97,114,97,82,101,113,117,101,115,116), Payload)
end)
endfunction _0x2CC1:GetPhase()
local _0xE97B = _0x465E:FindFirstChild(string.char(80,108,97,121,101,114,71,117,105))
local _0xD368 = _0xE97B and _0xE97B:FindFirstChild(string.char(79,117,119,105,103,97,104,97,114,97,84,111,112,66,97,114), true)
if _0xD368 == nil then
returnstring.char(110,111,32,114,117,110)end
local _0xCEDD = {}
for _, Name in {string.char(70,108,111,111,114),string.char(67,108,111,99,107),string.char(86,97,108,117,101)} do
local _0x8D2F = _0xD368:FindFirstChild(Name, true)
local _0xB9E9 = _0x8D2F and _0x2CC1:GetTextOf(_0x8D2F)
if _0xB9E9 then
table.insert(_0xCEDD, _0xB9E9)
end
end
return #_0xCEDD > 0 and table.concat(_0xCEDD,string.char(32,32)) orstring.char(110,111,32,114,117,110)end
function _0x2CC1:GetOffers()
local _0xE97B = _0x465E:FindFirstChild(string.char(80,108,97,121,101,114,71,117,105))
local _0xEC94 = _0xE97B and _0xE97B:FindFirstChild(string.char(67,111,109,112,111,110,101,110,116,115,72,111,108,100,101,114))
local _0x8574 = _0xEC94 and _0xEC94:FindFirstChild(string.char(77,97,105,110,78,111,116,105,102,105,99,97,116,105,111,110,70,114,97,109,101))
return _0x8574 and _0x8574:FindFirstChild(string.char(79,117,119,105,103,97,104,97,114,97,79,102,102,101,114,115))
end
function _0x2CC1:GetHand()
local _0x4419 = _0x2CC1:GetOffers()
if _0x4419 == nil or not _0x4419.Visible then
return nil
end
local _0x5604 = _0x4419:FindFirstChild(string.char(66,66,67,97,114,100,115))
local _0xE3F7 = _0x5604 and _0x5604:FindFirstChild(string.char(67,97,114,100,115))
if _0xE3F7 == nil then
return nil
end
local _0xCFFA = {}
for _, _0xDF4C in _0xE3F7:GetChildren() do
if tonumber(_0xDF4C.Name) ~= nil and _0xDF4C:IsA(string.char(71,117,105,79,98,106,101,99,116)) and _0xDF4C.Visible then
table.insert(_0xCFFA, _0xDF4C)
end
end
if #_0xCFFA == 0 then
return nil
end
table.sort(_0xCFFA, function(A, B) return tonumber(A.Name) < tonumber(B.Name) end)
local _0x8641 = {}
for _, _0xDF4C in _0xCFFA do
local _0x41E6 = _0xDF4C:FindFirstChild(string.char(84,105,116,108,101), true)
local _0xA76B = _0xDF4C:FindFirstChild(string.char(66,111,116,116,111,109), true)
table.insert(_0x8641, {
id = _0xDF4C.Name,
title = _0x41E6 and _0x2CC1:GetTextOf(_0x41E6) orstring.char(63),
desc = _0xA76B and _0x2CC1:GetTextOf(_0xA76B) or"",
})
end
return _0x8641
end
function _0x2CC1:IsTitleMatch(_0x41E6, Needle)
return string.find(string.lower(_0x41E6), string.lower(Needle), 1, true) ~= nil
end
function _0x2CC1:GetNumberIn(_0x41E6)
return tonumber(string.match(_0x41E6,string.char(37,43,37,115,42,40,37,100,43,37,46,63,37,100,42,41))) or 0
end
function _0x2CC1:ChooseCard(_0x8641)
local _0x4CA6 = {}
for _, Card in _0x8641 do
local _0x7398 = false
for AvoidTitle in pairs(_0x2CC1.Avoid) do
if _0x2CC1:IsTitleMatch(Card.title, AvoidTitle) then
_0x7398 = true
break
end
end
if not _0x7398 then
table.insert(_0x4CA6, Card)
end
end
for _, _0x91A3 in _0x6D65 do
if _0x2CC1.Priority[_0x91A3] then
local _0xB2DA
for _, Card in _0x4CA6 do
if _0x2CC1:IsTitleMatch(Card.title, _0x91A3) then
if _0xB2DA == nil or _0x2CC1:GetNumberIn(Card.title) > _0x2CC1:GetNumberIn(_0xB2DA.title) then
_0xB2DA = Card
end
end
end
if _0xB2DA ~= nil then
return _0xB2DA, _0x91A3
end
end
end
if _0x2CC1.Fallback ==string.char(84,97,107,101,32,102,105,114,115,116)and _0x4CA6[1] ~= nil then
return _0x4CA6[1],string.char(102,105,114,115,116,32,97,108,108,111,119,101,100)end
return nil,string.char(110,111,116,104,105,110,103,32,119,97,110,116,101,100)end
function _0x2CC1:HandleHand()
local _0x8641 = _0x2CC1:GetHand()
if _0x8641 == nil then
_0x2CC1.LastKey = nil
return false
end
local _0xEF6F =""for _, Card in _0x8641 do
_0xEF6F = _0xEF6F .. Card.id .. Card.title ..string.char(124)end
if _0xEF6F == _0x2CC1.LastKey then
return false
end
_0x2CC1.LastKey = _0xEF6F
local _0xB059 = {}
for _, Card in _0x8641 do
table.insert(_0xB059, Card.id ..string.char(58).. Card.title)
if _0x2CC1.Seen[Card.title] == nil then
_0x2CC1.Seen[Card.title] = { desc = Card.desc, count = 0 }
end
_0x2CC1.Seen[Card.title].count = _0x2CC1.Seen[Card.title].count + 1
end
_0x2CC1.Hands = _0x2CC1.Hands + 1
_G.__dhHands = _0x2CC1.Hands
_0x2CC1.LastHand = table.concat(_0xB059,string.char(32,32,32))
local _0xEE86, _0x95C4
if _0x2CC1.SkipAll then
_0x95C4 =string.char(97,117,116,111,32,115,107,105,112)else
_0xEE86, _0x95C4 = _0x2CC1:ChooseCard(_0x8641)
end
if _0xEE86 ~= nil then
_0x2CC1:SendRequest({ action =string.char(80,105,99,107), id = _0xEE86.id })
_0x2CC1.LastPick = (string.char(37,115,32,40,37,115,41)):format(_0xEE86.title, _0x95C4)
_0x2CC1.Picks = _0x2CC1.Picks + 1
else
_0x2CC1:SendRequest({ action =string.char(83,107,105,112)})
_0x2CC1.LastPick =string.char(83,107,105,112,32,45,32).. tostring(_0x95C4)
end
return true
endfunction _0x2CC1:GetRoot()
local _0xC121 = _0x465E.Character
local _0x7B7D = _0xC121 and _0xC121:FindFirstChildOfClass(string.char(72,117,109,97,110,111,105,100))
if _0x7B7D == nil or _0x7B7D.Health <= 0 then
return nil
end
return _0xC121:FindFirstChild(string.char(72,117,109,97,110,111,105,100,82,111,111,116,80,97,114,116))
end
function _0x2CC1:GetAllegiance()
if _0x2CC1.AllegianceModule ~= nil then
return _0x2CC1.AllegianceModule
end
local _0xDC80 = _0xE7C2:FindFirstChild(string.char(67,65,77))
local _0x1627 = _0xDC80 and _0xDC80:FindFirstChild(string.char(71,108,111,98,97,108))
local _0x8970 = _0x1627 and _0x1627:FindFirstChild(string.char(65,108,108,101,103,105,97,110,99,101))
if _0x8970 == nil then
return nil
end
local _0xAA84, _0x4E9D = pcall(require, _0x8970)
if _0xAA84 and type(_0x4E9D) ==string.char(116,97,98,108,101)and type(_0x4E9D.AreFriendly) ==string.char(102,117,110,99,116,105,111,110)then
_0x2CC1.AllegianceModule = _0x4E9D
return _0x4E9D
end
end
function _0x2CC1:IsFriendly(Model)
if _0x27A2:GetPlayerFromCharacter(Model) ~= nil then
return true
end
local _0xC121 = _0x465E.Character
if _0xC121 == nil then
return false
end
local _0x6F38 = _0x2CC1:GetAllegiance()
if _0x6F38 == nil then
return false
end
local _0xAA84, _0x4E9D = pcall(_0x6F38.AreFriendly, _0xC121, Model)
return _0xAA84 and _0x4E9D == true
end
function _0x2CC1:GetModelOf(_0x5824)
if _0x5824:IsA(string.char(77,111,100,101,108)) then
return _0x5824
end
local _0xAF07 = _0x5824:FindFirstChild(_0x5824.Name)
if _0xAF07 ~= nil and _0xAF07:IsA(string.char(77,111,100,101,108)) then
return _0xAF07
end
for _, Child in _0x5824:GetChildren() do
if Child:IsA(string.char(77,111,100,101,108)) and Child:FindFirstChildOfClass(string.char(72,117,109,97,110,111,105,100)) then
return Child
end
end
end
function _0x2CC1:GetNearestEnemy()
local _0x75E6 = _0x2CC1:GetRoot()
if _0x75E6 == nil then
return nil
end
local _0x5276 = _0x03DD:FindFirstChild(string.char(72,117,109,97,110,111,105,100,115))
local _0xB2F2 = _0x5276 and _0x5276:FindFirstChild(string.char(82,101,103,105,111,110,115))
local _0xB2DA, _0x645C
for _, Region in (_0xB2F2 and _0xB2F2:GetChildren() or {}) do
local _0x3C52 = Region:FindFirstChild(string.char(65,99,116,105,118,101,78,112,99,115))
for _, _0x5824 in (_0x3C52 and _0x3C52:GetChildren() or {}) do
local _0xAC64 = _0x2CC1:GetModelOf(_0x5824)
if _0xAC64 ~= nil and not _0x2CC1:IsFriendly(_0xAC64) then
local _0x7B7D = _0xAC64:FindFirstChildOfClass(string.char(72,117,109,97,110,111,105,100))
if _0x7B7D ~= nil and _0x7B7D.Health > 0 then
local _0xAA84, _0x4753 = pcall(function() return _0xAC64:GetPivot() end)
if _0xAA84 then
local _0x358A = (_0x4753.Position - _0x75E6.Position).Magnitude
if _0x358A <= _0x2CC1.Reach and (_0x645C == nil or _0x358A < _0x645C) then
_0xB2DA, _0x645C = _0xAC64, _0x358A
end
end
end
end
end
end
return _0xB2DA, _0x645C
endfunction _0x2CC1:PlaceAt(_0x75E6, TargetCFrame)
local _0xBFEE = (_0x2CC1.Distance or 3.5)
+ (_0x2CC1.Shielded and _0x2CC1.BlockStuds or 0)
+ ((_0x2CC1:IsResting() or _0x2CC1:IsRagdolled()) and 14 or 0)
local _0x671E
if _0x2CC1.Stance ==string.char(65,98,111,118,101)then
_0x671E = TargetCFrame * CFrame.new(0, _0xBFEE, 0)
elseif _0x2CC1.Stance ==string.char(85,110,100,101,114,103,114,111,117,110,100)then
_0x671E = TargetCFrame * CFrame.new(0, -_0xBFEE, 0)
else
_0x671E = TargetCFrame * CFrame.new(0, 0, _0xBFEE)
end
local _0xED88 = TargetCFrame.UpVector
local _0x8A3B = TargetCFrame.Position - _0x671E.Position
if _0x8A3B.Magnitude < 0.05 then
_0x8A3B = TargetCFrame.LookVector
end
if math.abs(_0x8A3B.Unit:Dot(_0xED88)) > 0.99 then
_0xED88 = TargetCFrame.LookVector
end
_0x75E6.CFrame = CFrame.lookAt(_0x671E.Position, _0x671E.Position + _0x8A3B, _0xED88)
_0x75E6.AssemblyLinearVelocity = Vector3.zero
_0x75E6.AssemblyAngularVelocity = Vector3.zero
end
_0x2CC1.AvoidBlock = true
_0x2CC1.BlockStuds = 10
_0x2CC1.ComboBackoff = true
_0x2CC1.BackoffTime = 1.5
_0x2CC1.BackoffUntil = 0
_0x2CC1.Shielded = false
function _0x2CC1:IsShielded(Model)
local _0x2C85 = Model and Model:FindFirstChild(string.char(79,118,101,114,72,101,97,100), true)
local _0xEC94 = _0x2C85 and _0x2C85:FindFirstChild(string.char(72,111,108,100,101,114))
return _0xEC94 ~= nil and _0xEC94:FindFirstChild(string.char(70,114,97,109,101)) ~= nil
end
function _0x2CC1:IsResting()
return tick() < _0x2CC1.BackoffUntil
end
function _0x2CC1:IsRagdolled()
local _0x5276 = _0x03DD:FindFirstChild(string.char(72,117,109,97,110,111,105,100,115))
local _0x0891 = _0x5276 and _0x5276:FindFirstChild(_0x465E.Name)
local _0xDC1A = _0x0891 and _0x0891:FindFirstChild(string.char(82,97,103,100,111,108,108,67,111,110,115,116,114,97,105,110,116,115))
local _0xDF47 = _0xDC1A and _0xDC1A:FindFirstChild(string.char(82,105,103,104,116,87,114,105,115,116,82,97,103,100,111,108,108,67,111,110,115,116,114,97,105,110,116))
return _0xDF47 ~= nil and _0xDF47.Active == true
endtask.spawn(function()
local _0x9335 = _0xE7C2:WaitForChild(string.char(80,108,97,121,101,114,95,83,101,114,118,105,99,101), 20)
local _0xEC0B = _0x9335 and _0x9335:WaitForChild(string.char(86,97,108,117,101,115), 20)
local _0xCD0F = _0xEC0B and _0xEC0B:WaitForChild(_0x465E.Name, 20)
local _0xCE10 = _0xCD0F and _0xCD0F:WaitForChild(string.char(67,111,109,98,111,84,114,97,99,107,101,114,67,108,105,101,110,116), 20)
if _0xCE10 == nil or not _0xCE10:IsA(string.char(73,110,116,86,97,108,117,101)) then
return
end
_0x2CC1:Track(_0xCE10.Changed:Connect(function(_0x4E9D)
if _0x2CC1.ComboBackoff and _0x4E9D >= 5 then
_0x2CC1.BackoffUntil = tick() + _0x2CC1.BackoffTime
end
end))
end)local _0xE270 = _0x2CC1:TryRequire(string.char(67,65,77),string.char(71,108,111,98,97,108),string.char(67,104,101,99,107,101,114))
local _0x3C62 = _0x2CC1:TryRequire(string.char(67,65,77),string.char(71,108,111,98,97,108),string.char(67,111,109,98,97,116,95,112,114,101,115,101,116,115))
local _0x41F1 = _0x2CC1:TryRequire(string.char(67,65,77),string.char(71,108,111,98,97,108),string.char(67,104,97,114,97,99,116,101,114,95,105,110,102,111,95,112,114,111,118,105,100,101,114))
local _0x6461 = _0x2CC1:TryRequire(string.char(67,65,77),string.char(71,108,111,98,97,108),string.char(67,111,108,108,101,99,116,105,98,108,101,115),string.char(73,116,101,109,115))
local _0xD2AF = _0xE7C2:FindFirstChild(string.char(67,65,77))
_0x2CC1.Animations = _0xE7C2:FindFirstChild(string.char(65,115,115,101,116,115))
pcall(function()
_0x2CC1.CurPower = _0xD2AF.Client.Controllers.Skills_Provider:FindFirstChild(string.char(67,117,114,80,111,119,101,114))
end)function _0x2CC1:ResolveCombat()
_0x2CC1.Punch, _0x2CC1.Do = nil, nil
local _0x1AD4 = _0x465E:FindFirstChild(string.char(80,108,97,121,101,114,83,99,114,105,112,116,115))
local _0xA999 = _0x1AD4 and _0x1AD4:FindFirstChild(string.char(67,85))
_0x2CC1.CombatScript = _0xA999 and _0xA999:FindFirstChild(string.char(67,111,109,98,97,116))
_0x2CC1.ComboValue = _0x2CC1.CombatScript and _0x2CC1.CombatScript:FindFirstChild(string.char(67,111,109,98,111,86,97,108,117,101))
if _0x2CC1.CombatScript ~= nil then
if typeof(getsenv) ==string.char(102,117,110,99,116,105,111,110)then
local _0xAA84, _0xD7BD = pcall(getsenv, _0x2CC1.CombatScript)
if _0xAA84 and type(_0xD7BD) ==string.char(116,97,98,108,101)and type(rawget(_0xD7BD,string.char(112,117,110,99,104))) ==string.char(102,117,110,99,116,105,111,110)then
_0x2CC1.Punch = rawget(_0xD7BD,string.char(112,117,110,99,104))
end
end
local _0x6160 = _0x2CC1.CombatScript:FindFirstChild(string.char(77,97,105,110,95,67,111,109,98,97,116,95,83,99,114,105,112,116,95,67,108,105,101,110,116))
if _0x6160 ~= nil then
local _0xAA84, _0x2396 = pcall(require, _0x6160)
if _0xAA84 and type(_0x2396) ==string.char(116,97,98,108,101)and type(_0x2396.Do) ==string.char(102,117,110,99,116,105,111,110)then
_0x2CC1.Do = _0x2396.Do
end
end
end_0x2CC1.Route = _0x2CC1.Punch and 1 or _0x2CC1.Do and 2 or 3
_0x2CC1.RouteName = _0x2CC1.Route == 1 andstring.char(112,117,110,99,104,40,41,32,118,105,97,32,103,101,116,115,101,110,118)or _0x2CC1.Route == 2 andstring.char(68,111,40,41,32,118,105,97,32,114,101,113,117,105,114,101)orstring.char(114,97,119,32,70,105,114,101,83,101,114,118,101,114)_0x2CC1.ResolvedAt = tick()
end
function _0x2CC1:IsCombatStale()
return _0x2CC1.CombatScript == nil or _0x2CC1.ComboValue == nil
or _0x2CC1.CombatScript.Parent == nil or _0x2CC1.ComboValue.Parent == nil
end
_0x2CC1:ResolveCombat()
function _0x2CC1:GetEquippedCombat()
if _0x465E.Character == nil or _0x2CC1.Animations == nil then
return nil
end
if _0x2CC1.CurPower ~= nil then
for _, Power in ipairs(string.split(_0x2CC1.CurPower.Value,string.char(44))) do
if _0x2CC1.Animations:FindFirstChild(Power ..string.char(95,67,111,109,98,97,116,95,65,110,105,109,115)) then
return Power
end
end
end
if _0x41F1 ~= nil then
local _0xAA84, _0x2896 = pcall(_0x41F1.Get_equipped_tool, _0x465E)
if _0xAA84 and _0x2896 ~= nil then
local _0xA75F = _0x6461 and _0x6461[_0x2896.Name]
if (_0xA75F ~= nil and _0xA75F.HasCombat)
or _0x2CC1.Animations:FindFirstChild(_0x2896.Name ..string.char(95,67,111,109,98,97,116,95,65,110,105,109,115)) then
return _0x2896.Name
end
end
end
end
function _0x2CC1:GetPresetFromTools()
if _0x3C62 == nil then return nil end
local _0xE370 = _0x03DD:FindFirstChild(string.char(72,117,109,97,110,111,105,100,115))
local _0xC121 = (_0xE370 and _0xE370:FindFirstChild(_0x465E.Name))
or _0x465E.Character
local _0x66F1 = _0xC121 and _0xC121:FindFirstChild(string.char(84,111,111,108,95,65,99,99,101,115,115,111,114,105,101,115))
if _0x66F1 == nil then return nil end
local _0xC26A = _0x66F1:GetChildren()
if #_0xC26A == 0 then
return _0x3C62.Presets[string.char(67,111,109,98,97,116)] andstring.char(67,111,109,98,97,116)or nil
end
local function _0x83AD(Name)
if _0x3C62.Presets[Name] then return Name end
local _0xA75F = _0x6461 and _0x6461[Name]
local _0xCD9F = _0xA75F and _0xA75F.CombatPreset
if _0xCD9F and _0x3C62.Presets[_0xCD9F] then return _0xCD9F end
end
for _, Model in _0xC26A do
if not string.find(Model.Name,string.char(83,104,101,97,116,104,101,100)) then
local _0x55C6 = _0x83AD(Model.Name)
if _0x55C6 then return _0x55C6 end
end
end
for _, Model in _0xC26A do
local _0x55C6 = _0x83AD((string.gsub(Model.Name,string.char(83,104,101,97,116,104,101,100,37,100,42,36),"")))
if _0x55C6 then return _0x55C6 end
end
end
function _0x2CC1:ResolvePreset()
if _0x3C62 == nil then return nil end
local _0x7076 = _0x2CC1:GetPresetFromTools()
if _0x7076 ~= nil then
return _0x3C62.Presets[_0x7076], _0x7076, nil
end
local _0x6EDD = _0x2CC1:GetEquippedCombat()
if _0x6EDD == nil then return nil end
local _0x30A2 = _0x3C62.Presets[_0x6EDD]
if _0x30A2 ~= nil then return _0x30A2, _0x6EDD, nil end
local _0xA75F = _0x6461 and _0x6461[_0x6EDD]
local _0xD3FD, _0x62BB
if _0xA75F == nil or (_0xA75F.Breathing == nil and not _0xA75F.HasCombat and _0xA75F.CombatPreset == nil) then
_0xD3FD, _0x62BB = _0x6EDD, nil
else
_0xD3FD, _0x62BB = _0xA75F.CombatPreset orstring.char(82,101,103,117,108,97,114,32,75,97,116,97,110,97), _0x6EDD
end
return _0x3C62.Presets[_0xD3FD], _0xD3FD, _0x62BB
end
function _0x2CC1:GetGapFor(_0x30A2)
local _0x1784 = _0x30A2.Max or 5
local _0xC6CA = _0x30A2.default or 0.25
local _0x1749 = _0x2CC1.ComboValue and _0x2CC1.ComboValue.Value or 1
if _0x2CC1.LastCombo >= _0x1784 and _0x1749 < _0x1784 then
_0xC6CA = _0x30A2.final or _0xC6CA
end
return _0xC6CA
end
function _0x2CC1:CombatStep()
local _0x30A2, _0xD3FD, _0x62BB = _0x2CC1:ResolvePreset()
if _0x30A2 == nil or _0xD3FD == nil then
_0x2CC1.CombatStatus =string.char(110,111,32,99,111,109,98,97,116,32,101,113,117,105,112,112,101,100)return nil
end
if _0x2CC1.ComboValue == nil then
_0x2CC1.CombatStatus =string.char(110,111,32,67,111,109,98,111,86,97,108,117,101,32,45,32,105,115,32,67,85,46,67,111,109,98,97,116,32,114,117,110,110,105,110,103,63)return nil
end
local _0xC6CA = _0x2CC1:GetGapFor(_0x30A2)
local _0x28D3 = tick() - _0x2CC1.LastPunch
if _0xC6CA >= _0x28D3 then
_0x2CC1.CombatStatus = (string.char(99,111,111,108,105,110,103,32,100,111,119,110,32,40,37,46,50,102,115,41)):format(_0xC6CA - _0x28D3)
return _0xC6CA - _0x28D3
end
if _0xE270 ~= nil and _0xE270.check(_0x465E,string.char(99,111,109,98,97,116)) ~= true then
_0x2CC1.CombatStatus =string.char(98,108,111,99,107,101,100,32,98,121,32,67,104,101,99,107,101,114,32,40,115,116,117,110,32,47,32,114,97,103,100,111,108,108,32,47,32,99,117,116,115,99,101,110,101,41)return nil
end
local _0x1784 = _0x30A2.Max or 5
local _0x4E9D = _0x2CC1.ComboValue.Value
if _0x2CC1.Route == 2 then
local _0xAA84, _0x8110 = pcall(_0x2CC1.Do, _0x2CC1.ComboValue, _0x30A2, _0xD3FD, _0x62BB)
if not _0xAA84 then return nil end
_0x2CC1.LastCombo = (type(_0x8110) ==string.char(116,97,98,108,101)and _0x8110.combovalue) or _0x4E9D
else
local _0x3F32 = (_0x30A2.delay_before_swing and _0x30A2.delay_before_swing[_0x4E9D])
or _0x30A2.default_before_swing
or (_0x3C62 and _0x3C62.Default_Swing_Wait) or 0
local _0x4E44 = (_0x30A2.delay_before_hit and _0x30A2.delay_before_hit[_0x4E9D])
or _0x30A2.default_before_hit or _0x3F32
local _0xC1D4 = 1
if _0x3C62 and type(_0x3C62.attackSpeedMult) ==string.char(102,117,110,99,116,105,111,110)then
local _0x2E45, _0x27B2 = pcall(_0x3C62.attackSpeedMult, _0x465E)
if _0x2E45 and type(_0x27B2) ==string.char(110,117,109,98,101,114)and _0x27B2 > 0 then
_0xC1D4 = _0x27B2
end
end
local _0x2D1B = _0x2CC1:GetSignalEvent()
if _0x2D1B == nil then
_0x2CC1.CombatStatus =string.char(83,105,103,110,97,108,69,118,101,110,116,32,109,105,115,115,105,110,103)return nil
end
local _0x0903, _0xE05A = pcall(function()
_0x2D1B:FireServer(string.char(67,111,109,98,97,116,95,83,101,114,118,105,99,101), _0xD3FD, _0x4E9D, false,
(_0x4E44 - _0x3F32) / _0xC1D4, false, nil)
end)
if not _0x0903 then
_0x2CC1.CombatStatus =string.char(101,114,114,111,114,58,32).. tostring(_0xE05A)
return nil
end
_0x2CC1.LastCombo = _0x4E9D
end
if _0x3C62 then
_0x3C62.Last_Combo = _0x4E9D
end
_0x2CC1.ComboValue.Value = (_0x4E9D == _0x1784 or _0x4E9D == 7) and 1 or _0x4E9D + 1
_0x2CC1.LastPunch = tick()
_0x2CC1.CombatStatus = (string.char(112,117,110,99,104,105,110,103,32,37,115,32,99,111,109,98,111,32,37,100,47,37,100)):format(_0xD3FD, _0x4E9D, _0x1784)
return _0x2CC1:GetGapFor(_0x30A2)
end
function _0x2CC1:Swing()
if _0x2CC1:IsCombatStale() and tick() - (_0x2CC1.ResolvedAt or 0) > 2 then
_0x2CC1:ResolveCombat()
end
if _0x2CC1.Route == 1 then
local _0xAA84, _0xD519 = pcall(_0x2CC1.Punch)
if not _0xAA84 then
_0x2CC1.CombatStatus =string.char(112,117,110,99,104,40,41,32,101,114,114,111,114,101,100,58,32).. tostring(_0xD519)
elseif _0xD519 == nil then
_0x2CC1.CombatStatus =string.char(112,117,110,99,104,40,41,32,114,101,102,117,115,101,100,32,45,32,117,115,105,110,103,32,99,111,109,98,97,116,83,116,101,112)local _0x16FB, _0xC6CA = pcall(_0x2CC1.CombatStep, _0x2CC1)
return (_0x16FB and _0xC6CA) or 0.25
else
_0x2CC1.CombatStatus = (string.char(112,117,110,99,104,105,110,103,32,40,110,101,120,116,32,105,110,32,37,46,50,102,115,41)):format(_0xD519)
return _0xD519
end
return 0.25
end
local _0xAA84, _0xC6CA = pcall(_0x2CC1.CombatStep, _0x2CC1)
if not _0xAA84 then
_0x2CC1.CombatStatus =string.char(101,114,114,111,114,58,32).. tostring(_0xC6CA)
end
return (_0xAA84 and _0xC6CA) or 0.25
end_0x2CC1.Quest =string.char(73,108,108,32,102,105,110,100,32,116,104,101,32,102,111,114,103,101,40,76,118,32,54,53,41)_0x2CC1.Portal = Vector3.new(-1594, 1003, 1145)
_0x2CC1.Pad =string.char(79,117,119,105,103,97,104,97,114,97,80,114,111,109,112,116,80,97,100)function _0x2CC1:GetQuestState()
local _0x8FB3 = _0xE7C2:FindFirstChild(string.char(80,108,97,121,101,114,95,83,101,114,118,105,99,101))
local _0x95C8 = _0x8FB3 and _0x8FB3:FindFirstChild(string.char(68,97,116,97))
local _0xCD0F = _0x95C8 and _0x95C8:FindFirstChild(_0x465E.Name)
local _0xEE13 = _0xCD0F and _0xCD0F:FindFirstChild(string.char(115,108,111,116,69,113,117,105,112,112,101,100))
local _0xCFFA = _0xCD0F and _0xCD0F:FindFirstChild(string.char(115,108,111,116,115))
local _0xDF4C = _0xCFFA and _0xCFFA:FindFirstChild(string.char(83,108,111,116).. tostring(_0xEE13 and _0xEE13.Value or 1))
local _0xC287 = _0xDF4C and _0xDF4C:FindFirstChild(string.char(81,117,101,115,116,115))
if _0xC287 == nil then
returnstring.char(117,110,107,110,111,119,110)end
for _, FolderName in {string.char(67,111,109,112,108,101,116,101,100),string.char(72,111,108,100,101,114)} do
local _0xEF85 = _0xC287:FindFirstChild(FolderName)
for _, _0x25A8 in (_0xEF85 and _0xEF85:GetChildren() or {}) do
if _0x25A8.Name == _0x2CC1.Quest then
return FolderName ==string.char(67,111,109,112,108,101,116,101,100)andstring.char(99,111,109,112,108,101,116,101,100)orstring.char(104,101,108,100)end
end
end
returnstring.char(110,111,110,101)end
function _0x2CC1:GetPortalPrompt()
local _0x20A9 = _0x03DD:FindFirstChild(string.char(77,97,112))
local _0x73A1 = _0x20A9 and _0x20A9:FindFirstChild(_0x2CC1.Pad)
local _0xCB82 = _0x73A1 and _0x73A1:FindFirstChildWhichIsA(string.char(80,114,111,120,105,109,105,116,121,80,114,111,109,112,116), true)
if _0xCB82 ~= nil then
return _0xCB82
end
for _, Descendant in _0x03DD:GetDescendants() do
if Descendant:IsA(string.char(80,114,111,120,105,109,105,116,121,80,114,111,109,112,116)) and Descendant.Name ==string.char(79,117,119,105,103,97,104,97,114,97)and Descendant.ActionText ==string.char(69,110,116,101,114)then
return Descendant
end
end
end
_0x2CC1.Files = {
Hub =string.char(104,117,98,95,100,117,110,103,101,111,110,95,118,50,95,86,97,100,101,114,85,73,46,108,117,97),
_0x8574 =string.char(77,97,105,110,95,118,50,95,86,97,100,101,114,85,73,46,108,117,97),
}
function _0x2CC1:QueueRouter()
if _queue_on_teleport == nil then
returnstring.char(110,111,32,113,117,101,117,101,95,111,110,95,116,101,108,101,112,111,114,116)end
if _clear_teleport_queue ~= nil then
pcall(_clear_teleport_queue)
endlocal _0x8D5D = (string.char(116,97,115,107,46,119,97,105,116,40,56,41,32,105,102,32,103,97,109,101,46,80,108,97,99,101,73,100,32,61,61,32,37,100,32,116,104,101,110,32,108,111,97,100,115,116,114,105,110,103,40,114,101,97,100,102,105,108,101,40,37,113,41,41,40,41,32,101,108,115,101,32,108,111,97,100,115,116,114,105,110,103,40,114,101,97,100,102,105,108,101,40,37,113,41,41,40,41,32,101,110,100))
:format(75556147183481, _0x2CC1.Files.Hub, _0x2CC1.Files.Main)
local _0xAA84 = pcall(_queue_on_teleport, _0x8D5D)
return _0xAA84 andstring.char(97,114,109,101,100)orstring.char(114,101,102,117,115,101,100,32,98,121,32,116,104,101,32,101,120,101,99,117,116,111,114)end
function _0x2CC1:EnterDungeon()
if game.PlaceId == 75556147183481 then
return true,string.char(97,108,114,101,97,100,121,32,105,110,32,79,117,119,105,103,97,104,97,114,97)end
if game.PlaceId ~= 136406881576517 then
return false,string.char(110,111,116,32,105,110,32,79,117,119,108,97,110,100)end
if _0x2CC1:IsOutOfLives() then
return false,string.char(111,117,116,32,111,102,32,108,105,118,101,115,32,45,32,116,104,101,32,112,111,114,116,97,108,32,119,105,108,108,32,110,111,116,32,116,97,107,101,32,121,111,117,32,97,103,97,105,110)end
local _0x25A8 = _0x2CC1:GetQuestState()
if _0x25A8 ==string.char(110,111,110,101)then
return false,string.char(113,117,101,115,116,32,110,111,116,32,100,111,110,101,32,45,32,116,97,108,107,32,116,111,32,66,108,97,99,107,115,109,105,116,104,32,84,111,103,97,110,101,32,102,105,114,115,116)end
local _0x75E6 = _0x2CC1:GetRoot()
if _0x75E6 == nil then
return false,string.char(110,111,32,99,104,97,114,97,99,116,101,114)end
_0x75E6.CFrame = CFrame.new(_0x2CC1.Portal + Vector3.new(0, 3, 4))
_0x75E6.AssemblyLinearVelocity = Vector3.zero
_0x75E6.AssemblyAngularVelocity = Vector3.zero
local _0xCB82
local _0x9F15 = tick() + 8
repeat
_0xCB82 = _0x2CC1:GetPortalPrompt()
if _0xCB82 == nil then
task.wait(0.3)
end
until _0xCB82 ~= nil or tick() > _0x9F15
if _0xCB82 == nil then
return false,string.char(112,111,114,116,97,108,32,112,114,111,109,112,116,32,110,101,118,101,114,32,115,116,114,101,97,109,101,100,32,105,110)end
if not _0xCB82.Enabled then
return false,string.char(112,111,114,116,97,108,32,100,105,115,97,98,108,101,100,32,45,32,105,115,32,116,104,101,32,102,111,114,103,101,32,113,117,101,115,116,32,99,111,109,112,108,101,116,101,100,63)end
_0x2CC1:QueueRouter()
if _fireproximityprompt then
pcall(_fireproximityprompt, _0xCB82)
else
pcall(function()
local _0xCB98 = _0xCB82.HoldDuration
_0xCB82.HoldDuration = 0
_0xCB82:InputHoldBegin()
_0xCB82:InputHoldEnd()
_0xCB82.HoldDuration = _0xCB98
end)
end
return true,string.char(112,111,114,116,97,108,32,102,105,114,101,100)end_0x2CC1.SlotNumber = { One = 1, Two = 2, Three = 3, Four = 4, Five = 5 }
function _0x2CC1:GetEquippedSlotValue()
local _0xD4E8 = _0x465E:FindFirstChild(string.char(73,116,101,109,115,95,67,111,110,102,105,103))
return _0xD4E8 and _0xD4E8:FindFirstChild(string.char(69,113,117,105,112,112,101,100)) or nil
end
function _0x2CC1:IsWeaponDrawn()
local _0x6EDD = _0x2CC1:GetEquippedSlotValue()
return _0x6EDD ~= nil and _0x6EDD.Value ~= 0
end
function _0x2CC1:GetFilledSlots()
local _0x8FB3 = _0xE7C2:FindFirstChild(string.char(80,108,97,121,101,114,95,83,101,114,118,105,99,101))
local _0x95C8 = _0x8FB3 and _0x8FB3:FindFirstChild(string.char(68,97,116,97))
local _0xCD0F = _0x95C8 and _0x95C8:FindFirstChild(_0x465E.Name)
local _0xEE13 = _0xCD0F and _0xCD0F:FindFirstChild(string.char(115,108,111,116,69,113,117,105,112,112,101,100))
local _0xCFFA = _0xCD0F and _0xCD0F:FindFirstChild(string.char(115,108,111,116,115))
local _0xDF4C = _0xCFFA and _0xCFFA:FindFirstChild(string.char(83,108,111,116).. tostring(_0xEE13 and _0xEE13.Value or 1))
local _0xB380 = _0xDF4C and _0xDF4C:FindFirstChild(string.char(73,110,118,101,110,116,111,114,121))
local _0x4809 = _0xB380 and _0xB380:FindFirstChild(string.char(84,111,111,108,98,97,114))
local _0x7CD9 = {}
for _, Name in {string.char(79,110,101),string.char(84,119,111),string.char(84,104,114,101,101),string.char(70,111,117,114),string.char(70,105,118,101)} do
local _0x5824 = _0x4809 and _0x4809:FindFirstChild(Name)
if _0x5824 ~= nil and tonumber(_0x5824.Value) ~= nil and _0x5824.Value ~= 0 then
table.insert(_0x7CD9, Name)
end
end
return _0x7CD9
end
function _0x2CC1:DrawWeapon()
if _0x2CC1:IsWeaponDrawn() then
return true,string.char(97,108,114,101,97,100,121,32,100,114,97,119,110)end
local _0x91A3 = _0x2CC1.Slot
local _0x7CD9 = _0x2CC1:GetFilledSlots()
if _0x2CC1.SlotNumber[_0x91A3] == nil or not table.find(_0x7CD9, _0x91A3) then
_0x91A3 = _0x7CD9[1]
end
if _0x91A3 == nil then
return false,string.char(116,111,111,108,98,97,114,32,105,115,32,101,109,112,116,121)end
local _0x7C4F = _0x2CC1.SlotNumber[_0x91A3]
local _0x6EDD = _0x2CC1:GetEquippedSlotValue()
if _0x6EDD ~= nil then
local _0xAA84 = pcall(function() _0x6EDD.Value = _0x7C4F end)
if not _0xAA84 then
return false,string.char(99,111,117,108,100,32,110,111,116,32,115,101,116,32,73,116,101,109,115,95,67,111,110,102,105,103,46,69,113,117,105,112,112,101,100)end
else
local _0x2D1B = _0x2CC1:GetSignalEvent()
if _0x2D1B == nil then
return false,string.char(83,105,103,110,97,108,69,118,101,110,116,32,109,105,115,115,105,110,103)end
pcall(function() _0x2D1B:FireServer(string.char(73,116,101,109,95,69,113,117,105,112), _0x7C4F) end)
end
local _0x9F15 = tick() + 3
repeat
task.wait(0.2)
until _0x2CC1:IsWeaponDrawn() or tick() > _0x9F15
if _0x2CC1:IsWeaponDrawn() then
return true,string.char(100,114,101,119,32,115,108,111,116,32).. _0x91A3
end
return false,string.char(115,101,110,116,32,98,117,116,32,110,111,116,104,105,110,103,32,100,114,101,119)endfunction _0x2CC1:GetHearts()
local _0x4E9D = _0x465E:GetAttribute(string.char(72,101,97,114,116,115))
if _0x4E9D == nil then
return nil
end
return tonumber(_0x4E9D) or 0
end
function _0x2CC1:IsOutOfLives()
local _0xBC60 = _0x2CC1:GetHearts()
return _0xBC60 ~= nil and _0xBC60 <= 0
end
function _0x2CC1:GetState()
return tostring(game:GetService(string.char(87,111,114,107,115,112,97,99,101)):GetAttribute(string.char(77,105,110,105,103,97,109,101,83,116,97,116,101)) orstring.char(63))
end
function _0x2CC1:IsClimbing()
return _0x2CC1:GetState() ==string.char(67,108,105,109,98,105,110,103)end
function _0x2CC1:IsReadied()
return _0x465E:GetAttribute(string.char(82,101,97,100,105,101,100)) == true
end
function _0x2CC1:GetStartPrompt()
local _0x20A9 = _0x03DD:FindFirstChild(string.char(77,97,112))
local _0xA52F = _0x20A9 and _0x20A9:FindFirstChild(string.char(77,105,110,105,103,97,109,101,32,77,97,112))
local _0x73A1 = _0xA52F and _0xA52F:FindFirstChild(string.char(83,116,97,114,116,80,97,100), true)
if _0x73A1 ~= nil then
local _0xCB82 = _0x73A1:FindFirstChildWhichIsA(string.char(80,114,111,120,105,109,105,116,121,80,114,111,109,112,116), true)
if _0xCB82 ~= nil then
return _0xCB82, _0x73A1
end
end
for _, Descendant in _0x03DD:GetDescendants() do
if Descendant:IsA(string.char(80,114,111,120,105,109,105,116,121,80,114,111,109,112,116)) and Descendant:GetAttribute(string.char(80,114,111,109,112,116,83,116,121,108,101)) ==string.char(67,97,114,100)then
return Descendant, Descendant.Parent
end
end
end
function _0x2CC1:FirePrompt(_0xCB82)
if _fireproximityprompt then
return pcall(_fireproximityprompt, _0xCB82)
end
return pcall(function()
local _0xCB98 = _0xCB82.HoldDuration
_0xCB82.HoldDuration = 0
_0xCB82:InputHoldBegin()
_0xCB82:InputHoldEnd()
_0xCB82.HoldDuration = _0xCB98
end)
end
function _0x2CC1:ReadyUp()
if _0x2CC1:IsReadied() then
return true,string.char(97,108,114,101,97,100,121,32,114,101,97,100,105,101,100)end
if _0x2CC1:IsClimbing() then
return false,string.char(97,108,114,101,97,100,121,32,99,108,105,109,98,105,110,103)end
if _0x2CC1:IsOutOfLives() then
return false,string.char(111,117,116,32,111,102,32,108,105,118,101,115,32,45,32,116,104,105,115,32,114,117,110,32,105,115,32,102,105,110,105,115,104,101,100)end
local _0xCB82, _0x73A1 = _0x2CC1:GetStartPrompt()
if _0xCB82 == nil then
return false,string.char(110,111,32,83,116,97,114,116,80,97,100,32,112,114,111,109,112,116,32,45,32,110,111,116,32,105,110,32,116,104,101,32,108,111,98,98,121,63)end
local _0x75E6 = _0x2CC1:GetRoot()
if _0x75E6 ~= nil and _0x73A1 ~= nil then
local _0xAA84, _0x4753 = pcall(function()
return _0x73A1:IsA(string.char(77,111,100,101,108)) and _0x73A1:GetPivot() or CFrame.new(_0x73A1.Position)
end)
if _0xAA84 then
_0x75E6.CFrame = CFrame.new(_0x4753.Position + Vector3.new(0, 4, 0))
_0x75E6.AssemblyLinearVelocity = Vector3.zero
task.wait(0.4)
end
end
_0x2CC1:FirePrompt(_0xCB82)
local _0x9F15 = tick() + 4
repeat
task.wait(0.2)
until _0x2CC1:IsReadied() or _0x2CC1:IsClimbing() or tick() > _0x9F15
if _0x2CC1:IsReadied() or _0x2CC1:IsClimbing() then
return true,string.char(114,101,97,100,105,101,100)end
return false,string.char(112,114,111,109,112,116,32,102,105,114,101,100,32,98,117,116,32,110,101,118,101,114,32,114,101,97,100,105,101,100)endfunction _0x2CC1:DropOldWindows()
local _0x00FF = { game:GetService(string.char(67,111,114,101,71,117,105)) }
if typeof(gethui) ==string.char(102,117,110,99,116,105,111,110)then
table.insert(_0x00FF, gethui())
end
local function _0x9CE1(_0x8D2F, Screen)
for _, Child in _0x8D2F:GetChildren() do
local _0xEAAE = Child:IsA(string.char(83,99,114,101,101,110,71,117,105)) and Child or Screen
local _0xAA84, _0xB9E9 = pcall(function() return Child.Text end)
if _0xAA84 and type(_0xB9E9) ==string.char(115,116,114,105,110,103)and string.find(_0xB9E9,string.char(118,97,100,101,114,104,117,103,32,45,32,79,117,119,105,103,97,104,97,114,97), 1, true)
and _0xEAAE ~= nil then
pcall(function() _0xEAAE:Destroy() end)
return
end
_0x9CE1(Child, _0xEAAE)
end
end
for _, GuiRoot in _0x00FF do
pcall(_0x9CE1, GuiRoot, nil)
end
end_0x2CC1:DropOldWindows()
local _0x14A9 = _0xA034:CreateWindow({
_0x41E6 =string.char(118,97,100,101,114,104,117,103,32,45,32,79,117,119,105,103,97,104,97,114,97),
SubTitle =string.char(100,117,110,103,101,111,110),
TabWidth = 150,
Size = UDim2.fromOffset(520, 360),
Acrylic = false,
Theme =string.char(68,97,114,107,101,114),
MinimizeKey = Enum.KeyCode.RightControl,
})
local _0xC03C = {
Run = _0x14A9:AddTab({ _0x41E6 =string.char(82,117,110), Icon =string.char(115,119,111,114,100,115)}),
Cards = _0x14A9:AddTab({ _0x41E6 =string.char(67,97,114,100,115), Icon =string.char(108,97,121,101,114,115)}),
}_0xC03C.Run:AddToggle(string.char(65,117,116,111,69,110,116,101,114), {
_0x41E6 =string.char(65,117,116,111,32,69,110,116,101,114,32,68,117,110,103,101,111,110),
Description =string.char(70,114,111,109,32,79,117,119,108,97,110,100,44,32,119,97,108,107,115,32,116,111,32,116,104,101,32,112,111,114,116,97,108,32,97,110,100,32,103,111,101,115,32,105,110),
Default = false,
}):OnChanged(function(_0x4E9D)
_0x2CC1.AutoEnter = _0x4E9D
end)
_0xC03C.Run:AddButton({
_0x41E6 =string.char(69,110,116,101,114,32,100,117,110,103,101,111,110,32,110,111,119),
Description =string.char(84,114,97,118,101,108,115,32,116,111,32,116,104,101,32,112,111,114,116,97,108,32,112,97,100,32,97,110,100,32,116,114,105,103,103,101,114,115,32,105,116,32,111,110,99,101),
Callback = function()
task.spawn(function()
_0x2CC1:RaiseIdentity()
local _0xAA84, _0x5F81 = _0x2CC1:EnterDungeon()
_0x2CC1.EnterStatus = tostring(_0x5F81)
print((string.char(91,100,117,110,103,101,111,110,93,32,101,110,116,101,114,58,32,37,115,32,45,32,37,115)):format(tostring(_0xAA84), tostring(_0x5F81)))
end)
end,
})
_0xC03C.Run:AddToggle(string.char(65,117,116,111,82,117,110), {
_0x41E6 =string.char(65,117,116,111,32,82,117,110),
Description =string.char(82,101,97,100,105,101,115,32,117,112,32,105,110,32,116,104,101,32,108,111,98,98,121,32,97,110,100,32,115,116,97,114,116,115,32,116,104,101,32,110,101,120,116,32,99,108,105,109,98,32,119,104,101,110,32,111,110,101,32,101,110,100,115),
Default = false,
}):OnChanged(function(_0x4E9D)
_0x2CC1.AutoRun = _0x4E9D
end)
_0xC03C.Run:AddButton({
_0x41E6 =string.char(82,101,97,100,121,32,117,112,32,110,111,119),
Description =string.char(87,97,108,107,115,32,116,111,32,116,104,101,32,83,116,97,114,116,80,97,100,32,97,110,100,32,116,114,105,103,103,101,114,115,32,105,116,32,111,110,99,101),
Callback = function()
task.spawn(function()
_0x2CC1:RaiseIdentity()
local _0xAA84, _0x5F81 = _0x2CC1:ReadyUp()
print((string.char(91,100,117,110,103,101,111,110,93,32,114,101,97,100,121,32,117,112,58,32,37,115,32,45,32,37,115)):format(tostring(_0xAA84), tostring(_0x5F81)))
end)
end,
})
_0xC03C.Run:AddToggle(string.char(65,117,116,111,69,113,117,105,112), {
_0x41E6 =string.char(65,117,116,111,32,69,113,117,105,112,32,87,101,97,112,111,110),
Description =string.char(68,114,97,119,115,32,97,32,119,101,97,112,111,110,32,111,110,32,97,114,114,105,118,97,108,32,45,32,116,104,101,32,112,111,114,116,97,108,32,108,101,97,118,101,115,32,121,111,117,32,101,109,112,116,121,32,104,97,110,100,101,100),
Default = true,
}):OnChanged(function(_0x4E9D)
_0x2CC1.AutoEquip = _0x4E9D
end)
_0xC03C.Run:AddDropdown(string.char(87,101,97,112,111,110,83,108,111,116), {
_0x41E6 =string.char(87,101,97,112,111,110,32,115,108,111,116),
Description =string.char(87,104,105,99,104,32,116,111,111,108,98,97,114,32,115,108,111,116,32,116,111,32,100,114,97,119,46,32,70,97,108,108,115,32,98,97,99,107,32,116,111,32,116,104,101,32,102,105,114,115,116,32,102,105,108,108,101,100,32,111,110,101),
_0xEC0B = {string.char(79,110,101),string.char(84,119,111),string.char(84,104,114,101,101),string.char(70,111,117,114),string.char(70,105,118,101)},
Multi = false,
Default = 1,
}):OnChanged(function(_0x4E9D)
_0x2CC1.Slot = _0x4E9D
end)
_0xC03C.Run:AddToggle(string.char(65,117,116,111,67,111,109,98,97,116), {
_0x41E6 =string.char(65,117,116,111,32,67,111,109,98,97,116),
Description =string.char(65,116,116,97,99,107,32,116,104,101,32,110,101,97,114,101,115,116,32,101,110,101,109,121,46,32,70,114,105,101,110,100,108,105,101,115,32,97,114,101,32,110,101,118,101,114,32,116,97,114,103,101,116,101,100),
Default = false,
}):OnChanged(function(_0x4E9D)
_0x2CC1.Combat = _0x4E9D
end)
_0xC03C.Run:AddSlider(string.char(82,101,97,99,104), {
_0x41E6 =string.char(82,101,97,99,104),
Description =string.char(73,103,110,111,114,101,32,101,110,101,109,105,101,115,32,102,117,114,116,104,101,114,32,97,119,97,121,32,116,104,97,110,32,116,104,105,115),
Default = 500, Min = 50, Max = 2000, Rounding = 0,
}):OnChanged(function(_0x4E9D)
_0x2CC1.Reach = _0x4E9D
end)
_0x2CC1.Reach = 500
_0xC03C.Run:AddSlider(string.char(68,105,115,116,97,110,99,101), {
_0x41E6 =string.char(65,116,116,97,99,107,32,100,105,115,116,97,110,99,101),
Description =string.char(72,111,119,32,99,108,111,115,101,32,116,111,32,115,105,116,32,119,104,105,108,101,32,115,119,105,110,103,105,110,103),
Default = 3.5, Min = 1, Max = 15, Rounding = 1,
}):OnChanged(function(_0x4E9D)
_0x2CC1.Distance = _0x4E9D
end)
_0xC03C.Run:AddDropdown(string.char(83,116,97,110,99,101), {
_0x41E6 =string.char(83,116,97,110,99,101),
Description =string.char(65,98,111,118,101,32,97,110,100,32,85,110,100,101,114,103,114,111,117,110,100,32,115,105,116,32,111,110,32,116,104,101,32,116,97,114,103,101,116,39,115,32,89,32,97,120,105,115,32,45,32,116,104,101,32,111,110,101,32,115,105,100,101,32,116,104,101,121,32,99,97,110,110,111,116,32,116,117,114,110,32,116,111,32,102,97,99,101),
_0xEC0B = {string.char(66,101,104,105,110,100),string.char(65,98,111,118,101),string.char(85,110,100,101,114,103,114,111,117,110,100)},
Multi = false,
Default = 1,
}):OnChanged(function(_0x4E9D)
_0x2CC1.Stance = _0x4E9D
end)
_0xC03C.Run:AddToggle(string.char(65,118,111,105,100,66,108,111,99,107), {
_0x41E6 =string.char(65,118,111,105,100,32,98,108,111,99,107),
Description =string.char(83,116,97,110,100,32,111,102,102,32,97,110,100,32,104,111,108,100,32,115,119,105,110,103,115,32,119,104,105,108,101,32,116,104,101,32,116,97,114,103,101,116,32,105,115,32,98,108,111,99,107,105,110,103),
Default = true,
}):OnChanged(function(_0x4E9D)
_0x2CC1.AvoidBlock = _0x4E9D
end)
_0xC03C.Run:AddToggle(string.char(67,111,109,98,111,66,97,99,107,111,102,102), {
_0x41E6 =string.char(87,97,105,116,32,102,111,114,32,99,111,111,108,100,111,119,110),
Description =string.char(83,116,101,112,32,98,97,99,107,32,102,111,114,32,116,104,101,32,114,101,99,111,118,101,114,121,32,97,102,116,101,114,32,97,32,99,111,109,98,111,32,102,105,110,105,115,104,101,114,32,108,97,110,100,115),
Default = true,
}):OnChanged(function(_0x4E9D)
_0x2CC1.ComboBackoff = _0x4E9D
end)
_0xC03C.Run:AddToggle(string.char(65,117,116,111,76,111,111,116), {
_0x41E6 =string.char(65,117,116,111,32,108,111,111,116),
Description =string.char(79,112,101,110,32,109,111,98,32,100,114,111,112,115,32,97,110,100,32,99,104,101,115,116,115),
Default = true,
}):OnChanged(function(_0x4E9D)
_0x2CC1.AutoLoot = _0x4E9D
end)
do
local _0xD516 = {string.char(49,44,48,48,48,32,69,120,112),string.char(49,44,48,48,48,32,87,101,110),string.char(82,101,102,105,110,101,109,101,110,116,32,79,114,101),string.char(77,121,116,104,105,99,32,82,101,102,105,110,101,109,101,110,116,32,79,114,101)}
local _0xFC28 = {}
local function _0x0D29()
local _0xF483 = {}
if _0x2CC1.BuyOn then
for _, _0xA75F in _0xD516 do
if _0xFC28[_0xA75F] then
table.insert(_0xF483, _0xA75F)
end
end
end
_0x2CC1.BuyList = _0xF483
end
_0xC03C.Run:AddDropdown(string.char(66,117,121,73,116,101,109,115), {
_0x41E6 =string.char(66,117,121,32,119,105,116,104,32,116,111,119,101,114,32,112,111,105,110,116,115),
Description =string.char(83,112,101,110,116,32,119,104,101,110,32,116,104,101,32,104,101,97,114,116,115,32,114,117,110,32,111,117,116,44,32,116,111,112,32,111,102,32,116,104,101,32,108,105,115,116,32,102,105,114,115,116),
_0xEC0B = _0xD516,
Multi = true,
Default = {string.char(49,44,48,48,48,32,69,120,112)},
}):OnChanged(function(_0x4E9D)
_0xFC28 = {}
if type(_0x4E9D) ==string.char(116,97,98,108,101)then
for _0xA75F, Selected in pairs(_0x4E9D) do
if Selected then
_0xFC28[_0xA75F] = true
end
end
end
_0x0D29()
end)
_0xC03C.Run:AddToggle(string.char(65,117,116,111,66,117,121), {
_0x41E6 =string.char(65,117,116,111,32,98,117,121),
Description =string.char(83,112,101,110,100,32,116,104,101,32,114,117,110,39,115,32,112,111,105,110,116,115,32,111,110,32,116,104,101,32,105,116,101,109,115,32,97,98,111,118,101,32,119,104,101,110,32,105,116,32,101,110,100,115),
Default = false,
}):OnChanged(function(_0x4E9D)
_0x2CC1.BuyOn = _0x4E9D
_0x0D29()
end)
end
_0x2CC1.RunStatus = _0xC03C.Run:AddParagraph({
_0x41E6 =string.char(83,116,97,116,117,115),
Content =string.char(105,100,108,101),
})_0xC03C.Cards:AddToggle(string.char(65,117,116,111,67,97,114,100,115), {
_0x41E6 =string.char(65,117,116,111,32,80,105,99,107,32,67,97,114,100,115),
Description =string.char(82,101,97,100,115,32,116,104,101,32,98,111,97,114,100,32,97,110,100,32,112,105,99,107,115,32,98,121,32,116,104,101,32,112,114,105,111,114,105,116,121,32,108,105,115,116,32,98,101,108,111,119),
Default = false,
}):OnChanged(function(_0x4E9D)
_0x2CC1.Cards = _0x4E9D
end)
function _0x2CC1:GetSelectedSet(_0x4E9D)
local _0x0E20 = {}
if type(_0x4E9D) ==string.char(116,97,98,108,101)then
for _0xEF6F, Selected in pairs(_0x4E9D) do
if Selected == true then
_0x0E20[_0xEF6F] = true
elseif type(Selected) ==string.char(115,116,114,105,110,103)then
_0x0E20[Selected] = true
end
end
end
return _0x0E20
end
function _0x2CC1:GetDefaultList(_0x0E20)
local _0xF483 = {}
for _, _0x41E6 in _0x6D65 do
if _0x0E20[_0x41E6] then
table.insert(_0xF483, _0x41E6)
end
end
return _0xF483
end
_0xC03C.Cards:AddDropdown(string.char(80,114,105,111,114,105,116,121), {
_0x41E6 =string.char(87,97,110,116),
Description =string.char(67,97,114,100,115,32,119,111,114,116,104,32,116,97,107,105,110,103,46,32,82,97,110,107,101,100,32,98,121,32,116,104,101,32,98,117,105,108,116,45,105,110,32,111,114,100,101,114,44,32,98,101,115,116,32,102,105,114,115,116),
_0xEC0B = _0x6D65,
Multi = true,
Default = _0x2CC1:GetDefaultList(_0x2CC1.Priority),
}):OnChanged(function(_0x4E9D)
local _0x0E20 = _0x2CC1:GetSelectedSet(_0x4E9D)
if next(_0x0E20) ~= nil then
_0x2CC1.Priority = _0x0E20
end
end)
_0xC03C.Cards:AddDropdown(string.char(65,118,111,105,100), {
_0x41E6 =string.char(78,101,118,101,114,32,116,97,107,101),
Description =string.char(80,97,99,105,102,105,115,116,32,100,105,115,97,98,108,101,115,32,97,108,108,32,115,107,105,108,108,115,32,102,111,114,32,116,104,101,32,119,104,111,108,101,32,114,117,110,32,45,32,110,101,118,101,114,32,116,97,107,101,32,105,116),
_0xEC0B = _0x6D65,
Multi = true,
Default = _0x2CC1:GetDefaultList(_0x2CC1.Avoid),
}):OnChanged(function(_0x4E9D)
_0x2CC1.Avoid = _0x2CC1:GetSelectedSet(_0x4E9D)
end)
_0xC03C.Cards:AddDropdown(string.char(70,97,108,108,98,97,99,107), {
_0x41E6 =string.char(87,104,101,110,32,110,111,116,104,105,110,103,32,109,97,116,99,104,101,115),
_0xEC0B = {string.char(83,107,105,112),string.char(84,97,107,101,32,102,105,114,115,116)},
Multi = false,
Default = 1,
}):OnChanged(function(_0x4E9D)
_0x2CC1.Fallback = _0x4E9D
end)
_0xC03C.Cards:AddToggle(string.char(65,117,116,111,83,107,105,112), {
_0x41E6 =string.char(83,107,105,112,32,101,118,101,114,121,116,104,105,110,103),
Description =string.char(84,97,107,101,115,32,110,111,32,99,97,114,100,32,97,116,32,97,108,108,46,32,79,118,101,114,114,105,100,101,115,32,116,104,101,32,112,114,105,111,114,105,116,121,32,108,105,115,116,32,98,101,108,111,119),
Default = false,
}):OnChanged(function(_0x4E9D)
_0x2CC1.SkipAll = _0x4E9D
end)
_0x2CC1.CardStatus = _0xC03C.Cards:AddParagraph({
_0x41E6 =string.char(76,97,115,116,32,98,111,97,114,100),
Content =string.char(110,111,110,101,32,121,101,116),
})
_0xC03C.Cards:AddButton({
_0x41E6 =string.char(68,117,109,112,32,99,97,114,100,32,99,97,116,97,108,111,103,117,101),
Description =string.char(69,118,101,114,121,32,100,105,115,116,105,110,99,116,32,99,97,114,100,32,115,101,101,110,32,115,111,32,102,97,114,44,32,116,111,32,116,104,101,32,99,111,110,115,111,108,101),
Callback = function()
local _0x8761 = {}
for _0x41E6 in pairs(_0x2CC1.Seen) do
table.insert(_0x8761, _0x41E6)
end
table.sort(_0x8761)
print((string.char(91,99,97,114,100,115,93,32,61,61,61,61,32,37,100,32,100,105,115,116,105,110,99,116,32,99,97,114,100,115,32,111,118,101,114,32,37,100,32,104,97,110,100,115,32,61,61,61,61)):format(
#_0x8761, _0x2CC1.Hands))
for _, _0x41E6 in _0x8761 do
local _0x5824 = _0x2CC1.Seen[_0x41E6]
print((string.char(91,99,97,114,100,115,93,32,37,51,100,120,32,32,37,45,50,56,115,32,124,32,37,115)):format(
_0x5824.count, _0x41E6, _0x5824.desc))
end
_0x2CC1:RaiseIdentity()
pcall(function()
_0x2CC1.CardStatus:SetDesc((string.char(37,100,32,100,105,115,116,105,110,99,116,32,99,97,114,100,115,32,115,101,101,110,32,111,118,101,114,32,37,100,32,104,97,110,100,115,32,45,32,102,117,108,108,32,108,105,115,116,32,105,110,32,116,104,101,32,99,111,110,115,111,108,101))
:format(#_0x8761, _0x2CC1.Hands))
end)
end,
})
_0xC03C.Cards:AddButton({
_0x41E6 =string.char(82,101,97,100,32,98,111,97,114,100,32,110,111,119),
Description =string.char(83,104,111,119,115,32,116,104,101,32,99,117,114,114,101,110,116,32,104,97,110,100,32,119,105,116,104,111,117,116,32,112,105,99,107,105,110,103,32,97,110,121,116,104,105,110,103),
Callback = function()
_0x2CC1:RaiseIdentity()
local _0x8641 = _0x2CC1:GetHand()
if _0x8641 == nil then
_0x2CC1.CardStatus:SetDesc(string.char(110,111,32,98,111,97,114,100,32,111,110,32,115,99,114,101,101,110))
return
end
local _0xF3C0 = {}
for _, Card in _0x8641 do
table.insert(_0xF3C0, (string.char(37,115,32,32,37,115)):format(Card.id, Card.title))
end
local _0xEE86, _0x95C4 = _0x2CC1:ChooseCard(_0x8641)
table.insert(_0xF3C0,"")
table.insert(_0xF3C0, _0xEE86
and (string.char(119,111,117,108,100,32,112,105,99,107,58,32,37,115,32,40,37,115,41)):format(_0xEE86.title, _0x95C4)
or (string.char(119,111,117,108,100,32,115,107,105,112,32,45,32).. tostring(_0x95C4)))
_0x2CC1.CardStatus:SetDesc(table.concat(_0xF3C0,string.char(10)))
end,
})if game.PlaceId == 75556147183481 then
_0x2CC1:QueueRouter()
enddo
if _G.__kaitunAntiIdle ~= nil then
pcall(function() _G.__kaitunAntiIdle:Disconnect() end)
_G.__kaitunAntiIdle = nil
end
local _0xAA84, _0x63A8 = pcall(game.GetService, game,string.char(86,105,114,116,117,97,108,85,115,101,114))
if _0xAA84 and _0x63A8 ~= nil then
_G.__kaitunAntiIdle = _0x465E.Idled:Connect(function()
pcall(function()
_0x63A8:CaptureController()
_0x63A8:ClickButton2(Vector2.new())
end)
end)
end
end_0x2CC1.OffersRoot = _0x2CC1:GetOffers()
if _0x2CC1.OffersRoot ~= nil then
_0x2CC1:Track(_0x2CC1.OffersRoot:GetPropertyChangedSignal(string.char(86,105,115,105,98,108,101)):Connect(function()
if _0x2CC1.OffersRoot.Visible and _0x2CC1.Cards then
task.wait(0.5)
pcall(_0x2CC1.HandleHand, _0x2CC1)
end
end))
end
coroutine.wrap(function()
while true do
if _0x2CC1.BreakLoop or not _0x2CC1:IsAlive() then break end
local _0xAA84, _0x8124 = pcall(function()
if _0x2CC1.Cards then
pcall(_0x2CC1.HandleHand, _0x2CC1)
end
task.wait(2)
end)
if _0x8124 then
if _0xFBA6 then warn(string.char(91,67,97,114,100,115,93,32,67,97,117,103,104,116,32,69,114,114,111,114,58), _0x8124) end
task.wait(1)
end
end
end)()coroutine.wrap(function()
while _0x43FF.Heartbeat:Wait() do
if _0x2CC1.BreakLoop or not _0x2CC1:IsAlive() then break end
local _0xAA84, _0x8124 = pcall(function()
if not _0x2CC1:IsAlive() or not _0x2CC1.Combat then
return
end
local _0xE66F = _0x2CC1.Held
if _0xE66F == nil or _0xE66F.Parent == nil then
return
end
local _0x7B7D = _0xE66F:FindFirstChildOfClass(string.char(72,117,109,97,110,111,105,100))
if _0x7B7D == nil or _0x7B7D.Health <= 0 then
_0x2CC1.Held = nil
return
end
local _0x75E6 = _0x2CC1:GetRoot()
if _0x75E6 == nil then
return
end
_0x2CC1.Shielded = _0x2CC1.AvoidBlock and _0x2CC1:IsShielded(_0xE66F) or false
local _0xAA84, _0x4753 = pcall(function() return _0xE66F:GetPivot() end)
if _0xAA84 then
_0x2CC1:PlaceAt(_0x75E6, _0x4753)
end
end)
if _0x8124 and _0xFBA6 then warn(string.char(91,80,111,115,105,116,105,111,110,105,110,103,93,32,67,97,117,103,104,116,32,69,114,114,111,114,58), _0x8124) end
end
end)()coroutine.wrap(function()
while true do
if _0x2CC1.BreakLoop or not _0x2CC1:IsAlive() then break end
local _0xAA84, _0x8124 = pcall(function()
if _0x2CC1.AutoEquip and (_0x2CC1.Combat or _0x2CC1.AutoRun) and not _0x2CC1:IsWeaponDrawn() then
local _0xAA84, _0x5F81 = _0x2CC1:DrawWeapon()
_0x2CC1.EquipStatus = tostring(_0x5F81)
task.wait(_0xAA84 and 2 or 5)
else
task.wait(2)
end
end)
if _0x8124 then
if _0xFBA6 then warn(string.char(91,69,113,117,105,112,93,32,67,97,117,103,104,116,32,69,114,114,111,114,58), _0x8124) end
task.wait(1)
end
end
end)()coroutine.wrap(function()
while true do
if _0x2CC1.BreakLoop or not _0x2CC1:IsAlive() then break end
local _0xAA84, _0x8124 = pcall(function()
if _0x2CC1.AutoEnter and game.PlaceId == 136406881576517 and not _0x2CC1:IsOutOfLives() then
local _0xAA84, _0x5F81 = _0x2CC1:EnterDungeon()
_0x2CC1.EnterStatus = tostring(_0x5F81)
task.wait(_0xAA84 and 12 or 6)
else
task.wait(2)
end
end)
if _0x8124 then
if _0xFBA6 then warn(string.char(91,69,110,116,101,114,93,32,67,97,117,103,104,116,32,69,114,114,111,114,58), _0x8124) end
task.wait(1)
end
end
end)()_0x2CC1.Prices = {
[string.char(49,44,48,48,48,32,69,120,112)] = 3500,
[string.char(49,44,48,48,48,32,87,101,110)] = 2500,
[string.char(82,101,102,105,110,101,109,101,110,116,32,79,114,101)] = 1500,
[string.char(77,121,116,104,105,99,32,82,101,102,105,110,101,109,101,110,116,32,79,114,101)] = 30000,
}
_0x2CC1.BuyList = {}
_0x2CC1.BuyKeep = 0
_0x2CC1.BuyStatus =string.char(105,100,108,101)_0x2CC1.SpentRun = false
_0x2CC1.AutoLoot = true
function _0x2CC1:GetPriceOf(_0xA75F)
local _0xAC3F = _0x2CC1.Prices[_0xA75F]
if _0xAC3F == nil and string.sub(_0xA75F, -8) ==string.char(32,77,97,115,116,101,114,121)then
_0xAC3F = 3000
end
return _0xAC3F
end
function _0x2CC1:GetRunPoints()
return tonumber(_0x465E:GetAttribute(string.char(82,117,110,80,111,105,110,116,115))) or 0
end
function _0x2CC1:SpendPoints(Reason)
if #_0x2CC1.BuyList == 0 then
returnstring.char(110,111,116,104,105,110,103,32,116,111,32,98,117,121,32,99,111,110,102,105,103,117,114,101,100)end
if _0x03DD:GetAttribute(string.char(77,105,110,105,103,97,109,101,82,117,110,70,114,101,115,104,83,116,97,114,116)) == true then
_0x2CC1.BuyStatus =string.char(114,111,103,117,101,108,105,107,101,32,114,117,110,32,45,32,116,104,101,32,115,104,111,112,115,32,107,101,101,112,32,110,111,116,104,105,110,103)return _0x2CC1.BuyStatus
end
local _0x6473 = _0xE7C2:FindFirstChild(string.char(67,111,109,109,117,110,105,99,97,116,105,111,110))
_0x6473 = _0x6473 and _0x6473:FindFirstChild(string.char(83,101,114,118,101,114,65,110,100,67,108,105,101,110,116))
_0x6473 = _0x6473 and _0x6473:FindFirstChild(string.char(83,105,103,110,97,108,115))
_0x6473 = _0x6473 and _0x6473:FindFirstChild(string.char(83,105,103,110,97,108,70,117,110,99,116,105,111,110))
_0x6473 = _0x6473 and _0x6473:FindFirstChild(string.char(70,117,110,99,116,105,111,110))
if _0x6473 == nil then
_0x2CC1.BuyStatus =string.char(83,105,103,110,97,108,70,117,110,99,116,105,111,110,32,109,105,115,115,105,110,103)return _0x2CC1.BuyStatus
end
local _0x9168 = {}
for _, _0xA75F in _0x2CC1.BuyList do
local _0xAC3F = _0x2CC1:GetPriceOf(_0xA75F)
local _0x8D59 = _0xAC3F and math.floor((_0x2CC1:GetRunPoints() - _0x2CC1.BuyKeep) / _0xAC3F) or 0
if _0x8D59 > 0 then
local _0xAA84, _0x8110 = pcall(function()
return _0x6473:InvokeServer(string.char(80,117,114,99,104,97,115,101,83,101,108,101,99,116,105,111,110), { [_0xA75F] = _0x8D59 })
end)
table.insert(_0x9168, (string.char(37,115,32,120,37,100,32,37,115)):format(_0xA75F, _0x8D59,
(_0xAA84 and _0x8110) andstring.char(98,111,117,103,104,116)or (string.char(114,101,102,117,115,101,100,32,40).. tostring(_0x8110) ..string.char(41))))
task.wait(0.5)
end
end
_0x2CC1.BuyStatus = (string.char(37,115,32,45,32,37,115,44,32,37,100,32,112,111,105,110,116,115,32,108,101,102,116)):format(tostring(Reason),
#_0x9168 > 0 and table.concat(_0x9168,string.char(44,32)) orstring.char(110,111,116,104,105,110,103,32,97,102,102,111,114,100,97,98,108,101), _0x2CC1:GetRunPoints())
return _0x2CC1.BuyStatus
end
coroutine.wrap(function()
local _0xFEFA = nil
while true do
if _0x2CC1.BreakLoop or not _0x2CC1:IsAlive() then break end
local _0xAA84, _0x8124 = pcall(function()
local _0xBC60 = _0x2CC1:GetHearts()
if _0x2CC1:IsClimbing() and (_0xBC60 == nil or _0xBC60 > 0) then
_0x2CC1.SpentRun, _0xFEFA = false, nil
elseif not _0x2CC1:IsClimbing() then
_0xFEFA = _0xFEFA or tick()
end
local _0x6283 = _0xBC60 ~= nil and _0xBC60 <= 0
local _0x3ABC = _0xFEFA ~= nil and tick() - _0xFEFA > 3
if not _0x2CC1.SpentRun and #_0x2CC1.BuyList > 0 and _0x2CC1:GetRunPoints() > 0
and (_0x6283 or _0x3ABC) then
_0x2CC1.SpentRun = true
print(string.char(91,100,117,110,103,101,111,110,93,32,115,104,111,112,58,32).. _0x2CC1:SpendPoints(_0x6283 andstring.char(111,117,116,32,111,102,32,104,101,97,114,116,115)orstring.char(99,108,105,109,98,32,101,110,100,101,100)))
end
task.wait(0.5)
end)
if _0x8124 then
if _0xFBA6 then warn(string.char(91,83,104,111,112,93,32,67,97,117,103,104,116,32,69,114,114,111,114,58), _0x8124) end
task.wait(1)
end
end
end)()function _0x2CC1:LootOnce()
local _0xE662 = 0
for _, FolderName in {string.char(76,111,111,116,68,114,111,112,115),string.char(67,104,101,115,116,115)} do
local _0x1B0D = _0x03DD:FindFirstChild(FolderName)
for _, _0xA75F in (_0x1B0D and _0x1B0D:GetChildren() or {}) do
local _0xCB82 = _0xA75F:FindFirstChildWhichIsA(string.char(80,114,111,120,105,109,105,116,121,80,114,111,109,112,116), true)
if _0xCB82 ~= nil and _0xCB82.Enabled and _0x2CC1:FirePrompt(_0xCB82) then
_0xE662 = _0xE662 + 1
end
end
end
return _0xE662
end
coroutine.wrap(function()
while true do
if _0x2CC1.BreakLoop or not _0x2CC1:IsAlive() then break end
local _0xAA84, _0x8124 = pcall(function()
if _0x2CC1.AutoLoot then
pcall(_0x2CC1.LootOnce, _0x2CC1)
end
task.wait(1)
end)
if _0x8124 then
if _0xFBA6 then warn(string.char(91,76,111,111,116,93,32,67,97,117,103,104,116,32,69,114,114,111,114,58), _0x8124) end
task.wait(1)
end
end
end)()coroutine.wrap(function()
local _0x7097 = false
while true do
if _0x2CC1.BreakLoop or not _0x2CC1:IsAlive() then break end
local _0xAA84, _0x8124 = pcall(function()
if not _0x2CC1.AutoRun then
task.wait(1)
else
if _0x2CC1:IsClimbing() then
_0x7097 = true
else
if _0x7097 then
_0x2CC1.Runs = _0x2CC1.Runs + 1
_0x7097 = false
task.wait(3)
end
if _0x2CC1:IsOutOfLives() then
_0x2CC1.LastReady =string.char(111,117,116,32,111,102,32,108,105,118,101,115)task.wait(5)
elseif not _0x2CC1:IsReadied() then
local _0xAA84, _0x5F81 = _0x2CC1:ReadyUp()
_0x2CC1.LastReady = tostring(_0x5F81)
task.wait(_0xAA84 and 2 or 4)
end
end
task.wait(1)
end
end)
if _0x8124 then
if _0xFBA6 then warn(string.char(91,65,117,116,111,32,82,117,110,93,32,67,97,117,103,104,116,32,69,114,114,111,114,58), _0x8124) end
task.wait(1)
end
end
end)()coroutine.wrap(function()
while true do
if _0x2CC1.BreakLoop or not _0x2CC1:IsAlive() then break end
local _0xAA84, _0x8124 = pcall(function()
if not _0x2CC1.Combat then
_0x2CC1.Target =string.char(45)task.wait(0.5)
else
local _0xE66F, _0x358A = _0x2CC1:GetNearestEnemy()
if _0xE66F == nil then
_0x2CC1.Target =string.char(45)_0x2CC1.Held = nil
task.wait(0.5)
else
_0x2CC1.Target = (string.char(37,115,32,40,37,46,48,102,41)):format(_0xE66F.Name, _0x358A or -1)
_0x2CC1.Held = _0xE66F
if _0x2CC1:IsResting() then
_0x2CC1.CombatStatus =string.char(102,105,110,105,115,104,101,114,32,108,97,110,100,101,100,32,45,32,98,97,99,107,105,110,103,32,111,102,102)task.wait(0.1)
elseif _0x2CC1:IsRagdolled() then
_0x2CC1.CombatStatus =string.char(114,97,103,100,111,108,108,101,100,32,45,32,119,97,105,116,105,110,103,32,116,111,32,103,101,116,32,117,112)task.wait(0.1)
elseif _0x2CC1.Shielded then
_0x2CC1.CombatStatus =string.char(119,97,105,116,105,110,103,32,45,32,116,97,114,103,101,116,32,115,116,105,108,108,32,98,108,111,99,107,105,110,103)task.wait(0.2)
else
task.wait(_0x2CC1:Swing())
end
end
end
end)
if _0x8124 then
if _0xFBA6 then warn(string.char(91,67,111,109,98,97,116,93,32,67,97,117,103,104,116,32,69,114,114,111,114,58), _0x8124) end
task.wait(1)
end
end
end)()coroutine.wrap(function()
while true do
if _0x2CC1.BreakLoop or not _0x2CC1:IsAlive() then break end
local _0xAA84, _0x8124 = pcall(function()
local _0xF11B = _0x2CC1:GetPhase()
local _0xA465 = game.PlaceId == 75556147183481 andstring.char(79,117,119,105,103,97,104,97,114,97)or tostring(game.PlaceId)
_0x2CC1:RaiseIdentity()
pcall(function()
_0x2CC1.RunStatus:SetDesc((string.char(80,108,97,99,101,58,32,37,115,10,83,116,97,116,101,58,32,37,115,37,115,10,72,101,97,114,116,115,58,32,37,115,10,82,117,110,58,32,37,115,10,84,97,114,103,101,116,58,32,37,115,10,83,116,97,110,99,101,58,32,37,115,32,64,32,37,46,49,102,32,115,116,117,100,115,10,82,117,110,115,58,32,37,100,32,32,32,80,105,99,107,101,100,58,32,37,100,32,99,97,114,100,115,10,76,97,115,116,58,32,37,115))
:format(_0xA465, _0x2CC1:GetState(), _0x2CC1:IsReadied() andstring.char(32,40,114,101,97,100,105,101,100,41)or"",
_0x2CC1:IsOutOfLives() andstring.char(48,32,45,32,114,117,110,32,102,105,110,105,115,104,101,100)or tostring(_0x2CC1:GetHearts() orstring.char(45)),
_0xF11B, _0x2CC1.Target, tostring(_0x2CC1.Stance),
_0x2CC1.Distance or 3.5, _0x2CC1.Runs, _0x2CC1.Picks, _0x2CC1.LastPick))
end)
task.wait(1)
end)
if _0x8124 then
if _0xFBA6 then warn(string.char(91,83,116,97,116,117,115,93,32,67,97,117,103,104,116,32,69,114,114,111,114,58), _0x8124) end
task.wait(1)
end
end
end)()_G.DgSet = function(_0xEF6F, _0x4E9D)
_0x2CC1[_0xEF6F] = _0x4E9D
return (string.char(37,115,32,61,32,37,115)):format(tostring(_0xEF6F), tostring(_0x4E9D))
end
_G.DgGet = function()
local _0xE66F, _0x358A = _0x2CC1:GetNearestEnemy()
return (string.char(99,97,114,100,115,61,37,115,32,99,111,109,98,97,116,61,37,115,32,114,101,97,99,104,61,37,115,32,116,97,114,103,101,116,61,37,115,32,110,101,97,114,101,115,116,61,37,115,32,100,105,115,116,61,37,115,32,114,111,117,116,101,61,37,115,32,115,116,97,116,117,115,61,37,115)):format(
tostring(_0x2CC1.Cards), tostring(_0x2CC1.Combat), tostring(_0x2CC1.Reach),
tostring(_0x2CC1.Target),
_0xE66F and _0xE66F.Name orstring.char(110,111,110,101),
_0x358A and (string.char(37,46,48,102)):format(_0x358A) orstring.char(45),
tostring(_0x2CC1.RouteName), tostring(_0x2CC1.CombatStatus))
.. (string.char(32,104,101,97,114,116,115,61).. tostring(_0x2CC1:GetHearts() orstring.char(45)))
end
_G.DgEquip = function()
local _0xAA84, _0x5F81 = _0x2CC1:DrawWeapon()
return (string.char(100,114,97,119,110,61,37,115,32,111,107,61,37,115,32,37,115)):format(
tostring(_0x2CC1:IsWeaponDrawn()), tostring(_0xAA84), tostring(_0x5F81))
endif game.PlaceId == 136406881576517 then
_0xA034:Notify({
_0x41E6 =string.char(73,110,32,79,117,119,108,97,110,100),
Content =string.char(84,117,114,110,32,111,110,32,65,117,116,111,32,69,110,116,101,114,32,68,117,110,103,101,111,110,44,32,111,114,32,112,114,101,115,115,32,69,110,116,101,114,32,100,117,110,103,101,111,110,32,110,111,119,46),
Duration = 8,
})
elseif game.PlaceId ~= 75556147183481 then
_0xA034:Notify({
_0x41E6 =string.char(87,114,111,110,103,32,112,108,97,99,101),
Content =string.char(84,104,105,115,32,104,117,98,32,119,111,114,107,115,32,105,110,32,79,117,119,108,97,110,100,32,97,110,100,32,79,117,119,105,103,97,104,97,114,97,46),
Duration = 8,
})
end
_0x14A9:SelectTab(1)
_0xA034:Notify({
_0x41E6 =string.char(79,117,119,105,103,97,104,97,114,97,32,104,117,98),
Content =string.char(76,111,97,100,101,100,46,32,84,111,103,103,108,101,115,32,115,116,97,114,116,32,79,70,70,32,45,32,116,117,114,110,32,116,104,101,109,32,111,110,32,119,104,101,110,32,97,32,102,108,111,111,114,32,98,101,103,105,110,115,46),
Duration = 6,
})
