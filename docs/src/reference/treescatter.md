# treescatter

Tree scatter plots a scatter marker on each node.

Equivalent to `scatter!(tp.orderedpoints)

````@figure treescatter
tree = ((:a, :b), (:c, (:d, :e)))
nodeweight= 1:9

fig = Figure(size=(600, 300))
ax, tp = treeplot(fig[1,1], tree)
treescatter!(tp; color=nodeweight, markersize=20)

ax, tp = treeplot(fig[1,2], tree)
scatter!(tp.orderedpoints; color=nodeweight, markersize=20)
fig
````

## Reference

```@docs; canonical=false
treescatter
```
