#import "../lib.typ": prose-cite, acr

= Related Work <sec-rel>

== GNU Guix <sec-rel-guix>

_GNU Guix_ @guix is another implementation of the "purely functional software deployment model" devised by #prose-cite(<dolstra>) as the theoretical foundation of Nix.
It is itself based on Nix, but replaces the Nix Language with _Guile Scheme_, a _Lisp_ dialect, as the language package definitions are written in.
Like the Nix project, _GNU Guix_ includes a repository with build definitions. @guix[`/gnu`]
The _Guix System_ is a Linux distribution built from those packages and fills the role of NixOS in the _Guix_ ecosystem.
In 2023, members of the project announced that they successfully reduced the bootstrap seed of the _GNU Guix_ package set to a 357-byte binary.
For this, they coined the term "full-source bootstrap".
They claim to be the first distribution to achieve this.
@guix-bootstrap

== Nixpkgs' `minimal-bootstrap` <sec-rel-nixpkgs>

When the full-source bootstrap for _GNU Guix_ was published, efforts were made to implement a similar bootstrap chain for Nixpkgs.
That resulted in the `minimal-bootstrap` package set.
@nixpkgs[`/pkgs/os-specific/linux/minimal-bootstrap`]

Neither the `minimal-bootstrap` package set, nor the open #acr("PR") that would extend it with additional packages @nixpkgs[`#260193`] have been updated since 2023.
In the Nixpkgs snapshot we used for our bootstrap, the `minimal-bootstrap` packages no longer built successfully.
_Aux~Foundation_, which we used instead, is based on the work on the `minimal-bootstrap` package set. It already incorporates the packages the #acr("PR") would add.
More importantly, it is currently under active development, and we were able to build the contained packages without modifications.

== Other Operating Systems <sec-rel-os>

Outside the realm of functional package managers, there are other operating systems that can be built using another existing #acr("OS")'s tooling.
Likely, a full-source bootstrap for any #acr("OS") buildable on a different Linux distribution can be achieved using _live-bootstrap_.

Examples include _FreeBSD_ @freebsd[ch. 26.9], _NetBSD_ @netbsd[ch. 33] and Gentoo
#footnote[
  Gentoo can be installed in a subdirectory on another Linux distribution. @gentoo-prefix
  It might be possible to build installation media in this environment.
],
as well as Linux distributions that are designed to be always built on an existing Linux host system, like _Linux From Scratch_ @lfs-book and the embedded distributions _Yocto_ @yocto-quickbuild and _buildroot_ @buildroot-manual.

== Reproducible Builds <sec-rel-repro>

As we have shown in @sec-dis-repro, bootstrapping and reproducibility are closely linked.
The _Reproducible Builds_ project @reproducible-builds-homepage advocates for developers and distributors to take reproducibility into account when writing and packaging software.
Under the project's umbrella, tools for making builds reproducible and for investigating non-deterministic behavior are developed.
