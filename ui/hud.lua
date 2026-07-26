-- ui/hud.lua
local HUD = {}

function HUD.draw()
    if not GameState then return end
    
    -- Top left corner: RES and UX
    local res_str = "RES: " .. tostring(GameState.res) .. "%"
    local ux_str = "UX:  " .. tostring(GameState.ux) .. "%"
    
    -- Draw shadow
    gfx.text(res_str, 3, 3, gfx.COLOR_BLACK)
    gfx.text(ux_str, 3, 13, gfx.COLOR_BLACK)
    
    -- Draw text
    gfx.text(res_str, 2, 2, gfx.COLOR_WHITE)
    local ux_color = GameState.ux > 80 and gfx.COLOR_RED or gfx.COLOR_YELLOW
    gfx.text(ux_str, 2, 12, ux_color)
    
    -- We can also draw party HP here if needed
end

return HUD
