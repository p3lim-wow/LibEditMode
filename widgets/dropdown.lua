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

local function get(data)
	local value = data.get(lib:GetActiveLayoutName())
	if value then
		if data.multiple then
			assert(type(value) == 'table', "multiple choice dropdowns expects a table from 'get'")

			for _, v in next, value do
				if v == data.value then
					return true
				end
			end
		else
			return value == data.value
		end
	end
end

local function set(data)
	data.set(lib:GetActiveLayoutName(), data.value, false)

	data.widget:GetParent():GetParent():RefreshWidgets()
end

local dropdownMixin = {}
function dropdownMixin:Setup(data)
	self.setting = data
	self.Label:SetText(data.name)
	self:Refresh()

	if data.generator then
		-- let the user have full control
		self.Dropdown:SetupMenu(function(owner, rootDescription)
			pcall(data.generator, owner, rootDescription, data)
		end)
	elseif data.values then
		self.Dropdown:SetupMenu(function(_, rootDescription)
			if data.height then
				rootDescription:SetScrollMode(data.height)
			end

			local values = data.values
			if type(values) == 'function' then
				values = values()
			end

			for _, value in next, values do
				if data.multiple then
					rootDescription:CreateCheckbox(value.text, get, set, {
						get = data.get,
						set = data.set,
						value = value.value or value.text,
						multiple = data.multiple,
						widget = self,
					})
				else
					rootDescription:CreateRadio(value.text, get, set, {
						get = data.get,
						set = data.set,
						value = value.value or value.text,
						multiple = data.multiple,
						widget = self,
					})
				end
			end
		end)
	end
end

function dropdownMixin:Refresh()
	local data = self.setting
	if type(data.disabled) == 'function' then
		self:SetEnabled(not data.disabled(lib:GetActiveLayoutName()))
	else
		self:SetEnabled(not data.disabled)
	end

	if type(data.hidden) == 'function' then
		self:SetShown(not data.hidden(lib:GetActiveLayoutName()))
	else
		self:SetShown(not data.hidden)
	end
end

function dropdownMixin:SetEnabled(enabled)
	self.Dropdown:SetEnabled(enabled)
	self.Label:SetTextColor((enabled and WHITE_FONT_COLOR or DISABLED_FONT_COLOR):GetRGB())
end

lib.internal:CreatePool(lib.SettingType.Dropdown, function()
	local frame = CreateFrame('Frame', nil, UIParent, 'ResizeLayoutFrame')
	frame:SetScript('OnLeave', DefaultTooltipMixin.OnLeave)
	frame:SetScript('OnEnter', showTooltip)
	frame.fixedHeight = 32
	Mixin(frame, dropdownMixin)

	local label = frame:CreateFontString(nil, nil, 'GameFontHighlightMedium')
	label:SetPoint('LEFT')
	label:SetWidth(100)
	label:SetJustifyH('LEFT')
	frame.Label = label

	local dropdown = CreateFrame('DropdownButton', nil, frame, 'WowStyle1DropdownTemplate')
	dropdown:SetPoint('LEFT', label, 'RIGHT', 5, 0)
	dropdown:SetSize(200, 30)
	frame.Dropdown = dropdown

	return frame
end, function(_, frame)
	frame:Hide()
	frame.layoutIndex = nil
end)
