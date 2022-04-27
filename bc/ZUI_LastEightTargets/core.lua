LET = LibStub("AceAddon-3.0"):NewAddon("ZUI_LastEightTargets")
local L = LibStub("AceLocale-3.0"):GetLocale("ZUI_LastEightTargetsLocale")
local LET_GUI = LibStub("AceGUI-3.0")

local defaults = {
    
}

SLASH_LET1 = "/let"

SlashCmdList["LET"] = function()
    if (LET_GUI.Main:IsVisible()) then LET_GUI.Main:Hide() else LET_GUI.Main:Show() end
end

function LET:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("ZUI_LastEightTargetsDB", defaults, true)
    LET.lastTargets = {}
    LET_GUI.UnitFrames = {}

    LET:CreateUI()
    LET_GUI.Main:Hide()
end

function LET:CreateUI()
    if (LET_GUI.Main) then LET_GUI.Main:Hide() LET_GUI.Main = {} end
    LET_GUI.Main = CreateFrame("Frame", LastEightTargets, UIParent)
    LET_GUI.Main:SetSize(1000, 100)
    LET_GUI.Main:SetPoint("TOP", 0, -30)
    LET_GUI.Main:SetMovable(true)
    LET_GUI.Main:EnableMouse(true)
    LET_GUI.Main:RegisterForDrag("LeftButton")
    LET_GUI.Main:SetScript("OnDragStart", function() if(IsShiftKeyDown() == true) then LET_GUI.Main:StartMoving() end end)
    LET_GUI.Main:SetScript("OnDragStop", LET_GUI.Main.StopMovingOrSizing)
    LET_GUI.Main:RegisterEvent("PLAYER_TARGET_CHANGED")
    LET_GUI.Main:SetScript("OnEvent", function(self, event, ...) 
        if (event == "PLAYER_TARGET_CHANGED") then LET:PlayerTargetChanged(self, event, ...) end
    end)
    LET_GUI.Main:Show()
end

function LET:PlayerTargetChanged(self, event, ...)
    local targetInfo = {name = GetUnitName("target"), guid = UnitGUID("target")}

    -- if target is already in lastTargets, remove it
    for i, v in ipairs(LET.lastTargets) do 
        if (v.guid == targetInfo.guid) then table.remove(LET.lastTargets, i) end
    end
    
    -- Insert target to lastTargets 
    table.insert(LET.lastTargets, targetInfo)

    -- removes target from lastTarget after some time (removes frame too)
    LET:RemoveFrameAfterTime(targetInfo)

    -- limit of 8 targets
    if (#LET.lastTargets > 8) then
        table.remove(LET.lastTargets, 1)
    end

    -- Make or Reuse UnitFrame
    LET:MakeUnitFrames() 

    -- Change Name of new/hidden UnitFrames
    LET:AddNameToNewUnitFrame()
end

function LET:MakeUnitFrames() 
    -- Make/Reuse unitframes
    for i, v in ipairs(LET.lastTargets) do 
        -- if they dont exist
        if (LET_GUI.UnitFrames[i] == nil) then 
            local unitFrame = CreateFrame("Button", nil, LET_GUI.Main, "SecureActionButtonTemplate")
            unitFrame:SetSize(150, 50)
            unitFrame:SetPoint("TOPLEFT", 150 * (i-1), -20)
            -- unitFrame:SetAttribute("type", "target")
            -- unitFrame:SetAttribute("unit", "player")
            unitFrame:SetAttribute("type", "macro")
            unitFrame:SetAttribute("macrotext1", string.format("/target %s", v.name))
            table.insert(LET_GUI.UnitFrames, unitFrame)
        -- if UnitFrames do exist but are hidden, reuse the frame
        elseif (LET_GUI.UnitFrames[i]:IsVisible() == false) then
            LET_GUI.UnitFrames[i]:Show()
        end
    end
end

function LET:AddNameToNewUnitFrame()
    -- change name on unitframes
    for i, v in ipairs(LET.lastTargets) do
    if (LET_GUI.UnitFrames[i].Name == nil) then 
        LET_GUI.UnitFrames[i].Name = LET_GUI.UnitFrames[i]:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
    end
    LET_GUI.UnitFrames[i].Name:SetPoint("TOP", 0, -20)
    LET_GUI.UnitFrames[i].Name:SetText(LET.lastTargets[i].name)
    end
end

function LET:RemoveFrameAfterTime(targetInfo)
   -- settiemout to remove old targets and hide last unitframe
   C_Timer.After(30, function() 
        -- loop through lastTargets, if targetInfo.guid == lastTargets.guid remove from lastTargets
        for i, v in ipairs(LET.lastTargets) do 
            if (targetInfo.guid == v.guid) then
                table.remove(LET.lastTargets, i)
            end
        end
        
        -- count all visible UnitFrames
        local visibleFrames = 0;
        for i, v in ipairs(LET_GUI.UnitFrames) do
            if (v:IsVisible() == true) then visibleFrames = visibleFrames + 1 end
        end
        -- hide last UnitFrame if there are more UnitFrames than lastTargets
        if (#LET.lastTargets < visibleFrames) then 
            LET_GUI.UnitFrames[visibleFrames]:Hide()
        end
        
        -- Change all UnitFrames name
        LET:ShiftDownUnitFramesName()
    end)
end

function LET:ShiftDownUnitFramesName()
    for i, v in ipairs(LET.lastTargets) do
        LET_GUI.UnitFrames[i].Name:SetText(LET.lastTargets[i].name)
        LET_GUI.UnitFrames[i]:SetAttribute("type", "macro")
        LET_GUI.UnitFrames[i]:SetAttribute("macrotext1", string.format("/target %s", v.name))
    end
end