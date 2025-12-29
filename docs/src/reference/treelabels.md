# treelabels

Use `treelabels!` to annotate nodes with labels

````@figure treelabels
tree = ((:a, :b), (:c, (:d, :e)))
fig, ax, tp = treeplot(tree)
treelabels!(tp)
fig
````

By default it will use `BasicTreePlots.tipannotations(tp.nodepoints)` and plot
`BasicTreePlots.label(leaf)` for each leaf.

## Nodelabels

List of nodes and associated labels for which to plot. Should be an iterable where
each element is a pair or tuple of `node => label`. Basically `[(node, label) for (node, label) in nodelabels]` should
not error and provide each node and label you want plotted.

````@figure treelabels
tree = ((:a, :b), (:c, (:d, :e)))
fig, ax, tp = treeplot(tree)
treelabels!(tp; nodelabels = [
    tree[1] => "A and B",
    (:c, (:d, :e)) => "C, D, E",
    :a => "A",
    :c => "C",
    :d => "D",
])
fig
````

Nodes not provided will not have annotations added.

## Depth

Available options:

* `nothing` (default) in which case the anchorpoints for the labels are directly on the nodes being labeled.
* `depth=:align`, Places the anchorpoints at a constant depth equal to the leaf node maximally distant from the root.
* `depth=<:Real`, sets the custom constant depth at which the label anchorpoints are set.
* `depth=(node,pos)->Point2f`, Determines a custom function that takes a node and its coordinate and returns
    where the label anchorpoint should be.

````@figure treelabels
tree = ((:a, :b), (:c, (:d, :e)))
nodelabels = [tree[1] => "A and B", (:c, (:d, :e)) => "C, D, E", :a => "A", :c => "C", :d => "D"]
fig = Figure(size=(900, 300))

ax, tp = treeplot(fig[1,1], tree, axis=(; xautolimitmargin=(0.05, 0.4)))
hidedecorations!(ax)
treelabels!(tp; nodelabels, depth=:align)

ax, tp = treeplot(fig[1,2], tree, axis=(; xautolimitmargin=(0.05, 0.4)))
hidedecorations!(ax)
treelabels!(tp; nodelabels, depth=tp.maxtreedepth)

ax, tp = treeplot(fig[1,3], tree, axis=(; xautolimitmargin=(0.05, 0.2)))
hidedecorations!(ax)
treelabels!(tp; nodelabels, depth=(node, pos) -> let
    BasicTreePlots.isleaf(node) ? Point2f(tp.maxtreedepth[], pos[2]) : pos
end)

fig
````

## Label rotation

Options are `:horizontal`, `:radial`, `:aligned`, or a number `θ<:Real` in radians.
If `automatic`, will default to `:aligned` on polar axis and `:horizontal` otherwise.

Rotation examples on `Axis` plot

````@figure treelabels
tree = ((:a, :b), (:c, (:d, :e)))
nodelabels = [tree[1] => "A and B", (:c, (:d, :e)) => "C, D, E", :a => "A", :c => "C", :d => "D"]
fig = Figure(size=(600, 300))

ax, tp = treeplot(fig[1,1], tree, axis=(;
    title="labelrotation = :horizontal",
    xautolimitmargin=(0.05, 0.4))
)
treelabels!(tp; nodelabels, labelrotation = :horizontal)

ax, tp = treeplot(fig[1,2], tree, axis=(;
        title="labelrotation = deg2rad(45)",
    xautolimitmargin=(0.05, 0.4))
)
treelabels!(tp; nodelabels, labelrotation = deg2rad(45))

fig
````

Rotation examples on `PolarAxis` plot

````@figure treelabels
tree = ((:a, :b), (:c, (:d, :e)))
nodelabels = [
    tree[1] => "A and B", (:c, (:d, :e)) => "C, D, E",
    :a => "A", :b => "B", :c => "C", :d => "D", :e => "E"
]

fig = Figure(size=(600, 300))

ax, tp = treeplot(fig[1,1], tree, axis=(;
    type=PolarAxis,
    title="labelrotation = :aligned",
    rautolimitmargin=(0.0, 0.4))
)
hidedecorations!(ax)
treelabels!(tp; nodelabels, labelrotation = :aligned)

ax, tp = treeplot(fig[1,2], tree, axis=(;
    type=PolarAxis,
    title="labelrotation = :radial",
    rautolimitmargin=(0.0, 0.4))
)
hidedecorations!(ax)
treelabels!(tp; nodelabels, labelrotation = :radial)

fig
````

## Label alignment

determines where on the textbox is anchored to the anchorpoint, useful when plotting the tree
in different orientations

```@figure treelabels
fig = Figure(size=(400, 400))

ax, tp = treeplot(fig[1,1], tree,
    orientation=:bottom,
    axis=(;
        yautolimitmargin=(0.2, 0.05)
    )
)
treelabels!(tp; nodelabels,
    labelrotation = deg2rad(45),
    labelalign=(:right, :center),
    labeloffset=(0.0, -10),
)
fig
```

## Label offset

Offset in pixel space to push text label anchor points. Available options:

* `automatic` (default) if plotting on `Axis()` the offset is (5px, 0), if on `PolarAxis()` the default is
    `5px * (cos(θ), sin(θ))` where θ is the radian angle of the node.

* `labeloffset::Real` defaults to offsetting the label in pixels toward the x direction for `Axis`` and in radius for`PolarAxis`

* `labeloffset=Tuple{<:Real, <:Real}`, if plotting on an `Axis` provide `(x,y)`, if on `PolarAxis` provide `(θ, r)`
    in pixel units for the offset relative to the label anchorpoint.

* `labeloffset::Function=(node,pos)->(x_px, y_px)`, Provide a custom function that takes a node and its coordinate
    in dataspace and return a pixel space offset. Note that pixel space does not get converted like the `PolarAxis`,
    so conversion of coordinates may be required `r_off * (cos(θ+θ_off), sin(θ+θ_off))`.

```@figure treelabels
fig = Figure(size=(900,600))

ax, tp = treeplot(fig[1,1], tree; axis=(;
    xautolimitmargin=(0.05, 0.15),
    title="labeloffset=automatic"
    )
)
hidedecorations!(ax)
treelabels!(tp; nodelabels)

ax, tp = treeplot(fig[2,1], tree;
    axis=(;
        type=PolarAxis,
        rautolimitmargin=(0.0, 0.3),
        title="labeloffset=automatic"
    )
)
hidedecorations!(ax)
treelabels!(tp; nodelabels)

ax, tp = treeplot(fig[1,2], tree; axis=(;
    xautolimitmargin=(0.05, 0.15),
    title="labeloffset=(20, 0)"
    )
)
hidedecorations!(ax)
treelabels!(tp; nodelabels, labeloffset=(20, 0))

ax, tp = treeplot(fig[2,2], tree;
    axis=(;
        type=PolarAxis,
        rautolimitmargin=(0.0, 0.4),
        title="labeloffset=(0, 20)"
    )
)
hidedecorations!(ax)
treelabels!(tp; nodelabels, labeloffset=(0, 20))

ax, tp = treeplot(fig[1,3], tree; axis=(;
    xautolimitmargin=(0.05, 0.15),
    title="labeloffset=function"
    )
)
hidedecorations!(ax)
treelabels!(tp; nodelabels, labeloffset=(node, pos)->let
    BasicTreePlots.isleaf(node) ? (20, 0) : (-55, 10)
end)

ax, tp = treeplot(fig[2,3], tree;
    axis=(;
        type=PolarAxis,
        rautolimitmargin=(0.0, 0.3),
        title="labeloffset=function"
    )
)
hidedecorations!(ax)
treelabels!(tp; nodelabels, labeloffset=(node,pos)-> let
    BasicTreePlots.isleaf(node) ? 5 .* (cos(pos[1]), sin(pos[1])) : 25 .* (cos(pos[1])+deg2rad(-10), sin(pos[1]+deg2rad(-10)))
end)

fig
```

## Label guideline styling

If `guidesvisible=true` (default) draw guide lines from node to label anchorpoint.
Useful for visually connecting leaves to their location on the y axis (or θ axis if plotted on `PolarAxis`),
especially when using the `depth` attribute.

```@figure treelabels
fig = Figure(size=(600, 300))

ax, tp = treeplot(fig[1,1], tree; axis=(;title="No guides", xautolimitmargin=(0.05, 0.2)))
hidedecorations!(ax)
treelabels!(tp; depth=:align, guidesvisible=false)

ax, tp = treeplot(fig[1,2], tree; axis=(;title="Styled guides", xautolimitmargin=(0.05, 0.2)))
hidedecorations!(ax)
treelabels!(tp; depth=:align, guideswidth=3, guidescolor=:magenta, guidesstyle=:dash)

fig
```

## Reference

```@docs; canonical=false
treelabels
```
