local ADDON, ns = ...
local Probes = {}
ns.Probes = Probes

-- Map spellIDs → range; resolve names via GetSpellInfo (locale-safe).
local CLASS_SPELLS = {
  PRIEST = {
    { id = 2061, range = 40 },  -- Flash Heal
    { id = 17,   range = 30 },  -- Power Word: Shield
  },
  DRUID = {
    { id = 774,  range = 40 },  -- Rejuvenation
    { id = 1126, range = 30 },  -- Mark of the Wild
  },
  PALADIN = {
    { id = 19750, range = 40 }, -- Flash of Light
    { id = 20217, range = 30 }, -- Blessing of Kings
  },
  SHAMAN = {
    { id = 8004,  range = 40 }, -- Lesser Healing Wave
    { id = 526,   range = 30 }, -- Cure Poison (ally)
  },
  MAGE = {
    { id = 1459,  range = 30 }, -- Arcane Intellect
  },
  WARLOCK = {
    { id = 5697,  range = 30 }, -- Unending Breath
  },
  HUNTER = {
    -- Hunters: few ally singles; rely mostly on interact fallbacks
  },
  WARRIOR = {
    -- No friendly singles; rely on interact fallbacks
  },
  ROGUE = {
    -- Few ally singles; rely on interact fallbacks
  },
}

-- Build resolved probe list once
local _, CLASS = UnitClass("player")
local RESOLVED = {}
do
  local list = CLASS_SPELLS[CLASS] or {}
  for _, p in ipairs(list) do
    local name = GetSpellInfo(p.id)
    if name then
      RESOLVED[#RESOLVED+1] = { name = name, range = p.range }
    end
  end
end

-- Returns lower, upper, estimate (yards)
function Probes:GetRangeBracket(unit)
  if not UnitExists(unit) then return nil end
  local lower, upper = 0, 40

  -- Friendly spell probes (if any)
  for _, p in ipairs(RESOLVED) do
    local r = IsSpellInRange(p.name, unit)
    if r == 1 then
      upper = math.min(upper, p.range)
    elseif r == 0 then
      lower = math.max(lower, p.range)
    end
  end

  -- Universal interact fallbacks (very reliable)
  -- 3: Duel (~9-10y). If true, upper ≤ 10; else lower ≥ 10
  if CheckInteractDistance(unit, 3) then
    upper = math.min(upper, 10)
  else
    lower = math.max(lower, 10)
  end
  -- 4: Follow (~28y). If true, upper ≤ 28; else lower ≥ 28
  if CheckInteractDistance(unit, 4) then
    upper = math.min(upper, 28)
  else
    lower = math.max(lower, 28)
  end

  if upper < lower then upper = lower end
  local estimate = (lower + upper) / 2
  return lower, upper, estimate
end

function Probes:GetEstimate(unit)
  local _, _, e = self:GetRangeBracket(unit)
  return e or 40
end
