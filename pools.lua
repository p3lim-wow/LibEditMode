local lib = LibStub('LibEditMode')

-- fork of ObjectPoolMixin to support passing through parent
local poolMixin = CreateFromMixins(ObjectPoolMixin)
function poolMixin:Acquire(parent)
	local numInactiveObjects = #self.inactiveObjects
	if numInactiveObjects > 0 then
		local obj = self.inactiveObjects[numInactiveObjects]
		self.activeObjects[obj] = true
		self.numActiveObjects = self.numActiveObjects + 1
		self.inactiveObjects[numInactiveObjects] = nil
		return obj, false
	end

	local newObj = self.creationFunc(self)
	if self.resetterFunc and not self.disallowResetIfNew then
		self.resetterFunc(self, newObj)
	end

	self.activeObjects[newObj] = true
	self.numActiveObjects = self.numActiveObjects + 1

	newObj:SetParent(parent)

	return newObj, true
end

local pools = {}

--[[ LibEditMode:CreatePool(_kind, creationFunc, resetterFunc_)
TODO: docs
--]]
function lib:CreatePool(kind, creationFunc, resetterFunc)
	local pool = CreateFromMixins(poolMixin)
	pool:OnLoad(creationFunc, resetterFunc)

	pools[kind] = pool
end

--[[ LibEditMode:GetPool(_kind_)
TODO: docs
--]]
function lib:GetPool(kind)
	return pools[kind]
end

--[[ LibEditMode:ReleaseAllPools()
TODO: docs
--]]
function lib:ReleaseAllPools()
	for _, pool in next, pools do
		pool:ReleaseAll()
	end
end
