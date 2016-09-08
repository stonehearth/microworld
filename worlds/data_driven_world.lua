local Point3 = _radiant.csg.Point3
-- localising for performance/maintenance reasons
local is_table, is_string, is_number = radiant.check.is_table, radiant.check.is_string, radiant.check.is_number

local MicroWorld = require 'micro_world'
local DataDriven = class(MicroWorld)

function DataDriven:__init()
   local index_reference = radiant.util.get_config('data_driven_index', 'microworld:data_driven:world:mini_game')
   self._config = radiant.resources.load_json(index_reference)
   
   -- World Creation
   self[MicroWorld]:__init(self:_get_config('world.size', 64))
   self:create_world()
end

-- Returns the value at `key_name` (which can contain sub-keys in the format
-- "root_key.sub_key.sub_sub_key") from `source`.
--  If any key cannot be found or the value's type is different, then 
--`default_value` is returned instead.
local function _get_value(source, key_name, default_value)
   is_table(source)
   is_string(key_name)
   local value = source
   for part in key_name:gmatch('([^.]+)') do
      value = value[part]
      if value == nil then
         return default_value
      end
   end
   
   -- This check only really works for non-table-values,
   -- as it does not verify that the table structure of 
   --  `value` is the same as `default_value`.
   -- Use subsequent calls to `_get_value` to achieve
   -- this kind of validation.
   if type(value) ~= type(default_value) then
      return default_value
   end
   
   return value
end

function DataDriven:start()
   -- Create additional terrain, if requested.
   -- `world.terrain` (Array) contains objects which are passed directly to `MicroWorld:create_terrain` 
   -- in terms of coordinates. The key `block_type` is used to determine what kind of block it creates.
   -- For more information on how this can be used, see `MicroWorld:create_terrain` or the example
   -- world (microworld:data_driven:world:terrain_test)
   for _, terrain in pairs(self:_get_config('world.terrain', {})) do
      is_string(terrain.block_type)
      self:create_terrain(terrain, terrain.block_type)
   end
   
   local player_id = self:get_session().player_id
   local pop = stonehearth.population:get_population(player_id)

   -- If world.town_position was set, embark
   if self._config.world.town_position then
      local town_x, town_z = self:_get_config('world.town_position.x', 0), self:_get_config('world.town_position.z', 0)
      self:place_town_banner(town_x, town_z, player_id)
   end
   
   -- entities (Array)
   -- Each entity may have the following properties:
   --  | `alias` (string, required): alias/entity reference of the entity
   --  |\  `position` (table, required): position of the entity
   --  | | `x` (number, required): x-position of the entity
   --  | | `z` (number, required): z-position of the entity
   --  |
   --  | `requires_owner` (boolean, optional): If set, this entity will have its owner set. Required for stonehearth:decoration:firepit. Default false.
   --  | `full_size` (boolean, optional): If set to `true` it will spawn a "real" entity, if set to `false` it spawns an iconic version. Default false.
   --  | `rotation` (number, optional): If set, the entity will be rotated by `rotation` degrees. Default 0.
   --  |
   --  |\  `repeat` (table, optional): if set, the entity will be spawned multiple times. This can be used to create clusters.
   --  | | `x` (number, optional): if set, the entity will be spawned `x`-times along the x-axis. Default 1.
   --  | | `z` (number, optional): if set, the entity will be spawned `z`-times along the z-axis. Default 1.
   --  |
   --  |\  `offset` (table, optional): deals with offset of clusters. Only effective if `repeat` was set.
   --  | | `x` (number, optional): if `repeat_x` is greater than 1, each entity is spawned `offset_x` away from the last one. Default 1.
   --  | | `y` (number, optional): if `repeat_x` is greater than 1, each entity is spawned `offset_x` away from the last one. Default 1.
   --  |
   --  | `equipment` (table, optional): if set, the entity will be equipped with each of the elements inside the array
   local entities = self:_get_config('entities', {})
   for _, entity_def in pairs(entities) do
      if type(entity_def) ~= 'table' then
         error('invalid entities-entry! Expected table, got ' .. type(entity_def))
      end
      
      local alias, position = entity_def.alias, entity_def.position
      
      is_table(position)
      
      local x, z = position.x, position.z
      
      -- Validation of these parameters, as they're horribly important and cannot default
      is_string(alias)
      is_number(x)
      is_number(z)
      
      -- To create "fields" of entities easily, repeat_x and repeat_z can be set to higher values
      local repeat_x, repeat_z = _get_value(entity_def, 'repeat.x', 1), _get_value(entity_def, 'repeat.z', 1)
      local offset_x, offset_z = _get_value(entity_def, 'offset.x', 1), _get_value(entity_def, 'offset.z', 1)
      
      -- Whether the owner-field needs to be set; this is currently required for the firepit and might
      -- be required for other player-created fields
      local owner = _get_value(entity_def, 'requires_owner', false) and player_id or nil
      local full_size = _get_value(entity_def, 'full_size', false)
      
      -- Optional stuff.
      local rotation = entity_def.rotation
      if rotation ~= nil then
         is_number(rotation)
      end
      
      local final_data = {
         owner = owner,
         full_size = full_size
      }
      
      local equipment = entity_def.equipment or {}
      
      -- We could use `microworld.place_entity_cluster` here, but will not do so as it
      -- does currently not support set spaces between entities.
      for x_inc = 0, repeat_x - 1 do
         for z_inc = 0, repeat_z - 1 do
            local entity = self:place_item(alias, x + x_inc * offset_x, z + z_inc * offset_z, player_id, final_data)
            
            if rotation then
               entity:add_component('mob'):turn_to(rotation)
            end
            
            for _, equip_ref in pairs(equipment) do
               radiant.entities.equip_item(entity, equip_ref)
            end
         end
      end
   end
   
   -- citizens (Array)
   -- Each citizen definition may have the following properties:
   --  \ 
   --  |\ `position` (table, required): The location of the citizen
   --  | | `x` (number, required): x-position of the worker
   --  | | `z` (number, required): z-position of the worker
   --  |
   --  | `carrying` (string; optional): alias/entity reference that the worker will carry
   --  | `job` (string, optional): job that the worker is immediately promoted to
   --  | 
   --  |\ `workshop` (table, optional): If set, a workshop for this worker is spawned too.
   --  | | `x` (number, required): x-position of the workshop
   --  | | `z` (number, required): z-position of the workshop
   --  |
   --  | `equipment` (table, optional): Items that will be equipped to this worker
   local citizens = self:_get_config('citizens', {})
   for _, citizen_def in pairs(citizens) do
      is_table(citizen_def.position)
      
      local x, z = citizen_def.position.x, citizen_def.position.z
      
      is_number(x)
      is_number(z)
      
      local worker = self:place_citizen(x, z, citizen_def.job)
      
      if citizen_def.carrying then
         is_string(citizen_def.carrying)
         local item = pop:create_entity(citizen_def.carrying)
         radiant.entities.pickup_item(worker, item)
      end
      
      if citizen_def.workshop then
         if not citizen_def.job then
            error('worker cannot have a workshop without a profession!')
         end
         
         is_table(citizen_def.workshop.position)
         
         local x, z = citizen_def.workshop.position.x, citizen_def.workshop.position.z
         
         is_number(x)
         is_number(z)
         
         self:create_workbench(worker, x, z)
      end
      
      -- 
      if citizen_def.equipment then
         for _, alias in pairs(citizen_def.equipment) do
            radiant.entities.equip_item(worker, alias)
         end
      end
   end
   
   -- stockpiles (Array)
   -- Each stockpile definition may have the following properties:
   --  |\  `position` (table, required): position of the stockpile
   --  | | `x` (number, required): x of the stockpile
   --  | | `z` (number, required): z of the stockpile
   --  |
   --  |\  `dimension` (table, required): dimension of the stockpile
   --  | | `width` (number, required): width of the stockpile
   --  | | `height` (number, required): height of the stockpile
   local stockpiles = self:_get_config('stockpiles', {})
   for _, stockpile_def in pairs(stockpiles) do
      is_table(stockpile_def.position)
      is_table(stockpile_def.dimension)
      
      local x, z, width, height = stockpile_def.position.x, stockpile_def.position.z, stockpile_def.dimension.width, stockpile_def.dimension.height
      
      is_number(x)
      is_number(z)
      is_number(width)
      is_number(height)
      
      self:place_stockpile_cmd(player_id, x, z, width, height)
   end
end

-- Returns a value from our source JSON
function DataDriven:_get_config(key_name, default_value)
   return _get_value(self._config, key_name, default_value)
end

return DataDriven
