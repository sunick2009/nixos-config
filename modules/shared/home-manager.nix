{ config, pkgs, lib, ... }:

let
  name = "sunick2009";
  user = "susu";
  email = "sunick2009@gmail.com";
  atuinWithSecrets = pkgs.writeShellScriptBin "atuin" ''
    env_file="$HOME/.atuin-sync.env"
    if [ -f "$env_file" ]; then
      set -a
      . "$env_file"
      set +a
    fi

    exec ${pkgs.atuin}/bin/atuin "$@"
  '';
in
{
  # zsh is managed by chezmoi (dot_zshrc in my-dotfiles).
  # home-manager no longer generates ~/.zshrc to avoid conflicts.
  # zsh shell is set at the system level (users.users.susu.shell = pkgs.zsh).

  git = {
    enable = true;
    ignores = [ "*.swp" ".DS_Store"  "**/.DS_Store"];
    lfs = {
      enable = true;
    };
    settings = {
      user = {
        name = name;
        email = email;
        signingkey = "229B5A8D63E1795F";
      };
      init.defaultBranch = "main";
      core = {
	    editor = "vim";
        autocrlf = "input";
      };
      commit.gpgsign = false;
      pull.rebase = true;
      rebase.autoStash = true;
    };
  };

  gpg = {
    enable = true;
    settings = {
      trust-model = "tofu+pgp";
    };
  };

  # vim = {
  #   enable = true;
  #   plugins = with pkgs.vimPlugins; [ vim-airline vim-airline-themes vim-startify vim-tmux-navigator ];
  #   settings = { ignorecase = true; };
  #   extraConfig = ''
  #     "" General
  #     set number
  #     set history=1000
  #     set nocompatible
  #     set modelines=0
  #     set encoding=utf-8
  #     set scrolloff=3
  #     set showmode
  #     set showcmd
  #     set hidden
  #     set wildmenu
  #     set wildmode=list:longest
  #     set cursorline
  #     set ttyfast
  #     set nowrap
  #     set ruler
  #     set backspace=indent,eol,start
  #     set laststatus=2
  #     set clipboard=autoselect

  #     " Dir stuff
  #     set nobackup
  #     set nowritebackup
  #     set noswapfile
  #     set backupdir=~/.config/vim/backups
  #     set directory=~/.config/vim/swap

  #     " Relative line numbers for easy movement
  #     set relativenumber
  #     set rnu

  #     "" Whitespace rules
  #     set tabstop=8
  #     set shiftwidth=2
  #     set softtabstop=2
  #     set expandtab

  #     "" Searching
  #     set incsearch
  #     set gdefault

  #     "" Statusbar
  #     set nocompatible " Disable vi-compatibility
  #     set laststatus=2 " Always show the statusline
  #     let g:airline_theme='bubblegum'
  #     let g:airline_powerline_fonts = 1

  #     "" Local keys and such
  #     let mapleader=","
  #     let maplocalleader=" "

  #     "" Change cursor on mode
  #     :autocmd InsertEnter * set cul
  #     :autocmd InsertLeave * set nocul

  #     "" File-type highlighting and configuration
  #     syntax on
  #     filetype on
  #     filetype plugin on
  #     filetype indent on

  #     "" Paste from clipboard
  #     nnoremap <Leader>, "+gP

  #     "" Copy from clipboard
  #     xnoremap <Leader>. "+y

  #     "" Move cursor by display lines when wrapping
  #     nnoremap j gj
  #     nnoremap k gk

  #     "" Map leader-q to quit out of window
  #     nnoremap <leader>q :q<cr>

  #     "" Move around split
  #     nnoremap <C-h> <C-w>h
  #     nnoremap <C-j> <C-w>j
  #     nnoremap <C-k> <C-w>k
  #     nnoremap <C-l> <C-w>l

  #     "" Easier to yank entire line
  #     nnoremap Y y$

  #     "" Move buffers
  #     nnoremap <tab> :bnext<cr>
  #     nnoremap <S-tab> :bprev<cr>

  #     "" Like a boss, sudo AFTER opening the file to write
  #     cmap w!! w !sudo tee % >/dev/null

  #     let g:startify_lists = [
  #       \ { 'type': 'dir',       'header': ['   Current Directory '. getcwd()] },
  #       \ { 'type': 'sessions',  'header': ['   Sessions']       },
  #       \ { 'type': 'bookmarks', 'header': ['   Bookmarks']      }
  #       \ ]

  #     let g:startify_bookmarks = [
  #       \ '~/Projects',
  #       \ '~/Documents',
  #       \ ]

  #     let g:airline_theme='bubblegum'
  #     let g:airline_powerline_fonts = 1
  #     '';
  #    };

  alacritty = {
    enable = false;
    settings = {
      cursor = {
        style = "Block";
      };

      window = {
        opacity = 1.0;
        padding = {
          x = 24;
          y = 24;
        };
      };

      font = {
        normal = {
          family = "MesloLGS NF";
          style = "Regular";
        };
        size = lib.mkMerge [
          (lib.mkIf pkgs.stdenv.hostPlatform.isLinux 10)
          (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin 14)
        ];
      };


      colors = {
        primary = {
          background = "0x1f2528";
          foreground = "0xc0c5ce";
        };

        normal = {
          black = "0x1f2528";
          red = "0xec5f67";
          green = "0x99c794";
          yellow = "0xfac863";
          blue = "0x6699cc";
          magenta = "0xc594c5";
          cyan = "0x5fb3b3";
          white = "0xc0c5ce";
        };

        bright = {
          black = "0x65737e";
          red = "0xec5f67";
          green = "0x99c794";
          yellow = "0xfac863";
          blue = "0x6699cc";
          magenta = "0xc594c5";
          cyan = "0x5fb3b3";
          white = "0xd8dee9";
        };
      };
    };
  };

  ssh = {
    enable = true;
    enableDefaultConfig = true;
    includes = [
      (lib.mkIf pkgs.stdenv.hostPlatform.isLinux
        "/home/${user}/.ssh/config_external"
      )
      (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin
        "/Users/${user}/.ssh/config_external"
      )
    ];
    matchBlocks = {
      "github.com" = {
        identitiesOnly = true;
        identityFile = [
          (lib.mkIf pkgs.stdenv.hostPlatform.isLinux
            "/home/${user}/.ssh/id_ed25519"
          )
          (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin
            "/Users/${user}/.ssh/id_ed25519"
          )
        ];
      };
    };
  };

  atuin = {
    enable = true;
    package = atuinWithSecrets;
    settings = {
      sync = {
        records = true;
      };
      auto_sync = true;
      sync_frequency = "1h";
    };
  };

  # tmux is managed by chezmoi (dot_tmux.conf in my-dotfiles) via TPM.
  # home-manager no longer generates ~/.tmux.conf to avoid conflicts.
  # The tmux binary is provided by shared/packages.nix.
}
