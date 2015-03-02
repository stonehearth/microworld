local Point3 = _radiant.csg.Point3
-- localising for performance/maintenance reasons
local is_table, is_string, is_number = radiant.check.is_table, radiant.check.is_string, radiant.check.is_number

local DataDriven = class()

function DataDriven:__init()
   local index_reference = radiant.util.get_config('data_driven_index', 'microworld:data_driven:world:mini_game')
   
   self._config = radiant.resources.load_json(index_reference)
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
   -- World creation
   microworld:create_world(self:_get_config('world.size', 64))

   local player_id = microworld:get_local_player_id()
   local pop = stonehearth.population:get_population(player_id)

   -- If world.town_position was set, embark
   if self._config.world.town_position then
      local town_x, town_z = self:_get_config('world.town_position.x', 0), self:_get_config('world.town_position.z', 0)
      microworld:place_town_banner(town_x, town_z)
   end
   
   -- entities (Array)
   -- Each entity may have the following properties:
   --    `entity_ref` (string, required): alias/entity reference of the entity
   --    `x` (number, required): x-position of the entity
   --    `z` (number, required): z-position of the entity
   -- 
   --    `requires_owner` (boolean, optional): If set, this entity will have its owner set. Required for stonehearth:decoration:firepit. Default false.
   --    `full_size` (boolean, optional): If set to `true` it will spawn a "real" entity, if set to `false` it spawns an iconic version. Default false.
   --    `rotation` (number, optional): If set, the entity will be rotated by `rotation` degrees. Default 0.
   --
   --    It's possible to create clusters using the following properties:
   --    `repeat_x` (number, optional): if set, the entity will be spawned `repeat_x`-times along the x-axis. Default 1.
   --    `repeat_z` (number, optional): if set, the entity will be spawned `repeat_z`-times along the z-axis. Default 1.
   --    `offset_x` (number, optional): if `repeat_x` is greater than 1, each entity is spawned `offset_x` away from the last one. Default 1.
   --    `offset_x` (number, optional): if `repeat_x` is greater than 1, each entity is spawned `offset_x` away from the last one. Default 1.
   --
   --    Optionally, the entity may also have an array that contains items that will be equipped to the spawned entity.
   --    this only makes sense for NPCs.
   --    `equipment` (table, optional): if set, the entity will be equipped with each of the elements inside the array
   local entities = self:_get_config('entities', {})
   for _, entity_def in pairs(entities) do
      if type(entity_def) ~= 'table' then
         error('invalid entities-entry! Expected table, got ' .. type(entity_def))
      end
      
      local entity_ref, x, z = entity_def.entity_ref, entity_def.x, entity_def.z
      
      -- Validation of these parameters, as they're horribly important and cannot default
      is_string(entity_ref)
      is_number(x)
      is_number(z)
      
      -- To create "fields" of entities easily, repeat_x and repeat_z can be set to higher values
      local repeat_x, repeat_z = _get_value(entity_def, 'repeat_x', 1), _get_value(entity_def, 'repeat_z', 1)
      local offset_x, offset_z = _get_value(entity_def, 'offset_x', 1), _get_value(entity_def, 'offset_z', 1)
      
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
            local entity = microworld:place_entity(entity_ref, x + x_inc * offset_x, z + z_inc * offset_z, final_data)
            
            if rotation then
               entity:add_component('mob'):turn_to(rotation)
            end
            
            for _, equip_ref in pairs(equipment) do
               radiant.entities.equip_item(entity, equip_ref)
            end
         end
      end
   end
   
   -- workers (Array)
   -- Each worker definition may have the following properties:
   --  \ `x` (number, required): x-position of the worker
   --  | `z` (number, required): z-position of the worker
   --  | `carrying` (string; optional): alias/entity reference that the worker will carry
   --  | `job` (string, optional): job that the worker is immediately promoted to
   --  | 
   --  |\ `workshop` (table, optional): If set, a workshop for this worker is spawned too.
   --  | | `x` (number, required): x-position of the workshop
   --  | | `z` (number, required): z-position of the workshop
   --  |
   --  | `equipment` (table, optional): Items that will be equipped to this worker
   local workers = self:_get_config('workers', {})
   for _, worker_def in pairs(workers) do
      local x, z = worker_def.x, worker_def.z
      
      is_number(x)
      is_number(z)
      
      local worker = microworld:place_citizen(x, z, worker_def.job)
      
      if worker_def.carrying then
         is_string(worker_def.carrying)
         local item = pop:create_entity(worker_def.carrying)
         radiant.entities.pickup_item(worker, item)
      end
      
      if worker_def.workshop then
         if not worker_def.job then
            error('worker cannot have a workshop without a profession!')
         end
         
         local x, z = worker_def.workshop.x, worker_def.workshop.z
         
         is_number(x)
         is_number(z)
         
         microworld:create_workbench(worker, x, z)
      end
      
      -- 
      if worker_def.equipment then
         for _, entity_ref in pairs(worker_def.equipment) do
            radiant.entities.equip_item(worker, entity_ref)
         end
      end
   end
   
   -- stockpiles (Array)
   -- Each stockpile definition may have the following properties:
   --    `x` (number, required): x of the stockpile
   --    `z` (number, required): z of the stockpile
   --    `width` (number, required): width of the stockpile
   --    `height` (number, required): height of the stockpile
   local stockpiles = self:_get_config('stockpiles', {})
   for _, stockpile_def in pairs(stockpiles) do
      local x, z, width, height = stockpile_def.x, stockpile_def.z, stockpile_def.width, stockpile_def.height
      
      is_number(x)
      is_number(z)
      is_number(width)
      is_number(height)
      
      microworld:place_stockpile(x, z, width, height)
   end
end

-- Returns a value from our source JSON
function DataDriven:_get_config(key_name, default_value)
   return _get_value(self._config, key_name, default_value)
end

return DataDriven
