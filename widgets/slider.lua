local MINOR = 10
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

local sliderMixin = {}
function sliderMixin:Setup(data)
	self.setting = data
	self.Label:SetText(data.name)

	self.initInProgress = true
	self.formatters = {}
	self.formatters[MinimalSliderWithSteppersMixin.Label.Right] = CreateMinimalSliderFormatter(MinimalSliderWithSteppersMixin.Label.Right, data.formatter)

	local stepSize = data.valueStep or 1
	local steps = (data.maxValue - data.minValue) / stepSize
	self.Slider:Init(data.get(lib:GetActiveLayoutName()) or data.default, data.minValue or 0, data.maxValue or 1, steps, self.formatters)
	self.initInProgress = false
end

function sliderMixin:OnSliderValueChanged(value)
	if not self.initInProgress then
		self.setting.set(lib:GetActiveLayoutName(), value)
	end
end

lib.internal:CreatePool(lib.SettingType.Slider, function()
	local frame = CreateFrame('Frame', nil, UIParent, 'EditModeSettingSliderTemplate')
	frame:SetScript('OnLeave', DefaultTooltipMixin.OnLeave)
	frame:SetScript('OnEnter', showTooltip)
	Mixin(frame, sliderMixin)

	frame:SetHeight(32)
	frame.Slider:SetWidth(200)
	frame.Slider.MinText:Hide()
	frame.Slider.MaxText:Hide()
	frame.Label:SetPoint('LEFT')

	frame:OnLoad()
	return frame
end, function(_, frame)
	frame:Hide()
	frame.layoutIndex = nil
end)
