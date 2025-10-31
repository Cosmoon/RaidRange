local ADDON, ns = ...
RaidRange = ns

local C = {}
ns.C = C

C.PREFIX = "RRNG1"
C.UPDATE_RATE = 0.3
C.DEFAULTS = {
  enabled = true,
  threshold = 5,
  debug = false,
}

local db

-- util
local function deepcopy(tbl)
  if type(tbl) ~= "table" then return tbl end
  local t = {}
  for k,v in pairs(tbl) do t[k] = deepcopy(v) end
  return t
end

local function ensureDB()
  if type(RaidRangeDB) ~= "table" then RaidRangeDB = deepcopy(C.DEFAULTS) end
  db = RaidRangeDB
  for k,v in pairs(C.DEFAULTS) do if db[k] == nil then db[k] = deepcopy(v) end end
end

-- group lists
ns._partyUnits, ns._raidUnits, ns._unitToName, ns._nameToUnit = {}, {}, {}, {}
local function RebuildUnitLists()
  wipe(ns._partyUnits); wipe(ns._raidUnits); wipe(ns._unitToName); wipe(ns._nameToUnit)
  if IsInRaid() then
    for i=1,40 do
      local unit = "raid"..i
      if UnitExists(unit) then
        local name = UnitName(unit)
        if name then
          ns._unitToName[unit] = name
          ns._nameToUnit[name] = unit
          table.insert(ns._raidUnits, unit)
        end
      end
    end
  else
    table.insert(ns._partyUnits, "player")
    for i=1,4 do
      local unit = "party"..i
      if UnitExists(unit) then table.insert(ns._partyUnits, unit) end
    end
    for _,unit in ipairs(ns._partyUnits) do
      local name = UnitName(unit)
      if name then ns._unitToName[unit] = name; ns._nameToUnit[name] = unit end
    end
  end
end

-- slash handler
local function SlashHandler(msg)
  msg = (msg and msg:match("^%s*(.-)%s*$"):lower()) or ""
  if msg == "debug" then
    db.debug = not db.debug
    print("|cff33ff99RaidRange|r debug mode: " .. (db.debug and "|cffff0000ON|r" or "|cff00ff00OFF|r"))
    if ns.UI and ns.UI.Refresh then ns.UI:Refresh() end
    return
  elseif msg == "toggle" or msg == "" then
    if ns.UI and ns.UI.frame then
      if ns.UI.frame:IsShown() then ns.UI.frame:Hide() else ns.UI.frame:Show(); ns.UI:Refresh() end
    else
      print("|cff33ff99RaidRange|r UI not ready")
    end
    return
  end

  local n = tonumber(msg)
  if n then
    db.threshold = n
    print(("RaidRange: threshold set to %d yards"):format(n))
    if ns.UI and ns.UI.frame then ns.UI.frame:Show(); ns.UI:Refresh() end
  else
    print("|cff33ff99RaidRange usage:|r /raidr [yards|debug|toggle]  or  /raidrange ...")
  end
end

-- robust slash registration (can be called multiple times harmlessly)
local function RegisterSlashes()
  SLASH_RAIDR1 = "/raidr"
  SLASH_RAIDR2 = "/raidrange"
  SlashCmdList["RAIDR"] = SlashHandler
end

-- events
local f = CreateFrame("Frame")
ns._eventFrame = f
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("CHAT_MSG_ADDON")
C_ChatInfo.RegisterAddonMessagePrefix(C.PREFIX)

f:SetScript("OnEvent", function(_, event, ...)
  if event == "ADDON_LOADED" then
    local addon = ...
    if addon == "RaidRange" then
      ensureDB()
      RebuildUnitLists()
      RegisterSlashes()              -- register early
      if ns.UI and ns.UI.Init then
        ns.UI:Init(db)
      end
      if ns.Comms and ns.Comms.Init then
        ns.Comms:Init(db)
      end
      print("|cff33ff99RaidRange|r loaded. Slashes: /raidr, /raidrange")
    end

  elseif event == "PLAYER_LOGIN" then
    -- In case something delayed, ensure slashes exist
    RegisterSlashes()
    if not ns.UI or not ns.UI.frame then
      if ns.UI and ns.UI.Init then ns.UI:Init(db or C.DEFAULTS) end
    end

  elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
    RebuildUnitLists()

  elseif event == "CHAT_MSG_ADDON" then
    local prefix, msg, channel, sender = ...
    if prefix == C.PREFIX and ns.Comms and ns.Comms.OnMessage then
      ns.Comms:OnMessage(sender, msg)
    end
  end
end)

-- update loop
local tick = 0
f:SetScript("OnUpdate", function(_, elapsed)
  tick = tick + elapsed
  if tick >= C.UPDATE_RATE then
    tick = 0
    if ns.UI and ns.UI.frame and ns.UI.frame:IsShown() then
      if ns.Range and ns.Range.UpdateBuckets then ns.Range:UpdateBuckets() end
      if ns.UI.Refresh then ns.UI:Refresh() end
    end
  end
  if ns.Comms and ns.Comms.Broadcast then
    ns.Comms:Broadcast(elapsed)
  end
end)
