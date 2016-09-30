local MicroWorld = require 'microworld.micro_world'
local HarvestTest = class(MicroWorld)

function HarvestTest:__init()
   self[MicroWorld]:__init(128)
   self:create_world()

   local player_id = self:get_session().player_id

   local z = -35
   self:place_item('stonehearth:trees:oak:ancient', -45, z)
   self:place_item('stonehearth:trees:oak:large', -25, z)
   self:place_item('stonehearth:trees:oak:medium', -5, z)
   self:place_item('stonehearth:trees:oak:small', 15, z)

   z = z + 20
   self:place_item('stonehearth:trees:juniper:ancient', -45, z)
   self:place_item('stonehearth:trees:juniper:large', -25, z)
   self:place_item('stonehearth:trees:juniper:medium', -5, z)
   self:place_item('stonehearth:trees:juniper:small', 15, z)

   z = z + 20
   self:place_item('stonehearth:trees:pine:large', -25, z)
   self:place_item('stonehearth:trees:pine:medium', -5, z)
   self:place_item('stonehearth:trees:pine:small', 15, z)

   z = z + 20
   self:place_item('stonehearth:trees:acacia:large', -45, z)
   self:place_item('stonehearth:trees:acacia:small', -15, z)
   self:place_item('stonehearth:trees:cactus:large', 15, z)
   self:place_item('stonehearth:trees:cactus:small', 35, z)

   z = z + 10
   self:place_item('stonehearth:boulder:large_1', -45, z)
   self:place_item('stonehearth:boulder:large_2', -35, z)
   self:place_item('stonehearth:boulder:medium_1', -25, z)
   self:place_item('stonehearth:boulder:medium_2', -15, z)
   self:place_item('stonehearth:boulder:medium_3', -5, z)
   self:place_item('stonehearth:boulder:small', 5, z)
   self:place_item('stonehearth:boulder:small', 15, z)
       :add_component('mob'):turn_to(90)
   self:place_item('stonehearth:boulder:small', 25, z)
       :add_component('mob'):turn_to(180)
   self:place_item('stonehearth:boulder:small', 35, z)
       :add_component('mob'):turn_to(280)

   z = z + 10
   self:place_item('stonehearth:plants:berry_bush', -45, z, nil, {force_iconic=false})
   self:place_item('stonehearth:plants:silkweed', -35, z, nil, {force_iconic=false})
   self:place_item('stonehearth:plants:brightbell', -25, z, nil, {force_iconic=false})
   self:place_item('stonehearth:plants:frostsnap', -15, z, nil, {force_iconic=false})
   self:place_item('stonehearth:plants:tumbleweed', -5, z, nil, {force_iconic=false})
   self:place_item('stonehearth:plants:pear_cactus', 5, z, nil, {force_iconic=false})
   self:place_item('stonehearth:plants:cactus', 10, z, nil, {force_iconic=false})

   self:place_item('stonehearth:containers:log_pile', 15, z, nil, {force_iconic=false})
   self:place_item('stonehearth:containers:stone_pile', 25, z, nil, {force_iconic=false})
   self:place_item('stonehearth:containers:wheat_pile', 35, z, nil, {force_iconic=false})
   self:place_item('stonehearth:containers:clay_pile', 45, z, nil, {force_iconic=false})

   -- add two workers.
   self:place_citizen(12, 12)
   self:place_citizen(14, 14)

   -- create a stockpile so the workers will have someplace to drop
   -- their stuff if you harvest a tree now.
   self:place_stockpile_cmd(player_id, 12, 12, 4, 4)
end

return HarvestTest

