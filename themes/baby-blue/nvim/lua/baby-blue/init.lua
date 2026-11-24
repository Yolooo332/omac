-- Baby Blue for Neovim. Same coloring layout as the VS Code theme:
-- keywords baby blue (bold), strings green, comments orange (italic),
-- numbers/constants/operators muted, everything else the main text color.
-- Picks dark or white from vim.o.background. Colors live in palette.lua (generated).

local M = {}

M.config = {
  transparent = false, -- leave the background to the terminal (Ghostty's glass)
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

function M.colors()
  local palettes = require("baby-blue.palette")
  return vim.o.background == "light" and palettes.white or palettes.dark
end

function M.load()
  local c = M.colors()
  local none = "NONE"
  local bg = M.config.transparent and none or c.bg
  local panel = M.config.transparent and none or c.surface

  if vim.g.colors_name then vim.cmd("hi clear") end
  vim.g.colors_name = "baby-blue"

  local hl = {
    -- Editor
    Normal = { fg = c.fg, bg = bg },
    NormalNC = { fg = c.fg, bg = bg },
    NormalFloat = { fg = c.fg, bg = panel },
    FloatBorder = { fg = c.frame, bg = panel },
    FloatTitle = { fg = c.accent, bg = panel, bold = true },
    Cursor = { fg = c.bg, bg = c.accent },
    lCursor = { link = "Cursor" },
    TermCursor = { link = "Cursor" },
    CursorLine = { bg = c.cursorLine },
    CursorColumn = { bg = c.cursorLine },
    ColorColumn = { bg = c.surface },
    CursorLineNr = { fg = c.accent, bold = true },
    LineNr = { fg = c.lineNumber },
    LineNrAbove = { fg = c.lineNumber },
    LineNrBelow = { fg = c.lineNumber },
    SignColumn = { bg = bg },
    FoldColumn = { fg = c.lineNumber, bg = bg },
    Folded = { fg = c.muted, bg = c.surface },
    NonText = { fg = c.lineNumber },
    Whitespace = { fg = c.lineNumber },
    EndOfBuffer = { fg = c.lineNumber },
    SpecialKey = { fg = c.lineNumber },
    Conceal = { fg = c.dim },
    Visual = { bg = c.selectionSolid },
    VisualNOS = { bg = c.selectionSolid },
    Search = { fg = c.fg, bg = c.search },
    IncSearch = { fg = c.onFill, bg = c.comment },
    CurSearch = { link = "IncSearch" },
    Substitute = { link = "IncSearch" },
    MatchParen = { fg = c.accent, bold = true, underline = true },
    WinSeparator = { fg = c.guide },
    VertSplit = { fg = c.guide },
    StatusLine = { fg = c.fg, bg = panel },
    StatusLineNC = { fg = c.dim, bg = panel },
    WinBar = { fg = c.fg, bg = bg },
    WinBarNC = { fg = c.dim, bg = bg },
    TabLine = { fg = c.dim, bg = panel },
    TabLineFill = { bg = panel },
    TabLineSel = { fg = c.accent, bg = bg, bold = true },
    Pmenu = { fg = c.fg, bg = c.surface },
    PmenuSel = { bg = c.selectionSolid, bold = true },
    PmenuSbar = { bg = c.surface },
    PmenuThumb = { bg = c.lineNumber },
    PmenuMatch = { fg = c.accent, bold = true },
    WildMenu = { link = "PmenuSel" },
    QuickFixLine = { bg = c.selectionSolid },
    Directory = { fg = c.accent },
    Title = { fg = c.fg, bold = true },
    ModeMsg = { fg = c.fg, bold = true },
    MoreMsg = { fg = c.accent },
    Question = { fg = c.accent },
    ErrorMsg = { fg = c.error },
    WarningMsg = { fg = c.comment },
    SpellBad = { undercurl = true, sp = c.error },
    SpellCap = { undercurl = true, sp = c.accent },
    SpellLocal = { undercurl = true, sp = c.muted },
    SpellRare = { undercurl = true, sp = c.pink },

    -- Diff
    DiffAdd = { bg = c.diffAdd },
    DiffDelete = { bg = c.diffDelete },
    DiffChange = { bg = c.diffChange },
    DiffText = { bg = c.diffText },
    Added = { fg = c.string },
    Changed = { fg = c.accent },
    Removed = { fg = c.error },

    -- Syntax (VS Code layout)
    Comment = { fg = c.comment, italic = true },
    Constant = { fg = c.muted },
    String = { fg = c.string },
    Character = { fg = c.muted },
    Number = { fg = c.muted },
    Float = { fg = c.muted },
    Boolean = { fg = c.muted },
    Identifier = { fg = c.fg },
    Function = { fg = c.fg },
    Statement = { fg = c.accent, bold = true },
    Conditional = { fg = c.accent, bold = true },
    Repeat = { fg = c.accent, bold = true },
    Label = { fg = c.fg },
    Operator = { fg = c.muted },
    Keyword = { fg = c.accent, bold = true },
    Exception = { fg = c.accent, bold = true },
    PreProc = { fg = c.accent, bold = true },
    Include = { fg = c.accent, bold = true },
    Define = { fg = c.accent, bold = true },
    Macro = { fg = c.accent, bold = true },
    PreCondit = { fg = c.accent, bold = true },
    Type = { fg = c.fg },
    StorageClass = { fg = c.accent, bold = true },
    Structure = { fg = c.accent, bold = true },
    Typedef = { fg = c.accent, bold = true },
    Special = { fg = c.muted },
    SpecialChar = { fg = c.muted },
    Tag = { fg = c.fg },
    Delimiter = { fg = c.fg },
    SpecialComment = { fg = c.comment, italic = true },
    Debug = { fg = c.accent },
    Underlined = { fg = c.link, underline = true },
    Error = { fg = c.error },
    Todo = { fg = c.onFill, bg = c.accentFill, bold = true },

    -- Treesitter
    ["@variable"] = { fg = c.fg },
    ["@variable.builtin"] = { fg = c.fg },
    ["@variable.parameter"] = { fg = c.fg, italic = true },
    ["@variable.member"] = { fg = c.fg },
    ["@constant"] = { fg = c.muted },
    ["@constant.builtin"] = { fg = c.muted },
    ["@constant.macro"] = { fg = c.muted },
    ["@module"] = { fg = c.fg },
    ["@module.builtin"] = { fg = c.fg },
    ["@label"] = { fg = c.fg },
    ["@string"] = { fg = c.string },
    ["@string.documentation"] = { fg = c.string },
    ["@string.escape"] = { fg = c.muted },
    ["@string.regexp"] = { fg = c.muted },
    ["@string.special"] = { fg = c.muted },
    ["@string.special.symbol"] = { fg = c.muted },
    ["@string.special.url"] = { fg = c.accent, underline = true },
    ["@character"] = { fg = c.muted },
    ["@character.special"] = { fg = c.muted },
    ["@number"] = { fg = c.muted },
    ["@number.float"] = { fg = c.muted },
    ["@boolean"] = { fg = c.muted },
    ["@type"] = { fg = c.fg },
    ["@type.builtin"] = { fg = c.accent, bold = true },
    ["@type.definition"] = { fg = c.fg },
    ["@attribute"] = { fg = c.muted },
    ["@attribute.builtin"] = { fg = c.muted },
    ["@property"] = { fg = c.fg },
    ["@function"] = { fg = c.fg },
    ["@function.builtin"] = { fg = c.muted },
    ["@function.call"] = { fg = c.fg },
    ["@function.macro"] = { fg = c.fg },
    ["@function.method"] = { fg = c.fg },
    ["@function.method.call"] = { fg = c.fg },
    ["@constructor"] = { fg = c.fg },
    ["@operator"] = { fg = c.muted },
    ["@keyword"] = { fg = c.accent, bold = true },
    ["@keyword.coroutine"] = { fg = c.accent, bold = true },
    ["@keyword.function"] = { fg = c.accent, bold = true },
    ["@keyword.operator"] = { fg = c.accent, bold = true },
    ["@keyword.import"] = { fg = c.accent, bold = true },
    ["@keyword.type"] = { fg = c.accent, bold = true },
    ["@keyword.modifier"] = { fg = c.accent, bold = true },
    ["@keyword.repeat"] = { fg = c.accent, bold = true },
    ["@keyword.return"] = { fg = c.accent, bold = true },
    ["@keyword.exception"] = { fg = c.accent, bold = true },
    ["@keyword.conditional"] = { fg = c.accent, bold = true },
    ["@keyword.directive"] = { fg = c.accent, bold = true },
    ["@punctuation"] = { fg = c.fg },
    ["@punctuation.delimiter"] = { fg = c.fg },
    ["@punctuation.bracket"] = { fg = c.fg },
    ["@punctuation.special"] = { fg = c.accent }, -- ${ } in template strings
    ["@comment"] = { link = "Comment" },
    ["@comment.documentation"] = { link = "Comment" },
    ["@comment.error"] = { fg = c.error, bold = true },
    ["@comment.warning"] = { fg = c.comment, bold = true },
    ["@comment.todo"] = { link = "Todo" },
    ["@comment.note"] = { fg = c.accent, bold = true },
    ["@tag"] = { fg = c.fg },
    ["@tag.builtin"] = { fg = c.fg },
    ["@tag.attribute"] = { fg = c.muted },
    ["@tag.delimiter"] = { fg = c.fg },
    ["@markup.heading"] = { fg = c.fg, bold = true },
    ["@markup.strong"] = { fg = c.muted, bold = true },
    ["@markup.italic"] = { fg = c.accent, italic = true },
    ["@markup.strikethrough"] = { strikethrough = true },
    ["@markup.underline"] = { underline = true },
    ["@markup.quote"] = { fg = c.comment },
    ["@markup.math"] = { fg = c.muted },
    ["@markup.link"] = { fg = c.fg },
    ["@markup.link.label"] = { fg = c.fg },
    ["@markup.link.url"] = { fg = c.accent, underline = true },
    ["@markup.raw"] = { fg = c.string },
    ["@markup.list"] = { fg = c.fg },
    ["@markup.list.checked"] = { fg = c.string },
    ["@markup.list.unchecked"] = { fg = c.dim },
    ["@diff.plus"] = { fg = c.string },
    ["@diff.minus"] = { fg = c.error },
    ["@diff.delta"] = { fg = c.accent },

    -- LSP semantic tokens
    ["@lsp.type.enumMember"] = { fg = c.muted },
    ["@lsp.type.parameter"] = { link = "@variable.parameter" },
    ["@lsp.type.property"] = { link = "@property" },
    ["@lsp.type.namespace"] = { link = "@module" },
    ["@lsp.typemod.variable.defaultLibrary"] = { fg = c.fg },
    LspReferenceText = { bg = c.surfaceHi },
    LspReferenceRead = { bg = c.surfaceHi },
    LspReferenceWrite = { bg = c.surfaceHi },
    LspInlayHint = { fg = c.dim, italic = true },
    LspSignatureActiveParameter = { fg = c.accent, bold = true },

    -- Diagnostics (warnings are orange: no yellow)
    DiagnosticError = { fg = c.error },
    DiagnosticWarn = { fg = c.comment },
    DiagnosticInfo = { fg = c.accent },
    DiagnosticHint = { fg = c.muted },
    DiagnosticOk = { fg = c.string },
    DiagnosticUnderlineError = { undercurl = true, sp = c.error },
    DiagnosticUnderlineWarn = { undercurl = true, sp = c.comment },
    DiagnosticUnderlineInfo = { undercurl = true, sp = c.accent },
    DiagnosticUnderlineHint = { undercurl = true, sp = c.muted },
    DiagnosticUnnecessary = { fg = c.dim },
    DiagnosticDeprecated = { strikethrough = true },

    -- gitsigns
    GitSignsAdd = { fg = c.string },
    GitSignsChange = { fg = c.accent },
    GitSignsDelete = { fg = c.error },

    -- Telescope
    TelescopeNormal = { fg = c.fg, bg = panel },
    TelescopeBorder = { fg = c.guide, bg = panel },
    TelescopePromptBorder = { fg = c.accent, bg = panel },
    TelescopePromptTitle = { fg = c.onFill, bg = c.accentFill, bold = true },
    TelescopePreviewTitle = { fg = c.bg, bg = c.string, bold = true },
    TelescopeResultsTitle = { fg = c.dim },
    TelescopePromptPrefix = { fg = c.accent },
    TelescopeSelection = { bg = c.selectionSolid, bold = true },
    TelescopeSelectionCaret = { fg = c.accent, bg = c.selectionSolid },
    TelescopeMatching = { fg = c.accent, bold = true },

    -- nvim-cmp
    CmpItemAbbr = { fg = c.fg },
    CmpItemAbbrMatch = { fg = c.accent, bold = true },
    CmpItemAbbrMatchFuzzy = { fg = c.accent },
    CmpItemAbbrDeprecated = { fg = c.dim, strikethrough = true },
    CmpItemKind = { fg = c.muted },
    CmpItemKindKeyword = { fg = c.accent },
    CmpItemKindSnippet = { fg = c.string },
    CmpItemMenu = { fg = c.dim },

    -- which-key
    WhichKey = { fg = c.accent },
    WhichKeyGroup = { fg = c.muted },
    WhichKeyDesc = { fg = c.fg },
    WhichKeySeparator = { fg = c.dim },
    WhichKeyNormal = { bg = panel },

    -- oil, indent-blankline, lazy, mason
    OilDir = { fg = c.accent, bold = true },
    IblIndent = { fg = c.guide, nocombine = true },
    IblScope = { fg = c.lineNumber, nocombine = true },
    LazyH1 = { fg = c.onFill, bg = c.accentFill, bold = true },
    LazyButtonActive = { fg = c.onFill, bg = c.accentFill, bold = true },
    MasonHeader = { fg = c.onFill, bg = c.accentFill, bold = true },
    MasonHighlight = { fg = c.accent },
    MasonHighlightBlockBold = { fg = c.onFill, bg = c.accentFill, bold = true },
  }

  for group, spec in pairs(hl) do
    vim.api.nvim_set_hl(0, group, spec)
  end

  for i, col in ipairs(c.terminal) do
    vim.g["terminal_color_" .. (i - 1)] = col
  end

  -- Re-read the lualine theme so the statusline follows a dark/white switch.
  package.loaded["lualine.themes.baby-blue"] = nil
  -- Only when lualine is already running: requiring it here would make lazy.nvim
  -- load it during colorscheme setup, before LazyVim has created `Snacks`.
  local lualine = package.loaded["lualine"]
  if lualine and lualine.get_config then
    local cfg = lualine.get_config()
    if cfg.options and cfg.options.theme == "baby-blue" then lualine.setup(cfg) end
  end
end

-- Switch variant when the background flips (Neovim reads it from the terminal).
vim.api.nvim_create_autocmd("OptionSet", {
  group = vim.api.nvim_create_augroup("BabyBlueBackground", { clear = true }),
  pattern = "background",
  callback = function()
    if vim.g.colors_name == "baby-blue" then vim.cmd.colorscheme("baby-blue") end
  end,
})

return M
