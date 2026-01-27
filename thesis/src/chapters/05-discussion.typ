#import "../lib.typ": acr, acrs, acrpl, acrspl, acrlpl, author-cite, prose-cite
#import "../research-questions.typ": rq-ref, rq-text

= Discussion <sec-dis>

Having demonstrated that and how a full-source bootstrap for NixOS can be implemented, we will now delve into the broader implications for the security and usability of the bootstrapped OS.
Moreover, we will discuss the challenges we faced during implementation regarding the availability of the source code.

== Usability <sec-dis-use>

Being built from the same sources, the bootstrapped NixOS installation behaves just like a non-bootstrapped one from the end-user perspective.
The differences lie in the initial installation procedure and in the process of installing additional packages.

=== Initial Installation <sec-dis-use-install>

Our introduction of the full-source bootstrap significantly increases the computational cost of installing NixOS---especially when running the entire bootstrap chain starting with _live-bootstrap_.
Moreover, the bootstrap, at least in its current form, limits hardware compatibility to just `x86_64-linux`:
The bootstrap chains we built upon only run on x86 #acrspl("CPU"), and NixOS only supports 64-bit x86.
Additionally, _live-bootstrap_ limits us to computers that can boot from a #acr("MBR"), excluding machines that only support the newer #acrs("UEFI") standard.

The requirement for #acr("MBR") compatibility, as well as parts of the computational cost, can be worked around by using the NixOS installer image.
As we showed, the installer image can be built from our modified Nixpkgs on a bootstrapped NixOS installation.
Including the build-time dependencies needed for a basic NixOS system might be a viable approach to reduce the installation's resource requirements further.

Using an installation medium merely shifts the problem, though:
Obtaining said installation media without breaking the trustworthiness of the binaries established through the bootstrap still requires building it oneself.
Still, this may present an improvement over having to run the entire bootstrap chain for every installation when setting up multiple computers, or when a trusted party provides the once-built image to multiple others.
We will discuss another possible solution to this issue in @sec-dis-repro.

=== Adding Packages <sec-dis-use-pkgs>

As long as the build-time dependencies compiled during the initial installation remain in the Nix store, installing additional packages has a similar computational cost to using another source-based package manager.
When the garbage collector is triggered for the first time, however, the build-time dependencies are deleted.
Afterward, installing new packages additionally involved rebuilding their build-time dependencies.
In a test we performed
#footnote[
Building `stdenv` after running `nix-collect-garbage -d` on a bootstrapped NixOS installation using a default configuration generated with `nixos-generate-config`
],
this included the entire inner bootstrap chain.

A way to improve this might be to explicitly include all, or a central subset of the build-time dependencies in the system configuration, to prevent them from being deleted during garbage collection.
That might not be desirable in all scenarios, though, as it limits the amount of disk space the garbage collector can free:
On a fresh install, garbage collection freed more than 19 #acrs("GiB"), which would keep being used if deleting the build-time dependencies was prevented.

=== Updating <sec-dis-use-updates>

The issue of updating is twofold:
the modified version of Nixpkgs must be updated with package definitions from upstream Nixpkgs, and the bootstrapped NixOS installations must be updated with the updated Nixpkgs.

Since we implemented the inner bootstrap in a fork of the Nixpkgs repository, updating the Nixpkgs version it bootstraps requires manually rebasing our changes onto a newer Nixpkgs commit using Git.
Being a manual process, as well as the potential for conflicting changes in the upstream repository that we would have to reconcile manually, render this setup unsuitable as a long-term solution.

Ideally, the inner bootstrap will be merged into the upstream Nixpkgs repository, eliminating the need for a modified fork.
That would allow users to weigh usability against the trustworthiness of binaries by choosing whether to use the binary cache, use the prebuilt installation media, or build everything themselves.

Another option worth investigating is converting the bootstrap into a Nixpkgs overlay.
Overlays are Nix language functions that override parts of the package set.
As an overlay, the bootstrap would no longer be bound to any specific Nixpkgs version.

Updating the bootstrapped NixOS installations incurs the same computational cost as installing new packages.
Additionally, any dependents of the updated packages must be rebuilt, too.
Updates to `stdenv` or any of its dependencies consequently require a rebuild of all packages installed on the system.

== Source Availability <sec-dis-sources>

A persistent problem we faced during implementation was the availability of the source code of the packages we needed to build.
#prose-cite(<nixpkgs-space-time>) found that 99.94% of the packages in a Nixpkgs snapshot from 2017 could still be built when they conducted their experiment six years later.
From our experience, it is evident that they achieved this result only because they used the Nix project's binary cache---an outcome they anticipated in their paper.

#pagebreak()
For our bootstrap, we deactivated the binary cache to rule out downloading any precompiled binaries from it.
Due to the aforementioned availability issues, we were only able to run the online version of the bootstrap with manual intervention, prompting us to focus our work on the offline version.

The two classes of build failures we experienced with #acrpl("FOD") were files not being available at their #acrspl("URL"), either temporarily or permanently, and the hash of the source files available at their original #acrspl("URL") changing.
The latter occurred with files generated on demand by Git repository hosting software.
Presumably, the hashes changed due to changes to said hosting software.
For a subset of those #acrpl("FOD"), we addressed the changed hashes by cherry-picking the commits that updated the hashes from the upstream Nixpkgs repository into our own fork.
We obtained the remaining unavailable files by selectively pulling the #acrpl("FOD") from the binary cache.

While the binary cache solves the source availability problem in the context of Nix, it highlights the value of projects like _Software Heritage_ @software-heritage, which archive source code repositories to keep them available even when the originals disappear from the internet.

== Remaining Sources of Untrustworthiness <sec-dis-trust>

The full-source bootstrap we implemented effectively mitigates the attack via malicious compiler, as described by #author-cite(<thompson>), with one notable exception:
Compilers that are not bootstrapped from the C-compiler contained in `bootstrapTools`, but from a different, precompiled binary seed.
Eliminating these other binary seeds from Nixpkgs remains an obstacle on the path towards establishing the ultimate trust that all packages produced by Nixpkgs' build definitions accurately reflect the source code they were built from.

=== External Factors <sec-dis-trust-external>

Despite the bootstrap chain's binary seed being small enough to be human-auditable, the bootstrap cannot be considered fully independent of any intransparent binaries:
it still requires an existing #acr("OS") to prepare the bootstrap files, as well as the firmware powering the hardware on which the bootstrap runs.

While it is conceivable for the #acr("OS") used for preparation to be malicious and to tamper with the files as the bootstrap media is prepared, malicious code being present in the computer's firmware is the more realistic scenario. This attack vector does not require tampering with the files or the bootstrapped operating system itself, and cannot be prevented on the software side.

=== Malicious Source Code <sec-dis-trust-source>

Even when we trust the compiler to translate source code to machine code faithfully, we can not automatically trust the compiled binaries to be free of trojan horses:
The attack on `xz-utils` @xz-utils-cve, a data compression program and library, has made it abundantly clear, that being a widely used
#footnote[
Some examples: Part of Nixpkgs' `stdenv`; Compression method used for #acrpl("NAR") in Nix binary caches; Used by some projects to compress their source tarballs; Previously used to compress Arch Linux packages
]
#acr("FOSS") project does not mean that a program does not include malicious code.

In this incident, an attacker managed to introduce a trojan horse targeting the _OpenSSH_ @openssh server.
It allowed bypassing the #acrs("SSH") server's authentication check, granting the attacker full remote access to compromised systems.
The malicious code was obfuscated well enough that it was not found upon its introduction into the publicly available `xz-utils` source code repository.
It was only discovered when a developer detected anomalous behavior of the #acrs("SSH") server on an affected machine.
@przymus

== Reproducible Builds <sec-dis-repro>

Reproducible builds offer promising solutions to the computational cost problem we discussed in @sec-dis-use.
A build is considered reproducible if, and only if, executing it with the same inputs produces a bit-by-bit identical result every time.
That allows using prebuilt binaries without having to trust any single distributor:
#footnote[Or in the nix context, the operators of a binary cache.]
if a quorum of independent builders produce the same output for a given build job, we can be reasonably sure that the build result has not been tampered with.
@reproducible-builds

#prose-cite(<nixpkgs-rb>) found that in the Nixpkgs revisions they investigated, between 69% and 91% of packages could be built reproducibly.
The minimal installer image includes a higher share of reproducible packages:
over 95% for all examined revisions since May 2019.
In 2023, a version of the minimal installer image was successfully reproduced.
@reproducible-oct-2023 @nix-iso-reproducible

With a fully reproducible installer image, running the outer bootstrap can be skipped in favor of installing via the image, without sacrificing any of the trustworthiness improvements provided by the full-source bootstrap.
The same is true for any other reproducible package individually. Even at the worst case observed by #author-cite(<nixpkgs-rb>) of 69% of packages being buildable reproducibly, a binary cache containing only independently verified binaries of these packages could significantly speed up the installation of the #acr("OS"), and of individual packages.
If most packages were available from an independently verified source, users might be motivated to compile the missing packages locally.
An implementation of such a binary cache that verifies the packages it serves by comparing the build results of multiple builders is _Trustix_.
@trustix-tweag @trustix-github

=== Content-Addressed Derivations <sec-dis-repro-ca>

Nix can operate under two different models:
The _extensional model_ @dolstra[pp. 87--134], which current versions of Nix use by default, and the _intensional model_ @dolstra[pp. 135--163], the implementation of which is still considered experimental.

In @sec-bg-nix-store, we explained that the hash portion of a derivation's store path is calculated from its inputs.
The derivations for which this is the case are called _input-addressed derivations_.
@nix-manual[ch. 4.4.1]
We also introduced an exception from this rule in the form of _#acrlpl("FOD")_.
Both _input-addressed_ and _fixed-output_ derivations are part of the _extensional model_.

Under the _intensional model_, input-addressed derivations are replaced by #acrpl("ca-derivation").
As the name suggests, #acrpl("ca-derivation") do not calculate their hash from their inputs, but from the contents of the resulting store path.
They share this property with #acrpl("FOD"), which can be considered a special case of #acrpl("ca-derivation").
Unlike for #acrpl("FOD"), the store path of a #acr("ca-derivation") is not known at evaluation time.
Hence, the advantage of #acrpl("FOD")---that the build only has to be executed once if multiple derivations yield the same result
#footnote[e.g. if multiple `fetchurl` calls with different #acrspl("URL") but the same hash exist, or if the file has already been added to the store with `nix-store --add-fixed`.]---does not apply to #acrpl("ca-derivation").

Using #acrpl("ca-derivation") allows implementing an _early-cutoff_ for the build process:
When a dependency of a package needs to be rebuilt, this ordinarily means that its output path changes, which in turn changes the inputs of the dependent package, prompting it to be rebuilt as well.
If the dependency is a #acr("ca-derivation") and its rebuild produces a bit-by-bit identical result, it will produce the same store path, thus leaving the dependent package's inputs unchanged and allowing its rebuild to be skipped.
@ca-nix-tweag @ca-nix-rfc

The _early-cutoff_ can help avoid unnecessary rebuilds of large parts of the package set during updates:
Suppose an update to a build tool fixes a rare edge case. With input-addressed derivations,
this change requires rebuilding every package that depends on the tool directly or indirectly.
When using #acrpl("ca-derivation"), on the other hand, only the tool's direct dependents are rebuilt.
#footnote[As long as none of them trigger the hypothetical, fixed edge case, leading to a change in the build result.]
