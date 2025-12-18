# treeplot

```@figure
tree = ((:a, :b), (:c, (:d, :e)))
treeplot(tree)
```

Working with a figure syntax

```@figure
tree = ((:a, :b), (:c, (:d, :e)))
fig = Figure()
ax = Axis(fig[1,1])
treeplot!(tree)
fig
```

## Documentation

```@docs; canonical=false
treeplot
```
