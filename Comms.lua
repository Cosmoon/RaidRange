local ADDON, ns = ...
local Comms = {}
ns.Comms = Comms

local prefix = "RAIDRANGE"
C_ChatInfo.RegisterAddonMessagePrefix(prefix)

Comms._lastSend = 0
Comms._receiveCache = {}   -- [sender][target] = { dist = number, time = timestamp }

-------------------------------------------------------
-- Broadcast our local distances
-------------------------------------------------------
function Comms:Broadcast(elapsed)
  self._lastSend = (self._lastSend or 0) + elapsed
  if self._lastSend < 1.0 then return end   -- send every ~1s
  self._lastSend = 0

  if not IsInGroup() then return end
  local myName = UnitName("player")
  local msgParts = {}

  local rangeCache = ns.Range._cache or {}
  for unit, dist in pairs(rangeCache) do
    local targetName = ns._unitToName[unit]
    if targetName and dist and dist < 40 then
      table.insert(msgParts, string.format("%s=%.1f", targetName, dist))
    end
  end

  if #msgParts > 0 then
    local payload = table.concat(msgParts, ";")
    C_ChatInfo.SendAddonMessage(prefix, myName .. ":" .. payload, IsInRaid() and "RAID" or "PARTY")
  end
end

-------------------------------------------------------
-- Receive and store others' data
-------------------------------------------------------
function Comms:OnMessage(sender, msg)
  if sender == UnitName("player") then return end

  local now = GetTime()
  self._receiveCache[sender] = self._receiveCache[sender] or {}

  for pair in string.gmatch(msg, "([^;]+)") do
    local target, dist = string.match(pair, "([^=]+)=([%d%.]+)")
    if target and dist then
      self._receiveCache[sender][target] = { dist = tonumber(dist), time = now }
    end
  end
end

-------------------------------------------------------
-- Get merged distance (A↔B averaging)
-------------------------------------------------------
function Comms:GetMergedDistance(unit)
  local name = ns._unitToName[unit]
  if not name then return nil end

  local myDist = ns.Range._cache and ns.Range._cache[unit]
  local now = GetTime()
  local total, count = 0, 0

  for sender, data in pairs(self._receiveCache) do
    local entry = data[name]
    if entry and (now - entry.time) < 5 then
      total = total + entry.dist
      count = count + 1
    end
  end

  if count > 0 then
    if myDist then
      return (myDist + (total / count)) / 2
    else
      return total / count
    end
  else
    return myDist   -- fallback: only our data
  end
end
