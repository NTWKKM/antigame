-- world/tilemap.lua
local Tilemap = {
    data = nil,
    collisions = nil,
    objects = nil,
    width = 0,
    height = 0,
    tile_size = 16
}

function Tilemap.init()
end

function Tilemap.load(map_name)
    local path = "maps/" .. map_name .. ".json"
    local map_data = usagi.read_json(path)
    
    if map_data then
        for _, layer in ipairs(map_data.layers) do
            if layer.name == "ground" then
                Tilemap.data = layer.data
            elseif layer.name == "collisions" then
                Tilemap.collisions = layer.data
            elseif layer.name == "objects" then
                Tilemap.objects = layer.objects
            end
        end
        Tilemap.width = map_data.width
        Tilemap.height = map_data.height
        Tilemap.tile_size = map_data.tilewidth or 16
        print("Loaded map: " .. map_name)
    else
        print("Failed to load map: " .. map_name)
    end
end

function Tilemap.get_tile(tx, ty)
    if tx < 0 or tx >= Tilemap.width or ty < 0 or ty >= Tilemap.height then
        return nil
    end
    local index = 1 + tx + (ty * Tilemap.width)
    return Tilemap.data and Tilemap.data[index]
end

function Tilemap.is_solid(tx, ty)
    if tx < 0 or tx >= Tilemap.width or ty < 0 or ty >= Tilemap.height then
        return true
    end
    if not Tilemap.collisions then return false end
    local index = 1 + tx + (ty * Tilemap.width)
    return Tilemap.collisions[index] and Tilemap.collisions[index] > 0
end

-- Convert world coordinates to tile coordinates
function Tilemap.world_to_tile(wx, wy)
    return math.floor(wx / Tilemap.tile_size), math.floor(wy / Tilemap.tile_size)
end

function Tilemap.draw()
    if not Tilemap.data then return end
    
    -- Optimization: Only draw visible tiles based on Camera
    local cam_x, cam_y = Camera.ox or 0, Camera.oy or 0
    
    local start_tx = math.max(0, math.floor(cam_x / Tilemap.tile_size))
    local start_ty = math.max(0, math.floor(cam_y / Tilemap.tile_size))
    local end_tx = math.min(Tilemap.width - 1, start_tx + math.ceil(usagi.GAME_W / Tilemap.tile_size))
    local end_ty = math.min(Tilemap.height - 1, start_ty + math.ceil(usagi.GAME_H / Tilemap.tile_size))
    
    for ty = start_ty, end_ty do
        for tx = start_tx, end_tx do
            local tile_id = Tilemap.get_tile(tx, ty)
            if tile_id and tile_id > 0 then
                -- Assuming tile_id directly maps to sprite index (1-based or 0-based depending on JSON generator)
                -- Usually Tiled exports with 1-based IDs, but our sprite indices are 0-based? Let's assume 1-based for Usagi sprite atlas.
                local dx = tx * Tilemap.tile_size - cam_x
                local dy = ty * Tilemap.tile_size - cam_y
                gfx.spr(tile_id, dx, dy)
            end
        end
    end
end

return Tilemap
