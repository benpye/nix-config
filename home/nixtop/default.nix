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
  nixpkgs.config = {
    allowUnfree = true;
    # firefox.enablePlasmaBrowserIntegration = true;
  };

  home.packages = [
    pkgs.kicad
    pkgs.cascadia-code
    pkgs.inter
    pkgs.freecad
    pkgs._7zz
    pkgs.discord
    pkgs.eclipses.eclipse-java
    pkgs.openjdk11
    pkgs.steam
    pkgs.plasma-integration
    pkgs.plasma-browser-integration
    pkgs.cider
  ];

  home.file.".mozilla/native-messaging-hosts".source = pkgs.symlinkJoin {
    name = "native-messaging-hosts";
    paths = [
      "${pkgs.plasma-browser-integration}/lib/mozilla/native-messaging-hosts"
    ];
  };

  systemd.user.sessionVariables = {
    MOZ_ENABLE_WAYLAND = 1;
    #NIXOS_OZONE_WL = 1;
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
      font = {
        normal = {
          family = "Cascadia Code";
        };
        size = 11;
      };

      window = {
        opacity = 1.0;
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

  services.kdeconnect.enable = true;

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
