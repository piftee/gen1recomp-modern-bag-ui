-- Visual smoke test. Run from the repository root:
--   SHOT_DIR=/tmp/modern-bag-ui \
--   POKEPORT_DRIVER=mods/modern_bag_ui/tests/preview_driver.lua \
--   POKEPORT_IDENTITY=modern-bag-preview POKEPORT_VERSION=red love .
return function(game)
  local U = dofile("tests/drivers/util.lua")
  local Bag = require("src.inventory.Bag")
  local Font = require("src.render.Font")
  local PaletteFX = require("src.render.PaletteFX")
  local Screens = require("src.ui.Screens")
  local TextBox = require("src.render.TextBox")
  local DIR = os.getenv("SHOT_DIR") or "/tmp/modern-bag-ui"

  love.window.setMode(1280, 720, {
    resizable = true, minwidth = 640, minheight = 576,
  })
  game.save.options = game.save.options or {}
  game.save.options.colors = "redpp"
  PaletteFX.setMode("redpp")
  game.save.inventory = {}
  game.save.bagOrder = nil
  game.save.money = 18420

  local inventory = {
    { "POTION", 7 }, { "SUPER_POTION", 3 }, { "ANTIDOTE", 4 },
    { "POKE_BALL", 12 }, { "GREAT_BALL", 5 },
    { "ESCAPE_ROPE", 2 }, { "REPEL", 6 }, { "FIRE_STONE", 1 },
    { "X_ATTACK", 2 }, { "DIRE_HIT", 1 },
    { "TM_THUNDERBOLT", 1 }, { "HM_CUT", 1 },
    { "BICYCLE", 1 }, { "TOWN_MAP", 1 }, { "ITEMFINDER", 1 },
  }
  for _, entry in ipairs(inventory) do
    if game.data.items[entry[1]] then
      Bag.add(game.save, entry[1], entry[2], game.data)
    end
  end

  while game.stack:top() do game.stack:pop() end
  local menu = Screens.push(game, "BagMenu", {})
  U.wait(12)
  U.log(menu.modernBagUI and "PASS modern Bag is active"
    or "FAIL modern Bag was not registered")
  U.shot(game, DIR .. "/modern_bag_all.png")

  -- Medicine pocket, with SUPER POTION selected for a populated details pane.
  menu:modernBagSwitchPocket(1)
  menu:modernBagSwitchPocket(1)
  menu.index = math.min(2, #menu.items)
  local medicineRows = {}
  for _, item in ipairs(menu.items) do medicineRows[#medicineRows + 1] = item.value end
  U.log("medicine rows:", table.concat(medicineRows, ", "))
  U.wait(8)
  U.shot(game, DIR .. "/modern_bag_medicine.png")

  -- Regression preview: DYNAMIC used to dock this classic 160px source rect
  -- against a wider Bag canvas and splice unrelated pixels into the box.
  game.save.options.uiLayout = "dynamic"
  local box = TextBox.new(game, "It won't have\nany effect.")
  box.shown = {
    Font.encode("It won't have"), Font.encode("any effect."),
  }
  box.done, box.waiting, box.blink = true, false, 31
  game.stack:push(box)
  U.wait(8)
  U.shot(game, DIR .. "/modern_bag_message.png")
  game.stack:pop()

  -- Key Items gives the palette and procedural artwork a second visual pass.
  for _ = 1, 3 do menu:modernBagSwitchPocket(1) end
  U.wait(8)
  U.shot(game, DIR .. "/modern_bag_key_items.png")

  -- The player's item-storage PC reuses the same pocket shell while keeping
  -- the native WITHDRAW/DEPOSIT/TOSS controllers underneath.
  while game.stack:top() do game.stack:pop() end
  game.save.pcItems = {
    POTION = 12, ANTIDOTE = 4, POKE_BALL = 18,
    ESCAPE_ROPE = 2, X_ATTACK = 3, TM_THUNDERBOLT = 1,
  }
  local pcRoot = Screens.push(game, "PlayerPC")
  pcRoot.items[1].onSelect()
  local pcList = game.stack:top()
  U.wait(8)
  U.log(pcList.modernPCUI and "PASS modern PC is active"
    or "FAIL modern PC list was not decorated")
  U.shot(game, DIR .. "/modern_pc_withdraw.png")

  -- Regression preview: opening DEPOSIT's amount selector must not apply a
  -- second responsive-layout offset to the PC surface underneath it.
  game.stack:pop()
  pcRoot.items[2].onSelect()
  pcList = game.stack:top()
  pcList.onChoose(pcList.items[pcList.index], pcList)
  local pcQuantity = game.stack:top()
  U.wait(8)
  U.shot(game, DIR .. "/modern_pc_deposit_quantity.png")
  game.stack:pop()
  pcQuantity.onDone(nil)

  -- Portrait phones use a taller native-pixel surface instead of centring a
  -- cramped 160x144 desktop composition between large black bars.
  love.window.setMode(480, 960, {
    resizable = true, minwidth = 160, minheight = 144,
  })
  pcList.modernBagPocket = 1
  pcList:modernBagRefresh(pcList.items[pcList.index]
    and pcList.items[pcList.index].value)
  U.wait(12)
  U.shot(game, DIR .. "/modern_pc_mobile_portrait.png")

  while game.stack:top() do game.stack:pop() end
  menu = Screens.push(game, "BagMenu", {})
  menu.modernBagPocket = 1
  menu:modernBagRefresh(menu.items[menu.index] and menu.items[menu.index].value)
  U.wait(12)
  U.shot(game, DIR .. "/modern_bag_mobile_portrait.png")

  menu.onChoose(menu.items[menu.index], menu)
  local action = game.stack:pop()
  action.items[2].onSelect()
  local quantity = game.stack:top()
  U.wait(8)
  U.shot(game, DIR .. "/modern_bag_mobile_toss_quantity.png")
  game.stack:pop()
  quantity.onDone(1)
  U.wait(8)
  U.shot(game, DIR .. "/modern_bag_mobile_toss_confirm.png")

  -- The alternate reference-inspired skin is selected from the normal
  -- Options menu and immediately applies to both responsive Bag layouts.
  love.window.setMode(1280, 720, {
    resizable = true, minwidth = 640, minheight = 576,
  })
  while game.stack:top() do game.stack:pop() end
  game.mods.modOptions = game.mods.modOptions or {}
  game.mods.modOptions.modern_bag_ui =
    game.mods.modOptions.modern_bag_ui or {}
  game.mods.modOptions.modern_bag_ui.skin = "modern"
  game.save.options.modOptions = game.save.options.modOptions or {}
  game.save.options.modOptions.modern_bag_ui =
    game.save.options.modOptions.modern_bag_ui or {}
  game.save.options.modOptions.modern_bag_ui.skin = "modern"
  local options = Screens.push(game, "OptionsMenu")
  local skinRow
  for index, row in ipairs(options.rows) do
    if row.id == "modern_bag_ui_skin" then
      skinRow = row
      options.index = index
      options.scroll = math.max(0, index - 4)
      break
    end
  end
  if skinRow then skinRow.step(game, 1) end
  U.wait(8)
  U.shot(game, DIR .. "/bag_skin_option.png")
  game.stack:pop()

  for _, id in ipairs({ "MOON_STONE", "NUGGET", "MAX_REPEL" }) do
    if game.data.items[id] and not game.save.inventory[id] then
      Bag.add(game.save, id, 1, game.data)
    end
  end
  menu = Screens.push(game, "BagMenu", {})
  menu:modernBagSwitchPocket(1)
  U.wait(12)
  U.log(menu:modernBagLayoutInfo().skin == "classic_pocket"
    and "PASS Pocket skin is active" or "FAIL Pocket skin did not activate")
  U.shot(game, DIR .. "/classic_pocket_bag_wide.png")

  -- Match the near-square reference aspect for the fidelity comparison.
  love.window.setMode(832, 720, {
    resizable = true, minwidth = 640, minheight = 576,
  })
  U.wait(12)
  U.shot(game, DIR .. "/classic_pocket_bag_reference.png")

  -- Every named pocket selects a different compartment in the source-derived
  -- five-pocket backpack. Keep one same-viewport capture per state for QA.
  for _, name in ipairs({ "medicine", "balls", "machines", "key" }) do
    menu:modernBagSwitchPocket(1)
    U.wait(8)
    U.shot(game, DIR .. "/classic_pocket_bag_" .. name .. ".png")
  end
  menu:modernBagSwitchPocket(-4)

  love.window.setMode(480, 960, {
    resizable = true, minwidth = 160, minheight = 144,
  })
  U.wait(12)
  U.shot(game, DIR .. "/classic_pocket_bag_mobile.png")
end
