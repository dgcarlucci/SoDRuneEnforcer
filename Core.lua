local _, addon = ...

-- 1. Initialize Database
SoDRuneEnforcerDB = SoDRuneEnforcerDB or { phase = 1 }

-- 2. Define Local Data and Helpers
local L = {
    PHASE_SET = "Current enforcement set to: Phase %d",
    CHECKING = "Checking group members for Phase %d compliance...",
    VIOLATION_SUMMARY = "|cffff0000[SRE] VIOLATION:|r %s: %s",
    ALL_CLEAR = "All group members are compliant with Phase %d restrictions.",
    NOT_IN_RAID = "You are not in a group.",
    HELP = "SoD Rune Enforcer Commands:\n/sre phase [1-8] - Set current Phase\n/sre check - Check all raid members\n/sre ui - Toggle control panel\n/sre debug - Status of your current runes",
}

local slots = {
    ["Chest"] = {id = 5, name = "Chest", friendly = "Chest"},
    ["Hands"] = {id = 10, name = "Hands", friendly = "Gloves"},
    ["Legs"] = {id = 7, name = "Legs", friendly = "Legs"},
    ["Waist"] = {id = 6, name = "Waist", friendly = "Belt"},
    ["Feet"] = {id = 8, name = "Feet", friendly = "Boots"},
    ["Head"] = {id = 1, name = "Head", friendly = "Helm"},
    ["Wrist"] = {id = 9, name = "Wrist", friendly = "Bracers"},
    ["Back"] = {id = 15, name = "Back", friendly = "Cloak"},
    ["Finger0"] = {id = 11, name = "Ring1", friendly = "Ring 1"},
    ["Finger1"] = {id = 12, name = "Ring2", friendly = "Ring 2"},
}

local mainFrame
local gridButtons = {}
local playerScanData = {}
local inspectQueue = {}
local activeInspectUnit = nil
local activeInspectTimeoutTimer = nil
local isScanning = false
local isGroupScanning = false

-- Tooltip scanner
local scanner = CreateFrame("GameTooltip", "SREScanner", nil, "GameTooltipTemplate")
scanner:SetOwner(WorldFrame, "ANCHOR_NONE")

local function GetRunePhase(className, runeName)
    if not addon.RuneData or not className or not runeName then return nil end
    local classKey = className:sub(1,1):upper() .. className:sub(2):lower()
    local classData = addon.RuneData[classKey]
    if not classData then return nil end
    
    local lowerRune = runeName:lower()
    for phase, pSlots in pairs(classData) do
        for slot, runes in pairs(pSlots) do
            for _, name in ipairs(runes) do
                if name:lower() == lowerRune then return phase end
            end
        end
    end
    
    if addon.RingRunes then
        for name, phase in pairs(addon.RingRunes) do
            if name:lower() == lowerRune then return phase end
        end
    end
    return nil
end

local function GetRuneNameFromSlot(unit, slotID)
    if unit == "player" and C_Engraving then
        local getRune = C_Engraving.GetRuneForEquipmentSlot or C_Engraving.GetRuneOnSlot
        if getRune then
            local success, rune = pcall(getRune, slotID)
            if success and rune then
                local name = rune.name or rune.runeName
                if name then return name end
            end
        end
    end

    local link = GetInventoryItemLink(unit, slotID)
    if not link then return nil end
    
    scanner:SetOwner(WorldFrame, "ANCHOR_NONE")
    scanner:ClearLines()
    scanner:SetHyperlink(link)
    
    for i = 1, scanner:NumLines() do
        local line = _G["SREScannerTextLeft"..i]
        local text = line and line:GetText()
        if text then
            local clean = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
            local runeName = clean:match("^Engraved: (.+)") or 
                             clean:match("^Rune of (.+)") or
                             clean:match("(.+) %- Engraved") or
                             clean:match("^Rune: (.+)")
            
            if runeName then return runeName end
            local _, class = UnitClass(unit)
            if GetRunePhase(class, clean) then return clean end
        end
    end
    return nil
end

local function ScanUnit(unit)
    local guid = UnitGUID(unit)
    if not guid then return end
    
    local name = UnitName(unit)
    local _, class = UnitClass(unit)
    if not class or not name then return end

    local pData = {
        name = name,
        class = class,
        guid = guid,
        status = "compliant",
        runes = {},
    }
    
    local hasViolation = false
    for slotName, info in pairs(slots) do
        local runeName = GetRuneNameFromSlot(unit, info.id)
        if runeName then
            local phase = GetRunePhase(class, runeName)
            local isRuneViolation = false
            if phase and phase > SoDRuneEnforcerDB.phase then
                isRuneViolation = true
                hasViolation = true
            end
            pData.runes[slotName] = {
                name = runeName,
                phase = phase,
                isViolation = isRuneViolation
            }
        end
    end
    
    pData.status = hasViolation and "violating" or "compliant"
    playerScanData[name] = pData
    return pData
end

local function GetClassColoredName(name, class)
    if not name then return "" end
    if not class then return name end
    local color = RAID_CLASS_COLORS[class]
    if color then
        return string.format("|cff%02x%02x%02x%s|r", math.floor(color.r * 255), math.floor(color.g * 255), math.floor(color.b * 255), name)
    else
        return name
    end
end

local function ShortenName(name)
    if not name then return "" end
    if strlen(name) > 6 then
        return string.sub(name, 1, 5) .. ".."
    end
    return name
end

local function GetGroupRoster()
    local roster = {}
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local name, rank, subgroup, level, class, fileName = GetRaidRosterInfo(i)
            if name then
                local shortName = name:match("([^%-]+)")
                local unit = "raid" .. i
                table.insert(roster, {
                    name = name,
                    shortName = shortName,
                    unit = unit,
                    subgroup = subgroup,
                    class = fileName,
                })
            end
        end
    elseif IsInGroup() then
        local _, class = UnitClass("player")
        table.insert(roster, {
            name = UnitName("player"),
            shortName = UnitName("player"),
            unit = "player",
            subgroup = 1,
            class = class,
        })
        for i = 1, GetNumGroupMembers() - 1 do
            local unit = "party" .. i
            if UnitExists(unit) then
                local _, uClass = UnitClass(unit)
                local name = UnitName(unit)
                table.insert(roster, {
                    name = name,
                    shortName = name,
                    unit = unit,
                    subgroup = 1,
                    class = uClass,
                })
            end
        end
    else
        local name = UnitName("player")
        if name then
            local _, class = UnitClass("player")
            table.insert(roster, {
                name = name,
                shortName = name,
                unit = "player",
                subgroup = 1,
                class = class,
            })
        end
    end
    return roster
end

local function HighlightViolations()
    local visible = (CharacterFrame and CharacterFrame:IsVisible()) or (ElvUI_CharacterFrame and ElvUI_CharacterFrame:IsVisible())
    if not visible then return end
    
    local _, class = UnitClass("player")
    for uiName, info in pairs(slots) do
        local btn = _G["Character" .. uiName .. "Slot"] or _G["ElvUI_Character" .. uiName .. "Slot"]
        if btn then
            if not btn.sreRuneWarning then
                btn.sreRuneWarning = btn:CreateTexture(nil, "OVERLAY")
                btn.sreRuneWarning:SetTexture("Interface\\Buttons\\UI-AutoCastableOverlay")
                btn.sreRuneWarning:SetAllPoints()
                btn.sreRuneWarning:SetBlendMode("ADD")
                btn.sreRuneWarning:SetVertexColor(1, 0, 0, 0.7)
                btn.sreRuneWarning:Hide()
            end
            
            local runeName = GetRuneNameFromSlot("player", info.id)
            local isViolation = false
            if runeName then
                local phase = GetRunePhase(class, runeName)
                if phase and phase > SoDRuneEnforcerDB.phase then isViolation = true end
            end
            if isViolation then btn.sreRuneWarning:Show() else btn.sreRuneWarning:Hide() end
        end
    end
end

local function HookEngravingUI()
    if not EngravingFrame then return end
    hooksecurefunc("EngravingFrame_UpdateRuneList", function()
        if not EngravingFrame.scrollFrame or not EngravingFrame.scrollFrame.buttons then return end
        local _, class = UnitClass("player")
        for _, btn in ipairs(EngravingFrame.scrollFrame.buttons) do
            if btn:IsShown() and btn.name then
                if not btn.sreRuneWarning then
                    btn.sreRuneWarning = btn:CreateTexture(nil, "OVERLAY")
                    btn.sreRuneWarning:SetTexture("Interface\\Buttons\\UI-AutoCastableOverlay")
                    btn.sreRuneWarning:SetAllPoints()
                    btn.sreRuneWarning:SetBlendMode("ADD")
                    btn.sreRuneWarning:SetVertexColor(1, 0, 0, 0.7)
                    btn.sreRuneWarning:Hide()
                end
                local phase = GetRunePhase(class, btn.name)
                if phase and phase > SoDRuneEnforcerDB.phase then btn.sreRuneWarning:Show() else btn.sreRuneWarning:Hide() end
            end
        end
    end)
end

local function ShowPlayerTooltip(btn)
    local name = btn.playerName
    if not name then return end
    
    GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    
    local class = btn.playerClass
    local coloredName = GetClassColoredName(name, class)
    
    GameTooltip:AddDoubleLine(coloredName, string.format("Phase %d Mode", SoDRuneEnforcerDB.phase), 1, 1, 1, 0.7, 0.7, 0.7)
    GameTooltip:AddLine(" ")
    
    local data = playerScanData[name]
    if not data then
        GameTooltip:AddLine("No compliance data cached.", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Left-click to inspect player.", 0.5, 0.8, 1, true)
    else
        GameTooltip:AddLine("Equipped Runes Compliance:", 1, 0.82, 0)
        
        local orderedSlots = {
            { key = "Chest", label = "Chest" },
            { key = "Hands", label = "Gloves" },
            { key = "Legs", label = "Legs" },
            { key = "Waist", label = "Belt" },
            { key = "Feet", label = "Boots" },
            { key = "Head", label = "Helm" },
            { key = "Wrist", label = "Bracers" },
            { key = "Back", label = "Cloak" },
            { key = "Finger0", label = "Ring 1" },
            { key = "Finger1", label = "Ring 2" },
        }
        
        local hasAnyRune = false
        for _, item in ipairs(orderedSlots) do
            local rInfo = data.runes[item.key]
            if rInfo then
                hasAnyRune = true
                local phaseStr = rInfo.phase and string.format("P%d", rInfo.phase) or "P?"
                local r, g, b
                if rInfo.isViolation then
                    r, g, b = 1, 0.2, 0.2  -- red
                else
                    r, g, b = 0.2, 1, 0.2  -- green
                end
                GameTooltip:AddLine(string.format("%s: %s (%s)", item.label, rInfo.name, phaseStr), r, g, b)
            end
        end
        
        if not hasAnyRune then
            GameTooltip:AddLine("No engraved runes detected.", 0.8, 0.4, 0.4)
        end
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Left-click to re-inspect.", 0.5, 0.8, 1, true)
    end
    
    GameTooltip:Show()
end

local function UpdateUI()
    if not mainFrame or not mainFrame:IsShown() then return end
    
    if mainFrame.phaseValue then
        mainFrame.phaseValue:SetText("Phase " .. SoDRuneEnforcerDB.phase)
    end
    
    local roster = GetGroupRoster()
    local subgroupCounts = {0, 0, 0, 0, 0, 0, 0, 0}
    
    local mapped = {}
    for _, member in ipairs(roster) do
        local g = member.subgroup
        if g >= 1 and g <= 8 then
            subgroupCounts[g] = subgroupCounts[g] + 1
            local row = subgroupCounts[g]
            if row <= 5 then
                local btn = gridButtons[g][row]
                btn.playerName = member.shortName
                btn.playerClass = member.class
                btn.playerUnit = member.unit
                
                btn.nameText:SetText(GetClassColoredName(ShortenName(member.shortName), member.class))
                
                local data = playerScanData[member.shortName]
                if data then
                    local hasViolation = false
                    for slotName, rInfo in pairs(data.runes) do
                        local phase = GetRunePhase(member.class, rInfo.name)
                        if phase and phase > SoDRuneEnforcerDB.phase then
                            rInfo.isViolation = true
                            hasViolation = true
                        else
                            rInfo.isViolation = false
                        end
                    end
                    data.status = hasViolation and "violating" or "compliant"
                    
                    btn.status = data.status
                    if data.status == "compliant" then
                        btn:SetBackdropColor(0.1, 0.4, 0.15, 0.7)
                        btn:SetBackdropBorderColor(0.2, 0.6, 0.2, 1)
                    else
                        btn:SetBackdropColor(0.5, 0.1, 0.1, 0.7)
                        btn:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
                    end
                else
                    btn.status = "unscanned"
                    btn:SetBackdropColor(0.15, 0.15, 0.15, 0.6)
                    btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
                end
                
                btn:Show()
                mapped[g .. "_" .. row] = true
            end
        end
    end
    
    for col = 1, 8 do
        for row = 1, 5 do
            if not mapped[col .. "_" .. row] then
                gridButtons[col][row]:Hide()
            end
        end
    end
end

local function ClearInspectState()
    if activeInspectTimeoutTimer then
        activeInspectTimeoutTimer:Cancel()
        activeInspectTimeoutTimer = nil
    end
    activeInspectUnit = nil
end

local function PrintViolationsSummary()
    local roster = GetGroupRoster()
    local foundAny = false
    print("|cff00ff00[SRE] Scan complete for Phase " .. SoDRuneEnforcerDB.phase .. ".|r")
    for _, member in ipairs(roster) do
        local data = playerScanData[member.shortName]
        if data and data.status == "violating" then
            local violations = {}
            for slotName, info in pairs(slots) do
                local rInfo = data.runes[slotName]
                if rInfo and rInfo.isViolation then
                    table.insert(violations, string.format("%s (%s - P%d)", info.name, rInfo.name, rInfo.phase or 0))
                end
            end
            if #violations > 0 then
                print(string.format(L.VIOLATION_SUMMARY, member.shortName, table.concat(violations, ", ")))
                foundAny = true
            end
        end
    end
    if not foundAny then
        print("|cff00ff00[SRE]|r All group members are compliant.")
    end
end

local function ProcessInspectQueue()
    if #inspectQueue == 0 then
        isScanning = false
        if isGroupScanning then
            isGroupScanning = false
            PrintViolationsSummary()
        end
        UpdateUI()
        return
    end
    
    isScanning = true
    local unit = table.remove(inspectQueue, 1)
    
    if not UnitExists(unit) then
        ProcessInspectQueue()
        return
    end
    
    if unit == "player" then
        ScanUnit("player")
        UpdateUI()
        ProcessInspectQueue()
        return
    end
    
    if not CanInspect(unit) or not CheckInteractDistance(unit, 4) then
        ProcessInspectQueue()
        return
    end
    
    activeInspectUnit = unit
    NotifyInspect(unit)
    
    activeInspectTimeoutTimer = C_Timer.NewTimer(2.0, function()
        activeInspectUnit = nil
        ProcessInspectQueue()
    end)
end

local function QueueInspect(unit)
    for _, u in ipairs(inspectQueue) do
        if u == unit then return end
    end
    table.insert(inspectQueue, unit)
    if not activeInspectUnit then
        ProcessInspectQueue()
    end
end

local function QueueGroupScan()
    inspectQueue = {}
    ClearInspectState()
    
    local roster = GetGroupRoster()
    for _, member in ipairs(roster) do
        table.insert(inspectQueue, member.unit)
    end
    ProcessInspectQueue()
end

local function CreateUI()
    if mainFrame then return end
    
    mainFrame = CreateFrame("Frame", "SREMainFrame", UIParent, "BackdropTemplate")
    mainFrame:SetSize(660, 290)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
    mainFrame:Hide()

    mainFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    mainFrame:SetBackdropColor(0.08, 0.08, 0.1, 0.95)
    mainFrame:SetBackdropBorderColor(0.2, 0.25, 0.3, 1.0)

    local closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", 0, 0)
    closeBtn:SetScript("OnClick", function() mainFrame:Hide() end)

    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 15, -15)
    title:SetText("SoD Rune Enforcer")

    local phaseHeader = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    phaseHeader:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -15)
    phaseHeader:SetText("Enforcing Phase:")
    
    local phaseValue = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    phaseValue:SetPoint("TOPLEFT", phaseHeader, "BOTTOMLEFT", 0, -5)
    phaseValue:SetText("Phase " .. SoDRuneEnforcerDB.phase)
    mainFrame.phaseValue = phaseValue

    local function CreatePhaseButton(p, label, yOffset)
        local btn = CreateFrame("Button", nil, mainFrame, "GameMenuButtonTemplate")
        btn:SetSize(140, 22)
        btn:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 15, yOffset)
        btn:SetText(label)
        btn:SetScript("OnClick", function()
            SoDRuneEnforcerDB.phase = p
            print(string.format("|cff00ff00[SRE]|r " .. L.PHASE_SET, p))
            if CharacterFrame and CharacterFrame:IsVisible() then HighlightViolations() end
            if EngravingFrame and EngravingFrame:IsVisible() then EngravingFrame_UpdateRuneList() end
            UpdateUI()
        end)
        return btn
    end

    CreatePhaseButton(1, "Phase 1 (Lv 25)", -90)
    CreatePhaseButton(2, "Phase 2 (Lv 40)", -115)
    CreatePhaseButton(3, "Phase 3 (Lv 50)", -140)
    CreatePhaseButton(4, "Phase 4+ (Lv 60)", -165)

    local scanBtn = CreateFrame("Button", nil, mainFrame, "GameMenuButtonTemplate")
    scanBtn:SetSize(140, 30)
    scanBtn:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 15, -205)
    scanBtn:SetText("SCAN GROUP")
    scanBtn:SetScript("OnClick", function()
        isGroupScanning = true
        QueueGroupScan()
    end)

    local clearBtn = CreateFrame("Button", nil, mainFrame, "GameMenuButtonTemplate")
    clearBtn:SetSize(140, 22)
    clearBtn:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 15, -242)
    clearBtn:SetText("CLEAR CACHE")
    clearBtn:SetScript("OnClick", function()
        playerScanData = {}
        print("|cff00ff00[SRE]|r Cache cleared.")
        UpdateUI()
    end)

    local divider = mainFrame:CreateTexture(nil, "BORDER")
    divider:SetColorTexture(0.2, 0.25, 0.3, 0.8)
    divider:SetSize(1, 260)
    divider:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 170, -15)

    for col = 1, 8 do
        gridButtons[col] = {}
        
        local colHeader = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        colHeader:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 185 + (col - 1) * 59, -15)
        colHeader:SetWidth(53)
        colHeader:SetText("G" .. col)
        
        for row = 1, 5 do
            local btn = CreateFrame("Button", nil, mainFrame, "BackdropTemplate")
            btn:SetSize(53, 42)
            btn:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 185 + (col - 1) * 59, -35 - (row - 1) * 48)
            
            btn:SetBackdrop({
                bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 8, edgeSize = 8,
                insets = { left = 1, right = 1, top = 1, bottom = 1 }
            })
            btn:SetBackdropColor(0.15, 0.15, 0.15, 0.6)
            btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
            
            btn.nameText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            btn.nameText:SetPoint("CENTER", 0, 0)
            btn.nameText:SetWidth(48)
            btn.nameText:SetJustifyH("CENTER")
            
            btn:SetScript("OnClick", function(self)
                if self.playerUnit then
                    print("|cff00ff00[SRE]|r Scanning " .. GetClassColoredName(self.playerName, self.playerClass) .. "...")
                    QueueInspect(self.playerUnit)
                end
            end)
            
            btn:SetScript("OnEnter", function(self)
                ShowPlayerTooltip(self)
                self:SetBackdropBorderColor(1, 1, 1, 1)
            end)
            
            btn:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
                local status = self.status or "unscanned"
                if status == "compliant" then
                    self:SetBackdropBorderColor(0.2, 0.6, 0.2, 1)
                elseif status == "violating" then
                    self:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
                else
                    self:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
                end
            end)
            
            gridButtons[col][row] = btn
        end
    end
end

-- 3. Register Slash Command
SLASH_SODRUNEENFORCER1 = "/sre"
SlashCmdList["SODRUNEENFORCER"] = function(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    if cmd == "phase" then
        local p = tonumber(arg)
        if p and p >= 1 and p <= 8 then
            SoDRuneEnforcerDB.phase = p
            print(string.format("|cff00ff00[SRE]|r " .. L.PHASE_SET, p))
            HighlightViolations()
            UpdateUI()
        else
            print("|cffff0000[SRE]|r Invalid phase. Use /sre phase [1-8].")
        end
    elseif cmd == "ui" or cmd == "" then
        CreateUI()
        if mainFrame:IsShown() then
            mainFrame:Hide()
        else
            mainFrame:Show()
            HighlightViolations()
            UpdateUI()
        end
    elseif cmd == "check" then
        print(string.format("|cff00ff00[SRE]|r " .. L.CHECKING, SoDRuneEnforcerDB.phase))
        isGroupScanning = true
        QueueGroupScan()
    elseif cmd == "debug" then
        print("|cff00ff00[SRE] Rune Compliance Status:|r")
        local _, class = UnitClass("player")
        local found = 0
        for name, info in pairs(slots) do
            local rune = GetRuneNameFromSlot("player", info.id)
            if rune then
                found = found + 1
                local phase = GetRunePhase(class, rune)
                local isOK = (not phase or phase <= SoDRuneEnforcerDB.phase)
                print(string.format(" %s: %s | OK: %s (Phase: %s)", info.name, rune, isOK and "|cff00ff00Yes|r" or "|cffff0000No|r", phase or "Unknown"))
            end
        end
        if found == 0 then print("|cffff0000[SRE]|r No runes detected. Are they engraved on your gear?") end
    else
        print("|cff00ff00[SRE]|r " .. L.HELP)
    end
end

-- 4. Event Handler
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("INSPECT_READY")
f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("GROUP_ROSTER_UPDATE")

f:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == "SoDRuneEnforcer" then
        SoDRuneEnforcerDB = SoDRuneEnforcerDB or { phase = 1 }
        CreateUI()
        HookEngravingUI()
        print("|cff00ff00[SRE]|r Addon Loaded. Use /sre ui for control panel.")
    elseif event == "PLAYER_EQUIPMENT_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
        if SoDRuneEnforcerDB then
            HighlightViolations()
            ScanUnit("player")
            UpdateUI()
        end
    elseif event == "GROUP_ROSTER_UPDATE" then
        if SoDRuneEnforcerDB then
            UpdateUI()
        end
    elseif event == "INSPECT_READY" then
        local guid = arg1
        if activeInspectUnit and UnitGUID(activeInspectUnit) == guid then
            if activeInspectTimeoutTimer then
                activeInspectTimeoutTimer:Cancel()
                activeInspectTimeoutTimer = nil
            end
            ScanUnit(activeInspectUnit)
            ClearInspectPlayer()
            activeInspectUnit = nil
            UpdateUI()
            ProcessInspectQueue()
        end
    end
end)
