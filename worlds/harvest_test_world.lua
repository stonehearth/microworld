local MicroWorld = require 'micro_world'
local Point3 = _radiant.csg.Point3

local HarvestTest = class(MicroWorld)

function HarvestTest:__init()
   self[MicroWorld]:__init(128)
   self:create_world()
   local player_id = self:get_session().player_id

   -- place some trees around the world
   self:place_item('stonehearth:trees:oak:large', -25, -25, player_id)
   self:place_item('stonehearth:trees:oak:medium', -5, -25, player_id)
   self:place_item('stonehearth:trees:oak:small',  15, -25, player_id)

   self:place_item('stonehearth:trees:juniper:large', -25, -5, player_id)
   self:place_item('stonehearth:trees:juniper:medium', -5, -5, player_id)
   self:place_item('stonehearth:trees:juniper:small',  15, -5, player_id)

   -- place some boulders.  those can be harvested, too!
   self:place_item('stonehearth:boulder:large_1',  -25, 5, player_id)
   self:place_item('stonehearth:boulder:medium_1', -15, 5, player_id)
   self:place_item('stonehearth:boulder:small',   -5, 5, player_id)

   self:place_item('stonehearth:boulder:small',    5, 5, player_id)
       :add_component('mob'):turn_to(90)

   self:place_item('stonehearth:boulder:small',    15, 5, player_id)
       :add_component('mob'):turn_to(90)

   self:place_item('stonehearth:plants:berry_bush', -25, 15, player_id)
   self:place_item('stonehearth:plants:berry_bush', -15, 15, player_id)
   self:place_item('stonehearth:plants:silkweed',  -5, 15, player_id)

   -- add two workers.
   self:place_citizen(12, 12)
   self:place_citizen(14, 14)

   -- create a stockpile so the workers will have someplace to drop
   -- their stuff if you harvest a tree now.
   self:place_stockpile_cmd(player_id, 12, 12, 4, 4)
end

return HarvestTest

