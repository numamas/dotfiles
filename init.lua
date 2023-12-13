local AUGROUP = vim.api.nvim_create_augroup('user_config', { clear = true })

local util = {
    contains = function(tbl, value)
        for _, x in pairs(tbl) do
            if x == value then
                return true
            end
        end
        return false
    end,

    error = function(s)
        vim.cmd(string.format('echoerr "%s"', s))
    end,

    escape = function(s)
        return (s:gsub('[%-%.%+%[%]%(%)%$%^%%%?%*]','%%%1'))
    end,

    filter = function(tbl, fn)
        local out = {}
        for k, v in pairs(tbl) do
            if fn(k, v) then
                if type(k) == 'number' then
                    table.insert(out, v)
                else
                    out[k] = v
                end
            end
        end
        return out
    end,

    peel = function(tbl)
        local out = {}
        for _, outer in pairs(tbl) do
            for k, v in pairs(outer) do
                if type(k) == 'number' then
                    table.insert(out, v)
                else
                    out[k] = v
                end
            end
        end
        return out
    end,

    split = function(s, sep)
        sep = sep or '%s'
        local out = {}
        for x in string.gmatch(s, "([^"..sep.."]+)") do
            table.insert(out, x)
        end
        return out
    end,
}

local set = {
    augroup = function(name)
        vim.api.nvim_create_augroup(name, { clear = true })
    end,

    autocmd = function(event, pattern)
        pattern = pattern or '*'
        return function(opts)
            opts = vim.tbl_deep_extend('keep', opts, { group = AUGROUP, pattern = pattern })
            vim.api.nvim_create_autocmd(event, opts)
        end
    end,

    command = function(name)
        return function(action)
            vim.cmd(string.format('command! %s %s', name, action))
        end
    end,

    highlight = function(name)
        return function(config)
            local s = string.format('hi %s %s', name, config)
            vim.cmd(s)
            vim.api.nvim_create_autocmd('ColorScheme', { group = AUGROUP, pattern = '*', command = s })
        end
    end,

    keymap = function(modes, opts)
        -- * -> map | ! -> map! | n, i, v, ...
        opts = opts or {}
        return function (binds)
            for i = 1, #binds, 2 do
                local lhs = binds[i]
                local rhs = binds[i+1]
                for c = 1, string.len(modes) do
                    local mode = string.sub(modes, c, c)
                    if mode == '*' then
                        mode = ''
                    end
                    -- When rhs contains '<Plug>', 'noremap' option turns false automatically.
                    vim.keymap.set(mode, lhs, rhs, vim.tbl_deep_extend('keep', opts, { silent = true }))
                end
            end
        end
    end,

    section = function(_)
        return function(fns)
            for _, fn in ipairs(fns) do
                fn()
            end
        end
    end,
}

local plugin = {
    list = {},

    finalize = function(self)
        local path = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
        if not vim.loop.fs_stat(path) then
            vim.fn.system({ 'git', 'clone', '--filter=blob:none', 'https://github.com/folke/lazy.nvim.git', '--branch=stable', path })
            print('lazy.nvim has been installed.')
        end
        vim.opt.rtp:prepend(path)
        require('lazy').setup(self.list)
    end,

    register = function(self)
        return function(spec)
            table.insert(self.list, spec)
        end
    end,
}

setmetatable(plugin, { __call = plugin.register })

set.section 'options' {
    function()
        vim.cmd.language 'C'
        vim.o.fileencodings = 'utf-8,cp932,utf-16le,euc-jp'
        vim.o.number = true
        vim.o.showcmd = false
        vim.o.scrolloff = 2
        vim.o.autochdir = true
        vim.o.signcolumn = 'yes'
        vim.o.updatetime = 2000
        vim.o.splitbelow = true
        -- wrap
        vim.o.wrap = false
        vim.o.linebreak = true
        -- search
        vim.o.ignorecase = true
        vim.o.smartcase = true
        -- indent
        vim.o.expandtab = true
        vim.o.tabstop = 4
        vim.o.softtabstop = 0
        vim.o.shiftwidth = 0
        -- invisible characters
        vim.o.list = true
        vim.o.listchars='tab:⋅⋅,extends:>,precedes:<,nbsp:%'
        -- persistent undo
        vim.o.undofile = true
        vim.o.undodir = vim.fn.stdpath('data') .. '/undo'
        -- retain indentation when wrapping
        vim.o.breakindent = true
        -- inhibit automatic commentstring insertion
        set.autocmd('BufEnter') { command = 'setlocal formatoptions-=ro' }
        -- highlight curosline only in insert mode
        set.highlight('CursorLine') [[ctermfg=NONE ctermbg=0 cterm=NONE guifg=NONE guibg=#15171c gui=NONE]]
        set.autocmd('InsertEnter') { command = 'setlocal cursorline' }
        set.autocmd('InsertLeave') { command = 'setlocal nocursorline' }
        -- disable startup message
        vim.opt.shortmess:append('I')
        -- gui support
        if vim.g.nvy then
            vim.o.title = true
            vim.o.guifont = 'HackGen Console NF:h11'
        end
    end
}

set.section 'mapping' {
    function()
        -- disable increment and decrement
        set.keymap('*') {
            '<C-a>', [[<Nop>]],
            '<C-x>', [[<Nop>]],
        }

        -- use blackhole register
        set.keymap('*') {
            'c', [["_c]],
            'C', [["_C]],
            'x', [["_x]],
        }
        set.keymap('x') {
            'p', [["_dP]],
        }

        -- paste (gui)
        set.keymap("*!") {
            '<S-Insert>', [[<C-R>+]]
        }

        -- move cursor based on logical lines
        set.keymap('*') {
            'j', 'gj',
            'k', 'gk',
        }

        -- space-prefixed
        set.keymap('n') {
            '<Space>' , [[<Nop>]],
            '<Space>n', [[:noh<CR>]],
            '<Space>-', [[:split<CR>]],
            '<Space>/', [[:vsplit<CR>]],
            '<Space>c', [[<C-w>c]],
            '<Space>k', [[:bdelete<CR>]],
            '<Space>o', [[:only<CR>]],
            '<Space>w', [[:set wrap!<CR>]],
        }

        -- quickfix
        set.keymap('n') {
            '<C-q>', [[:copen<CR>]],
        }

        -- q to close
        set.autocmd('FileType', { 'help', 'qf', 'fugitive' }) {
            callback = function()
                set.keymap('n', { buffer = true, nowait = true }) {
                    'q', [[<C-w>c]]
                }
            end
        }
    end
}

plugin 'hop.nvim' {
    'phaazon/hop.nvim', branch = 'v2',
    keys = {
        { 's', [[<Cmd>lua require("hop").hint_char1()<CR>]], mode = { 'n', 'x' } },
    },
    config = true,
}

plugin 'mini.nvim' {
    'echasnovski/mini.nvim', branch = 'stable',
    config = function()
        require('mini.align').setup() -- ga / gA

        require('mini.comment').setup {
            mappings = {
                comment      = '<C-_>', -- C-/
                comment_line = '<C-_>',
                textobject   = '<C-_>',
            },
        }

        require('mini.surround').setup {
            mappings = {
                add            = 'S',
                delete         = "ds",
                replace        = "cs",
                find           = '',
                find_left      = '',
                highlight      = '',
                update_n_lines = '',
            },
        }
    end
}

plugin 'vim-indent-object' {
    'michaeljsmith/vim-indent-object'
}

if vim.g.vscode then goto exit end

set.section 'clipboard' {
    function()
        -- automatic detection of clipboard method takes a little time because it calls `excutable` many times.
        -- share/nvim/runtime/autoload/provider/clipboard.vim: provider#clipboard#Executable()
        vim.o.clipboard = 'unnamed,unnamedplus'

        if vim.fn.has('wsl') == 1 then
            vim.g.clipboard = {
                copy = {
                    ['+'] = { 'win32yank.exe', '-i', '--crlf' },
                    ['*'] = { 'win32yank.exe', '-i', '--crlf' },
                },
                paste = {
                    ['+'] = { 'win32yank.exe', '-o', '--lf' },
                    ['*'] = { 'win32yank.exe', '-o', '--lf' },
                },
            }
        elseif vim.env.WAYLAND_DISPLAY ~= '' then
            -- TODO
        elseif vim.env.DISPLAY ~= '' then
            vim.g.clipboard = {
                copy = {
                    ['+'] = { 'xsel', '--nodetach', '-i', '-b' },
                    ['*'] = { 'xsel', '--nodetach', '-i', '-p' },
                },
                paste = {
                    ['+'] = { 'xsel', '-o', '-b' },
                    ['*'] = { 'xsel', '-o', '-p' },
                },
            }
        end
    end
}

set.section 'diff' {
    function()
        vim.opt.fillchars:append('diff: ')

        if vim.wo.diff then
            vim.wo.number = false
            vim.wo.wrap = true

            set.keymap('n') {
                'q'     , ':qa<CR>',
                '<Up>'  , '[czz',
                '<Down>', ']czz',
            }
            set.keymap('x') {
                'do', [[:diffget<CR>]],
                'dp', [[:diffput<CR>]],
            }
        end
    end
}

set.section 'filetypes' {
    function()
        set.autocmd('FileType', 'autohotkey') { command = 'setlocal commentstring=;;%s' }

        set.autocmd('FileType', 'dart') {
            callback = function()
                vim.bo.cindent = true
                vim.bo.vartabstop = '2'
            end
        }

        set.autocmd('FileType', 'go') {
            callback = function()
                vim.bo.expandtab = false
            end
        }

        set.autocmd('FileType', 'sh') {
            callback = function()
                vim.bo.expandtab = false
            end
        }

        -- xml
        set.autocmd('BufRead', '*.scl') { command = 'setlocal filetype=xml' }
        set.autocmd('BufRead', '*.scd') { command = 'setlocal filetype=xml' }
        set.autocmd('BufRead', '*.cid') { command = 'setlocal filetype=xml' }
        set.autocmd('BufRead', '*.icd') { command = 'setlocal filetype=xml' }
    end
}

set.section 'occur' {
    function()
        function _G.occur()
            local org_efm = vim.bo.errorformat
            vim.bo.errorformat = '%f:%l:%m'

            vim.fn.setqflist({})
        end
--  function! s:Occur()
--      let org_efm = &errorformat
--      let &errorformat = '%f:%l:%m'
--
--      " Clear quickfix
--      call setqflist([])
--
--      " Log the current cursor position
--      normal! H
--
--      " Execute occur
--      let expr = 'caddexpr expand("%") . ":" . line(".") . ":" . getline(".")'
--      execute 'silent keepjumps g/' . @/ . '/' . expr
--
--      " Open the results window (and restore cursor position)
--      keepjumps cfirst 1
--      exec "normal! \<C-o>"
--      copen
--
--      " TODO Map the key sequence on the QuickFix
--      " nnoremap <buffer> <silent> <Space> <C-w><C-_>
--      " nnoremap <buffer> <silent> x       10<C-w>_<CR>zxzz:copen<CR>
--      " nnoremap <buffer> <silent> <CR>    <CR>zxzz:cclose<CR>
--      " nnoremap <buffer> <silent> q       :cclose<CR>
--
--      " Restore errorformat
--      let &errorformat = org_efm
--  endfunction
    end
}

set.section 'ruler' {
    function()
        vim.o.laststatus = 1
        vim.o.rulerformat = '%70(%= %{v:lua.ruler_diagnostics()} %{v:lua.ruler_lsp_servers()} %#TabLine#  %{v:lua.ruler_fileinfo()} %P  %)'

        function _G.ruler_fileinfo()
            local indent = function()
                local s = {}

                if vim.bo.vartabstop == '' then
                    table.insert(s, string.format('%s%d', vim.bo.expandtab and 's' or 't', vim.bo.tabstop))
                else
                    table.insert(s, string.format('%s[%d]', vim.bo.expandtab and 's' or 't', vim.bo.vartabstop))
                end

                if vim.bo.softtabstop ~= 0 then
                    table.insert(s, 'sts=' .. vim.bo.softtabstop)
                end
                if vim.bo.shiftwidth ~= 0 then
                    table.insert(s, 'sw=' .. vim.bo.shiftwidth)
                end
                return table.concat(s, ':')
            end

            local items = {}
            if vim.bo.readonly then table.insert(items, '[RO]') end
            if vim.bo.filetype ~= '' then table.insert(items, vim.bo.filetype) else table.insert(items, '-') end
            if vim.bo.fileencoding ~= '' then table.insert(items, vim.bo.fileencoding) else table.insert(items, '-') end
            if vim.bo.bomb then table.insert(items, 'BOM') end
            if vim.bo.fileformat ~= '' then table.insert(items, vim.bo.fileformat) else table.insert(items, '-') end
            table.insert(items, indent())
            return table.concat(items, ' ')
        end

        function _G.ruler_diagnostics()
            local results = {}
            local error = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
            local warn = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
            local info = #vim.diagnostic.get(0, { severity = { max = vim.diagnostic.severity.INFO, min = vim.diagnostic.severity.HINT }})

            if error ~= 0 then table.insert(results, ' ' .. error) end
            if warn ~= 0 then table.insert(results, ' ' .. warn) end
            if info ~= 0 then table.insert(results, ' ' .. info) end

            return table.concat(results, ' ')
        end

        function _G.ruler_lsp_servers()
            local results = {}
            for _, client in ipairs(vim.lsp.get_active_clients { bufnr = 0 }) do
                if client.name == 'null-ls' then
                    for _, source in ipairs(require('null-ls.sources').get_available(vim.bo.filetype)) do
                        table.insert(results, source.name)
                    end
                else
                    table.insert(results, client.name)
                end
            end
            if #results == 0 then
                return ''
            else
                return '(' .. table.concat(results, ' ') .. ')'
            end
        end
    end
}

set.section 'tmux-navigate' {
    function()
        function _G.tmux_navigate(direction) -- direction = 'k' | 'j' | 'h' | 'l'
            local nr = vim.fn.winnr()
            vim.cmd.wincmd(direction)
            if nr == vim.fn.winnr() then
                vim.fn.system('tmux select-pane -' .. vim.fn.tr(direction, 'hjkl', 'LDUR'))
            end
        end

        set.keymap('nixt') {
            '<A-k>', [[<Cmd>call v:lua.tmux_navigate('k')<CR>]],
            '<A-j>', [[<Cmd>call v:lua.tmux_navigate('j')<CR>]],
            '<A-h>', [[<Cmd>call v:lua.tmux_navigate('h')<CR>]],
            '<A-l>', [[<Cmd>call v:lua.tmux_navigate('l')<CR>]],
        }
    end
}

set.section 'winrestview' {
    -- https://stackoverflow.com/questions/4251533/vim-keep-window-position-when-switching-buffers
    function()
        set.autocmd('BufLeave', '*') {
            callback = function()
                vim.b.winview = vim.fn.winsaveview()
            end
        }
        set.autocmd('BufEnter', '*') {
            callback = function()
                if vim.b.winview then
                    vim.fn.winrestview(vim.b.winview)
                end
            end
        }
    end
}

plugin 'zephyr' {
    'glepnir/zephyr-nvim',
    priority = 1000,
    config = function()
        vim.o.background = 'dark'
        vim.o.termguicolors = true
        vim.cmd.colorscheme 'zephyr'

        set.highlight('Visual')     [[guifg=NONE guibg=#2d3f76]]
        set.highlight('Search')     [[guifg=#c8d3f5 guibg=#3e68d7]]
        set.highlight('CurSearch')  [[guifg=#1b1d2b guibg=#ff966c]]
        set.highlight('IncSearch')  [[guifg=#1b1d2b guibg=#ff966c]]

        set.highlight('DiffAdd')    [[ctermfg=NONE ctermbg=22  guifg=NONE guibg=#394634 term=bold]]
        set.highlight('DiffChange') [[ctermfg=NONE ctermbg=17  guifg=NONE guibg=#354257 term=bold]]
        set.highlight('DiffDelete') [[ctermfg=NONE ctermbg=0   guifg=NONE guibg=#000000 term=bold]]
        set.highlight('DiffText')   [[ctermfg=NONE ctermbg=110 guifg=NONE guibg=#37636e term=reverse]]
    end,
}

plugin 'capture.vim' {
    'tyru/capture.vim',
    cmd = 'Capture',
}

plugin 'bufferline.nvim' {
    'akinsho/bufferline.nvim', version = '3.*',
    requires = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        local filter = function(buf, _bufnr)
            local ignore_filetypes = { 'help', 'qf' }
            local ignore_patterns = { }

            for _, ft in ipairs(ignore_filetypes) do
                if vim.bo[buf].filetype == ft then
                    return false
                end
            end

            for _, pat in ipairs(ignore_patterns) do
                if vim.fn.bufname(buf):match(pat) then
                    return false
                end
            end

            return true
        end

        local cycle_buffer = function(forward)
            local init_buf = vim.api.nvim_get_current_buf()
            while true do
                if forward then
                    vim.cmd [[BufferLineCycleNext]]
                else
                    vim.cmd [[BufferLineCyclePrev]]
                end
                local buf = vim.api.nvim_get_current_buf()
                if filter(buf) or buf == init_buf then
                    break
                end
            end
        end

        set.keymap('ni') {
            '<C-PageDown>', function() cycle_buffer(true) end,
            '<C-PageUp>'  , function() cycle_buffer(false) end,
        }

        require('bufferline').setup {
            highlights = {
                buffer_selected = { italic = false },
            },
            options = {
                custom_filter = filter,
            },
        }
    end,
}

plugin 'git-confilict.nvim' {
    'akinsho/git-conflict.nvim', version = "*",
    event = 'VeryLazy',
    config = true,
}

plugin 'gitsigns.nvim' {
    'lewis6991/gitsigns.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    event = 'VeryLazy',
    config = {
        attach_to_untracked = false,
        on_attach = function(bufnr)
            vim.wo[0].signcolumn = 'yes'
            -- TODO
            -- set.keymap('n', { bufnr = 0 }) {
            --     'g.', [[<Cmd>Gitsigns next_hunk<CR>zz']],
            --     'g,', [[<Cmd>Gitsigns prev_hunk<CR>zz']],
            --     'gp', [[<Cmd>Gitsigns preview_hunk<CR>']],
            --     'gs', [[<Cmd>Gitsigns stage_hunk<CR>']],
            --     'gu', [[<Cmd>Gitsigns undo_stage_hunk<CR>']],
            --     'gR', [[<Cmd>Gitsigns reset_hunk<CR>']],
            --     'gd', [[<Cmd>Gitsigns diffthis<CR>']],
            -- }
            vim.api.nvim_buf_set_keymap(bufnr, 'n', 'g.', '<Cmd>Gitsigns next_hunk<CR>zz'    , { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(bufnr, 'n', 'g,', '<Cmd>Gitsigns prev_hunk<CR>zz'    , { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gp', '<Cmd>Gitsigns preview_hunk<CR>'   , { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gs', '<Cmd>Gitsigns stage_hunk<CR>'     , { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gu', '<Cmd>Gitsigns undo_stage_hunk<CR>', { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gR', '<Cmd>Gitsigns reset_hunk<CR>'     , { noremap = true, silent = true })
            vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gd', '<Cmd>Gitsigns diffthis<CR>'       , { noremap = true, silent = true })
        end,
    }
}

plugin 'nvim-autopairs' {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = function()
        require('nvim-autopairs').setup()

        local rule = require('nvim-autopairs.rule')
        local cond = require('nvim-autopairs.conds')

        cond.starts_with = function(s)
            return function(opts)
                return string.match(opts.line, string.format('^%%s*%s', util.escape(s))) ~= nil
            end
        end

        cond.not_contains = function(s)
            return function(opts)
                return string.match(opts.line, util.escape(s)) == nil
            end
        end

        cond.wedged = function(a, b)
            return function(opts)
                return cond.before_text(a)(opts) and cond.after_text(b)(opts)
            end
        end

        local function add_rules(rules)
            for _, entry in ipairs(rules) do
                require('nvim-autopairs').add_rules(entry)
            end
        end

        require('nvim-autopairs').get_rules([[']])[1].not_filetypes = { 'clojure', 'lisp', 'scheme' }
        require('nvim-autopairs').get_rules([[`]])[1].not_filetypes = { 'clojure', 'lisp', 'scheme' }

        add_rules {
            { rule(' ', ' ') :with_pair(cond.wedged('{', '}')) },
            { rule(' ', ' ') :with_pair(cond.wedged('[', ']')) },
            { rule([[```]], [[```]]) },

            -- lua
            { rule('function.*', 'end', 'lua') :end_wise(cond.not_contains('end')) :use_regex(true) },
            { rule('then', 'end', 'lua') :end_wise(cond.starts_with('if')) },
            { rule('do'  , 'end', 'lua') :end_wise(cond.starts_with('for')) },

            -- python
            { rule([[f"]]  , [["]]  , 'python') },
            { rule([[f']]  , [[']]  , 'python') },
            { rule([[f"""]], [["""]], 'python') },
            { rule([[f''']], [[''']], 'python') },
            { rule([[r"]]  , [["]]  , 'python') },
            { rule([[r']]  , [[']]  , 'python') },
            { rule([[r"""]], [["""]], 'python') },
            { rule([[r''']], [[''']], 'python') },

            -- shell
            { rule('then', 'fi', 'sh') :end_wise(cond.starts_with('if')) },
            { rule('do', 'done', 'sh') :end_wise(cond.starts_with('for')) },
            { rule('do', 'done', 'sh') :end_wise(cond.starts_with('while')) },
            { rule('in', 'esac', 'sh') :end_wise(cond.starts_with('case')) },
        }
    end,
}

plugin 'nvim-bqf' {
    'kevinhwang91/nvim-bqf',
    dependencies = { 'junegunn/fzf' , 'junegunn/fzf.vim' },
    ft = 'qf',
    config = function()
        require('bqf').setup()
        set.highlight('BqfPreviewRange') [[guifg=None guibg=NONE gui=underline]]
    end,
}

plugin 'nvim-cmp' {
    'hrsh7th/nvim-cmp',
    dependencies = { 'hrsh7th/cmp-nvim-lsp', 'hrsh7th/cmp-buffer', 'hrsh7th/cmp-nvim-lua', 'hrsh7th/cmp-vsnip', 'hrsh7th/vim-vsnip' },
    event = 'InsertEnter',
    config = function()
        local cmp = require('cmp')

        local super_tab_vsnip = function(forward)
            -- https://github.com/hrsh7th/nvim-cmp/wiki/Example-mappings#vim-vsnip
            local has_words_before = function()
                local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
            end

            local feedkey = function(key, mode)
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
            end

            return cmp.mapping(function(fallback)
                if cmp.visible() then
                    if forward then cmp.select_next_item() else cmp.select_prev_item() end
                elseif vim.fn["vsnip#available"](1) == 1 then
                    feedkey("<Plug>(vsnip-expand-or-jump)", "")
                elseif vim.fn["vsnip#jumpable"](-1) == 1 then
                    feedkey("<Plug>(vsnip-jump-prev)", "")
                elseif has_words_before() then
                    cmp.complete()
                else
                    fallback()
                end
            end, { 'i', 's' })
        end

        cmp.setup {
            preselect = cmp.PreselectMode.None,
            mapping = {
                ['<Tab>'] = super_tab_vsnip(true),
                ['<S-Tab>'] = super_tab_vsnip(false)
            },
            snippet = {
                expand = function(args)
                    vim.fn["vsnip#anonymous"](args.body)
                end,
            },
            sources = cmp.config.sources(
                {{ name = 'nvim_lsp' }, { name = 'vsnip' }},
                {{ name = 'buffer' }},
                {{ name = 'nvim_lua' }}
            ),
        }
    end,
}

plugin 'nvim-ufo' {
    'kevinhwang91/nvim-ufo',
    dependencies = { 'kevinhwang91/promise-async', 'nvim-treesitter/nvim-treesitter' },
    event = 'VeryLazy', -- if being lazy based on keys, first input gets ignored.
    keys = {
        { 't'       , [[<Cmd>lua fold_toggle()<CR>]] },
        { '<Space>t', [[<Cmd>lua require("ufo").openAllFolds()<CR>]] },
        { '<C-t>'   , [[<Cmd>lua require("ufo").closeAllFolds()<CR>]] },
        { 'T'       , [[<Cmd>lua fold_close_same_level()<CR>]] },
        { '<Space>z', [[<Cmd>lua fold_reload()<CR> ]] },
    },
    init = function()
        vim.o.foldlevel = 99
        vim.o.foldlevelstart = 99
        vim.o.foldenable = true
        set.highlight('Folded') [[ctermfg=NONE cterm=NONE guifg=NONE gui=NONE]]
        -- https://github.com/konfekt/fastfold#example-setup
        vim.wo.foldmethod = 'syntax'
        vim.g.clojure_fold     = 1
        vim.g.markdown_folding = 1
        vim.g.sh_fold_enabled  = 7

        -- TODO https://github.com/anasrar/nvim-treesitter-parser-bin/tree/main
        -- function _G.setup_treesitter_parsers()
        --     local path = vim.fn.stdpath('data') .. '/lazy/nvim-treesitter/parser'
        --     local file = path .. '/all.zip'
        --     local url = string.format('https://github.com/anasrar/nvim-treesitter-parser-bin/releases/download/%s/all.zip', vim.fn.has('win32') == 1 and 'window' or 'linux')
        --
        --     print('Downloading treesitter parsers...')
        --     vim.fn.system { 'curl', '-L', url, '-o', file }
        --     if vim.v.shell_error ~= 0 then
        --         util.error('Failed to download.')
        --         return
        --     end
        --
        --     print('Extracting...')
        --     if vim.fn.has('win32') == 1 then
        --         vim.fn.system { 'powershell', '-c', 'Expand-Archive', '-Path', file, '-DestinationPath', path }
        --     else
        --         vim.fn.system { 'unzip', '-o', '-j', file, '-d', path }
        --     end
        --     if vim.v.shell_error ~= 0 then
        --         util.error('Failed to extract.')
        --     end
        --
        --     print('Done.')
        -- end
    end,
    config = function()
        function _G.fold_reload()
            vim.cmd [[mkview]]
            vim.cmd [[edit]]
            vim.cmd [[sleep 100m]] -- wait for the provider of ufo to get prepared
            vim.cmd [[loadview]]
        end

        function _G.fold_toggle()
            local status = tonumber(vim.fn.foldclosed(vim.fn.line('.')))
            if status == -1 then
                pcall(vim.cmd, 'foldclose') -- foldclose is try to fold parent levels
            else
                pcall(vim.cmd, 'foldopen!')
            end
        end

        function _G.fold_close_same_level()
            -- folds the nodes with the same level at the cursor but folded nodes remain closed.
            -- require('ufo').closeFoldsWith(vim.fn.foldlevel(vim.fn.line('.')) - 1)
            local pos = vim.fn.getpos('.')
            local level = vim.fn.foldlevel(vim.fn.line('.'))
            for i = vim.fn.line('^'), vim.fn.line('$') do
                if vim.fn.foldclosed(i) == -1 and vim.fn.foldlevel(i) == level then
                    vim.fn.cursor(i, 0)
                    pcall(vim.cmd, 'foldclose') -- TODO
                end
            end
            vim.fn.setpos('.', pos)
        end

        local function get_foldmethod(bufnr)
            -- Return foldmethod considering ufo's provider.
            if vim.wo.foldmethod ~= 'manual' then
                return vim.wo.foldmethod
            end
            local ok, ufo_main = pcall(require, 'ufo.main')
            if ok then
                for _, info in ipairs(ufo_main.inspectBuf(bufnr)) do
                    local cap = string.match(info, 'Selected provider: (.+)')
                    if cap then
                        return cap
                    end
                end
            end
            return 'manual'
        end

        local function handler(virtText, lnum, endLnum, width, truncate, ctx)
            -- Customize fold text [https://github.com/kevinhwang91/nvim-ufo#customize-fold-text]
            local suffix = ('  ⇣ %d '):format(endLnum - lnum) -- ↯ ↸ ⇣ ⇲ ➤ [https://www.benricho.org/symbol/unicode-arrows.html]
            local newVirtText = {}
            local method = get_foldmethod(ctx.bufnr)

            -- insert ellipsis
            if method ~= 'indent' then
                table.insert(virtText, { ' ⋅⋅⋅ ', 'Comment' })
            end

            -- get virtText of end line and strip unnecessary chunks
            local endVirtText = ctx.get_fold_virt_text(endLnum)
            endVirtText[1][1] = string.gsub(endVirtText[1][1], '^%s*', '')
            if method == 'marker' then
                local cms = '^' .. string.gsub(vim.bo.commentstring, '%%s', '') .. '%s*'
                -- TODO local cms = "^" .. strip(split(vim.bo.commentstring, '%%s')[1]) .. "%s*"
                endVirtText[1][1] = string.gsub(endVirtText[1][1], cms, '')
            elseif method == 'indent' or method == 'diff' then
                endVirtText = {}
            elseif util.contains({'clojure', 'lisp'}, vim.bo.filetype) then  -- FIXME for lisp
                endVirtText = { { ')', 'default'} }
            end

            -- concatenate endVirtText into virtText
            for _, chunk in ipairs(endVirtText) do
                table.insert(virtText, chunk)
            end

            local targetWidth = width - vim.fn.strdisplaywidth(suffix)
            local curWidth = 0
            for _, chunk in ipairs(virtText) do
                local chunkText = chunk[1]
                local chunkWidth = vim.fn.strdisplaywidth(chunkText)
                if targetWidth > curWidth + chunkWidth then
                    table.insert(newVirtText, chunk)
                else
                    chunkText = truncate(chunkText, targetWidth - curWidth)
                    local hlGroup = chunk[2]
                    table.insert(newVirtText, {chunkText, hlGroup})
                    chunkWidth = vim.fn.strdisplaywidth(chunkText)
                    -- str width returned from truncate() may less than 2nd argument, need padding
                    if curWidth + chunkWidth < targetWidth then
                        suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
                    end
                    break
                end
                curWidth = curWidth + chunkWidth
            end
            table.insert(newVirtText, {suffix, 'MoreMsg'})
            return newVirtText
        end

        require('ufo').setup {
            open_fold_hl_timeout = 1, -- 0 value disables the highlight but remains virtTexts
            fold_virt_text_handler = handler,
            enable_get_fold_virt_text = true, -- enable 6th parameters of handler
            provider_selector = function(bufnr, filetype, _buftype)
                if vim.fn.getfsize(vim.api.nvim_buf_get_name(bufnr)) > 10000000 then
                    return 'indent' -- use indent for larger files than 10MB
                elseif util.contains({ 'clojure', 'markdown', 'sh' }, filetype) then
                    return '' -- use foldmethod = syntax | expr
                elseif util.contains({ 'python', 'yaml' }, filetype) then
                    return 'indent'
                else
                    return { 'treesitter', 'indent' }
                end
            end,
        }
    end,
}

plugin 'telescope.nvim' {
    'nvim-telescope/telescope.nvim', branch = '0.1.x',
    dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-tree/nvim-web-devicons',
        'nvim-telescope/telescope-file-browser.nvim',
    },
    keys = {
        { '<C-s>'   , [[<Cmd>lua require('telescope.builtin').current_buffer_fuzzy_find()<CR>]] },
        { '<Space>e', [[<Cmd>lua require('telescope').load_extension('file_browser').file_browser()<CR>]] },
        { '<Space>f', [[<Cmd>lua require('telescope.builtin').find_files()<CR>]] },
        { '<Space>g', [[<Cmd>lua require('telescope.builtin').live_grep()<CR>]] },
        { '<Space>h', [[<Cmd>lua require('telescope.builtin').help_tags()<CR>]] },
        { '<Space>m', [[<Cmd>lua require('telescope.builtin').filetypes()<CR>]] },
        { '<Space>q', [[<Cmd>lua require('telescope.builtin').quickfixhistory()<CR>]] },
        { '<Space>r', [[<Cmd>lua require('telescope.builtin').oldfiles()<CR>]] },
        { '<Space>s', [[<Cmd>lua require('telescope.builtin').grep_string()<CR>]] },
        { '<Space>;', [[<Cmd>lua require('telescope.builtin').buffers()<CR>]] },
        { '<Space>:', [[<Cmd>lua require('telescope.builtin').commands()<CR>]] },
        { '<Space>/', [[<Cmd>lua require('telescope.builtin').search_history(telescope_config())<CR>]] },
        -- TODO use env
        { '<Space>b', [[<Cmd>lua require('telescope.builtin').find_files({ cwd = '~/shared/memo' })<CR>]] },
        { '<Space>B', [[<Cmd>lua require('telescope.builtin').grep_string({ cwd = '~/shared/memo' })<CR>]] },
    },
    config = function()
        require('telescope').setup {
            defaults = {
                -- theme
                results_title = false,
                sorting_strategy = 'ascending',
                layout_strategy = 'vertical',
                layout_config = {
                    preview_cutoff = 1,
                    anchor = 'S',
                    height = 0.9,
                    preview_height = 0.4,
                    prompt_position = 'top',
                },
                borderchars = {
                    prompt = { "─", "│", " ", "│", "╭", "╮", "│", "│" },
                    results = { "─", "│", "─", "│", "├", "┤", "╯", "╰" },
                    preview = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
                },

                -- make ripgrep remove indentation [https://github.com/nvim-telescope/telescope.nvim/wiki/Configuration-Recipes#ripgrep-remove-indentation]
                vimgrep_arguments = { "rg", "--color=never", "--no-heading", "--with-filename", "--line-number", "--column", "--smart-case", "--trim" },

                mappings = {
                    i = {
                        ['<Esc>'] = require('telescope.actions').close,
                        ['<C-g>'] = require('telescope.actions').close,
                    },
                    n = {
                        ['<C-g>'] = require('telescope.actions').close,
                    },
                },
            },

            pickers = {
                buffers = { ignore_current_buffer = true, sort_lastused = true },
                lsp_definitions = { jump_type = 'never' },
            },
        }
    end,
}

plugin 'toggleterm.nvim' {
    'akinsho/toggleterm.nvim', version = '*',
    keys = {
        { '<Space>p' , '<Cmd>ToggleTerm direction=horizontal<CR>' },
        { '<Space>\\', '<Cmd>ToggleTerm direction=float<CR>' },
        { '<Space>y' , '<Cmd>ToggleTermSendCurrentLine<CR>' },
        { '<Space>y' , '<Cmd>ToggleTermSendVisualSelection<CR>', mode = { 'x' } },
    },
    config = function()
        require("toggleterm").setup()
    end,
}

-- TEST
plugin 'vim-bookmarks' {
    'MattesGroeger/vim-bookmarks',
    keys = {
        { 'mm' },
    }
}

::highlight::

plugin 'nvim-pqf' {
    'yorickpeterse/nvim-pqf',
    event = 'VeryLazy',
    config = true,
}

plugin 'rainbow_csv' {
    'mechatroner/rainbow_csv',
    ft = { 'csv', 'tsv' }
}

plugin 'vim-log-highlighting' {
    'MTDL9/vim-log-highlighting',
}

plugin 'vim-ps1' {
    'PProvost/vim-ps1',
    config = function()
        set.autocmd({'BufNewFile', 'BufRead'}, '*.cmd') { command = 'setlocal filetype=ps1' }
        set.autocmd('FileType', 'ps1') { command = 'setlocal fenc=cp932 commentstring=#%s' }
    end
}

::development::

if vim.fn.has('win32') == 1 then goto exit end

packages = {
    lsp = {
        ['efm'] = {},
        ['gopls'] = {},
        ['pyright'] = {},
    },
    dap = {
        ['debugpy'] = {},
        ['delve'] = {},
    },
    linter = {
        ['hadolint'] = { ft = { 'dockerfile' } },
        ['luacheck'] = { ft = { 'lua' }, extra_args = { '--no-global', '--no-max-line-length', '--ignore', '521' } },
        ['shellcheck'] = { ft = { 'sh' }, extra_args = { '-e', '1091', '-e', '2002', '-e', '2004', '-e', '2016', '-e', '2164'} },
    },
    formatter = {
        ['goimports'] = { ft = { 'go' } },
        ['isort'] = { ft = { 'python' } },
    },
}

efm = {
    filetypes = function()
        local results = {}
        for _, specs in pairs { packages.linter, packages.formatter } do
            for _, spec in pairs(specs) do
                for _, filetype in pairs(spec.ft) do
                    table.insert(results, filetype)
                end
            end
        end
        return results
    end,

    languages = function()
        local function efm_extend(base, extra_args)
            if not extra_args then
                return base
            end

            local add_extra_args = function(s)
                return string.gsub(s, '^[^%s]+', '%0 ' .. table.concat(extra_args, ' '))
            end
            if base.formatCommand then
                base.formatCommand = add_extra_args(base.formatCommand)
            elseif base.lintCommand then
                base.lintCommand = add_extra_args(base.lintCommand)
            end
            return base
        end

        local results = {}

        for name, spec in pairs(packages.linter) do
            for _, filetype in pairs(spec.ft) do
                if not results[filetype] then
                    results[filetype] = {}
                end
                table.insert(results[filetype], efm_extend(require(string.format('efmls-configs.linters.%s', name)), spec.extra_args))
            end
        end

        for name, spec in pairs(packages.formatter) do
            for _, filetype in pairs(spec.ft) do
                if not results[filetype] then
                    results[filetype] = {}
                end
                table.insert(results[filetype], efm_extend(require(string.format('efmls-configs.formatters.%s', name)), spec.extra_args))
            end
        end

        return results
    end,
}

plugin 'mason.nvim' {
    'williamboman/mason.nvim',
    build = ':MasonUpdate',
    cmd = { 'Mason', 'MasonInstall', 'MasonUninstall', 'MasonUninstallAll', 'MasonUpdate', 'MasonLog' },
    init = function()
        function _G.setup_manson()
            vim.cmd [[Mason]]
            for k, _ in pairs(util.peel(packages)) do
                local p = require('mason-registry').get_package(k)
                if not p:is_installed() then
                    p:install()
                end
            end
        end
    end,
    config = true,
}

plugin 'nvim-lspconfig' {
    'neovim/nvim-lspconfig',
    dependencies = {
        'williamboman/mason-lspconfig.nvim',
        'creativenull/efmls-configs-nvim',
        'hrsh7th/cmp-nvim-lsp',
        'ray-x/lsp_signature.nvim',
    },
    config = function()
        vim.diagnostic.config {
            float = { source = "always" },
            virtual_text = { prefix = '●', severity_limit = 'Error' },
            severity_sort = true,
        }

        -- customize preview window [https://neovim.discourse.group/t/lsp-hover-float-window-too-wide/3276]
        local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
        function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
          opts = opts or {}
          opts.border = opts.border or 'single'
          opts.max_width= opts.max_width or vim.fn.winwidth(0)
          return orig_util_open_floating_preview(contents, syntax, opts, ...)
        end

        local lsp_on_attach = function(_client, bufnr)
            vim.wo[0].signcolumn = 'yes' -- signcolumn is a window option
            require('lsp_signature').on_attach({ hint_prefix = '' }, bufnr)
            set.keymap('n', { buffer = true }) {
                'K'    , [[<Cmd>lua vim.lsp.buf.hover()<CR>]],
                '<C-k>', [[<Cmd>lua vim.diagnostic.open_float()<CR>]],
                'me'   , [[<Cmd>lua vim.diagnostic.setloclist()<CR>]],
                'mc'   , [[<Cmd>lua vim.lsp.buf.rename()<CR>]],
                'ma'   , [[<Cmd>lua vim.lsp.buf.code_action()<CR>]],
                'mf'   , [[<Cmd>lua vim.lsp.buf.formatting()<CR>]],
                'mr'   , [[<Cmd>lua vim.lsp.buf.references()<CR>]],
                'mi'   , [[<Cmd>lua vim.lsp.buf.implementation()<CR>]],
                'mt'   , [[<Cmd>lua vim.lsp.buf.type_definition()<CR>]],
                'md'   , [[<Cmd>lua vim.lsp.buf.definition()<CR>]],
                'mD'   , [[<Cmd>lua vim.lsp.buf.declaration()<CR>]],
            }
        end

        local config = function(opts)
            opts = opts or {}
            local default = {
                on_attach = lsp_on_attach,
                capabilities = require('cmp_nvim_lsp').default_capabilities(),
                single_file_support = true,
            }
            return vim.tbl_deep_extend('force', default, opts)
        end

        require('mason-lspconfig').setup()
        require('mason-lspconfig').setup_handlers {
            function (server_name)
                local opts = packages.lsp[require('mason-lspconfig.mappings.server').lspconfig_to_package[server_name]]
                if opts ~= nil then
                    require('lspconfig')[server_name].setup(config(opts))
                end
            end,

            ['efm'] = function()
                require('lspconfig').efm.setup(config {
                    init_options = {
                        documentFormatting = true,
                        documentRangeFormatting = true,
                    },
                    filetypes = efm.filetypes(),
                    settings = {
                        rootMarkers = { '.git/' },
                        languages = efm.languages(),
                    },
                })
            end,
        }

        -- TODO format on save
        set.autocmd('BufWritePre') {
            callback = function(ev)
                local efm = vim.lsp.get_active_clients { name = 'efm', bufnr = ev.buf }
                if not vim.tbl_isempty(efm) then
                    vim.lsp.buf.format { name = 'efm' }
                end
            end
        }
    end,
}

plugin 'goto-preview' {
    'rmagatti/goto-preview',
    event = 'LspAttach',
    config = function()
        require('goto-preview').setup()
        set.keymap('n') {
            'm.', [[<Cmd>lua require('goto-preview').goto_preview_definition()<CR>]],
            'm,', [[<Cmd>lua require('goto-preview').close_all_win()<CR>]],
        }
    end,
}

plugin 'fidget.nvim' {
    'j-hui/fidget.nvim', tag = 'legacy',
    event = 'LspAttach',
    config = true,
}

goto exit

plugin 'flutter-tools.nvim' {
    'akinsho/flutter-tools.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    -- TODO dependencies = { 'nvim-lua/plenary.nvim', 'mfussenegger/nvim-dap' },
    event = 'VeryLazy',
    config = {
        statusline = {
            decorations = {
                app_version = true,
                device = true,
                project_config = true,
            },
        },
    },
}

plugin 'vim-translator' {
    'voldikss/vim-translator',
    keys = {
        { '\\e', ':<C-u>Translate --target_lang=en ' },
        { '\\j', ':<C-u>Translate --target_lang=ja ' },
        { '\\d', ':<C-u>Translate --target_lang=de ' },
        { '\\e', ':Translate --target_lang=en<CR>', mode = { 'x' } },
        { '\\j', ':Translate --target_lang=ja<CR>', mode = { 'x' } },
        { '\\d', ':Translate --target_lang=de<CR>', mode = { 'x' } },
        { '\\we', 'viw:Translate --target_lang=en<CR>' },
        { '\\wj', 'viw:Translate --target_lang=ja<CR>' },
        { '\\wd', 'viw:Translate --target_lang=de<CR>' },
    },
    init = function()
        vim.g.translator_target_lang = 'en'
        vim.g.translator_default_engines = { 'google' }
    end
}

::exit::

plugin:finalize()
