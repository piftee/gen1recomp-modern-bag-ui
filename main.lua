-- Modern Bag UI retains the built-in BagMenu controller and replaces its
-- presentation plus the small amount of navigation needed for pocket tabs.
-- Every item effect, target picker, battle turn, toss prompt and callback
-- continues to run through src/ui/BagMenu.lua.
return function(mod)
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

  local screenOK, bagScreen = pcall(makeScreen, mod)
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

  mod.content.screens:register("BagMenu", bagScreen)
  mod.content.screens:register("PlayerPC", inventory.playerPC)
  mod.exports.inventoryLimits = inventory.limits
  mod.log:info("modern pocket bag enabled (%d slots, x%d stacks)",
    inventory.limits.slots, inventory.limits.stack)
end
