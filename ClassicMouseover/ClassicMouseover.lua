--[[-
Classic Mouseover
Lets you make mouseover macros for Vanilla WoW (1.12.1)
Acknowledgements: This heavily borrows on Clique's design. It wouldn't have been possible(for me) without it.
]]
CM = AceLibrary("AceAddon-2.0"):new(
    "AceHook-2.0", 
    "AceConsole-2.0",
    "AceEvent-2.0",
    "AceModuleCore-2.0",
    "AceDebug-2.0"
)

StaticPopupDialogs["CM_AUTO_SELF_CAST"] = {
	text = "Classic Mouseover will not work properly with Blizzard's AutoSelfCast.  Please disable it.",
	button1 = TEXT(OKAY),
	OnAccept = function()
	end,
	timeout = 0,
	hideOnEscape = 1
}

local L = AceLibrary:GetInstance("AceLocale-2.0"):new("CM")
L:RegisterTranslations("enUS", function()
    return {
        DUAL_HOLY_SHOCK		        = "Holy Shock",
        DUAL_MIND_VISION            = "Mind Vision",
		CURE_DISPEL_MAGIC 		    = "Dispel Magic",
    }
end)
L:RegisterTranslations("zhCN", function()
    return {
        DUAL_HOLY_SHOCK		        = "\231\165\158\229\156\163\233\156\135\229\135\187",
        DUAL_MIND_VISION            = "\229\191\131\231\191\181\232\167\134\231\149\140",
        CURE_DISPEL_MAGIC 		    = "\233\169\177\230\149\163\233\173\148\230\179\149",
    }
end)
L:RegisterTranslations("frFR", function()
    return {
        DUAL_HOLY_SHOCK		        = "Holy Shock",
        DUAL_MIND_VISION            = "Vision t\195\169l\195\169pathique",
        CURE_DISPEL_MAGIC 	    	= "Dissiper Magie",
    }
end)
L:RegisterTranslations("deDE", function()
    return {
        DUAL_HOLY_SHOCK		        = "Heiliger Schock",
        DUAL_MIND_VISION            = "Gedankensicht",
        CURE_DISPEL_MAGIC 		    = "Magiebannung",
    }
end)

-- Expoxe AceHook and AceEvent to our modules
CM:SetModuleMixins("AceHook-2.0", "AceEvent-2.0", "AceDebug-2.0")

CM.currentUnit = nil

--[[---------------------------------------------------------------------------------
  This is the actual addon object
----------------------------------------------------------------------------------]]

function CM:OnInitialize()
    self:LevelDebug(2, "CM:OnInitialize()")
    
    self:LevelDebug(3, "Setting all modules to inactive.")
    for name,module in self:IterateModules() do
        self:ToggleModuleActive(name, false)
    end
end

function CM:OnEnable()
    -- Register for ADDON_LOADED so we can load plugins for LOD addons
    self:RegisterEvent("ADDON_LOADED", "LoadModules")
    
	if GetCVar("AutoSelfCast") == "1" then
        StaticPopup_Show("CM_AUTO_SELF_CAST")
        return
    end
    -- Load any valid modules
    self:LoadModules()

end

function CM:LoadModules()
    for name,module in self:IterateModules() do
        if not self:IsModuleActive(name) and not module.disabled then
            -- Try to enable the module
            
            local loadModule = nil
                        
            if module.Test and type(module.Test) == "function" then
                if module:Test() then
                    loadModule = true
                end
            else
                loadModule = true
            end
            
            if loadModule and not CM:IsModuleActive(name) then
                self:LevelDebug(1, "Enabling module \"%s\" for %s.", name, module.fullname)
                CM:ToggleModuleActive(name,true)
 
                if module._OnClick then
                    self:LevelDebug(2, "Grabbing _OnClick from %s", name)
                    self._OnClick[name] = module
                end
            end
        end
    end
end

function CM:CheckProfile()
    self:LevelDebug(2, "CM:CheckProfile()")

    local profile = self.db.char
end

function CM:CastSpell(spell, unit)
	local restore = false
	unit = unit
    
    -- IMPORTANT: If the unit is targettarget or more, then we need to try
    -- to convert it to a friendly unit (to make click-casting work
    -- properly). If this isn't successful, set it up so we restore our 
    -- target
	
	self:LevelDebug(2, "CM:CastSpell("..tostring(spell)..", "..tostring(unit) .. ")")

    if string.find(unit, "target") and string.len(unit) > 6 then
        local friendly = CM:GetFriendlyUnit(unit)

        if friendly then
            unit = friendly
        else
			self:LevelDebug(2, "Setting targettarget flag.")
            targettarget = true
        end
    end
    
    -- Lets resolve the targeting.  If this is a hostile target and its
    -- not currently our target, then we will need to target the unit
    if UnitCanAttack("player", unit) then
        if not UnitIsUnit(unit, "target") then
            self:LevelDebug(2, "Changing to hostile target.")
            TargetUnit(unit)
        end

	-- If we're looking at someone else's target, we have to change targets since
    -- ClearTarget() will get rid of the blahtarget unitID entirely.  We only do
	-- this if this is a friendly target (since they will consume the spell)
	elseif targettarget and not UnitCanAttack("player", "target") then
		self:LevelDebug(2, "Changing target due to friendly target.")
		TargetUnit(unit)
    
    -- If the target is a friendly unit, and its not the unit we're casting on
    elseif UnitExists("target") and not UnitCanAttack("player", "target") and not UnitIsUnit(unit, "target") then
        self:LevelDebug(3, "Clearing the target")
        ClearTarget()
        restore = true
	
    elseif UnitExists("target") and self:IsDualSpell(spell) and not UnitIsUnit(unit, "target") then
        self:LevelDebug(3, "Clearing target for this dual spell")
        ClearTarget()
        restore = true
    end

    --self:Print("CM:CastSpell(%s, %s)", spell, unit)
    --self:Print("Dual Spell: %s, %s", spell, tostring(self:IsDualSpell(spell)))
    
	CastSpellByName(spell)
	
	if SpellIsTargeting() then
        self:LevelDebug(3, "SpellTargetingUnit")
        SpellTargetUnit(unit)
	end
    
    if SpellIsTargeting() then SpellStopTargeting() end
	
	if restore then
        self:LevelDebug(3, "Restoring with TargetLastTarget")
		TargetUnit("playertarget")
	end
end

--[[---------------------------------------------------------------------------------
  This is a small unitID cache on unit names which returns the friendly unitID
  of a specified unit.  This helps to convert raid2targettarget into the more
  friendly (and usable) raid14 allowing us to click-cast without changing 
  targets.
----------------------------------------------------------------------------------]]

local unitCache = {}
local RAID_IDS = {}
local PARTY_IDS = {}
for i=1,MAX_RAID_MEMBERS do RAID_IDS[i] = "raid"..i end
for i=1,MAX_PARTY_MEMBERS do PARTY_IDS[i] = "party"..i end

function CM:GetFriendlyUnit(unit)
    local name = UnitName(unit)
    local cache = unitCache[name]

	--ace:print("Unit: " .. unit .. " Cache: " .. tostring(cache))
	
    if cache then
        if UnitName(cache) == name then
            return cache
        end
    end
    
    local unitID = nil
    local num = GetNumRaidMembers()
    
    local tbl
    if not UnitIsUnit("player", unit) then
        if num > 0 then
            tbl = RAID_IDS
        else
            num = GetNumPartyMembers()
            tbl = PARTY_IDS
        end
        
        for i=1,num do
            local u = tbl[i]
            if UnitIsUnit(u, unit) then
                unitID = u
                break
            end
        end
    else
        unitID = "player"
    end
    
    unitCache[name] = unitID

	--ace:print("UnitID: " .. (tostring(unitID or unit)))

	return unitID
end

function CM:Cast(spell)
	local unit = CM.currentUnit
	if unit ~= nil then 
		CM:CastSpell(spell,unit) 
	elseif UnitName("mouseover") ~= nil then
		CM:CastSpell(spell,"mouseover")
	end
end

local dual_lookup = {
    -- Any spell that can be cast on friendly or hostile units
    [L"DUAL_HOLY_SHOCK"]     = true,
    [L"DUAL_MIND_VISION"]    = true,
    [L"CURE_DISPEL_MAGIC"]   = true,
}

function CM:IsDualSpell(spell)
    return dual_lookup[spell]
end

SLASH_CM1 = "/cmcast"
SlashCmdList["CM"] = function(arg)
	CM:Cast(arg)
end