ITEM.name = "Alchemy Base"
ITEM.description = "An alchemical ingredient used for potion brewing."
ITEM.category = "Alchemy"
ITEM.model = Model("models/props_junk/garbage_glassbottle003a.mdl")
ITEM.width = 1
ITEM.height = 1
ITEM.price = 20
ITEM.isAlchemyIngredient = true
ITEM.alchemyEffects = {}

function ITEM:GetDescription()
	local description = self.description
	local character = LocalPlayer and LocalPlayer():GetCharacter()

	if (!character) then
		return description
	end

	local knownEffects = character:GetData("alchemyKnownEffects", {})
	local itemKnownEffects = knownEffects[self.uniqueID] or {}
	local discovered = {}

	for _, effectID in ipairs(self.alchemyEffects or {}) do
		if (itemKnownEffects[effectID] and PLUGIN.effectPool[effectID]) then
			discovered[#discovered + 1] = PLUGIN.effectPool[effectID].name
		end
	end

	if (#discovered > 0) then
		description = string.format("%s\nKnown effects: %s", description, table.concat(discovered, ", "))
	end

	return description
end
