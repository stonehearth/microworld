local MicroWorld = require 'micro_world'
local Point3 = _radiant.csg.Point3

local BuildingEditor = class(MicroWorld)

function BuildingEditor:__init()
   -- create a tiny world
   self[MicroWorld]:__init(128)
   self:create_world()

   local player_id = self:get_session().player_id
   local pop = stonehearth.population:get_population(player_id)

   -- create a settlement with a banner and firepit
   -- and 6 workers around the point(0,0)
   local workers = self:create_settlement({
                                              carpenter = {
                                                 num = 1,
                                                 level = 6
                                              },
                                              potter = {
                                                 num = 1,
                                                 level = 6
                                              },
                                              mason = {
                                                 num = 1,
                                                 level = 6
                                              },
                                              blacksmith = {
                                                 num = 1,
                                                 level = 6
                                              },
                                              weaver = {
                                                 num = 1,
                                                 level = 6
                                              },
                                              engineer = {
                                                 num = 1,
                                                 level = 6
                                              }
                                          }, 0, 0)

end

return BuildingEditor

