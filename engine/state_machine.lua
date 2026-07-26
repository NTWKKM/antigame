-- engine/state_machine.lua
local StateMachine = {
    states = {},
    current_state_name = nil,
    current_state = nil
}

function StateMachine.init()
    -- Register real states
    StateMachine.register("EXPLORATION", require("states.exploration"))
    StateMachine.register("BATTLE", require("states.battle"))
end

function StateMachine.register(name, state_table)
    StateMachine.states[name] = state_table
end

function StateMachine.switch(name, ...)
    local next_state = StateMachine.states[name]
    if not next_state then
        error("State '" .. tostring(name) .. "' not found!")
        return
    end

    if StateMachine.current_state and StateMachine.current_state.exit then
        StateMachine.current_state.exit()
    end

    StateMachine.current_state_name = name
    StateMachine.current_state = next_state

    if StateMachine.current_state.enter then
        StateMachine.current_state.enter(...)
    end
end

function StateMachine.update(dt)
    if StateMachine.current_state and StateMachine.current_state.update then
        StateMachine.current_state.update(dt)
    end
end

function StateMachine.draw(dt)
    if StateMachine.current_state and StateMachine.current_state.draw then
        StateMachine.current_state.draw(dt)
    end
end

function StateMachine.draw_ui(dt)
    if StateMachine.current_state and StateMachine.current_state.draw_ui then
        StateMachine.current_state.draw_ui(dt)
    end
end

return StateMachine
