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

--[[ LibEditMode:CreatePool(_kind, creationFunc[, resetterFunc_])
Internal method for creating a pool.  
It's functionally equivalent to SharedXML/Pools.lua's `ObjectPoolMixin`, except `Acquire` can pass a parent frame.

* `kind`: unique identifier _(string|number)_
* `creationFunc`: function that will be called when a new object is acquired.
* `resetterFunc`: optional function that will be called when an object is released.
--]]
function lib:CreatePool(kind, creationFunc, resetterFunc)
	local pool = CreateFromMixins(poolMixin)
	pool:OnLoad(creationFunc, resetterFunc)

	pools[kind] = pool
end

--[[ LibEditMode:GetPool(_kind_)
Internal method for retreiving a registered pool.

* `kind`: pool identifier _(string|number)_

Returns:

* `pool`: object representing the pool, inheriting all methods of SharedXML/Pools.lua's `ObjectPoolMixin`.
--]]
function lib:GetPool(kind)
	return pools[kind]
end

--[[ LibEditMode:ReleaseAllPools()
Internal method for releasing all objects in all pools. Calls `resetterFunc` on each object.
--]]
function lib:ReleaseAllPools()
	for _, pool in next, pools do
		pool:ReleaseAll()
	end
end
