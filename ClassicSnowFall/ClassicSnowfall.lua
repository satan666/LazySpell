ClassicSnowfall = AceLibrary("AceAddon-2.0"):new(
    "AceHook-2.0", 
	"AceEvent-2.0"
)
local print = function(msg) if msg then DEFAULT_CHAT_FRAME:AddMessage(msg) end end
local bongos = IsAddOnLoaded("Bongos_ActionBar")

function ClassicSnowfall:OnEnable()
	SLASH_CS1 = "/csselfcast"
    SlashCmdList["CS"] = ClassicSnowfall.ToggleSelfCast;
	self:Hook("ActionButtonDown","ActionButtonDown")
	self:Hook("ActionButtonUp","ActionButtonUp")
	self:Hook("MultiActionButtonDown","MultiActionButtonDown")
	self:Hook("MultiActionButtonUp","MultiActionButtonUp")
end

function ClassicSnowfall:SelfCast()
		if (CS_SELF_ENABLED) then
			return IsAltKeyDown();
		else
			return 0;
		end
end

function ClassicSnowfall:ToggleSelfCast()
	if (CS_SELF_ENABLED) then
		CS_SELF_ENABLED = false
		print("Classic Snowfall ALT SelfCast now disabled.")
	else
		CS_SELF_ENABLED = true
		print("Classic Snowfall ALT SelfCast now enabled.")
	end
end


function ClassicSnowfall:ActionButtonDown(id)
	local button,pagedID;
	print(onSelf);
	if bongos == nil then
		if ( BonusActionBarFrame:IsShown() ) then
			local button = getglobal("BonusActionButton"..id);
			if ( button:GetButtonState() == "NORMAL" ) then
				button:SetButtonState("PUSHED");
				UseAction(ActionButton_GetPagedID(button), 0, self:SelfCast());
			end
			return;
		end

		button = getglobal("ActionButton"..id)
		
		if (button:GetButtonState() == "NORMAL" ) then
			button:SetButtonState("PUSHED");
			UseAction(ActionButton_GetPagedID(button), 0, self:SelfCast());
		end
	else
		button = getglobal("BActionButton"..id)
		pagedID = BActionButton.GetPagedID(id);
		if (button and button:GetButtonState() == "NORMAL" ) then
			button:SetButtonState("PUSHED");
		end
		UseAction(pagedID, 0);
	end
end

function ClassicSnowfall:ActionButtonUp(id, onSelf)
	local button
	if bongos == nil then
		if ( BonusActionBarFrame:IsShown() ) then
			local button = getglobal("BonusActionButton"..id);
			if ( button:GetButtonState() == "PUSHED" ) then
				button:SetButtonState("NORMAL");
				if ( MacroFrame_SaveMacro ) then
					MacroFrame_SaveMacro();
				end
				if ( IsCurrentAction(ActionButton_GetPagedID(button)) ) then
					button:SetChecked(1);
				else
					button:SetChecked(0);
				end
			end
			return;
		end

		button = getglobal("ActionButton"..id)
		if ( button and button:GetButtonState() == "PUSHED" ) then
			button:SetButtonState("NORMAL");
			if ( MacroFrame_SaveMacro ) then
				MacroFrame_SaveMacro();
			end
			if ( IsCurrentAction(ActionButton_GetPagedID(button)) ) then
				button:SetChecked(1);
			else
				button:SetChecked(0);
			end
		end
	else
		button = getglobal("BActionButton"..id)
		if ( button and button:GetButtonState() == "PUSHED" ) then
			button:SetButtonState("NORMAL");
			if ( MacroFrame_SaveMacro ) then
				MacroFrame_SaveMacro();
			end
			button:SetChecked(IsCurrentAction(BActionButton.GetPagedID(id)));
		end
	end
end

function ClassicSnowfall:MultiActionButtonDown(bar, id)
	local button;
	button = getglobal(bar.."Button"..id);

	if ( button:GetButtonState() == "NORMAL" ) then
		button:SetButtonState("PUSHED");
		UseAction(ActionButton_GetPagedID(button), 0, self:SelfCast());
	end
end

function ClassicSnowfall:MultiActionButtonUp(bar, id, onSelf)
	local button = getglobal(bar.."Button"..id);
	if ( button:GetButtonState() == "PUSHED" ) then
		button:SetButtonState("NORMAL");
		if ( MacroFrame_SaveMacro ) then
			MacroFrame_SaveMacro();
		end
		
		if ( IsCurrentAction(ActionButton_GetPagedID(button)) ) then
			button:SetChecked(1);
		else
			button:SetChecked(0);
		end
	end
end