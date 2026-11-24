-- lualine theme: options.theme = "baby-blue". Follows the dark/white variant in use.
local c = require("baby-blue").colors()
local panel = require("baby-blue").config.transparent and "NONE" or c.surface

local function mode(fill, text)
  return {
    a = { fg = text or c.bg, bg = fill, gui = "bold" },
    b = { fg = c.fg, bg = c.surfaceHi },
    c = { fg = c.muted, bg = panel },
  }
end

return {
  normal = mode(c.accentFill, c.onFill), -- baby blue
  insert = mode(c.string),
  visual = mode(c.pink, c.onFill),
  replace = mode(c.error),
  command = mode(c.comment),
  terminal = mode(c.muted),
  inactive = {
    a = { fg = c.dim, bg = panel },
    b = { fg = c.dim, bg = panel },
    c = { fg = c.dim, bg = panel },
  },
}
