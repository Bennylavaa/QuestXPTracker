local addOnName = ...
local LEVEL_CAP = 60
local questXPCache = {}

local QXP = CreateFrame("FRAME")
QXP:RegisterEvent("ADDON_LOADED")

function QXP:ADDON_LOADED(loadedAddOnName)
    if loadedAddOnName == addOnName then
        local originalQuestLog_Update = QuestLog_Update
        QuestLog_Update = function()
            originalQuestLog_Update()
            QXP:UpdateQuestXP()
            QXP:UpdateQuestLogDisplay()
        end
    end
end

function QXP:UpdateQuestXP()
    local numEntries, numQuests = GetNumQuestLogEntries()
    if numEntries == 0 then
        return
    end
    
    local oldSelection = GetQuestLogSelection()
    questXPCache = {}
    
    for i = 1, numEntries do
        local title, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID, displayQuestID = GetQuestLogTitle(i)
        if not isHeader and questID then
            SelectQuestLogEntry(i)
            local questXP = GetQuestLogRewardXP()
            if questXP and questXP > 0 then
                questXPCache[questID] = questXP
            end
        end
    end
    
    if oldSelection > 0 then
        SelectQuestLogEntry(oldSelection)
    end
end

function QXP:UpdateQuestLogDisplay()
    if not QuestLogFrame:IsShown() then
        return
    end
    
    local playerLevel = UnitLevel("player")
    local xpLevelTag = playerLevel == LEVEL_CAP and "**" or "xp"
    local numEntries, numQuests = GetNumQuestLogEntries()
    
    if numEntries == 0 then
        return
    end
    
    local buttons = QuestLogScrollFrame.buttons
    if not buttons then
        return
    end
    
    local scrollOffset = HybridScrollFrame_GetOffset(QuestLogScrollFrame)
    
    for i = 1, #buttons do
        local questLogTitle = buttons[i]
        local questIndex = i + scrollOffset
        
        if questLogTitle and questIndex <= numEntries then
            local title, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID, displayQuestID = GetQuestLogTitle(questIndex)
            
            if not isHeader and questID then
                local questTitleTag = questLogTitle.tag
                
                if questTitleTag then
                    local questXP = questXPCache[questID]
                    local xpText = ""
                    
                    if questXP and questXP > 0 then
                        xpText = string.format("(%d%s)", questXP, xpLevelTag)
                    end
                    
                    local tagText = ""
                    if isComplete and isComplete < 0 then
                        questTag = FAILED
                    elseif isComplete and isComplete > 0 then
                        questTag = COMPLETE
                    elseif isDaily then
                        if questTag then
                            questTag = format(DAILY_QUEST_TAG_TEMPLATE, questTag)
                        else
                            questTag = DAILY
                        end
                    end
                    
                    if xpText ~= "" and questTag then
                        tagText = xpText .. "(" .. questTag .. ")"
                    elseif xpText ~= "" then
                        tagText = xpText
                    elseif questTag then
                        tagText = "(" .. questTag .. ")"
                    end
                    
                    if tagText ~= "" then
                        questTitleTag:SetText(tagText)
                        questTitleTag:Show()
                    else
                        questTitleTag:Hide()
                    end
                    
                    QuestLogTitleButton_Resize(questLogTitle)
                end
            end
        end
    end
end

QXP:SetScript("OnEvent",
    function (self, event, ...)
        if self[event] then
            return self[event](self, ...)
        end
    end
)
