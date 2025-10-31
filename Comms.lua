local ADDON, ns = ...
local Comms = {}
ns.Comms = Comms

local prefix = ns.C and ns.C.PREFIX or "RAIDRANGE"
C_ChatInfo.RegisterAddonMessagePrefix(prefix)

Comms._lastSend = 0
Comms._receiveCache = {}

-------------------------------------------------------
-- Initialization
-------------------------------------------------------
function Comms:Init(db)
  self.db = db
end

-------------------------------------------------------
-- Broadcast local distances
-------------------------------------------------------
function Comms:Broadcast(elapsed)
  self._lastSend = (self._lastSend or 0) + elapsed
  if self._lastSend < 1.0 then return end   -- send every ~1s
  self._lastSend = 0

  if not IsInGroup() then return end

  local myName = UnitName("player")
  local parts = {}
  local cache = ns.Range._cache or {}

  for unit, dist in pairs(cache) do
    local target = ns._unitToName[unit]
    if target and dist and dist < 40 then
      parts[#parts+1] = string.format("%s=%.1f", target, dist)
    end
  end

  if #parts > 0 then
    local payload = myName .. ":" .. table.concat(parts, ";")
    local chan = IsInRaid() and "RAID" or "PARTY"
    C_ChatInfo.SendAddonMessage(prefix, payload, chan)
    if self.db and self.db.debug then
      print(("|cff33ff99RaidRange|r sent %d entries via %s"):format(#parts, chan))
    end
  end
end

-------------------------------------------------------
-- Receive data
-------------------------------------------------------
function Comms:OnMessage(sender, msg)
  if sender == UnitName("player") then return end
  local now = GetTime()
  self._receiveCache[sender] = self._receiveCache[sender] or {}

  local nameSection, payload = msg:match("^([^:]+):(.*)$")
  if not payload then return end

  for pair in payload:gmatch("([^;]+)") do
    local name, dist = pair:match("([^=]+)=([%d%.]+)")
    if name and dist then
      self._receiveCache[sender][name] = { dist = tonumber(dist), time = now }
    end
  end

  if self.db and self.db.debug then
    local count = 0
    for _ in pairs(self._receiveCache[sender]) do count = count + 1 end
    print(("|cff33ff99RaidRange|r recv from %s: %d entries"):format(sender, count))
  end
end

-------------------------------------------------------
-- Merge distances from other senders
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
    return myDist  -- fallback: local only
  end
end
