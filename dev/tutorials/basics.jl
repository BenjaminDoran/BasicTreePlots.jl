using CairoMakie, BasicTreePlots
using AbstractTrees
update_theme!(Theme(size = (500, 500)))

tree = ((:a, :b), (:c, (:d, :e)))
treeplot(tree)

fig = Figure()
ax = Axis(fig[1, 1])
hidedecorations!(ax)
hidespines!(ax)
treeplot!(tree)
fig

fig = Figure()
ax = Axis(fig[1, 1])
hidedecorations!(ax)
hidespines!(ax)
treeplot!(tree; branchstyle = :straight)
fig

fig = Figure()
ax = PolarAxis(fig[1, 1])
hidedecorations!(ax)
hidespines!(ax)
treeplot!(tree)
fig

fig = Figure()
ax = PolarAxis(fig[1, 1], rautolimitmargin = (0.0, 0.2))
hidedecorations!(ax)
hidespines!(ax)
treeplot!(tree; tipfontsize = 30)
fig

fig = Figure()
ax = PolarAxis(fig[1, 1], rautolimitmargin = (0.0, 0.1))
hidedecorations!(ax)
hidespines!(ax)
treeplot!(tree; linecolor = :orange, tipfontsize = 12)
fig

branchcolors = map(PreOrderDFS(tree)) do node
    hash(node)
end

fig = Figure()
ax = PolarAxis(fig[1, 1], rautolimitmargin = (0.0, 0.1))
hidedecorations!(ax)
hidespines!(ax)
treeplot!(tree; linecolor = branchcolors, tipfontsize = 12)
fig

tree_data = Dict(
    node => (; support = rand(), favorite_number = rand(1:5)) for node in PreOrderDFS(tree)
)

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
p = treeplot!(tree; linecolor = branchcolors, linewidth = branchwidths, tipfontsize = 12)
Colorbar(fig[1, 2][3, 1], p)
fig

fig = Figure()
ax = PolarAxis(fig[1, 1], rautolimitmargin = (0.0, 0.1))
hidedecorations!(ax)
hidespines!(ax)
p = treeplot!(
    tree;
    linecolor = branchcolors,
    linewidth = branchwidths,
    tipfontsize = 12,
    tipannotationsvisible = false,
)
Colorbar(fig[1, 2][3, 1], p)
fig

fig = Figure()
ax = PolarAxis(fig[1, 1], rautolimitmargin = (0.0, 0.1))
hidedecorations!(ax)
hidespines!(ax)
p = treeplot!(
    tree;
    linecolor = branchcolors,
    linewidth = branchwidths,
    tipfontsize = 12,
    openangle = deg2rad(140),
)
Colorbar(fig[1, 2][3, 1], p)
fig

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
