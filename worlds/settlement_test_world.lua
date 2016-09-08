local MicroWorld = require 'micro_world'
local SettlementTest = class(MicroWorld)

local Point2 = _radiant.csg.Point2
local Point3 = _radiant.csg.Point3

function SettlementTest:__init()
   self[MicroWorld]:__init(1024)
   local rc = 'rayyas_children:kingdoms:rayyas_children'
   local kingdom = nil --rc
   self:create_world(kingdom)
   local player_id = self:get_session().player_id

   --stonehearth.game_creation:set_game_mode('stonehearth:game_mode:hard')

   local combat_attributes = {
      body = 5,
      spirit = 5
   }

   -- Create settlement with citizens
   -- Specify a citizen's class and how many of each to spawn
   self:create_settlement({
      knight = {
         num = 1,
         attributes = combat_attributes
      },
      footman = {
         num = 1,
         attributes = combat_attributes
      },
      cleric = {
         num = 1,
         attributes = combat_attributes
      },
      archer = 1,
      carpenter = 1,
      shepherd = 1,
      blacksmith = 1,
      worker = 1,
   })

   self:place_item('stonehearth:sheep', -3, -6)
   self:place_item('stonehearth:trees:oak:medium', -25, -25)
   self:place_item('stonehearth:carpenter:talisman', 0, 0, player_id, { force_iconic = true})

   local function create_stockpile(x, z)
      stonehearth.inventory:get_inventory(player_id)
                              :create_stockpile(Point3(x, 1, z), Point2(4, 4))
      self:place_item_cluster('stonehearth:furniture:comfy_bed', x, z, 4, 4, player_id)
   end
   self:place_item_cluster('stonehearth:construction:picket_fence', -4, 14, 4, 4, player_id )
   self:place_item_cluster('stonehearth:resources:wood:oak_log', 4, 14, 2, 3, player_id )

   create_stockpile(14, 14)
   create_stockpile(10, 8)
   create_stockpile(2, 16)

   local inventory = stonehearth.inventory:get_inventory(player_id)

   if inventory ~= nil then
      inventory:add_gold(10000)
   end

   -- send in the goblins!!
   radiant.set_realtime_timer("SettlementTest game master start", 5000, function()
         stonehearth.game_master:start()
      end)

   if true then return end

   self:place_citizen(2, 2)
   self:place_citizen(2, 2)
   self:place_citizen(2, 2)
   self:place_citizen(2, 2)

   self:place_item_cluster('stonehearth:resources:wood:oak_log', 8, 8, 7, 7)
   self:place_item_cluster('stonehearth:resources:stone:hunk_of_stone', -8, 8, 7, 7)
   self:place_item_cluster('stonehearth:portals:wooden_door_2', -2, -2, 2, 2)
   self:place_item_cluster('stonehearth:decoration:wooden_wall_lantern', -10, 10, 2, 2)
   self:place_item_cluster('stonehearth:furniture:comfy_bed', 2, 2, 2, 2)
   --if true then return end
   self:place_item_cluster('stonehearth:food:berries:berry_basket', -8, -8, 2, 2)
   self:place_item_cluster('stonehearth:portals:wooden_door', -8, 8, 1, 1)
   self:place_item_cluster('stonehearth:portals:wooden_window_frame', -12, 8, 2, 2)
   self:place_item_cluster('stonehearth:portals:wooden_diamond_window', -12, 12, 2, 2)
   
   --self:place_citizen(0, 0)
   if true then return end

   self:place_citizen(2, 2)
   self:place_citizen(2, 2)
   self:place_citizen(2, 2)
   self:place_citizen(2, 2)

   if true then return end   
   for i = -8, 8, 4 do
   self:place_citizen(0, i)
   end
end

function SettlementTest:place_combat_unit(x, y, job)
   local unit = self:place_citizen(x, y, job)
   radiant.entities.set_attribute(unit, 'body', 5)
   radiant.entities.set_attribute(unit, 'spirit', 5)
end

return SettlementTest


