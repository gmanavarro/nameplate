local addonName, addon = ...
local Nameplate = CreateFrame("Frame")
Nameplate:RegisterEvent("ADDON_LOADED")
Nameplate:RegisterEvent("PLAYER_LOGIN")
Nameplate:RegisterEvent("UNIT_AURA")
Nameplate:RegisterEvent("NAME_PLATE_UNIT_ADDED")
Nameplate:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

local trackedDebuffs = {}
local activeNameplates = {}

local function CreateAnimatedBorder(parent)
    local border = CreateFrame("Frame", nil, parent)
    border:SetAllPoints(parent)
    
    -- Create four lines for the border
    local lines = {}
    local thickness = 2 -- Border thickness in pixels
    
    -- Top line
    local top = border:CreateTexture(nil, "OVERLAY")
    top:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    top:SetPoint("TOPLEFT", border, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", border, "TOPRIGHT", 0, 0)
    top:SetHeight(thickness)
    table.insert(lines, top)
    
    -- Right line
    local right = border:CreateTexture(nil, "OVERLAY")
    right:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    right:SetPoint("TOPRIGHT", border, "TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", 0, 0)
    right:SetWidth(thickness)
    table.insert(lines, right)
    
    -- Bottom line
    local bottom = border:CreateTexture(nil, "OVERLAY")
    bottom:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    bottom:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(thickness)
    table.insert(lines, bottom)
    
    -- Left line
    local left = border:CreateTexture(nil, "OVERLAY")
    left:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    left:SetPoint("TOPLEFT", border, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT", 0, 0)
    left:SetWidth(thickness)
    table.insert(lines, left)
    
    -- Create animation group
    local animationGroup = border:CreateAnimationGroup()
    local rotation = animationGroup:CreateAnimation("Rotation")
    rotation:SetDuration(2)
    rotation:SetDegrees(360)
    rotation:SetSmoothing("NONE")
    animationGroup:SetLooping("REPEAT")
    
    border.lines = lines
    border.animationGroup = animationGroup
    return border
end

local function UpdateNameplateBorder(unit)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if not nameplate then return end
    
    local border = activeNameplates[unit]
    if not border then
        border = CreateAnimatedBorder(nameplate)
        activeNameplates[unit] = border
    end
    
    local hasTrackedDebuff = false
    local debuffColor = {r = 1, g = 1, b = 1}
    
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, spellId = UnitDebuff(unit, i)
        if name and trackedDebuffs[name] then
            hasTrackedDebuff = true
            debuffColor = trackedDebuffs[name]
            break
        end
    end
    
    if hasTrackedDebuff then
        for _, line in ipairs(border.lines) do
            line:SetVertexColor(debuffColor.r, debuffColor.g, debuffColor.b, 1)
        end
        border.animationGroup:Play()
        border:Show()
    else
        border.animationGroup:Stop()
        border:Hide()
    end
end

local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        NameplateDB = NameplateDB or {
            trackedDebuffs = {}
        }
        trackedDebuffs = NameplateDB.trackedDebuffs
    elseif event == "PLAYER_LOGIN" then
        print("Nameplate addon loaded successfully!")
    elseif event == "UNIT_AURA" then
        local unit = ...
        if unit and unit:find("nameplate") then
            UpdateNameplateBorder(unit)
        end
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        local unit = ...
        UpdateNameplateBorder(unit)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        local unit = ...
        if activeNameplates[unit] then
            activeNameplates[unit]:Hide()
            activeNameplates[unit] = nil
        end
    end
end

Nameplate:SetScript("OnEvent", OnEvent)

-- API functions for configuration
function Nameplate:TrackDebuff(spellName, r, g, b)
    trackedDebuffs[spellName] = {r = r, g = g, b = b}
    NameplateDB.trackedDebuffs = trackedDebuffs
end

function Nameplate:UntrackDebuff(spellName)
    trackedDebuffs[spellName] = nil
    NameplateDB.trackedDebuffs = trackedDebuffs
end 