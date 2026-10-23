local _, ns = ...
local lib
if ns.LibEditMode then
	lib = ns.LibEditMode
else
	local MINOR = 18
	local prevMinor
	lib, prevMinor = LibStub('LibEditMode')
	if prevMinor > MINOR then
		return
	end
end

local internal = lib.internal

local coordsMixin = {}

function coordsMixin:Update(selection, point, x, y)
	if not point or not x or not y then
		point, x, y = internal:CalculateParentPosition(selection)
	end

	self.selection = selection
	self.point = point
	self.x = x
	self.y = y

	self.XEditBox:SetText(x)
	self.XEditBox.value = x

	self.YEditBox:SetText(y)
	self.YEditBox.value = y

	self:Show()
end

function coordsMixin:Reset()
	self.selection = nil
	self.point = nil
	self.x = nil
	self.XEditBox.value = nil
	self.y = nil
	self.YEditBox.value = nil
end

local MAX_STEP = 10
local MID_STEP = 1
local MIN_STEP = 0.1

function coordsMixin:OnKeyDown(key)
	if InCombatLockdown() then
		return
	end

	if self.selection then
		self:SetPropagateKeyboardInput(false) -- protected

		if key == 'LEFT' then
			internal:MoveParent(self.selection, IsShiftKeyDown() and -MAX_STEP or IsAltKeyDown() and -MIN_STEP or -MID_STEP)
		elseif key == 'RIGHT' then
			internal:MoveParent(self.selection, IsShiftKeyDown() and MAX_STEP or IsAltKeyDown() and MIN_STEP or MID_STEP)
		elseif key == 'UP' then
			internal:MoveParent(self.selection, 0, IsShiftKeyDown() and MAX_STEP or IsAltKeyDown() and MIN_STEP or MID_STEP)
		elseif key == 'DOWN' then
			internal:MoveParent(self.selection, 0, IsShiftKeyDown() and -MAX_STEP or IsAltKeyDown() and -MIN_STEP or -MID_STEP)
		else
			self:SetPropagateKeyboardInput(true) -- protected
		end
	else
		self:SetPropagateKeyboardInput(true) -- protected
	end
end

local function onButtonMouseDown(self)
	if InCombatLockdown() then
		return
	end

	local parent = self:GetParent()
	if parent.selection then
		if self.dir == 'LEFT' then
			internal:MoveParent(parent.selection, IsShiftKeyDown() and -MAX_STEP or IsAltKeyDown() and -MIN_STEP or -MID_STEP)
		elseif self.dir == 'RIGHT' then
			internal:MoveParent(parent.selection, IsShiftKeyDown() and MAX_STEP or IsAltKeyDown() and MIN_STEP or MID_STEP)
		elseif self.dir == 'UP' then
			internal:MoveParent(parent.selection, 0, IsShiftKeyDown() and MAX_STEP or IsAltKeyDown() and MIN_STEP or MID_STEP)
		elseif self.dir == 'DOWN' then
			internal:MoveParent(parent.selection, 0, IsShiftKeyDown() and -MAX_STEP or IsAltKeyDown() and -MIN_STEP or -MID_STEP)
		end
	end
end

local function onEditFocus(self)
	self:SetText(self.value)
	self:HighlightText()
end

local function onEditSubmit(self)
	local parent = self:GetParent()

	local newX = tonumber(parent.XEditBox:GetText()) or 0
	local newY = tonumber(parent.YEditBox:GetText()) or 0

	internal:MoveParentToPoint(parent.selection, parent.point, newX, newY)

	self:ClearFocus()
end

local function onEditReset(self)
	self:SetText(self.value)
	self:ClearFocus()
end

function internal:CreateCoords()
	local coords = Mixin(CreateFrame('Frame', nil, UIParent), coordsMixin)
	coords:SetSize(256, 72)
	coords:SetPoint('BOTTOM', internal.dialog, 'TOP', 0, 8)
	coords:SetFrameStrata('DIALOG')
	coords:SetFrameLevel(300)
	coords:EnableMouse(true)
	coords:SetScript('OnKeyDown', coords.OnKeyDown)
	coords:Hide()

	local coordsBorder = CreateFrame('Frame', nil, coords, 'DialogBorderTranslucentTemplate')
	coords.Border = coordsBorder

	local xLabel = coords:CreateFontString(nil, nil, 'GameFontHighlightMedium')
	xLabel:SetPoint('BOTTOMLEFT', coords, 'LEFT', 16, 4)
	xLabel:SetWidth(24)
	xLabel:SetJustifyH('LEFT')
	xLabel:SetText('X' .. HEADER_COLON)
	coords.XLabel = xLabel

	local xEditBox = CreateFrame('EditBox', nil, coords, 'InputBoxTemplate')
	xEditBox:SetHeight(20)
	xEditBox:SetPoint('LEFT', xLabel, 'RIGHT', 4, 0)
	xEditBox:SetPoint('RIGHT', coords, -16, 0)
	xEditBox:SetAutoFocus(false)
	xEditBox:SetJustifyH('LEFT')
	xEditBox:SetScript('OnEditFocusGained', onEditFocus)
	xEditBox:SetScript('OnEnterPressed', onEditSubmit)
	xEditBox:SetScript('OnEscapePressed', onEditReset)
	xEditBox:SetScript('OnEditFocusLost', onEditReset)
	coords.XEditBox = xEditBox

	local yLabel = coords:CreateFontString(nil, nil, 'GameFontHighlightMedium')
	yLabel:SetPoint('TOPLEFT', coords, 'LEFT', 16, -4)
	yLabel:SetWidth(24)
	yLabel:SetJustifyH('LEFT')
	yLabel:SetText('Y' .. HEADER_COLON)
	coords.YLabel = yLabel

	local yEditBox = CreateFrame('EditBox', nil, coords, 'InputBoxTemplate')
	yEditBox:SetHeight(20)
	yEditBox:SetPoint('LEFT', yLabel, 'RIGHT', 4, 0)
	yEditBox:SetPoint('RIGHT', coords, -16, 0)
	yEditBox:SetAutoFocus(false)
	yEditBox:SetJustifyH('LEFT')
	yEditBox:SetScript('OnEditFocusGained', onEditFocus)
	yEditBox:SetScript('OnEnterPressed', onEditSubmit)
	yEditBox:SetScript('OnEscapePressed', onEditReset)
	yEditBox:SetScript('OnEditFocusLost', onEditReset)
	coords.YEditBox = yEditBox

	local leftArrow = CreateFrame('Button', nil, coords)
	leftArrow:SetSize(24, 24)
	leftArrow:SetPoint('LEFT', -16, 0)
	leftArrow:SetNormalAtlas('common-dropdown-condense-button')
	leftArrow:SetPushedAtlas('common-dropdown-condense-button-pressed')
	leftArrow:SetHighlightAtlas('common-dropdown-condense-button-hover', 'ADD')
	leftArrow:SetScript('OnMouseDown', onButtonMouseDown)
	leftArrow.dir = 'LEFT'

	local rightArrow = CreateFrame('Button', nil, coords)
	rightArrow:SetSize(24, 24)
	rightArrow:SetPoint('RIGHT', 16, 0)
	rightArrow:SetNormalAtlas('common-dropdown-expand-button')
	rightArrow:SetPushedAtlas('common-dropdown-expand-button-pressed')
	rightArrow:SetHighlightAtlas('common-dropdown-expand-button-hover', 'ADD')
	rightArrow:SetScript('OnMouseDown', onButtonMouseDown)
	rightArrow.dir = 'RIGHT'

	local topArrow = CreateFrame('Button', nil, coords)
	topArrow:SetSize(24, 24)
	topArrow:SetPoint('TOP', 0, 16)
	topArrow:SetNormalAtlas('common-dropdown-expand-button')
	topArrow:SetPushedAtlas('common-dropdown-expand-button-pressed')
	topArrow:SetHighlightAtlas('common-dropdown-expand-button-hover', 'ADD')
	topArrow:SetScript('OnMouseDown', onButtonMouseDown)
	topArrow.dir = 'UP'

	local bottomArrow = CreateFrame('Button', nil, coords)
	bottomArrow:SetSize(24, 24)
	bottomArrow:SetPoint('BOTTOM', 0, -16)
	bottomArrow:SetNormalAtlas('common-dropdown-condense-button')
	bottomArrow:SetPushedAtlas('common-dropdown-condense-button-pressed')
	bottomArrow:SetHighlightAtlas('common-dropdown-condense-button-hover', 'ADD')
	bottomArrow:SetScript('OnMouseDown', onButtonMouseDown)
	bottomArrow.dir = 'DOWN'

	return coords
end
