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

  lockCmd = "${pkgs.i3lock}/bin/i3lock -n -c 000000";
in
{
  nixpkgs.config.allowUnfree = true;

  home.packages = [
    pkgs.kicad
    pkgs.cascadia-code
    pkgs.inter
    pkgs.i3lock
    pkgs.font-awesome
    pkgs.freecad
    pkgs._7zz
    pkgs.discord
    pkgs.pavucontrol
  ];

  fonts.fontconfig.enable = true;

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
      "editor.fontFamily" = "Cascadia Code";
      "editor.inlayHints.fontFamily" = "Cascadia Code";
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
        hostname = "192.168.10.66";
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
      background_opacity = 1.0;

      font = {
        normal = {
          family = "Cascadia Code";
        };
        size = 11;
      };

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

  programs.i3status-rust = {
    enable = true;
    bars =  {
      default = {
        blocks = [
          {
            block = "disk_space";
            path = "/";
            alias = "/";
            info_type = "available";
            unit = "GB";
            interval = 60;
            warning = 20.0;
            alert = 10.0;
          }
          {
            block = "memory";
            display_type = "memory";
            format_mem = "{mem_total_used_percents}";
            format_swap = "{swap_used_percents}";
          }
          {
            block = "cpu";
            interval = 1;
          }
          {
            block = "load";
            format = "{1m}";
            interval = 1;
          }
          {
            block = "sound";
            driver = "pulseaudio";
          }
          {
            block = "time";
            format = "%a %d/%m %R";
            interval = 60;
          }
        ];
        icons = "awesome5";
        settings = {
          theme = {
            name = "solarized-light";
            overrides = {
              separator= " ";
            };
          };
        };
      };
    };
  };

  xsession = {
    enable = true;

    windowManager.i3 = {
      enable = true;

      extraConfig = ''
        title_align center
      '';

      config = {
        modifier = "Mod4";

        colors = {
          background = solarized.base3;

          focused = {
            background = solarized.blue;
            border = solarized.blue;
            # border = solarized.base1;
            childBorder = solarized.base1;
            indicator = solarized.blue;
            text = solarized.base2;
          };

          focusedInactive = {
            #  background = solarized.base2;
            background = solarized.base2;
            border = solarized.base2;
            # border = solarized.magenta;
            childBorder = solarized.base2;
            # childBorder = solarized.magenta;
            indicator = solarized.base2;
            text = solarized.base01;
          };

          placeholder = {
            background = "#0c0c0c";
            border = "#000000";
            childBorder = "#0c0c0c";
            indicator = "#000000";
            text = "#ffffff";
          };

          unfocused = {
            # background = solarized.base3;
            # border = solarized.base1;
            # childBorder = solarized.base1;
            background = solarized.base3;
            border = solarized.base2;
            childBorder = solarized.base2;
            indicator = solarized.base2;
            text = solarized.base00;
          };

          urgent = {
            background = solarized.red;
            border = solarized.red;
            # border = solarized.base1;
            childBorder = solarized.base1;
            indicator = solarized.base1;
            text = solarized.base2;
          };
        };

        window = {
          hideEdgeBorders = "smart";
        };

        terminal = "alacritty";
        menu = "\"rofi -modi combi -combi-modi drun,run -show combi -show-icons\"";

        fonts = {
          names = [ "Inter" "Font Awesome 5 Free" ];
          size = 11.0;
        };

        gaps = {
          inner = 12;
          outer = 0;
        };

        keybindings = let
          mod = config.xsession.windowManager.i3.config.modifier;
        in lib.mkOptionDefault {
          "${mod}+l" = "exec ${lockCmd}";
        };

        bars = [{
          mode = "dock";
          hiddenState = "hide";
          position = "top";
          workspaceButtons = true;
          workspaceNumbers = true;
          statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ${config.xdg.configHome}/i3status-rust/config-default.toml";

          fonts = {
            names = [ "Inter" "Font Awesome 5 Free" ];
            size = 11.0;
          };

          trayOutput = "primary";

          colors = {
            background = solarized.base3;
            statusline = solarized.base00;
            separator = solarized.base0;
            focusedWorkspace = {
              border = solarized.blue;
              background = solarized.blue;
              text = solarized.base2;
            };
            activeWorkspace = {
              border = solarized.base2;
              background = solarized.base2;
              text = solarized.base01;
            };
            inactiveWorkspace = {
              border = solarized.base3;
              background = solarized.base3;
              text = solarized.base00;
            };
            urgentWorkspace = {
              border = solarized.red;
              background = solarized.red;
              text = solarized.base2;
            };
            bindingMode = {
              border = solarized.base1;
              background = solarized.yellow;
              text = solarized.base2;
            };
          };
        }];
      };
    };
  };

  services.picom = {
    enable = true;
    backend = "xrender";
    experimentalBackends = true;
    shadow = true;
    vSync = true;
    opacityRule = [
      "80:class_g =   'i3bar'"
      "90:class_g =   'Alacritty'"
    ];
    extraOptions = ''
      unredir-if-possible = true;

      blur:
      {
        method = "gaussian";
        size = 20;
        deviation = 10;
      };
    '';
  };

  services.dunst = {
    enable = true;
    settings = {
      global = {
        follow = "mouse";
        geometry = "480x5-16+40";
        transparency = 0;
        padding = 8;
        horizontal_padding = 8;
        frame_width = 2;
        frame_color = solarized.base0;
        seperator_color = solarized.base1;
        font = "Inter 11";
      };

      urgency_low = {
        background = solarized.base3;
        foreground = solarized.base00;
        timeout = 10;
      };

      urgency_normal = {
        background = solarized.base3;
        foreground = solarized.base01;
        timeout = 10;
      };

      urgency_critical = {
        background = solarized.base3;
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
#    enable = true;
    interval = "1h";
    imageDirectory = "%h/backgrounds";
  };

  services.screen-locker = {
    enable = true;
    inactiveInterval = 5;
    inherit lockCmd;
  };

  # programs.foot = {
  #   enable = true;
  #   settings = {
  #     main = {
  #       font = "Cascadia Code:size=11";
  #       dpi-aware = "yes";
  #     };
  #   };
  # };

  # wayland.windowManager.sway = {
  #   enable = true;
  #   config = {
  #     modifier = "Mod4";

  #     window = {
  #       hideEdgeBorders = "smart";
  #       titlebar = true;
  #     };

  #     terminal = "foot";

  #     fonts = {
  #       names = [ "Inter" "Font Awesome 5 Free" ];
  #       size = 11.0;
  #     };

  #     gaps = {
  #       inner = 12;
  #       outer = 0;
  #     };
  #   };
  # };

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
