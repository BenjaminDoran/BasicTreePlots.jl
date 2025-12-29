# treeplot

```@setup treeplot
using NewickTree
```

Plots a tree. Assumes it is passed the root node of the tree that has `AbstractTrees.children()` defined.
Thus, all nodes should be reachable by using `AbstractTrees.PreOrderDFS()` iterator on the argument `tree`.

```@figure treeplot
tree = ((:a, :b), (:c, (:d, :e)))
fig, ax, tp = treeplot(tree)
```

## Public attributes

Further annotations can be added from [treelabels](./treelabels.md), [treescatter](./treescatter.md), [treecladelabel](./treecladelabel.md), and [treehilight](./treehilight.md).

If further customization is needed one can access the geometries computed by `treeplot`. Specifically

### tp.orderedpoints

```@example treeplot
tp.orderedpoints[]
```

can be used to get the coordinates of each node and leaf respectively.
The order of these points is the same as the order of nodes in `AbstractTrees.PreOrderDFS(tree)`.

It can be used directly in a `Makie.scatter!` plot or any other plot where we want to plot over each node.

```@figure treeplot
scatter(tp.orderedpoints; markersize=20)
```

### tp.nodepoints

```@example treeplot
tp.nodepoints[]
```

Is a `OrderedDict` of `node=>coordinate` pairs in the order returned by `AbstractTrees.PostOrderDFS(tree)`.

This is useful for more complicated plotting where we need to work with both the node and the coordinate at the same time.

As an example

```@figure treeplot
fig, ax, tp = treeplot(tree)
pts = [tp.nodepoints[][n] for n in PreOrderDFS(tree) if BasicTreePlots.isleaf(n)]
scatter!(pts, markersize=15)
fig
```

### tp.maxtreedepth

This is the largest distance of a node to the root in the tree. Can be useful when plotting

```@figure treeplot
fig, ax, tp = treeplot(tree)
treelabels!(tp; depth=tp.maxtreedepth)
## equivalent to
## treelabels!(tp; depth=:align)
fig

```

### tp.tree

This is the same as the tree used as the argument to `treeplot`. But using `tp.tree` may allow updates to flow
more directly through the `Makie.ComputeGraph`.

## layoutstyle & branchstyle

`layoutstyle` options: `:dendrogram`, `:cladogram`.

`branchstyle` options: `:square`, `:straight`.

````@figure treeplot
using NewickTree, BasicTreePlots, CairoMakie
tree = nw"((a:0.1, b:0.2):0.3, (c:0.5, (d:0.3, e:0.1):0.1):0.2):0.5;"

layoutstyles = (:dendrogram, :cladogram)
branchstyles = (:square, :straight)
fig = Figure(size=(500, 500))

for i in 1:2, j in 1:2
    ax = Axis(fig[i,j];
        title=join([layoutstyles[i], ", ", branchstyles[j]]),
        xautolimitmargin=(0.05, 0.1),
    )
    tp = treeplot!(fig[i,j], tree;
        layoutstyle=layoutstyles[i],
        branchstyle=branchstyles[j],
    )
    hidedecorations!(ax)
    treelabels!(tp)
    treescatter!(tp)
end
fig
````

In a Polar axis

```@figure treeplot
using NewickTree, BasicTreePlots, CairoMakie
tree = NewickTree.nw"((a:0.1, b:0.2):0.3, (c:0.5, (d:0.3, e:0.1):0.1):0.2):0.5;"

layoutstyles = (:dendrogram, :cladogram)
branchstyles = (:square, :straight)
fig = Figure(size=(500, 500))

for i in 1:2, j in 1:2
    ax = PolarAxis(fig[i,j];
        title=join([layoutstyles[i], ", ", branchstyles[j]]),
        rautolimitmargin=(0, 0.2),
    )
    tp = treeplot!(tree;
        layoutstyle=layoutstyles[i],
        branchstyle=branchstyles[j],
    )
    hidedecorations!(ax)
    treelabels!(tp)
    treescatter!(tp)
end
fig
```

## orientation

Options are `:right`, `:top`, `:left', and`:bottom`, and indicate where the leaves point away from the root.
`:right` and `:top` will keep the root at zero the leaves will increase in distance on the `x` and `y` axis
respectively. `:left` and `bottom` will translate the tree after multiplying the axis by `-1` so that
the deepest leaf is at `0` and the internal nodes increase in height away from that leaf.

```@figure treeplot
fig = Figure(size = (600, 600))
treeplot(fig[1, 1], tree, orientation = :right, axis = (; title = "orientation = :right"))
treeplot(fig[1, 2], tree, orientation = :left, axis = (; title = "orientation = :left"))
treeplot(fig[2, 1], tree, orientation = :top, axis = (; title = "orientation = :top"))
treeplot(fig[2, 2], tree, orientation = :bottom, axis = (; title = "orientation = :bottom"))
fig
```

For radial plots the orientation can also be inverted.

```@figure treeplot
fig = Figure(size = (600, 300))
ax, tp = treeplot(fig[1, 1], tree, orientation = :out, axis = (;type=PolarAxis, title = "orientation = :out"))
hidedecorations!(ax)
ax, tp = treeplot(fig[1, 2], tree, orientation = :in, axis = (;type=PolarAxis, title = "orientation = :in"))
hidedecorations!(ax)
fig
```

## branchcolor & branchwidth

Can be either a single color `:black`, color plus alpha transperency `(:black, 0.5)`,
or a vector of numbers for each node in pre-walk order.
color for each node is associated to the line connecting it to its parent.

Likewise, Can be either a single width of type `Real` or a vector of numbers for each node in pre-walk order.
width for each node is associated to the branch connecting it to its parent.

```@figure treeplot
fig = Figure(size=(900, 300))
treeplot(fig[1,1], tree;
    branchcolor = :blue,
    branchwidth = 2,
    axis=(; title="branchcolor = :blue, branchwidth = 2")
)
treeplot(fig[1,2], tree;
    branchcolor = (:red, 0.3),
    branchwidth = 10 .* rand(9),
    axis=(; title="branchcolor = (:red, 0.3), branchwidth = random")
)
treeplot(fig[1,3], tree;
    branchcolor = 1:9,
    branchwidth = 1:9,
    axis=(; title="branchcolor = 1:9, branchwidth = 1:9")
)
fig
```

## leafoffset & usemaxdepth

Offset added to first leaf. At default leaves start counting from `1`. Set to -1 to start counting from
`0`. Useful for starting the first leaf pointing directly right when using `PolarAxis` or setting the first
leaf at the `y` origin when using `Axis`

If `usemaxdepth=true` draw lines of each leaf tip to the depth of the leaf that is maximally distant from root.
This options is useful for connecting leaves to there location on the y axis (or θ axis if plotted on `PolarAxis`).

```@figure treeplot
fig = Figure()
ax1 = Axis(fig[1,1]; title="default leafoffset")
treeplot!(tree)
ax2 = Axis(fig[1,2]; title="leafoffset = -1, usemaxdepth");
treeplot!(tree; leafoffset = -1, usemaxdepth = true)
fig
```

## showroot

If `BasicTreePlots.distance()` is defined for the root, `showroot=true` draws the root-parent link.

```@figure treeplot
NewickTree.setdistance!(tree, 0.5)
fig = Figure()
ax = Axis(fig[1,1]; title="showroot = true")
treeplot!(tree; showroot = true)
fig
```

## Notes

- Colormap and color-range related options are mixed in from Makie (`colorscale`, `colormap`, etc.) and behave the same as other `Makie` plot types.

## Reference

```@docs; canonical=false
treeplot
```
