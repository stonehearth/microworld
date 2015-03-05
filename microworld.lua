-- aliases for common core Radiant types.
local Cube3 = _radiant.csg.Cube3
local Point2 = _radiant.csg.Point2
local Point3 = _radiant.csg.Point3
local Region3 = _radiant.csg.Region3


local LOCAL_PLAYER = 'player_1'
local log = radiant.log.create_logger('main')

local MicroWorld = class()

-- creates a new world.  the `size` parameter is a number representing the size
-- of the world to create
function MicroWorld:create_world(size)
   size = size or 32

   -- add a single local player to the game.
   stonehearth.player:add_player(LOCAL_PLAYER, 'stonehearth:kingdoms:ascendancy')   

   -- create a trivial terrain.  just a flat, square world with bedrock, soil, and
   -- grass.
   self:create_terrain({ base = Point3(0, -2, 0), dimension = Point3(size, 2, size) }, 'bedrock')
   self:create_terrain({ base = Point3(0, 0, 0), dimension = Point3(size, 9, size) }, 'soil_dark')
   self:create_terrain({ base = Point3(0, 9, 0), dimension = Point3(size, 1, size) }, 'grass')
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
                  coordinates.base.x - math.floor(coordinates.dimension.x / 2),
                  coordinates.base.y,
                  coordinates.base.z - math.floor(coordinates.dimension.z / 2)
               )
         max = Point3(
                  coordinates.base.x + math.ceil(coordinates.dimension.x / 2),
                  coordinates.base.y + coordinates.dimension.y,
                  coordinates.base.z + math.ceil(coordinates.dimension.z / 2)
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

-- get the player_id of the local player.
function MicroWorld:get_local_player_id()
   return LOCAL_PLAYER
end

-- helper function to create entity with options.  `options` may have the
-- following values
--
--    owner (string): the player_id of the owner of the object
--
function MicroWorld:create_entity(alias, options)
   local entity = radiant.entities.create_entity(alias, options)
   
   return entity
end

-- create the entity identifyed by `alias` and place it on the ground at
-- coordinate `x`, `z`.  `alias` may be the absolute path to a entity json file
-- or an alias in the manifest of a mod which points to it.
--
-- `options` is an optional argument to assist in entity creation.  see
-- MicroWorld:create_entity for more information.  In addition to those options
-- the user may specify:
--
--    full_size (bool) : if true, places a full sized entity instead of an
--    iconic one.  For example if placing a 'stonehearth:furniture:comfy_bed'
--    the iconic version is the one a worker can pick up and carry around,
--    while the full_sized one someone can walk up and sleep in.
--
function MicroWorld:place_entity(alias, x, z, options)
   local entity = self:create_entity(alias, options)
   local force_iconic = options and not options.full_size

   radiant.terrain.place_entity(entity, Point3(x, 1, z), { force_iconic = force_iconic })
   return entity
end

-- places the town banner for the local player at `x`, `z`
function MicroWorld:place_town_banner(x, z)
   local banner = self:place_entity('stonehearth:camp_standard', x, z, {
         full_size = true
      })
   stonehearth.town:get_town(LOCAL_PLAYER)
                        :set_banner(banner)
   return banner
end

-- create `w` * `h` entities at `x`, `z`.  see `place_entity` for a discussion
-- of options
function MicroWorld:place_entity_cluster(alias, x, z, w, h, options)
   w = w and w or 3
   h = h and h or 3
   for i = x, x+w-1 do
      for j = z, z+h-1 do
         self:place_entity(alias, i, j, options)
      end
   end
end

-- create a citizen for the local player with the specified `job` and place
-- him at `x`, `z`.  The job must be an alias to a valid job (see the stonehearth
-- manifest for a list).  If no job is specified, a Worker is created.
function MicroWorld:place_citizen(x, z, job)
   local pop = stonehearth.population:get_population(LOCAL_PLAYER)
   local citizen = pop:create_new_citizen()

   job = job or 'stonehearth:jobs:worker'

   citizen:add_component('stonehearth:job')
               :promote_to(job)

   radiant.terrain.place_entity(citizen, Point3(x, 1, z))
   return citizen
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
   local workbench = self:place_entity(job_definition.workshop.workbench_type, x, z, { full_size = true, owner = self:get_local_player_id() })
   
   -- Link worker and crafter together
   local workshop_component = workbench:get_component('stonehearth:workshop')
   
   if not workshop_component then
      error('workbench has no stonehearth:workshop component!', 2)
   end
   
   crafter_component:set_workshop(workshop_component)
   workshop_component:set_crafter(citizen)
   
   return workbench
end

-- place a stockpile for the local player at `x`, `z`
function MicroWorld:place_stockpile(x, z, w, h)
   w = w and w or 3
   h = h and h or 3

   local location = Point3(x, 1, z)
   local size = Point2( w, h )

   local inventory = stonehearth.inventory:get_inventory(LOCAL_PLAYER)
   return inventory:create_stockpile(location, size)
end

-- the 'radiant:new_game' event is triggered whenever a new game starts
radiant.events.listen(MicroWorld, 'radiant:new_game', function(args)
      -- read the config file for the world to use.  this will read the
      -- mods.microworld.world key, returning it's value or 'mini_game'
      -- if that key does not exist.
      local world_name = radiant.util.get_config('world', 'mini_game')

      -- generate the name of the script to load for this world from the
      -- world name.  it must be placed in the worlds directory.
      local script_name = string.format('worlds.%s_world', world_name)

      -- try to load the script.
      local script = require(script_name)
      if not script then
         error(string.format('failed to require world script "%s".', script_name))
      end

      -- the script must return a generator function which create an
      -- insteand of an object with a `start` method.
      local world = script()
      if not world then
         error(string.format('world script "%s" failed to construct a world.', script_name))
      end

      -- we got a world back!  start it up!!
      world:start()
   end)

return MicroWorld
