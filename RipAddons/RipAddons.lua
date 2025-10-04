local ADDON_NAME = ...

local RipAddons = {}
_G["RipAddons"] = RipAddons

RipAddons.name = ADDON_NAME
RipAddons.lastScan = nil

local function addonPrint(message)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cff50fa7b[RIPAddons]|r " .. tostring(message))
  end
end

local function normalizeAddonName(name)
  if not name then return nil end
  local normalized = name:gsub("[^%w]", "")
  return string.lower(normalized)
end

local function getNumAddOns()
  if C_AddOns and C_AddOns.GetNumAddOns then
    return C_AddOns.GetNumAddOns()
  elseif GetNumAddOns then
    return GetNumAddOns()
  else
    return 0
  end
end

local function getAddOnInfo(index)
  if C_AddOns and C_AddOns.GetAddOnInfo then
    local name, title, notes, loadable, reason = C_AddOns.GetAddOnInfo(index)
    return name, title, notes, loadable, reason
  elseif GetAddOnInfo then
    local name, title, notes, loadable, reason = GetAddOnInfo(index)
    return name, title, notes, loadable, reason
  else
    return nil
  end
end

local function severityColorRGB(severity)
  local s = string.lower(severity or "unknown")
  if s == "critical" or s == "red" then return 1.0, 0.2, 0.2 end
  if s == "high" then return 1.0, 0.4, 0.2 end
  if s == "medium" or s == "yellow" then return 1.0, 0.82, 0.0 end
  if s == "low" or s == "green" then return 0.4, 1.0, 0.4 end
  return 0.8, 0.8, 0.8
end

local function rgbToHexBytes(r, g, b)
  local ri = math.max(0, math.min(255, math.floor((r or 0) * 255 + 0.5)))
  local gi = math.max(0, math.min(255, math.floor((g or 0) * 255 + 0.5)))
  local bi = math.max(0, math.min(255, math.floor((b or 0) * 255 + 0.5)))
  return ri, gi, bi
end

function RipAddons:ScanInstalledAddons()
  local results = {}
  local impacted = (RipAddons_ImpactedData and RipAddons_ImpactedData.addons) or {}
  local total = getNumAddOns()

  for i = 1, total do
    local name, title = getAddOnInfo(i)
    local normalized = normalizeAddonName(name)
    if normalized and impacted[normalized] then
      local info = impacted[normalized]
      table.insert(results, {
        name = name,
        title = title or name,
        severity = info.severity or "unknown",
        note = info.note,
        link = info.link,
      })
    end
  end

  table.sort(results, function(a, b)
    local rank = { critical = 1, high = 2, medium = 3, low = 4, unknown = 5 }
    local ra = rank[string.lower(a.severity or "unknown")] or 99
    local rb = rank[string.lower(b.severity or "unknown")] or 99
    if ra == rb then
      return (a.title or a.name) < (b.title or b.name)
    end
    return ra < rb
  end)

  self.lastScan = {
    timestamp = time and time() or 0,
    dataVersion = (RipAddons_ImpactedData and RipAddons_ImpactedData.version) or "unknown",
    items = results,
    totalInstalled = total,
    totalImpacted = #results,
  }

  RipAddonsDB.lastScan = self.lastScan
  return self.lastScan
end

function RipAddons:PrintScanSummary()
  if not self.lastScan then
    addonPrint("No scan yet. Type /ripaddons scan")
    return
  end
  local ls = self.lastScan
  addonPrint(string.format("Impacted: %d of %d installed (data v%s)", ls.totalImpacted or 0, ls.totalInstalled or 0, tostring(ls.dataVersion)))
  for _, item in ipairs(ls.items) do
    local r, g, b = severityColorRGB(item.severity)
    local sev = item.severity or "unknown"
    local ri, gi, bi = rgbToHexBytes(r, g, b)
    local line = string.format("- %s |cff%02x%02x%02x[%s]|r", item.title or item.name, ri, gi, bi, sev)
    if item.note then line = line .. " - " .. item.note end
    addonPrint(line)
  end
end

-- UI
function RipAddons:CreateUI()
  if self.frame then return end

  local f = CreateFrame("Frame", "RipAddonsFrame", UIParent, "BasicFrameTemplateWithInset")
  f:SetSize(520, 420)
  f:SetPoint("CENTER")
  f:Hide()

  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  f.title:SetPoint("LEFT", f.TitleBg, "LEFT", 5, 0)
  f.title:SetText("RIP Addons - Impacted Installed Addons")

  local scanBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  scanBtn:SetSize(100, 24)
  scanBtn:SetPoint("TOPRIGHT", -50, -30)
  scanBtn:SetText("Rescan")
  scanBtn:SetScript("OnClick", function()
    RipAddons:ScanInstalledAddons()
    RipAddons:UpdateList()
  end)

  local sf = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT", 12, -60)
  sf:SetPoint("BOTTOMRIGHT", -30, 16)

  local content = CreateFrame("Frame", nil, sf)
  content:SetSize(1, 1)
  sf:SetScrollChild(content)

  f.scrollFrame = sf
  f.content = content

  self.frame = f
end

function RipAddons:UpdateList()
  if not self.frame then return end
  local f = self.frame
  local content = f.content

  for _, child in ipairs({ content:GetChildren() }) do
    child:Hide()
    child:SetParent(nil)
  end

  local y = -4
  local rowHeight = 18

  local data = self.lastScan and self.lastScan.items or {}
  for _, item in ipairs(data) do
    local r, g, b = severityColorRGB(item.severity)
    local ri, gi, bi = rgbToHexBytes(r, g, b)
    local text = string.format("%s - |cff%02x%02x%02x%s|r", item.title or item.name, ri, gi, bi, item.severity or "unknown")
    if item.note then
      text = text .. " - " .. item.note
    end

    local fs = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOPLEFT", 4, y)
    fs:SetJustifyH("LEFT")
    fs:SetText(text)

    y = y - rowHeight
  end

  content:SetSize(1, math.abs(y))
end

function RipAddons:Show()
  self:CreateUI()
  if not self.lastScan then
    self:ScanInstalledAddons()
  end
  self:UpdateList()
  self.frame:Show()
end

function RipAddons:Hide()
  if self.frame then self.frame:Hide() end
end

function RipAddons:ToggleFrame()
  self:CreateUI()
  if self.frame:IsShown() then self:Hide() else self:Show() end
end

-- Slash command
SLASH_RIPADDONS1 = "/ripaddons"
SlashCmdList["RIPADDONS"] = function(msg)
  msg = string.lower(msg or "")
  if msg == "scan" then
    RipAddons:ScanInstalledAddons()
    RipAddons:PrintScanSummary()
  elseif msg == "show" or msg == "ui" then
    RipAddons:Show()
  elseif msg == "hide" then
    RipAddons:Hide()
  else
    addonPrint("Commands: /ripaddons scan | show | hide")
    RipAddons:PrintScanSummary()
  end
end

-- Event init
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event, ...)
  if event == "ADDON_LOADED" then
    local addon = ...
    if addon == ADDON_NAME then
      RipAddonsDB = RipAddonsDB or {}
      RipAddons:CreateUI()
    end
  elseif event == "PLAYER_LOGIN" then
    -- Perform an initial scan on login for convenience
    RipAddons:ScanInstalledAddons()
  end
end)


