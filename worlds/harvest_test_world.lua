local HarvestTest = class()

function HarvestTest:start()
   microworld:create_world(64)

   -- place some trees around the world
   microworld:place_entity('stonehearth:large_oak_tree', -25, -25)
   microworld:place_entity('stonehearth:medium_oak_tree', -5, -25)
   microworld:place_entity('stonehearth:small_oak_tree',  15, -25)

   microworld:place_entity('stonehearth:large_juniper_tree', -25, -5)
   microworld:place_entity('stonehearth:medium_juniper_tree', -5, -5)
   microworld:place_entity('stonehearth:small_juniper_tree',  15, -5)

   -- place some boulders.  those can be harvested, too!
   microworld:place_entity('stonehearth:large_boulder_1',  -25, 5)
   microworld:place_entity('stonehearth:medium_boulder_1', -15, 5)
   microworld:place_entity('stonehearth:small_boulder',   -5, 5)

   microworld:place_entity('stonehearth:small_boulder',    5, 5)
       :add_component('mob'):turn_to(90)

   microworld:place_entity('stonehearth:small_boulder',    15, 5)
       :add_component('mob'):turn_to(90)

   microworld:place_entity('stonehearth:berry_bush', -25, 15)
   microworld:place_entity('stonehearth:berry_bush', -15, 15)
   microworld:place_entity('stonehearth:plants:silkweed',  -5, 15)

   -- add two workers.
   microworld:place_citizen(12, 12)
   microworld:place_citizen(14, 14)

   -- create a stockpile so the workers will have someplace to drop
   -- their stuff if you harvest a tree now.
   microworld:place_stockpile(12, 12, 4, 4)
end

return HarvestTest

