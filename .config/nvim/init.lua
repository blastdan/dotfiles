-- ============================================================
-- NEOVIM CONFIG — kickstart.nvim base + agent-first customisations
-- Theme: Catppuccin Macchiato | LSP: TypeScript, Python, Lua
-- ============================================================

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

-- ============================================================
-- OPTIONS
-- ============================================================
vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = 'a'
vim.o.showmode = false
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.inccommand = 'split'
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.confirm = true
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- OSC 52 clipboard (works in tmux + Windows Terminal)
vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
end)

-- ============================================================
-- KEYMAPS
-- ============================================================
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- VSCode-familiar
vim.keymap.set({ 'n', 'i' }, '<C-s>', '<cmd>w<CR><Esc>', { desc = 'Save file' })
vim.keymap.set('n', '<leader>e', '<cmd>Neotree toggle<CR>', { desc = 'Toggle [E]xplorer' })
vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { desc = '[C]ode [A]ction' })
vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { desc = '[R]e[n]ame' })
vim.keymap.set('n', '<leader>fm', function()
  require('conform').format { async = true, lsp_format = 'fallback' }
end, { desc = '[F]or[m]at buffer' })
vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = '[G]oto [D]efinition' })
vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = 'Hover documentation' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Diagnostics
vim.diagnostic.config {
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },
  virtual_text = true,
  jump = { float = true },
}

-- Highlight on yank
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

-- ============================================================
-- LAZY.NVIM BOOTSTRAP
-- ============================================================
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system {
    'git', 'clone', '--filter=blob:none', '--branch=stable',
    'https://github.com/folke/lazy.nvim.git', lazypath,
  }
  if vim.v.shell_error ~= 0 then error('Error cloning lazy.nvim:\n' .. out) end
end
vim.opt.rtp:prepend(lazypath)

-- ============================================================
-- PLUGINS
-- ============================================================
require('lazy').setup({

  -- Detect tabstop/shiftwidth automatically
  { 'NMAC427/guess-indent.nvim', opts = {} },

  -- --------------------------------------------------------
  -- THEME: Catppuccin Macchiato
  -- --------------------------------------------------------
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    opts = {
      flavour = 'macchiato',
      integrations = {
        telescope = true,
        neotree = true,
        which_key = true,
        gitsigns = true,
        mini = { enabled = true },
        treesitter = true,
        mason = true,
      },
    },
    config = function(_, opts)
      require('catppuccin').setup(opts)
      vim.cmd.colorscheme 'catppuccin-macchiato'
    end,
  },

  -- --------------------------------------------------------
  -- KEYBIND HINTS — which-key
  -- --------------------------------------------------------
  {
    'folke/which-key.nvim',
    event = 'VimEnter',
    opts = {
      delay = 300,
      icons = { mappings = vim.g.have_nerd_font },
      spec = {
        { '<leader>s', group = '[S]earch' },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
        { '<leader>c', group = '[C]ode' },
        { 'gr',        group = 'LSP [G]oto' },
      },
    },
  },

  -- --------------------------------------------------------
  -- FILE EXPLORER — neo-tree
  -- --------------------------------------------------------
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      'MunifTanjim/nui.nvim',
    },
    opts = {
      filesystem = {
        filtered_items = { hide_dotfiles = false },
        follow_current_file = { enabled = true },
      },
      window = { width = 35 },
    },
  },

  -- --------------------------------------------------------
  -- SEAMLESS TMUX NAVIGATION — Ctrl-h/j/k/l
  -- --------------------------------------------------------
  {
    'christoomey/vim-tmux-navigator',
    cmd = {
      'TmuxNavigateLeft', 'TmuxNavigateDown',
      'TmuxNavigateUp', 'TmuxNavigateRight',
    },
    keys = {
      { '<C-h>', '<cmd>TmuxNavigateLeft<CR>' },
      { '<C-j>', '<cmd>TmuxNavigateDown<CR>' },
      { '<C-k>', '<cmd>TmuxNavigateUp<CR>' },
      { '<C-l>', '<cmd>TmuxNavigateRight<CR>' },
    },
  },

  -- --------------------------------------------------------
  -- FUZZY FINDER — Telescope
  -- --------------------------------------------------------
  {
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make', cond = function() return vim.fn.executable 'make' == 1 end },
      { 'nvim-telescope/telescope-ui-select.nvim' },
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      require('telescope').setup {
        extensions = { ['ui-select'] = { require('telescope.themes').get_dropdown() } },
      }
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      local builtin = require 'telescope.builtin'
      -- VSCode-style shortcuts
      vim.keymap.set('n', '<leader>ff', builtin.find_files,  { desc = '[F]ind [F]iles' })
      vim.keymap.set('n', '<leader>fg', builtin.live_grep,   { desc = '[F]ind by [G]rep' })
      vim.keymap.set('n', '<leader>fb', builtin.buffers,     { desc = '[F]ind [B]uffers' })
      vim.keymap.set('n', '<leader>fh', builtin.help_tags,   { desc = '[F]ind [H]elp' })
      vim.keymap.set('n', '<leader>fd', builtin.diagnostics, { desc = '[F]ind [D]iagnostics' })
      vim.keymap.set('n', '<leader>fr', builtin.resume,      { desc = '[F]ind [R]esume' })
      vim.keymap.set('n', '<leader>fs', builtin.builtin,     { desc = '[F]ind [S]elect Telescope' })
      vim.keymap.set({ 'n', 'v' }, '<leader>fw', builtin.grep_string, { desc = '[F]ind current [W]ord' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find buffers' })

      vim.keymap.set('n', '<leader>/', function()
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown { previewer = false })
      end, { desc = '[/] Fuzzy search buffer' })
    end,
  },

  -- --------------------------------------------------------
  -- GIT SIGNS
  -- --------------------------------------------------------
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add          = { text = '+' },
        change       = { text = '~' },
        delete       = { text = '_' },
        topdelete    = { text = '‾' },
        changedelete = { text = '~' },
      },
      on_attach = function(bufnr)
        local gs = require 'gitsigns'
        local map = function(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end
        map('n', '<leader>hs', gs.stage_hunk,  { desc = 'Git [H]unk [S]tage' })
        map('n', '<leader>hr', gs.reset_hunk,  { desc = 'Git [H]unk [R]eset' })
        map('n', '<leader>hp', gs.preview_hunk, { desc = 'Git [H]unk [P]review' })
        map('n', '<leader>hb', gs.blame_line,  { desc = 'Git [H]unk [B]lame' })
        map('n', ']h', gs.next_hunk, { desc = 'Next git hunk' })
        map('n', '[h', gs.prev_hunk, { desc = 'Prev git hunk' })
      end,
    },
  },

  -- --------------------------------------------------------
  -- LSP
  -- --------------------------------------------------------
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'mason-org/mason.nvim', opts = {} },
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            vim.keymap.set(mode or 'n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end
          map('grn', vim.lsp.buf.rename,       '[R]e[n]ame')
          map('gra', vim.lsp.buf.code_action,  '[C]ode [A]ction', { 'n', 'x' })
          map('grD', vim.lsp.buf.declaration,  '[G]oto [D]eclaration')
          map('grr', require('telescope.builtin').lsp_references,    '[G]oto [R]eferences')
          map('gri', require('telescope.builtin').lsp_implementations,'[G]oto [I]mplementation')
          map('grd', require('telescope.builtin').lsp_definitions,    '[G]oto [D]efinition')

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method('textDocument/inlayHint', event.buf) then
            -- Inlay hints are OFF by default; toggle with <leader>ti
            vim.lsp.inlay_hint.enable(false, { bufnr = event.buf })
            map('<leader>ti', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle [I]nlay Hints')
          end
        end,
      })

      local servers = {
        -- TypeScript / JavaScript
        ts_ls = {},
        -- Python
        pyright = {},
        -- Shell
        bashls = {},
        -- YAML
        yamlls = {},
        -- JSON
        jsonls = {},
        -- Lua
        lua_ls = {
          settings = {
            Lua = {
              runtime = { version = 'LuaJIT' },
              workspace = { checkThirdParty = false },
            },
          },
        },
      }

      require('mason-tool-installer').setup {
        ensure_installed = vim.list_extend(vim.tbl_keys(servers), {
          'stylua', 'prettier', 'ruff',
        }),
      }

      for name, server in pairs(servers) do
        vim.lsp.config(name, server)
        vim.lsp.enable(name)
      end
    end,
  },

  -- --------------------------------------------------------
  -- FORMATTING — conform.nvim
  -- --------------------------------------------------------
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    opts = {
      format_on_save = { timeout_ms = 500, lsp_format = 'fallback' },
      formatters_by_ft = {
        lua        = { 'stylua' },
        javascript = { 'prettier' },
        typescript = { 'prettier' },
        javascriptreact = { 'prettier' },
        typescriptreact = { 'prettier' },
        json       = { 'prettier' },
        css        = { 'prettier' },
        html       = { 'prettier' },
        markdown   = { 'prettier' },
        python     = { 'ruff_format' },
      },
    },
  },

  -- --------------------------------------------------------
  -- AUTOCOMPLETION — blink.cmp
  -- --------------------------------------------------------
  {
    'saghen/blink.cmp',
    event = 'VimEnter',
    version = '1.*',
    dependencies = { { 'L3MON4D3/LuaSnip', version = '2.*', opts = {} } },
    opts = {
      keymap = { preset = 'super-tab' },
      appearance = { nerd_font_variant = 'mono' },
      completion = { documentation = { auto_show = true, auto_show_delay_ms = 300 } },
      sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
      snippets = { preset = 'luasnip' },
      fuzzy = { implementation = 'lua' },
      signature = { enabled = true },
    },
  },

  -- --------------------------------------------------------
  -- TREESITTER
  -- --------------------------------------------------------
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    branch = 'main',
    build = ':TSUpdate',
    config = function()
      local parsers = {
        'bash', 'c', 'diff', 'html', 'lua', 'luadoc',
        'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc',
        'typescript', 'javascript', 'tsx', 'python', 'json', 'yaml', 'toml',
      }
      require('nvim-treesitter').install(parsers)

      local function treesitter_try_attach(buf, language)
        if not vim.treesitter.language.add(language) then return end
        vim.treesitter.start(buf, language)
        local has_indent = vim.treesitter.query.get(language, 'indents') ~= nil
        if has_indent then vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
      end

      local available = require('nvim-treesitter').get_available()
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          local language = vim.treesitter.language.get_lang(args.match)
          if not language then return end
          local installed = require('nvim-treesitter').get_installed 'parsers'
          if vim.tbl_contains(installed, language) then
            treesitter_try_attach(args.buf, language)
          elseif vim.tbl_contains(available, language) then
            require('nvim-treesitter').install(language):await(function()
              treesitter_try_attach(args.buf, language)
            end)
          end
        end,
      })
    end,
  },

  -- --------------------------------------------------------
  -- MINI.NVIM (statusline, surround, ai textobjects, pairs)
  -- --------------------------------------------------------
  {
    'nvim-mini/mini.nvim',
    config = function()
      require('mini.ai').setup { n_lines = 500 }
      require('mini.surround').setup()
      require('mini.pairs').setup()
      require('mini.comment').setup()
      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }
      statusline.section_location = function() return '%2l:%-2v' end
    end,
  },

  -- --------------------------------------------------------
  -- TODO COMMENTS
  -- --------------------------------------------------------
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },

}, {
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘', config = '🛠', event = '📅', ft = '📂',
      init = '⚙', keys = '🗝', plugin = '🔌', runtime = '💻',
      require = '🌙', source = '📄', start = '🚀', task = '📌', lazy = '💤 ',
    },
  },
})

-- vim: ts=2 sts=2 sw=2 et
