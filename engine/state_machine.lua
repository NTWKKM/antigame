-- engine/state_machine.lua
local StateMachine = {
    states = {},
    stack = {}
}

function StateMachine.init()
    -- Register real states
    StateMachine.register("EXPLORATION", require("states.exploration"))
    StateMachine.register("BATTLE", require("states.battle"))
end

function StateMachine.register(name, state_table)
    StateMachine.states[name] = state_table
end

function StateMachine.swap(name, ...)
    local next_state = StateMachine.states[name]
    if not next_state then
        error("State '" .. tostring(name) .. "' not found!")
        return
    end

    local top = StateMachine.stack[#StateMachine.stack]
    if top and top.exit then
        top.exit()
    end
    
    if #StateMachine.stack > 0 then
        table.remove(StateMachine.stack)
    end
    table.insert(StateMachine.stack, next_state)

    if next_state.enter then
        next_state.enter(...)
    end
end

function StateMachine.push(name, ...)
    local next_state = StateMachine.states[name]
    if not next_state then
        error("State '" .. tostring(name) .. "' not found!")
        return
    end

    table.insert(StateMachine.stack, next_state)
    if next_state.enter then
        next_state.enter(...)
    end
end

function StateMachine.pop()
    local top = StateMachine.stack[#StateMachine.stack]
    if top then
        if top.exit then
            top.exit()
        end
        table.remove(StateMachine.stack)
    end
end

function StateMachine.update(dt)
    local top = StateMachine.stack[#StateMachine.stack]
    if top and top.update then
        top.update(dt)
    end
end

function StateMachine.draw(dt)
    local top = StateMachine.stack[#StateMachine.stack]
    if top and top.draw then
        top.draw(dt)
    end
end

function StateMachine.draw_ui(dt)
    local top = StateMachine.stack[#StateMachine.stack]
    if top and top.draw_ui then
        top.draw_ui(dt)
    end
end

return StateMachine
