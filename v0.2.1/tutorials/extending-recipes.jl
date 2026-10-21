using CairoMakie, BasicTreePlots

tree = ((:a, :b), (:c, (:d, :e)))
fig, ax, tp = treeplot(tree)

tp.orderedpoints[]

tp.nodepoints[]

tp.maxtreedepth[]

map!(tp.attributes, [:tree, :nodepoints], :leafcoords) do tree, nodepoints
    leafcoords = [nodepoints[node] for node in PreOrderDFS(tree) if BasicTreePlots.isleaf(node)]
    return leafcoords
end;
scatter!(tp.leafcoords; color = 1:5, markersize = 20)
fig

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
