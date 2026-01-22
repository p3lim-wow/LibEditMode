local MINOR = 13
local lib, minor = LibStub('LibEditMode')
if minor > MINOR then
	return
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

local checkboxMixin = {}
function checkboxMixin:Setup(data)
	self.setting = data
	self.Label:SetText(data.name)
	self:Refresh()

	local value = data.get(lib:GetActiveLayoutName())
	if value == nil then
		value = data.default
	end

	self.checked = value
	self.Button:SetChecked(not not value) -- force boolean
end

function checkboxMixin:Refresh()
	local data = self.setting
	local isEnabled = not data.disabled
	if type(data.disabled) == 'function' then
		isEnabled = not data.disabled(lib:GetActiveLayoutName())
	end

	self:SetEnabled(isEnabled)

	local isShown = not data.hidden
	if type(data.hidden) == 'function' then
		isShown = not data.hidden(lib:GetActiveLayoutName())
	end

	self:SetShown(isShown)
end

function checkboxMixin:OnCheckButtonClick()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	self.checked = not self.checked
	self.setting.set(lib:GetActiveLayoutName(), not not self.checked, false)

	self:GetParent():GetParent():Refresh()
end

function checkboxMixin:SetEnabled(enabled)
	self.Button:SetEnabled(enabled)
	self.Label:SetTextColor((enabled and WHITE_FONT_COLOR or DISABLED_FONT_COLOR):GetRGB())
end

lib.internal:CreatePool(lib.SettingType.Checkbox, function()
	local frame = CreateFrame('Frame', nil, UIParent, 'EditModeSettingCheckboxTemplate')
	frame:SetScript('OnLeave', DefaultTooltipMixin.OnLeave)
	frame:SetScript('OnEnter', showTooltip)
	return Mixin(frame, checkboxMixin)
end, function(_, frame)
	frame:Hide()
	frame.layoutIndex = nil
end)
