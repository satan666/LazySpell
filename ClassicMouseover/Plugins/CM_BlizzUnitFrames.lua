--[[---------------------------------------------------------------------------------
  This is a template for the plugin/module system for CM.

  Plugins are typically used to tie CM to a specific set of unit frames, but 
  can also be used to add functionality to the system through a manner of hooks.
  
  Plugins are registered with CM with a shortname that is used for all slash
  commands.  In addition they are required to have a fullname parameter that is
  used in all display messages
----------------------------------------------------------------------------------]]

-- Create a new plugin for CM, with the shortname "test"
local Plugin = CM:NewModule("blizzuf")
Plugin.fullname = "Blizzard Unit Frames"

local frames = {
	["PlayerFrame"]              = "player",
	["PetFrame"]                  = "pet",
	["TargetFrame"]             = "target",
	["TargetofTargetFrame"]     = "targettarget",
	["PartyMemberFrame1"]         = "party1",
	["PartyMemberFrame2"]         = "party2",
	["PartyMemberFrame3"]         = "party3",
	["PartyMemberFrame4"]         = "party4",
	["PartyMemberFrame1PetFrame"] = "party1",
	["PartyMemberFrame2PetFrame"] = "party2",
	["PartyMemberFrame3PetFrame"] = "party3",
	["PartyMemberFrame4PetFrame"] = "party4",
}

-- Plugin:OnEnable() is called if Plugin:Test() is true, and the mod hasn't been explicitly
-- disabled.  This is where you should handle all your hooks, etc.
function Plugin:OnEnable()
    for frame,unit in pairs(frames) do
        local button = getglobal(frame)
        	
		self:HookScript(button, "OnEnter")
		self:HookScript(button, "OnLeave")
    end
end

function Plugin:OnEnter()
	CM.currentUnit = this.unit
	UnitFrame_OnEnter()
end

function Plugin:OnLeave()
	CM.currentUnit = nil
	UnitFrame_OnLeave()
end