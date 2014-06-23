--[[---------------------------------------------------------------------------------
  This is a template for the plugin/module system for Classic Mouseover.

  Plugins are typically used to tie Classic Mouseover to a specific set of unit frames, but 
  can also be used to add functionality to the system through a manner of hooks.
  
  Plugins are registered with Classic Mouseover with a shortname that is used for all slash
  commands.  In addition they are required to have a fullname parameter that is
  used in all display messages
----------------------------------------------------------------------------------]]

-- Create a new plugin for Clique, with the shortname "test"
local Plugin = CM:NewModule("aguf")
Plugin.fullname = "ag Unit Frames"

-- Plugin:Test() is called anytime the mod tries to enable.  It is optional
-- but it will be checked if it exists.  Will typically be based off some global
-- or the state of the addon itself.
function Plugin:Test() return aUF end

-- Plugin:OnEnable() is called if Plugin:Test() is true, and the mod hasn't been explicitly
-- disabled.  This is where you should handle all your hooks, etc.
function Plugin:OnEnable()
	aUF.classes.aUFunit.prototype.OnEnterOld = aUF.classes.aUFunit.prototype.OnEnter
	aUF.classes.aUFunit.prototype.OnLeaveOld = aUF.classes.aUFunit.prototype.OnLeave
	aUF.classes.aUFunit.prototype.OnEnter = self.OnEnter
    aUF.classes.aUFunit.prototype.OnLeave = self.OnLeave
end

-- Plugin:OnDisable() is called if the mod is enabled and its being explicitly disabled.
-- This function is optional.  If it doesn't exist, Plugin:UnregisterAllEvents() and
-- Plugin:UnregisterAllHooks().
function Plugin:OnDisable()
   	aUF.classes.aUFunit.prototype.OnEnter = aUF.classes.aUFunit.prototype.OnEnterOld
	aUF.classes.aUFunit.prototype.OnLeave = aUF.classes.aUFunit.prototype.OnLeaveOld
end

function Plugin:OnEnter()
	self.frame.unit = self.unit
	self:UpdateHighlight(true)
	CM.currentUnit = string.gsub(self.frame:GetName(),"aUF","")
	UnitFrame_OnEnter()
end

function Plugin:OnLeave()
	self:UpdateHighlight()
	CM.currentUnit = nil
	UnitFrame_OnLeave()
end