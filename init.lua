craftskills = {}
craftskills.recipes = {}
craftskills.players = {}
local input = io.open(minetest.get_worldpath()..'/craftskills_players', 'r')
if input then
	craftskills.players = minetest.deserialize(input:read())
	io.close(input)
end

function craftskills.register_recipe(iname, locked, need_ep, get_ep)
	craftskills.recipes[iname] = {locked = locked, need_ep = need_ep, get_ep = get_ep}
end

function craftskills.save_players()
	local output = io.open(minetest.get_worldpath()..'/craftskills_players', 'w')
	output:write(minetest.serialize(craftskills.players))
	io.close(output)
end

minetest.register_on_joinplayer(function(player)
	local pname = player:get_player_name()
	if not craftskills.players[pname] then
		craftskills.players[pname]={items = {}, ep = 0}
	end
	craftskills.players[pname].hud = player:hud_add({
		hud_elem_type = "text",
		position = {x=0, y=1},
		offset = {x=100, y=-30},
		number = 0xFFFFFF,
		text = "Craft-EP: "..craftskills.players[pname].ep,
	})
end)

function craftskills.grant_recipe(pname, iname)
	craftskills.players[pname].recipes[iname] = true
	craftskills.save_players()
end

function craftskills.get_ep(pname)
	return craftskills.players[pname].ep
end

function craftskills.set_ep(pname, ep)
	craftskills.players[pname].ep = ep
	craftskills.save_players()
	local player = minetest.get_player_by_name(pname)
	player:hud_change(craftskills.players[pname].hud, "text", "Craft-EP: "..craftskills.players[pname].ep)
end

function craftskills.add_ep(pname, ep)
	craftskills.players[pname].ep = craftskills.players[pname].ep + ep
	craftskills.save_players()
	local player = minetest.get_player_by_name(pname)
	player:hud_change(craftskills.players[pname].hud, "text", "Craft-EP: "..craftskills.players[pname].ep)
end


function craftskills.check_recipe_lock(pname, iname)
	if craftskills.recipes[iname].locked == false then
		return true
	else
		if craftskills.players[pname].recipes[iname] == true then
			return true
		else
			minetest.chat_send_player(pname, "You have to unlock this recipe!")
			return false
		end
	end
end

function craftskills.check_recipe_ep(pname, iname)
	if craftskills.recipes[iname].need_ep>craftskills.players[pname].ep then
		minetest.chat_send_player(pname, "You need "..craftskills.recipes[iname].need_ep-craftskills.players[pname].ep.." Craft-EP more, to unlock this recipe!")
		return false
	else
		return true
	end
end

function craftskills.check_recipe(pname, iname)
	return craftskills.check_recipe_lock(pname, iname) and craftskills.check_recipe_ep(pname, iname)
end


minetest.after(0.1, function()
	for iname in pairs(minetest.registered_items) do
		if minetest.get_all_craft_recipes(iname) then
			if not craftskills.recipes[iname] then
				craftskills.recipes[iname] = {locked = false, need_ep = 0, get_ep=1}
			end
		end
	end
end)


minetest.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
	local iname = itemstack:get_name()
	local pname = player:get_player_name()
	if craftskills.check_recipe_ep(pname, iname) then
		craftskills.add_ep(pname, craftskills.recipes[iname].get_ep)
		return itemstack
	else
		local inv = minetest.get_inventory({type="player", name=pname})
		inv:set_list("craft", old_craft_grid)
		return ItemStack("")
	end
end)

craftskills.register_recipe("default:torch", false, 3, -1)
