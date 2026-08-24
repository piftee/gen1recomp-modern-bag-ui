return function(mod)
  mod.options:define({
    { key = "fullscreen_menu", label = "FULLSCREEN BAG MENUS",
      type = "toggle", default = true },
  })
  mod.content.constants:patch("bagSize", 999)
  mod.content.screens:register("BagMenu", {
    new = function()
      return { usefulBagFixtureScreen = true }
    end,
  })
end
