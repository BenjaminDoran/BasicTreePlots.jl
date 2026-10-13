using AbstractTrees: PreOrderDFS
using CairoMakie

CairoMakie.activate!()

tree = ((:a, :b), (:c, (:d, :e)))

for layoutstyle in BasicTreePlots.UNROOTED_LAYOUTS
    @testset "$layoutstyle" begin
        figure = Figure()
        axis = Axis(figure[1, 1])
        tree_plot = treeplot!(axis, tree; layoutstyle)
        node_scatter = treescatter!(axis, tree_plot; markersize = 12)

        expected_points = Point2f[tree_plot.nodepoints[][node] for node in PreOrderDFS(tree)]
        @test node_scatter[1][] == expected_points

        tree_plot.rotation[] = Float32(π / 3)
        rotated_points = Point2f[tree_plot.nodepoints[][node] for node in PreOrderDFS(tree)]
        @test node_scatter[1][] == rotated_points
        @test node_scatter[1][] != expected_points
    end
end
