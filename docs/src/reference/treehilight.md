# treehilight

Highlight specific clades of the tree by plotting a shaded area around the set of descendents of a node.

```@figure treehilight
tree = ((:a, :b), (:c, (:d, :e)))
fig, ax, tp = treeplot(tree)
treehilight!(tp; nodes=[tree[1], (:d, :e)])
fig
```

## Nodes

Draws a shaded region surrounding each of the nodes provided as a list to `nodes`.
Assumes that each node and decendent node is accessible as `nodepoints[node]`.
`nodepoints` can be accessed from `tp = treeplot(tree)` as `tp.nodepoints`.

```@figure treehilight
tree = ((:a, :b), (:c, (:d, :e)))
fig, ax, tp = treeplot(tree)
treelabels!(tp),
treehilight!(tp; nodes=[tree[1]])
# Region colors will cycle with each call to `treehilight`.
treehilight!(tp; nodes=[(:d, :e)])
fig
```

## Styling

### Padding

Padding value to expand region around clade. Expects `(root_edge, leave_edge, first_leaf_edge, last_leaf_edge)`.
When plotting on `Axis`, the `first_leaf_edge` is at the bottom. If input is `(num_1, num_2)`,
the resulting padding will be `(num_1, num_1, num_2, num_2)`, and if the input is `num_1` the padding will
be `(num_1, num_1, num_1, num_1)`.

````@figure treehilight
tree = ((:a, :b), (:c, (:d, :e)))
fig = Figure(size=(500,500))
ax = PolarAxis(fig[1,1]; rautolimitmargin=(0, 0.2))
hidedecorations!(ax)
tp = treeplot!(tree)
treelabels!(tp)

treehilight!(tp;
    nodes=[tree[1]],
    # padding
    padding = 0.5,
    color=:green,
    alpha=0.1,
)
treehilight!(tp;
    nodes=[tree[2][1]],
    padding = (0.5, 0.1),
    alpha=1,
    strokewidth=3,
    strokecolor=:red,
)
fig
````

### Z shift

By default the regions are shifted back in Z direction so that the tree and other annotations are plotted in front.
Making the `z_shift` option greater in magnitude will shift the highlighted region forward.

```@figure treehilight
tree = ((:a, :b), (:c, (:d, :e)))
fig = Figure(size=(500,500))
ax = PolarAxis(fig[1,1]; rautolimitmargin=(0, 0.2))
hidedecorations!(ax)
tp = treeplot!(tree)
treelabels!(tp)

treehilight!(tp;
    nodes=[tree[2][2]],
    padding = (0.5, 0.1),
    alpha=1,
    z_shift=0,
)
fig
```

## Reference

```@docs; canonical=false
treehilight
```
