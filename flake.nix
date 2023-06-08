{
  description = "Nik's Neovim Configuration";
  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    clipboard-image.url = "github:ekickx/clipboard-image.nvim";
    clipboard-image.flake = false;
  };
  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (self: super: {
            vimPlugins =
              super.vimPlugins
              // {
                clipboard-image = super.vimUtils.buildVimPluginFrom2Nix {
                  name = "clipboard-image.nvim";
                  pname = "clipboard-image.nvim";
                  src = inputs.clipboard-image;
                  # buildInputs = [ super.curl ];
                };
              };
          })
        ];
      };

      recursiveMerge = attrList: let
        f = attrPath:
          builtins.zipAttrsWith (n: values:
            if pkgs.lib.tail values == []
            then pkgs.lib.head values
            else if pkgs.lib.all pkgs.lib.isList values
            then pkgs.lib.unique (pkgs.lib.concatLists values)
            else if pkgs.lib.all pkgs.lib.isAttrs values
            then f (attrPath ++ [n]) values
            else pkgs.lib.last values);
      in
        f [] attrList;
    in rec {
      dependencies = with pkgs;
        [
          fd
          ripgrep
          fzy
          zoxide
          bat # previewer for telescope for now
          zk # lsp for markdown notes
          zsh # terminal requires it
          git
          curl # needed to fetch titles from urls
          # todo: research https://github.com/artempyanykh/marksman
          vale # linter for prose
          proselint # ditto
          luaformatter # ditto for lua
          prisma-engines # ditto for schema.prisma files
          #rnix-lsp # nix lsp -- appears to be abandoned?
          nil # nix lsp -- better than rnix?
          #nixfmt # nix formatter used with null-ls
          alejandra # nix formatter alternative
          statix # linter for nix
          shellcheck
          # luajitPackages.lua-lsp
          lua-language-server
          nodePackages.eslint_d # js/ts code formatter and linter
          nodePackages.prettier # ditto
          nodePackages.vscode-langservers-extracted # lsp servers for json, html, css
          nodePackages.svelte-language-server
          nodePackages.diagnostic-languageserver
          nodePackages.typescript-language-server
          nodePackages.bash-language-server
          nodePackages."@tailwindcss/language-server"
          python310Packages.python-lsp-server # todo: is specifying 310 an issue?
          metals # lsp for scala
        ]
        ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
          ueberzug
          xclip # needed by vim clipboard-image plugin
          wl-clipboard # needed by vim clipboard-image plugin
        ]
        ++ pkgs.lib.optionals pkgs.stdenv.isDarwin
        [pngpaste]; # needed by vim clipboard-image plugin
      neovim-augmented = recursiveMerge [
        pkgs.neovim-unwrapped
        {buildInputs = dependencies;}
      ];
      packages.nvim = pkgs.wrapNeovim neovim-augmented {
        viAlias = true;
        vimAlias = true;
        withNodeJs = false;
        withPython3 = false;
        withRuby = false;
        extraPython3Packages = false;
        extraMakeWrapperArgs = ''--prefix PATH : "${pkgs.lib.makeBinPath dependencies}"'';
        # make sure impatient is loaded before everything else to speed things up
        configure = {
          customRC =
            ''
              lua << EOF
                package.path = "${self}/?.lua;" .. package.path
            ''
            + pkgs.lib.readFile ./init.lua
            + ''
              EOF
            '';
          packages.myPlugins = with pkgs.vimPlugins; {
            start = with pkgs.vimPlugins;
              [
                vim-rhubarb
                vim-sleuth
                nvim-lspconfig
                mason-nvim
                mason-lspconfig-nvim
                fidget-nvim
                neodev-nvim
                plenary-nvim
                copilot-vim
                

                # UI #################################################
                onedarkpro-nvim # colorscheme
                ir_black # colorscheme for basic terminals
                telescope-nvim # da best popup fuzzy finder
                telescope-fzy-native-nvim # with fzy gives better results
                telescope-frecency-nvim # and frecency comes in handy too
                
                nvim-colorizer-lua # color over CSS like #00ff00
                nvim-web-devicons # makes things pretty; used by many plugins below
                nvim-tree-lua # file navigator
                gitsigns-nvim # git status in gutter
                symbols-outline-nvim # navigate the current file better
                lualine-nvim # nice status bar at bottom
                vim-bbye # fix bdelete buffer stuff needed with bufferline
                bufferline-nvim
                indent-blankline-nvim # visual indent
                toggleterm-nvim # better terminal management
                #nvim-treesitter.withAllGrammars # better code coloring (not sure withAllGrammars works anymore)
                (nvim-treesitter.withPlugins (_: pkgs.tree-sitter.allGrammars)) # better code coloring
                playground # treesitter playground
                nvim-treesitter-textobjects # jump around and select based on syntax (class, function, etc.)
                nvim-treesitter-context # keep current block header (func defn or whatever) on first line
                lf-vim

                # Editor Features ####################################
                vim-abolish # better abbreviations / spelling fixer
                nvim-surround # .... updated lua-based alternative to tpope's surround
                vim-unimpaired # bunch of convenient navigation key mappings
                vim-repeat # supports all of the above so you can use .
                vim-rsi # brings keyline bindings to editing (like ctrl-e for end of line when in insert mode)
                vim-visualstar # press * or # on a word to find it
                comment-nvim # code commenter
                #nvim-ts-context-commentstring # makes kommentary contextual for embedded languages
                vim-eunuch # brings cp/mv type commands. :Rename and :Move are particularly handy
                vim-speeddating # allows ctrl-x and ctrl-a to increment/decrement dates

                # Database interactions
                vim-dadbod
                vim-dadbod-ui
                vim-dadbod-completion

                # Autocompletion
                nvim-cmp # generic autocompleter
                cmp-nvim-lsp # use lsp as source for completions
                cmp-nvim-lua # makes vim config editing better with completions
                cmp-buffer # any text in open buffers
                cmp-path # complete paths
                cmp-cmdline # completing in :commands
                cmp-emoji # complete :emojis:
                cmp-nvim-lsp-signature-help # help complete function call by showing args
                cmp-npm # complete node packages in package.json
                nvim-autopairs # balances parens as you type
                nvim-ts-autotag # balance or rename html
                vim-emoji # TODO: redundant now?
                luasnip # snippets driver
                cmp_luasnip # snippets completion
                friendly-snippets # actual library of snippets used by luasnip

                # writing
                zk-nvim # lsp for a folder of notes for searching/linking/etc.
                true-zen-nvim # distraction free, width constrained writing mode
                # twilight-nvim # dim text outside of current scope

                # Misc
                vim-fugitive # git management
                diffview-nvim
                project-nvim
                vim-tmux-navigator # navigate vim and tmux panes together
                impatient-nvim # speeds startup times by caching lua bytecode
                which-key-nvim
                #vim-startuptime
              ]
              ++ pkgs.lib.optionals (!pkgs.stdenv.isDarwin) [
                telescope-media-files-nvim # only works on linux, requires ueberzug, but gives image preview
              ];
            opt = with pkgs.vimPlugins; [
              # grammar check
              vim-grammarous
              # see note about hologram in markdown.lua file. commented out 2023-01-19
              #hologram-nvim # images inline for markdown (only in terminal)
              direnv-vim # auto-execute nix direnv setups -- currently my slowest plugin; enabled by programming filetype
              clipboard-image # only loaded in markdown files
            ];
          };
        };
      };
      apps.nvim = flake-utils.lib.mkApp {
        drv = packages.nvim;
        name = "nvim";
        exePath = "/bin/nvim";
      };
      packages.default = packages.nvim;
      apps.default = apps.nvim;
      devShell = pkgs.mkShell {
        buildInputs = with pkgs; [packages.nvim] ++ dependencies;
      };
    });
}
