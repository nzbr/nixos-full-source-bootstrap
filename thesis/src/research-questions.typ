#import "./lib.typ": fonts

#let rq-counter = counter("rq")
#let rq-text-state = state("rq", none)

#let rqs = (
  (<rq-nix>, [Is it possible to construct a full-source bootstrap chain for the Nix package manager?]),
  (
    <rq-nixpkgs>,
    [Is it possible to construct a full-source bootstrap chain for Nixpkgs by replacing the `bootstrapTools` package?],
  ),
  (<rq-nixos>, [How can these two bootstrap chains be combined to create a full-source bootstrap for NixOS?]),
  (<rq-offline>, [Can the bootstrap chain be executed fully offline?]),
  (
    <rq-iso>,
    [Is it possible to create a NixOS ISO image that can be used to install the bootstrapped NixOS on other computers without having to run the full bootstrap on them first?],
  ),
  (<rq-cross>, [How can the bootstrap be adapted to architectures beyond x86-based systems?]),
  (<rq-purity>, [Does the bootstrap chain still include any binaries besides the initial bootstrap seeds?]),
)

#let rq-style = text.with(..fonts.sans, size: 0.9em, weight: "bold", fill: luma(33%))

#let rq-ref(it) = {
  rq-style(link(it, [RQ#{ context rq-counter.at(it).at(0) }]))
}

#let rq-text(it) = {
  context rq-text-state.at(it)
}

#let show-rqs() = {
  rq-counter.update(0)
  list(..(rqs.map(it =>
  [
    #let l = it.at(0)
    #rq-counter.step()
    #rq-text-state.update(it.at(1))
    #rq-ref(l)#sym.space.en#rq-text(l) #l
  ])))
}
