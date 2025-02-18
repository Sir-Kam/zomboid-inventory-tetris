if not __GLOBAL_ITEM_RETURN_SCOPE then

    local BaseScope = require("Notloc/ModScope/BaseScope")
    local ItemReturnScope = BaseScope:new()
    __GLOBAL_ITEM_RETURN_SCOPE = ItemReturnScope

    function ItemReturnScope:execute(playerObj, returnableItems, callback)
        local instance = {
            playerObj = playerObj,
            returnableItems = NotUtil.toTruthMap(returnableItems),
            returnActions = {}
        }

        local values = BaseScope.execute(self, callback, instance)

        for _, action in ipairs(instance.returnActions) do
            ISTimedActionQueue.add(action)
        end

        return unpack(values)
    end

    function ItemReturnScope.createReturnAction(playerObj, action)
        local instance = ItemReturnScope:getInstance()
        if instance.playerObj ~= playerObj then return end
        if not instance.returnableItems[action.item] then
            return
        end

        local returnAction = ISInventoryTransferAction:newReturnAction(playerObj, action.item, action.destContainer, action.srcContainer)
        table.insert(instance.returnActions, returnAction)
    end

    Events.OnGameStart.Add(function()
        local og_new = ISInventoryTransferAction.new
        
        ---@diagnostic disable-next-line: duplicate-set-field
        function ISInventoryTransferAction.new(self, character, ...)
            local o = og_new(self, character, ...)
            if ItemReturnScope:isActive() then
                ItemReturnScope.createReturnAction(character, o)
            end
            return o
        end

        function ISInventoryTransferAction.newReturnAction(self, character, ...)
            return og_new(self, character, ...)
        end
    end)
end

return __GLOBAL_ITEM_RETURN_SCOPE
