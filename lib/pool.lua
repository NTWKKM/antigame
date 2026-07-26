local pool = {}

function pool.new(create_func)
    return {
        items = {},
        create_func = create_func,
        
        get = function(self)
            if #self.items > 0 then
                return table.remove(self.items)
            end
            return self.create_func()
        end,
        
        recycle = function(self, item)
            table.insert(self.items, item)
        end
    }
end

return pool
