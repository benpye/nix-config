{ config, lib, pkgs, inputs, ... }:

let
  solarized = {
    base03 =  "#002b36";
    base02 =  "#073642";
    base01 =  "#586e75";
    base00 =  "#657b83";
    base0 =   "#839496";
    base1 =   "#93a1a1";
    base2 =   "#eee8d5";
    base3 =   "#fdf6e3";
    yellow =  "#b58900";
    orange =  "#cb4b16";
    red =     "#dc322f";
    magenta = "#d33682";
    violet =  "#6c71c4";
    blue =    "#268bd2";
    cyan =    "#2aa198";
    green =   "#859900";
  };
in
{
  nixpkgs.config.allowUnfree = true;

  home.packages = [
    pkgs.steam
    pkgs.discord
    pkgs.kicad-unstable
  ];

  programs.ncspot = {
    enable = true;
    settings = {
      gapless = true;
      notify = true;
      backend = "rodio";

      theme = {
        background            = solarized.base3;
        primary               = solarized.base00;
        secondary             = solarized.base00;
        title                 = solarized.base01;
        playing               = solarized.yellow;
        playing_selected      = solarized.yellow;
        playing_bg            = solarized.base3;
        highlight             = solarized.base01;
        highlight_bg          = solarized.base2;
        error                 = solarized.red;
        error_bg              = solarized.base3;
        statusbar_progress    = solarized.yellow;
        statusbar_progress_bg = solarized.base00;
        statusbar             = solarized.yellow;
        statusbar_bg          = solarized.base3;
        cmdline               = solarized.base3;
        cmdline_bg            = solarized.base00;
        search_match          = solarized.red;
      };
    };
  };

  programs.firefox = {
    enable = true;
    package = pkgs.firefox-bin;
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
      "window.titleBarStyle" = "custom";
      "window.menuBarVisibility" = "classic";
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
  };

  programs.go = {
    enable = true;
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

      "nixserve" = {
        forwardAgent = true;
      };
    };
  };

  programs.zsh = {
    enable = true;
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
  };

  programs.alacritty = {
    enable = true;
    settings = {
      background_opacity = 0.95;

      window = {
        padding = {
          x = 8;
          y = 8;
        };
      };

      colors = {
        primary = {
          background = solarized.base3;
          foreground = solarized.base01;
        };

        normal = {
          black   = solarized.base02;
          red     = solarized.red;
          green   = solarized.green;
          yellow  = solarized.yellow;
          blue    = solarized.blue;
          magenta = solarized.magenta;
          cyan    = solarized.cyan;
          white   = solarized.base2;
        };

        bright = {
          black   = solarized.orange;
          red     = solarized.base03;
          green   = solarized.base01;
          yellow  = solarized.base00;
          blue    = solarized.base0;
          magenta = solarized.violet;
          cyan    = solarized.base1;
          white   = solarized.base3;
        };
      };
    };
  };

  xsession = {
    enable = true;
    windowManager.i3 = {
      enable = true;
      config = {
        gaps = {
          inner = 16;
          outer = 0;
        };
        terminal = "alacritty";
        menu = "\"rofi -modi combi -combi-modi drun,run -show combi\"";
      };
    };
  };

  services.picom = {
    enable = true;
    backend = "xrender";
    experimentalBackends = true;
    shadow = true;
    vSync = true;
    extraOptions = ''
      unredir-if-possible = true
    '';
  };

  services.dunst = {
    enable = true;
    settings = {
      global = {
        follow = "mouse";
        geometry = "480x5-0-19";
        transparency = 0;
        padding = 16;
        horizontal_padding = 16;
        frame_width = 0;
        seperator_color = "auto";
        font = "Droid Sans Bold 12";
      };

      urgency_low = {
        background = solarized.base03;
        foreground = solarized.base1;
        timeout = 10;
      };

      urgency_normal = {
        background = solarized.base03;
        foreground = solarized.base1;
        timeout = 10;
      };

      urgency_critical = {
        background = solarized.base03;
        foreground = solarized.red;
        timeout = 0;
      };
    };
  };

  services.redshift = {
    enable = true;
    latitude = 49.246292;
    longitude = -123.116226;
    provider = "manual";
    tray = true;
    temperature = {
      day = 6000;
      night = 3500;
    };
  };

  programs.rofi = {
    enable = true;
  };

  xresources.properties = {
    "Xft.dpi" = 96;
  };

  services.random-background = {
    enable = true;
    interval = "1h";
    imageDirectory = "%h/backgrounds";
  };

  home.keyboard.layout = "gb";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.11";
}
