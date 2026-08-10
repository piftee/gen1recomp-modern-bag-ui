-- Modern Bag UI retains the built-in BagMenu controller and replaces its
-- presentation plus the small amount of navigation needed for pocket tabs.
-- Every item effect, target picker, battle turn, toss prompt and callback
-- continues to run through src/ui/BagMenu.lua.
return function(mod)
  local source, readErr = mod:read("screen.lua")
  if not source then
    mod.log:error("screen.lua is missing (%s); reinstall the mod",
      tostring(readErr or "unknown read error"))
    return
  end

  local chunk, compileErr = load(source, "@" .. mod.path .. "/screen.lua")
  if not chunk then
    mod.log:error("screen.lua did not compile: %s", tostring(compileErr))
    return
  end

  local ok, makeScreen = pcall(chunk)
  if not ok or type(makeScreen) ~= "function" then
    mod.log:error("screen.lua must return a factory function: %s", tostring(makeScreen))
    return
  end

  local made, record = pcall(makeScreen, mod)
  if not made or type(record) ~= "table" or type(record.new) ~= "function" then
    mod.log:error("bag screen factory failed: %s", tostring(record))
    return
  end

  mod.content.screens:register("BagMenu", record)
  mod.log:info("modern pocket bag enabled")
end
