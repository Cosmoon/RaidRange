local ADDON, ns = ...
local Range = {}
ns.Range = Range

local Probes = ns.Probes

Range._cache = {}

function Range:UpdateBuckets()
  wipe(self._cache)
  local units = IsInRaid() and ns._raidUnits or ns._partyUnits
  for _, u in ipairs(units) do
    if UnitExists(u) and not UnitIsUnit(u, "player") then
      local localDist = Probes and Probes:GetEstimate(u) or nil
      local dist = localDist
      if ns.Comms and ns.Comms.GetMergedDistance then
        local merged = ns.Comms:GetMergedDistance(u, localDist) -- pass local as hint
        if merged then dist = merged end
      end
      self._cache[u] = dist or localDist or 999
    end
  end
end

function Range:GetExactRange(unit) return self._cache[unit] end
function Range:GetApproxRange(unit) return self._cache[unit] end
function Range:IsInsideThreshold(unit, threshold)
  local d = self._cache[unit]
  return d and d <= threshold
end
