#import "../lib.typ": acr, acrs, heading-level, author-cite
#import "../research-questions.typ": show-rqs

= Introduction <sec-intro>

// 1-2 pages
// What is the problem?
// What strategy will be used to address it?
// Problem statement

To use any computer system effectively, the user must trust that the software running on it will act in their best interests.
With proprietary software, which is available only in binary form, this trust has to be awarded uncritically,
based solely on the vendor's claims and reputation.

// Abbr does not allow capitalizing the abbreviation, so we need to spell out the long form here ourselves
// To make it know that it got used, I bodged together this abomination from its source code
#context state("abbr").update(it=>{
  let dct = it.at("FOSS", default: (:))
  dct.frst = false
  it.insert("FOSS", dct)
  return it
})
Free and open-source software (#acr("FOSS")) is generally considered more trustworthy because the source code used to compile the executables is publicly available, allowing users and independent security researchers to review it.
Many #acr("FOSS") projects are developed fully in the open, allowing anyone to track and investigate every change to their source code.
In theory, the user could even read and then compile it on their own hardware, fully absolving them from having to trust the author's or any third party's claims about the software.

== Binary Packages <sec-intro-packages>

On Linux systems, software is often installed through a package manager.
Usually, this is the one that ships with the user's distribution of choice.
A lot of the time, the software included in a distribution's official package repository
#footnote[the place from where the package manager obtains the software],
as well as the build scripts that were used to create the packages, are #acr("FOSS").
The user, on the other hand, only downloads binaries built by the maintainers of the package repositories.
However, popular package managers like _#acr("dpkg")_ and _#acr("RPM")_ offer no easy way to verify that the packages were actually built from the available source code,
requiring the user to trust the packages' supplier, just like with proprietary software.

Source-based package managers, like Gentoo's _Portage_ @portage, solve this by downloading the package's source code and compiling it locally on the user's machine instead.
While this solves the problem of having to trust someone else with building the executables, local compilation also significantly increases the time and computing power required to install a new package, thereby making source-based package managers less convenient to use than binary-based ones.

_Nix_, a source-based package manager that we will introduce in greater detail in @sec-bg-nix, circumvents this inconvenience by using a binary cache.
By default, instead of building everything locally, Nix queries the configured binary caches to check if they contain a prebuilt copy of the package and, if so, uses that instead.
In this configuration, Nix behaves almost like a binary-based package manager.
Unlike with those, the retrieval of prebuilt packages ("substitution" as Nix calls it) can be deactivated if the user does not want to trust the binary cache operators.
Even if it is turned on, #linebreak(justify: true)#pagebreak() Nix can easily rebuild any package locally and compare the result to the one obtained from a binary cache #footnote[`nix-build --check`].

== Trusting Compilers <sec-intro-compilers>

To be able to ultimately trust that the produced binaries behave exactly as described by the source code they were built from, building just the package itself locally is not enough:
As #cite(<thompson>, form: "author") demonstrated in his 1984 Turing Award lecture "Reflections on Trusting Trust" @thompson, any executable, no matter how trustworthy its source code may be, can only ever be as trustworthy as the compiler that was used to build it.
That is because a malicious compiler could be created that injects malicious code into the executables it produces.

#author-cite(<thompson>) suggests that this could result in a virtually undetectable trojan when applied to a self-hosting compiler.
A compiler is self-hosting if it can compile itself. Self-hosting compilers are usually built using an earlier version of themselves.
Such a compiler could be modified to detect when it is compiling itself, and inject the trojan code into the new executable.
Once a first infected compiler has been built, all subsequent rebuilds will also carry the trojan, even if it is removed from the source code afterward.
While #author-cite(<thompson>) used the original UNIX C compiler for his demonstration in the lecture, a significant number of the compilers used to build the software running on modern computer systems, like _gcc_, _rustc_, and _go_, are self-hosting and therefore vulnerable in the same way.

Circumventing this kind of attack requires building the compiler using another compiler.
The process of building a self-hosting compiler "from scratch" without using a previous version of the compiler is called "bootstrapping".
Because the bootstrap compiler could be similarly modified to infect the other compiler when used for the bootstrap, it, too, needs to be bootstrapped from another compiler, creating a bootstrap chain.
Ultimately, this means that a trustworthy system has to be bootstrapped from a compiler that is written in machine code by hand and therefore can be executed directly, without requiring a compiler to build it. That is what is called a "full-source bootstrap"
#footnote[
  The term "full-source bootstrap" was coined by the Guix project @guix-bootstrap. See @sec-rel-guix
],
as everything is built from human-readable sources.

Because of the way Nix is designed, packages can only use programs from other Nix packages in their build scripts.
That means it is not possible to use a compiler already present on the host within a Nix build.
Cyclic dependencies are not possible either.
Therefore, the entire dependency tree of _Nixpkgs_, the Nix package repository, is rooted in a single package, `bootstrapTools`, which contains an initial set of prebuilt binaries that are used to bootstrap the rest of the package set @nixpkgs[`/pkgs/stdenv/linux`] @dolstra[p. 177] @hemel[pp. 21--24].
This makes NixOS, the Linux distribution built from the packages in Nixpkgs, an ideal candidate for attempting the full-source bootstrap of a complete Linux distribution.

#heading-level.update(1)
#pagebreak()
== Research Questions <sec-intro-questions>

This thesis answers the following questions:
#show-rqs()
