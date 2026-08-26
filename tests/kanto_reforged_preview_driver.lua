-- Live screenshot proof for Modern Bag UI + Kanto Reforged.
-- Run from the Gen1Recomp repository root with both mods installed:
--   SHOT_DIR=build \
--   POKEPORT_DRIVER=mods/modern_bag_ui/tests/kanto_reforged_preview_driver.lua \
--   POKEPORT_IDENTITY=modern-bag-kanto-give POKEPORT_VERSION=red love .
return function(game)
  local U = dofile("tests/drivers/util.lua")
  local Screens = require("src.ui.Screens")
  local shotDir = os.getenv("SHOT_DIR") or "/tmp/modern-bag-kanto"

  love.window.setMode(960, 720, {
    resizable = true, minwidth = 640, minheight = 576,
  })

  local kanto = game.mods and game.mods.mods
    and game.mods.mods["Kanto-Reforged"]
  U.log(kanto and "PASS Kanto Reforged is loaded"
    or "FAIL Kanto Reforged is not loaded")

  game.save.options = game.save.options or {}
  game.save.options.modOptions = game.save.options.modOptions or {}
  game.save.options.modOptions["Kanto-Reforged"] =
    game.save.options.modOptions["Kanto-Reforged"] or {}
  game.save.options.modOptions["Kanto-Reforged"].bag_give = true
  game.mods.modOptions = game.mods.modOptions or {}
  game.mods.modOptions["Kanto-Reforged"] =
    game.mods.modOptions["Kanto-Reforged"] or {}
  game.mods.modOptions["Kanto-Reforged"].bag_give = true

  game.save.inventory = { CHERI_BERRY = 2 }
  game.save.bagOrder = { "CHERI_BERRY" }
  game.save.money = 18420
  while game.stack:top() do game.stack:pop() end

  local bag = Screens.push(game, "BagMenu", {})
  for _ = 1, 5 do
    local pocket = bag.modernBagPockets
      and bag.modernBagPockets[bag.modernBagPocket]
    if pocket and pocket.key == "berries" then break end
    bag:modernBagSwitchPocket(1)
  end

  local berry
  for index, item in ipairs(bag.items or {}) do
    if item.value == "CHERI_BERRY" then
      berry = item
      bag.index = index
      break
    end
  end
  U.log(berry and "PASS CHERI BERRY is in the Berry pocket"
    or "FAIL CHERI BERRY is missing from the Berry pocket")
  if not berry then return end

  bag.onChoose(berry, bag)
  local action = game.stack:top()
  local labels = {}
  for _, row in ipairs(action and action.items or {}) do
    labels[#labels + 1] = tostring(row.label or "")
  end
  U.log("action rows:", table.concat(labels, " -> "))
  U.log(labels[1] == "USE" and labels[2] == "GIVE" and labels[3] == "TOSS"
    and "PASS Kanto GIVE action is visible"
    or "FAIL expected USE -> GIVE -> TOSS")
  U.wait(12)
  U.shot(game, shotDir .. "/kanto-reforged-give-action.png")
end
