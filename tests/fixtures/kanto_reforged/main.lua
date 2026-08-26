return function(mod)
  local Bag = require("src.inventory.Bag")
  local Builtin = require("src.ui.BagMenu")

  mod.options:define({
    { key = "bag_give", label = "BAG GIVE", type = "toggle",
      default = true },
  })
  mod.content.constants:patch("bagSize", 60)

  local pockets = { "items", "balls", "key", "tmhm", "berries" }
  local berries = { BERRY = true, CHERI_BERRY = true }
  local pocketIndex = 1
  local filterActive = false
  local originalOrder = Bag.order

  local function classify(game, id)
    local def = game.data.items[id] or {}
    if berries[id] then return "berries" end
    if def.machine then return "tmhm" end
    if def.keyItem then return "key" end
    if def.ball then return "balls" end
    return "items"
  end

  Bag.order = function(save)
    local order = originalOrder(save)
    if not filterActive then return order end
    local filtered = {}
    local game = mod.__fixtureGame
    for _, id in ipairs(order) do
      if game and classify(game, id) == pockets[pocketIndex] then
        filtered[#filtered + 1] = id
      end
    end
    return filtered
  end

  local function rebuild(list, game)
    local items = {}
    for _, id in ipairs(Bag.order(game.save)) do
      local def = game.data.items[id] or {}
      items[#items + 1] = {
        value = id, label = def.name or id,
        right = "x" .. tostring(game.save.inventory[id] or 0),
      }
    end
    items[#items + 1] = { cancel = true, label = "CANCEL" }
    list.items, list.index, list.scroll = items, 1, 0
    list.title = pockets[pocketIndex]
    list.__pocketIndex = pocketIndex
    list.__pocketIds = pockets
    list.onSelectKey = pockets[pocketIndex] == "tmhm" and nil
      or function() list.kantoReorderPreserved = true end
  end

  mod.content.screens:register("BagMenu", {
    new = function(game, opts)
      mod.__fixtureGame = game
      filterActive = true
      local list = Builtin.new(game, opts)
      rebuild(list, game)
      local choose = list.onChoose
      list.onChoose = function(item, active)
        if item and item.value == "CHERI_BERRY" then
          game.stack:push({
            kantoGiveMenu = true,
            items = {
              { label = "USE", onSelect = function() end },
              { label = "GIVE", onSelect = function()
                list.kantoGiveChosen = true
              end },
              { label = "TOSS", onSelect = function() end },
            },
          })
          return true
        end
        return choose(item, active)
      end
      list.gen1ModernUi = {
        switchPocket = function(_, delta)
          pocketIndex = ((pocketIndex - 1 + (delta or 0)) % #pockets) + 1
          rebuild(list, game)
          return true
        end,
      }
      local cancel = list.onCancel
      list.onCancel = function()
        filterActive = false
        list.kantoCancelPreserved = true
        if cancel then return cancel() end
      end
      return list
    end,
  })
end
