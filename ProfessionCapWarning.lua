-- ProfessionCapWarning.lua - v3 (Simplified)
DEFAULT_CHAT_FRAME:AddMessage("ProfessionCapWarning: Starting to load...")

local ADDON_NAME = "ProfessionCapWarning"
local CHECK_INTERVAL = 10 -- seconds

-- Right column frame (gathering profs) - anchored from center going right
local rightFrame = CreateFrame("Frame", "ProfCapRightFrame", UIParent)
rightFrame:SetWidth(350)
rightFrame:SetHeight(300)
rightFrame:SetPoint("TOPLEFT", UIParent, "TOP", 10, -20)
rightFrame:Hide()

-- Right column text (left-aligned, text flows left to right from center)
local rightText = rightFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rightText:SetPoint("TOPLEFT", rightFrame, "TOPLEFT", 0, 0)
rightText:SetJustifyH("LEFT")
rightText:SetTextColor(1, 1, 1)

-- Left column frame (crafting profs) - anchored from center going left
local leftFrame = CreateFrame("Frame", "ProfCapLeftFrame", UIParent)
leftFrame:SetWidth(350)
leftFrame:SetHeight(300)
leftFrame:SetPoint("TOPRIGHT", UIParent, "TOP", -10, -20)
leftFrame:Hide()

-- Left column text (right-aligned, text flows right to left from center)
local leftText = leftFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
leftText:SetPoint("TOPRIGHT", leftFrame, "TOPRIGHT", 0, 0)
leftText:SetJustifyH("RIGHT")
leftText:SetTextColor(1, 1, 1)

DEFAULT_CHAT_FRAME:AddMessage("ProfessionCapWarning: Warning frames created")

-- Edge glow frames for urgent warnings
local edgeGlow = {}
edgeGlow.textures = {}

-- Top edge
edgeGlow.top = CreateFrame("Frame", "ProfCapEdgeTop", UIParent)
edgeGlow.top:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
edgeGlow.top:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
edgeGlow.top:SetHeight(200)
edgeGlow.top:SetFrameStrata("BACKGROUND")
edgeGlow.textures.top = edgeGlow.top:CreateTexture(nil, "BACKGROUND")
edgeGlow.textures.top:SetAllPoints()
edgeGlow.textures.top:SetTexture(1, 0, 0, 0.3)
edgeGlow.textures.top:SetGradientAlpha("VERTICAL", 1, 0, 0, 0, 1, 0, 0, 0.4)
edgeGlow.top:Hide()

-- Bottom edge
edgeGlow.bottom = CreateFrame("Frame", "ProfCapEdgeBottom", UIParent)
edgeGlow.bottom:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
edgeGlow.bottom:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
edgeGlow.bottom:SetHeight(200)
edgeGlow.bottom:SetFrameStrata("BACKGROUND")
edgeGlow.textures.bottom = edgeGlow.bottom:CreateTexture(nil, "BACKGROUND")
edgeGlow.textures.bottom:SetAllPoints()
edgeGlow.textures.bottom:SetTexture(1, 0, 0, 0.3)
edgeGlow.textures.bottom:SetGradientAlpha("VERTICAL", 1, 0, 0, 0.4, 1, 0, 0, 0)
edgeGlow.bottom:Hide()

-- Left edge
edgeGlow.left = CreateFrame("Frame", "ProfCapEdgeLeft", UIParent)
edgeGlow.left:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
edgeGlow.left:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
edgeGlow.left:SetWidth(200)
edgeGlow.left:SetFrameStrata("BACKGROUND")
edgeGlow.textures.left = edgeGlow.left:CreateTexture(nil, "BACKGROUND")
edgeGlow.textures.left:SetAllPoints()
edgeGlow.textures.left:SetTexture(1, 0, 0, 0.3)
edgeGlow.textures.left:SetGradientAlpha("HORIZONTAL", 1, 0, 0, 0.4, 1, 0, 0, 0)
edgeGlow.left:Hide()

-- Right edge
edgeGlow.right = CreateFrame("Frame", "ProfCapEdgeRight", UIParent)
edgeGlow.right:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
edgeGlow.right:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
edgeGlow.right:SetWidth(200)
edgeGlow.right:SetFrameStrata("BACKGROUND")
edgeGlow.textures.right = edgeGlow.right:CreateTexture(nil, "BACKGROUND")
edgeGlow.textures.right:SetAllPoints()
edgeGlow.textures.right:SetTexture(1, 0, 0, 0.3)
edgeGlow.textures.right:SetGradientAlpha("HORIZONTAL", 1, 0, 0, 0, 1, 0, 0, 0.4)
edgeGlow.right:Hide()

-- Pulse state
edgeGlow.pulseTime = 0
edgeGlow.intensity = 0

-- Cache state
local cachedSkills = {}
local cachedTotalPoints = 0
local lastUpdate = 0

-- Zone data extracted from wow-professions.com guides
local ZONE_DATA = {
    ["Herbalism"] = {
        [1] = {"Elwynn Forest", "Durotar", "Teldrassil", "Dun Morogh", "Tirisfal Glades", "Mulgore"},
        [70] = {"The Barrens", "Silverpine Forest", "Loch Modan", "Darkshore"},
        [115] = {"Hillsbrad Foothills", "Wetlands", "Stonetalon Mountains"},
        [170] = {"Stranglethorn Vale", "Arathi Highlands"},
        [205] = {"Tanaris", "Searing Gorge"},
        [230] = {"The Hinterlands"},
        [270] = {"Felwood", "Eastern Plaguelands", "Winterspring"}
    },
    ["Fishing"] = {
        [1] = {"Elwynn Forest", "Durotar", "Teldrassil", "Dun Morogh", "Tirisfal Glades", "Mulgore"},
        [75] = {"The Barrens", "Darkshore", "Ironforge", "Loch Modan", "Silverpine Forest", "Westfall"},
        [150] = {"Dustwallow Marsh", "Alterac Mountains", "Arathi Highlands", "Desolace", "Stranglethorn Vale", "Swamp of Sorrows", "Thousand Needles"},
        [225] = {"Felwood", "Feralas", "The Hinterlands", "Tanaris", "Un'Goro Crater", "Western Plaguelands"}
    },
    ["Mining"] = {
        [1] = {"Durotar", "Mulgore", "Tirisfal Glades", "Elwynn Forest", "Darkshore", "Dun Morogh"},
        [65] = {"Hillsbrad Foothills", "Redridge Mountains", "Ashenvale", "The Barrens"},
        [125] = {"Arathi Highlands", "Desolace", "Thousand Needles", "Stranglethorn Vale"},
        [175] = {"The Hinterlands", "Tanaris", "Badlands", "Searing Gorge"},
        [225] = {"Burning Steppes", "Searing Gorge", "Badlands", "Tanaris"},
        [250] = {"Un'Goro Crater", "Eastern Plaguelands", "Winterspring", "Burning Steppes"}
    },
    ["Skinning"] = {
        [1] = {"Durotar", "Dun Morogh", "Elwynn Forest", "Teldrassil"},
        [75] = {"The Barrens", "Loch Modan", "Wetlands", "Hillsbrad Foothills"},
        [155] = {"Thousand Needles", "Arathi Highlands", "Stranglethorn Vale", "Desolace"},
        [215] = {"Tanaris", "Feralas", "The Hinterlands", "Azshara"},
        [260] = {"Un'Goro Crater", "Felwood", "Eastern Plaguelands", "Winterspring"}
    }
}

-- Gathering professions
local GATHERING_PROFS = {"Herbalism", "Mining", "Skinning", "Fishing"}

-- Crafting professions
local CRAFTING_PROFS = {"Alchemy", "Blacksmithing", "Enchanting", "Engineering", "Leatherworking", "Tailoring",
                        "Cooking", "First Aid"}

-- All professions  
local ALL_PROFS = {}
for _, prof in ipairs(GATHERING_PROFS) do
    table.insert(ALL_PROFS, prof)
end
for _, prof in ipairs(CRAFTING_PROFS) do
    table.insert(ALL_PROFS, prof)
end

local SPECIAL_TRAINERS = {
    ["Alchemy"] = {
        [150] = {
            alliance = "Expert: Ainethil (Darnassus)",
            horde = "Expert: Doctor Herbert Halsey (Undercity)"
        },
        [225] = {
            alliance = "Artisan: Kylanna Windwhisper (Feathermoon, Feralas)",
            horde = "Artisan: Rogvar (Stonard, Swamp of Sorrows)"
        }
    },
    ["Blacksmithing"] = {
        [150] = {
            alliance = "Expert: Bengus Deepforge (Ironforge)",
            horde = "Expert: Saru Steelfury (Orgrimmar)"
        },
        [225] = "Artisan: Brikk Keencraft (Booty Bay, STV)"
    },
    ["Cooking"] = {
        [150] = {
            alliance = "Expert: Buy book from Shandrina (Ashenvale)",
            horde = "Expert: Buy book from Wulan (Shadowprey, Desolace)"
        },
        [225] = {
            alliance = "Artisan: Quest from Daryl Riknussun (Ironforge)",
            horde = "Artisan: Quest from Zamja (Orgrimmar)"
        }
    },
    ["Enchanting"] = {
        [150] = {
            alliance = "Expert: Kitta Firewind (Tower of Azora, Elwynn)",
            horde = "Expert: Hgarth (Sun Rock Retreat, Stonetalon)"
        },
        [225] = "Artisan: Annora (Uldaman instance, Badlands)"
    },
    ["Engineering"] = {
        [150] = {
            alliance = "Expert: Springspindle Fizzlegear (Ironforge)",
            horde = "Expert: Roxxik (Orgrimmar)"
        },
        [225] = "Artisan: Buzzek Bracketswing (Gadgetzan, Tanaris)"
    },
    ["Fishing"] = {
        [150] = "Expert: Buy book from Old Man Heming (STV)",
        [225] = "Artisan: Nat Pagle Quest (Dustwallow Marsh)"
    },
    ["First Aid"] = {
        [150] = {
            alliance = "Expert: Buy book (Theramore or Stromgarde)",
            horde = "Expert: Buy book (Brackenwall or Hammerfall)"
        },
        [225] = {
            alliance = "Artisan: Triage quest (Theramore, Dustwallow)",
            horde = "Artisan: Triage quest (Brackenwall, Dustwallow)"
        }
    },
    ["Leatherworking"] = {
        [150] = {
            alliance = "Expert: Telonis (Darnassus)",
            horde = "Expert: Una (Thunder Bluff)"
        },
        [225] = {
            alliance = "Artisan: Drakk Stonehand (Aerie Peak, Hinterlands)",
            horde = "Artisan: Hahrana Ironhide (Camp Mojache, Feralas)"
        }
    },
    ["Tailoring"] = {
        [150] = {
            alliance = "Expert: Georgio Bolero (Stormwind)",
            horde = "Expert: Josef Gregorian (Undercity)"
        },
        [225] = {
            alliance = "Artisan: Timothy Worthington (Theramore, Dustwallow)",
            horde = "Artisan: Daryl Stack (Tarren Mill, Hillsbrad)"
        }
    }
}

-- Calculate beast level range for skinning skill
local function GetBeastLevelRange(skillRank)
    -- Skinning formula in WoW Classic:
    -- - Skills 1-100: max level = (skill / 10) + 10
    -- - Skills 100+: max level = skill / 5
    -- - Skill-ups from mobs ~10 levels below max

    local maxLevel
    if skillRank < 100 then
        maxLevel = math.floor(skillRank / 10) + 10
    else
        maxLevel = math.floor(skillRank / 5)
    end

    local minLevel = maxLevel - 10

    -- Clamp to valid levels
    if minLevel < 1 then minLevel = 1 end
    if maxLevel > 60 then maxLevel = 60 end

    return minLevel, maxLevel
end

-- Get appropriate zones for skill level
local function GetZonesForSkill(profession, skillRank)
    local zones = ZONE_DATA[profession]
    if not zones then
        return nil
    end

    local bestRange = 1
    for threshold, _ in pairs(zones) do
        if skillRank >= threshold and threshold > bestRange then
            bestRange = threshold
        end
    end

    return zones[bestRange]
end

-- Get trainer suggestion text
local function GetTrainerSuggestion(profession, skillRank, skillMaxRank)
    -- check if skillMaxRank is 300+
    if skillMaxRank >= 300 then
        return "Almost done!"
    end

    -- Check for special trainer requirements
    local specialTrainers = SPECIAL_TRAINERS[profession]
    if specialTrainers then
        -- Get player faction
        local faction = UnitFactionGroup("player")
        local factionKey = (faction == "Alliance" and "alliance") or "horde"

        for threshold, instruction in pairs(specialTrainers) do
            if skillMaxRank >= threshold and skillRank >= (threshold - 25) then
                if type(instruction) == "table" then
                    return instruction[factionKey] or "Visit a trainer"
                else
                    return instruction
                end
            end
        end
    end

    -- Default case
    return "Visit a trainer"
end

-- Check if this is an actual profession
local function IsProfession(skillName)
    for _, prof in ipairs(ALL_PROFS) do
        if skillName == prof then
            return true
        end
    end
    return false
end

-- Check if this is a gathering profession
local function IsGatheringProfession(profName)
    for _, prof in ipairs(GATHERING_PROFS) do
        if profName == prof then
            return true
        end
    end
    return false
end

-- Get current profession values
local function GetAllSkills()
    local skills = {}
    local success, numSkills = pcall(GetNumSkillLines)
    if not success then
        return skills
    end

    for i = 1, numSkills do
        local success, skillName, isHeader, _, skillRank, _, _, skillMaxRank = pcall(GetSkillLineInfo, i)
        if not success then
            break
        end

        skillRank = tonumber(skillRank) or 0
        skillMaxRank = tonumber(skillMaxRank) or 0

        if skillName and not isHeader and skillMaxRank > 0 and IsProfession(skillName) then
            skills[skillName] = {
                rank = skillRank,
                maxRank = skillMaxRank
            }
        end
    end

    return skills
end

-- Check specific profession for cap and return warning info
local function CheckSingleProfession(profName, skillRank, skillMaxRank)
    -- Safety checks
    if not profName or not skillRank or not skillMaxRank then
        return nil
    end

    skillRank = tonumber(skillRank) or 0
    skillMaxRank = tonumber(skillMaxRank) or 0

    -- Skip if already at true max (300/300)
    if skillRank >= 300 and skillMaxRank >= 300 then
        return nil
    end

    -- Determine status and color
    local status = "normal"
    local color = "|cff00FF00" -- Green
    local trainerSuggestion = ""
    local zoneSuggestion = ""
    local beastLevelRange = ""
    local urgency = 0 -- 0 = normal, 0-1 = ready, 1 = capped

    -- Check if capped (red priority) - but no urgency if already at max training (300)
    if skillRank >= skillMaxRank then
        status = "capped"
        color = "|cffFF0000" -- Red
        trainerSuggestion = GetTrainerSuggestion(profName, skillRank, skillMaxRank) or "Visit trainer"
        if skillMaxRank < 300 then
            urgency = 1.0
        end
        -- Check if can train (orange priority) - only for sub-300 caps
    elseif (skillMaxRank == 75 and skillRank >= 50) or (skillMaxRank == 150 and skillRank >= 125) or
        (skillMaxRank == 225 and skillRank >= 200) then
        status = "ready"
        color = "|cffFF8000" -- Orange
        trainerSuggestion = GetTrainerSuggestion(profName, skillRank, skillMaxRank) or "Ready to train"
        -- Calculate urgency based on proximity to cap (0.3 to 1.0)
        local pointsFromCap = skillMaxRank - skillRank
        local maxPointsInRange = 25
        urgency = 0.3 + (0.7 * (1 - (pointsFromCap / maxPointsInRange)))
    end

    -- Get zone suggestions for gathering professions
    if IsGatheringProfession(profName) then
        local zones = GetZonesForSkill(profName, skillRank)
        if zones and table.getn(zones) > 0 then
            zoneSuggestion = table.concat(zones, ", ")
        end

        -- Add beast level range for skinning
        if profName == "Skinning" then
            local minLevel, maxLevel = GetBeastLevelRange(skillRank)
            beastLevelRange = "Beasts: " .. minLevel .. "-" .. maxLevel
        end
    end

    return {
        profession = profName,
        status = status,
        color = color,
        skillText = skillRank .. "/" .. skillMaxRank,
        skillRank = skillRank,
        skillMaxRank = skillMaxRank,
        trainerSuggestion = trainerSuggestion,
        zoneSuggestion = zoneSuggestion,
        beastLevelRange = beastLevelRange,
        urgency = urgency,
        priority = (status == "capped" and 1) or (status == "ready" and 2) or 3
    }
end

-- Helper function to build zone frequency map
local function BuildZoneFrequencyMap(professionInfoList)
    local zoneCount = {}

    for _, info in ipairs(professionInfoList) do
        if info.zoneSuggestion and info.zoneSuggestion ~= "" then
            -- Split zones by comma
            local zones = {}
            for zone in string.gfind(info.zoneSuggestion, "[^,]+") do
                -- Trim whitespace
                zone = string.gsub(zone, "^%s*(.-)%s*$", "%1")
                zones[zone] = true
            end

            -- Count each unique zone
            for zone, _ in pairs(zones) do
                zoneCount[zone] = (zoneCount[zone] or 0) + 1
            end
        end
    end

    return zoneCount
end

-- Helper function to color a zone name based on frequency
local function ColorZoneByFrequency(zoneName, frequency)
    if frequency >= 4 then
        return "|cffFF8000" .. zoneName .. "|r" -- Orange (4 professions)
    elseif frequency >= 3 then
        return "|cffFFFF00" .. zoneName .. "|r" -- Yellow (3 professions)
    elseif frequency >= 2 then
        return "|cff00FF00" .. zoneName .. "|r" -- Green (2 professions)
    else
        return zoneName -- No color (1 profession)
    end
end

-- Main update function
local function UpdateDisplay()
    local currentSkills = GetAllSkills()

    -- Check if anything actually changed
    local hasChanges = false
    for profName, current in pairs(currentSkills) do
        local cached = cachedSkills[profName]
        if not cached or cached.rank ~= current.rank or cached.maxRank ~= current.maxRank then
            hasChanges = true
            break
        end
    end

    -- Early exit if no changes
    if not hasChanges then
        return
    end

    -- Update cache immediately
    cachedSkills = currentSkills

    local allProfessionInfo = {}

    -- Get all profession info (gathering and crafting)
    for _, profName in ipairs(ALL_PROFS) do
        local current = currentSkills[profName]
        if current then
            local info = CheckSingleProfession(profName, current.rank, current.maxRank)
            if info then
                table.insert(allProfessionInfo, info)
            end
        end
    end

    -- Separate gathering (excluding fishing), fishing, and crafting professions
    local gatheringProfs = {}
    local fishingProfs = {}
    local craftingProfs = {}

    for _, info in ipairs(allProfessionInfo) do
        if info.profession == "Fishing" then
            table.insert(fishingProfs, info)
        elseif IsGatheringProfession(info.profession) then
            table.insert(gatheringProfs, info)
        else
            table.insert(craftingProfs, info)
        end
    end

    -- Sort function: by urgency desc, then by maxRank desc (closer to 300 = higher)
    local function sortByUrgencyAndMaxRank(a, b)
        if a.urgency ~= b.urgency then
            return a.urgency > b.urgency
        end
        return a.skillMaxRank > b.skillMaxRank
    end

    table.sort(gatheringProfs, sortByUrgencyAndMaxRank)
    table.sort(fishingProfs, sortByUrgencyAndMaxRank)
    table.sort(craftingProfs, sortByUrgencyAndMaxRank)

    -- Build zone frequency map for highlighting (gathering + fishing only)
    local gatheringAndFishing = {}
    for _, info in ipairs(gatheringProfs) do table.insert(gatheringAndFishing, info) end
    for _, info in ipairs(fishingProfs) do table.insert(gatheringAndFishing, info) end
    local zoneFrequency = BuildZoneFrequencyMap(gatheringAndFishing)

    -- Track maximum urgency across all
    local maxUrgency = 0
    for _, info in ipairs(allProfessionInfo) do
        if info.urgency > maxUrgency then
            maxUrgency = info.urgency
        end
    end

    -- Build RIGHT column message (gathering + fishing): name, skill, trainer, zones
    local rightMessage = ""
    local rightProfs = {}
    for _, info in ipairs(gatheringProfs) do table.insert(rightProfs, info) end
    for _, info in ipairs(fishingProfs) do table.insert(rightProfs, info) end

    for i, info in ipairs(rightProfs) do
        if i > 1 then
            rightMessage = rightMessage .. "\n\n"
        end

        -- Main profession line: name, skill, trainer info
        local line = info.color .. info.profession .. "|r " .. info.skillText
        if info.trainerSuggestion and info.trainerSuggestion ~= "" then
            line = line .. " - " .. info.trainerSuggestion
        end
        if info.beastLevelRange and info.beastLevelRange ~= "" then
            line = line .. " (" .. info.beastLevelRange .. ")"
        end

        rightMessage = rightMessage .. line

        -- Zone suggestions on separate line with frequency-based coloring
        if info.zoneSuggestion and info.zoneSuggestion ~= "" then
            local zoneList = {}
            for zone in string.gfind(info.zoneSuggestion, "[^,]+") do
                zone = string.gsub(zone, "^%s*(.-)%s*$", "%1")
                local frequency = zoneFrequency[zone] or 1
                table.insert(zoneList, { name = zone, freq = frequency })
            end

            table.sort(zoneList, function(a, b)
                if a.freq ~= b.freq then return a.freq > b.freq end
                return a.name < b.name
            end)

            local coloredZones = {}
            for _, zoneData in ipairs(zoneList) do
                table.insert(coloredZones, ColorZoneByFrequency(zoneData.name, zoneData.freq))
            end
            rightMessage = rightMessage .. "\n  " .. table.concat(coloredZones, ", ")
        end
    end

    -- Build LEFT column message (crafting): trainer info - skill - name (reversed order)
    local leftMessage = ""
    for i, info in ipairs(craftingProfs) do
        if i > 1 then
            leftMessage = leftMessage .. "\n\n"
        end

        -- Reversed order: trainer info - skill - name
        local line = ""
        if info.trainerSuggestion and info.trainerSuggestion ~= "" then
            line = info.trainerSuggestion .. " - "
        end
        line = line .. info.skillText .. " " .. info.color .. info.profession .. "|r"

        leftMessage = leftMessage .. line
    end

    -- Show/hide frames based on content
    if rightMessage ~= "" then
        rightText:SetText(rightMessage)
        rightFrame:Show()
    else
        rightFrame:Hide()
    end

    if leftMessage ~= "" then
        leftText:SetText(leftMessage)
        leftFrame:Show()
    else
        leftFrame:Hide()
    end

    -- Update edge glow intensity based on maximum urgency
    edgeGlow.intensity = maxUrgency
    if maxUrgency > 0 then
        if maxUrgency >= 0.3 then
            PlaySound("RaidWarning")
        end
        edgeGlow.top:Show()
        edgeGlow.bottom:Show()
        edgeGlow.left:Show()
        edgeGlow.right:Show()
    else
        edgeGlow.top:Hide()
        edgeGlow.bottom:Hide()
        edgeGlow.left:Hide()
        edgeGlow.right:Hide()
    end

    -- Hide frames if nothing to show
    if table.getn(allProfessionInfo) == 0 then
        rightFrame:Hide()
        leftFrame:Hide()
        edgeGlow.intensity = 0
        edgeGlow.top:Hide()
        edgeGlow.bottom:Hide()
        edgeGlow.left:Hide()
        edgeGlow.right:Hide()
    end
end

-- Timer state and function using frame OnUpdate
local lastUpdate = 0

-- Event frame
local eventFrame = CreateFrame("Frame")

-- Pulse update function for edge glow
local function UpdateEdgeGlowPulse()
    if edgeGlow.intensity > 0 then
        local currentTime = GetTime()
        edgeGlow.pulseTime = currentTime

        -- Pulse speed increases with urgency (faster when more urgent)
        local pulseSpeed = 1.5 + (edgeGlow.intensity * 1.5) -- 1.5 to 3.0 seconds per cycle
        local pulsePhase = (currentTime - math.floor(currentTime / pulseSpeed) * pulseSpeed) / pulseSpeed -- 0 to 1

        -- Sine wave for smooth pulsing
        local pulseFactor = (math.sin(pulsePhase * 3.14159 * 2) + 1) / 2 -- 0 to 1

        -- Base alpha increases with urgency, pulse amplitude also increases
        -- When capped (intensity = 1.0): baseAlpha = 0.6, amplitude = 0.4, max alpha = 1.0
        local baseAlpha = 0.3 + (edgeGlow.intensity * 0.3) -- 0.3 to 0.6
        local pulseAmplitude = 0.2 + (edgeGlow.intensity * 0.2) -- 0.2 to 0.4
        local alpha = baseAlpha + (pulseFactor * pulseAmplitude)

        -- Update all edge textures with pulsing alpha
        edgeGlow.textures.top:SetGradientAlpha("VERTICAL", 1, 0, 0, 0, 1, 0, 0, alpha)
        edgeGlow.textures.bottom:SetGradientAlpha("VERTICAL", 1, 0, 0, alpha, 1, 0, 0, 0)
        edgeGlow.textures.left:SetGradientAlpha("HORIZONTAL", 1, 0, 0, alpha, 1, 0, 0, 0)
        edgeGlow.textures.right:SetGradientAlpha("HORIZONTAL", 1, 0, 0, 0, 1, 0, 0, alpha)
    end
end

-- Timer function using frame OnUpdate
local function OnUpdate()
    local currentTime = GetTime()

    -- Update edge glow pulse every frame if active
    UpdateEdgeGlowPulse()

    -- Check for profession updates every CHECK_INTERVAL seconds
    if currentTime - lastUpdate >= CHECK_INTERVAL then
        lastUpdate = currentTime
        UpdateDisplay()
    end
end

-- Event handler
local function OnEvent()
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        DEFAULT_CHAT_FRAME:AddMessage(ADDON_NAME .. " v3 loaded - 10s update cycle")
        UpdateDisplay()
        lastUpdate = GetTime()
        eventFrame:SetScript("OnUpdate", OnUpdate)
    end
end

-- Event registration
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", OnEvent)
