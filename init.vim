call plug#begin('~/.local/share/nvim/plugged')

Plug 'nvim-telescope/telescope-frecency.nvim'
Plug 'folke/which-key.nvim'
Plug 'stevearc/stickybuf.nvim'
Plug 'zbirenbaum/copilot.lua'
Plug 'tpope/vim-sensible'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'vim-airline/vim-airline'
Plug 'powerline/powerline'
Plug 'ryanoasis/vim-devicons'
Plug 'vim-airline/vim-airline-themes'
Plug 'whonore/Coqtail'
Plug 'morhetz/gruvbox'
Plug 'joshdick/onedark.vim'
Plug 'dracula/vim'
Plug 'sainnhe/everforest'
Plug 'folke/tokyonight.nvim'
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'preservim/nerdtree'
Plug 'akinsho/toggleterm.nvim', {'tag' : '*'}
Plug 'navarasu/onedark.nvim'
Plug 'scottmckendry/cyberdream.nvim'
Plug 'sbdchd/neoformat'
Plug 'wakatime/vim-wakatime'
Plug 'Mofiqul/vscode.nvim'
Plug 'lewis6991/satellite.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release' }
Plug 'nvim-lua/plenary.nvim'
Plug 'lewis6991/gitsigns.nvim'
Plug 'stevearc/aerial.nvim'
Plug 'mrcjkb/rustaceanvim'
Plug 'Scysta/pink-panic.nvim'
Plug 'rktjmp/lush.nvim'
Plug 'folke/todo-comments.nvim'
Plug 'nvim-tree/nvim-web-devicons'
Plug 'akinsho/bufferline.nvim', { 'tag': '*' }
Plug 'folke/persistence.nvim'
Plug 'numToStr/Comment.nvim'
Plug 'folke/flash.nvim'
Plug 'windwp/nvim-autopairs'
Plug 'lukas-reineke/indent-blankline.nvim'
Plug 'kylechui/nvim-surround', { 'tag': '*' }
Plug 'folke/trouble.nvim'

call plug#end()

autocmd VimEnter * ++once call s:EnableAirlineAfterStartup()
function! s:EnableAirlineAfterStartup()
  set laststatus=2
  AirlineRefresh
endfunction

autocmd BufNewFile,BufRead *.sh set filetype=sh

let mapleader = " "

lua << EOF
local copilot = require("copilot")

copilot.setup({
  suggestion = {
    enabled = true,
    auto_trigger = true,
    debounce = 60,
    keymap = { accept = false },
  },
  panel = { enabled = false },
  server_opts_overrides = {
    settings = {
      advanced = {
        inlineSuggestCount = 1,
        listCount = 3,
      }
    }
  }
})

local suggestion = require("copilot.suggestion")

local function after_member_access()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local before_cursor = line:sub(1, col)
  return before_cursor:match("[%.%-:][%w_]*$") ~= nil
end

local function should_suppress_copilot()
  local line = vim.api.nvim_get_current_line()
  local is_blank = line:match("^%s*$") ~= nil
  return is_blank or after_member_access()
end

vim.keymap.set("i", "<Tab>", function()
  local line = vim.api.nvim_get_current_line()
  local is_blank = line:match("^%s*$") ~= nil

  if suggestion.is_visible() and not is_blank then
    suggestion.accept_line()
    return ""
  elseif require("cmp").visible() then
    require("cmp").confirm({ select = true })
    return ""
  else
    return "<Tab>"
  end
end, { expr = true, silent = true, desc = "Accept copilot line / confirm completion / indent" })

vim.keymap.set("i", "<C-j>", function()
  if suggestion.is_visible() then
    suggestion.accept()
  end
end, { silent = true, desc = "Accept full copilot suggestion" })

local state_path = "/tmp/nvim_copilot_disabled"

local function load_copilot_state()
  local f = io.open(state_path, "r")
  if f then
    local val = f:read("*a"):gsub("\n", "")
    f:close()
    return val == "true"
  end
  return false
end

local function save_copilot_state(disabled)
  local f = io.open(state_path, "w")
  if f then
    f:write(tostring(disabled))
    f:close()
  end
end

local copilot_user_disabled = load_copilot_state()

vim.keymap.set("n", "<leader>d", function()
  copilot_user_disabled = not copilot_user_disabled
  save_copilot_state(copilot_user_disabled)
  if copilot_user_disabled then
    suggestion.dismiss()
    vim.b.copilot_suggestion_auto_trigger = false
  else
    vim.b.copilot_suggestion_auto_trigger = true
  end
  vim.cmd("redrawstatus")
end, { desc = "Toggle Copilot suggestions" })

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if copilot_user_disabled then
      vim.b.copilot_suggestion_auto_trigger = false
    end
    vim.cmd("redrawstatus")
  end,
})

vim.api.nvim_create_autocmd({ "InsertEnter", "CursorMovedI", "TextChangedI" }, {
  callback = function()
    if copilot_user_disabled or should_suppress_copilot() then
      suggestion.dismiss()
      vim.b.copilot_suggestion_auto_trigger = false
    else
      vim.b.copilot_suggestion_auto_trigger = true
    end
  end,
})

require("todo-comments").setup {
  signs = true,
  keywords = {
    FIX = { icon = " ", color = "error" },
    TODO = { icon = " ", color = "info" },
    HACK = { icon = " ", color = "warning" },
    WARN = { icon = " ", color = "warning" },
    PERF = { icon = " ", color = "hint" },
    NOTE = { icon = " ", color = "hint" },
    BUG =  { icon = " ", color = "error" },
  },
}

vim.api.nvim_create_autocmd({"InsertEnter", "InsertLeave"}, {
  callback = function()
    vim.cmd("redrawstatus")
  end,
})

function _G.CopilotStatus()
  local auto = vim.b.copilot_suggestion_auto_trigger
  local disabled = (auto == false) or (auto == nil and copilot_user_disabled)
  if disabled then
    return " "
  else
    return " "
  end
end

require('nvim-treesitter').setup {
  ensure_installed = { "rust", "c", "gleam", "cpp", "markdown", "haskell", "python", "js" },
  highlight = {
    enable = true,
  },
  indent = {
    enable = true,
  },
}

vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    vim.schedule(function()
      pcall(vim.treesitter.start)
    end)
  end,
})

require('aerial').setup({
  filter_kind = false,
  layout = {
    default_direction = 'right',
    min_width = 30,
  },
  show_guides = true,
  nerd_font = true,
  post_parse_symbol = nil,
  manage_folds = false,
  link_folds_to_tree = false,
  link_tree_to_cursor = true,
  arrange_symbols = function(symbols, opts)
    local grouped = { Struct = {}, Enum = {}, Function = {}, Other = {} }
    for _, sym in ipairs(symbols) do
      if grouped[sym.kind] then
        table.insert(grouped[sym.kind], sym)
      else
        table.insert(grouped.Other, sym)
      end
    end
    local result = {}
    for _, group in ipairs({ "Struct", "Enum", "Function", "Other" }) do
      for _, sym in ipairs(grouped[group]) do
        table.insert(result, sym)
      end
    end
    return result
  end,
})

vim.keymap.set('n', '<leader>aa', '<cmd>AerialToggle! right<CR>', { desc = "Toggle symbols outline" })
vim.keymap.set('n', '<leader>as', '<cmd>Telescope aerial<CR>', { desc = "Search symbols (Telescope)" })

require("cyberdream").setup({
    transparent = true,
})

local cmp = require('cmp')
local cmp_lsp = require('cmp_nvim_lsp')

vim.lsp.config("clangd", {
    cmd = {
        "clangd",
        "--clang-tidy",
        "--background-index",
        "--header-insertion=iwyu",
        "--enable-config",
    },
    capabilities = cmp_lsp.default_capabilities(),
    on_attach = function(client, bufnr)
        cmp.setup.buffer {
            sources = {
                { name = 'nvim_lsp', max_item_count = 15 },
            }
        }
    end,
})
vim.lsp.enable({"clangd"})

vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
})

vim.api.nvim_create_autocmd({"TextChanged", "TextChangedI"}, {
    pattern = "*",
    callback = function()
        vim.diagnostic.setloclist({open=false})
    end
})

require'toggleterm'.setup()

vim.lsp.config.bashls = {
  cmd = { 'bash-language-server', 'start' },
  filetypes = { 'bash', 'sh' }
}
vim.lsp.enable 'bashls'

vim.g.rustaceanvim = {
  server = {
    on_attach = on_attach,
    settings = {
        ["rust-analyzer"] = {
            lru = { capacity = 512 },
            updates = { rateLimit = 0 },
            diagnostics = {
                enableExperimental = true,
            },
            check = {
                command = "clippy",
            },
            cargo = {
                allFeatures = true,
                buildScripts = {
                    enable = true,
                },
            },
            procMacro = {
                enable = true,
            },
            analysis = {
                enable = true,
                ignoreInactiveCode = false,
            },
            imports = {
                granularity = {
                    group = "module",
                },
                prefix = "self",
            },
        },
    },
  },
}

vim.lsp.config("pylsp", {})
vim.lsp.enable({"pylsp"})

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
    border = "rounded",
})

vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = 'rounded' })

local lsp_buf_hover = function()
    if vim.fn.pumvisible() == 1 then
        vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<C-e>", true, true, true), "n")
    end
    vim.lsp.buf.hover()
end

local cmp = require'cmp'
cmp.setup({
    snippet = {
        expand = function(args)
        end,
    },

    completion = {
        completeopt = 'menu,menuone,noselect',
        max_items = 10,
        min_length = 1,
        timeout = 100,
    },
    mapping = {
        ['<C-n>'] = cmp.mapping.select_next_item(),
        ['<C-p>'] = cmp.mapping.select_prev_item(),
        ['<C-e>'] = cmp.mapping.close(),
        ['<C-y>'] = cmp.mapping.confirm({ select = true }),
        ['<C-l>'] = cmp.mapping(lsp_buf_hover, { 'i', 's' }),
        ['<C-Space>'] = cmp.mapping.complete(),
    },

    sources = {
        {
            name = 'nvim_lsp',
            entry_filter = function(entry)
                return true
            end,
            max_item_count = 20,
        },
        { name = 'buffer', max_item_count = 20 },
        { name = 'path', max_item_count = 20 },
    },

    window = {
      completion = cmp.config.window.bordered({
        border = "rounded",
        winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,CursorLine:PmenuSel,Search:None",
      }),
      documentation = cmp.config.window.bordered({
        border = "rounded",
        winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
      }),
    },
})

vim.api.nvim_set_keymap('n', '<leader>ff', ':Neoformat<CR>', { noremap = true, silent = true, desc = "Format file (Neoformat)" })

vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { desc = "Exit terminal mode" })
vim.filetype.add({
    extension = {
        mdx = "markdown",
    },
})

local lsp_active = false

function toggle_lsp()
    vim.lsp.stop_client(vim.lsp.get_clients())
    lsp_active = false
end

local wk = require('which-key')
wk.setup({ delay = 400, win = { border = "rounded" } })

vim.api.nvim_create_autocmd("User", {
  pattern = "WhichKeyClose",
  callback = function()
    vim.cmd("AirlineRefresh")
  end,
})

-- which-key group labels
local wk = require('which-key')
wk.add({
  { "<leader>a", group = "aerial/symbols" },
  { "<leader>f", group = "find/format" },
  { "<leader>h", group = "git hunks" },
  { "<leader>t", group = "toggles" },
  { "<leader>q", group = "session" },
  { "<leader>x", group = "trouble/diagnostics" },
  { "<leader>?", desc = "Show all keybinds" },
  { "<leader>g", desc = "NERDTree: find current file" },
  { "<leader>G", desc = "NERDTree: toggle" },
  { "<leader>n", desc = "NERDTree: focus" },
  { "<leader>e", desc = "Toggle terminal" },
  { "<leader>d", desc = "Toggle Copilot" },
  { "<leader>[", desc = "Previous buffer" },
  { "<leader>]", desc = "Next buffer" },
  { "<leader>c", desc = "Convert // comments to /* */ (visual)", mode = "v" },
  { "]c", desc = "Next git hunk" },
  { "[c", desc = "Prev git hunk" },
  { "<F1>", desc = "Stop LSP clients" },
  { "<F5>", desc = "Strip trailing whitespace" },
})

require('gitsigns').setup{
  on_attach = function(bufnr)
    local gitsigns = require('gitsigns')

    local function map(mode, l, r, desc)
      vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
    end

    -- Navigation
    map('n', ']c', function()
      if vim.wo.diff then
        vim.cmd.normal({']c', bang = true})
      else
        gitsigns.nav_hunk('next')
      end
    end, "Next git hunk")

    map('n', '[c', function()
      if vim.wo.diff then
        vim.cmd.normal({'[c', bang = true})
      else
        gitsigns.nav_hunk('prev')
      end
    end, "Prev git hunk")

    -- Actions
    map('n', '<leader>hs', gitsigns.stage_hunk, "Stage hunk")
    map('n', '<leader>hr', gitsigns.reset_hunk, "Reset hunk")

    map('v', '<leader>hs', function()
      gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
    end, "Stage selected hunk")

    map('v', '<leader>hr', function()
      gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
    end, "Reset selected hunk")

    map('n', '<leader>hS', gitsigns.stage_buffer, "Stage buffer")
    map('n', '<leader>hR', gitsigns.reset_buffer, "Reset buffer")
    map('n', '<leader>hp', gitsigns.preview_hunk, "Preview hunk")
    map('n', '<leader>hi', gitsigns.preview_hunk_inline, "Preview hunk inline")

    map('n', '<leader>hb', function()
      gitsigns.blame_line({ full = true })
    end, "Blame line (full)")

    map('n', '<leader>hd', gitsigns.diffthis, "Diff this")

    map('n', '<leader>hD', function()
      gitsigns.diffthis('~')
    end, "Diff against last commit")

    map('n', '<leader>hQ', function() gitsigns.setqflist('all') end, "All hunks to quickfix")
    map('n', '<leader>hq', gitsigns.setqflist, "Buffer hunks to quickfix")

    -- Toggles
    map('n', '<leader>tb', gitsigns.toggle_current_line_blame, "Toggle line blame")
    map('n', '<leader>tw', gitsigns.toggle_word_diff, "Toggle word diff")

    -- Text object
    vim.keymap.set({'o', 'x'}, 'ih', gitsigns.select_hunk, { buffer = bufnr, desc = "Select hunk (text object)" })
  end
}

require('satellite').setup({
  current_only = false,
  winblend = 50,
  handlers = {
    aerial = { enable = true },
    gitsigns = { enable = true },
    diagnostic = { enable = true },
  },
})
require("stickybuf").setup()

vim.api.nvim_set_keymap('n', '<F1>', ':lua toggle_lsp()<CR>', { noremap = true, silent = true, desc = "Stop LSP clients" })

local uv = vim.loop
local last_weather = ""
local last_update = 0
local weather_timer = nil
local cache_path = "/tmp/nvim_weather_cache"
local sun_cache_path = "/tmp/nvim_sun_cache"
local moon_cache_path = "/tmp/nvim_moon_cache"
local sunrise, sunset = nil, nil
local last_moon = ""

local moon_emoji_to_nf = {
  ["🌑"] = "",
  ["🌒"] = "",
  ["🌓"] = "",
  ["🌔"] = "",
  ["🌕"] = "",

  ["🌖"] = "",
  ["🌗"] = "",

  ["🌘"] = "",
}

local function moon_cache_stale()
  local stat = uv.fs_stat(moon_cache_path)
  if not stat then return true end
  return (os.time() - stat.mtime.sec) > (6 * 3600)
end

local function load_moon_cache()

  local f = io.open(moon_cache_path, "r")
  if f then

    local data = f:read("*a")
    f:close()
    if data and data ~= "" then
      last_moon = data:gsub("\n", ""):gsub("%s+", "")
    end
  end
end
 
local function save_moon_cache()
  local f = io.open(moon_cache_path, "w")
  if f then
    f:write(last_moon)
    f:close()
  end
end

 
local function update_moon_async()
  if not moon_cache_stale() then
    load_moon_cache()

    return
  end
 
  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)
  local data = ""
  local handle
  handle = uv.spawn("curl", {
    args = { "-s", "wttr.in?format=%m" },
    stdio = { nil, stdout, stderr },
  }, function(code)
    vim.defer_fn(function()
      stdout:close()

      stderr:close()
      handle:close()
      if code == 0 and data and data ~= "" then
        last_moon = data:gsub("\n", ""):gsub("%s+", "")
        save_moon_cache()
        vim.schedule(function() vim.cmd("redrawstatus") end)
      end
    end, 100)

  end)
  stdout:read_start(function(err, chunk)
    if chunk then data = data .. chunk end
  end)
  stderr:read_start(function() end)
end
 
local function get_moon_icon()
  if last_moon == "" then return "" end
  return moon_emoji_to_nf[last_moon] or last_moon
end

local function load_weather_cache()
  local f = io.open(cache_path, "r")
  if f then
    local data = f:read("*a")
    f:close()
    if data and data ~= "" then
      last_weather = data:gsub("\n", "")
    end
  end
end

local function save_weather_cache()
  local ok, f = pcall(io.open, cache_path, "w")
  if ok and f then
    f:write(last_weather)
    f:close()
  end
end

local function parse_sun_times(data)
  -- wttr.in?format=%S+%s gives sunrise/sunset in HH:MM:SS format (local time)
  local sr, ss = data:match("(%d+:%d+:%d*):?%s+(%d+:%d+:%d*):?")
  if sr and ss then
    sunrise, sunset = sr, ss
    return true
  end
  return false
end

local function save_sun_cache()
  if not sunrise or not sunset then return end
  local f = io.open(sun_cache_path, "w")
  if f then
    f:write(string.format("%s %s\n", sunrise, sunset))
    f:close()
  end
end

local function load_sun_cache()
  local f = io.open(sun_cache_path, "r")
  if f then
    local data = f:read("*a")
    f:close()
    parse_sun_times(data)
  end
end

local function sun_cache_stale()
  local stat = uv.fs_stat(sun_cache_path)
  if not stat then return true end
  -- refresh if older than 6 hours (sunrise/sunset don't shift much)
  return (os.time() - stat.mtime.sec) > (6 * 3600)
end

local function update_sun_times()
  if not sun_cache_stale() then
    load_sun_cache()
    return
  end

  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)
  local data = ""
  local handle
  handle = uv.spawn("curl", {
    args = { "-s", "wttr.in?format=%S+%s" },
    stdio = { nil, stdout, stderr },
  }, function(code)
    vim.defer_fn(function()
      stdout:close()
      stderr:close()
      handle:close()
      if code == 0 and data and data ~= "" and parse_sun_times(data) then
        save_sun_cache()
      end
    end, 100)
  end)
  stdout:read_start(function(err, chunk)
    if chunk then data = data .. chunk end
  end)
  stderr:read_start(function() end)
end

local function is_daytime()
  if not (sunrise and sunset) then
    load_sun_cache()
    if not (sunrise and sunset) then
      update_sun_times()
      return true  -- default to day if unknown
    end
  end

  local function to_minutes(t)
    local h, m = t:match("(%d+):(%d+)")
    return tonumber(h) * 60 + tonumber(m)
  end

  local now = os.date("*t")
  local now_m = now.hour * 60 + now.min
  local sr_m = to_minutes(sunrise)
  local ss_m = to_minutes(sunset)

  return now_m >= sr_m and now_m < ss_m
end

local function get_weather_icon(temp, cond)
  if not cond or cond == "" then return "🌡️" end
  cond = cond:lower()
  local day = is_daytime()

  local icon
  if cond:match("thunder") or cond:match("storm") or cond:match("lightning") then
    icon = ""
  elseif cond:match("rain") or cond:match("drizzle") then
    if cond:match("light") then
      icon = ""
    elseif cond:match("heavy") then
      icon = ""
    else
      icon = ""
    end
  elseif cond:match("snow") or cond:match("sleet") or cond:match("flurr") then
    if cond:match("light") then
      icon = ""
    elseif cond:match("heavy") then
      icon = ""
    else
      icon = ""
    end
  elseif cond:match("hail") then
    icon = ""
  elseif cond:match("fog") or cond:match("mist") or cond:match("haze") or cond:match("smoke") then
    icon = ""
  elseif cond:match("overcast") then
    icon = ""
  elseif cond:match("partly") or cond:match("cloud") then
    icon = day and "" or ""
  elseif cond:match("clear") or cond:match("sun") then
    icon = day and "" or ""
  elseif cond:match("wind") or cond:match("breeze") or cond:match("gust") then
    icon = ""
  elseif cond:match("tornado") or cond:match("cyclone") or cond:match("funnel") then
    icon = ""
  elseif cond:match("dust") or cond:match("sand") then
    icon = ""
  elseif cond:match("ice") or cond:match("freez") then
    icon = ""
  else
    icon = ""
  end

  if not day and icon ~= "" then
    icon = " " .. icon
  end

  return icon
end

local function update_weather_async()
  if weather_timer then weather_timer:stop() end
  weather_timer = uv.new_timer()

  local function fetch_weather()
    local stdout = uv.new_pipe(false)
    local stderr = uv.new_pipe(false)
    local data = ""
    local handle
    handle = uv.spawn("curl", {
      args = { "-s", "wttr.in?format=%t+%C" },
      stdio = { nil, stdout, stderr },
    }, function(code)
      vim.defer_fn(function()
        stdout:close()
        stderr:close()
        handle:close()
        if code == 0 and data ~= "" and not data:match("Unknown location") then
          last_weather = data:gsub("\n", "")
          last_update = os.time()
          save_weather_cache()
          vim.schedule(function() vim.cmd("redrawstatus") end)
        end
      end, 100)
    end)
    stdout:read_start(function(err, chunk)
      if chunk then data = data .. chunk end
    end)
    stderr:read_start(function() end)
  end

  fetch_weather()
  weather_timer:start(60000, 60000, fetch_weather)
end

function _G.StatusWeather()
  local temp, cond = last_weather:match("([%+%-]?%d+°[CF])%s*(.*)")
  local icon = get_weather_icon(temp or "", cond or "")
  local moon = get_moon_icon()
  local moon_str = moon ~= "" and (moon .. "  ") or ""
  if temp and cond then
    return string.format(" %s %s  %s  %s │ %s  ", moon_str, icon, cond, temp, os.date("%I:%M %p  %m/%d"))
  else
    return os.date("   %m/%d  %I:%M %p  ")
  end
end

local function schedule_time_updates()
  vim.defer_fn(function()
    vim.cmd("redrawstatus")
    schedule_time_updates()
  end, 60000)
end

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    load_weather_cache()
    load_moon_cache()
    update_weather_async()
    update_sun_times()
    update_moon_async()
    schedule_time_updates()
  end,
})

vim.opt.statuscolumn = "%s%=%l%#LineNr#│"
vim.api.nvim_create_autocmd("ModeChanged", {

  callback = function()
    vim.cmd("redrawstatus!")

    vim.cmd("redraw!")
  end,
})

local M = {}

local has_telescope, telescope = pcall(require, "telescope.builtin")
if not has_telescope then
  return M
end

local function get_project_root()
  local root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  if root == "" then
    root = vim.loop.cwd()
  end
  return root
end

local function get_search_text()
  local mode = vim.fn.mode()
  local text = ""

  if mode == "v" or mode == "V" then
    vim.cmd('normal! "vy')
    text = vim.fn.getreg('v')
  else
    text = vim.fn.expand("<cword>")
  end

  text = text:gsub("^%s+", ""):gsub("%s+$", "")
  return text
end

function M.live_grep_project()
  local root = get_project_root()
  local default_text = get_search_text()

  telescope.live_grep({
    cwd = root,
    default_text = default_text,
  })
end

vim.keymap.set('n', 'fr', function()
  local root = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
  if not root or root == '' then
    root = vim.fn.getcwd()
  end
  require('telescope').extensions.frecency.frecency({
    cwd = root,
    workspace = 'CWD',
  })
end, { noremap = true, silent = true })

vim.keymap.set('v', '<leader>fg', M.live_grep_project, { noremap = true, silent = true, desc = "Live grep (visual selection)" })
vim.keymap.set('n', '<leader>fg', M.live_grep_project, { noremap = true, silent = true, desc = "Live grep project" })
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = "Move to left window" })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = "Move to right window" })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = "Move to window below" })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = "Move to window above" })
vim.keymap.set('n', '<C-Left>',  '<C-w><', { desc = "Shrink window width" })
vim.keymap.set('n', '<C-Right>', '<C-w>>', { desc = "Grow window width" })
vim.keymap.set('n', '<C-Up>',    '<C-w>+', { desc = "Grow window height" })
vim.keymap.set('n', '<C-Down>',  '<C-w>-', { desc = "Shrink window height" })
vim.keymap.set('n', '<C-x>', ':bdelete<CR>', { noremap = true, silent = true, desc = 'Close buffer' })
vim.keymap.set('n', '<leader>[', ':bprev<CR>', { desc = "Previous buffer" })
vim.keymap.set('n', '<leader>]', ':bnext<CR>', { desc = "Next buffer" })

-- Bufferline: a reorderable tabline (airline's tabline is disabled below).
-- ---- persist the drag-order of buffers across restarts, per directory ----
local bl_order_file = vim.fn.stdpath("state") .. "/bufferline_order.json"
local bl_saved_index = {}   -- path -> position, for the current working dir

local function bl_read_all()
  local f = io.open(bl_order_file, "r"); if not f then return {} end
  local d = f:read("*a"); f:close()
  local ok, t = pcall(vim.json.decode, d); return (ok and t) or {}
end
local function bl_write_all(t)
  local f = io.open(bl_order_file, "w"); if not f then return end
  f:write(vim.json.encode(t)); f:close()
end
local function bl_refresh_saved()
  bl_saved_index = {}
  local paths = bl_read_all()[vim.fn.getcwd()]
  if paths then for i, p in ipairs(paths) do bl_saved_index[p] = i end end
end
bl_refresh_saved()

-- Two colors drive the tab styling (defined once, reused below):
local bl_dim_bg = "#0c0e13"  -- dimmed tab-bar chrome / inactive tab background
local bl_dim_fg = "#6b7280"  -- dimmed inactive tab text

require('bufferline').setup {
  options = {
    mode = "buffers",
    separator_style = "thin",        -- default single divider between tabs
    indicator = { style = "icon", icon = "▎" },  -- colored bar marks the active tab
    show_buffer_close_icons = true,  -- the little × per buffer
    show_close_icon = false,         -- no global close button on the far right
    show_buffer_icons = true,        -- filetype icons via nvim-web-devicons
    modified_icon = "●",
    diagnostics = false,
    always_show_bufferline = true,
    -- Initial order follows the saved per-dir order; unknown buffers trail by id.
    -- A manual move (BufferLineMove*) overrides this for the rest of the session.
    sort_by = function(a, b)
      local ia, ib = bl_saved_index[a.path], bl_saved_index[b.path]
      if ia and ib then return ia < ib end
      if ia then return true end
      if ib then return false end
      return a.id < b.id
    end,
  },
  -- Active tab = transparent (blends into the buffer background, no box).
  -- Everything else = a dim strip (bl_dim_bg) with dim text (bl_dim_fg), so the
  -- active tab reads as a lit "hole" through an otherwise dimmed bar.
  highlights = {
    -- dimmed chrome + inactive tabs
    fill                 = { bg = bl_dim_bg },
    background           = { fg = bl_dim_fg, bg = bl_dim_bg },
    buffer_visible       = { fg = bl_dim_fg, bg = bl_dim_bg },
    separator            = { fg = bl_dim_bg, bg = bl_dim_bg },
    separator_visible    = { fg = bl_dim_bg, bg = bl_dim_bg },
    modified             = { fg = bl_dim_fg, bg = bl_dim_bg },
    modified_visible     = { fg = bl_dim_fg, bg = bl_dim_bg },
    close_button         = { fg = bl_dim_fg, bg = bl_dim_bg },
    close_button_visible = { fg = bl_dim_fg, bg = bl_dim_bg },
    duplicate            = { fg = bl_dim_fg, bg = bl_dim_bg },
    duplicate_visible    = { fg = bl_dim_fg, bg = bl_dim_bg },
    -- active tab: fully transparent, default (bright) foreground
    buffer_selected       = { bg = "NONE" },
    separator_selected    = { bg = "NONE" },
    modified_selected     = { bg = "NONE" },
    close_button_selected = { bg = "NONE" },
    duplicate_selected    = { bg = "NONE" },
    indicator_selected    = { bg = "NONE" },
  },
}

-- Save the current visual order (as file paths) on exit, keyed by directory.
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    local ok, bl = pcall(require, "bufferline"); if not ok then return end
    local els = bl.get_elements(); els = (els and els.elements) or {}
    local paths = {}
    for _, e in ipairs(els) do
      if e.path and e.path ~= "" then paths[#paths + 1] = e.path end
    end
    if #paths == 0 then return end
    local all = bl_read_all()
    all[vim.fn.getcwd()] = paths
    bl_write_all(all)
  end,
})

-- Reorder the current buffer left/right within the bufferline.
vim.keymap.set('n', '<leader><Left>',  ':BufferLineMovePrev<CR>', { silent = true, desc = "Move buffer left in tabline" })
vim.keymap.set('n', '<leader><Right>', ':BufferLineMoveNext<CR>', { silent = true, desc = "Move buffer right in tabline" })

-- Session persistence (per directory): remember open buffers/tabs/window layout.
-- What gets saved in a session — buffers, cwd, tabpages, window sizes, etc.
vim.o.sessionoptions = "buffers,curdir,folds,globals,help,tabpages,terminal,winsize,winpos"
require('persistence').setup()

-- Auto-restore the session for this directory when launching bare `nvim`
-- (no file arguments and nothing piped in), so `nvim` in a project drops you
-- right back where you left off after `:wqa`.
vim.api.nvim_create_autocmd("VimEnter", {
  nested = true,
  callback = function()
    local no_file_args = vim.fn.argc() == 0
    local not_piped_in = not vim.g.started_with_stdin
    if no_file_args and not_piped_in then
      require('persistence').load()
      bl_refresh_saved()   -- session restored a cwd; reload its saved tab order
    end
  end,
})
vim.api.nvim_create_autocmd("StdinReadPre", {
  callback = function() vim.g.started_with_stdin = true end,
})

-- Manual session controls if you ever want them.
vim.keymap.set('n', '<leader>qs', function() require('persistence').load() end, { desc = "Restore session (this dir)" })
vim.keymap.set('n', '<leader>ql', function() require('persistence').load({ last = true }) end, { desc = "Restore last session" })
vim.keymap.set('n', '<leader>qd', function() require('persistence').stop() end, { desc = "Stop saving session" })

-- Comment.nvim: treesitter-aware comment toggling (gcc line, gc motion/visual).
require('Comment').setup()

-- flash.nvim: jump anywhere with labels; also enhances f/t/F/T.
require('flash').setup()
vim.keymap.set({ "n", "x", "o" }, "s", function() require("flash").jump() end, { desc = "Flash jump" })
-- Treesitter select on S in normal/operator only (visual S is left to nvim-surround).
vim.keymap.set({ "n", "o" }, "S", function() require("flash").treesitter() end, { desc = "Flash treesitter" })

-- nvim-autopairs: auto-close brackets/quotes, integrated with nvim-cmp.
require('nvim-autopairs').setup {}
do
  local ok_cmp, cmp = pcall(require, 'cmp')
  local ok_ap, cmp_ap = pcall(require, 'nvim-autopairs.completion.cmp')
  if ok_cmp and ok_ap then
    cmp.event:on('confirm_done', cmp_ap.on_confirm_done())
  end
end

-- indent-blankline (ibl): vertical box-drawing indent guides + current scope.
require('ibl').setup {
  indent = { char = "│" },
  scope = { enabled = true },
}

-- nvim-surround: add/change/delete surrounds (ys/cs/ds, visual S).
require('nvim-surround').setup {}

-- trouble.nvim: aggregated diagnostics/quickfix panel (complements inline LSP).
require('trouble').setup {}
vim.keymap.set('n', '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>',              { desc = "Diagnostics (Trouble)" })
vim.keymap.set('n', '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', { desc = "Buffer diagnostics (Trouble)" })
vim.keymap.set('n', '<leader>xq', '<cmd>Trouble qflist toggle<cr>',                    { desc = "Quickfix list (Trouble)" })

-- Summon the full which-key hint list for the current mode (all first keys,
-- not just <leader>). Pressing <leader> alone already shows the leader menu.
vim.keymap.set('n', '<leader>?', function() require('which-key').show({ global = true }) end, { desc = "Show all keybinds (which-key)" })

vim.api.nvim_create_autocmd({"InsertEnter", "InsertLeave", "BufEnter"}, {
  callback = function()
    vim.cmd("redrawstatus")
  end,
})

return M

EOF

function! ConvertAllCommentsToBlocks() range
  let l:start = a:firstline
  let l:end = a:lastline
  let l:lines = getline(l:start, l:end)

  let l:result = []
  let l:block_buffer = []
  let l:in_block = 0

  for l:line in l:lines
    " CASE 1: full-line comment
    if l:line =~ '^\s*//'
      let l:comment_text = substitute(l:line, '^\s*//\s*', '', '')
      call add(l:block_buffer, l:comment_text)
      let l:in_block = 1
      continue
    endif

    " CASE 2: line of code with inline comment
    if l:line =~ '//'
      " flush existing block if any
      if l:in_block && !empty(l:block_buffer)
        call add(l:result, '/* ' . join(l:block_buffer, ' ') . ' */')
        let l:block_buffer = []
        let l:in_block = 0
      endif
      let l:match_pos = match(l:line, '//')
      let l:prefix = strpart(l:line, 0, l:match_pos)
      let l:comment_part = substitute(strpart(l:line, l:match_pos), '^//\s*', '', '')
      call add(l:result, l:prefix . '/* ' . l:comment_part . ' */')
      continue
    endif

    " CASE 3: blank line or normal code line
    if l:in_block
      " flush block buffer when leaving comment run
      if !empty(l:block_buffer)
        call add(l:result, '/* ' . join(l:block_buffer, ' ') . ' */')
        let l:block_buffer = []
      endif
      let l:in_block = 0
    endif

    call add(l:result, l:line)
  endfor

  " Flush final block at end of range
  if !empty(l:block_buffer)
    call add(l:result, '/* ' . join(l:block_buffer, ' ') . ' */')
  endif

  " Replace lines in buffer
  call setline(l:start, l:result)
  if len(l:result) < (l:end - l:start + 1)
    call deletebufline('%', l:start + len(l:result), l:end)
  endif
endfunction

vnoremap <leader>c :<C-u>call ConvertAllCommentsToBlocks()<CR>

syntax enable
if !isdirectory(expand("~/.local/share/nvim/undo"))
  call mkdir(expand("~/.local/share/nvim/undo"), "p")
endif

let g:NERDTreeWinPos = 'right'
let g:NERDTreeWinSize = 40
let g:NERDTreeChDirMode = 2
nnoremap <leader>g :NERDTreeFind<CR>
nnoremap <leader>G :NERDTreeToggle<CR>
nnoremap <leader>n :NERDTreeFocus<CR>
nnoremap <leader>e <Cmd>exe v:count1 . "ToggleTerm"<CR>
nnoremap <F5> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>

nnoremap <leader>fb <cmd>lua require('telescope.builtin').buffers({
            \ cwd = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
            \ })<cr>

nnoremap <leader>fh <cmd>lua require('telescope.builtin').help_tags({
            \ cwd = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
            \ })<cr>

for s:i in range(1, 9)
    execute 'nnoremap <silent> <leader>' . s:i .
        \ ' :let g:bufs = getbufinfo({"buflisted": 1}) \|' .
        \ ' if len(g:bufs) >= ' . s:i .
        \ ' \| execute "buffer " . g:bufs[' . (s:i - 1) . ']["bufnr"]' .
        \ ' \| endif<CR>'
endfor

autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif

function! AirlineWeather()
  return luaeval('StatusWeather()')
endfunction

function! AirlineCopilot()
  return luaeval('CopilotStatus()')
endfunction


let g:airline_powerline_fonts = 1
let g:webdevicons_enable_airline_tabline = 1
let g:webdevicons_enable_airline_statusline = 1
" Tabline is handled by bufferline.nvim (see setup below), so disable airline's.
let g:airline#extensions#tabline#enabled = 0
let g:airline#extensions#tabline#formatter = 'default'
let g:airline_theme = 'base16_material_darker'
let g:powerline_pycmd = 'python3'
let g:airline_skip_empty_sections = 1
let g:airline_section_c = ''

call airline#parts#define_function('airline_weather', 'AirlineWeather')
let g:airline_section_x = airline#section#create_right(['airline_weather'])


autocmd User AirlineAfterInit call s:SetupCopilotSection()
function! s:SetupCopilotSection()
  call airline#parts#define_function('airline_copilot', 'AirlineCopilot')
  let g:airline_section_z = airline#section#create(['airline_copilot', ' %p%%', 'linenr', 'maxlinenr', 'colnr'])
endfunction

colorscheme cyberdream

set undofile
set undodir^=~/.local/share/nvim/undo//
set laststatus=2
set termguicolors
set number
set relativenumber
set signcolumn=yes
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set smartindent
set cursorline

highlight CursorLineNr ctermfg=Yellow guifg=Yellow
highlight CursorLine ctermbg=NONE guibg=NONE

command! Wq wq
command! WQ wq
command! W w
command! Q q

set shada=!,'100,<1000,s100,h

"
"let g:neoformat_verilog_verible = {
"      \ 'exe': 'verible-verilog-format',
"      \ 'args': ['--indentation_spaces=4 -'],
"      \ 'stdin': 1,
"      \ }
"let g:neoformat_enabled_verilog = ['verible']
