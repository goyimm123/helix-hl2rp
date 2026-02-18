ITEM.name = "Alchemy Potion"
ITEM.description = "An experimental brew created from mixed ingredients."
ITEM.category = "Alchemy"
ITEM.model = Model("models/props_junk/garbage_glassbottle002a.mdl")
ITEM.width = 1
ITEM.height = 1
ITEM.price = 45

function ITEM:GetName()
	return self:GetData("name", self.name)
end

function ITEM:GetDescription()
	local effects = self:GetData("effects", {})
	local effectNames = {}

	for _, effectID in ipairs(effects) do
		if (PLUGIN.effectPool[effectID]) then
			effectNames[#effectNames + 1] = PLUGIN.effectPool[effectID].name
		end
	end

	if (#effectNames == 0) then
		return self.description
	end

	return string.format("%s\nEffects: %s", self.description, table.concat(effectNames, ", "))
end

ITEM.functions.Drink = {
	sound = "items/battery_pickup.wav",
	OnRun = function(item)
		local client = item.player
		if (!IsValid(client)) then
			return false
		end

		local effects = item:GetData("effects", {})
		if (#effects == 0) then
			client:Notify("This potion has lost its potency.")
			return
		end

		for _, effectID in ipairs(effects) do
			local effectData = PLUGIN.effectPool[effectID]
			if (effectData and effectData.apply) then
				effectData.apply(client)
			end
		end

		client:Notify("You drink the potion and feel its effects.")
	end
}
