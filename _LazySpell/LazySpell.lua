local HealComm = AceLibrary("HealComm-1.0")
local L = AceLibrary("Babble-Spell-2.2")
LazySpell = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0")
LazySpell.debugging = nil

LazySpell.BOL = {
["enUS"] = "Receives up to (%d+) extra healing from Holy Light spells%, and up to (%d+) extra healing from Flash of Light spells%.",
["deDE"] = "Erhält bis zu (%d+) extra Heilung durch %'Heiliges Licht%' und bis zu (%d+) extra Heilung durch den Zauber %'Lichtblitz%'%.",
["frFR"] = "Les sorts de Lumiere sacrée rendent jusqu%'a (%d+) points de vie supplémentaires%, les sorts d%'Eclair lumineux jusqu%'a (%d+)%."
}

function LazySpell:Debug(msg)
	if self.debugging then
		DEFAULT_CHAT_FRAME:AddMessage("|cff00eeee LazySpell Debug: |cffffffff"..msg);
	end
end

function LazySpell:DebugToggle()
	self.debugging = not self.debugging
	LazySpell:Debug("Debugging enabled")
end

LazySpell:RegisterChatCommand({"/ls"}, {
	type = "group",
	name = "LazySpell",
	args = {
			debug = {
				type	= "execute",
				name	= "debug",
				desc	=  "debug",
				func	= "DebugToggle",
			},
		}
	}
)

function LazySpell:OnEnable()
	DEFAULT_CHAT_FRAME:AddMessage("_Lazy Spell by ".."|cffFF0066".."Ogrisch".."|cffffffff".. " loaded")
	if Clique then
		Clique.CastSpell_OLD = Clique.CastSpell
		Clique.CastSpell = self.Clique_CastSpell
	end
	
	if CM then
		CM.CastSpell_OLD = CM.CastSpell
		CM.CastSpell = self.CM_CastSpell
	end
end

function LazySpell:ExtractSpell(spell)
	local s = spell
	local _, i, r
	_, _, s = string.find(s, "^(.*);?%s*$")
	while ( string.sub( s, -2 ) == "()" ) do
		s = string.sub( s, 1, -3 )
	end
	_, _, s = string.find(s, "^%s*(.*)$")
	_, _, i, r = string.find(s, "(.*)%(.*(%d)%)$")
	if (i and r) then
		s = i
		r = tonumber(r)
		return s, r
	end
end

function LazySpell:GetBuffSpellPower()
	local Spellpower = 0
	local healmod = 1
	for i=1, 16 do
		local buffTexture, buffApplications = UnitBuff("player", i)
		if not buffTexture then
			return Spellpower, healmod
		end
		healcommTip:SetUnitBuff("player", i)
		local buffName = healcommTipTextLeft1:GetText()
		if HealComm.Buffs[buffName] and HealComm.Buffs[buffName].icon == buffTexture then
			Spellpower = (HealComm.Buffs[buffName].amount * buffApplications) + Spellpower
			healmod = (HealComm.Buffs[buffName].mod * buffApplications) + healmod
		end
	end
	return Spellpower, healmod
end

function LazySpell:GetUnitSpellPower(spell, unit)
	local targetpower = 0
	local targetmod = 1
	local buffTexture, buffApplications
	local debuffTexture, debuffApplications
	for i=1, 16 do
		if UnitExists(unit) and UnitIsVisible(unit) and UnitIsConnected(unit) and UnitReaction(unit, "player") > 4 then
			buffTexture, buffApplications = UnitBuff(unit, i)
			healcommTip:SetUnitBuff(unit, i)
		else
			buffTexture, buffApplications = UnitBuff("player", i)
			healcommTip:SetUnitBuff("player", i)
		end
		if not buffTexture then
			break
		end
		local buffName = healcommTipTextLeft1:GetText()
		if (buffTexture == "Interface\\Icons\\Spell_Holy_PrayerOfHealing02" or buffTexture == "Interface\\Icons\\Spell_Holy_GreaterBlessingofLight") then
			local _,_, HLBonus, FoLBonus = string.find(healcommTipTextLeft2:GetText(),LazySpell.BOL[GetLocale()])
			if (spell == L["Flash of Light"]) then
				targetpower = FoLBonus + targetpower
			elseif spell == L["Holy Light"] then
				targetpower = HLBonus + targetpower
			end
		end
		if buffName == L["Healing Way"] and spell == L["Healing Wave"] then
			targetmod = targetmod * ((buffApplications * 0.06) + 1)
		end
	end
	for i=1, 16 do
		if UnitIsVisible(unit) and UnitIsConnected(unit) and UnitReaction(unit, "player") > 4 then
			debuffTexture, debuffApplications = UnitDebuff(unit, i)
			healcommTip:SetUnitDebuff(unit, i)
		else
			debuffTexture, debuffApplications = UnitDebuff("player", i)
			healcommTip:SetUnitDebuff("player", i)
		end
		if not debuffTexture then
			break
		end
		local debuffName = healcommTipTextLeft1:GetText()
		if HealComm.Debuffs[debuffName] then
			targetpower = (HealComm.Debuffs[debuffName].amount * debuffApplications) + targetpower
			targetmod = (1-(HealComm.Debuffs[debuffName].mod * debuffApplications)) * targetmod
		end
	end
	return targetpower, targetmod
end	

function LazySpell:GetMaxSpellRank(spellName)
    local i = 1;
    local List = {};
    local spellNamei, spellRank;

    while true do
        spellNamei, spellRank = GetSpellName(i, BOOKTYPE_SPELL);
        if not spellNamei then return table.getn(List) end

        if spellNamei == spellName then
            _,_,spellRank = string.find(spellRank, " (%d+)$");
            spellRank = tonumber(spellRank);
            if not spellRank then return i end
            List[spellRank] = i;
        end
        i = i + 1;
    end
end


function LazySpell:CalculateRank(spell, unit)
	local Bonus = 0
	local max_rank = self:GetMaxSpellRank(spell)
	if BonusScanner then
		Bonus = tonumber(BonusScanner:GetBonus("HEAL"))
	end		

	local targetpower, targetmod = self:GetUnitSpellPower(spell, unit)
	local buffpower, buffmod = self:GetBuffSpellPower()
	local Bonus = Bonus + buffpower	
	local healneed = UnitHealthMax(unit) - UnitHealth(unit);
	
	local result = 1
	local heal = 0
	for i = max_rank,1,-1 do
		local amount = ((math.floor(HealComm.Spells[spell][i](Bonus))+targetpower)*buffmod*targetmod)
		if amount < healneed then
			if i < max_rank then
				result = i + 1
				heal = ((math.floor(HealComm.Spells[spell][i+1](Bonus))+targetpower)*buffmod*targetmod)
				break
			else
				result = i
				heal = amount
				break
			end
		else
			heal = amount
		end	
	end	
	self:Debug(spell.."(Rank "..result..") - "..GetUnitName(unit).." - Heal: "..heal.." - Needed: "..healneed)
	return result
end

function LazySpell:Clique_CastSpell(spell, unit)
	local s,r = LazySpell:ExtractSpell(spell)
	unit = unit or Clique.unit
	
	if s and HealComm.Spells[s] and r == 1 then
		local rank = LazySpell:CalculateRank(s, unit)
		spell = s.."(Rank "..rank..")"
		
	end	
	Clique:CastSpell_OLD(spell, unit)
end

function LazySpell:CM_CastSpell(spell, unit)
	local s,r = LazySpell:ExtractSpell(spell)
	
	if s and HealComm.Spells[s] and r == 1 then
		local rank = LazySpell:CalculateRank(s, unit)
		spell = s.."(Rank "..rank..")"
	end	
	CM:CastSpell_OLD(spell, unit)
end


