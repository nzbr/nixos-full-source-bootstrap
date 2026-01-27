#import "../lib.typ": acr, acrs, acrpl, acrspl, heading-level, lineSpacing, fig-supplement

= Implementation <sec-im>

// About 1/3 of the thesis
// Should have the same length as background and evaluation

Overall, our goal for this thesis is to show that it is possible to create a full-source bootstrap that starts with only source code and (ideally) a single human-auditable binary seed.
For the purpose of simplifying development, we split the bootstrap chain into two distinct parts:

- The _outer bootstrap_ builds a Linux #acr("OS") with a Nix installation from a bootable binary seed.
- The _inner bootstrap_, on the other hand, assumes an existing, working Nix installation running under an existing Linux kernel and builds a NixOS _toplevel_ derivation from a binary seed that can be executed inside the Nix build sandbox.

Both parts can be developed independently.
The outer bootstrap does not require anything that the inner bootstrap provides.
A copy of Nixpkgs is needed to validate that the bootstrapped Nix is functional, but an unmodified Nixpkgs is sufficient.
Even though the inner bootstrap requires the result of the outer bootstrap as a prerequisite, it can be developed using another Nix installation running under an existing Linux kernel, assuming that the bootstrapped Nix will behave the same as the one on the development machine.
Once both parts work individually, we can combine them to create the actual full-source bootstrap.

== The Outer Bootstrap <sec-im-outer>

As a basis for the outer bootstrap, we used _live-bootstrap_, which we introduced in @sec-bg-livebootstrap.
It provides us with a Linux #acr("OS") as a starting point for bootstrapping Nix.

=== Setup <sec-im-outer-setup>

During development, we ran the bootstrap in a QEMU #acr("VM").
Because we wanted to control the arguments passed to QEMU, and the Python script included with _live-bootstrap_ was not flexible enough in that regard, we wrote a Makefile that creates disk images in _bare-metal_ mode and starts a QEMU VM using them.
We used almost the same setup as the provided script:
#acrs("KVM") acceleration enabled, `kernel-irqchip=split` set as the machine type, and an `e1000` #acr("NIC").
We diverged from the live-bootstrap setup by setting the #acrs("CPU") type to `host`, but this had no effect on the files produced by the bootstrap; all hashes still matched after introducing the change.
Furthermore, since we were using _bare-metal_ images, we had to use a display for #acrs("I/O") rather than the serial console.
To be able to comfortably use QEMU over #acrs("SSH") without having to attach to the #acr("VM") using a remote desktop viewer, we used the `-display curses` option, which makes QEMU render the screen into the terminal, as long as the software running in the #acr("VM") has not switched the display out of text mode.
That required a small change to the Linux kernel command line that the bootstrap uses when switching from _fiwix_ to Linux, to prevent the kernel from switching into graphical mode.
At a later point, we modified the generator script so that it does not start a #acr("VM") in _QEMU_-Mode, allowing us to choose between the two modes using the `BOOTSTRAP_PLATFORM` variable of our Makefile.

After the main bootstrap chain finishes, the Makefile can be used to start a development #acr("VM") that is a clone of the original bootstrap #("VM").
It does this by leveraging the copy-on-write nature of the _#acrs("QCOW")2_ disk image format we are using.
That allows us to return to the state directly after the bootstrap without rerunning the entire bootstrap chain.

=== Extensions <sec-im-outer-extensions>

Using our new Makefile-based tooling, we built what we are calling the _extension system_.
An _extension_ is an optional continuation of _live-bootstrap_'s bootstrap chain.
It consists of a list of steps that can be executed after the original bootstrap chain finishes.

We tried to reuse as much of the existing tooling in _live-bootstrap_ as possible.
For this reason, extensions use the same syntax for defining steps and the bootstrap chain as _live-bootstrap_.
The file layout of an extension follows that of the `steps` directory in the _live-bootstrap_ repository:
The order of steps is defined in the `manifest` file, each package is contained in a subdirectory, and the hashes of the build results are stored in the `SHA256SUMS.pkgs` file.

Using the same structure allows us to bundle one or more extensions into the bootstrap image, creating a single bootstrap chain that executes the _live-bootstrap_ steps and then the extension, without requiring manual intervention.
We realized this by extending the Python script that generates the disk images with a new `--extension` command-line option.

A significant part of the bootstrap chain runs on kernels that do not support physical address extensions and thus cannot use the entire system memory.
In combination with an in-memory file system, this tightly limits the available storage capacity.
As a result, bundling an extension that is too large leads to a crash.
To mitigate that, the script packs the extension's `steps` directory into a compressed `.tar.xz` archive.
The archive is included in the bootstrap disk image alongside a generated `improve` script that unpacks the steps.
When appending the extension's manifest to the existing one, a step that runs the generated unpack script is placed before the extension's first step.
The `SHA256SUMS.pkgs` files are concatenated without any special processing.

To bundle multiple extensions, the option can be used multiple times.
The extensions are then executed in the order they were specified.
When using the Makefile to run the bootstrap, the extensions to be bundled can be set via the `BOOTSTRAP_EXTS` variable.

Aside from being integrated into the initial bootstrap chain, extensions can also be applied to an existing _live-bootstrap_ installation.
For this purpose, the Makefile has a target that packs an extension into a disk image.
By setting the `MOUNT_EXT` make option when starting a development #acr("VM"), the specified extension can be packed into a disk image and attached to the #acr("VM"), allowing us to test new changes to extensions quickly.

The extension is installed by mounting the disk image and starting the `run.sh` script on it.
The script replaces the contents of the `/steps` directory, which remains on a finished _live-bootstrap_ installation, with the extension's steps, runs the _script generator_ to generate new bootstrap scripts from the extension's manifest, and then executes the first stage of the generated scripts (`/steps/1.sh`) using bash.

=== The `dev-setup` Extension <sec-im-outer-devsetup>

The first thing we created using this system was the `dev-setup` extension.
Its purpose is not to be used as a part of the final bootstrap chain, but to verify that the extension system works as intended and to support development and testing of the `nix` extension we created after it.

It builds _busybox_, a collection of UNIX command line utilities @busybox, to fill in those which are missing on a regular _live-bootstrap_ install (e.g., `clear`, `less`) and sets up _busybox_'s init system, allowing us to start background services with the #acr("OS").
_busybox_ also includes a minimal variant of the `vi` text editor, which we can use to edit the bootstrap files on the running system without having to reboot.

The service the init system is relevant for is the _dropbear_ #acrs("SSH") server that the extension builds after _busybox_.
With _dropbear_ installed and running, we no longer need to rely on the serial console to interact with the #acr("VM") and can instead connect to it directly over #acrs("SSH").

To further improve the usability of the terminal interface, the extension configures the _bash_ shell with a prompt that displays the username, the hostname, and the current working directory, as is common on other Linux distributions.
Additionally, it installs scripts to simplify mounting and building an extension (`buildext`), and to build a single package directly (`build.sh`).

=== The `nix` Extension <sec-im-outer-nix>

Using the tools installed by the `dev-setup` extension, we developed an extension to bootstrap Nix.
As a reference for writing the build scripts, we looked at how these packages are built in Arch Linux
@arch-packages and Alpine Linux @alpine-packages. We choose these distributions because of the similarity of their package managers' build scripts to the _live-bootstrap_ ones and because Alpine Linux, like _live-bootstrap_, uses the _musl_ C standard library.

When using the generator script to create the disk images, the file system does not fill the entire available space in the image. To fix this, the nix extension resizes the partition and file system to fill the entire available space before building any packages.

We decided to bootstrap version `2.28.4` of Nix because it is the version packaged in the Nixpkgs snapshot we will use for the inner bootstrap in @sec-im-inner.

Nix is written in C++. The needed compiler, `g++`, is already provided by _live-bootstrap_.
Current versions of Nix---including the version we are using---are built using the _Meson_ build system.
_Meson_ is written in Python, which, too, is already provided by _live-bootstrap_.

While the interpreter is present, building _Meson_ also requires the Python packaging utilities (the packages `build`, `installer`, and `wheel`).
The first build action of the extension is to bootstrap the necessary Python packages and to build _Meson_.

To execute a build, _Meson_ requires the _Ninja_ build system, which it uses in the background, to be installed.
It is the package that the extension bootstraps next.
Because _CMake_ is required to build some of Nix's dependencies, the extension also bootstraps it.

Some libraries included with _live-bootstrap_ are built for static linking only.
To avoid rebuilding those libraries, we opted to link Nix and its dependencies statically as well.
Among the libraries Nix depends on, there are a few that require special consideration:
#pagebreak()

- `bdw-gc`, `libgit2`, `nlohmann-json` and Nix itself need to have `-latomic` added to the `CFLAGS` environment variable to be built on 32-bit x86, because GCC does not automatically link against `libatomic`, which is used to implement the `__atomic` functions on platforms that do not support GCC's built-in hardware-based implementation. @gcc-libatomic

- We had to compile `libsodium`, a library providing cryptography functionality, with the stack protector disabled. While this is not optimal from a security standpoint, all packages we are building will be replaced with versions built from Nixpkgs, so we did not consider this a significant problem.

- Nix uses `queue.h`, a file that is present in _glibc_, but missing from _musl_. Alpine Linux provides an implementation of `queue.h` for _musl_, which Nixpkgs also uses. We download that file from the Alpine Linux repository and install it to the correct location so we can build Nix against _musl_. @nixpkgs[`/pkgs/by-name/mu/musl/package.nix`]

- The version of `libarchive` included in _live-bootstrap_ lacks `bzip2` support. Compiling against it results in a Nix that cannot unpack `.tar.bz2` archives. To overcome this, we needed to rebuild `libarchive`. Because the `bzip2` built by _live-bootstrap_ lacks the _pkg-config_ file needed for the _libarchive_ build to detect it, we had to rebuild _bzip2_ as well.

After building Nix, the extension's final step is to set it up.
For this, we wrote an `improve` script that generates the `/etc/nix/nix.conf` configuration file, creates the `/nix` directory, and sets up the `nixbld` group and users, which Nix needs for its build sandbox.

@fig-nix-extension shows the dependencies of the packages in the `nix` extension.
For readability, we did not draw edges for dependencies that are already fulfilled transitively.

#figure(image("../../generated/nix-extension-fixed.svg"), caption: [Dependency Graph of the `nix` extension]) <fig-nix-extension>

#heading-level.update(1) #pagebreak()

== The Inner Bootstrap <sec-im-inner>

#figure(
  image("../../generated/bootstrap-tools-fixed.svg", width: 100%),
  caption: [Overview of the packages built in each stage of the inner bootstrap],
) <fig-bootstrap-tools>

#pagebreak()
NixOS is a part of Nixpkgs.
As such, building a full-source bootstrap chain for NixOS is equivalent to building one for Nixpkgs.

The approach we chose for the inner bootstrap was to focus on the `bootstrapTools` package from which every other package in Nixpkgs is bootstrapped.
We used _Aux~Foundation_ as a starting package set to build a replacement for `bootstrapTools`.

Following the structure of _Aux~Foundation_, we split the bootstrap chain into stages.
Our final `bootstrapTools` bootstrap consists of nine stages.
Each stage is a function that uses the derivations produced by the previous stages to produce a new #acr("attrset") with derivations.

=== Stages 1 and 2: Aux Foundation

The first two stages re-export the _Aux~Foundation_ packages from the stages with the same names.
It is worth noting that _Aux~Foundation_ has three stages, starting with stage 0, where it builds a first, simple C compiler.
However, we did not use the packages from stage 0 directly.
Therefore, our bootstrap chain starts with stage 1.
The bulk of the packages we used are built in stage 2, including the `gcc` toolchain and the `glibc` C standard library. The `musl` C library against which the toolchain links is built in stage 1.

=== Stage 3: First Minimal `stdenv`

In stage 3, we build a first version of `stdenv`.
In addition to a C toolchain, Nixpkgs' `stdenv` contains the following packages: @nixpkgs[`/pkgs/stdenv/generic/common-path.nix`]
#[
#set list(spacing: lineSpacing)
- `bash`
- `bzip2`
- `coreutils`
- `diffutils`
- `file`
- `findutils`
- `gawk`
- `gnugrep`
- `gnumake`
- `gnused`
- `gnutar`
- `gzip`
- `gnupatch`
- `xz`
]

As shown in @fig-bootstrap-tools, _Aux~Foundation_ provides all of these packages, except for `file`, which we thusly omit in this stage.

To be usable in `stdenv`, the C compiler must be wrapped by a script that injects the command-line flags needed to produce working executables within the Nix build environment.
Building this wrapper itself requires `stdenv`.
Nixpkgs solves this by additionally building `stdenvNoCC`, a variant of `stdenv` that is built without a C compiler.
We replicated this solution for our bootstrap.

Wrapping a compiler that links against `musl` additionally requires the `fortify-headers` package.
To build it, we called its existing function in Nixpkgs with our package set.

The `patch` command built by _Aux~Foundation_ is broken when used as `stdenv` tries to invoke it, so we added an override to build the first version of `fortify-headers` without applying the patches.
Downloading the sources requires `fetchurl`, which depends on `curl`.
The `bootstrapTools` package does not include `curl`, meaning that Nixpkgs needs to solve this problem, too.
To do so, Nixpkgs includes a bootstrap version of `fetchurl` that uses the `<nix/fetchurl.nix>` fetcher instead.
We used this to provide the required `fetchurl`.

Notwithstanding Nixpkgs supporting building `bootstrapTools` using binaries linked against `musl`, we decided to use `glibc`-linked binaries like the prebuilt version that an unmodified Nixpkgs would use.
The rationale was to replicate the original `bootstrapTools` as closely as possible to avoid causing problems when integrating the bootstrap chain into Nixpkgs.
Since the `gcc` package provided by _Aux~Foundation_ is configured to link against `musl`, we cannot use this first `stdenv` to build the `bootstrapTools` replacement, and need to build a compiler that links against `glibc` first.

=== Stage 4: Complete `stdenv`

With the basic `stdenv` from the previous stage, we (re-)built `file`, `gnupatch`, and `xz` to complete the `stdenv` packages.
While `file` is built for the first time in this stage, both `gnupatch` and `xz` are already contained in _Aux~Foundation_.
The packages work in isolation, but when used with `mkDerivation`, they are not able to apply patches and unpack `.tar.xz` archives respectively.
We used the Nixpkgs package definitions for the rebuild to ensure the options required to make the programs work with `stdenv` are set correctly.
Building `gnupatch`, however, again required an override to prevent it from attempting to apply patches, since the previous version is non-functional.
To save on build time, we did not immediately rebuild `gnupatch` with the patches applied. The unpatched version is sufficient for building everything until it is rebuilt for inclusion in `bootstrapTools`.

=== Stage 5: Cross-Compiler

Using the now complete set of inputs, we built a new `stdenv`.
With this, we rebuilt `fortify-headers`---this time without the override that removed the patches.

Until this point, every `stdenv` we built had `i686-unknown-linux-musl` set as its _build_, _host_, and _target_ platforms.
That means they used and produced binaries that can be executed on any i686-compatible (32-bit x86-based) #acrs("CPU") running Linux, and that the binaries are linked against `musl`.

The central operation of this stage is building a cross-compiler that is itself linked against `musl`, but outputs binaries linked against `glibc`.
To achieve this, we rebuilt `binutils` and `gcc`, and their respective wrappers, with `i686-unknown-linux-gnu` set as the _target_ platform.
From these packages, we built a new `stdenv` variant that we called `crossStdenv`.
This new `stdenv` has `i686-unknown-linux-musl` set as its _build_ platform, and `i686-unknown-linux-gnu` as the _host_ and _target_ platforms.
The `glibc` package we use in this stage is taken from _Aux~Foundation_'s `stage2`.

=== Stage 6: Native Compiler

In the next stage, we used the `crossStdenv` to rebuild `binutils` and `gcc` again, this time for `i686-unknown-linux-gnu`, which they also target.
For the build, we used the same platform definitions as `crossStdenv`.
We created another `stdenv` that uses the native compiler, with `i686-unknown-linux-gnu` as its _build_, _host_, and _target_ platforms.

=== Stage 7: `fetchurl`

To recreate the Nixpkgs-built `bootstrapTools` as closely as possible, we used the package definitions from Nixpkgs for all included packages.
Because these were built with the expectation of having the entirety of Nixpkgs available, they use fetchers like `fetchpatch`, which depend on features of `fetchurl` that are not available in the bootstrap version.
That is why, in this stage, we bootstrapped the regular `curl`-based `fetchurl`.

=== Stage 8: Final Compiler

As stated before, we wanted to build all packages contained in `bootstrapTools` from their Nixpkgs definitions.
For this reason, we rebuilt `glibc`, `gcc`, and `binutils`, including their dependencies from their Nixpkgs definitions for the last time, and used the result to create our final `stdenv`.

=== Stage 9: `bootstrapTools`
Every package contained in `bootstrapTools` is either built for the first time or rebuilt in `stage8` or `stage9`.
Doing this was necessary so that all packages in `bootstrapTools` are linked against the exact `glibc` included with them that we built in `stage7`.
We obtained the `bootstrapTools` derivation by calling the function in `make-bootstrap-tools.nix`
#footnote[@nixpkgs[`/pkgs/stdenv/linux/make-bootstrap-tools.nix`]],
and passing in our package set.

=== Integration

The `bootstrap-files`
#footnote[@nixpkgs[`/pkgs/stdenv/linux/bootstrap-files/`]]
directory in Nixpkgs contains a `.nix` file for every supported platform.
Each file contains an #acr("attrset") with two entries: `bootstrapTools` and `busybox`.
These entries contain the results of two `<nix/fetchurl.nix>` calls that download the prebuilt `bootstrapTools` and a statically linked `busybox` binary, which is used as the initial builder.
The files downloaded here are the ones `make-bootstrap-tools.nix` returns in the `bootstrapFiles` attribute.
Because the #acr("attrset") contained in that attribute has the same form as the ones defined in the `bootstrap-files` directory, we replaced the contents of `i686-unknown-linux-gnu.nix` with code that imports our bootstrap chain and returns the value of `bootstrapTools.bootstrapFiles` from it.
For all other platforms, we modified the files to throw an error when evaluated, to prevent accidental use of non-bootstrapped packages.

Since January 2024, support for the `i686-linux` platform by Nixpkgs and thus NixOS has been discontinued.
@nix-i686-deprecation
Consequently, NixOS is no longer guaranteed to be buildable on this platform.
Because we encountered build failures when building a NixOS `toplevel` derivation, we decided to build NixOS for the `x86_64-linux` platform instead.
Thanks to 64-bit x86 #acrspl("CPU") generally being able to execute 32-bit x86 binaries, we can use our existing `i686-linux` bootstrap chain to cross-compile `bootstrapTools` for `x86_64-linux`:
Based on the code in `make-bootstrap-tools-cross.nix`
#footnote[@nixpkgs[`/pkgs/stdenv/linux/make-bootstrap-tools-cross.nix`]],
we modified `x86_64-unknown-linux-gnu.nix` in the `bootstrap-files` directory to build the `x86_64-linux` version of `bootstrapTools` from the bootstrapped `i686-linux` Nixpkgs, making use of its cross-compilation support.

#heading-level.update(1) #pagebreak()

== The Combined Bootstrap <sec-im-full>

By linking the bootstrap chains together, we constructed a combined bootstrap chain that starts with _live-bootstrap_ and results in a NixOS installation.
We implemented this through another extension using the system we introduced in @sec-im-outer-extensions.

First, the `nixos` extension reconfigures the _tmpfs_ mounted at `/tmp` to a size of 32 #acrs("GiB") and four million inodes.
To support this without impacting the available system memory, it also generates and activates a swap file of the same size.
Growing the _tmpfs_ is necessary, as Nix stores the working directory of the build processes in there.
The original size and inode count set by _live-bootstrap_ caused space-intensive builds to run out of capacity.
Unmounting the _tmpfs_ entirely or instructing Nix to use another directory were solutions we considered as well. Both caused build failures in _Aux~Foundation_---hence, we did not pursue them any further.

Before Nix is used to build any packages, we added a step that starts the _Nix daemon_ and configures all subsequent Nix invocations to access the Nix store through the daemon rather than directly.
Having this single point through which all interactions with the Nix store are managed prevented a race condition between multiple builds finishing at the same time, which had caused bootstrap failures before we introduced the daemon.
The race condition might have been mitigated by deactivating the `auto-optimise-store` option in `/etc/nix/nix.conf`. If the option is enabled, Nix deduplicates all files in the Nix store using hard links.
The build failure occurred when a Nix instance attempted to create a hard link that another build process had already created in the time since it checked for its presence.
To save on disk space, we kept the feature enabled.

As a result of _live-bootstrap_ targeting 32-bit x86, the kernel it builds can not execute 64-bit binaries, even when running on a 64-bit #acrs("CPU").
To overcome this limitation, we used Nix to cross-compile a 64-bit Linux kernel.
Nixpkgs' default configuration is not suitable for use without an #acr("initramfs") containing the kernel modules needed to interface with the disk containing the root file system.
We used the kernel configuration from _live-bootstrap_, ensuring that the new kernel is bootable on all (64-bit capable) computers that can run _live-bootstrap_.
A `jump` script switches to the new kernel and resumes the bootstrap chain there.

During development of the kernel bootstrap, we found that the `bash` package from _Aux Foundations_'s `stage1` is not buildable under a 32-bit kernel.
The cause is one of the checks in the package's `./configures` script crashing in this scenario.
Before integrating the bootstrap chains, the problem did not occur because we developed the inner bootstrap on a NixOS installation with a 64-bit kernel.
Our solution was to skip the misbehaving check and always assume that the functionality it was trying to detect is unavailable.
#footnote[Pull request with the fix we opened upstream: https://git.auxolotl.org/auxolotl/foundation/pulls/3]

Attempting to build 64-bit packages with the 32-bit Nix we built in @sec-im-outer-nix fails with a `Bad system call` error.
We added a step that uses the 32-bit Nix to cross-compile a 64-bit version, as we did with the kernel.
Afterward, the Nix daemon is restarted so that it, too, uses the 64-bit version of Nix.

In its penultimate step, the extension builds a NixOS `toplevel` derivation for the `x86_64-linux` platform.
The configuration used to build it can not be adjusted for the specific machine the bootstrap is running on due to _live-bootstrap_'s reproducibility checks.
Instead, we added a script to the configuration that runs NixOS's boot process.
The script uses the `nixos-generate-config`#footnote[@nixpkgs[`/nixos/modules/installer/tools/nixos-generate-config.pl`]] utility to automatically detect the needed options for the hardware, generating the `hardware-configuration.nix` file.
This file is imported by the NixOS configuration, which the script rebuilds before rebooting.
When executing the rebuild, the script removes itself from the configuration, so that it runs only once.
In this step, we also create the `/etc/NIXOS_LUSTRATE` file, which tells NixOS to perform a cleanup of the system. Before the configuration is activated, everything that does not belong to the configuration or is listed in that file is moved to `/old-root`. @nixpkgs-manual[`#sec-installing-from-other-distro`]

Finally, the extension jumps into NixOS.
We used the 64-bit kernel built with _live-bootstrap_'s config earlier instead of the one built with the NixOS `toplevel` derivation for this, because hardware detection only happens after the first boot, and therefore required modules may still be missing from the #acr("initramfs"), rendering the NixOS kernel unbootable.
We did, however, use the #acr("initramfs") included in the `toplevel` derivation.
Doing so ensures that `nixos-generate-config` can properly detect the boot device.

The bootstrap chain ends when the hardware-detection script included in the initial configuration reboots the system.
If running inside QEMU using the command from our Makefile, the #acr("VM") exits at this point instead of completing the reboot.

== Taking the Bootstrap Offline <sec-im-offline>

Checksums ensure the integrity of the files downloaded from the internet during the bootstrap.
They are used for this purpose throughout the bootstrap chain.
Nonetheless, we wanted the bootstrap to be executable without an internet connection to eliminate the possibility that any component downloads unverified data, thereby contaminating the bootstrapped system.

Through the use of the `--external-sources` option when generating the bootstrap files, _live-bootstrap_ can already be used fully offline.
The only problem we encountered was that it still requires a #acr("NIC") to be connected to the bootstrap machine.
Without that, the bootstrap fails when it tries to acquire an #acrs("IP") address via #acrs("DHCP").
We made the problematic step skippable by introducing a new `--offline` option.
Furthermore, the `nix` extension can also be used offline without modification.
It exclusively uses the `sources` files to obtain the packages' source code. Accordingly, they are handled by the `--external-sources` option, too.

Building the `nixos` extension offline, on the other hand, required a more sophisticated approach.
The Nix packages utilize the _fetchers_ to download their source files.
Manually finding the #acrspl("URL") and hashes of all source files would not be feasible within a reasonable timeframe, due to the number of packages and their associated source files involved in building the `toplevel` derivation.
Besides that, we needed to instruct Nix to use the local source files rather than attempting the download.

#pagebreak()
=== `fetchurl`

The `nix derivation show` command prints a #acrs("JSON") representation of a given store derivation.
The output produced for the store derivation corresponding to the example derivation shown in @code-minimal-drv-attrset in @sec-bg-nix-lang is shown in @code-minimal-drv-store.

#figure([
  #raw(read("../../assets/minimal-derivation-store.json"), lang: "json", block: true)
  #fig-supplement[Store paths have been shortened for readability.]
], caption: "JSON representation of an example store derivation") <code-minimal-drv-store>

With the `--recursive` option, the generated #acr("JSON") contains not only the contents of the store derivation passed to the command, but also of the store derivations of all store paths referenced by it, directly or indirectly.
The result encompasses everything needed to build the input derivation from scratch.

#acrpl("FOD") are trivial to detect in this representation, because their `outputs.out` attribute additionally contains the keys `hash`, `hashAlgo`, and `method`.
The value of `method` determines how the hash is to be calculated: `flat` specifies that the derivation's output is a single file that should be hashed directly, whereas `nar` and `recursive` instruct Nix to calculate the hash from a #acr("NAR") dump of the output.
#footnote[
  There are further, experimental hashing methods.
  Those are however not relevant in the context of this thesis, as we did not enable the relevant experimental features.
]
@nix-manual[ch. 5.4.1.1]
Entries created by a call to `fetchurl` also contain the #acrs("URL") they download in the `.env.url` attribute, or in the `env.urls` attribute if multiple mirrors are specified.

Initially, we focused only on files that _live-bootstrap_'s tooling can download.
Every line in a `sources` file contains the #acrs("URL"), the #acrs("SHA-256") hash, and a filename.
To generate such a file, we wrote a script that parses the output of `nix derivation show --recursive` for all packages built in the `nixos` extension.
It filters out everything that is not a #acr("FOD") with a known #acrs("URL"), a `sha256` hash, the `flat` hashing method, and an unset or empty `.env.postFetch` value.
The `postFetch` environment variable is used by fetchers that perform the actual download with `fetchurl`, but need to post-process the downloaded file.
Nix checks the hash _after_ the post-processing step, hence there is no way to infer the checksum of the original file.

To make Nix use the downloaded files, we added a new step to the `nixos` extension between starting the Nix daemon and building the first package, that copies the files into the Nix store with `nix-store --add-fixed`.
This command results in the same store path as building a #acr("FOD") with the file as its output would.
@nix-manual[ch. 8.3.3.1]
Nix thus detects that the store path is already present and skips the download.
That is another reason why we had to filter out derivations with a non-empty `postFetch` value:
Even if we were able to obtain the correct hash and download the files, in order to create a #acr("FOD") with the correct store path, we would have had to replicate the post-processing step before adding the file to the Nix store.

=== Other Fixed Output Derivations

For all #acrpl("FOD") we were unable to replace with this method, we used Nix's binary cache feature.
We modified the script to copy all incompatible #acrpl("FOD") into a local binary cache, which is packed into an archive and placed next to the downloaded source files.
During the bootstrap, the archive is unpacked and the contained #acrpl("FOD") are copied to the Nix store of the bootstrap machine.

The caveat with this solution is that post-processing no longer occurs on the bootstrap machine, but on the computer preparing the bootstrap, using non-trustworthy software.
Given that #acr("FOD") build results are checked against predefined hashes, we were willing to accept this tradeoff.

=== Built-in Fetchers

After implementing the binary cache, the last source files that were not available offline were those downloaded by the built-in fetchers.
Since the built-in fetchers do not produce store derivations, there is nothing for `nix derivation show` to convert to #acrs("JSON").
Even though the downloaded store paths do appear in the attributes of the derivations that use them, paths obtained from a built-in fetcher do not have their own entries.

In Nixpkgs, built-in fetchers may not be used.
@nixpkgs-manual[`#chap-pkgs-fetchers`]
_Aux~Foundation_ does, however, use them in two places:
First, to download a repository with library functions, and secondly, to download and unpack the sources for the `stage0` packages.

#pagebreak()
We addressed the first instance by copying the contents of the library repository into the _Aux~Foundation_ source tree.
That allowed us to remove the download entirely.

For the second instance, removing the calls to `builtins.fetchTarball` was not trivially
#footnote[
There is an open pull request on the _Aux~Foundation_ repository @aux-foundation[`#15`] that aims to replace the `fetchTarball` calls with a combination of the code behind `<nix/fetchurl.nix>` and the undocumented `builtin:unpack-channel` builder to solve this exact problem.
]
possible.
Because these downloads occur before any Nix packages are built, the `fetchTarball` function is essential for unpacking the downloaded archives.
Instead of removing the fetcher calls, we modified them so that the #acrpl("URL") can be overwritten with `files://` #acrpl("URL") pointing to local copies of the files.
This way, `fetchTarball` still unpacks the archives, but no longer requires an internet connection.
