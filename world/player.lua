-- world/player.lua
local Tilemap = require("world.tilemap")
local FX = require("lib.fx")

local Player = {
    x = 16,
    y = 16,
    w = 16,
    h = 16,
    speed = 60,
    sprite_id = 2,
    facing = "down",
    is_moving = false,
    anim_timer = 0,
    frame = 0
}

function Player.init(start_x, start_y)
    Player.x = start_x or 16
    Player.y = start_y or 16
end

function Player.update(dt)
    local dx = 0
    local dy = 0
    Player.is_moving = false

    -- Handle input (Usagi API: input.held / input.LEFT/RIGHT/UP/DOWN)
    if input.held(input.LEFT) then
        dx = -1
        Player.facing = "left"
        Player.is_moving = true
    elseif input.held(input.RIGHT) then
        dx = 1
        Player.facing = "right"
        Player.is_moving = true
    end

    if input.held(input.UP) then
        dy = -1
        Player.facing = "up"
        Player.is_moving = true
    elseif input.held(input.DOWN) then
        dy = 1
        Player.facing = "down"
        Player.is_moving = true
    end

    -- Normalize diagonal movement
    if dx ~= 0 and dy ~= 0 then
        local len = math.sqrt(dx*dx + dy*dy)
        dx = dx / len
        dy = dy / len
    end

    -- Calculate desired position
    local new_x = Player.x + dx * Player.speed * dt
    local new_y = Player.y + dy * Player.speed * dt

    -- Simple collision detection (check corners of the bounding box)
    -- We shrink the hitbox slightly to make moving through corridors easier
    local hitbox = {
        left = new_x + 2,
        right = new_x + Player.w - 2,
        top = new_y + 8,  -- Top of hitbox is lower to give pseudo-3D feel (feet collision)
        bottom = new_y + Player.h
    }

    local function check_collision(hx, hy)
        local tx, ty = Tilemap.world_to_tile(hx, hy)
        return Tilemap.is_solid(tx, ty)
    end

    local collides_x = check_collision(hitbox.left, Player.y + 8) or 
                       check_collision(hitbox.right, Player.y + 8) or
                       check_collision(hitbox.left, Player.y + Player.h) or
                       check_collision(hitbox.right, Player.y + Player.h)
                       
    local collides_y = check_collision(Player.x + 2, hitbox.top) or 
                       check_collision(Player.x + Player.w - 2, hitbox.top) or
                       check_collision(Player.x + 2, hitbox.bottom) or
                       check_collision(Player.x + Player.w - 2, hitbox.bottom)

    if not collides_x then
        Player.x = new_x
    end
    if not collides_y then
        Player.y = new_y
    end

    -- NOTE: Interaction handled in exploration state to avoid double-fire

    if Player.is_moving then
        Player.anim_timer = Player.anim_timer + dt
        if Player.anim_timer > 0.15 then
            Player.anim_timer = 0
            Player.frame = Player.frame + 1
            FX.spawn("dust", Player.x + 8, Player.y + 16, 0.5, 0)
        end
    end
end

function Player.draw()
    -- Draw shadow
    gfx.rect_fill(Player.x - (Camera.ox or 0) + 2, Player.y - (Camera.oy or 0) + 12, 12, 4, gfx.COLOR_BLACK)
    
    -- Draw sprite (frame cycle if moving)
    local draw_sprite = Player.sprite_id
    if Player.is_moving then
        draw_sprite = Player.sprite_id + (Player.frame % 2)
    end
    
    gfx.spr(draw_sprite, Player.x - (Camera.ox or 0), Player.y - (Camera.oy or 0))
end

return Player
