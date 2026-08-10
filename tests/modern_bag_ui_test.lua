-- Standalone: luajit mods/modern_bag_ui/tests/modern_bag_ui_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")
local Bag = require("src.inventory.Bag")
local Font = require("src.render.Font")
local ListMenu = require("src.ui.ListMenu")
local PaletteFX = require("src.render.PaletteFX")

local data = T.fixtures.fresh()
data.items.POTION = {
  id = "POTION", name = "POTION", price = 300,
}
data.items.ANTIDOTE = {
  id = "ANTIDOTE", name = "ANTIDOTE", price = 100,
}
data.items.POKE_BALL = {
  id = "POKE_BALL", name = "POKé BALL", price = 200,
  ball = "POKE_BALL",
}
data.items.X_ATTACK = {
  id = "X_ATTACK", name = "X ATTACK", price = 500,
}
data.items.TM_FIX = {
  id = "TM_FIX", name = "TM01", price = 3000,
  machine = { kind = "TM", number = 1, move = "FIX_CUT" },
}
data.items.TOWN_MAP = {
  id = "TOWN_MAP", name = "TOWN MAP", price = 0, keyItem = true,
}
data.items.ESCAPE_ROPE = {
  id = "ESCAPE_ROPE", name = "ESCAPE ROPE", price = 550,
}
data.palettes = {
  palettes = {
    BLUEMON = {
      { 255, 255, 255 }, { 150, 180, 235 },
      { 55, 95, 175 }, { 0, 0, 0 },
    },
    BROWNMON = {
      { 255, 255, 255 }, { 225, 180, 135 },
      { 155, 95, 45 }, { 0, 0, 0 },
    },
    GREENMON = {
      { 255, 255, 255 }, { 150, 220, 150 },
      { 30, 130, 45 }, { 0, 0, 0 },
    },
    REDMON = {
      { 255, 255, 255 }, { 240, 160, 145 },
      { 175, 45, 35 }, { 0, 0, 0 },
    },
    YELLOWMON = {
      { 255, 255, 255 }, { 245, 225, 120 },
      { 185, 145, 25 }, { 0, 0, 0 },
    },
    PURPLEMON = {
      { 255, 255, 255 }, { 210, 170, 230 },
      { 120, 65, 165 }, { 0, 0, 0 },
    },
    CYANMON = {
      { 255, 255, 255 }, { 165, 220, 230 },
      { 45, 135, 160 }, { 0, 0, 0 },
    },
    MEWMON = {
      { 255, 255, 255 }, { 210, 185, 235 },
      { 115, 75, 160 }, { 0, 0, 0 },
    },
  },
  pokemon = {},
}

Font.load(data)
local previousMode = PaletteFX.mode
PaletteFX.setMode("gbc")

local run = T.sdk.loadMod("mods/modern_bag_ui", { data = data, dev = true })
T.eq(#run.errors, 0, "loads clean (" .. tostring(run.errors[1]) .. ")")

local record = run.data.screens and run.data.screens.BagMenu
T.check(type(record) == "table" and type(record.new) == "function",
  "the BagMenu screen record is registered")

local stack = { states = {} }
function stack:push(state) self.states[#self.states + 1] = state end
function stack:pop() return table.remove(self.states) end
function stack:top() return self.states[#self.states] end

local input = { pressed = {} }
function input:wasPressed(key) return self.pressed[key] == true end
function input:isDown() return false end

local order = {
  "ESCAPE_ROPE", "POTION", "ANTIDOTE", "POKE_BALL",
  "X_ATTACK", "TM_FIX", "TOWN_MAP",
}
local inventory = {}
for _, id in ipairs(order) do inventory[id] = id == "POTION" and 3 or 1 end

local game = {
  data = run.data,
  save = {
    inventory = inventory, bagOrder = order,
    money = 4321, player = { name = "RED" }, party = {}, flags = {},
  },
  stack = stack,
  input = input,
}

local screen = record.new(game, {})
stack:push(screen)
T.check(screen.modernBagUI == true, "the modern presentation is installed")
T.eq(screen.modernBagLayout, "pockets", "the pocket layout is identified")
T.eq(getmetatable(screen), ListMenu,
  "the screen keeps the original ListMenu-backed Bag controller")
T.check(screen.holdsUIAnchors == true,
  "responsive Bag messages stay inside the composed surface in Dynamic UI mode")
T.eq(#screen.items, #order,
  "the default All pocket preserves the complete acquisition-ordered list")
T.eq(screen.items[1].value, "ESCAPE_ROPE",
  "the All pocket retains the first acquired item")

local expectedCategories = {
  ESCAPE_ROPE = "items", POTION = "medicine", ANTIDOTE = "medicine",
  POKE_BALL = "balls", X_ATTACK = "battle", TM_FIX = "machines",
  TOWN_MAP = "key",
}
for id, expected in pairs(expectedCategories) do
  T.eq(screen:modernBagCategoryFor(id), expected,
    id .. " enters the " .. expected .. " pocket")
end

local graphics = love.graphics
local realPixelDimensions = graphics.getPixelDimensions
graphics.getPixelDimensions = function() return 1280, 720 end
T.eq(select(1, screen:uiSize()), 256,
  "a 16:9 window exposes a 256x144 responsive Bag surface")
graphics.getPixelDimensions = realPixelDimensions

local function press(key)
  input.pressed[key] = true
  screen:update(0)
  input.pressed[key] = nil
end

press("right")
T.eq(screen.modernBagPocket, 2, "RIGHT opens the general Items pocket")
T.eq(#screen.items, 1, "the Items pocket filters out the other categories")
T.eq(screen.items[1].value, "ESCAPE_ROPE",
  "the general item remains visible in its pocket")

press("right")
T.eq(screen.modernBagPocket, 3, "RIGHT advances to Medicine")
T.eq(#screen.items, 2, "the Medicine pocket contains both remedies")
T.eq(screen.items[1].value, "POTION", "Medicine preserves acquisition order")
press("down")
T.eq(screen.items[screen.index].value, "ANTIDOTE",
  "UP/DOWN navigates within the active pocket")
press("right")
press("left")
T.eq(screen.items[screen.index].value, "ANTIDOTE",
  "each pocket remembers its selected item")

-- Filtered reordering maps item ids back into bagOrder instead of treating a
-- pocket-local row number as a global inventory position.
press("select")
T.eq(screen.modernBagSwapId, "ANTIDOTE", "SELECT marks the source medicine")
press("up")
press("a")
T.eq(screen.modernBagSwapId, nil, "A completes a pending filtered reorder")
T.eq(game.save.bagOrder[2], "ANTIDOTE",
  "the selected medicine moved to the target's global acquisition slot")
T.eq(game.save.bagOrder[3], "POTION",
  "the target medicine moved to the source's global acquisition slot")
T.eq(screen.items[1].value, "ANTIDOTE",
  "the active pocket immediately reflects the new order")

-- A normal choice still goes through the native USE/TOSS controller.
screen.index = 2 -- POTION
press("a")
local actionMenu = stack:top()
T.check(actionMenu ~= screen and actionMenu.items
    and actionMenu.items[1].label == "USE"
    and actionMenu.items[2].label == "TOSS",
  "choosing an item still opens the built-in USE/TOSS menu")
stack:pop()

-- Inventory changes made by the native item controller are synchronized back
-- into both quantities and pocket contents without changing save format.
Bag.remove(game.save, "POTION", 1)
local drawOK, drawErr = pcall(screen.draw, screen)
T.check(drawOK, "the complete Bag draws headlessly: " .. tostring(drawErr))
T.eq(screen.items[2].right, "x2", "live quantities refresh in the pocket")

local zones = screen:sgbPalettes(game) or {}
T.check(#zones >= 3, "the Bag emits base, pocket and detail palette regions")
T.eq(zones[1].w, 160, "palette coverage follows the active UI surface")
T.eq(zones[2].colors, run.data.palettes.palettes.GREENMON,
  "the Medicine pocket applies its own accent palette")
T.check(screen:isWideBattleLayout(),
  "the Bag keeps its responsive surface when opened during a battle")

PaletteFX.setMode(previousMode)
T.finish()
