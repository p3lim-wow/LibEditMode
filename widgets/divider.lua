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

lib.SettingType.Divider = 'divider'

local dividerMixin = {}
function dividerMixin:Setup(data)
	self.setting = data
	self.Label:SetText(data.hideLabel and '' or data.name)
	self:Refresh()
end

function dividerMixin:Refresh()
	local data = self.setting
	if type(data.hidden) == 'function' then
		self:SetShown(not data.hidden(lib:GetActiveLayoutName()))
	else
		self:SetShown(not data.hidden)
	end
end

lib.internal:CreatePool(lib.SettingType.Divider, function()
	local frame = Mixin(CreateFrame('Frame', nil, UIParent), dividerMixin)
	frame:SetSize(330, 16)
	frame.align = 'center'

	local texture = frame:CreateTexture(nil, 'ARTWORK')
	texture:SetAllPoints()
	texture:SetTexture([[Interface\FriendsFrame\UI-FriendsFrame-OnlineDivider]])

	local label = frame:CreateFontString(nil, nil, 'GameFontHighlightMedium')
	label:SetAllPoints()
	frame.Label = label

	return frame
end, function(_, frame)
	frame:Hide()
	frame.Label:SetText()
	frame.layoutIndex = nil
end)
