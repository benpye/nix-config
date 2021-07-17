self: super:
{
  qemu6 = super.qemu.overrideAttrs (oldAttrs: rec {
    version = "6.0.0";

    src = super.fetchurl {
      url= "https://download.qemu.org/qemu-${version}.tar.xz";
      sha256 = "sha256-h7waRxyiS5fnAFcRBmAH1ENCPRmqzaPUQlWK4DL6MLk=";
    };
  } // (super.lib.optionalAttrs (super.pkgs.stdenv.isDarwin && super.pkgs.stdenv.isAarch64)) rec {
    patches = oldAttrs.patches ++ [
      ./patches/0001-meson-Add-implicit_include_directories-parameter.patch
      ./patches/0002-hvf-Move-assert_hvf_ok-into-common-directory.patch
      ./patches/0003-hvf-Move-vcpu-thread-functions-into-common-directory.patch
      ./patches/0004-hvf-Move-cpu-functions-into-common-directory.patch
      ./patches/0005-hvf-Move-hvf-internal-definitions-into-common-header.patch
      ./patches/0006-hvf-Make-hvf_set_phys_mem-static.patch
      ./patches/0007-hvf-Remove-use-of-hv_uvaddr_t-and-hv_gpaddr_t.patch
      ./patches/0008-hvf-Split-out-common-code-on-vcpu-init-and-destroy.patch
      ./patches/0009-hvf-Use-cpu_synchronize_state.patch
      ./patches/0010-hvf-Make-synchronize-functions-static.patch
      ./patches/0011-hvf-Remove-hvf-accel-ops.h.patch
      ./patches/0012-hvf-Introduce-hvf-vcpu-struct.patch
      ./patches/0013-hvf-Simplify-post-reset-init-loadvm-hooks.patch
      ./patches/0014-hvf-Add-Apple-Silicon-support.patch
      ./patches/0015-arm-hvf-Add-a-WFI-handler.patch
      ./patches/0016-hvf-arm-Implement-cpu-host.patch
      ./patches/0017-hvf-arm-Implement-PSCI-handling.patch
      ./patches/0018-arm-Add-Hypervisor.framework-build-target.patch
      ./patches/0019-arm-Enable-Windows-10-trusted-SMCCC-boot-call.patch
      ./patches/0020-hvf-arm-Handle-Windows-10-SMC-call.patch
      ./patches/0021-net-macos-implement-vmnet-based-netdev.patch
    ];

    # Required for vmnet patch set.
    buildInputs = oldAttrs.buildInputs ++ [
      super.darwin.apple_sdk.frameworks.vmnet
    ];

    # QEMU build assumes that codesign is available on the PATH.
    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
      (super.runCommand "qemu-build-symlinks" {} ''
        mkdir -p $out/bin
        ln -s /usr/bin/codesign $out/bin
      '')
    ];

    sandboxProfile = ''
      (allow file-read* file-write* process-exec mach-lookup)
      ; block homebrew dependencies
      (deny file-read* file-write* process-exec mach-lookup (subpath "/usr/local") (with no-log))
    '';

    postFixup = oldAttrs.postFixup + ''
      /usr/bin/codesign --entitlements ${./entitlements.plist} --force -s - $out/bin/qemu-system-aarch64
    '';
  });
}
