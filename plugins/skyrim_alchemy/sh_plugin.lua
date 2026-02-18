PLUGIN.name = "Skyrim Alchemy"
PLUGIN.author = "Codex"
PLUGIN.description = "Adds a Skyrim-like potion brewing loop with discoverable ingredient effects."

PLUGIN.effectPool = {
	restore_health = {
		name = "Restore Health",
		description = "Quickly restores 25 health.",
		apply = function(client)
			client:SetHealth(math.min(client:Health() + 25, client:GetMaxHealth()))
		end
	},
	damage_health = {
		name = "Damage Health",
		description = "Deals 10 poison damage.",
		apply = function(client)
			client:SetHealth(math.max(client:Health() - 10, 1))
		end
	},
	resist_damage = {
		name = "Stoneguard",
		description = "Grants 20 armor.",
		apply = function(client)
			client:SetArmor(math.min(client:Armor() + 20, 100))
		end
	},
	fortify_stamina = {
		name = "Fortify Stamina",
		description = "A strong stimulant. Restores 15 health.",
		apply = function(client)
			client:SetHealth(math.min(client:Health() + 15, client:GetMaxHealth()))
		end
	}
}

function PLUGIN:GetSharedEffects(firstItem, secondItem)
	local firstEffects = firstItem.alchemyEffects or {}
	local secondEffects = secondItem.alchemyEffects or {}
	local shared = {}

	for _, firstEffect in ipairs(firstEffects) do
		for _, secondEffect in ipairs(secondEffects) do
			if (firstEffect == secondEffect) then
				shared[#shared + 1] = firstEffect
				break
			end
		end
	end

	return shared
end

function PLUGIN:RememberEffects(character, ingredientID, effects)
	local knownEffects = character:GetData("alchemyKnownEffects", {})
	knownEffects[ingredientID] = knownEffects[ingredientID] or {}

	for _, effectID in ipairs(effects) do
		knownEffects[ingredientID][effectID] = true
	end

	character:SetData("alchemyKnownEffects", knownEffects)
end

local COMMAND = {}
COMMAND.description = "Brew a potion from two ingredients in your inventory."
COMMAND.arguments = {
	ix.type.string,
	ix.type.string
}
COMMAND.syntax = "<ingredient uniqueID> <ingredient uniqueID>"

function COMMAND:OnRun(client, firstID, secondID)
	firstID = string.Trim(string.lower(firstID or ""))
	secondID = string.Trim(string.lower(secondID or ""))

	if (firstID == "" or secondID == "") then
		client:Notify("You must specify two ingredient IDs.")
		return
	end

	if (firstID == secondID) then
		client:Notify("Use two different ingredients for brewing.")
		return
	end

	local character = client:GetCharacter()
	if (!character) then
		return
	end

	local inventory = character:GetInventory()
	local firstItem = inventory:HasItem(firstID)
	local secondItem = inventory:HasItem(secondID)

	if (!firstItem or !secondItem) then
		client:Notify("You do not have the required ingredients.")
		return
	end

	if (!firstItem.isAlchemyIngredient or !secondItem.isAlchemyIngredient) then
		client:Notify("Both items must be alchemy ingredients.")
		return
	end

	local sharedEffects = PLUGIN:GetSharedEffects(firstItem, secondItem)
	local potionData = {
		ingredients = {firstItem.name, secondItem.name}
	}

	if (#sharedEffects > 0) then
		potionData.effects = sharedEffects
		potionData.name = string.format("Potion: %s + %s", firstItem.name, secondItem.name)
		PLUGIN:RememberEffects(character, firstItem.uniqueID, sharedEffects)
		PLUGIN:RememberEffects(character, secondItem.uniqueID, sharedEffects)
	else
		potionData.effects = {"damage_health"}
		potionData.name = string.format("Unstable Brew: %s + %s", firstItem.name, secondItem.name)
	end

	if (!inventory:Add("alchemy_potion", 1, potionData)) then
		client:Notify("Brewing failed because your inventory is full.")
		return
	end

	inventory:Remove(firstItem.id)
	inventory:Remove(secondItem.id)

	if (#sharedEffects > 0) then
		client:Notify(string.format("You brewed a potion with %d shared effect(s).", #sharedEffects))
	else
		client:Notify("No shared effects found. You created an unstable brew.")
	end
end

ix.command.Add("BrewPotion", COMMAND)
