return {
    {
        "bjarneo/aether.nvim",
        branch = "v2",
        name = "aether",
        priority = 1000,
        opts = {
            transparent = false,
            colors = {
                -- Background colors
                bg = "#030000",
                bg_dark = "#030000",
                bg_highlight = "#ae3a3a",

                -- Foreground colors
                -- fg: Object properties, builtin types, builtin variables, member access, default text
                fg = "#FEFCFF",
                -- fg_dark: Inactive elements, statusline, secondary text
                fg_dark = "#FEFCFF",
                -- comment: Line highlight, gutter elements, disabled states
                comment = "#ae3a3a",

                -- Accent colors
                -- red: Errors, diagnostics, tags, deletions, breakpoints
                red = "#ff2936",
                -- orange: Constants, numbers, current line number, git modifications
                orange = "#ff858c",
                -- yellow: Types, classes, constructors, warnings, numbers, booleans
                yellow = "#ff476e",
                -- green: Comments, strings, success states, git additions
                green = "#7E81E1",
                -- cyan: Parameters, regex, preprocessor, hints, properties
                cyan = "#7565CF",
                -- blue: Functions, keywords, directories, links, info diagnostics
                blue = "#A398EE",
                -- purple: Storage keywords, special keywords, identifiers, namespaces
                purple = "#fc69fa",
                -- magenta: Function declarations, exception handling, tags
                magenta = "#ffc2fe",
            },
        },
        config = function(_, opts)
            require("aether").setup(opts)
            vim.cmd.colorscheme("aether")

            -- Enable hot reload
            require("aether.hotreload").setup()
        end,
    },
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "aether",
        },
    },
}
