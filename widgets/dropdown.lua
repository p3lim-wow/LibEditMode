local lib = LibStub('LibEditMode')

local LDD = LibStub('LibDropDown', true)
if not LDD then
	error('LibEditMode requires LibDropDown to function')
end

local dropdownMixin = {}
function dropdownMixin:Setup(data)
	self.setting = data
	self.Label:SetText(data.name)

	self.Dropdown:Clear()

	local current = data.get(lib.activeLayoutName)
	for _, info in next, data.values do
		info.checked = info.text == current
		info.func = GenerateClosure(self.OnSettingSelected, self, info.text)
		info.keepShown = false
		self.Dropdown:Add(info)

		if info.checked then
			self.Dropdown:SetText(info.text)
		end
	end
end

function dropdownMixin:OnSettingSelected(value)
	self.setting.set(lib.activeLayoutName, value)

	-- TODO: refresh support in LDD
	self.Dropdown:SetText(value)
end

lib:CreatePool(lib.SettingType.Dropdown, function()
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
end)
