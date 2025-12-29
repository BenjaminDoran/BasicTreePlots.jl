# # Extending to custom types

# To extend plotting trees with distances and automatic naming of nodes to your custom tree type.
# you need to extend `BasicTreePlots.distance(node::YourType)` which should return the flowting point distance from a
# node to its parent. And `BasicTreePlots.label(node::YourType)` which should return the name of the node as you
# want it represented in the plot.

# An example extending the plotting library to `NewickTree.Node` type

# ````julia
# module BasicTreePlotsNewickTreeExt
# import BasicTreePlots, NewickTree
# BasicTreePlots.distance(n::NewickTree.Node) = begin
#     d = NewickTree.distance(n)
#     isfinite(d) ? d : zero(typeof(d))
# end
# BasicTreePlots.label(n::NewickTree.Node) = NewickTree.name(n)
# end
# ````
