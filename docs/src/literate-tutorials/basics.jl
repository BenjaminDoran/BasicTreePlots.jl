#=
# Basic tree plot

basic setup
=#

using CairoMakie, BasicTreePlots
using AbstractTrees
update_theme!(Theme(size = (500, 500)))

# # plot the tree
tree = ((:a, :b), (:c, (:d, :e)))
treeplot(tree)

#==================
Because most nested collections in julia have `AbstractTrees.children` defined they can be plotted with `treeplot`.

We might want to just look at the tree rather than the axis
==================#

fig = Figure()
ax = Axis(fig[1, 1])
hidedecorations!(ax)
hidespines!(ax)
treeplot!(tree)
fig

# Rather than the square branches we can use straight branches

fig = Figure()
ax = Axis(fig[1, 1])
hidedecorations!(ax)
hidespines!(ax)
treeplot!(tree; branchstyle = :straight)
fig

#=
We can plot onto a Polar axis for a circular layout
=#

fig = Figure()
ax = PolarAxis(fig[1, 1])
hidedecorations!(ax)
hidespines!(ax)
treeplot!(tree)
fig

# We can add tip labels

fig = Figure()
ax = PolarAxis(fig[1, 1])
hidedecorations!(ax)
hidespines!(ax)
tp = treeplot!(tree)
treelabels!(tp.nodepoints)
fig

# We can increase the tip label fontsize.

fig = Figure()
ax = PolarAxis(fig[1, 1], rautolimitmargin = (0.0, 0.2))
hidedecorations!(ax)
hidespines!(ax)
tp = treeplot!(tree)
treelabels!(tp.nodepoints, fontsize = 40)
fig

# We can change the line color

fig = Figure()
ax = PolarAxis(fig[1, 1], rautolimitmargin = (0.0, 0.1))
hidedecorations!(ax)
hidespines!(ax)
tp = treeplot!(tree; branchcolor = :orange)
treelabels!(tp.nodepoints, fontsize = 20)
fig

# We can change the line color based on info in the tree

branchcolors = map(PreOrderDFS(tree)) do node
    hash(node)
end

fig = Figure()
ax = PolarAxis(fig[1, 1], rautolimitmargin = (0.0, 0.1))
hidedecorations!(ax)
hidespines!(ax)
tp = treeplot!(tree; branchcolor = branchcolors)
treelabels!(tp.nodepoints, fontsize = 20)
fig

# or employ markers in the nodes to showcase the tree's information

fig = Figure()
ax = PolarAxis(fig[1, 1], rautolimitmargin = (0.0, 0.1))
hidedecorations!(ax)
hidespines!(ax)
tp=treeplot!(tree;)
treelabels!(tp.nodepoints, fontsize = 20, labeloffset = (0.0, 0.2))
scatter!(tp.orderedpoints; color = branchcolors, markersize = 20)
fig

# For instance if we have external data about each node in the tree

tree_data = Dict(
    node => (; support = rand(), favorite_number = rand(1:5)) for node in PreOrderDFS(tree)
)

# then we can plot support as the color and the favorite number as the line width.

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
treelabels!(tp.nodepoints; fontsize = 20)
Colorbar(fig[1, 2][3, 1], p)
fig

# For a PolarAxis, We can also control the span across which the tree is plotted. with the `openangle` parameter

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
