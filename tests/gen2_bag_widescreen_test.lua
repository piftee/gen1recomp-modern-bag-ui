-- Standalone: luajit mods/modern_bag_ui/tests/gen2_bag_widescreen_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local total, failed = 0, 0
local function eq(actual, expected, label)
  total = total + 1
  if actual ~= expected then
    failed = failed + 1
    io.stderr:write(("not ok %d - %s (expected %s, got %s)\n"):format(
      total, label, tostring(expected), tostring(actual)))
  else
    print(("ok %d - %s"):format(total, label))
  end
end

local nativePanelCalls = 0
local NativePackMenu = {
  POCKETS = {
    { id = "ITEM", label = "ITEMS" },
    { id = "BALL", label = "POKé BALLS" },
    { id = "KEY_ITEM", label = "KEY ITEMS" },
    { id = "TM_HM", label = "TM/HM" },
  },
}
function NativePackMenu.new(game)
  local menu = { game = game, rows = {}, pocketIndex = 1 }
  function menu:drawPanel()
    nativePanelCalls = nativePanelCalls + 1
  end
  return menu
end

local NativeItemPcMenu = {}
function NativeItemPcMenu.new(game)
  return { game = game, drawPanel = function() end }
end

package.loaded["src.ui.gen2.Chrome"] = {
  wrap = function(text) return { text } end,
}
package.loaded["src.render.Font"] = {
  width = function(text) return #tostring(text or "") * 8 end,
  encode = function() return {} end,
  advanceOf = function() return 8 end,
}
package.loaded["src.ui.gen2.PackMenu"] = NativePackMenu
package.loaded["src.ui.gen2.ItemPcMenu"] = NativeItemPcMenu

local translations = {}
love = { graphics = {
  setColor = function() end,
  rectangle = function() end,
  push = function() end,
  pop = function() end,
  scale = function() end,
  translate = function(x, y)
    translations[#translations + 1] = { x = x, y = y }
  end,
} }

local screens = {}
local skin = "classic_pocket"
local mod = {
  id = "modern_bag_ui",
  options = { get = function(_, key)
    return key == "skin" and skin or nil
  end },
  exports = {},
  log = { info = function() end },
  content = { screens = {
    get = function(_, id) return screens[id] end,
    register = function(_, id, record) screens[id] = record end,
    override = function(_, id, record) screens[id] = record end,
  } },
}

dofile("mods/modern_bag_ui/gen2.lua")(mod, {})
local game = { mods = { modOptions = {
  modern_bag_ui = { skin = "classic_pocket" },
} } }
local menu = screens.Gen2PackMenu.new(game)
menu:drawWidescreen(1776, 1332)

eq(nativePanelCalls, 1,
  "the Pocket skin still draws the source-faithful native Pack panel")
eq(translations[2] and translations[2].x, 18,
  "the 160px Pack is centred inside the 197px responsive surface")
eq(translations[2] and translations[2].y, 0,
  "centring does not vertically shift the native Pack panel")

skin = "modern"
game.mods.modOptions.modern_bag_ui.skin = "modern"
eq(menu.modernBagUI, true,
  "the widescreen fix keeps the Gen 2 Pack decoration installed")

if failed > 0 then
  error(("%d of %d Gen 2 Bag checks failed"):format(failed, total), 0)
end
print(("%d/%d Gen 2 Bag checks passed"):format(total, total))
