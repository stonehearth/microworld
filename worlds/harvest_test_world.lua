local HarvestTest = class()

function HarvestTest:start()
   microworld:create_world(64)

   -- place some trees around the world
   microworld:place_entity('stonehearth:trees:oak:large', -25, -25)
   microworld:place_entity('stonehearth:trees:oak:medium', -5, -25)
   microworld:place_entity('stonehearth:trees:oak:small',  15, -25)

   microworld:place_entity('stonehearth:trees:juniper:large', -25, -5)
   microworld:place_entity('stonehearth:trees:juniper:medium', -5, -5)
   microworld:place_entity('stonehearth:trees:juniper:small',  15, -5)

   -- place some boulders.  those can be harvested, too!
   microworld:place_entity('stonehearth:boulder:large_1',  -25, 5)
   microworld:place_entity('stonehearth:boulder:medium_1', -15, 5)
   microworld:place_entity('stonehearth:boulder:small',   -5, 5)

   microworld:place_entity('stonehearth:boulder:small',    5, 5)
       :add_component('mob'):turn_to(90)

   microworld:place_entity('stonehearth:boulder:small',    15, 5)
       :add_component('mob'):turn_to(90)

   microworld:place_entity('stonehearth:plants:berry_bush', -25, 15)
   microworld:place_entity('stonehearth:plants:berry_bush', -15, 15)
   microworld:place_entity('stonehearth:plants:silkweed',  -5, 15)

   -- add two workers.
   microworld:place_citizen(12, 12)
   microworld:place_citizen(14, 14)

   -- create a stockpile so the workers will have someplace to drop
   -- their stuff if you harvest a tree now.
   microworld:place_stockpile(12, 12, 4, 4)
end

return HarvestTest

