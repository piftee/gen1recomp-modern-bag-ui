return function(mod)
  mod.content.constants:patch("bagSize", 999)
  mod.content.screens:register("BagMenu", {
    new = function()
      return { usefulBagFixtureScreen = true }
    end,
  })
end
