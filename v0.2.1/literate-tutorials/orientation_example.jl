# # Example showing orienting tree

using CairoMakie, BasicTreePlots
tree = (((:a, :b), :c), (:d, (:e, :f)))

begin
    fig = Figure(size = (600, 600))
    treeplot(fig[1, 1], tree, orientation = :right, axis = (; title = "orientation = :right"))
    treeplot(fig[1, 2], tree, orientation = :left, axis = (; title = "orientation = :left"))
    treeplot(fig[2, 1], tree, orientation = :top, axis = (; title = "orientation = :top"))
    treeplot(fig[2, 2], tree, orientation = :bottom, axis = (; title = "orientation = :bottom"))
    fig
end

# Note the difference in the yaxis direction between
begin
    fig=Figure(size = (600, 300))
    ax1, tp1 = treeplot(
        fig[1, 1],
        tree,
        orientation = :top,
        axis = (;
            title = "orientation = :top, yreversed=true",
            yreversed = true,
            yautolimitmargin = (0.05, 0.1),
        ),
    )
    treelabels!(tp1; labeloffset = (0, -5), labelalign = (:right, :center))

    ax2, tp2 = treeplot(
        fig[1, 2],
        tree,
        orientation = :bottom,
        axis = (; title = "orientation = :bottom", yautolimitmargin = (0.1, 0.05)),
    )
    treelabels!(ax2, tp2; labelrotation = deg2rad(45))
    hidexdecorations!(ax1)
    hidexdecorations!(ax2)
    fig
end
