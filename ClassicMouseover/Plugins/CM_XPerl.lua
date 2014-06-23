--[[---------------------------------------------------------------------------------
  This is a template for the plugin/module system for Clique.

  Plugins are typically used to tie Clique to a specific set of unit frames, but 
  can also be used to add functionality to the system through a manner of hooks.
  
  Plugins are registered with Clique with a shortname that is used for all slash
  commands.  In addition they are required to have a fullname parameter that is
  used in all display messages
----------------------------------------------------------------------------------]]

-- Create a new plugin for Clique, with the shortname "test"
local Plugin = CM:NewModule("xperl")
Plugin.fullname = "X-Perl"
Plugin.url = "http://www.wowinterface.com/downloads/fileinfo.php?id=5248"

-- Plugin:Test() is called anytime the mod tries to enable.  It is optional
-- but it will be checked if it exists.  Will typically be based off some global
-- or the state of the addon itself.
function Plugin:Test()
    if not IsAddOnLoaded("XPerl") then 
		return false 
	end
    
	return true
end

-- Plugin:OnEnable() is called if Plugin:Test() is true, and the mod hasn't been explicitly
-- disabled.  This is where you should handle all your hooks, etc.
function Plugin:OnEnable()
	self:Hook("XPerl_PlayerTip", "CM_XPerl_PlayerTip")
    self:Hook("XPerl_PlayerTipHide", "CM_XPerl_PlayerTipHide") 
end

function Plugin:CM_XPerl_PlayerTip(unitid)
	local unit = unitid
	CM.currentUnit = unitid
	return self.hooks.XPerl_PlayerTip.orig(unit)
end

function Plugin:CM_XPerl_PlayerTipHide()
	CM.currentUnit = nil
	return self.hooks.XPerl_PlayerTipHide.orig()
end






