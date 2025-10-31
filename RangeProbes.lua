local ADDON, ns = ...
local Probes = {}
ns.Probes = Probes

-------------------------------------------------------
-- Friendly spell probes per class
-- These should all work on friendly units.
-------------------------------------------------------
local FRIENDLY_PROBES = {
  PRIEST = {
    { spell = "Flash Heal", range = 40 },
    { spell = "Power Word: Shield", range = 30 },
    { spell = "Lesser Heal", range = 20 },
  },
  DRUID = {
    { spell = "Rejuvenation", range = 40 },
    { spell = "Mark of the Wild", range = 30 },
  },
  PALADIN = {
    { spell = "Flash of Light", range = 40 },
    { spell = "Blessing of Kings", range = 30 },
  },
  SHAMAN = {
    { spell = "Lesser Healing Wave", range = 40 },
    { spell = "Cure Poison", range = 30 },
  },
  MAGE = {
    { spell = "Arcane Intellect", range = 30 },
  },
  WARLOCK = {
    { spell = "Unending Breath", range = 30 },
  },
  HUNTER = {
    { spell = "Aspect of the Pack", range = 30 },
  },
  WARRIOR = {
    { spell = "Intervene", range = 25 },
  },
  ROGUE = {
    { spell = "Tricks of the Trade", range = 20 },
  },
  DEATHKNIGHT = {
    { spell = "Death Coil", range = 30 }, -- placeholder (WotLK+)
  },
}

-------------------------------------------------------
-- Detect player class once
-------------------------------------------------------
local _, playerClass = UnitClass("player")
local CLASS_PROBES = FRIENDLY_PROBES[playerClass] or {}

-------------------------------------------------------
-- Utility: get bracket from all probes
-------------------------------------------------------
function Probes:GetRangeBracket(unit)
  if not UnitExists(unit) then return nil end

  local lower, upper = 0, 40

  -- Friendly spell probes
  for _, probe in ipairs(CLASS_PROBES) do
    local inRange = IsSpellInRange(probe.spell, unit)
    if inRange == 1 then
      upper = math.min(upper, probe.range)
    elseif inRange == 0 then
      lower = math.max(lower, probe.range)
    end
  end

  -- Universal interact fallbacks
  if CheckInteractDistance(unit, 3) then
    upper = math.min(upper, 10)
  else
    lower = math.max(lower, 10)
  end

  if CheckInteractDistance(unit, 4) then
    upper = math.min(upper, 28)
  else
    lower = math.max(lower, 28)
  end

  -- Safety clamps
  if upper < lower then upper = lower end

  local estimate = (lower + upper) / 2
  return lower, upper, estimate
end

-------------------------------------------------------
-- Example integration
-- (Called by Range.lua each update)
-------------------------------------------------------
function Probes:GetEstimate(unit)
  local lower, upper, estimate = self:GetRangeBracket(unit)
  return estimate or 40
end
