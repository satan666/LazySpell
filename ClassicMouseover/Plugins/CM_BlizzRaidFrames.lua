--[[---------------------------------------------------------------------------------
  This is a template for the plugin/module system for CM.

  Plugins are typically used to tie CM to a specific set of unit frames, but 
  can also be used to add functionality to the system through a manner of hooks.
  
  Plugins are registered with CM with a shortname that is used for all slash
  commands.  In addition they are required to have a fullname parameter that is
  used in all display messages
----------------------------------------------------------------------------------]]

-- Create a new plugin for CM, with the shortname "test"
local Plugin = CM:NewModule("blizzraid")
Plugin.fullname = "Blizzard Raid Frames"

-- Plugin:Test() is called anytime the mod tries to enable.  It is optional
-- but it will be checked if it exists.  Will typically be based off some global
-- or the state of the addon itself.
function Plugin:Test()
	return RaidPullout_Update and not IsAddOnLoaded("EasyRaid")
end

function Plugin:OnEnable()
    self:Hook("RaidPullout_Update", "SetClicks")
end

function Plugin:SetClicks(frame)
    self.hooks.RaidPullout_Update.orig(frame)

    if not frame then frame = this end
    for i=1,NUM_RAID_PULLOUT_FRAMES	do
        for j=1, frame.numPulloutButtons do
            local button = getglobal(frame:GetName().."Button"..j.."ClearButton");
			button:SetScript("OnEnter",function() self:OnEnter() end)
			button:SetScript("OnLeave",function() self:OnLeave() end)
        end
    end
end

function Plugin:OnClick()
    local button = arg1
    local unit = this.unit
    if not Clique:OnClick(button, unit) then
        self.hooks.RaidPulloutButton_OnClick.orig(this)
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