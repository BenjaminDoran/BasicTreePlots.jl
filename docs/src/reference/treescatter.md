# treescatter

`treescatter` plots a marker on each node. It is equivalent to
`scatter!(tp.orderedpoints)`, and accepts the same plot attributes as Makie's `scatter`.

````@figure treescatter
tree = ((:a, :b), (:c, (:d, :e)))
nodeweight = 1:9

fig = Figure(size = (600, 300))
ax, tp = treeplot(fig[1, 1], tree)
treescatter!(tp; color = nodeweight, markersize = 20)

ax, tp = treeplot(fig[1, 2], tree)
scatter!(tp.orderedpoints; color = nodeweight, markersize = 20)
fig
````

The markers use the coordinates computed by `treeplot`, including unrooted and daylight layouts.
They also follow changes to reactive tree attributes such as `rotation`.

````@figure treescatter_unrooted
tree = ((:a, :b), (:c, (:d, :e)))
layoutstyles = (
    :unrooted_dendrogram,
    :daylight_dendrogram,
    :unrooted_cladogram,
    :daylight_cladogram,
)
fig = Figure(size = (600, 600))

for (index, layoutstyle) in enumerate(layoutstyles)
    row, column = Tuple(CartesianIndices((2, 2))[index])
    ax = Axis(fig[row, column]; aspect = DataAspect(), title = string(layoutstyle))
    tp = treeplot!(ax, tree; layoutstyle)
    treescatter!(tp; color = 1:9, markersize = 15)
    hidedecorations!(ax)
end
fig
````

## Reference

```@docs; canonical=false
treescatter
```
