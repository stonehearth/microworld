local MicroWorld = require 'micro_world'
local Point3 = _radiant.csg.Point3

local MiniGame = class(MicroWorld)

function MiniGame:__init()
   -- create a tiny world
   self[MicroWorld]:__init(128)
   self:create_world()

   local player_id = self:get_session().player_id
   local pop = stonehearth.population:get_population(player_id)

   -- create a settlement with a banner and firepit
   -- and 6 workers around the point(0,0)
   local workers = self:create_settlement({ worker = 6 }, 0, 0)

   -- add some bushes so our citizens don't starve
   for x = 1,4 do
      for z = 1,2 do
         self:place_item('stonehearth:plants:berry_bush', 8 + x * 4, 2 + z * 4, player_id, {force_iconic=false})
      end
   end

   -- drop some trees, too
   self:place_item('stonehearth:trees:oak:large', -12, -12, player_id)
   self:place_item('stonehearth:trees:oak:medium',  14, -13, player_id)
   self:place_item('stonehearth:trees:oak:medium',  11,  16, player_id)
   self:place_item('stonehearth:trees:oak:small', -10,  15, player_id)

   -- and a cute little fox.
   self:place_item('stonehearth:red_fox', 2, 2, player_id)

   -- give some of the workers some starting items.
   local pop = stonehearth.population:get_population(player_id)

   local function pickup(who, uri)
      local item = pop:create_entity(uri)
      radiant.entities.pickup_item(who, item)
   end
   pickup(workers[6], 'stonehearth:resources:wood:oak_log')
   pickup(workers[2], 'stonehearth:resources:fiber:silkweed_bundle')
   pickup(workers[3], 'stonehearth:trapper:talisman')
   pickup(workers[4], 'stonehearth:carpenter:talisman')
end

return MiniGame

