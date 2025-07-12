function hcstrsplit(delimiter, subject)
    if not subject then return nil end
    local delimiter, fields = delimiter or ":", {}
    local pattern = string.format("([^%s]+)", delimiter)
    string.gsub(subject, pattern, function(c) fields[table.getn(fields)+1] = c end)
    return unpack(fields)
end

local major, minor, fix = hcstrsplit(".", tostring(GetAddOnMetadata("QuestXP", "Version")))
fix = fix or 0
local alreadyshown = false
local localversion = tonumber(major*10000 + minor*100 + fix)
local remoteversion = tonumber(qxpupdateavailable) or 0
local loginchannels = { "BATTLEGROUND", "RAID", "GUILD", "PARTY" }
local groupchannels = { "BATTLEGROUND", "RAID", "PARTY" }

qxpupdater = CreateFrame("Frame")
qxpupdater:RegisterEvent("CHAT_MSG_ADDON")
qxpupdater:RegisterEvent("PLAYER_ENTERING_WORLD")
qxpupdater:RegisterEvent("PARTY_MEMBERS_CHANGED")
qxpupdater:SetScript("OnEvent", function(_, event, ...)
    if event == "CHAT_MSG_ADDON" then
        local arg1, arg2 = ...
        if arg1 == "qxp" then
            local v, remoteversion = hcstrsplit(":", arg2)
            remoteversion = tonumber(remoteversion)
            if v == "VERSION" and remoteversion then
                if remoteversion > localversion then
                    qxpupdateavailable = remoteversion
                    if not alreadyshown then
                        print("QuestXP Tracker New version available! |cff66ccffhttps://github.com/Bennylavaa/QuestXPTracker|r")
                        alreadyshown = true
                    end
                end
            end
            if v == "PING?" then
                for _, chan in ipairs(loginchannels) do
                    SendAddonMessage("qxp", "PONG!:"..GetAddOnMetadata("QuestXP", "Version"), chan)
                end
            end
            if v == "PONG!" then
                --print(arg1 .." "..arg2.." "..arg3.." "..arg4)
            end
        end
        if event == "PARTY_MEMBERS_CHANGED" then
            local groupsize = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers() > 0 and GetNumPartyMembers() or 0
            if (this.group or 0) < groupsize then
                for _, chan in ipairs(groupchannels) do
                    SendAddonMessage("qxp", "VERSION:" .. localversion, chan)
                end
            end
            this.group = groupsize
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        if not alreadyshown and localversion < remoteversion then
            print("QuestXP Tracker New version available! |cff66ccffhttps://github.com/Bennylavaa/QuestXPTracker|r")
            qxpupdateavailable = localversion
            alreadyshown = true
        end
        for _, chan in ipairs(loginchannels) do
            SendAddonMessage("qxp", "VERSION:" .. localversion, chan)
        end
    end
end)