# # Annotating various clade groups

using CairoMakie, BasicTreePlots

# Adding annotations on both and Axis and Polar axis


tree = ((:a, :b), (:c, (:d, :e)))
nodelabels =
    (:a => "Alpha", :b => "Bravo", (:a, :b) => "Parent", (:a, :b) => "Parent", :d => "Delta")
bcolor = rand(9);

fig = Figure(size = (1000, 500))

ax1 = Axis(fig[1, 1], xautolimitmargin = (0.05, 0.1))
hidedecorations!(ax1)
hidespines!(ax1)

tp = treeplot!(tree, branchwidth = 3, colormap = :vik, visible = true, branchstyle = :straight)
treelabels!(tp.nodepoints; depth = tp.maxtreedepth[] + 0.1)
scatter!(tp.orderedpoints, markersize = 30, color = rand(9))
treecladelabel!(tp.nodepoints, lineoffset = 0.3, color = (:green))
treehilight!(tp.nodepoints; nodes = [tree, tree[1]], strokecolor = (:black, 0.2))
treehilight!(tp.nodepoints; nodes = [tree[2], tree[2][2]], strokecolor = (:black, 0.2))


ax2 = PolarAxis(fig[1, 2], rautolimitmargin = (0.0, 0.2))
hidedecorations!(ax2)
hidespines!(ax2)

tp = treeplot!(tree, branchwidth = 3, colormap = :vik, visible = true)
treelabels!(tp.nodepoints; nodelabels, labeloffset = (0.0, 0.2))
treecladelabel!(
    tp.nodepoints;
    nodelabels = [(:a, :b) => "clade 1", ((:d, :e), "clade 2")],
    lineoffset = (1.7, 1.5),
)
treecladelabel!(tp.nodepoints; lineoffset = 2.5, color = :green, labeloffset = (-2.0, -2.0))
treehilight!(
    tp.nodepoints;
    nodes = [(:a, :b), (:c, (:d, :e)), (:d, :e)],
    resolution = 25,
    color = [:lightgreen, (:lightgrey, 0.25), (:grey, 0.5)],
    strokewidth = 1,
)
fig
