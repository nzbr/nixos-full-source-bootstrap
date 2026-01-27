#import "../lib.typ": acr, acrs, codly-local, heading-level
#import "../research-questions.typ": rq-ref, rq-text, rq-style

= Results <sec-res>

Previously, we described how we implemented the full-source bootstrap for NixOS.
In this chapter, we present the final results we achieved using our implementation.

== #rq-ref(<rq-nix>)#rq-style(":") #rq-text(<rq-nix>) <sec-res-rq-nix>
#heading-level.update(1)

Using the approach detailed in @sec-im-outer, we were able to bootstrap a Linux #acr("OS") with a fully operational Nix installation.
In terms of files, the only prerequisites are the source code and a human-auditable binary seed; thus, we consider this a successful implementation of a full-source bootstrap chain for the Nix package manager.

== #rq-ref(<rq-nixpkgs>)#rq-style(":") #rq-text(<rq-nixpkgs>) <sec-res-rq-nixpkgs>
#heading-level.update(1)

In @sec-im-inner, we showed that a replacement for the `bootstrapTools` package can be bootstrapped entirely using Nix packages.
Because the packages are built from only source code and a human-auditable binary seed, we consider this, too, a full-source bootstrap chain.

== #rq-ref(<rq-nixos>)#rq-style(":") #rq-text(<rq-nixos>) <sec-res-rq-nixos>
#heading-level.update(1)

Using the solution we detailed in @sec-im-full, NixOS can be bootstrapped from source.
We extended the Nix bootstrap chain developed to answer #rq-ref(<rq-nix>) to bootstrap a 64-bit Linux environment, switch to it, and then build and install a NixOS `toplevel` derivation from the modified Nixpkgs we developed to answer #rq-ref(<rq-nixpkgs>).

Because of availability issues with the source files, running the bootstrap only completed with manual intervention before we made it capable of running offline to answer #rq-ref(<rq-offline>).
We successfully executed the entire bootstrap in a #acr("VM") and on a physical computer.
The #acr("VM") was assigned 16 #acrs("GiB") of #acrs("RAM") and 12 logical #acrs("CPU") cores.
It was executed using QEMU `9.2.4` on a host machine running Fedora 42, which was equipped with an _AMD Ryzen 7 5800X_ processor and 32 #acrs("GiB") of #acrs("RAM").#linebreak(justify: true)
The exact QEMU command can be obtained from the Makefile located in the root directory of our fork of the _live-bootstrap_ repository.
The physical computer was a _Lenovo ThinkPad T440p_ equipped with an _Intel Core i7-4702MQ_ processor and 16 #acrs("GiB") of #acrs("RAM").

In the #acr("VM"), our three successful offline bootstrap runs took 17h 3min, 17h 21min, and 17h 43min, as measured by the `time` command.
We did not measure the bootstrap duration on the physical computer.

== #rq-ref(<rq-offline>)#rq-style(":") #rq-text(<rq-offline>) <sec-res-rq-offline>
#heading-level.update(1)

With the adjustments we described in @sec-im-offline, we were able to run the bootstrap in a #acr("VM") without any #acr("NIC") attached. Consequently, this #acr("VM") was not connected to the internet.
These changes made the bootstrap independent of the availability of the servers hosting the source files, once they have been downloaded to the computer preparing the bootstrap.

After implementing the changes, the bootstrap in the #acr("VM") passed without requiring any interaction.
On the physical computer, the last step of the bootstrap chain failed without an internet connection because `nixos-generate-config` enabled options that required building additional packages.
Furthermore, we had to remove the kernel arguments we added to be able to use QEMU's `curses` display mode from the configuration. With these set, the video output did not work after the bootstrap completed.

== #rq-ref(<rq-iso>)#rq-style(":") #rq-text(<rq-iso>) <sec-res-rq-iso>
#heading-level.update(1)

We successfully built a NixOS installer ISO image from our modified version of Nixpkgs by following the instructions in the NixOS manual @nixos-manual[`#sec-building-image`] on a NixOS installation that resulted from running the full-source bootstrap.

Using this image, we were able to install NixOS on another #acr("VM") without running the entire bootstrap chain.
Since the installer ISO only contains the run-time dependencies of the packages it includes, using it to install NixOS still involves building through the inner part of the bootstrap chain.
Because of the source availability issues we encountered, the installation only succeeded after we loaded the source files we downloaded for running the bootstrap offline into the Nix store of the installation system.

== #rq-ref(<rq-cross>)#rq-style(":") #rq-text(<rq-cross>) <sec-res-rq-cross>
#heading-level.update(1)

Neither _live-bootstrap_ nor _Aux~Foundation_ support architectures other than 32-bit x86 at the time of writing.
That means that it is not possible to execute the bootstrap chain on other architectures directly.
With the Nix #acr("DSL") code shown in @code-cross-iso, we were able to cross-compile a NixOS installer ISO image for the `aarch64-linux` platform that we confirmed to be bootable on a Raspberry Pi 4 with #acrs("UEFI") firmware @pi4-uefi installed.
Nonetheless, because we did not implement a `bootstrapTools` bootstrap for that platform, it was not possible to build packages on the booted installation system.
Cross-compiling `bootstrapTools` from `i686-linux` like we did for `x86_64-linux` would be a solution, but would require a secondary x86-based computer set up as a remote builder, @nix-manual[ch. 7.2] to run the `i686-linux` parts of the bootstrap chain on.
Our ability to cross-compile the installer ISO for `aarch64-linux`, however, demonstrates that it would be possible to use an x86-based computer to cross-compile the entire system configuration for other platforms.

#figure(
  codly-local(header: [*cross-iso.nix*], raw(read("../../assets/cross-iso.nix"), lang: "nix", block: true)),
  caption: [Nix #acr("DSL") expression for cross compiling an `aarch64-linux` installer ISO on `x86_64-linux`],
) <code-cross-iso>

== #rq-ref(<rq-purity>)#rq-style(":") #rq-text(<rq-purity>) <sec-res-rq-purity>
#heading-level.update(1)

Without employing any complex methods, we can confirm this by providing an example:
the basic NixOS configuration we used to build the `toplevel` derivation for the NixOS bootstrap depends on `rustc`, the compiler for the _Rust_ programming language.
That compiler is bootstrapped from precompiled binaries provided by the _Rust_ project.
@nixpkgs[`pkgs/development/compilers/rust/bootstrap.nix`]
