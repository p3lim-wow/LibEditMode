local lib = LibStub('LibEditMode')

lib:CreatePool('button', function()
	return CreateFrame('Button', nil, UIParent, 'EditModeSystemSettingsDialogExtraButtonTemplate')
end)
