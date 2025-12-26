# Getting started

## plot the tree

````@figure gettingstarted
using CairoMakie, BasicTreePlots
tree = ((:a, :b), (:c, (:d, :e)))
treeplot(tree)
````

Because most nested collections in julia have `AbstractTrees.children` defined they can be plotted with `treeplot`.

We might want to just look at the tree rather than the axis

````@figure gettingstarted
fig = Figure()
ax = Axis(fig[1, 1])
hidedecorations!(ax)
hidespines!(ax)
treeplot!(tree)
fig
````

Rather than the square branches we can use straight branches

````@figure gettingstarted
fig = Figure()
ax = Axis(fig[1, 1])
hidedecorations!(ax)
hidespines!(ax)
treeplot!(tree; branchstyle = :straight)
fig
````

We can plot onto a Polar axis for a circular layout

````@figure gettingstarted
fig = Figure()
ax = PolarAxis(fig[1, 1])
hidedecorations!(ax)
hidespines!(ax)
treeplot!(tree)
fig
````

## Labeling tips

We can add tip labels

````@figure gettingstarted
fig = Figure()
ax = PolarAxis(fig[1, 1], rautolimitmargin = (0.0, 0.1))
hidedecorations!(ax)
hidespines!(ax)
tp = treeplot!(tree)
treelabels!(tp)
fig
````

We can increase the tip label fontsize.

````@figure gettingstarted
fig = Figure()
ax = PolarAxis(fig[1, 1], rautolimitmargin = (0.0, 0.2))
hidedecorations!(ax)
hidespines!(ax)
tp = treeplot!(tree)
treelabels!(tp; fontsize = 40)
fig
````

## Adjusting branch appearence

We can change the color of the branches

````@figure gettingstarted
fig = Figure()
ax = PolarAxis(fig[1, 1], rautolimitmargin = (0.0, 0.1))
hidedecorations!(ax)
hidespines!(ax)
tp = treeplot!(tree; branchcolor = :orange)
treelabels!(tp; fontsize = 20)
fig
````

We can change the line color based on info in the tree

````@figure gettingstarted
branchcolors = map(PreOrderDFS(tree)) do node
    hash(node)
end

fig = Figure()
ax = PolarAxis(fig[1, 1], rautolimitmargin = (0.0, 0.1))
hidedecorations!(ax)
hidespines!(ax)
tp = treeplot!(tree; branchcolor = branchcolors)
treelabels!(tp; fontsize = 20)
fig
````

For instance if we have external data about each node in the tree

````@example gettingstarted
tree_data =
    Dict(node => (; support = rand(), favorite_number = rand(1:5)) for node in PreOrderDFS(tree))
````

then we can plot support as the color and the favorite number as the line width.

````@figure gettingstarted
branchcolors = map(PreOrderDFS(tree)) do node
    tree_data[node].support
end

branchwidths = map(PreOrderDFS(tree)) do node
    tree_data[node].favorite_number
end

fig = Figure()
ax = PolarAxis(fig[1, 1], rautolimitmargin = (0.0, 0.1))
hidedecorations!(ax)
hidespines!(ax)

p = treeplot!(tree; branchcolor = branchcolors, branchwidth = branchwidths)
treelabels!(tp; fontsize = 20)
Colorbar(fig[1, 2][3, 1], p)
fig
````

## Markers for each node

We can employ markers in the nodes to showcase the tree's information

````@figure gettingstarted
fig = Figure()
ax = PolarAxis(fig[1, 1], rautolimitmargin = (0.0, 0.2))
hidedecorations!(ax)
hidespines!(ax)
tp=treeplot!(tree;)
treelabels!(tp; fontsize = 20, labeloffset = (0.0, 10))
treescatter!(tp; color = branchcolors, markersize = 15)
fig
````

`treescatter(tp)` is equivalent to `scatter(tp.orderedpoints)` so all the keyword arguments for `scatter`
should work. The points are ordered according to the result of `PreOrderDFS(tree)`, attributes can be assocated
by matching that order.

## Other adjustments of style

For a PolarAxis, We can also control the span across which the tree is plotted. with the `openangle` parameter

````@figure gettingstarted
fig = Figure()
ax = PolarAxis(fig[1, 1], rautolimitmargin = (0.0, 0.1))
hidedecorations!(ax)
hidespines!(ax)
p = treeplot!(
    tree;
    branchcolor = branchcolors,
    branchwidth = branchwidths,
    openangle = deg2rad(140),
)
Colorbar(fig[1, 2][3, 1], p)
fig
````
