using CairoMakie
using AbstractTrees: PreOrderDFS, children

CairoMakie.activate!()

rotate_point((x, y), angle) =
    Point2f(cos(angle) * x - sin(angle) * y, sin(angle) * x + cos(angle) * y)

tree = ((:a, :b), (:c, :d))
rotation = Float32(π / 3)

for layoutstyle in BasicTreePlots.UNROOTED_LAYOUTS
    @testset "$layoutstyle" begin
        unrotated = BasicTreePlots.nodepositions(Point2f, tree; layoutstyle)

        figure = Figure()
        axis = Axis(figure[1, 1])
        tree_plot = treeplot!(axis, tree; layoutstyle, rotation)

        for node in PreOrderDFS(tree)
            @test tree_plot.nodepoints[][node] ≈ rotate_point(unrotated[node], rotation)
        end

        parent_of =
            Dict(child => parent for parent in PreOrderDFS(tree) for child in children(parent))
        for (node, segment) in zip(PreOrderDFS(tree), tree_plot.branchsegments[])
            node == tree && continue
            @test Point2f(segment[1]) ≈ tree_plot.nodepoints[][parent_of[node]]
            @test Point2f(segment[2]) ≈ tree_plot.nodepoints[][node]
        end
    end
end

@testset "annotation inheritance" begin
    figure = Figure()
    axis = Axis(figure[1, 1])
    tree_plot = treeplot!(axis, tree; layoutstyle = :unrooted_cladogram)
    node_scatter = treescatter!(tree_plot)
    node_labels = treelabels!(tree_plot; nodelabels = [:a => "a"])
    clade_label = treecladelabel!(tree_plot; cladelabels = [tree[1] => "ab"])
    clade_highlight = treehilight!(tree_plot; nodes = [tree[1]])

    old_clade_label_position = only(clade_label.label_position[])
    old_highlight = clade_highlight.clade_regions[]
    tree_plot.rotation[] = Float32(π / 2)

    @test node_scatter[1][] == tree_plot.orderedpoints[]
    @test only(node_labels.label_points[]) == tree_plot.nodepoints[][:a]
    @test only(clade_label.label_position[]) ≈
          rotate_point(old_clade_label_position, tree_plot.rotation[])
    @test clade_highlight.clade_regions[] != old_highlight
end

@testset "rooted layouts ignore rotation" begin
    for layoutstyle in (:dendrogram, :cladogram)
        figure = Figure()
        axis = Axis(figure[1, 1])
        unrotated = treeplot!(axis, tree; layoutstyle)
        rotated = treeplot!(axis, tree; layoutstyle, rotation)
        @test rotated.nodepoints[] == unrotated.nodepoints[]
    end
end
