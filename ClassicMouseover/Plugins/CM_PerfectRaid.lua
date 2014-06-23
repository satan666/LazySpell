--[[---------------------------------------------------------------------------------
  This is a template for the plugin/module system for CM.

  Plugins are typically used to tie CM to a specific set of unit frames, but
  can also be used to add functionality to the system through a manner of hooks.
 
  Plugins are registered with CM with a shortname that is used for all slash
  commands.  In addition they are required to have a fullname parameter that is
  used in all display messages
----------------------------------------------------------------------------------]]
local print = function(msg) if msg then DEFAULT_CHAT_FRAME:AddMessage(msg) end end
-- Create a new plugin for CM, with the shortname "test"
local Plugin = CM:NewModule("perfectraid")
Plugin.fullname = "PerfectRaid"

-- Plugin:Test() is called anytime the mod tries to enable.  It is optional
-- but it will be checked if it exists.  Will typically be based off some global
-- or the state of the addon itself.
function Plugin:Test()
	return PerfectRaid
end

-- Plugin:OnEnable() is called if Plugin:Test() is true, and the mod hasn't been explicitly
-- disabled.  This is where you should handle all your hooks, etc.
function Plugin:OnEnable()
	PerfectRaid.CreateFrameOld = PerfectRaid.CreateFrame
	PerfectRaid.CreateFrame = self.CreateFrame
	
	PerfectRaid.OnEnter = self.OnEnter
    PerfectRaid.OnLeave = self.OnLeave
end

function Plugin:CreateFrame(num)
	-- We need to allocate up to num frames
		
		if self.poolsize >= num then return end

--[[
		local mem,thr = gcinfo()
		self:Msg("Memory Usage Before: %s [%s].", mem, thr)
--]]
		local side = self.opt.Align
		
		local justify,point,relative,offset
		
		if side == "left" then
			justify = "RIGHT"
			point = "LEFT"
			relative = "RIGHT"
			offset = 5
		elseif side == "right" then
			justify = "LEFT"
			point = "RIGHT"
			relative = "LEFT"
			offset = -5
		end
		
		for i=(self.poolsize + 1),num do
			local frame = CreateFrame("Button", nil, PerfectRaidFrame)
			frame:EnableMouse(true)
			frame.unit = "raid"..i
			frame.id = i
			frame:SetWidth(225)
			frame:SetHeight(13)
			frame:SetMovable(true)
			frame:RegisterForDrag("LeftButton")
			frame:SetScript("OnDragStart", function() self["master"]:StartMoving() end)
			frame:SetScript("OnDragStop", function() self["master"]:StopMovingOrSizing() self:SavePosition() end)
			frame:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp", "Button4Up", "Button5Up")
			frame:RegisterEvent("Enter")
			frame:RegisterEvent("Leave")

			frame:SetScript("OnClick", self.OnClick)
		    frame:SetScript("OnEnter",self.OnEnter)
			frame:SetScript("OnLeave",self.OnLeave)
			frame:SetParent(self.master)

			local font = frame:CreateFontString(nil, "ARTWORK")
			font:SetFontObject(GameFontHighlightSmall)
			font:SetText("WW")
			font:SetJustifyH("CENTER")
			font:SetWidth(font:GetStringWidth())
			font:SetHeight(14)
			font:Show()
			font:ClearAllPoints()
			font:SetPoint(point, frame, relative,0, 0)
			-- Add this font string to the frame
			frame.Prefix = font
			
			font = frame:CreateFontString(nil, "ARTWORK")
			font:SetFontObject(GameFontHighlightSmall)
			font:SetText()
			font:SetJustifyH(justify)
			font:SetWidth(55)
			font:SetHeight(12)
			font:Show()
			font:ClearAllPoints()
			font:SetPoint(point, frame.Prefix, relative, offset, 0)
			-- Add this font string to the frame
			frame.Name = font
			
			local bar = CreateFrame("StatusBar", nil, frame)
			bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
			bar:SetMinMaxValues(0,100)
			bar:ClearAllPoints()
			bar:SetPoint(point, frame.Name, relative, offset, 0)
			bar:SetWidth(60)
			bar:SetHeight(7)
			bar:Show()
			-- Add this status bar to the frame
			frame.Bar = bar
			
			font = frame:CreateFontString(nil, "ARTWORK")
			font:SetFontObject(GameFontHighlightSmall)
			font:SetText("")
			font:SetJustifyH(justify)
			font:SetWidth(font:GetStringWidth())
			font:SetHeight(12)
			font:Show()
			font:ClearAllPoints()
			font:SetPoint(point, frame.Bar, relative, offset, 0)
			-- Add this font string to the frame
			frame.Status = font
			
			-- Lets set the frame in the indexed array
			self.frames[i] = frame
			self.frames["raid"..i] = frame
			self.poolsize = i
		end
end

function Plugin:OnEnter()
	CM.currentUnit = this.unit
end

function Plugin:OnLeave()
	CM.currentUnit = nil
end