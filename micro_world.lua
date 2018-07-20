local MicroWorld = class()
local game_master_lib = require 'stonehearth.lib.game_master.game_master_lib'
local entity_forms_lib = require 'stonehearth.lib.entity_forms.entity_forms_lib'

local Point2 = _radiant.csg.Point2
local Point3 = _radiant.csg.Point3
local Cube3 = _radiant.csg.Cube3
local Region3 = _radiant.csg.Region3

local log = radiant.log.create_logger('microworld')

function MicroWorld:__init(size, height)
   self._nextTime = 1
   self._running = false
   self._session = {
      player_id = 'player_1',
   }

   if not size then
      size = 32
   end
   self._size = size
   self._height = height
end

function MicroWorld:get_session()
   return self._session
end

function MicroWorld:create_world(kingdom, biome)
   local session = self:get_session()
   if not kingdom then
      kingdom = 'stonehearth:kingdoms:ascendancy'
   end

   stonehearth.world_generation:create_empty_world(biome)

   stonehearth.player:add_player(session.player_id)
   stonehearth.player:add_kingdom(session.player_id, kingdom)
   stonehearth.terrain:set_fow_enabled(session.player_id, false)

   local height = 10
   if self._height then 
      height = self._height
   end


   assert(self._size % 2 == 0)
   local half_size = self._size / 2

   local block_types = radiant.terrain.get_block_types()

   local region3 = Region3()
   region3:add_cube(Cube3(Point3(0, -2, 0), Point3(self._size, 0, self._size), block_types.bedrock))
   region3:add_cube(Cube3(Point3(0, 0, 0), Point3(self._size, height-1, self._size), block_types.soil_dark))
   region3:add_cube(Cube3(Point3(0, height-1, 0), Point3(self._size, height, self._size), block_types.grass))
   region3 = region3:translated(Point3(-half_size, 0, -half_size))

   radiant.terrain.get_terrain_component():add_tile(region3)

   stonehearth.weather:set_weather_override('stonehearth:weather:test')

   stonehearth.hydrology:start()
   stonehearth.mining:start()
end

function MicroWorld:at(time, fn)
   return radiant.set_realtime_timer("MicroWorld at", time, fn)
end

function MicroWorld:place_tree(x, z)
   return self:place_item('stonehearth:trees:oak:small', x, z)
end

function MicroWorld:place_item(uri, x, z, player_id, options)
   local entity = radiant.entities.create_entity(uri, {owner = player_id})
   entity = radiant.terrain.place_entity(entity, Point3(x, 1, z), options)
   if player_id then
      local inventory = stonehearth.inventory:get_inventory(player_id)
      if inventory and not inventory:contains_item(entity) then
         inventory:add_item(entity)
      end
   end
   return entity
end

function MicroWorld:place_item_cluster(uri, x, z, w, h, player_id)
   w = w and w or 3
   h = h and h or 3
   for i = x, x+w-1 do
      for j = z, z+h-1 do
         self:place_item(uri, i, j, player_id)
      end
   end
end

function MicroWorld:place_item_list(uri_list, x, z, x_offset, z_offset, player_id, options)
   for num, uri in pairs(uri_list) do
      if uri ~= '' then
         local entity = radiant.entities.create_entity(uri, {owner = player_id})
         entity = radiant.terrain.place_entity(entity, Point3(x+num*x_offset, 1, z+num*z_offset), options)
         if player_id then
            local inventory = stonehearth.inventory:get_inventory(player_id)
            if inventory and not inventory:contains_item(entity) then
               inventory:add_item(entity)
            end
         end
      end
   end

end



function MicroWorld:place_filled_container(uri, x, y, player_id, container_uri)
   container_uri = container_uri or 'stonehearth:containers:stone_chest'
   local container = self:place_item(container_uri, x, y, player_id, { force_iconic = false })
   self:fill_storage(container, uri)
end

function MicroWorld:place_citizen(x, z, job, gender, options)
   job = job or 'stonehearth:jobs:worker'
   options = options or {suppress_traits=true}  -- Without traits is the default in MicroWorld

   local pop = stonehearth.population:get_population('player_1')
   local citizen = pop:create_new_citizen(nil, gender, options)

   if not string.find(job, ':') and not string.find(job, '/') then
      -- as a convenience for autotest writers, stick the stonehearth:job on
      -- there if they didn't put it there to begin with
      job = 'stonehearth:jobs:' .. job
   end
   local job_component = citizen:add_component('stonehearth:job')
   local path = job_component:get_job_description_path(job)
   local job_json = radiant.resources.load_json(path, true)

   -- place them facing the camera
   radiant.terrain.place_entity(citizen, Point3(x, 1, z), { facing = 180 })

   if job_json.parent_level_requirement then
      job_component:promote_to(job_json.parent_job)
      self:level_up_citizen(citizen, job_json.parent_level_requirement)
   end

   job_component:promote_to(job)

   if options.clear_traits and citizen:get_component('stonehearth:traits') then
      citizen:get_component('stonehearth:traits'):clear_all_traits()
   end

   return citizen
end

-- creates a new block.
-- `coordinates`is a table either containing two Point3 (or tables with x/y/z members) called
--    - `min` and `max` if you wish to define it in a min/max coordinate style
--    - `center` and `dimension` if you wish to have a centered block
--    - `base` and `dimension` if you wish to have a centered block on top of `base`
-- `block_type` is the name of the block type to be created
--              (as pulled from `radiant.terrain.get_block_types()`)
function MicroWorld:create_terrain(coordinates, block_type)
   local region3 = Region3()
   local min, max

   -- Make sure that all the coordinates are Point3s
   for k, v in pairs(coordinates) do
      if not radiant.util.is_a(v, Point3) and radiant.util.is_a(v, 'table') then
         coordinates[k] = Point3(v.x, v.y, v.z)
      end
   end

   -- does coordinates contain min/max?
   if coordinates.min ~= nil and coordinates.max ~= nil then
      min, max = coordinates.min, coordinates.max
   elseif coordinates.dimension ~= nil then
      local dimension_half = coordinates.dimension / 2
      if coordinates.center ~= nil then
         min = coordinates.center - Point3(math.floor(dimension_half.x), math.floor(dimension_half.y), math.floor(dimension_half.z))
         max = coordinates.center + Point3(math.ceil(dimension_half.x), math.ceil(dimension_half.y), math.ceil(dimension_half.z))
      elseif coordinates.base ~= nil then
         min = Point3(
                  coordinates.base.x - math.floor(dimension_half.x),
                  coordinates.base.y,
                  coordinates.base.z - math.floor(dimension_half.z)
               )
         max = Point3(
                  coordinates.base.x + math.ceil(dimension_half.x),
                  coordinates.base.y + coordinates.dimension.y,
                  coordinates.base.z + math.ceil(dimension_half.z)
               )
      else
         error('cannot determine coordinates of block (invalid coordinates passed)')
      end
   else
      error('cannot determine coordinates of block (invalid coordinates passed)')
   end

   local block_types = radiant.terrain.get_block_types()
   region3:add_cube(Cube3(min, max, block_types[block_type]))

   radiant._root_entity:add_component('terrain'):add_tile(region3)
end

-- places the town banner for the local player at `x`, `z`
function MicroWorld:place_town_banner(x, z, player_id)
   local banner = self:place_item('stonehearth:camp_standard', x, z, player_id, { force_iconic = false })
   stonehearth.town:get_town(player_id):set_banner(banner)
   return banner
end

-- creates a workbench for `citizen` at (`x`/`z`)
function MicroWorld:create_workbench(citizen, x, z)
   -- Get the job component
   local job_component = citizen:get_component('stonehearth:job')
   if not job_component then
      error('citizen has no stonehearth:job component! (did you forget the promotion?)', 2)
   end

   -- Get the crafter component
   local crafter_component = citizen:get_component('stonehearth:crafter')
   if not crafter_component then
      error('citizen has no stonehearth:crafter component!', 2)
   end

   -- Create the workshop, pulling the entity ref from the job's definition
   local job_definition = radiant.resources.load_json(job_component:get_job_uri())
   local player_id = self:get_session().player_id
   local workbench = self:place_item(job_definition.workshop.workbench_type, x, z, player_id, { force_iconic = false })

   -- Link worker and crafter together
   local workshop_component = workbench:get_component('stonehearth:workshop')

   if not workshop_component then
      error('workbench has no stonehearth:workshop component!', 2)
   end

   crafter_component:set_current_workshop(workshop_component)

   return workbench
end

-- Spawns monsters at the specified x,z location
-- Uses tuning data file or info similar to that in encounter files
-- to modify monster
-- ex. spawn_monster(0, 0, 'goblins', 'stonehearth:monster_tuning:goblins:marauder') or
-- info = {
--    from_population = {
--       role = 'wolf',
--       min = 1,
--       max = 1
--    },
--    equipment = {
--       weapon = {
--          'stonehearth:weapons:stone_maul'
--       },
--       abilities = 'stonehearth:abilities:wolf_rider_abilities'
--    }
-- }
function MicroWorld:spawn_monster(x, z, npc_player_id, info, role)
   local origin = Point3(x, 10, z)
   local monster_info = type(info) == 'table' and info or
      {
         tuning = info,
         from_population = {
            location = origin,
            role = role or 'default'
         }
      }
   if info.from_population then
      monster_info.from_population = info.from_population
      monster_info.from_population.location = origin
   end

   local population = stonehearth.population:get_population(npc_player_id)
   radiant.assert(population, 'population %s does not exist!', npc_player_id)
   local members = game_master_lib.create_citizens(population, monster_info, origin, { player_id = npc_player_id })
   if #members == 1 then
      return members[1]
   end
   return members
end

function MicroWorld:create_enemy_party(player_id, enemies)
   local party_entity = stonehearth.unit_control:get_controller(player_id):create_party()
   local party_component = party_entity:get_component('stonehearth:party')

   local citizens = type(enemies) == 'table' and enemies or { enemies }
   for _, citizen in pairs(citizens) do
      party_component:add_member(citizen)
   end

   return party_entity
end

function MicroWorld:place_stockpile_cmd(player_id, x, z, w, h)
   w = w and w or 3
   h = h and h or 3

   local location = Point3(x, 1, z)
   local size = Point2( w, h )

   local inventory = stonehearth.inventory:get_inventory(player_id)
   return inventory:create_stockpile(location, size)
end

function MicroWorld:add_to_storage(entity, item_uri)
   local storage = entity:get_component('stonehearth:storage')
   local item = radiant.entities.create_entity(item_uri, {owner = entity})
   local root, iconic = entity_forms_lib.get_forms(item)
   if iconic then
      storage:add_item(iconic)
   else
      storage:add_item(item)
   end
end

function MicroWorld:fill_storage(entity, item_uri)
   --Fill entire storage with items
   local num = entity:get_component('stonehearth:storage'):get_capacity()

   for i=1, num do
      self:add_to_storage(entity, item_uri)
   end
end

function MicroWorld:add_cube_to_terrain(x, z, width, length, height, tag)
   local y = radiant.terrain.get_point_on_terrain(Point3(x, 0, z)).y
   local cube = Cube3(
         Point3(x, y, z),
         Point3(x + width, y + height, z + length),
         tag
      )
   radiant.terrain.add_cube(cube)
   return cube
end

function MicroWorld:remove_cube_from_terrain(x, z, width, length, depth)
   local y = radiant.terrain.get_point_on_terrain(Point3(x, 0, z)).y
   local cube = Cube3(
         Point3(x, y - depth, z),
         Point3(x + width, y, z + length)
      )
   radiant.terrain.subtract_cube(cube)
   return cube
end

-- Create a settlement (with town banner) with the specified number of citizens, spawned in a spiral shape around the origin
-- @param options - a number specifying how many workers to spawn OR
                 -- a map with the citizen class and how many of that class to spawn and/or desired attributes
                                    -- ex: {
                                    --          footman = 10,
                                    --          shepherd = { num = 1, attributes = { body = 1, spirit = 1}},
                                    --          carpenter = 1
                                    --     }
-- @param origin - origin x and z coordinates around which to spawn the hearthlings
-- @param spacing - how far each hearthling should spawn from each other
function MicroWorld:create_settlement(options, x, z, spacing)
   local player_id = self:get_session().player_id
   local town = stonehearth.town:get_town(player_id)
   local inventory = stonehearth.inventory:get_inventory(player_id)
   local standard, standard_ghost = stonehearth.player:get_kingdom_banner_style(player_id)
   if not standard then
      standard = 'stonehearth:camp_standard'
   end

   local banner = radiant.entities.create_entity(standard, { owner = player_id })
   radiant.terrain.place_entity(banner, Point3(8, 1, 8), { force_iconic = false })
   inventory:add_item(banner)
   town:set_banner(banner)

   local hearth_entity = radiant.entities.create_entity('stonehearth:decoration:firepit_hearth', { owner = player_id })
   radiant.terrain.place_entity(hearth_entity, Point3(8, 1, 5), { force_iconic = false })
   inventory:add_item(hearth_entity)
   town:set_hearth(hearth_entity)

   local dx = spacing or 3
   local dy = 0
   local segment_length = 1
   local segment_progress = 0

   local function new_point(x, y)
      local new_x, new_y = x + dx, y + dy
      segment_progress = segment_progress + 1
      if segment_progress == segment_length then
         segment_progress = 0
         dx, dy = -dy, dx
         if dy == 0 then
            segment_length = segment_length + 1
         end
      end
      return new_x, new_y
   end

   local x = x or 0
   local y = z or 0

   assert(options, 'no options specified for create settlement!')

   local citizens = {}
   if type(options) == 'table' then
      for class_name, info in pairs(options) do
         local num = info
         local attributes, level, levels_array, gender, opts

         if type(info) == 'table' then
            num = info.num
            attributes = info.attributes
            level = info.level
            levels_array = info.levels
            gender = info.gender
            opts = info.options
         end

         for i=1, num do
            local citizen = self:place_citizen(x, y, class_name, gender, opts)
            if attributes then
               for attr, value in pairs(attributes) do
                  radiant.entities.set_attribute(citizen, attr, value)
               end
            end
            if levels_array and levels_array[i] then
                self:level_up_citizen(citizen, levels_array[i])
            elseif level then
               self:level_up_citizen(citizen, level)
            end
            table.insert(citizens, citizen)
            x, y = new_point(x, y)
         end
      end
   else
      for i=1, options do
         local citizen = self:place_citizen(x, y)
         table.insert(citizens, citizen)
         x, y = new_point(x, y)
      end
   end

   local town = stonehearth.town:get_town(player_id)
   if town then
      town:check_for_combat_job_presence()
   end

   return citizens
end

function MicroWorld:level_up_citizen(entity, level)
   local job_component = entity:get_component('stonehearth:job')
   for i=1, level do
      job_component:level_up(true)
   end
end

-- Add gold so net worth is equivalent to what is needed to get to the current population size,
-- in order to get the correct raids (which are gated on net worth)
function MicroWorld:set_appropriate_net_worth(player_id)
   local population = stonehearth.population:get_population(player_id)
   local num_citizens = population:get_citizen_count()
   local req_net_worth = math.max(math.max((num_citizens - 6), 0.5) * 550 , (num_citizens ^ 2 - 18 * num_citizens) * 100)

   local score_data = stonehearth.score:get_scores_for_player(player_id):get_score_data()
   local net_worth = score_data and score_data.total_scores:get('net_worth') or 0

   if net_worth then
      req_net_worth = req_net_worth - net_worth
   end

   if req_net_worth > 0 then
      local inventory = stonehearth.inventory:get_inventory(player_id)

      if inventory ~= nil then
         inventory:add_gold(req_net_worth)
      end
   else
      -- if net_worth too high, manually force it to the citizen req net worth
      score_data.total_scores:add('net_worth', req_net_worth + net_worth)
   end
end

--Place all the equipment in all the relevant mods in the test world
function MicroWorld:place_all_entities_passing_filter(player_id, x, z, filter_fn)
   local all_entities = stonehearth.catalog:get_all_entity_uris()
   local x = x
   local z = z

   for uri in pairs(all_entities) do
      if filter_fn(uri) then
         for i = 1, 4 do
            -- place the entity into the world
            self:place_item(uri, x, z, player_id)
            x = (x + 1) % 8
            if x == 0 then
               z = z + 1
            end
         end
      end
   end
end

local alias_is_equipment = function(uri)
   local json = radiant.resources.load_json(uri)

   if json['components'] ~= nil and
      json['components']['stonehearth:equipment_piece'] ~= nil and
      json['components']['stonehearth:equipment_piece'].roles ~= nil then
      return true
   end

   return false
end

--Place all the equipment in all the relevant mods in the test world
function MicroWorld:place_all_combat_equipment(player_id, x, z)
   self:place_all_entities_passing_filter(player_id, x, z, alias_is_equipment)
end

-- Create resource piles that restock themselves
function MicroWorld:create_resource_stockpiles(player_id)
   local inventory = stonehearth.inventory:get_inventory('player_1')
   local food_stockpile = inventory:create_stockpile(Point3(-10, 1, 20), Point2(4, 4))
   self:place_item_cluster('stonehearth:food:berries:berry_basket', -10, 20, 4, 4, 'player_1')
   local storage_component = food_stockpile:get_component('stonehearth:storage')
   storage_component:set_filter({ "food_container", "prepared_food", "cooking_ingredient", "drink" })

   inventory:create_stockpile(Point3(20, 1, 10), Point2(4, 4))
   self:place_item_cluster('stonehearth:consumables:healing_tonic:small', 20, 10, 4, 4, 'player_1')
   inventory:create_stockpile(Point3(13, 1, 20), Point2(4, 4))
   self:place_item_cluster('stonehearth:consumables:coarse_bandage', 13, 20, 4, 4, 'player_1')

   local function restock_items()
      local inventory = stonehearth.inventory:get_inventory('player_1')
      if not inventory:get_items_of_type('stonehearth:food:berries:berry_basket') then
         self:place_item_cluster('stonehearth:food:berries:berry_basket', -10, 20, 4, 4, 'player_1')
     end
     if not inventory:get_items_of_type('stonehearth:consumables:healing_tonic:small') then
         self:place_item_cluster('stonehearth:consumables:healing_tonic:small', 20, 10, 2, 2, 'player_1')
     end
     if not inventory:get_items_of_type('stonehearth:consumables:coarse_bandage') then
         self:place_item_cluster('stonehearth:consumables:coarse_bandage', 13, 20, 2, 2, 'player_1')
      end
   end

   -- check whether we need to restock every 5 hours
   local timer = stonehearth.calendar:set_interval("item restock timer", '5h', restock_items)
end

return MicroWorld
