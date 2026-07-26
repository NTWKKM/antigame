local collision = {}

function collision.check_tile(map, x, y, width, height)
    -- Simplified AABB vs Tilemap collision
    if not map or not map.collisions then return false end
    
    local left = math.floor(x / 16)
    local right = math.floor((x + width - 1) / 16)
    local top = math.floor(y / 16)
    local bottom = math.floor((y + height - 1) / 16)
    
    for ty = top, bottom do
        for tx = left, right do
            if tx >= 0 and tx < map.width and ty >= 0 and ty < map.height then
                local idx = ty * map.width + tx + 1
                if map.collisions[idx] and map.collisions[idx] > 0 then
                    return true
                end
            end
        end
    end
    return false
end

function collision.check_aabb(a, b)
    return a.x < b.x + b.width and
           a.x + a.width > b.x and
           a.y < b.y + b.height and
           a.y + a.height > b.y
end

return collision
