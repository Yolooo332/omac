-- Omarchy's see-through Neovim: clear the background of the editor's highlight
-- groups so the terminal shows behind it. With Ghostty's glass
-- (background-opacity + background-blur) that is the same frosted window as
-- the shell. Ported from Omarchy's ~/.config/nvim/plugin/after/transparency.lua,
-- and re-applied after every colorscheme so `omac theme <name>` keeps it.

-- Make a highlight group transparent while keeping its other attributes
local function make_transparent(name)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  if ok then
    hl.bg = nil
    vim.api.nvim_set_hl(0, name, hl)
  end
end

local groups = {
  -- transparent background
  "Normal",
  "NormalFloat",
  "FloatBorder",
  "Pmenu",
  "Terminal",
  "EndOfBuffer",
  "FoldColumn",
  "Folded",
  "SignColumn",
  "LineNr",
  "CursorLineNr",
  "StatusLine",
  "StatusLineNC",
  "NormalNC",
  "WhichKeyFloat",
  "TelescopeBorder",
  "TelescopeNormal",
  "TelescopePromptBorder",
  "TelescopePromptTitle",
  -- neotree
  "NeoTreeNormal",
  "NeoTreeNormalNC",
  "NeoTreeVertSplit",
  "NeoTreeWinSeparator",
  "NeoTreeEndOfBuffer",
  -- nvim-tree
  "NvimTreeNormal",
  "NvimTreeVertSplit",
  "NvimTreeEndOfBuffer",
  -- notify
  "NotifyINFOBody",
  "NotifyERRORBody",
  "NotifyWARNBody",
  "NotifyTRACEBody",
  "NotifyDEBUGBody",
  "NotifyINFOTitle",
  "NotifyERRORTitle",
  "NotifyWARNTitle",
  "NotifyTRACETitle",
  "NotifyDEBUGTitle",
  "NotifyINFOBorder",
  "NotifyERRORBorder",
  "NotifyWARNBorder",
  "NotifyTRACEBorder",
  "NotifyDEBUGBorder",
}

local function apply()
  -- The current line goes see-through too, leaving its number to mark it. The
  -- file tree marks its selection with that line alone, so it keeps the colour.
  local cursorline = vim.api.nvim_get_hl(0, { name = "CursorLine", link = false })
  if cursorline.bg then
    vim.api.nvim_set_hl(0, "NeoTreeCursorLine", { bg = cursorline.bg })
  end
  make_transparent("CursorLine")

  for _, name in ipairs(groups) do
    make_transparent(name)
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("omac_transparency", { clear = true }),
  callback = apply,
})
apply()
