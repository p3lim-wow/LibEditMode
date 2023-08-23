local MINOR = 7
local lib, minor = LibStub('LibEditMode')
if minor > MINOR then
	return
end

local LDD, lddMinor = LibStub('LibDropDown', true)
if not LDD then
	error('LibEditMode requires LibDropDown to function')
end

local function isChecked(a, getB, default)
	return a == (getB(lib.activeLayoutName) or default)
end

local dropdownMixin = {}
function dropdownMixin:Setup(data)
	self.setting = data
	self.Label:SetText(data.name)

	self.Dropdown:Clear()

	for _, info in next, data.values do
		info.checked = GenerateClosure(isChecked, info.text, data.get, data.default)
		info.func = GenerateClosure(self.OnSettingSelected, self, info.text)
		info.keepShown = false
		self.Dropdown:Add(info)

		if info.checked() then
			self.Dropdown:SetText(info.text)
		end
	end
end

function dropdownMixin:OnSettingSelected(value)
	self.setting.set(lib.activeLayoutName, value)

	if lddMinor >= 7 and lddMinor < 9 then
		self.Dropdown:Refresh()
	end
	self.Dropdown:SetText(value)
end

lib.internal:CreatePool(lib.SettingType.Dropdown, function()
	local frame = CreateFrame('Frame', nil, UIParent, 'ResizeLayoutFrame')
	frame.fixedHeight = 32
	Mixin(frame, dropdownMixin)

	local label = frame:CreateFontString(nil, nil, 'GameFontHighlightMedium')
	label:SetPoint('LEFT')
	label:SetWidth(100)
	label:SetJustifyH('LEFT')
	frame.Label = label

	local dropdown = LDD:NewButton(frame)
	dropdown:SetPoint('LEFT', label, 'RIGHT', 5, 0)
	dropdown:SetSize(200, 30)
	dropdown:SetJustifyH('LEFT')
	dropdown:SetCheckAlignment('LEFT')
	frame.Dropdown = dropdown

	return frame
end, function(_, frame)
	frame:Hide()
	frame.layoutIndex = nil
end)
