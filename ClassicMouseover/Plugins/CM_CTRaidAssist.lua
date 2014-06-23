--[[---------------------------------------------------------------------------------
  This is a template for the plugin/module system for CM.

  Plugins are typically used to tie CM to a specific set of unit frames, but 
  can also be used to add functionality to the system through a manner of hooks.
  
  Plugins are registered with CM with a shortname that is used for all slash
  commands.  In addition they are required to have a fullname parameter that is
  used in all display messages
----------------------------------------------------------------------------------]]

-- Create a new plugin for CM, with the shortname "test"
local Plugin = CM:NewModule("ctra")
Plugin.fullname = "CT_RaidAssist"
Plugin.url = "http://ctmod.net"

-- Plugin:Test() is called anytime the mod tries to enable.  It is optional
-- but it will be checked if it exists.  Will typically be based off some global
-- or the state of the addon itself.
function Plugin:Test()
    return CT_RA_Cache
end

-- Plugin:OnEnable() is called if Plugin:Test() is true, and the mod hasn't been explicitly
-- disabled.  This is where you should handle all your hooks, etc.
function Plugin:OnEnable()
	CT_RA_MemberFrame_OnEnter_Old = CT_RA_MemberFrame_OnEnter
    CT_RA_MemberFrame_OnEnter = self.OnEnter
	CT_RA_Emergency_OnEnter_Old = CT_RA_Emergency_OnEnter
	CT_RA_Emergency_OnEnter = self.EmergencyOnEnter
	GameTooltip.HideCTOld = GameTooltip.Hide
	GameTooltip.Hide = self.Hide
end

function Plugin:Hide()
	CM.currentUnit = nil
	return GameTooltip:HideCTOld()
end

function Plugin:EmergencyOnEnter()
	CM.currentUnit = this.unitid
	return CT_RA_Emergency_OnEnter_Old()	
end

function Plugin:OnEnter()
	local tempOptions = CT_RAMenu_Options["temp"];
	if ( SpellIsTargeting() ) then
		SetCursor("CAST_CURSOR");
	end
	local parent = this.frameParent;
	local id = parent.id;
	if ( strsub(parent.name, 1, 12) == "CT_RAMTGroup" ) then
		local name;
		if ( CT_RA_MainTanks[id] ) then
			name = CT_RA_MainTanks[id];
		end
		for i = 1, GetNumRaidMembers(), 1 do
			local memberName = GetRaidRosterInfo(i);
			if ( name == memberName ) then
				id = i;
				break;
			end
		end
	elseif ( strsub(parent.name, 1, 12) == "CT_RAPTGroup" ) then
		local name;
		if ( CT_RA_PTargets[id] ) then
			name = CT_RA_PTargets[id];
		end
		for i = 1, GetNumRaidMembers(), 1 do
			local memberName = GetRaidRosterInfo(i);
			if ( name == memberName ) then
				id = i;
				break;
			end
		end
	end
	local unitid = "raid"..id;
	CM.currentUnit = unitid
	if ( SpellIsTargeting() and not SpellCanTargetUnit(unitid) ) then
		SetCursor("CAST_ERROR_CURSOR");
	end
	if ( tempOptions["HideTooltip"] ) then
		return;
	end
	local xp = "LEFT";
	local yp = "BOTTOM";
	local xthis, ythis = this:GetCenter();
	local xui, yui = UIParent:GetCenter();
	if ( xthis < xui ) then
		xp = "RIGHT";
	end
	if ( ythis < yui ) then
		yp = "TOP";
	end
	GameTooltip:SetOwner(this, "ANCHOR_" .. yp .. xp);
	local name, rank, subgroup, level, class, fileName, zone, online, isDead = GetRaidRosterInfo(id);
	local stats = CT_RA_Stats[name];
	local isVirtual;
	if ( not name and tempOptions["SORTTYPE"] == "virtual" ) then
		isVirtual = 1;
		name, level = "Virtual " .. id, 60;
	end
	local version = stats;
	if ( version ) then
		version = version["Version"];
	end
	if ( name == UnitName("player") ) then
		zone = GetRealZoneText();
		version = CT_RA_VersionNumber;
	end
	local color = RAID_CLASS_COLORS[fileName];
	if ( not color ) then
		color = { ["r"] = 1, ["g"] = 1, ["b"] = 1 };
	end
	GameTooltip:AddDoubleLine(name, level, color.r, color.g, color.b, 1, 1, 1);
	if ( UnitRace(unitid) and class ) then
		GameTooltip:AddLine(UnitRace(unitid) .. " " .. class, 1, 1, 1);
	end
	GameTooltip:AddLine(zone, 1, 1, 1);
	
	if ( not version and not isVirtual ) then
		if ( not stats or not stats["Reporting"] ) then
			GameTooltip:AddLine("No CTRA Found", 0.7, 0.7, 0.7);
		else
			GameTooltip:AddLine("CTRA <1.077", 1, 1, 1);
		end
	elseif ( not isVirtual ) then
		GameTooltip:AddLine("CTRA " .. version, 1, 1, 1);
	end

	if ( stats and stats["AFK"] ) then
		if ( type(stats["AFK"][1]) == "string" ) then
			GameTooltip:AddLine("AFK: " .. stats["AFK"][1]);
		end
		GameTooltip:AddLine("AFK for " .. CT_RA_FormatTime(stats["AFK"][2]));
	elseif ( CT_RA_Stats[name] and stats["DND"] ) then
		if ( type(stats["DND"][1]) == "string" ) then
			GameTooltip:AddLine("DND: " .. stats["DND"][1]);
		end
		GameTooltip:AddLine("DND for " .. CT_RA_FormatTime(stats["DND"][2]));
	end
	if ( stats and stats["Offline"] ) then
		GameTooltip:AddLine("Offline for " .. CT_RA_FormatTime(stats["Offline"]));
	elseif ( stats and stats["FD"] ) then
		if ( stats["FD"] < 360 ) then
			GameTooltip:AddLine("Dying in " .. CT_RA_FormatTime(360-stats["FD"]));
		end
	elseif ( stats and stats["Dead"] ) then
		if ( stats["Dead"] < 360 and not UnitIsGhost(unitid) ) then
			GameTooltip:AddLine("Releasing in " .. CT_RA_FormatTime(360-stats["Dead"]));
		else
			GameTooltip:AddLine("Dead for " .. CT_RA_FormatTime(stats["Dead"]));
		end
	end
	if ( stats and stats["Rebirth"] and stats["Rebirth"] > 0 ) then
		GameTooltip:AddLine("Rebirth up in: " .. CT_RA_FormatTime(stats["Rebirth"]));
	elseif ( stats and stats["Reincarnation"] and stats["Reincarnation"] > 0 ) then
		GameTooltip:AddLine("Ankh up in: " .. CT_RA_FormatTime(stats["Reincarnation"]));
	elseif ( stats and stats["Soulstone"] and stats["Soulstone"] > 0 ) then
		GameTooltip:AddLine("Soulstone up in: " .. CT_RA_FormatTime(stats["Soulstone"]));
	end
	GameTooltip:Show();
	CT_RA_CurrentMemberFrame = this;
end