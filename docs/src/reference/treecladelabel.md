# treecladelabel

```@figure treecladelabel
tree = ((:a, :b), (:c, (:d, :e)))
fig, ax, tp = treeplot(tree)
treecladelabel!(tp; cladelabels=[(:a, :b) => "Clade 1", tree[2] => "Clade 2"])
fig
```

## Clade labels

Draws a clade label for each node provided in `cladelabels`. Should be an iterable where
each element is a pair `parentnode => label`. Basically `[(node, label) for (node, label) in nodelabels]` should
not error and provide each node and label you want plotted.

if `nodelabels` is nothing, will default to `first(last(nodepoints))` (the root of the tree), and will plot a
label surrounding the full tree (assuming `nodepoints` has been calculated from `treeplot`).

Nodes and their decendent nodes should have coordinates accessible via `nodepoints[node]`.
These coordinates can be calculated with `tp = treeplot!(tree)` and accessed with `tp.nodepoints`.

```@figure treecladelabel
tree = ((:a, :b), (:c, (:d, :e)))
fig, ax, tp = treeplot(tree)
treecladelabel!(tp; cladelabels=[tree => BasicTreePlots.label(tree), (:a, :b) => "Clade 1"])
fig
```

```@figure treecladelabel
tree = ((:a, :b), (:c, (:d, :e)))
fig, ax, tp = treeplot(tree, axis=(; type=PolarAxis, rautolimitmargin=(0.0, 0.2)))
hidedecorations!(ax)
treecladelabel!(tp; cladelabels=[tree => BasicTreePlots.label(tree), (:a, :b) => "Clade 1"])
fig
```

## Unrooted label rotation

For unrooted layouts, `labelrotation` is relative to the radial direction. A value of `0`
is radial and the default `pi / 2` is tangent to the clade arc. Rotations are not folded
into a 180-degree range, so adding `pi` reverses the text direction.

```@figure treecladelabel
rotations = (0, 90, 180, 270)
tree = ((:a, :b), (:c, :d))
fig = Figure(size = (900, 240))
for (column, degrees) in enumerate(rotations)
    ax = Axis(
        fig[1, column];
        title = "$(degrees)°",
        aspect = DataAspect(),
        xautolimitmargin = (0.2, 0.2),
        yautolimitmargin = (0.2, 0.5),
    )
    hidedecorations!(ax)
    hidespines!(ax)
    tp = treeplot!(ax, tree; layoutstyle = :unrooted_cladogram)
    treecladelabel!(
        tp;
        cladelabels = [tree[1] => "clade"],
        labelrotation = deg2rad(degrees),
    )
end
fig
```

## Clade Label text styling

```@figure treecladelabel
tree = ((:a, :b), (:c, (:d, :e)))
fig, ax, tp = treeplot(tree, axis=(; xautolimitmargin=(0.05, 0.4)))
treecladelabel!(tp;
    cladelabels=[tree => BasicTreePlots.label(tree), (:a, :b) => "Clade 1"],
    labelfont=:bold,
    labelfontsize=12,
    labeloffset=(10, 0),
    labelalign=(:left, :center),
    labelrotation=0,
    color=:red,
)
fig
```

## Clade Label line styling

`lineoffset` in data space at which to draw the line indicating the clade being labeled.
Larger numbers move the line further from the root

```@figure treecladelabel
tree = ((:a, :b), (:c, (:d, :e)))
fig, ax, tp = treeplot(tree, axis=(; xautolimitmargin=(0.05, 0.4)))
treecladelabel!(tp;
    cladelabels=[tree => BasicTreePlots.label(tree), (:a, :b) => "Clade 1"],
    # Pushes line away from root
    lineoffset=1,
    # Pads width of the line
    linepadding=0.5,
    linestyle=:dash,
    linewidth=3,
)
fig
```

## Reference

```@docs; canonical=false
treecladelabel
```
