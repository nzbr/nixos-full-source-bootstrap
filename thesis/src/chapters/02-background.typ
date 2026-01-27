#import "../lib.typ": acr, acrs, acrpl, codly-local, fig-supplement, heading-level

#let nixdsl = [Nix #acr("DSL")]

= Background <sec-bg>

// 1/3
// used hard/software

== Nix <sec-bg-nix>

As already touched on in @sec-intro-packages, Nix is a purely functional, source-based package manager.
It was created by #cite(<dolstra>, form: "author") and is described in his #cite(<dolstra>, form: "year") doctoral thesis _The Purely Functional Software Deployment Model_ @dolstra.

=== The Nix Store <sec-bg-nix-store>

Unlike traditional package managers, Nix does not install any package files to the directories specified by #acr("FHS") @fhs. Instead, all downloaded packages
#footnote[The original doctoral thesis @dolstra[p. 19] uses the term _component_ for what we refer to as a package here. Current documentation @nix-manual uses _package_ instead, and we will follow that in this thesis.]
are kept in a single central location on the file system called the _Nix store_, usually located at `/nix/store`.
#footnote[
  Even though Nix does not mandate the Nix store be in that location, packages built on one installation are only compatible with Nix installations using the same store location. Because most users want to use official binary cache, it is not practical to diverge from the default.
]
@dolstra[p. 19]

The packages in the Nix store are stored unpacked under paths of the form `<hash>-<name>`, where `<name>` is the package's name as specified in its definition and `<hash>` is a cryptographic hash calculated from the package's _inputs_.
#footnote[As an example, a full store path for `bash` looks like this: \ `/nix/store/aqbddpi6p0bjfdlgswjry90n3sgjsqsy-bash-interactive-5.2p37`]
The inputs are the package's build instructions, which include the store paths for all dependencies of the package.
This way, every Nix package has a globally unique store path. If anything about the package definition changes, its store path changes, too, causing a rebuild.
If the calculated store path already exists, the build is skipped, so that if a package definition is modified and later reverted, the old version does not have to be built twice.
Because the hash is calculated from data that includes the store paths of all dependencies, a change to a package's store path causes the store paths of all packages that depend on it to change as well, ensuring that all dependents are rebuilt against the changed version.
@dolstra[pp. 19--21]

Due to the fact that all Nix packages are linked directly against their dependencies' store paths, their executables can be used directly from the Nix store.
That is why Nix does not need to install packages into global directories like other package managers do.
Because of this architecture, Nix can keep multiple versions of a package in its store at the same time, allowing it to install two programs side-by-side, even when they depend on two different versions of the same dependency that would otherwise be incompatible.
@dolstra[pp. 21, 23--24]

By default, Nix does not delete anything from the Nix store, unless the user manually triggers a garbage collector run.
When this happens, all store paths that are not referenced as run-time dependencies by any package registered as a garbage collector root are deleted. @dolstra[p. 124]
Among others, all packages explicitly installed into the system or user environment are automatically referenced by a garbage collector root.

Even though packages are kept unpacked in the Nix store, Nix still includes a bespoke package file format: #acrpl("NAR"). @dolstra[p. 92]
It is primarily used for binary caches, which are directories containing #acr("NAR") files, usually served via #acrs("HTTP").
When Nix is instructed to build a package, it first checks if its store path is already present locally. If not, it checks if the store path is available on one of the configured _substituters_.
These can be either other Nix stores (e.g., on another machine accessed via #acrs("SSH")) or binary caches. @nix-manual[ch. 8.6.1]
If the store path was found on a substituter, Nix downloads (and, in case of a binary cache, unpacks) it to the local Nix store. Only if it cannot be substituted is the package built from scratch.
#footnote[Unless the package explicitly requests being built by setting `allowSubstitutes = false`. @nix-manual[ch. 5.4.1.1]]

=== Nix, the Programming Language <sec-bg-nix-lang>

Nix packages are defined using expressions written in Nix's #acr("DSL"), which is also called _Nix_.
To avoid confusion between Nix, the package manager/interpreter, and Nix, the programming language, we will always refer to the latter as the _#{ nixdsl }_ or _Nix Language_ in this thesis.

The #nixdsl is a lazily evaluated, purely functional programming language.
In addition to types also found in other functional programming languages ---
numbers (integer, float), strings, booleans, lists, records (called _#acrpl("attrset")_) ---
the #nixdsl also has the special types _path_ and _string with context_.
#footnote[
  According to @dolstra[p. 67], there is also a "URI" type. While the syntax for it still works, it evaluates to a regular string on modern versions of Nix.
]
@dolstra[pp. 25, 62--63, 66--67, 71, 73] @nix-manual[ch. 5.1]

_Path_ literals can be used to refer to file system locations in place of strings.
Relative path literals are resolved relative to the location of the `.nix` file they appear in.
When a path is combined with another string---for example, when used in a build script via string interpolation---the file or directory it points to is copied to the Nix store, producing a string with context.
@dolstra[p. 67] @nix-manual[ch. 5.1.1]

_Strings with context_ behave exactly like regular strings in most circumstances.
The context, accessible through the built-in function `getContext`, associates the string with one or more store paths.
When two strings with context are combined, their contexts are merged.
Nix uses string context to track the packages' build-time dependencies.
#footnote[
  String context was introduced in Nix 0.10 @nix-manual[ch. 14.53] and is therefore not mentioned in the doctoral thesis. Instead, paths pointing to other derivations had to be created using the---since removed---_subpath_ operator. @dolstra[pp. 72--73]
]
@nix-manual[ch. 5.1.1]
Run-time dependencies are detected automatically as well; however, this happens at build-time, not during evaluation:
After the build has been completed, Nix scans the file(s) in the resulting store path for occurrences of other store paths. The paths that are found this way become the package's run-time dependencies.
@dolstra[pp. 23--24]

The central element of the Nix Language is the function `derivation`.
When it is evaluated, Nix creates (_instantiates_) a _store derivation_ from the function arguments and returns a _derivation_.
A store derivation is a `.drv` file in the Nix store that contains a serialized representation of everything needed to perform the actual build.
The package can be built (_realized_) from the store derivation without evaluating any #nixdsl code.
#footnote[`nix-store --realise /nix/store/<hash>-<name>.drv`]
@dolstra[p. 39]

The derivation returned from the call to `derivation` is an attribute set containing strings with context that link it to the store derivation.
An example of a minimum viable `derivation` call is shown in @code-minimal-drv-call.

#figure(
  raw(read("../../assets/minimal-derivation.nix"), lang: "nix", block: true),
  caption: [Minimum viable call to `derivation`],
) <code-minimal-drv-call>

In this example, we create a package called "example" that contains a single file with the text "hello world".
Packages are built by running the program specified in `builder` (the `bash` package from the 64-bit x86 version of Nixpkgs in this case) with the arguments specified in `args`.
The `system` attribute tells Nix on which platform the package can be built.
Aside from a set of special cases, all other attributes are passed to the builder as environment variables. @dolstra[p. 28] @nix-manual[ch. 5.4.1, 5.4.1.1]

When evaluated, the #nixdsl code in @code-minimal-drv-call produces a derivation that looks like this:

#figure(```
«derivation /nix/store/3abxnap3n654yfxdyccjwp37c6gjj9m4-example.drv»
```, caption: [Stringified derivation]) <code-derivation-stringified>
As stated before, a derivation is actually just an attribute set.
Nix detects that this #acr("attrset") is a derivation because it contains `type = "derivation";` @dolstra[p. 101] and uses this special syntax when printing it.
Internally, the derivation looks like @code-minimal-drv-attrset.

To ensure that package builds behave as much as possible like functions in a purely functional programming language, whose result depends purely on their inputs, they are executed in a sandbox, isolated from the host system.
#footnote[The build sandbox has been introduced in Nix 0.11 @nix-manual[ch. 14.51] and is therefore not mentioned in the original thesis.
  However, the idea of trying to prevent host-system data from leaking into the build process has been discussed in @dolstra[pp. 179--180].
].
Besides preventing the builder from accessing host files, it also blocks network access.
It is possible to supply the hash of the build output to the `derivation` call to create a #acr("FOD"). In this case, the network restriction is lifted because the file is checked against the supplied hash and can therefore still be considered pure. The hash in the path of a #acr("FOD") is calculated from the supplied hash rather than the derivation inputs, so that different #acrpl("FOD") with the same hash produce the same store path, and it only has to be built once.
@dolstra[p. 106] @nix-manual[ch. 8.6.1]

Because the #nixdsl is lazily evaluated, only the derivations that are actually relevant for the current operation (e.g., building a specific package) are evaluated and therefore instantiated. @dolstra[pp. 62--64]
This is especially relevant in the context of large package sets like Nixpkgs.
Without lazy evaluation, Nix would have to evaluate and instantiate all packages in Nixpkgs every time it is imported.

#figure([
  #raw(read("../../assets/minimal-derivation-attrset.nix"), lang: "nix", block: true)
  #fig-supplement[Store paths have been shortened for readability.]
], caption: [Derivation #acr("attrset")]) <code-minimal-drv-attrset>

=== Nixpkgs <sec-bg-nix-pkgs>

Nixpkgs is the Nix project's official collection of Nix package definitions.
It is provided as a single git repository. @nixpkgs
With over 120000 packages,
#footnote[
There are 129435 packages in the 25.05 version of Nixpkgs at the time of writing (2025-10-02).
The current count can be obtained with this command: \
#set text(size: .75em)
`curl -sL 'https://channels.nixos.org/nixos-25.05/packages.json.br' | brotli -d | jq -r '.packages | keys | .[]' | wc -l`
]
it is the largest and most up-to-date package repository tracked by the indexing website _repology_. @repology-graphs

While the build definitions themselves are #acr("FOSS"), the packaged software includes both #acr("FOSS") and proprietary programs. By default, however, evaluating a proprietary package's definition produces an error.
It must be explicitly allowed by the user, either globally or for individual packages.
We do not set that option and can therefore assume that everything we use from Nixpkgs is #acr("FOSS") and can be built from source. @nixpkgs-manual[`#sec-allow-unfree`]

==== `stdenv`

A central element of Nixpkgs is `stdenv`, the _standard environment_.
It consists of a set of tools commonly needed for building software, and fulfills a similar role to packages like `build-essential` on Debian or `base-devel` on Arch Linux.
@dolstra[pp. 174--175]

#pagebreak()
Unlike those, `stdenv` is not installed onto the system.
It is used through the function `stdenv.mkDerivation`, which is a wrapper around the built-in `derivation` function.
It accepts all arguments accepted by `derivation` and can therefore be used as a drop-in replacement.
`mkDerivation` extends upon the built-in `derivation` by adding the packages contained in `stdenv` to the build environment and providing a default builder, called the _generic builder_.
@dolstra[pp. 27, 175]

The _generic builder_ is used when no other builder is specified.
It is a shell script executed by `bash`. When using the generic builder, the build process is split into the _configure_, _build_, _check_, and _install_ phases.
Each phase has a default value intended to cover the common `./configure && make && make install` build process shared by many, especially C, programs.
If the default script for a phase does not work for a given package, it can be selectively overwritten.
Using the generic builder makes the package definitions similar to those of other package managers, like Arch Linux's `PKGBUILD` files or the `pass*.sh` files from _live-bootstrap_, which will be introduced in @sec-bg-livebootstrap.
Virtually all packages in Nixpkgs use `mkDerivation` and the generic builder; as a result, they depend on `stdenv`.
@dolstra[pp. 175--176]

#figure(
  {
    columns(
      2,
      [
        #codly-local(header: [*example.nix*], raw(read("../../assets/example-mkDerivation.nix"), lang: "nix", block: true))

        #colbreak()

        #codly-local(header: [*example/sources*], raw("<url> <hash> example.tar.gz", block: true))

        #codly-local(header: [*example/pass1.sh*], raw(read("../../assets/example-pass1.sh"), lang: "bash", block: true))
      ],
    )
    columns(
      2,
      [
      #set align(center)
      #set par(first-line-indent: 0pt)

      #fig-supplement[
      A #nixdsl function that is passed `stdenv` and `fetchurl` as arguments and returns a derivation for the `example` package.
      ]

      #colbreak()

      #fig-supplement[
      A `sources` and `pass1.sh` file that build the `example` package as a live-bootstrap step.
      The package name is infered from the directory name.
      ]

      ],
    )
    columns(2, [
      a#sym.paren.r Nix

      #colbreak()

      b#sym.paren.r live-bootstrap
    ])
    fig-supplement[
      Both formats can build this example package with the defaults for their respective phases, meaning that these files could be considerably shorter. The commands are specified explicitly for illustration purposes.
    ]
  },
  caption: [Comparison of buildscript formats],
) <code-buildscripts>

To add packages to the build environment in addition to the ones from `stdenv`, `mkDerivation` accepts a set of options, the most commonly used of which are `buildInputs` and `nativeBuildInputs`.
This split allows Nixpkgs packages to be cross-compiled easily.
The `stdenv` derivation has three inputs that define the platform on which builds are executed and the platform they target.
The names and purpose of the inputs are the same as the options GNU software, including #acr("GCC"), uses for this purpose:
- `buildPlatform` is the platform on which the build is executed.
- `hostPlatform` is the platform on which the produced binaries can be executed. It diverges from `buildPlatform` during cross-compilation.
- `targetPlatform` is the platform the produced binaries target. It diverges from `hostPlatform` when building a cross-compiler.
All packages that need to be built for the host platform (e.g., libraries) must be placed in `buildInputs`, whereas all packages that need to be executed during the build process and for that reason need to be able to run on the build platform (e.g., compilers) must be placed in `nativeBuildInputs`.
@nixpkgs-manual[`#ssec-cross-platform-parameters`, `#ssec-stdenv-dependencies-propagated`]

// stdenv bootstrap

To ensure the purity of the build environment, the packages in `stdenv` are built using Nix, as well, thus creating a bootstrapping problem:
Because Nix does not support cyclic dependencies, it is not possible to use the `stdenv` packages to build a new `stdenv` directly in the way it would be done with other package managers --- by relying on the already globally installed versions of the tools.
To overcome this, Nixpkgs uses the package `bootstrapTools`, which contains precompiled versions of the programs needed to create a minimal `stdenv`.
These prebuilt binaries are downloaded as a #acr("FOD") and then used to bootstrap the "real" `stdenv` used throughout Nixpkgs.
@nixpkgs[`/pkgs/stdenv/linux`]

The files that make up the `bootstrapTools` package are themselves built from Nixpkgs.#footnote[@nixpkgs[`/pkgs/stdenv/linux/make-boostrap-tools.nix`]]
In that way, Nixpkgs is similar to a self-hosting compiler:
A working version of Nixpkgs is required to build Nixpkgs.

==== Helper Functions

Aside from `mkDerivation` and its generic builder, Nixpkgs also provides other helper functions to create common kinds of derivations.
Among these _trivial builders_ are functions for creating a single file containing a specified string (`writeText`), creating a shell script in `/bin` (`writeShellScriptBin`), and creating a single-file C program (`writeCBin`).
@nixpkgs[`/pkgs/build-support/trivial-builders`]

The _fetchers_ are helper functions used to create derivations that download files from the internet.
They include `fetuchurl` for downloading a single file and `fetchgit` for downloading a specific commit from a git repository.
Other fetchers also perform post-processing on the downloaded files. `fetchzip`, for example, extracts the archive after downloading, and `fetchpatch` normalizes the downloaded patch by removing everything that's not required for applying it (e.g., comments). All fetchers in Nixpkgs produce #acrpl("FOD"), which means Nix verifies the integrity of the downloaded files.
@nixpkgs[`/pkgs/build-support/fetch*`]

The fetchers in Nixpkgs are not the only way to download files when using Nix.
That would be a problem for bootstrapping Nixpkgs, because the fetchers it provides depend on programs like `curl` and `git` to perform the downloads.
Nix has built-in versions of some fetchers, including `fetchurl` and `fetchgit`.
These support a subset of the Nixpkgs fetchers' API but differ in significant ways:
Even though the result is a store path, too, the built-in fetchers do not create derivations.
Unlike the Nixpkgs fetchers, where the download is performed by a program when building the derivation they produce, the built-in fetchers are programmed so that Nix itself performs the download the moment the call to the fetcher is evaluated.
They also do not check whether the output path already exists and proceed with the download anyway.
@nixpkgs-manual[`#chap-pkgs-fetchers`]

A special case is the fetcher implemented in `<nix/fetchurl.nix>`, a file included with the Nix source code. It implements a third API-compatible variant of `fetchurl`.
This variant behaves like the Nixpkgs fetchers: It creates a #acr("FOD") that downloads the file when it is built.
What sets it apart is that it uses Nix's built-in downloading capabilities and therefore does not depend on any package.
@nix-src[`/src/libexpr/fetchurl.nix`]

// lib

In addition to packages and build helpers, Nixpkgs includes the standard library `lib`.
It extends the built-in functions with a set of functions written in the Nix Language, serving a similar purpose as, e.g., Haskell's _prelude_. @nixpkgs[`/lib`]
Finally, Nixpkgs contains the source code for NixOS.

=== NixOS <sec-bg-nix-os>

NixOS is a Linux distribution that is built completely from Nix packages.
@hemel @nixpkgs[`/nixos`] \
The entirety of NixOS, including installed programs and activated services, along with their configuration, is managed through a central, modular configuration system.
Modules, including the user-supplied system configuration
#footnote[Usually located in `/etc/nixos/configuration.nix`.],
are written in the #nixdsl.
Nixpkgs contains modules for many common services that can be used in any NixOS configuration without requiring explicit import.
@nixpkgs[`/nixos/modules`]

// Evaluating a NixOS configuration results in a set of derivations in the `config.system.build` attribute of the return value.
Evaluating a NixOS configuration returns an #acr("attrset") containing the derivations used to build the configuration under the `config.system.build` attribute.
The derivations describe different parts of the system, like the kernel and the contents of `/etc`.
Most importantly, `config.system.build` contains the `toplevel` derivation, which provides everything that is needed to install the configuration.
Among other things, `toplevel` contains the activation script (`activate`) that applies the configuration to the #acr("OS"), and the `bin/switch-to-configuration` script that is used to install a new configuration and activate it either immediately or on the next reboot.
@nixos-manual[`#sec-building-parts`, `#sec-switching-systems`]

Because the Nix store can contain an arbitrary number of versions of the same package, the #acr("OS")'s previous state is preserved even when a new configuration is activated.
All versions of the system configuration are registered as garbage collector roots to prevent Nix from deleting them or the packages installed by them, allowing NixOS to be rolled back to previous configurations, as long as the user does not explicitly prompt their disposal.
Every time NixOS boots, it runs the activation script of the current configuration, allowing rollbacks to be performed directly in the bootloader.
@nixos-manual[`#sec-rollback`, `#sec-nix-gc`]

Due to the fact that on NixOS everything is contained in the Nix store, the usual #acrs("FHS") @fhs directories are not populated.
For that reason, binaries built for other Linux distributions cannot be executed on NixOS without additional measures. @hemel[p. 70]

#heading-level.update(1) #pagebreak()

== Aux Foundation <sec-bg-auxfoundation>

The Aux project @aux aims to build an alternative to the Nixpkgs-centric Nix ecosystem.
Their package set is bootstrapped from a hand-auditable 256-byte binary seed.
This bootstrap chain is called _Aux~Foundation_. @aux-foundation @bootstrap-seeds[`/POSIX/x86/hex0-seed`]

Currently, a working version is only available for 32-bit x86-based computers running Linux (or `i686-linux` as Nix calls this platform).
_Aux~Foundation_ produces a set of packages that is similar to Nixpkgs' `stdenv`. Instead of _glibc_, it uses _musl_ as its C standard library.
Besides that, it does not include the complete set of packages in `stdenv` and therefore cannot be used as a drop-in replacement.

== live-bootstrap <sec-bg-livebootstrap>

While a bootstrap chain like _Aux~Foundation_ may be able to build a package set without relying on any existing compiler, it still requires an #acr("OS") (and in the case of _Aux~Foundation_, a Nix installation) to run on.
The #acr("OS") itself might be compromised and could tamper with the files or the build process.
As a consequence, to fully trust the bootstrapped binaries, the #acr("OS") on which the build runs needs to be trustworthy as well.

The _live-bootstrap_ @live-bootstrap project solves this by bootstrapping an entire minimal Linux distribution.
The seed for _live-bootstrap_ is a hand-auditable 512-byte
#footnote[This is a full bootsector, including padding and a MBR partition table. The actual program is shorter than 512 bytes. @builder-hex0[`/builder-hex0-x86-stage1.hex0`]]
binary, similar to the one used by _Aux~Foundation_.
Instead of a Linux executable, the binary seed used by _live-bootstrap_ is bootable on its own, without requiring an #acr("OS").
Like _Aux~Foundation_, _live-bootstrap_ currently only works on 32-bit x86-based computers and uses _musl_ instead of _glibc_.

To run the bootstrap, the seed is placed on a disk, along with the source code for the programs to be bootstrapped.
When a computer boots from this disk, it begins to execute the bootstrap chain.
First, it bootstraps #acr("tcc"), which is used to build _fiwix_ @fiwix, a small UNIX / Linux-like kernel.
After starting _fiwix_, the bootstrap chain continues by building #acr("GCC") and using it to build Linux.
Finally, on Linux, a small set of userland tools and #acr("GRUB") are built and installed, resulting in a bootable Linux system. @live-bootstrap[`/parts.rst`]

_live-bootstrap_ comes with its own simple package manager written in bash, which is used to define the build scripts for the bootstrapped programs.
An example of such a build script is shown in @code-buildscripts.
Before the first bash has been built, _kaem_, a very simple shell script interpreter, is used instead.
Each package can define multiple build scripts, named `pass1.sh`, `pass2.sh`, and so on, which are used when the package is built multiple times.
That is a requirement in a bootstrapping scenario like this because some programs can only be built with additional functionality if another package is present, which might itself depend on the program. In such cases, the program is built once with the feature disabled, used to build the other package, and then rebuilt again with the feature enabled. @live-bootstrap[`/steps/helpers.sh`]

The bootstrap chain itself is defined in a custom manifest format, which is translated into scripts by a C program during the bootstrap's initial stages.
Each line in the manifest contains an operation, a parameter, and, optionally, a condition that must be met for that line to be executed.
The available operations include `build`, which builds the package passed as the parameter, `improve`, which runs a script from the `improve` directory, and `jump`, which runs a script from the `jump` directory and, before that, sets up `/init` so that the bootstrap may be resumed by executing it.
The `jump` operation is used to execute a newly built kernel that, after loading, runs `/init` and resumes the bootstrap. @live-bootstrap[`/steps/manifest`, `/seed/script-generator.c`]

To ensure the reproducibility of the bootstrap, the `SHA256SUMS.pkgs` file contains hashes of the build results for all packages. After a package is built, the result is checked against the stored hash. @live-bootstrap[`/steps/SHA256SUMS.pkgs`]

The _live-bootstrap_ repository contains a Python script that automates the bootstrap setup.
The script has four modes: In the _chroot_ and _bwrap_ modes, it runs the bootstrap in a sandboxed environment, directly on the host #acr("OS").
In _bare-metal_ mode, the script produces disk images intended for use with a physical computer.
In _QEMU_ mode, it creates disk images, as in _bare-metal_ mode, intended for use with a #acr("VM"). After creating the images, it starts a QEMU #acr("VM") in which the bootstrap is executed.
The difference between the images created in the _bare-metal_ and _QEMU_ modes is that, while the _bare-metal_ images display the log messages on the screen, the _QEMU_ images use a serial port instead. @live-bootstrap[`/rootfs.py`]

Even though the bootstrapped #acr("OS") is minimal and not suitable for general-purpose use, it is a valuable base for bootstrapping other software.
