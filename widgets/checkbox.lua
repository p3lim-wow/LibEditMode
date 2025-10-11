local MINOR = 10
local lib, minor = LibStub('LibEditMode')
if minor > MINOR then
	return
end

local checkboxMixin = {}
function checkboxMixin:Setup(data)
	self.setting = data
	self.Label:SetText(data.name)

	local value = data.get(lib.activeLayoutName)
	if value == nil then
		value = data.default
	end

	self.checked = value
	self.Button:SetChecked(not not value) -- force boolean
end

function checkboxMixin:OnCheckButtonClick()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	self.checked = not self.checked
	self.setting.set(lib.activeLayoutName, not not self.checked) -- force boolean
end

lib.internal:CreatePool(lib.SettingType.Checkbox, function()
	local frame = CreateFrame('Frame', nil, UIParent, 'EditModeSettingCheckboxTemplate')
	return Mixin(frame, checkboxMixin)
end, function(_, frame)
	frame:Hide()
	frame.layoutIndex = nil
end)
