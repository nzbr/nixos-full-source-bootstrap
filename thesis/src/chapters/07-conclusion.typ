#import "../lib.typ": author-cite, acr

= Conclusion <sec-con>

// 1 Page
// summary of what was done/accomplished, emphasize results
// conclusions that can be drawn from the results
// future work
//

In this thesis, we showed how the NixOS Linux distribution can be bootstrapped (almost) entirely from source code, eliminating the risk of the "trusting-trust" attack outlined by #author-cite(<thompson>). @thompson
We implemented a bootstrap chain for the Nix package manager based on _live-bootstrap_ and one for the Nixpkgs package set based on _Aux~Foundation_.
From these two bootstrap chains, we constructed a single, continuous bootstrap chain for NixOS.

To run the bootstrap offline, we added functionality to download the required source files once, before the bootstrap is executed.
Because we consistently experienced problems with the availability of source files, this was a required step to complete the bootstrap without manual intervention.
With these changes, we were able to run the entire bootstrap chain both in a #acr("VM") and on physical hardware.

Additionally, we showed that the bootstrapped #acr("OS") can be used to create installation media for other computers.
That is also possible for foreign architectures through cross-compilation.

While it increases the trustworthiness of the resulting #acr("OS"), running the entire full-source bootstrap increases the installation procedure's computational cost drastically.
We discussed how binary caching and installation media can alleviate this and offer users flexibility in how much time and resources they are willing to invest in the security of their #acr("OS").
Extending on that, we explained how reproducible builds may make this consideration redundant by allowing build results to be verified through consensus among independent builders.

== Future Work <sec-con-future>

To make it available to all Nix and NixOS users, we propose integrating the inner bootstrap chain into upstream Nixpkgs.
For this purpose, the packages introduced by _Aux~Foundation_ and our bootstrap should be added to the existing `minimal-bootstrap` package set.
To avoid breaking compatibility with non-x86 platforms, the full-source bootstrap should be introduced only for platforms where the required bootstrap seeds are available.
The remaining platforms continue to use the precompiled `bootstrapTools` packages.

The bootstrap chain we built is not necessarily optimal yet. It might be possible to speed up the build process by removing superfluous (re-)builds.
For example, it might be possible to build the 64-bit bootstrap tools entirely with a `musl`-linked 32-bit toolchain, eliminating the need to build a `glibc`-linked toolchain first.
It would likely be even quicker to build the 64-bit bootstrap tools directly, without using an `i686-linux` Nixpkgs instance for cross-compilation.

Another area where additional work is needed is investigating which other precompiled bootstrap compilers Nixpkgs uses and how they can be replaced with bootstrapped versions.
Ideally, as long as proprietary packages are not enabled, every installable package in Nixpkgs should be compiled from source, either locally or by a builder that pushes it to a binary cache.
