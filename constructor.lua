-- rnd 2016:

-- CONSTRUCTOR machine: used to make all other protector

protector.craft_recipes = {
["steelprotect"] = {item = "protector:steelprotect", description = "Steel Protection Block", craft = {"default:stone 8","default:steelblock"}, tex  = "steelprotector"},
["copperprotect"] = {item = "protector:copperprotect", description = "Copper Protection Block", craft = {"default:stone 8","default:copperblock"}, tex = "copperprotector"},
["diamondprotect"] = {item = "protector:diamondprotect", description = "Diamond Protection Block", craft = {"default:stone 8","default:diamondblock"}, tex = "diamondprotector"},
["meseprotect"] = {item = "protector:meseprotect", description = "Mese Protection Block", craft = {"default:stone 8","default:mese"}, tex = "meseprotector"},

}

protector.craft_recipe_order = { -- order in which nodes appear
	"steelprotect", "copperprotect", "diamondprotect", "meseprotect",
}

		

local constructor_process = function(pos) 
	
			local meta = minetest.get_meta(pos);
			local craft = protector.craft_recipes[meta:get_string("craft")];
			if not craft then return end
			local item = craft.item;
			local craftlist = craft.craft;
			
			local inv = meta:get_inventory();
			for _,v in pairs(craftlist) do
				if not inv:contains_item("main", ItemStack(v)) then 
					meta:set_string("infotext", "#CRAFTING: you need " .. v .. " to craft " .. craft.item)
					return 
				end
			end
		
			for _,v in pairs(craftlist) do
				inv:remove_item("main", ItemStack(v));
			end
			inv:add_item("main", ItemStack(item));

end

local constructor_update_meta = function(pos)
		local meta = minetest.get_meta(pos);
		local list_name = "nodemeta:"..pos.x..','..pos.y..','..pos.z 
		local craft = meta:get_string("craft");
		
		local description = protector.craft_recipes[craft];
		local tex;
		
		if description then 
			tex = description.tex;
			local i = 0;
			local itex;
			
			local inv = meta:get_inventory(); -- set up craft list
			for _,v in pairs(description.craft) do
				i=i+1;
				inv:set_stack("recipe", i, ItemStack(v))	
			end
			
			for j = i+1,6 do
				inv:set_stack("recipe", j, ItemStack(""))
			end
			
			description = description.description 
			
		else 
			description = "" 
			tex = ""
		end
		
		
		local textlist = " ";
		
		local selected = meta:get_int("selected") or 1;
		for _,v in ipairs(protector.craft_recipe_order) do
			textlist = textlist .. v .. ", ";
			
		end
		
		local form  = 
			"size[8,10]"..
			"textlist[0,0;3,1.5;craft;" .. textlist .. ";" .. selected .."]"..
			"button[3.5,1;1.25,0.75;CRAFT;CRAFT]"..
			"image[3.65,0;1,1;".. tex .. ".png]"..
			"label[0,1.85;".. description .. "]"..
			"list[context;recipe;5,0;3,2;]"..
			"label[0,2.3;Put crafting materials here]"..
			"list[context;main;0,2.7;8,3;]"..
			--"list[context;dst;5,0;3,2;]"..
			"label[0,5.5;player inventory]"..
			"list[current_player;main;0,6;8,4;]"..
			"listring[context;main]"..
			"listring[current_player;main]";
		meta:set_string("formspec", form);
end


minetest.register_node("protector:constructor", {
	description = "Constructor: used to make protectors",
	tiles = {"crafting_top.png","crafting_bottom.png", "crafting_side.png","crafting_side.png","crafting_side.png","crafting_side.png"},
	groups = {cracky=3, mesecon_effector_on = 1},
	sounds = default.node_sound_wood_defaults(),
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos);
		meta:set_string("infotext", "Constructor: To operate it insert materials, select item to make and click craft button.")
		meta:set_string("owner", placer:get_player_name());
		meta:set_string("craft","steelprotector")
		meta:set_int("selected",1);
		local inv = meta:get_inventory();inv:set_size("main", 24);--inv:set_size("dst",6);
		inv:set_size("recipe",8);
	end,
	
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos);
		local privs = minetest.get_player_privs(player:get_player_name());
		if minetest.is_protected(pos, player:get_player_name()) and not privs.privs then return end -- only owner can interact with recycler
		constructor_update_meta(pos);
	end,
	
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if listname == "recipe" then return 0 end
		local meta = minetest.get_meta(pos);
		local privs = minetest.get_player_privs(player:get_player_name());
		if meta:get_string("owner")~=player:get_player_name() and not privs.privs then return 0 end
		return stack:get_count();
	end,
	
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		if listname == "recipe" then return 0 end
		local privs = minetest.get_player_privs(player:get_player_name());
		if minetest.is_protected(pos, player:get_player_name()) and not privs.privs then return 0 end 
		return stack:get_count();
	end,
	
	on_metadata_inventory_put = function(pos, listname, index, stack, player) 
		if listname == "recipe" then return 0 end
		local privs = minetest.get_player_privs(player:get_player_name());
		if minetest.is_protected(pos, player:get_player_name()) and not privs.privs then return 0 end 
		return stack:get_count();
	end,
	
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		return 0;
	end,
	
	mesecons = {effector = { 
		action_on = function (pos, node,ttl) 
			if type(ttl)~="number" then ttl = 1 end
			if ttl<0 then return end -- machines_TTL prevents infinite recursion
			constructor_process(pos);
		end
		}
	},
	
	on_receive_fields = function(pos, formname, fields, sender) 
		
		if minetest.is_protected(pos, sender:get_player_name())  then return end 
		local meta = minetest.get_meta(pos);
		
		if fields.craft then
			if string.sub(fields.craft,1,3)=="CHG" then
				local sel = tonumber(string.sub(fields.craft,5)) or 1
				meta:set_int("selected",sel);
			
				local i = 0;
				for _,v in ipairs(protector.craft_recipe_order) do
					i=i+1;
					if i == sel then meta:set_string("craft",v); break; end
				end
			else 
				return
			end
		end
		
		if fields.CRAFT then
			constructor_process(pos);
		end
		
		constructor_update_meta(pos);
	end,

})


minetest.register_craft({
	output = "protector:constructor",
	recipe = {
		{"default:steel_ingot","default:steel_ingot","default:steel_ingot"},
		{"default:steel_ingot","default:copperblock","default:steel_ingot"},
		{"default:steel_ingot","default:steel_ingot","default:steel_ingot"},
		
	}
})