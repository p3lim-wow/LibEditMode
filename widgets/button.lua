local _, ns = ...
local lib
if ns.LibEditMode then
	lib = ns.LibEditMode
else
	local MINOR, prevMinor = 15
	lib, prevMinor = LibStub('LibEditMode')
	if prevMinor > MINOR then
		return
	end
end

local function showTooltip(self)
	if self.setting and self.setting.desc then
		SettingsTooltip:SetOwner(self, 'ANCHOR_NONE')
		SettingsTooltip:SetPoint('BOTTOMRIGHT', self, 'TOPLEFT')
		SettingsTooltip:SetText(self.setting.name, 1, 1, 1)
		SettingsTooltip:AddLine(self.setting.desc)
		SettingsTooltip:Show()
	end
end

local buttonMixin = {}
function buttonMixin:Setup(data)
	-- unsure if this has any effect
	self.setting = data
end

lib.internal:CreatePool('button', function()
	local button = CreateFrame('Button', nil, UIParent, 'EditModeSystemSettingsDialogExtraButtonTemplate')
	button:SetScript('OnLeave', DefaultTooltipMixin.OnLeave)
	button:SetScript('OnEnter', showTooltip)
	return Mixin(button, buttonMixin)
end, function(_, button)
	button:Hide()
	button.layoutIndex = nil
end)
