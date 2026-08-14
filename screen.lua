-- Pocket-based presentation for src/ui/BagMenu.
--
-- The built-in BagMenu already owns a large and delicate behavior surface:
-- item targeting, battle turns, field actions, toss confirmation, scripted
-- tutorial input and several screens opened after item use. This module wraps
-- that controller instead of duplicating it. Only the visible list, drawing,
-- left/right pocket navigation and filtered-list reordering live here.
return function(mod)
  local BagMenu = require("src.ui.BagMenu")
  local Bag = require("src.inventory.Bag")
  local Font = require("src.render.Font")
  local ItemEffects = require("src.inventory.ItemEffects")
  local PaletteFX = require("src.render.PaletteFX")
  local Strings = require("src.core.Strings")
  local Theme = require("src.ui.Theme")

  local SCREEN_H = 144
  local HEADER_H = 16
  local TABS_H = 20
  local FOOTER_H = 8
  local PORTRAIT_MIN_H = 224
  local PORTRAIT_MAX_H = 400
  local ROWS = 6
  local ROW_H = 15

  local WHITE = 1
  local LIGHT = 170 / 255
  local DARK = 85 / 255
  local BLACK = 0

  local POCKETS = {
    { key = "all", label = "ALL ITEMS", short = "ALL", palette = "BLUEMON",
      blurb = "Everything you are carrying." },
    { key = "items", label = "ITEMS", short = "ITEMS", palette = "BROWNMON",
      blurb = "Useful items for your journey." },
    { key = "medicine", label = "MEDICINE", short = "MED", palette = "GREENMON",
      blurb = "Items that help your POKéMON." },
    { key = "balls", label = "POKé BALLS", short = "BALLS", palette = "REDMON",
      blurb = "Devices for catching wild POKéMON." },
    { key = "battle", label = "BATTLE", short = "BATTLE", palette = "YELLOWMON",
      blurb = "Items that give an edge in battle." },
    { key = "machines", label = "TMs/HMs", short = "TMs", palette = "PURPLEMON",
      blurb = "Machines that teach new moves." },
    { key = "key", label = "KEY ITEMS", short = "KEY", palette = "CYANMON",
      blurb = "Important items for your adventure." },
  }

  local BATTLE_ITEMS = {
    X_ACCURACY = true, X_ATTACK = true, X_DEFEND = true,
    X_SPEED = true, X_SPECIAL = true, DIRE_HIT = true,
    GUARD_SPEC = true, POKE_DOLL = true,
  }

  local MEDICINE = {
    POTION = true, SUPER_POTION = true, HYPER_POTION = true,
    MAX_POTION = true, FULL_RESTORE = true, FRESH_WATER = true,
    SODA_POP = true, LEMONADE = true, ANTIDOTE = true,
    BURN_HEAL = true, ICE_HEAL = true, AWAKENING = true,
    PARLYZ_HEAL = true, FULL_HEAL = true, REVIVE = true,
    MAX_REVIVE = true, RARE_CANDY = true, HP_UP = true,
    PROTEIN = true, IRON = true, CARBOS = true, CALCIUM = true,
    PP_UP = true, ETHER = true, MAX_ETHER = true,
    ELIXER = true, MAX_ELIXER = true,
  }

  local DESCRIPTIONS = {
    POTION = "Restores 20 HP to one POKéMON.",
    SUPER_POTION = "Restores 50 HP to one POKéMON.",
    HYPER_POTION = "Restores 200 HP to one POKéMON.",
    MAX_POTION = "Fully restores one POKéMON's HP.",
    FULL_RESTORE = "Fully restores HP and cures status.",
    FRESH_WATER = "A refreshing drink that restores 50 HP.",
    SODA_POP = "A fizzy drink that restores 60 HP.",
    LEMONADE = "A sweet drink that restores 80 HP.",
    ANTIDOTE = "Cures a poisoned POKéMON.",
    BURN_HEAL = "Cures a burned POKéMON.",
    ICE_HEAL = "Defrosts a frozen POKéMON.",
    AWAKENING = "Wakes a sleeping POKéMON.",
    PARLYZ_HEAL = "Cures a paralyzed POKéMON.",
    FULL_HEAL = "Cures all status conditions.",
    REVIVE = "Revives a fainted POKéMON with half HP.",
    MAX_REVIVE = "Revives a fainted POKéMON with full HP.",
    RARE_CANDY = "Raises one POKéMON by one level.",
    PP_UP = "Raises the maximum PP of one move.",
    ETHER = "Restores 10 PP to one move.",
    MAX_ETHER = "Fully restores the PP of one move.",
    ELIXER = "Restores 10 PP to every move.",
    MAX_ELIXER = "Fully restores the PP of every move.",
    ESCAPE_ROPE = "Returns you to the last POKéMON Center.",
    REPEL = "Keeps weak wild POKéMON away briefly.",
    SUPER_REPEL = "Keeps weak wild POKéMON away longer.",
    MAX_REPEL = "Keeps weak wild POKéMON away the longest.",
    FIRE_STONE = "A peculiar stone that evolves some POKéMON.",
    WATER_STONE = "A peculiar stone that evolves some POKéMON.",
    THUNDER_STONE = "A peculiar stone that evolves some POKéMON.",
    LEAF_STONE = "A peculiar stone that evolves some POKéMON.",
    MOON_STONE = "A peculiar stone that evolves some POKéMON.",
    NUGGET = "A solid gold nugget that sells for a high price.",
    POKE_DOLL = "A doll that can help you escape a wild battle.",
    BICYCLE = "A folding bicycle that is faster than walking.",
    TOWN_MAP = "A convenient map of the Kanto region.",
    ITEMFINDER = "Checks the area for hidden items.",
    POKE_FLUTE = "A flute with a melody that wakes sleepers.",
    OLD_ROD = "Use it by water to fish for POKéMON.",
    GOOD_ROD = "A good rod for fishing up POKéMON.",
    SUPER_ROD = "The best rod for fishing up POKéMON.",
  }

  local inkShader -- false when shaders are unavailable

  local function gray(value)
    love.graphics.setColor(value, value, value, 1)
  end

  local function shaderForInk()
    if inkShader == nil then
      if not love.graphics.newShader then
        inkShader = false
      else
        local ok, shader = pcall(love.graphics.newShader, [[
          vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
            vec4 pixel = Texel(tex, tc);
            return vec4(color.rgb, pixel.a * color.a);
          }
        ]])
        inkShader = ok and shader or false
      end
    end
    return inkShader or nil
  end

  local function fitText(text, maxWidth)
    text = tostring(text or "")
    maxWidth = math.max(0, math.floor(maxWidth or Font.width(text)))
    if Font.width(text) <= maxWidth then return text end
    local spans = Font.split(text)
    local count = Font.spansFitting(spans, math.max(0, maxWidth - 8))
    if count < 1 then return "" end
    return text:sub(1, spans[count].to) .. "."
  end

  local function drawText(text, x, y, maxWidth, shade)
    text = fitText(text, maxWidth or Font.width(tostring(text or "")))
    love.graphics.push("all")
    local shader = shaderForInk()
    if shader then
      love.graphics.setShader(shader)
      gray(shade == nil and WHITE or shade)
    else
      gray(BLACK)
    end
    Font.draw(text, math.floor(x), math.floor(y))
    love.graphics.pop()
    return Font.width(text)
  end

  local function drawTextRight(text, right, y, maxWidth, shade)
    text = fitText(text, maxWidth)
    local width = Font.width(text)
    drawText(text, right - width, y, maxWidth, shade)
    return width
  end

  local function drawCode(code, x, y, shade)
    love.graphics.push("all")
    local shader = shaderForInk()
    if shader then
      love.graphics.setShader(shader)
      gray(shade == nil and WHITE or shade)
    else
      gray(BLACK)
    end
    Font.drawCode(code, math.floor(x), math.floor(y))
    love.graphics.pop()
  end

  local function wrappedLines(text, maxWidth, maxLines)
    local lines, current = {}, ""
    for word in tostring(text or ""):gmatch("%S+") do
      local candidate = current == "" and word or (current .. " " .. word)
      if current ~= "" and Font.width(candidate) > maxWidth then
        lines[#lines + 1] = fitText(current, maxWidth)
        current = word
        if #lines >= maxLines then break end
      else
        current = candidate
      end
    end
    if #lines < maxLines and current ~= "" then
      lines[#lines + 1] = fitText(current, maxWidth)
    end
    return lines
  end

  local function chamfer(mode, x, y, width, height, cut)
    cut = cut or 3
    if love.graphics.polygon then
      love.graphics.polygon(mode, {
        x + cut, y, x + width - cut, y,
        x + width, y + cut, x + width, y + height - cut,
        x + width - cut, y + height, x + cut, y + height,
        x, y + height - cut, x, y + cut,
      })
    else
      love.graphics.rectangle(mode, x, y, width, height)
    end
  end

  local function displayPixels()
    local width, height
    if love.graphics.getPixelDimensions then
      width, height = love.graphics.getPixelDimensions()
    else
      width, height = love.graphics.getDimensions()
    end
    return tonumber(width) or 160, tonumber(height) or SCREEN_H
  end

  local function responsiveSize()
    local width, height = displayPixels()

    -- A wide window keeps the original 144px-tall responsive surface. A
    -- phone in portrait needs the inverse treatment: lock the readable
    -- 160px width, then use the vertical pixels available at that same
    -- integer scale. This avoids both a postage-stamp Bag and resampled text.
    local portraitScale = math.max(1, math.floor(width / 160))
    local portraitHeight = math.min(PORTRAIT_MAX_H,
      math.floor(height / portraitScale))
    if height >= width * 1.35 and portraitHeight >= PORTRAIT_MIN_H then
      return 160, portraitHeight
    end

    local scale = math.max(1, math.floor(height / SCREEN_H))
    return math.max(160, math.min(400, math.floor(width / scale))), SCREEN_H
  end

  local function uiSize()
    return responsiveSize()
  end

  local function layoutFor(menu)
    local width, height = responsiveSize()
    local renderer = menu and menu.game and menu.game.renderer
    if renderer and renderer.uiSize then
      local rendererW, rendererH = renderer:uiSize()
      width, height = rendererW or width, rendererH or height
    end
    width = math.max(160, math.floor(width))
    height = math.max(SCREEN_H, math.floor(height))
    local wide = width >= 196
    local stacked = not wide and height >= PORTRAIT_MIN_H
    local headerH = stacked and 24 or HEADER_H
    local tabsY = headerH
    local contentY = tabsY + TABS_H
    local footerH = stacked and 20 or FOOTER_H
    local footerY = height - footerH
    local listY = contentY + 3

    if stacked then
      local detailMinH = 82
      local rows = math.floor((footerY - listY - detailMinH - 12) / ROW_H)
      rows = math.max(4, math.min(10, rows))
      local listH = rows * ROW_H + 8
      local detailY = listY + listH + 4
      return {
        width = width, height = height,
        wide = false, stacked = true, showDetails = true,
        headerH = headerH, tabsY = tabsY, tabsH = TABS_H,
        contentY = contentY, footerY = footerY, footerH = footerH,
        rows = rows,
        listX = 4, listY = listY, listW = width - 12, listH = listH,
        detailX = 4, detailY = detailY,
        detailW = width - 8, detailH = footerY - detailY - 3,
      }
    end

    local listColumnW = wide and math.floor(width * 0.54) or width - 8
    listColumnW = math.max(96, listColumnW)
    return {
      width = width, height = height,
      wide = wide, stacked = false, showDetails = wide,
      headerH = headerH, tabsY = tabsY, tabsH = TABS_H,
      contentY = contentY, footerY = footerY, footerH = footerH,
      rows = ROWS,
      listX = 4,
      listY = listY,
      listW = listColumnW - 4,
      listH = footerY - contentY - 6,
      detailX = listColumnW + 4,
      detailY = listY,
      detailW = width - listColumnW - 8,
      detailH = footerY - contentY - 6,
    }
  end

  local function normalizedPocket(value)
    value = tostring(value or ""):lower():gsub("[^a-z]", "")
    local aliases = {
      item = "items", items = "items", other = "items",
      medicine = "medicine", medicines = "medicine", healing = "medicine",
      ball = "balls", balls = "balls", pokeballs = "balls",
      battle = "battle", battleitems = "battle",
      tm = "machines", tms = "machines", hm = "machines",
      hms = "machines", machine = "machines", machines = "machines",
      key = "key", keyitem = "key", keyitems = "key",
    }
    return aliases[value]
  end

  local function categoryFor(game, id)
    local def = game.data.items[id] or {}
    local explicit = normalizedPocket(def.bagPocket or def.pocket)
    if explicit then return explicit end
    if ItemEffects.isBall(id) or def.ball then return "balls" end
    if def.machine then return "machines" end
    if BATTLE_ITEMS[id] then return "battle" end
    if def.keyItem then return "key" end
    if MEDICINE[id] then return "medicine" end
    return "items"
  end

  local function pocketFor(menu)
    return POCKETS[menu.modernBagPocket or 1]
  end

  local function makeRows(menu, pocketKey)
    local rows = {}
    for _, id in ipairs(Bag.order(menu.game.save)) do
      if pocketKey == "all" or categoryFor(menu.game, id) == pocketKey then
        local def = menu.game.data.items[id]
        rows[#rows + 1] = {
          value = id,
          label = def and def.name or id,
          right = "x" .. tostring(menu.game.save.inventory[id] or 0),
        }
      end
    end
    return rows
  end

  local function inventorySignature(menu)
    local parts = {}
    for _, id in ipairs(Bag.order(menu.game.save)) do
      parts[#parts + 1] = id .. ":" .. tostring(menu.game.save.inventory[id])
    end
    return table.concat(parts, "|")
  end

  local function clampList(menu)
    local count = #menu.items
    local rows = math.max(1, menu.rows or ROWS)
    menu.index = math.max(1, math.min(menu.index or 1, math.max(1, count)))
    menu.scroll = math.max(0, math.min(menu.scroll or 0,
      math.max(0, count - rows)))
    if menu.index - menu.scroll > rows then
      menu.scroll = menu.index - rows
    elseif menu.index - menu.scroll < 1 then
      menu.scroll = menu.index - 1
    end
  end

  local function rebuildPocket(menu, preserveId)
    local key = pocketFor(menu).key
    menu.items = makeRows(menu, key)
    if preserveId then
      for index, item in ipairs(menu.items) do
        if item.value == preserveId then
          menu.index = index
          break
        end
      end
    end
    clampList(menu)
    menu.modernBagInventorySignature = inventorySignature(menu)
    if menu.modernBagSwapId and not menu.game.save.inventory[menu.modernBagSwapId] then
      menu.modernBagSwapId = nil
    end
  end

  local function selectedId(menu)
    local item = menu.items and menu.items[menu.index]
    return item and item.value or nil
  end

  local function syncInventory(menu)
    local signature = inventorySignature(menu)
    if signature ~= menu.modernBagInventorySignature then
      rebuildPocket(menu, selectedId(menu))
    end
  end

  local function switchPocket(menu, delta)
    local current = pocketFor(menu)
    menu.modernBagPocketState[current.key] = {
      id = selectedId(menu), index = menu.index, scroll = menu.scroll,
    }
    menu.modernBagPocket = ((menu.modernBagPocket - 1 + delta) % #POCKETS) + 1
    menu.modernBagSwapId = nil
    local nextPocket = pocketFor(menu)
    local saved = menu.modernBagPocketState[nextPocket.key]
    menu.index = saved and saved.index or 1
    menu.scroll = saved and saved.scroll or 0
    rebuildPocket(menu, saved and saved.id)
  end

  local function finishSwap(menu, targetId)
    local sourceId = menu.modernBagSwapId
    menu.modernBagSwapId = nil
    if not sourceId or not targetId then return end
    local order = Bag.order(menu.game.save)
    local sourceIndex, targetIndex
    for index, id in ipairs(order) do
      if id == sourceId then sourceIndex = index end
      if id == targetId then targetIndex = index end
    end
    if sourceIndex and targetIndex then
      order[sourceIndex], order[targetIndex] = order[targetIndex], order[sourceIndex]
      local ok = menu.game and menu.game.data
      if ok then require("src.core.Sound").play(menu.game.data, "Swap") end
    end
    rebuildPocket(menu, sourceId)
  end

  local function reorder(menu, item)
    if not item then return end
    if menu.modernBagSwapId then
      finishSwap(menu, item.value)
    else
      menu.modernBagSwapId = item.value
    end
  end

  local function pocketCounts(menu)
    local counts = { all = 0, items = 0, medicine = 0, balls = 0,
      battle = 0, machines = 0, key = 0 }
    for _, id in ipairs(Bag.order(menu.game.save)) do
      counts.all = counts.all + 1
      local category = categoryFor(menu.game, id)
      counts[category] = (counts[category] or 0) + 1
    end
    return counts
  end

  local function drawPocketSymbol(key, x, y, size)
    x, y, size = math.floor(x), math.floor(y), math.max(8, math.floor(size))
    local unit = math.max(1, math.floor(size / 8))
    if key == "all" then
      gray(LIGHT)
      love.graphics.rectangle("fill", x + unit, y + 3 * unit,
        size - 2 * unit, size - 3 * unit)
      gray(BLACK)
      love.graphics.rectangle("line", x + 2 * unit, y + unit,
        size - 4 * unit, 3 * unit)
      love.graphics.rectangle("fill", x + 3 * unit, y + 4 * unit,
        size - 6 * unit, unit)
    elseif key == "items" then
      gray(LIGHT)
      if love.graphics.polygon then
        love.graphics.polygon("fill", x + size / 2, y,
          x + size, y + size / 2, x + size / 2, y + size,
          x, y + size / 2)
      else
        love.graphics.rectangle("fill", x + unit, y + unit,
          size - 2 * unit, size - 2 * unit)
      end
      gray(DARK)
      love.graphics.rectangle("fill", x + size / 2 - unit / 2,
        y + 2 * unit, unit, size - 4 * unit)
    elseif key == "medicine" then
      gray(DARK)
      love.graphics.rectangle("fill", x + 3 * unit, y,
        size - 6 * unit, 2 * unit)
      gray(LIGHT)
      love.graphics.rectangle("fill", x + 2 * unit, y + 2 * unit,
        size - 4 * unit, size - 2 * unit)
      gray(BLACK)
      love.graphics.rectangle("fill", x + 3 * unit, y + 4 * unit,
        size - 6 * unit, unit)
      love.graphics.rectangle("fill", x + size / 2 - unit / 2,
        y + 3 * unit, unit, 3 * unit)
    elseif key == "balls" then
      gray(LIGHT)
      love.graphics.circle("fill", x + size / 2, y + size / 2, size / 2)
      gray(DARK)
      love.graphics.rectangle("fill", x, y + size / 2 - unit / 2,
        size, unit)
      gray(BLACK)
      love.graphics.circle("fill", x + size / 2, y + size / 2, 2 * unit)
      gray(WHITE)
      love.graphics.circle("fill", x + size / 2, y + size / 2, unit)
    elseif key == "battle" then
      gray(LIGHT)
      love.graphics.rectangle("fill", x + 3 * unit, y,
        2 * unit, size)
      love.graphics.rectangle("fill", x, y + 3 * unit,
        size, 2 * unit)
      gray(DARK)
      love.graphics.rectangle("fill", x + 2 * unit, y + 2 * unit,
        4 * unit, 4 * unit)
    elseif key == "machines" then
      gray(LIGHT)
      love.graphics.circle("fill", x + size / 2, y + size / 2, size / 2)
      gray(DARK)
      love.graphics.circle("fill", x + size / 2, y + size / 2, 3 * unit)
      gray(BLACK)
      love.graphics.circle("fill", x + size / 2, y + size / 2, unit)
    elseif key == "key" then
      gray(LIGHT)
      love.graphics.circle("line", x + 2 * unit, y + 2 * unit, 2 * unit)
      love.graphics.rectangle("fill", x + 3 * unit, y + 3 * unit,
        size - 3 * unit, 2 * unit)
      love.graphics.rectangle("fill", x + 6 * unit, y + 5 * unit,
        2 * unit, 2 * unit)
    end
  end

  local function drawBackdrop(layout)
    gray(WHITE)
    love.graphics.rectangle("fill", 0, 0, layout.width, layout.height)
    gray(LIGHT)
    for x = -layout.height, layout.width, 24 do
      love.graphics.line(x, layout.contentY, x + layout.height, layout.footerY)
    end
  end

  local function drawHeader(menu, layout, counts)
    local pocket = pocketFor(menu)
    gray(DARK)
    love.graphics.rectangle("fill", 0, 0, layout.width, layout.headerH)
    drawText(Strings("BAG"), 5, layout.stacked and 2 or 4, 32, WHITE)

    local capacity = ("%d/%d"):format(Bag.slots(menu.game.save),
      Bag.capacity(menu.game.data))
    drawTextRight(capacity, layout.width - 5, layout.stacked and 2 or 4,
      48, WHITE)

    local label = (layout.wide or layout.stacked) and pocket.label or pocket.short
    local center = Strings(label) .. " " .. tostring(counts[pocket.key] or 0)
    local centerWidth = layout.stacked and (layout.width - 10)
      or math.max(40, layout.width - 96)
    center = fitText(center, centerWidth)
    drawText(center, (layout.width - Font.width(center)) / 2,
      layout.stacked and 13 or 4,
      centerWidth, WHITE)
  end

  local function drawTabs(menu, layout, counts)
    gray(LIGHT)
    love.graphics.rectangle("fill", 0, layout.tabsY, layout.width, layout.tabsH)
    local gap = layout.width >= 210 and 3 or 1
    local available = layout.width - 8 - gap * (#POCKETS - 1)
    local tabW = math.floor(available / #POCKETS)
    local totalW = tabW * #POCKETS + gap * (#POCKETS - 1)
    local x0 = math.floor((layout.width - totalW) / 2)

    for index, pocket in ipairs(POCKETS) do
      local x = x0 + (index - 1) * (tabW + gap)
      local active = index == menu.modernBagPocket
      if active then
        gray(BLACK)
        chamfer("fill", x, layout.tabsY + 1, tabW, layout.tabsH - 1, 2)
        gray(DARK)
        chamfer("fill", x + 1, layout.tabsY + 2,
          tabW - 2, layout.tabsH - 3, 2)
      else
        gray(WHITE)
        chamfer("fill", x, layout.tabsY + 3,
          tabW, layout.tabsH - 5, 2)
      end
      local iconSize = math.min(10, tabW - 4)
      drawPocketSymbol(pocket.key,
        x + math.floor((tabW - iconSize) / 2), layout.tabsY + 4, iconSize)
      gray(active and WHITE or DARK)
      local markerW = math.min(tabW - 6, math.max(2, counts[pocket.key] or 0))
      love.graphics.rectangle("fill", x + math.floor((tabW - markerW) / 2),
        layout.tabsY + layout.tabsH - 3, markerW, 2)
    end
  end

  local function drawList(menu, layout)
    gray(BLACK)
    chamfer("fill", layout.listX + 2, layout.listY + 2,
      layout.listW, layout.listH, 4)
    gray(WHITE)
    chamfer("fill", layout.listX, layout.listY,
      layout.listW, layout.listH, 4)
    gray(LIGHT)
    chamfer("fill", layout.listX + 2, layout.listY + 2,
      layout.listW - 4, layout.listH - 4, 3)

    if #menu.items == 0 then
      local line1, line2 = Strings("THIS POCKET"), Strings("IS EMPTY")
      drawText(line1, layout.listX + (layout.listW - Font.width(line1)) / 2,
        layout.listY + 31, layout.listW - 12, DARK)
      drawText(line2, layout.listX + (layout.listW - Font.width(line2)) / 2,
        layout.listY + 43, layout.listW - 12, DARK)
      return
    end

    for row = 1, layout.rows do
      local index = menu.scroll + row
      local item = menu.items[index]
      if not item then break end
      local y = layout.listY + 4 + (row - 1) * ROW_H
      local selected = index == menu.index
      if selected then
        gray(BLACK)
        chamfer("fill", layout.listX + 4, y - 1,
          layout.listW - 8, 13, 2)
        gray(DARK)
        chamfer("fill", layout.listX + 5, y,
          layout.listW - 10, 11, 2)
      elseif row % 2 == 0 then
        gray(WHITE)
        love.graphics.rectangle("fill", layout.listX + 5, y - 1,
          layout.listW - 10, 13)
      end

      local shade = selected and WHITE or BLACK
      local quantity = item.right or ""
      local qWidth = Font.width(quantity)
      drawText(item.label, layout.listX + 17, y + 1,
        layout.listW - qWidth - 30, shade)
      drawTextRight(quantity, layout.listX + layout.listW - 8, y + 1,
        qWidth + 8, shade)
      if selected then
        drawCode(Theme.cursor, layout.listX + 7, y + 1, shade)
      elseif item.value == menu.modernBagSwapId then
        drawCode(Theme.cursorHollow, layout.listX + 7, y + 1, BLACK)
      end
    end

    if menu.scroll > 0 then
      gray(DARK)
      if love.graphics.polygon then
        love.graphics.polygon("fill", layout.listX + layout.listW - 8,
          layout.listY + 4, layout.listX + layout.listW - 4,
          layout.listY + 4, layout.listX + layout.listW - 6,
          layout.listY + 1)
      else
        love.graphics.rectangle("fill", layout.listX + layout.listW - 7,
          layout.listY + 2, 3, 2)
      end
    end
    if menu.scroll + layout.rows < #menu.items then
      gray(DARK)
      if love.graphics.polygon then
        love.graphics.polygon("fill", layout.listX + layout.listW - 8,
          layout.listY + layout.listH - 4, layout.listX + layout.listW - 4,
          layout.listY + layout.listH - 4, layout.listX + layout.listW - 6,
          layout.listY + layout.listH - 1)
      else
        love.graphics.rectangle("fill", layout.listX + layout.listW - 7,
          layout.listY + layout.listH - 3, 3, 2)
      end
    end
  end

  local function itemDescription(menu, id)
    local def = menu.game.data.items[id] or {}
    if type(def.description) == "string" and def.description ~= "" then
      return def.description
    end
    if DESCRIPTIONS[id] then return Strings(DESCRIPTIONS[id]) end
    if def.machine then
      local move = menu.game.data.moves and menu.game.data.moves[def.machine.move]
      local moveName = move and move.name or def.machine.move
      return Strings("Teaches %s to a compatible POKéMON.", moveName)
    end
    local category = categoryFor(menu.game, id)
    if category == "balls" then
      return Strings("A device for catching wild POKéMON.")
    elseif category == "medicine" then
      return Strings("A medicine used to help a POKéMON.")
    elseif category == "battle" then
      return Strings("An item intended for use in battle.")
    elseif category == "key" then
      return Strings("An important item for your adventure.")
    end
    return Strings("A useful item for your journey.")
  end

  local function drawDetails(menu, layout)
    if not layout.showDetails then return end
    local pocket = pocketFor(menu)

    if layout.stacked then
      gray(BLACK)
      chamfer("fill", layout.detailX + 2, layout.detailY + 2,
        layout.detailW, layout.detailH, 4)
      gray(WHITE)
      chamfer("fill", layout.detailX, layout.detailY,
        layout.detailW, layout.detailH, 4)
      gray(LIGHT)
      chamfer("fill", layout.detailX + 2, layout.detailY + 2,
        layout.detailW - 4, layout.detailH - 4, 3)

      local item = menu.items[menu.index]
      local caption = item and categoryFor(menu.game, item.value) or pocket.key
      drawText(caption:upper(), layout.detailX + 6, layout.detailY + 5,
        math.floor(layout.detailW * 0.58), DARK)
      local money = ("¥%d"):format(menu.game.save.money or 0)
      drawTextRight(money, layout.detailX + layout.detailW - 6,
        layout.detailY + 5, math.floor(layout.detailW * 0.42), DARK)

      local category = item and categoryFor(menu.game, item.value) or pocket.key
      local iconSize = math.min(28, math.max(20, layout.detailH - 56))
      drawPocketSymbol(category, layout.detailX + 8, layout.detailY + 20,
        iconSize)
      local textX = layout.detailX + iconSize + 14
      local textW = layout.detailX + layout.detailW - 6 - textX
      local name = item and item.label or pocket.label
      drawText(name, textX, layout.detailY + 24, textW, BLACK)
      local description = item and itemDescription(menu, item.value) or pocket.blurb
      local descriptionY = layout.detailY + 20 + iconSize + 4
      local descriptionW = layout.detailW - 12
      local maxLines = math.max(2, math.floor(
        (layout.detailY + layout.detailH - 4 - descriptionY) / 9))
      for index, line in ipairs(wrappedLines(
          Strings(description), descriptionW, maxLines)) do
        drawText(line, layout.detailX + 6,
          descriptionY + (index - 1) * 9, descriptionW, DARK)
      end
      return
    end

    gray(BLACK)
    chamfer("fill", layout.detailX + 2, layout.detailY + 2,
      layout.detailW, layout.detailH, 4)
    gray(DARK)
    chamfer("fill", layout.detailX, layout.detailY,
      layout.detailW, layout.detailH, 4)
    gray(BLACK)
    chamfer("fill", layout.detailX + 2, layout.detailY + 2,
      layout.detailW - 4, layout.detailH - 4, 3)

    local item = menu.items[menu.index]
    local caption = item and categoryFor(menu.game, item.value) or pocket.key
    caption = caption:upper()
    drawText(caption, layout.detailX + 6, layout.detailY + 5,
      layout.detailW - 12, LIGHT)

    if item then
      local category = categoryFor(menu.game, item.value)
      local iconSize = 24
      drawPocketSymbol(category,
        layout.detailX + math.floor((layout.detailW - iconSize) / 2),
        layout.detailY + 17, iconSize)
      local name = fitText(item.label, layout.detailW - 12)
      drawText(name, layout.detailX + (layout.detailW - Font.width(name)) / 2,
        layout.detailY + 45, layout.detailW - 12, WHITE)
      local lines = wrappedLines(itemDescription(menu, item.value),
        layout.detailW - 12, 3)
      for index, line in ipairs(lines) do
        drawText(line, layout.detailX + 6,
          layout.detailY + 58 + (index - 1) * 9,
          layout.detailW - 12, LIGHT)
      end
    else
      drawPocketSymbol(pocket.key,
        layout.detailX + math.floor((layout.detailW - 28) / 2),
        layout.detailY + 20, 28)
      local lines = wrappedLines(Strings(pocket.blurb), layout.detailW - 12, 3)
      for index, line in ipairs(lines) do
        drawText(line, layout.detailX + 6,
          layout.detailY + 58 + (index - 1) * 9,
          layout.detailW - 12, LIGHT)
      end
    end

    local money = ("¥%d"):format(menu.game.save.money or 0)
    drawTextRight(money, layout.detailX + layout.detailW - 6,
      layout.detailY + layout.detailH - 11, layout.detailW - 12, WHITE)
  end

  local function drawFooter(menu, layout)
    gray(DARK)
    love.graphics.rectangle("fill", 0, layout.footerY,
      layout.width, layout.footerH)
    if layout.stacked then
      local line1, line2
      if menu.modernBagSwapId then
        line1 = Strings("CHOOSE NEW POSITION")
        line2 = Strings("A PLACE  B BACK")
      else
        line1 = Strings("L/R CHANGE POCKET")
        line2 = Strings("A USE  B BACK")
      end
      line1 = fitText(line1, layout.width - 8)
      line2 = fitText(line2, layout.width - 8)
      drawText(line1, (layout.width - Font.width(line1)) / 2,
        layout.footerY + 1, layout.width - 8, WHITE)
      drawText(line2, (layout.width - Font.width(line2)) / 2,
        layout.footerY + 11, layout.width - 8, WHITE)
      return
    end

    local message
    if menu.modernBagSwapId then
      message = Strings("CHOOSE A NEW POSITION")
    elseif layout.wide then
      message = Strings("L/R POCKET  A SELECT  B BACK")
    else
      message = Strings("L/R POCKET  B BACK")
    end
    message = fitText(message, layout.width - 8)
    drawText(message, (layout.width - Font.width(message)) / 2,
      layout.footerY, layout.width - 8, WHITE)
  end

  local function draw(menu)
    syncInventory(menu)
    local layout = layoutFor(menu)
    menu.rows = layout.rows
    clampList(menu)
    local counts = pocketCounts(menu)
    drawBackdrop(layout)
    drawHeader(menu, layout, counts)
    drawTabs(menu, layout, counts)
    drawList(menu, layout)
    drawDetails(menu, layout)
    drawFooter(menu, layout)
    gray(WHITE)
  end

  local function sgbPalettes(menu, game)
    local data = game and game.data
    if not data then return nil end
    local layout = layoutFor(menu)
    local pocket = pocketFor(menu)
    local base = PaletteFX.pal(data, "BLUEMON")
      or PaletteFX.pal(data, "MEWMON")
    local accent = PaletteFX.pal(data, pocket.palette) or base
    if not base then return nil end
    local zones = {
      { colors = base, x = 0, y = 0, w = layout.width, h = layout.height },
      { colors = accent, x = 0, y = 0, w = layout.width, h = layout.contentY },
    }
    if layout.showDetails then
      zones[#zones + 1] = {
        colors = accent,
        x = layout.detailX, y = layout.detailY,
        w = layout.detailW, h = layout.detailH,
      }
    end
    if #menu.items > 0 then
      zones[#zones + 1] = {
        colors = accent,
        x = layout.listX + 4,
        y = layout.listY + 3 + (menu.index - menu.scroll - 1) * ROW_H,
        w = layout.listW - 8, h = 13,
      }
    end
    return zones
  end

  local function update(menu, dt)
    local layout = layoutFor(menu)
    menu.rows = layout.rows
    clampList(menu)
    syncInventory(menu)
    local input = menu.game.input
    if not (input and input.wasPressed) then
      return menu.modernBagBaseUpdate(menu, dt)
    end
    if input:wasPressed("left") then
      switchPocket(menu, -1)
      return
    elseif input:wasPressed("right") then
      switchPocket(menu, 1)
      return
    end
    -- ListMenu closes an empty list on A as a legacy convenience. Pocket
    -- tabs remain open instead, so the player can continue browsing them.
    if #menu.items == 0 and input:wasPressed("a") then return end
    return menu.modernBagBaseUpdate(menu, dt)
  end

  return {
    new = function(game, opts)
      local menu = BagMenu.new(game, opts)
      local baseChoose = menu.onChoose
      menu.modernBagBaseUpdate = menu.update
      menu.modernBagPocket = 1
      menu.modernBagPocketState = {}
      menu.modernBagSwapId = nil
      menu.rows = layoutFor(menu).rows

      menu.onSelectKey = function(item, list)
        reorder(list, item)
      end
      menu.onChoose = function(item, list)
        if list.modernBagSwapId then
          finishSwap(list, item and item.value)
          return
        end
        return baseChoose(item, list)
      end

      menu.draw = draw
      menu.update = update
      menu.sgbPalettes = sgbPalettes
      menu.uiSize = uiSize
      menu.isWideBattleLayout = function() return true end
      -- The responsive Bag is one composed surface. In DYNAMIC UI mode a
      -- TextBox normally docks itself to the window edge, but its 160px
      -- source rect is declared in classic coordinates while this screen is
      -- wider. The renderer would then cut out the wrong canvas region and
      -- reassemble part of the Bag as dialogue (# wide Bag text seam).
      -- Battles solve the same composition problem by holding UI anchors;
      -- keep Bag messages (item failures, toss confirmations, etc.) inside
      -- this surface as well.
      menu.holdsUIAnchors = true
      menu.modernBagUI = true
      menu.modernBagLayout = "pockets"
      menu.modernBagPockets = POCKETS
      menu.modernBagCategoryFor = function(_, id) return categoryFor(game, id) end
      menu.modernBagLayoutInfo = function() return layoutFor(menu) end
      menu.modernBagSwitchPocket = switchPocket
      menu.modernBagRefresh = rebuildPocket
      rebuildPocket(menu)
      return menu
    end,
  }
end
