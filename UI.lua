local ADDON, ns = ...
local UI = {}
ns.UI = UI

local Range = ns.Range

-------------------------------------------------------
-- Initialization
-------------------------------------------------------
function UI:Init(db)
  self.db = db
  self.lines = {}

  -------------------------------------------------------
  -- Create main frame FIRST
  -------------------------------------------------------
  local f = CreateFrame("Frame", "RaidRangeFrame", UIParent)
  self.frame = f

  f:SetPoint("CENTER")
  f:SetSize(180, 230)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(frame) frame:StartMoving() end)
  f:SetScript("OnDragStop",  function(frame) frame:StopMovingOrSizing() end)

  -------------------------------------------------------
  -- Title
  -------------------------------------------------------
  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -4)
  title:SetText("RaidRange: 0y  0/0")
  self.title = title

  -------------------------------------------------------
  -- Debug text
  -------------------------------------------------------
  local dbg = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  dbg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 2)
  dbg:SetText("")
  self.debugText = dbg

  -------------------------------------------------------
  -- Name lines
  -------------------------------------------------------
  for i = 1, 15 do
    local fs = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -20 - (i-1)*14)
    fs:SetText("")
    self.lines[i] = fs
  end

  f:Hide()
end

-------------------------------------------------------
-- Refresh display
-------------------------------------------------------
function UI:Refresh()
  if not self.frame or not self.frame:IsShown() then return end

  local threshold = self.db.threshold or 10
  local units = IsInRaid() and ns._raidUnits or ns._partyUnits
  local list = {}
  local inCount, total = 0, 0

  for _, u in ipairs(units) do
    if UnitExists(u) and not UnitIsUnit(u, "player") then
      total = total + 1
      local name = GetUnitName(u, true) or UnitName(u)
      local dist = Range:GetExactRange(u) or Range:GetApproxRange(u)
      if dist then
        if dist <= threshold then
          inCount = inCount + 1
          list[#list+1] = { name = name, dist = dist, color = "red" }
        elseif dist <= threshold + 4 then
          list[#list+1] = { name = name, dist = dist, color = "orange" }
        end
      end
    end
  end

  table.sort(list, function(a,b) return a.dist < b.dist end)

  -- Update title
  if self.title then
    self.title:SetText(("RaidRange: %dy  %d/%d"):format(threshold, inCount, total))
  end

  -- Update player lines
  for i, fs in ipairs(self.lines) do
    local data = list[i]
    if data then
      local colorCode = (data.color == "red") and "|cffff0000" or "|cffffa500"
      fs:SetText(colorCode .. data.name .. " – " .. string.format("%.1f", data.dist) .. "y|r")
      fs:Show()
    else
      fs:Hide()
    end
  end

  -------------------------------------------------------
  -- Debug overlay
  -------------------------------------------------------
  if self.debugText and self.db.debug then
    local comms = ns.Comms
    local totalSenders = 0
    if comms and comms._receiveCache then
      for _ in pairs(comms._receiveCache) do totalSenders = totalSenders + 1 end
    end
    local totalRaid = IsInRaid() and GetNumGroupMembers() or GetNumSubgroupMembers()
    self.debugText:SetText(("Sync: %d/%d"):format(totalSenders, totalRaid))
    self.debugText:Show()
  elseif self.debugText then
    self.debugText:Hide()
  end
end
