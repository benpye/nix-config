{ config, lib, pkgs, inputs, ... }:
{
  nixpkgs.config = {
    allowUnfree = true;
  };

  home.packages = [
    pkgs.intel-one-mono
    pkgs.inter
    pkgs.discord
    pkgs.steam
    pkgs.rust-analyzer
    pkgs.rustc
    pkgs.cargo
    pkgs.vuescan
    pkgs.darktable
    pkgs.streamrip-dev
  ];

  home.sessionVariables = {
    NIXOS_OZONE_WL = 1;
    WLR_NO_HARDWARE_CURSORS = 1;
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh";
  };

  fonts.fontconfig.enable = true;

  programs.firefox = {
    enable = true;
    package = pkgs.firefox;
    profiles.default.settings = {
      "browser.contentblocking.category" = "strict";
      "browser.search.isUS" = false;
      "browser.search.region" = "CA";
      "gfx.webrender.all" = true;
      "gfx.webrender.compositor" = true;
      "gfx.webrender.enabled" = true;
    };
  };

  programs.vscode = {
    enable = true;
    userSettings = {
      "update.mode" = "none";
      "editor.renderWhitespace" = "all";
      "workbench.colorTheme" = "Solarized Light";
      "files.insertFinalNewline" = "true";
      "files.trimTrailingWhitespace" = "true";
      "window.titleBarStyle" = "native";
      "window.menuBarVisibility" = "toggle";
      "editor.fontFamily" = "konsole";
      "editor.inlayHints.fontFamily" = "Intel One Mono";
      "markdown.preview.fontFamily" = "Inter";
      "terminal.external.linuxExec" = "alacritty";
    };
  };

  programs.git = {
    enable = true;
    signing = {
      key = "0CCA2992";
      signByDefault = true;
    };
    userEmail = "ben@curlybracket.co.uk";
    userName = "Ben Pye";
    extraConfig = {
      init = {
        defaultBranch = "main";
      };
    };
  };

  programs.gpg = {
    enable = true;
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "*" = {
        user = "ben";
        extraOptions = {
          ControlMaster = "auto";
          ControlPath = "~/.ssh/sockets/%r@%h-%p";
          ControlPersist = "600";
        };
      };

      "routenix" = {
        forwardAgent = true;
        hostname = "192.168.1.1";
      };

      "nixserve" = {
        forwardAgent = true;
        hostname = "192.168.1.20";
      };
    };
  };

  programs.bash = {
   enable = true;
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentryPackage = pkgs.pinentry-qt;
  };

  programs.emacs = {
    enable = true;
    package = pkgs.emacs29-pgtk;
    extraPackages = epkgs: with epkgs; [
      treesit-grammars.with-all-grammars
      nix-ts-mode
      modus-themes
      corfu
    ];
    extraConfig = ''
      (when (display-graphic-p)
        (tool-bar-mode 0))
      (use-package modus-themes)
      (load-theme 'modus-operandi-tinted)

      (add-to-list 'default-frame-alist '(font . "Intel One Mono-11"))

      (column-number-mode)

      ;; Show stray whitespace
      (setq-default show-trailing-whitespace t)
      (setq-default indicate-empty-lines t)
      (setq-default indicate-buffer-boundaries 'left)

      ;; Require newline at end of file
      (setq-default require-final-newline t)

      ;;Use spaces for indentations
      (setq-default indent-tabs-mode nil)

      ;; Set default indent
      (setq-default tab-width 4)

      ;; Highlight matching parens
      (setq show-paren-delay 0)
      (show-paren-mode)

      ;; Do not move the current file whilst creating backup
      (setq backup-by-copying t)

      ;; Show line numbers
      (global-display-line-numbers-mode)

      ;; Corfu for completion
      (use-package corfu
       :init
       (global-corfu-mode))

      ;; Enable rust-ts-mode
      (require 'rust-ts-mode)

      ;; Enable nix-ts-mode for .nix files
      (use-package nix-ts-mode
       :mode "\\.nix\\'")
    '';
  };

  programs.beets = {
    enable = true;
    settings = {
      plugins = "the fetchart scrub replaygain zero edit convert";
      per_disc_numbering = true;
      import = {
        timid = true;
      };
      paths = {
        default = "%the{$albumartist}/$original_year - $album%aunique{}/$disc-$track $title";
        singleton = "Non-Album/%the{$artist}/$original_year - $title";
        comp = "Various Artists/$original_year - $album%aunique{}/$disc-$track $title";
      };
      replaygain = {
        backend = "ffmpeg";
      };
      zero = {
        fields = "images";
      };
      convert = {
        copy_album_art = true;
        album_art_maxwidth = 256;
        embed = false;
        max_bitrate = 1;
        never_convert_lossy_files = true;
        formats = {
          flac_portable = let
            convert_script = pkgs.writeShellScript "convert_to_portable_flac" ''
              target_sample_rate="48000"
              target_bit_depth="16"

              sample_rate=$(${pkgs.sox}/bin/soxi -r "$1")
              bit_depth=$(${pkgs.sox}/bin/soxi -b "$1")

              if [ "$sample_rate" -le "$target_sample_rate" ] && [ "$bit_depth" -le "$target_bit_depth" ]; then
                cp "$1" "$2"
              else
                if [ "$sample_rate" -lt "$target_sample_rate" ]; then
                  target_sample_rate="$sample_rate"
                elif [ "$sample_rate" -eq "88200" ] || [ "$sample_rate" -eq "176400" ] || [ "$sample_rate" -eq "352800" ]; then
                  target_sample_rate="44100"
                fi

                ${pkgs.sox}/bin/sox "$1" -G -b $target_bit_depth -r $target_sample_rate "$2"
              fi
            '';
          in {
            command = "${convert_script} $source $dest";
            extension = "flac";
          };
        };
      };
    };
  };

  home.keyboard.layout = "us";
  #
  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "23.11";
}
