-- Modern Bag UI retains the built-in BagMenu controller and replaces its
-- presentation plus the small amount of navigation needed for pocket tabs.
-- Every item effect, target picker, battle turn, toss prompt and callback
-- continues to run through src/ui/BagMenu.lua.
return function(mod)
  local SKINS = {
    { label = "MODERN", value = "modern" },
    { label = "POCKET", value = "classic_pocket" },
  }

  mod.options:define({
    { key = "skin", label = "BAG SKIN", type = "choice",
      default = "modern",
      choices = {
        { SKINS[1].label, SKINS[1].value },
        { SKINS[2].label, SKINS[2].value },
      } },
  })

  local function skinIndex()
    local current = mod.options:get("skin") or "modern"
    for index, skin in ipairs(SKINS) do
      if skin.value == current then return index end
    end
    return 1
  end

  local function setSkin(game, value)
    local options = game and game.save and game.save.options
    if options then
      options.modOptions = options.modOptions or {}
      options.modOptions[mod.id] = options.modOptions[mod.id] or {}
      options.modOptions[mod.id].skin = value
    end
    local loader = game and game.mods
    if loader then
      loader.modOptions = loader.modOptions or {}
      loader.modOptions[mod.id] = loader.modOptions[mod.id] or {}
      loader.modOptions[mod.id].skin = value
      if loader.events then
        loader.events:emit("mod.options_changed",
          { mod = mod.id, key = "skin", value = value })
      end
    end
  end

  -- Keep the skin beside the game's other display choices instead of hiding
  -- it one level deeper in the mod manager. Left, Right and A all cycle it.
  mod.hooks:wrap("ui.options.rows", function(next, game, rows)
    local out = next(game, rows)
    if type(out) ~= "table" then return out end
    out[#out + 1] = {
      id = "modern_bag_ui_skin",
      label = "BAG SKIN",
      value = function() return SKINS[skinIndex()].label end,
      step = function(g, dir)
        local index = (skinIndex() - 1 + (dir or 1)) % #SKINS + 1
        setSkin(g, SKINS[index].value)
        return true
      end,
    }
    return out
  end)

  local function loadFactory(filename)
    local source, readErr = mod:read(filename)
    if not source then
      mod.log:error("%s is missing (%s); reinstall the mod", filename,
        tostring(readErr or "unknown read error"))
      return nil
    end

    local chunk, compileErr = load(source, "@" .. mod.path .. "/" .. filename)
    if not chunk then
      mod.log:error("%s did not compile: %s", filename, tostring(compileErr))
      return nil
    end

    local ok, factory = pcall(chunk)
    if not ok or type(factory) ~= "function" then
      mod.log:error("%s must return a factory function: %s", filename,
        tostring(factory))
      return nil
    end
    return factory
  end

  -- Compile both parts before installing either one so a damaged archive
  -- cannot leave half of the mod active.
  local makeScreen = loadFactory("screen.lua")
  local makeInventory = loadFactory("inventory.lua")
  if not makeScreen or not makeInventory then return end

  local compatibility = {
    usefulBag = mod.find("useful_bag") ~= nil,
  }
  local screenOK, bagScreen = pcall(makeScreen, mod, compatibility)
  if not screenOK or type(bagScreen) ~= "table"
      or type(bagScreen.new) ~= "function" then
    mod.log:error("bag screen factory failed: %s", tostring(bagScreen))
    return
  end

  local inventoryOK, inventory = pcall(makeInventory, mod, bagScreen)
  if not inventoryOK or type(inventory) ~= "table"
      or type(inventory.playerPC) ~= "table"
      or type(inventory.playerPC.new) ~= "function" then
    mod.log:error("inventory extension factory failed: %s", tostring(inventory))
    return
  end

  -- Useful Bag also registers BagMenu. Its optional dependency edge lets it
  -- install storage/controller patches first; Modern Bag then takes explicit
  -- ownership of the shared presentation record instead of making the later
  -- registration fail and silently disabling one of the mods.
  if mod.content.screens:get("BagMenu") then
    mod.content.screens:override("BagMenu", bagScreen)
  else
    mod.content.screens:register("BagMenu", bagScreen)
  end
  mod.content.screens:register("PlayerPC", inventory.playerPC)
  mod.exports.inventoryLimits = inventory.limits
  mod.exports.skins = SKINS
  mod.exports.activeSkin = function() return SKINS[skinIndex()].value end
  mod.log:info("modern pocket bag enabled (%d slots, x%d stacks)",
    inventory.limits.slots, inventory.limits.stack)
end
