# BasicTreePlots

[![Stable Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://BenjaminDoran.github.io/BasicTreePlots.jl/stable)
[![In development documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://BenjaminDoran.github.io/BasicTreePlots.jl/dev)
[![Build Status](https://github.com/BenjaminDoran/BasicTreePlots.jl/workflows/Test/badge.svg)](https://github.com/BenjaminDoran/BasicTreePlots.jl/actions)
[![Test workflow status](https://github.com/BenjaminDoran/BasicTreePlots.jl/actions/workflows/Test.yml/badge.svg?branch=main)](https://github.com/BenjaminDoran/BasicTreePlots.jl/actions/workflows/Test.yml?query=branch%3Amain)
[![Lint workflow Status](https://github.com/BenjaminDoran/BasicTreePlots.jl/actions/workflows/Lint.yml/badge.svg?branch=main)](https://github.com/BenjaminDoran/BasicTreePlots.jl/actions/workflows/Lint.yml?query=branch%3Amain)
[![Docs workflow Status](https://github.com/BenjaminDoran/BasicTreePlots.jl/actions/workflows/Docs.yml/badge.svg?branch=main)](https://github.com/BenjaminDoran/BasicTreePlots.jl/actions/workflows/Docs.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/BenjaminDoran/BasicTreePlots.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/BenjaminDoran/BasicTreePlots.jl)
[![DOI](https://zenodo.org/badge/DOI/FIXME)](https://doi.org/FIXME)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](CODE_OF_CONDUCT.md)
[![All Contributors](https://img.shields.io/github/all-contributors/BenjaminDoran/BasicTreePlots.jl?labelColor=5e1ec7&color=c0ffee&style=flat-square)](#contributors)
[![BestieTemplate](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/JuliaBesties/BestieTemplate.jl/main/docs/src/assets/badge.json)](https://github.com/JuliaBesties/BestieTemplate.jl)

This is a package that aims to provide generic plotting recipes for tree like data structures.
As such the recipes should only require that your data structure fulfills the AbstractTrees interface,
i.e. has `AbstractTrees.children(YourType)` defined.

Optionally, `BasicTreePlots.distance(YourType)` and `BasicTreePlots.label(YourType)` can be defined to allow plotting trees
with variable distances between children and parent nodes and pretty printing of each node in the tree respectively.

Currently, we only provide `Makie.jl` backends, but are interested in contributions for recipes for `Plots.jl` and `TidyPlots.jl`.
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

```{julia}
using CairoMakie, BasicTreePlots
tree = ((:a, :b), (:c, :d))
treeplot(tree)
```

See [Documentation](https://BenjaminDoran.github.io/BasicTreePlots.jl/stable) for more details.

## How to Cite

If you use BasicTreePlots.jl in your work, please cite using the reference given in [CITATION.cff](https://github.com/BenjaminDoran/BasicTreePlots.jl/blob/main/CITATION.cff).

## Contributing

If you want to make contributions of any kind, please first that a look into our [contributing guide directly on GitHub](docs/src/90-contributing.md) or the [contributing page on the website](https://BenjaminDoran.github.io/BasicTreePlots.jl/dev/90-contributing/)

---

### Contributors

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->
