```@meta
CurrentModule = BasicTreePlots
```

# BasicTreePlots

Documentation for [BasicTreePlots](https://github.com/BenjaminDoran/BasicTreePlots.jl).

This is a package that aims to provide generic plotting recipes for tree like data structures.
As such the recipes should only require that your data structure fulfills the AbstractTrees interface,
i.e. has `AbstractTrees.children(YourType)` defined.

Optionally, `BasicTreePlots.distance(YourType)` and `BasicTreePlots.label(YourType)` can be defined to allow plotting trees
with variable distances between children and parent nodes and pretty printing of each node in the tree respectively.

Currently, we only provide `Makie.jl` backends, but are interested in contributions for recipes for `Plots.jl` and `TidierPlots.jl`.
As well as any other backends or custom tree structures that don't work automatically.
See the `ext` folder for example extensions.

## Installation

```{julia}
using Pkg
Pkg.add("BasicTreePlots")
```

Or the development version with

```{julia}
using Pkg
Pkg.dev("https://github.com/BenjaminDoran/BasicTreePlots.jl.git#main")
```

## Basic usage

```@example intro
using CairoMakie, BasicTreePlots
tree = ((:a, :b), (:c, :d))
treeplot(tree)
```

see [Tutorials](tutorials/00-index.md) and [Gallery](gallery/00-index.md) for more in depth examples

## `treeplot()` documentation

see [reference](reference/00-index.md) for other function's documentation

## Contributors

```@raw html
<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->
```
