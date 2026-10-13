using CairoMakie

CairoMakie.activate!()

function only_rotation(rotation)
    return rotation isa Real ? rotation : only(rotation)
end

function test_full_rotation!(plot, rotation_inputs)
    rotation_outputs = map(rotation_inputs) do angle
        plot.labelrotation[] = angle
        only_rotation(plot.rotation[])
    end
    return @test rotation_outputs .- first(rotation_outputs) ≈ rotation_inputs
end

function test_label_plots!(tree_plot, tree, rotation_inputs)
    clade_label = treecladelabel!(
        tree_plot;
        cladelabels = [tree[1] => "clade"],
        labelrotation = first(rotation_inputs),
    )
    node_label = treelabels!(
        tree_plot;
        nodelabels = [tree[1] => "node"],
        labelrotation = first(rotation_inputs),
    )

    test_full_rotation!(clade_label, rotation_inputs)
    return test_full_rotation!(node_label, rotation_inputs)
end

tree = ((:a, :b), (:c, :d))
rotation_inputs = Float32[0, π/2, π, 3π/2, 2π]
axis_layouts = (:dendrogram, :cladogram, BasicTreePlots.UNROOTED_LAYOUTS...)

for layoutstyle in axis_layouts
    @testset "Axis $layoutstyle" begin
        figure = Figure()
        axis = Axis(figure[1, 1])
        tree_plot = treeplot!(axis, tree; layoutstyle)
        test_label_plots!(tree_plot, tree, rotation_inputs)
    end
end

for layoutstyle in (:dendrogram, :cladogram)
    @testset "PolarAxis $layoutstyle" begin
        figure = Figure()
        axis = PolarAxis(figure[1, 1])
        tree_plot = treeplot!(axis, tree; layoutstyle)
        test_label_plots!(tree_plot, tree, rotation_inputs)
    end
end

figure = Figure()
axis = Axis(figure[1, 1])
tree_plot = treeplot!(axis, tree; layoutstyle = :unrooted_cladogram)
per_label_rotations = Float32[0, π]
node_labels =
    treelabels!(tree_plot; nodelabels = [:a => "a", :b => "b"], labelrotation = per_label_rotations)
@test node_labels.rotation[] == per_label_rotations
node_labels.labelrotation[] = per_label_rotations .+ 2π
@test node_labels.rotation[] ≈ per_label_rotations .+ 2π
