local MINOR = 10
local lib, minor = LibStub('LibEditMode')
if minor > MINOR then
	return
end

local internal = lib.internal

local extensionMixin = {}
function extensionMixin:Update(systemID)
	self.systemID = systemID

	internal.ReleaseAllPools()

	local numSettings = self:UpdateSettings()
	if numSettings == 0 then
		self.Buttons:ClearAllPoints()
		self.Buttons:SetPoint('TOP', 0, -20)
	else
		self.Buttons:ClearAllPoints()
		self.Buttons:SetPoint('TOP', self.Settings, 'BOTTOM', 0, -2)
	end

	self:UpdateButtons()

	-- reset position
	if not self:IsShown() then
		self:ClearAllPoints()
		self:SetPoint('TOPLEFT', EditModeSystemSettingsDialog, 'BOTTOMLEFT')
		self:SetPoint('TOPRIGHT', EditModeSystemSettingsDialog, 'BOTTOMRIGHT')
	end

	-- show and update layout
	self:Show()
	self:Layout()
end

function extensionMixin:UpdateSettings()
	local settings, num = internal:GetSystemSettings(self.systemID)
	local isEmpty = num == 0
	if not isEmpty then
		for index, data in next, settings do
			local pool = internal:GetPool(data.kind)
			if pool then
				local setting = pool:Acquire(self.Settings)
				setting.layoutIndex = index
				setting:Setup(data)
				setting:Show()
			end
		end
	end

	self.Settings.ignoreInLayout = isEmpty
	self.Settings.ResetButton.layoutIndex = num + 1
	self.Settings.ResetButton.ignoreInLayout = isEmpty
	self.Settings.ResetButton:SetEnabled(not isEmpty)
	self.Settings.Divider.layoutIndex = num + 2
	self.Settings.Divider.ignoreInLayout = isEmpty

	return num
end

function extensionMixin:UpdateButtons()
	local buttons, num = internal:GetSystemSettingsButtons(self.systemID)
	local isEmpty = num == 0
	if not isEmpty then
		for index, data in next, buttons do
			local button = internal:GetPool('button'):Acquire(self.Buttons)
			button.layoutIndex = index
			button:SetText(data.text)
			button:SetOnClickHandler(data.click)
			button:Show()
			button:SetEnabled(true) -- reset from pool
		end
	end

	self.Buttons.ignoreInLayout = isEmpty
	self.Settings.Divider.ignoreInLayout = isEmpty
end

function extensionMixin:ResetSettings()
	local settings, num = internal:GetSystemSettings(self.systemID)
	if num > 0 then
		for _, data in next, settings do
			if data.set then
				data.set(lib.activeLayoutName, data.default)
			end
		end

		self:Update(self.systemID)
	end
end

function internal:CreateExtension()
	local extension = Mixin(CreateFrame('Frame', nil, UIParent, 'ResizeLayoutFrame'), extensionMixin)
	extension:SetSize(64, 64)
	extension:SetFrameStrata('DIALOG')
	extension:SetClampedToScreen(true)
	extension:SetFrameLevel(200)
	extension:Hide()
	extension.widthPadding = 40
	extension.heightPadding = 40

	local extensionBorder = CreateFrame('Frame', nil, extension, 'DialogBorderTranslucentTemplate')
	extensionBorder.ignoreInLayout = true
	extension.Border = extensionBorder

	local extensionSettings = CreateFrame('Frame', nil, extension, 'VerticalLayoutFrame')
	extensionSettings:SetPoint('TOP', 0, -15)
	extensionSettings.spacing = 2
	extension.Settings = extensionSettings

	local resetSettingsButton = CreateFrame('Button', nil, extensionSettings, 'EditModeSystemSettingsDialogButtonTemplate')
	resetSettingsButton:SetText(RESET_TO_DEFAULT)
	resetSettingsButton:SetOnClickHandler(GenerateClosure(extension.ResetSettings, extension))
	extensionSettings.ResetButton = resetSettingsButton

	local divider = extensionSettings:CreateTexture(nil, 'ARTWORK')
	divider:SetSize(330, 16)
	divider:SetTexture([[Interface\FriendsFrame\UI-FriendsFrame-OnlineDivider]])
	extensionSettings.Divider = divider

	local extensionButtons = CreateFrame('Frame', nil, extension, 'VerticalLayoutFrame')
	extensionButtons.spacing = 2
	extension.Buttons = extensionButtons

	return extension
end
