--[[---------------------------------------------------------------------------------
  This is a template for the plugin/module system for CM.

  Plugins are typically used to tie CM to a specific set of unit frames, but 
  can also be used to add functionality to the system through a manner of hooks.
  
  Plugins are registered with CM with a shortname that is used for all slash
  commands.  In addition they are required to have a fullname parameter that is
  used in all display messages
----------------------------------------------------------------------------------]]

-- Create a new plugin for CM, with the shortname "test"
local Plugin = CM:NewModule("duf")
Plugin.fullname = "Discord Unit Frames"
Plugin.url = "http://www.wowinterface.com/downloads/info4177-Discord_Unit_Frames.html"

-- Plugin:Test() is called anytime the mod tries to enable.  It is optional
-- but it will be checked if it exists.  Will typically be based off some global
-- or the state of the addon itself.
function Plugin:Test()
    return DUF_UnitFrame_OnEnter
end

-- Plugin:OnEnable() is called if Plugin:Test() is true, and the mod hasn't been explicitly
-- disabled.  This is where you should handle all your hooks, etc.
function Plugin:OnEnable()
    self:Hook("DUF_UnitFrame_OnEnter", "DUFUnitFrameOnEnter")
    self:Hook("DUF_UnitFrame_OnLeave", "DUFUnitFrameOnLeave")
	self:Hook("DUF_Element_OnEnter", "DUFElementOnEnter")
    self:Hook("DUF_Element_OnLeave", "DUFElementOnLeave")
end

function Plugin:DUFUnitFrameOnEnter()
	CM.currentUnit = this.unit
	return self.hooks.DUF_UnitFrame_OnEnter.orig()
end

function Plugin:DUFUnitFrameOnLeave()
	CM.currentUnit = nil
	return self.hooks.DUF_UnitFrame_OnLeave.orig()
end

function Plugin:DUFElementOnEnter()
	CM.currentUnit = this:GetParent().unit
	return self.hooks.DUF_Element_OnEnter.orig()
end

function Plugin:DUFElementOnLeave()
	CM.currentUnit = nil
	return self.hooks.DUF_Element_OnLeave.orig()
end

