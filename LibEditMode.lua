local MAJOR = 'LibEditMode'
local MINOR = 1

local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then
	return
end

local layoutNames = setmetatable({'Modern', 'Classic'}, {
	__index = function(t, key)
		if key > 2 then
			-- the first 2 indices are reserved for 'Modern' and 'Classic' layouts, and anything
			-- else are custom ones, although GetLayouts() doesn't return data for the 'Modern'
			-- and 'Classic' layouts, so we'll have to substract and check
			local layouts = C_EditMode.GetLayouts().layouts
			if (key - 2) > #layouts then
				error('index is out of bounds')
			else
				return layouts[key - 2].layoutName
			end
		else
			-- also work for 'Modern' and 'Classic'
			rawget(t, key)
		end
	end
})

local frameSelections = {}
local frameCallbacks = {}
local frameDefaults = {}
local frameSettings = {}
local frameButtons = {}

local anonCallbacksEnter = {}
local anonCallbacksExit = {}
local anonCallbacksLayout = {}

local function resetSelection(hide)
	lib.dialog:Hide()

	for frame, selection in next, frameSelections do
		if selection.isSelected then
			frame:SetMovable(false)
		end

		if hide then
			selection:Hide()
			selection.isSelected = false
		else
			selection:ShowHighlighted()
		end
	end
end

local function onDragStart(self)
	self.parent:StartMoving()
end

local function normalizePosition(frame)
	-- ripped out of LibWindow-1.1, which is Public Domain
	local parent = frame:GetParent()
	if not parent then
		return
	end

	local scale = frame:GetScale()
	if not scale then
		return
	end

	local left = frame:GetLeft() * scale
	local top = frame:GetTop() * scale
	local right = frame:GetRight() * scale
	local bottom = frame:GetBottom() * scale

	local parentWidth, parentHeight = parent:GetSize()

	local x, y, point
	if left < (parentWidth - right) and left < math.abs((left + right) / 2 - parentWidth / 2) then
		x = left
		point = 'LEFT'
	elseif (parentWidth - right) < math.abs((left + right) / 2 - parentWidth / 2) then
		x = right - parentWidth
		point = 'RIGHT'
	else
		x = (left + right) / 2 - parentWidth / 2
		point = ''
	end

	if bottom < (parentHeight - top) and bottom < math.abs((bottom + top) / 2 - parentHeight / 2) then
		y = bottom
		point = 'BOTTOM' .. point
	elseif (parentHeight - top) < math.abs((bottom + top) / 2 - parentHeight / 2) then
		y = top - parentHeight
		point = 'TOP' .. point
	else
		y = (bottom + top) / 2 - parentHeight / 2
		point = '' .. point
	end

	if point == '' then
		point = 'CENTER'
	end

	return point, x / scale, y / scale
end

local function onDragStop(self)
	local parent = self.parent
	parent:StopMovingOrSizing()

	-- TODO: snap position to grid
	-- FrameXML/EditModeUtil.lua

	local point, x, y = normalizePosition(parent)
	parent:ClearAllPoints()
	parent:SetPoint(point, x, y)

	lib:TriggerCallback(parent, point, x, y)
end

local function onMouseDown(self) -- replacement for EditModeSystemMixin:SelectSystem()
	resetSelection()
	EditModeManagerFrame:ClearSelectedSystem() -- possible taint

	if not self.isSelected then
		self.parent:SetMovable(true)
		self:ShowSelected(true)
		lib.dialog:Update(self)
	end
end

local function onEditModeEnter()
	lib.isEditing = true

	resetSelection()

	for _, callback in next, anonCallbacksEnter do
		callback()
	end
end

local function onEditModeExit()
	lib.isEditing = false

	resetSelection(true)

	for _, callback in next, anonCallbacksExit do
		callback()
	end
end

local function onEditModeChanged(_, layoutInfo)
	local layoutName = layoutNames[layoutInfo.activeLayout]
	if layoutName ~= lib.activeLayoutName then
		lib.activeLayoutName = layoutName

		for _, callback in next, anonCallbacksLayout do
			callback(layoutName)
		end

		-- TODO: we should update the position of the button here, let the user not deal with that
	end
end

--[[ LibEditMode:AddFrame(_frame, callback, default_)
TODO: docs
--]]
function lib:AddFrame(frame, callback, default)
	local selection = CreateFrame('Frame', nil, frame, 'EditModeSystemSelectionTemplate')
	selection:SetAllPoints()
	selection:SetScript('OnMouseDown', onMouseDown)
	selection:SetScript('OnDragStart', onDragStart)
	selection:SetScript('OnDragStop', onDragStop)
	selection:SetLabelText(frame:GetName())
	selection:Hide()

	frameSelections[frame] = selection
	frameCallbacks[frame] = callback
	frameDefaults[frame] = default

	if not lib.dialog then
		lib.dialog = lib:CreateDialog()
		lib.dialog:HookScript('OnHide', function()
			resetSelection()
		end)

		-- listen for layout changes
		EventRegistry:RegisterFrameEventAndCallback('EDIT_MODE_LAYOUTS_UPDATED', onEditModeChanged)

		-- hook EditMode shown state, since QuickKeybindMode will hide/show EditMode
		EditModeManagerFrame:HookScript('OnShow', onEditModeEnter)
		EditModeManagerFrame:HookScript('OnHide', onEditModeExit)

		-- unselect our selections whenever a system is selected
		hooksecurefunc(EditModeManagerFrame, 'SelectSystem', function()
			resetSelection()
		end)
	end
end

--[[ LibEditMode:AddFrameSettings(_frame, settings_)
TODO: docs
--]]
function lib:AddFrameSettings(frame, settings)
	if not frameSelections[frame] then
		error('frame must be registered')
	end

	frameSettings[frame] = settings
end

--[[ LibEditMode:AddFrameSettingsButton(_frame, data_)
TODO: docs
--]]
function lib:AddFrameSettingsButton(frame, data)
	if not frameButtons[frame] then
		frameButtons[frame] = {}
	end

	table.insert(frameButtons[frame], data)
end

--[[ LibEditMode:RegisterCallback(_event, callback_)
TODO: docs
--]]
function lib:RegisterCallback(event, callback)
	assert(event and type(event) == 'string', 'event must be a string')
	assert(callback and type(callback) == 'function', 'callback must be a function')

	if event == 'enter' then
		table.insert(anonCallbacksEnter, callback)
	elseif event == 'exit' then
		table.insert(anonCallbacksExit, callback)
	elseif event == 'layout' then
		table.insert(anonCallbacksLayout, callback)
	else
		error('invalid callback event "' .. event .. '"')
	end
end

--[[ LibEditMode:GetActiveLayoutName()
TODO: docs
--]]
function lib:GetActiveLayoutName()
	return lib.activeLayoutName
end

--[[ LibEditMode:IsInEditMode()
TODO: docs
--]]
function lib:IsInEditMode()
	return lib.isEditing
end

--[[ LibEditMode.SettingType
Convenient shorthand for `Enum.EditModeSettingDisplayType`.
--]]
lib.SettingType = CopyTable(Enum.EditModeSettingDisplayType)

--[[ LibEditMode:TriggerCallback(_frame[, ...]_)
TODO: docs
--]]
function lib:TriggerCallback(frame, ...)
	if frameCallbacks[frame] then
		frameCallbacks[frame](frame, lib.activeLayoutName, ...)
	end
end

--[[ LibEditMode:GetFrameDefaultPosition(_frame_)
TODO: docs
--]]
function lib:GetFrameDefaultPosition(frame)
	return frameDefaults[frame]
end

--[[ LibEditMode:GetFrameSettings(_frame_)
TODO: docs
--]]
function lib:GetFrameSettings(frame)
	if frameSettings[frame] then
		return frameSettings[frame], #frameSettings[frame]
	else
		return nil, 0
	end
end

--[[ LibEditMode:GetFrameButtons(_frame_)
TODO: docs
--]]
function lib:GetFrameButtons(frame)
	if frameButtons[frame] then
		return frameButtons[frame], #frameButtons[frame]
	else
		return nil, 0
	end
end
