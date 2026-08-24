-- Standalone: luajit mods/modern_bag_ui/tests/modern_bag_ui_test.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")
local Bag = require("src.inventory.Bag")
local Font = require("src.render.Font")
local ListMenu = require("src.ui.ListMenu")
local PaletteFX = require("src.render.PaletteFX")
local Runtime = require("src.mods.Runtime")

local data = T.fixtures.fresh()
data.strings = {
  ["Restores 20 HP to one POKéMON."] = "HEALS TWENTY HP.",
}
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
require("src.core.Strings").load(run.data)

local schema = run.loader.optionSchemas.modern_bag_ui or {}
T.eq(#schema, 1, "registers one Bag presentation choice")
T.eq(schema[1].key, "skin", "the skin setting has a stable saved key")
T.eq(schema[1].default, "modern", "existing installs keep the modern skin")
local optionGame = {
  save = { options = {} }, mods = run.loader,
}
local optionRows = Runtime.call("ui.options.rows",
  function(_, base) return base end, optionGame, { { id = "text_speed" } })
T.eq(optionRows[2] and optionRows[2].id, "modern_bag_ui_skin",
  "BAG SKIN appears in the normal Options menu")
T.eq(optionRows[2].value(optionGame), "MODERN",
  "the Options row reports the default skin")
optionRows[2].step(optionGame, 1)
T.eq(optionRows[2].value(optionGame), "POCKET",
  "the Options row switches to the reference-inspired skin")
T.eq(optionGame.save.options.modOptions.modern_bag_ui.skin,
  "classic_pocket", "the selected skin is persisted with mod options")
optionRows[2].step(optionGame, 1)
T.eq(optionRows[2].value(optionGame), "MODERN",
  "the Options row cycles back to the original skin")

local record = run.data.screens and run.data.screens.BagMenu
T.check(type(record) == "table" and type(record.new) == "function",
  "the BagMenu screen record is registered")
local pcRecord = run.data.screens and run.data.screens.PlayerPC
T.check(type(pcRecord) == "table" and type(pcRecord.new) == "function",
  "the native PlayerPC extension is registered")
T.eq(Bag.capacity(run.data), 255,
  "the Bag accepts the complete 255-id item space")

local expandedSave = { inventory = {}, bagOrder = {} }
T.check(Bag.add(expandedSave, "FIX_BIG_STACK", 999, run.data),
  "a new item stack can be acquired directly at x999")
T.eq(expandedSave.inventory.FIX_BIG_STACK, 999,
  "the expanded quantity is stored without changing save shape")
T.check(not Bag.add(expandedSave, "FIX_BIG_STACK", 1, run.data),
  "a Bag stack cannot grow past x999")
for i = 1, 24 do
  T.check(Bag.add(expandedSave, "FIX_SLOT_" .. i, 1, run.data),
    "expanded Bag slot " .. i .. " is available")
end
T.eq(Bag.slots(expandedSave), 25,
  "the Bag can carry more than the cartridge's 20 unique items")

local stack = { states = {} }
function stack:push(state) self.states[#self.states + 1] = state end
function stack:pop() return table.remove(self.states) end
function stack:top() return self.states[#self.states] end

local input = { pressed = {} }
function input:wasPressed(key) return self.pressed[key] == true end
function input:isDown() return false end

-- The extended Player PC delegates to the stock menus while raising their
-- unique-item limit and keeping each stored stack at x999.
local pcStack = { states = {} }
function pcStack:push(state) self.states[#self.states + 1] = state end
function pcStack:pop() return table.remove(self.states) end
function pcStack:top() return self.states[#self.states] end

local pcGame = {
  data = run.data,
  save = {
    inventory = { POTION = 3 }, bagOrder = { "POTION" },
    pcItems = { POTION = 998 },
  },
  stack = pcStack,
  input = input,
}
local pcMenu = pcRecord.new(pcGame)
pcStack:push(pcMenu)
T.eq(pcGame.data.field.pcItemCap, 255,
  "the item-storage PC accepts 255 unique stacks")
pcMenu.items[1].onSelect()
local withdrawList = pcStack:top()
T.eq(withdrawList.modernBagListConfig.direction, "PC TO BAG",
  "WITHDRAW keeps its transfer direction in the content presentation")
T.eq(withdrawList.modernBagListConfig.modePalette, "GREENMON",
  "WITHDRAW has a stable green operation accent")
T.eq(table.concat(withdrawList.modernBagListConfig.empty, "|"),
  "PC STORAGE|IS EMPTY",
  "WITHDRAW names empty PC storage instead of an ambiguous pocket")
local withdrawText = {}
local withdrawFontDraw = Font.draw
local withdrawPixels = love.graphics.getPixelDimensions
love.graphics.getPixelDimensions = function() return 1280, 720 end
Font.draw = function(text, ...)
  withdrawText[#withdrawText + 1] = tostring(text)
  return withdrawFontDraw(text, ...)
end
local withdrawDrawOK, withdrawDrawErr = pcall(withdrawList.draw, withdrawList)
Font.draw = withdrawFontDraw
love.graphics.getPixelDimensions = withdrawPixels
T.check(withdrawDrawOK,
  "the directional WITHDRAW view draws headlessly: "
    .. tostring(withdrawDrawErr))
T.check(table.concat(withdrawText, "|"):find("PC TO BAG", 1, true) ~= nil,
  "WITHDRAW repeats PC TO BAG inside the persistent detail area")
pcStack:pop()
pcMenu.items[2].onSelect()
local depositList = pcStack:top()
T.check(depositList ~= pcMenu and type(depositList.onChoose) == "function",
  "DEPOSIT ITEM still opens the native PC item list")
T.check(depositList.modernPCUI == true,
  "PC item lists use the modern Bag visual system")
T.eq(depositList.modernBagLayout, "pc-pockets",
  "the PC identifies its responsive pocket layout")
T.check(depositList:isWideBattleLayout(),
  "the PC owns its responsive canvas while native overlays are visible")
T.check(depositList.holdsUIAnchors == true,
  "PC quantity prompts stay inside the composed modern surface")
T.eq(depositList.modernBagListConfig.direction, "BAG TO PC",
  "DEPOSIT visibly reverses the transfer direction")
T.eq(depositList.modernBagListConfig.modePalette, "YELLOWMON",
  "DEPOSIT uses a different operation accent from WITHDRAW")
local pcLayout = depositList:modernBagLayoutInfo()
T.eq(pcLayout.rows, 5,
  "the classic-height PC layout reserves room for a readable status footer")
local pcDrawOK, pcDrawErr = pcall(depositList.draw, depositList)
T.check(pcDrawOK,
  "the modern PC list draws headlessly: " .. tostring(pcDrawErr))
local pcPixelDimensions = love.graphics.getPixelDimensions
love.graphics.getPixelDimensions = function() return 998, 1980 end
local mobilePCLayout = depositList:modernBagLayoutInfo()
T.check(mobilePCLayout.stacked and mobilePCLayout.showDetails,
  "the PC uses the Bag's stacked portrait layout on phones")
local mobilePCDrawOK, mobilePCDrawErr = pcall(depositList.draw, depositList)
love.graphics.getPixelDimensions = pcPixelDimensions
T.check(mobilePCDrawOK,
  "the portrait PC list draws headlessly: " .. tostring(mobilePCDrawErr))
depositList:modernBagSwitchPocket(1)
T.eq(#depositList.items, 0,
  "PC pocket tabs filter the current deposit source")
depositList:modernBagSwitchPocket(1)
T.eq(depositList.items[1] and depositList.items[1].value, "POTION",
  "the medicine PC pocket exposes the Potion")
depositList:modernBagSwitchPocket(-2)
T.eq(depositList.modernBagPocket, 1,
  "the PC can return to its complete All pocket")
depositList.onChoose(depositList.items[1], depositList)
local quantity = pcStack:top()
T.eq(quantity.max, 1,
  "deposit quantity is capped by the remaining space in an x999 PC stack")
T.check(type(quantity.draw) == "function",
  "the three-digit native quantity selector has a widened renderer")
local wideDrawOK, wideDrawErr = pcall(quantity.draw, quantity)
T.check(wideDrawOK,
  "the widened x999 quantity selector draws headlessly: "
    .. tostring(wideDrawErr))
pcStack:pop()
quantity.onDone(1)
T.eq(pcGame.save.pcItems.POTION, 999,
  "a PC stack can reach x999")
T.eq(pcGame.save.inventory.POTION, 2,
  "the deposited quantity is removed from the Bag")
local pcDepth = #pcStack.states
depositList.onChoose(depositList.items[1], depositList)
T.eq(#pcStack.states, pcDepth,
  "a full x999 PC stack does not open another quantity prompt")
T.check(depositList.footer ~= nil,
  "a full PC stack reports that no storage room remains")

local manyPCItems = {}
for i = 1, 50 do manyPCItems["FIX_PC_" .. i] = 1 end
local manyPCStack = { states = {} }
function manyPCStack:push(state) self.states[#self.states + 1] = state end
function manyPCStack:pop() return table.remove(self.states) end
function manyPCStack:top() return self.states[#self.states] end
local manyPCGame = {
  data = run.data,
  save = {
    inventory = { ANTIDOTE = 1 }, bagOrder = { "ANTIDOTE" },
    pcItems = manyPCItems,
  },
  stack = manyPCStack,
  input = input,
}
local manyPCMenu = pcRecord.new(manyPCGame)
manyPCStack:push(manyPCMenu)
manyPCMenu.items[2].onSelect()
local manyDepositList = manyPCStack:top()
manyDepositList.onChoose(manyDepositList.items[1], manyDepositList)
local manyQuantity = manyPCStack:pop()
manyQuantity.onDone(1)
T.eq(manyPCGame.save.pcItems.ANTIDOTE, 1,
  "the PC can store a 51st unique item")
T.eq(manyPCGame.save.inventory.ANTIDOTE, nil,
  "the new PC stack is removed from the Bag normally")

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
    options = {},
  },
  stack = stack,
  input = input,
}

local screen = record.new(game, {})
stack:push(screen)
T.check(screen.modernBagUI == true, "the modern presentation is installed")
T.eq(screen.modernBagLayout, "pockets", "the pocket layout is identified")
T.eq(#screen.modernBagPockets, 6,
  "All plus five real pockets match the five-part reference backpack")
T.eq(getmetatable(screen), ListMenu,
  "the screen keeps the original ListMenu-backed Bag controller")
T.check(screen.holdsUIAnchors == true,
  "responsive Bag messages stay inside the composed surface in Dynamic UI mode")
T.eq(#screen.items, #order,
  "the default All pocket preserves the complete acquisition-ordered list")
T.eq(screen.items[1].value, "ESCAPE_ROPE",
  "the All pocket retains the first acquired item")

local headerText = {}
local originalFontDraw = Font.draw
local originalHeaderPixelDimensions = love.graphics.getPixelDimensions
love.graphics.getPixelDimensions = function() return 1280, 720 end
Font.draw = function(text, x, y)
  if y == 4 then headerText[#headerText + 1] = tostring(text) end
end
local headerDrawOK, headerDrawErr = pcall(screen.draw, screen)
Font.draw = originalFontDraw
love.graphics.getPixelDimensions = originalHeaderPixelDimensions
T.check(headerDrawOK,
  "the simplified slot-count header draws headlessly: "
    .. tostring(headerDrawErr))
T.eq(table.concat(headerText, "|"), "BAG|7/255|ALL ITEMS",
  "the header shows the pocket label once and a single total/capacity count")

local expectedCategories = {
  ESCAPE_ROPE = "items", POTION = "medicine", ANTIDOTE = "medicine",
  POKE_BALL = "balls", X_ATTACK = "items", TM_FIX = "machines",
  TOWN_MAP = "key",
}
for id, expected in pairs(expectedCategories) do
  T.eq(screen:modernBagCategoryFor(id), expected,
    id .. " enters the " .. expected .. " pocket")
end

local graphics = love.graphics
local realPixelDimensions = graphics.getPixelDimensions
graphics.getPixelDimensions = function() return 1280, 720 end
local landscapeW, landscapeH = screen:uiSize()
T.eq(landscapeW, 256,
  "a 16:9 window exposes a 256x144 responsive Bag surface")
T.eq(landscapeH, 144,
  "a landscape Bag keeps the Game Boy screen height")

graphics.getPixelDimensions = function() return 998, 1980 end
local portraitW, portraitH = screen:uiSize()
T.eq(portraitW, 160,
  "a tall phone keeps the readable 160px Bag width")
T.eq(portraitH, 330,
  "a tall phone uses the full portrait height at the same integer scale")

-- Useful Bag can be installed alongside this mod, but FAITHFUL RATIO is an
-- engine display promise. On mobile it cannot resize the physical window, so
-- the Bag must explicitly give its responsive portrait canvas back and use
-- the native 160x144 surface while the option is enabled.
game.save.options.faithfulRes = 1
game.renderer = {
  uiSize = function() return portraitW, portraitH end,
  uiFill = true,
}
local faithfulW, faithfulH = screen:uiSize()
local faithfulLayout = screen:modernBagLayoutInfo()
T.eq(faithfulW, 160,
  "FAITHFUL RATIO keeps the Bag at the native Game Boy width")
T.eq(faithfulH, 144,
  "FAITHFUL RATIO rejects the tall mobile Bag surface")
T.eq(faithfulLayout.width, 160,
  "the faithful Bag layout ignores a stale responsive renderer width")
T.eq(faithfulLayout.height, 144,
  "the faithful Bag layout ignores a stale responsive renderer height")
T.eq(faithfulLayout.canvasHeight, 144,
  "the faithful Bag canvas remains exactly 160x144")
T.check(not faithfulLayout.stacked,
  "FAITHFUL RATIO uses the compact native composition")
local faithfulDrawOK, faithfulDrawErr = pcall(screen.draw, screen)
T.check(faithfulDrawOK,
  "the faithful Bag draws headlessly: " .. tostring(faithfulDrawErr))
T.eq(game.renderer.uiFill, false,
  "the faithful Bag cancels inherited fill scaling before presentation")

local faithfulOverlay = {
  draw = function() end,
}
stack:push(faithfulOverlay)
T.check(faithfulOverlay.__modernBagResponsiveOverlay == true,
  "native prompts are still adopted while FAITHFUL RATIO is enabled")
T.eq(select(1, faithfulOverlay:uiSize()), 160,
  "a faithful Bag prompt inherits the native width")
T.eq(select(2, faithfulOverlay:uiSize()), 144,
  "a faithful Bag prompt inherits the native height")
stack:pop()

game.save.options.faithfulRes = 0
game.renderer = nil
T.eq(select(2, screen:uiSize()), portraitH,
  "turning FAITHFUL RATIO off restores the responsive portrait Bag")

-- A transparent overlay may already declare the classic 160x144 surface.
-- It still belongs inside the Bag composition rather than replacing it.
local preSizedOverlay = {
  uiSize = function() return 160, 144 end,
  draw = function() end,
}
stack:push(preSizedOverlay)
T.check(preSizedOverlay.__modernBagResponsiveOverlay == true,
  "a pre-sized transparent overlay is adopted by the Bag surface")
T.eq(select(1, preSizedOverlay:uiSize()), portraitW,
  "the pre-sized overlay keeps the portrait Bag width")
T.eq(select(2, preSizedOverlay:uiSize()), portraitH,
  "the pre-sized overlay no longer shrinks the Bag to classic height")
stack:pop()

-- Visible touch controls reserve their occupied lower area before the Bag
-- chooses its native height, keeping the canvas at a larger integer scale.
local TouchControls = require("src.core.TouchControls")
local touchVisible, touchLayout = TouchControls.visible, TouchControls.layout
local touchDimensions = love.graphics.getDimensions
love.graphics.getPixelDimensions = function() return 480, 960 end
love.graphics.getDimensions = function() return 480, 960 end
TouchControls.visible = function() return true end
TouchControls.layout = function()
  local zone = { cy = 850, w = 160 }
  return { dpad = zone, a = zone, b = zone, start = zone, select = zone }
end
local touchW, touchH = screen:uiSize()
local touchBagLayout = screen:modernBagLayoutInfo()
TouchControls.visible, TouchControls.layout = touchVisible, touchLayout
love.graphics.getDimensions = touchDimensions
love.graphics.getPixelDimensions = function() return 998, 1980 end
T.eq(touchW, 160,
  "a touch-overlay phone keeps the readable Bag width")
T.eq(touchH, 320,
  "visible controls do not shrink the responsive Bag canvas")
T.eq(touchBagLayout.canvasHeight, 320,
  "the full-height canvas preserves its larger integer scale")
T.eq(touchBagLayout.height, 252,
  "the visible Bag composition ends above the covered control area")
game.renderer = { uiSize = function() return portraitW, portraitH end }
local portrait = screen:modernBagLayoutInfo()
T.check(portrait.stacked and portrait.showDetails,
  "portrait switches to the stacked list and item-detail layout")
T.eq(portrait.rows, 10,
  "portrait uses its extra height to expose more inventory rows")
T.check(portrait.detailY > portrait.listY + portrait.listH,
  "the mobile detail card sits below the list without overlapping it")
T.eq(portrait.footerY + portrait.footerH, portraitH,
  "the two-line mobile controls stay inside the bottom edge")
local portraitDrawOK, portraitDrawErr = pcall(screen.draw, screen)
T.check(portraitDrawOK,
  "the complete portrait Bag draws headlessly: " .. tostring(portraitDrawErr))
local portraitZones = screen:sgbPalettes(game) or {}
T.eq(portraitZones[1] and portraitZones[1].h, portraitH,
  "portrait palette coverage reaches the full mobile surface")
T.check(portraitZones[3] and portraitZones[3].y == portrait.detailY,
  "the stacked detail card receives the active pocket palette")
game.renderer = nil
graphics.getPixelDimensions = realPixelDimensions

local function press(key)
  input.pressed[key] = true
  screen:update(0)
  input.pressed[key] = nil
end

press("right")
T.eq(screen.modernBagPocket, 2, "RIGHT opens the general Items pocket")
T.eq(#screen.items, 2,
  "the Items pocket includes general and battle-use items")
T.eq(screen.items[1].value, "ESCAPE_ROPE",
  "the general item remains visible in its pocket")
T.eq(screen.items[2].value, "X_ATTACK",
  "battle enhancers fold into Items instead of creating a sixth sprite pocket")

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
T.check(actionMenu.__modernBagResponsiveOverlay == true,
  "the USE/TOSS menu retains the responsive Bag surface")
stack:pop()
actionMenu.items[2].onSelect()
local bagQuantity = stack:top()
T.eq(screen.modernBagPrompt, "How many?",
  "TOSS displays its quantity prompt in the modern footer")
T.check(bagQuantity.__modernBagResponsiveOverlay == true,
  "the toss quantity box retains the Bag's responsive position")
T.eq(screen:modernBagLayoutInfo().rows, 5,
  "a visible Bag prompt reserves a second footer line")
local promptDrawOK, promptDrawErr = pcall(screen.draw, screen)
T.check(promptDrawOK,
  "the Bag draws with its quantity prompt: " .. tostring(promptDrawErr))
local bagOverlayPixels = love.graphics.getPixelDimensions
love.graphics.getPixelDimensions = function() return 998, 1980 end
local overlayW, overlayH = bagQuantity:uiSize()
T.eq(overlayW, 160,
  "a native Bag overlay keeps the portrait surface width")
T.eq(overlayH, 330,
  "a native Bag overlay keeps the portrait surface height")
local overlayTranslations = {}
local overlayTranslate = love.graphics.translate
love.graphics.translate = function(x, y)
  overlayTranslations[#overlayTranslations + 1] = { x = x, y = y }
end
local overlayDrawOK, overlayDrawErr = pcall(bagQuantity.draw, bagQuantity)
love.graphics.translate = overlayTranslate
love.graphics.getPixelDimensions = bagOverlayPixels
T.check(overlayDrawOK,
  "the selection-anchored portrait quantity box draws headlessly: "
    .. tostring(overlayDrawErr))
T.eq(bagQuantity.__modernBagAnchorKind, "selection",
  "the quantity selector identifies itself as a selected-row pop-out")
T.eq(bagQuantity.__modernBagAnchorX, 107,
  "the portrait quantity selector stays inside the selected row's right edge")
T.eq(bagQuantity.__modernBagAnchorY, 60,
  "the portrait quantity selector follows the selected row vertically")
T.eq(overlayTranslations[1] and overlayTranslations[1].x, -13,
  "the native quantity box is translated to its row anchor")
T.eq(overlayTranslations[1] and overlayTranslations[1].y, -12,
  "the quantity box no longer floats in the centre of a tall Bag")
stack:pop()
bagQuantity.onDone(1)
local tossChoice = stack:top()
T.eq(screen.modernBagPrompt, "Toss POTION?",
  "TOSS displays its confirmation question behind YES/NO")
T.check(tossChoice.__modernBagResponsiveOverlay == true,
  "the YES/NO box retains the Bag's responsive position")
stack:pop()
tossChoice.onChoose(false)
T.eq(screen.modernBagPrompt, nil,
  "cancelling TOSS clears the confirmation prompt")
T.eq(game.save.inventory.POTION, 3,
  "cancelling TOSS leaves the item stack unchanged")

-- Long translated two-word names wrap in the detail card, and description
-- source strings pass through the engine translation catalog.
screen.items[2].label = "MAXIMUM POTION"
local detailPixels = love.graphics.getPixelDimensions
love.graphics.getPixelDimensions = function() return 1280, 720 end
local detailText = {}
local detailFontDraw = Font.draw
Font.draw = function(text) detailText[#detailText + 1] = tostring(text) end
local translatedDrawOK, translatedDrawErr = pcall(screen.draw, screen)
Font.draw = detailFontDraw
love.graphics.getPixelDimensions = detailPixels
T.check(translatedDrawOK,
  "translated two-line details draw headlessly: "
    .. tostring(translatedDrawErr))
local detailJoined = table.concat(detailText, "|")
local sawMaximumLine, sawPotionLine = false, false
for _, text in ipairs(detailText) do
  if text == "MAXIMUM" then sawMaximumLine = true end
  if text == "POTION" then sawPotionLine = true end
end
T.check(sawMaximumLine and sawPotionLine
    and not detailJoined:find("MAXIMUM POTION.", 1, true),
  "a long two-word item name wraps instead of ending in a dot")
T.check(detailJoined:find("HEALS", 1, true),
  "individual item descriptions use translated source strings")
screen.items[2].label = "POTION"

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

-- The alternative skin reflows the same live Bag and PC controllers into
-- the reference's side rail, white item sheet and bottom description card.
run.loader.modOptions.modern_bag_ui.skin = "classic_pocket"
local classicPixels = love.graphics.getPixelDimensions
love.graphics.getPixelDimensions = function() return 1280, 720 end
local classicLayout = screen:modernBagLayoutInfo()
T.eq(classicLayout.skin, "classic_pocket",
  "the selected Pocket skin changes the live Bag layout")
T.eq(classicLayout.rows, 5,
  "the wide Pocket skin preserves a five-row reference-like item sheet")
local classicDrawOK, classicDrawErr = pcall(screen.draw, screen)
T.check(classicDrawOK,
  "the wide Pocket skin draws headlessly: " .. tostring(classicDrawErr))
T.eq(screen.modernBagClassicPocketLabel, "Meds",
  "the Pocket rail uses the reference's compact title-case label")
T.eq(screen.modernBagClassicPocketArt, "medicine",
  "the Pocket backpack reflects the active Medicine category")
T.eq(screen.modernBagClassicPocketRegion, "medicine",
  "Medicine highlights its dedicated compartment in the five-pocket sprite")
local classicZones = screen:sgbPalettes(game) or {}
T.check(#classicZones >= 6,
  "the Pocket skin emits separate header, rail, icon and selection colors")
T.eq(classicZones[2].colors, run.data.palettes.palettes.PURPLEMON,
  "the Pocket skin title uses the reference's purple accent")
T.eq(classicZones[3].colors, run.data.palettes.palettes.BLUEMON,
  "the Pocket skin rail uses the reference's woven blue")
T.eq(classicZones[4].colors, run.data.palettes.palettes.GREENMON,
  "the Pocket skin backpack card uses a green accent")
T.eq(classicZones[5].colors, run.data.palettes.palettes.REDMON,
  "the active pocket frame uses the reference's red accent")
screen:modernBagSwitchPocket(-1)
local classicItemsOK, classicItemsErr = pcall(screen.draw, screen)
T.check(classicItemsOK,
  "the Pocket skin redraws after switching categories: "
    .. tostring(classicItemsErr))
T.eq(screen.modernBagClassicPocketLabel, "Items",
  "the rail label stays small and title-case in the Items pocket")
T.eq(screen.modernBagClassicPocketArt, "items",
  "the backpack emblem changes when the active pocket changes")
T.eq(screen.modernBagClassicPocketRegion, "items",
  "Items highlights a different source-sprite compartment")
love.graphics.getPixelDimensions = function() return 998, 1980 end
local classicPortrait = screen:modernBagLayoutInfo()
T.check(classicPortrait.stacked and classicPortrait.rows == 10,
  "the Pocket skin remains usable in a tall phone layout")
T.check(classicPortrait.topRail,
  "the portrait Pocket skin moves its selector above the item list")
T.eq(classicPortrait.railW, 160,
  "the portrait pocket selector uses the full readable width")
T.eq(classicPortrait.listX, 0,
  "the portrait item sheet no longer loses width to a side rail")
T.eq(classicPortrait.listW, 160,
  "portrait item names receive the complete screen width")
T.eq(classicPortrait.listY,
  classicPortrait.headerH + classicPortrait.railH,
  "the item sheet begins directly beneath the horizontal pocket selector")
local classicPortraitOK, classicPortraitErr = pcall(screen.draw, screen)
T.check(classicPortraitOK,
  "the portrait Pocket skin draws headlessly: "
    .. tostring(classicPortraitErr))
local classicPortraitZones = screen:sgbPalettes(game) or {}
T.eq(classicPortraitZones[3] and classicPortraitZones[3].w, 160,
  "the woven pocket strip palette spans the portrait width")
T.check((classicPortraitZones[5] and classicPortraitZones[5].w or 0) > 80,
  "the active portrait pocket label has a readable wide color frame")
T.eq(depositList:modernBagLayoutInfo().skin, "classic_pocket",
  "the selected skin also applies to PC item lists")
love.graphics.getPixelDimensions = classicPixels
run.loader.modOptions.modern_bag_ui.skin = "modern"

-- The current Useful Bag release also registers BagMenu at priority 100.
-- Its optional dependency must initialize first, after which Modern Bag takes
-- explicit presentation ownership without disabling either mod. Keep this as
-- a local fixture so the regression does not depend on a network checkout.
run.release()
local compatibilityData = T.fixtures.fresh()
compatibilityData.items.POTION = {
  id = "POTION", name = "POTION", price = 300,
}
local compatibilityRun = T.sdk.loadMods({
  "mods/modern_bag_ui/tests/fixtures/useful_bag",
  "mods/modern_bag_ui",
}, { data = compatibilityData, dev = true })
T.eq(#compatibilityRun.errors, 0,
  "Useful Bag and Modern Bag load together without a BagMenu collision")
T.check(compatibilityRun.loader.mods.useful_bag ~= nil,
  "the Useful Bag compatibility fixture remains enabled")
T.eq(compatibilityRun.data.constants.bagSize, 999,
  "Useful Bag's larger storage patch survives Modern Bag presentation")

local compatibilityStack = { states = {} }
function compatibilityStack:push(state)
  self.states[#self.states + 1] = state
end
function compatibilityStack:pop() return table.remove(self.states) end
function compatibilityStack:top() return self.states[#self.states] end
local compatibilityInput = {}
function compatibilityInput:wasPressed() return false end
function compatibilityInput:isDown() return false end
local compatibilityGame = {
  data = compatibilityRun.data,
  save = {
    inventory = { POTION = 1 }, bagOrder = { "POTION" }, money = 0,
    options = { faithfulRes = 0 }, party = {}, flags = {},
  },
  stack = compatibilityStack,
  input = compatibilityInput,
  mods = compatibilityRun.loader,
  renderer = {
    uiSize = function() return 160, 330 end,
    uiFill = true,
  },
}
local compatibilityRecord = compatibilityRun.data.screens.BagMenu
local compatibilityPixels = love.graphics.getPixelDimensions
love.graphics.getPixelDimensions = function() return 998, 1980 end
compatibilityRun.loader.modOptions.useful_bag = { fullscreen_menu = false }
local compatibilityScreen = compatibilityRecord.new(compatibilityGame, {})
T.check(compatibilityScreen.modernBagUI == true,
  "Modern Bag owns the shared presentation after Useful Bag loads")
T.eq(select(1, compatibilityScreen:uiSize()), 160,
  "Useful Bag's native-menu setting keeps the Bag width at 160")
T.eq(select(2, compatibilityScreen:uiSize()), 144,
  "Useful Bag's native-menu setting keeps the Bag height at 144")
local compatibilityDrawOK, compatibilityDrawErr = pcall(
  compatibilityScreen.draw, compatibilityScreen)
T.check(compatibilityDrawOK,
  "the Useful Bag native pop-out draws headlessly: "
    .. tostring(compatibilityDrawErr))
T.eq(compatibilityGame.renderer.uiFill, false,
  "Useful Bag's native pop-out cancels inherited fill scaling")
compatibilityRun.loader.modOptions.useful_bag.fullscreen_menu = true
T.eq(select(2, compatibilityScreen:uiSize()), 330,
  "Useful Bag's fullscreen setting restores the tall mobile Bag")
love.graphics.getPixelDimensions = compatibilityPixels
compatibilityRun.release()

PaletteFX.setMode(previousMode)
T.finish()
