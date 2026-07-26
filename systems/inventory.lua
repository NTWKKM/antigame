local inventory = {
    items = {},
    data_modules = {},
    core_fragments = {},
    currency = 0
}

function inventory.add_item(id, qty)
    qty = qty or 1
    if not inventory.items[id] then
        inventory.items[id] = 0
    end
    inventory.items[id] = inventory.items[id] + qty
end

function inventory.remove_item(id, qty)
    qty = qty or 1
    if inventory.items[id] and inventory.items[id] >= qty then
        inventory.items[id] = inventory.items[id] - qty
        if inventory.items[id] == 0 then
            inventory.items[id] = nil
        end
        return true
    end
    return false
end

function inventory.has_item(id, qty)
    qty = qty or 1
    return inventory.items[id] and inventory.items[id] >= qty
end

function inventory.add_currency(amt)
    inventory.currency = inventory.currency + amt
end

return inventory
