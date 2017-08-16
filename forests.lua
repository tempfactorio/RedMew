global.chunks = {}
global.tree_n = 1
global.trees_permil_permin = 1
local spawn_radius = 6


local function register_chunk(event)
  table.insert(global.chunks, event.area.left_top)
  local chunk_pos = event.area.left_top
  local trees = game.surfaces[1].find_entities_filtered({area={top_left = {chunk_pos.x, chunk_pos.y}, bottom_right = {chunk_pos.x + 32, chunk_pos.y + 32}}, type = "tree"})
  for _,tree in pairs(trees) do
    if not string.match(tree.name, "dead") then
      global.tree_n = global.tree_n + 1
    end
  end
end

local function can_place(tree, pos)
  if not game.surfaces[1].can_place_entity{name = tree.name, position = pos} then return false end
  local ents = game.surfaces[1].find_entities_filtered({area={top_left = {pos.x - 1, pos.y - 1}, bottom_right = {pos.x + 1, pos.y + 1}}, type = "tree"})
  return #ents < 1
end

--for performance reason return 1 if successful
function grow_tree(tree)
  local pos = {x = tree.position.x + math.random(-spawn_radius, spawn_radius), y = tree.position.y + math.random(-spawn_radius, spawn_radius)}
  if can_place(tree, pos) then
    global.tree_n = global.tree_n + 1
    game.surfaces[1].create_entity({name = tree.name, position = pos})
    return 1
  end
  return 0
end

local function attempt_to_grow_trees(n, chunks, hops)
  local chunks = chunks or global.chunks
  if #chunks == 0 then return end
  local chunk_pos = chunks[math.random(#chunks)]
  local trees = game.surfaces[1].find_entities_filtered({area={top_left = {chunk_pos.x, chunk_pos.y}, bottom_right = {chunk_pos.x + 32, chunk_pos.y + 32}}, type = "tree"})
  local tree = {}
  local n_trees = #trees
  local id = 0
  while n > 0 and n_trees > 0 do
    id = math.random(n_trees)
    tree = trees[id]
    if not string.match(tree.name, "dead") then
      n = n - grow_tree(tree)
    end
    table.remove(trees, id)
    n_trees = n_trees - 1
  end
  --if trees are left, grow more
  if n > 0 then
    local hops = hops or 0
    hops = hops + 1
    if hops > 10 then
      return
    end
    attempt_to_grow_trees(n, chunks, hops)
  end
end

global.left_overs = 0
function forests_on_5_ticks()
  local trees_to_spawn = global.trees_permil_permin/1200000 * global.tree_n + global.left_overs
  global.left_overs = trees_to_spawn % 1
  local n = math.floor(trees_to_spawn)
  attempt_to_grow_trees(n)
end

local function entity_died(event)
  if string.match(event.entity.name, "tree") and (not string.match(event.entity.name, "dead")) then
    global.tree_n = global.tree_n - 1
  end
end
Event.register(defines.events.on_chunk_generated, register_chunk)
Event.register(defines.events.on_entity_died, entity_died)
Event.register(defines.events.on_player_mined_entity, entity_died)
Event.register(defines.events.on_robot_mined_entity, entity_died)
