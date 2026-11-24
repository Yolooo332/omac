-- Colorscheme from `omac theme` (~/.local/state/omac/theme/name), loaded from the omac checkout
-- so `omac update` brings theme fixes.
--   white | dark  → Baby Blue (themes/baby-blue/nvim)
--   anything else → that Omarchy theme's own lazy spec (themes/omarchy/<name>/neovim.lua)
local omac = vim.env.OMAC_PATH or vim.fn.expand("~/.local/share/omac")
local state = (vim.env.XDG_STATE_HOME or vim.fn.expand("~/.local/state")) .. "/omac/theme/name"

local function current()
  local f = io.open(state, "r")
  if not f then
    return "white"
  end
  local v = (f:read("*l") or "white"):gsub("%s+", "")
  f:close()
  return v ~= "" and v or "white"
end

local function baby_blue(variant)
  return {
    {
      name = "baby-blue",
      dir = omac .. "/themes/baby-blue/nvim",
      lazy = false,
      priority = 1000,
      init = function()
        vim.o.background = variant == "dark" and "dark" or "light"
      end,
      opts = { transparent = false },
      config = function(_, opts)
        require("baby-blue").setup(opts)
      end,
    },
    {
      "LazyVim/LazyVim",
      opts = { colorscheme = "baby-blue" },
    },
    {
      "nvim-lualine/lualine.nvim",
      opts = function(_, opts)
        opts.options = opts.options or {}
        opts.options.theme = "baby-blue"
      end,
    },
  }
end

local theme = current()
if theme == "white" or theme == "dark" then
  return baby_blue(theme)
end

local dir = omac .. "/themes/omarchy/" .. theme
local ok, spec = pcall(dofile, dir .. "/neovim.lua")
if not ok or type(spec) ~= "table" then
  vim.schedule(function()
    vim.notify("omac: no Neovim theme for '" .. theme .. "', using Baby Blue", vim.log.levels.WARN)
  end)
  return baby_blue("white")
end

-- Light themes need background=light before the colorscheme loads
local mode = "dark"
local conf = io.open(dir .. "/theme.conf", "r")
if conf then
  for line in conf:lines() do
    mode = line:match("^mode=(%a+)") or mode
  end
  conf:close()
end
vim.o.background = mode
table.insert(spec, {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.options = opts.options or {}
    opts.options.theme = "auto"
  end,
})
return spec
