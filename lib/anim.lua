local anim = {}

function anim.new(frames, speed, loop)
    return {
        frames = frames or {1},
        speed = speed or 10,
        loop = loop ~= false,
        timer = 0,
        index = 1,
        finished = false,
        
        update = function(self, dt)
            if self.finished then return end
            self.timer = self.timer + dt
            local delay = 1.0 / self.speed
            if self.timer >= delay then
                self.timer = self.timer - delay
                self.index = self.index + 1
                if self.index > #self.frames then
                    if self.loop then
                        self.index = 1
                    else
                        self.index = #self.frames
                        self.finished = true
                    end
                end
            end
        end,
        
        get_frame = function(self)
            return self.frames[self.index]
        end,
        
        reset = function(self)
            self.index = 1
            self.timer = 0
            self.finished = false
        end
    }
end

return anim
