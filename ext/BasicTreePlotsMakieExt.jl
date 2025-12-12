module BasicTreePlotsMakieExt

using BasicTreePlots: BasicTreePlots
import BasicTreePlots:
    treeplot,
    treeplot!,
    treelabels,
    treelabels!,
    treecladelabel,
    treecladelabel!,
    treearea,
    treearea!

using Makie
using Makie: Point2f, @recipe, automatic, Polar, Polygon

using AbstractTrees: AbstractTrees
using AbstractTrees: PreOrderDFS

toangle(y, N, openangle) = (y / N) * (2π - (openangle % 2pi))

# treeplot ====================================================================================

"""
	treeplot(tree; kwargs...)

# Args:

- tree, the root node of a tree that has `AbstractTrees.children()` defined.
	All nodes should be reachable by using `AbstractTrees.PreOrderDFS()` iterator.

# Examples

Quick snippet for seeing basic features

```
using NewickTree, CairoMakie
tree = nw"((a:0.1, b:0.2):0.3, (c:0.5, (d:0.3, e:0.1):0.1):0.2);"
fig = Figure(size=(500, 500))
layoutstyles = (:dendrogram, :cladogram)
branchstyles = (:square, :straight)
for i in 1:2, j in 1:2
ax, tp = treeplot(fig[i,j], tree;
    layoutstyle=layoutstyles[i],
    branchstyle=branchstyles[j],
    axis=(; title=join([layoutstyles[i]), ", ", branchstyles[j]])
)
treelabels!(tp.nodepoints)
scatter!(tp.orderedpoints)
end
fig
```

This can then be annotated with `treearea`, `treelabels`, and `treecladelabel` plots
"""
@recipe TreePlot (tree,) begin

    """If `BasicTreePlots.distance()` is not `nan` for root, show line linking root to parent."""
    showroot = false

    """
    Available options are `:square` or `:straight`.
    `:square` will display line from child to parent by going back to the height of the parent,
    before connecting back to the parent node at a right angle.
    `straight` will display line from child to parent as a straight direct line from child to parent.
    """
    branchstyle = :square

    """
    Available options are `:dendrogram`, or `:cladogram`.
    `:dendrogram` displays tree taking into account the distance between parent and children nodes as
    calculated from `BasicTreePlots.distance(node)`. If the distance is not defined, it defaults to `1` and
    is equivalent to the `:cladogram` layout `:cladogram` displays the tree where each distance from a child
    node to their parent is set to `1`.
    """
    layoutstyle = :dendrogram

    """
    Can be either a single color `:black`, color plus alpha transperency `(:black, 0.5)`,
    or a vector of numbers for each node in pre-walk order.
    color for each node is associated to the line connecting it to its parent.
    """
    branchcolor = @inherit color :black

    """
    Can be either a single width of type `Real` or a vector of numbers for each node in pre-walk order.
    width for each node is associated to the branch connecting it to its parent.
    """
    branchwidth = @inherit linewidth 1.0


    """
    Options are `:right`, `:top`, `:left', and `:bottom`, and indicate where the leaves point away from the root.
    `:right` and `:top` will keep the root at zero the leaves will increase in distance on the `x` and `y` axis respectively.
    `:left` and `bottom` will translate the tree after multiplying the axis by `-1` so that the deepest leaf
    is at `0` and the internal nodes increase in height away from that leaf.

    To keep the root at zero but the leaves pointing down, use `orientation=:top` in combination with
    `Axis(figloc; yreversed=true)`.

    """
    orientation = :right

    maxdepthoffset = 0.0f0

    """
    Number of points associated to each line segment. Can be decreased to increase plotting speed.
    Or, increased if lines that should be smooth are not.
    """
    branchpointresolution = 25

    """
    Offset added to first leaf. At default leaves start counting from `1`. Set to -1 to start counting from
    `0`. Useful for starting the first leaf pointing directly right when using `PolarAxis` or setting the first
    leaf at the `y` origin when using `Axis`
    """
    leafoffset = 0

    """
    Angle in radians that limits span of tree around the circle when plotted on `PolarAxis`.
    if `openangle = deg2rad(5)` then leaf tips will spread across angles `leafoffset` to `2π - openangle`.
    """
    openangle = 0

    """
    If `true` draw guide lines from each leaf tip to the depth of the leaf that is maximally distant from root.
    Useful for connecting leaves to there location on the y axis (or θ axis if plotted on `PolarAxis`).
    """
    usemaxdepth = false

    Makie.mixin_colormap_attributes()...
    Makie.mixin_generic_plot_attributes()...
end

function Makie.plot!(plt::TreePlot)

    ## Get calculate main coords
    inputs = [
        :tree,
        :showroot,
        :layoutstyle,
        :leafoffset,
        :branchstyle,
        :branchpointresolution,
        :openangle,
        :orientation,
        :maxdepthoffset,
        :transform_func,
    ]

    map!(
        plt.attributes,
        inputs,
        [:nodepoints, :orderedpoints, :branchsegments, :maxtreedepth, :nleaves], # outputs
    ) do tree,
    showroot,
    layoutstyle,
    leafoffset,
    branchstyle,
    resolution,
    openangle,
    orientation,
    maxdoff,
    tf

        nleaves = BasicTreePlots.leafcount(tree)

        nodepoints = BasicTreePlots.nodepositions(
            Point2f,
            tree;
            showroot,
            layoutstyle,
            nodeoffset = leafoffset,
        )

        maxtreedepth = maximum(x -> x[1], values(nodepoints))

        branchsegments =
            BasicTreePlots.makesegments(nodepoints, tree; branchstyle, resolution)

        if orientation !== :right && tf isa Polar
            @warn("Orientation of $orientation is not well tested on PolarAxis")
        end

        if orientation === :right
        elseif orientation === :left
            map!(values(nodepoints)) do (x, y)
                (-x + maxtreedepth + maxdoff, y)
            end
            map!(branchsegments) do segment
                [(-x + maxtreedepth + maxdoff, y) for (x, y) in segment]
            end
        elseif orientation === :top
            map!(values(nodepoints)) do (x, y)
                (y, x)
            end
            map!(branchsegments) do segment
                [(y, x) for (x, y) in segment]
            end
        elseif orientation === :bottom
            map!(values(nodepoints)) do (x, y)
                (y, -x + maxtreedepth + maxdoff)
            end
            map!(branchsegments) do segment
                [(y, -x + maxtreedepth + maxdoff) for (x, y) in segment]
            end
        else
            @warn(
                "Orientation of $orientation is not in options of :right, :top, :left, or :bottom"
            )
        end

        # modify all points if axis is polar
        if tf isa Polar

            # update node positions
            map!(values(nodepoints)) do (x, y)
                (toangle(y, nleaves, openangle), x)
            end

            # and segments
            map!(branchsegments) do segment
                [(toangle(y, nleaves, openangle), x) for (x, y) in segment]
            end
        end

        orderedpoints = Point2f[nodepoints[node] for node in PreOrderDFS(tree)]

        return nodepoints, orderedpoints, branchsegments, maxtreedepth, nleaves
    end

    # Check length of branchcolor and branchwidth vectors to ensure correct length
    if plt.branchcolor[] isa Union{AbstractVector,AbstractRange} &&
       length(plt.branchcolor[]) != length(plt.branchsegments[])
        error(
            "length of branchcolor ($(length(plt.branchcolor[]))) must match number nodes in tree ($(length(plt.branchsegments[])))",
        )
    end

    if plt.branchwidth[] isa Union{AbstractVector,AbstractRange} &&
       length(plt.branchwidth[]) != length(plt.branchsegments[])
        error(
            "length of branchwidth ($(length(plt.branchwidth[]))) must match number nodes in tree ($(length(plt.branchsegments[])))",
        )
    end

    # combine branchsegments into single NaN seperated line
    map!(plt.attributes, :branchsegments, :expandedbranchsegments) do branchsegments
        reduce(vcat, branchsegments)
    end

    # Setup linecolor
    map!(
        plt.attributes,
        [:branchcolor, :branchsegments],
        :color,
    ) do branchcolor, branchsegments
        if branchcolor isa Union{AbstractVector,AbstractRange}
            return repeat(branchcolor, inner = length(first(branchsegments)))
        end
        return branchcolor
    end

    # Setup linewidth
    map!(
        plt.attributes,
        [:branchwidth, :branchsegments],
        :linewidth,
    ) do branchwidth, branchsegments
        if branchwidth isa Union{AbstractVector,AbstractRange}
            return repeat(branchwidth, inner = length(first(branchsegments)))
        end
        return branchwidth
    end


    Makie.lines!(plt, plt.attributes, plt.expandedbranchsegments;)
end



# treelabels ====================================================================================
"""
Adds text labels associated to particular nodes in a tree already plotted with `treeplot`

## Examples

Defaults to labeling the leaves of the tree based on `BasicTreePlots.label(leafnode)`

```
ax, p = treeplot(tree)
treelabels!(p.nodepoints)
```

Also possible to specify a subset of nodes with custom labels
```
ax, p = treeplot(tree)
treelabels!(p.nodepoints; nodelabels=Dict(node1 => "Node 1", node_a => "My special node"))
```

"""
@recipe TreeLabels (nodepoints,) begin
    """
    List of nodes and associated labels for which to plot. Should be an iterable where
    each element is a pair `node => label`. Basically `[(node, label) for (node, label) in nodelabels]` should
    not error and provide each node and label you want plotted.

    If nothing will default to `BasicTreePlots.tipannotations(nodepoints)` and plot
    `BasicTreePlots.label(leaf)` for each leaf

    Nodes should have coordinates accessible via `nodepoints[node]`.
    These coordinates can be calculated with `tp = treeplot!(tree)` and accessed with `tp.nodepoints`.
    """
    nodelabels = nothing

    """
    Depth <: Real 'distance from root' in data space at which to plot tree text labels.
    """
    depth = nothing

    "Font of the text labels"
    font = @inherit font :regular

    "Font size of the node labels"
    fontsize = @inherit fontsize 9.0f0

    """
    Options are `:horizontal`, `:radial`, `:aligned`, or a number `θ<:Real` in radians.
    If `automatic`, will default to `:aligned` on polar axis and `:horizontal` otherwise.
    """
    labelrotation = automatic

    """
    Text alignment of labels to anchor points, Is overridden when labelrotation=:aligned (default).
    """
    labelalign = automatic

    """
    Offset in data space to push text label anchor points.
    """
    labeloffset = automatic

    """
    If `true` draw guide lines from node to label anchorpoint.
    Useful for visually connecting leaves to their location on the y axis (or θ axis if plotted on `PolarAxis`),
    especially when using the `depth` attribute.
    """
    guidesvisible = true
    "Line width of the guide lines"
    guideswidth = 0.5
    "Line color of the guide lines"
    guidescolor = :lightgray
    "Line style of the guide lines"
    guidesstyle = :solid

    Makie.mixin_generic_plot_attributes()...
end

function Makie.plot!(plt::TreeLabels)
    map!(
        plt.attributes,
        [
            :nodepoints,
            :nodelabels,
            :depth,
            :labelalign,
            :labelrotation,
            :labeloffset,
            :transform_func,
        ],
        [:label_points, :labels, :align, :rotation, :guides_points], # outputs
    ) do nodepoints, nodelabels, depth, lalign, lrotation, loffset, tf
        ## Get all tip positions and labels
        if isnothing(nodelabels)
            label_points_start, labels = BasicTreePlots.tipannotations(nodepoints)
        else
            labels = []
            label_points_start = Point2f[]
            for (node, label) in nodelabels
                push!(labels, label)
                push!(label_points_start, nodepoints[node])
            end
        end

        ## Lines from each tip to max tip depth
        guides_points = Point2f[]
        if !isnothing(depth)
            label_points_end = # update to max depth
                if tf isa Polar
                    map(pos -> Point2f(pos[1], depth), label_points_start)
                else
                    map(pos -> Point2f(depth, pos[2]), label_points_start)
                end
            for (beginpos, endpos) in zip(label_points_start, label_points_end)
                push!(guides_points, beginpos)
                push!(guides_points, endpos)
                push!(guides_points, Point2f(NaN, NaN))
            end
        end
        # finalize points for labels
        ## Need to add offset to points directly in data space, because the text recipe uses pixel space
        label_points = !isnothing(depth) ? label_points_end : label_points_start
        if loffset === automatic
            if tf isa Polar
                map!(pos -> pos + Point2f(0.0, 0.05), label_points)
            else
                map!(pos -> pos + Point2f(0.05, 0.0), label_points)
            end
        else
            map!(pos -> pos + Point2f(loffset), label_points)
        end

        # Handle rotation and alignment of labels, particularly for the Polar axis
        lrot = lrotation === automatic ? tf isa Polar ? :aligned : :horizontal : lrotation
        if lrot isa Real
            rotation = lrot
        elseif lrot isa AbstractArray{<:Number}
            rotation = lrot
        elseif lrot === :horizontal
            rotation = 0.0f0
        elseif lrot === :radial
            rotation = map(pos -> pos[1], label_points)
        elseif lrot === :aligned
            rotation = map(label_points) do pos
                cos(pos[1]) > 0.0 ? pos[1] : pos[1] + pi
            end
            lalign = map(label_points) do pos
                cos(pos[1]) > 0.0 ? (:left, :center) : (:right, :center)
            end
        else
            rotation = lrot
        end

        align = lalign === automatic ? (:left, :center) : lalign

        return label_points, labels, align, rotation, guides_points
    end

    Makie.lines!(
        plt,
        plt.attributes,
        plt.guides_points;
        visible = plt.guidesvisible,
        color = plt.guidescolor,
        linewidth = plt.guideswidth,
        linestyle = plt.guidesstyle,
    )

    Makie.text!(plt, plt.attributes, plt.label_points; text = plt.labels)

end


# treecladelabel ==============================================================================
"""
	treecladelabel(nodepoints::OrderedDict(node=>point); nodelabels=[node1 => "Node 1", node2 => "Node 2"])

# Examples

```
tree = ((:a, :b), (:c, (:d, :e)))
fig, ax, tp = treeplot(tree)
treecladelabel!(tp.nodepoints; nodelabels=[(:a, :b) => "Node 1", tree[2] => "Node 2"])
fig
```

"""
@recipe TreeCladeLabel (nodepoints,) begin
    """
    List of nodes and associated labels for which to draw surrounding regions. Should be an iterable where
    each element is a pair `node => label`. Basically `[(node, label) for (node, label) in nodelabels]` should
    not error and provide each node and label you want plotted.

    if `nodelabels` is nothing, will default to `first(last(nodepoints))`, and will plot an area surrounding
    the full tree (assuming `nodepoints` has been calculated from `treeplot`).

    Nodes and their decendent nodes should have coordinates accessible via `nodepoints[node]`.
    These coordinates can be calculated with `tp = treeplot!(tree)` and accessed with `tp.nodepoints`.
    """
    nodelabels = nothing

    # Line options
    """
    Offset in data space at which to draw the line indicating the clade being labeled.
    Larger numbers move the line further from the root
    """
    lineoffset = 0.2f0
    "Amount to increase/decrease the width of the line in data space"
    linepadding = 0.05f0
    linestyle = @inherit linestyle :solid
    linewidth = @inherit linewidth 1
    lineresolution = 50

    # Label options
    labelfont = @inherit font :regular
    labelfontsize = @inherit fontsize 12.0f0
    "Offset of the text label away from anchor point in pixel space"
    labeloffset = @inherit offset (5.0f0, 0.0f0)
    labelalign = @inherit align (:center, :top)
    labelrotation = @inherit rotation pi/2

    # Options for both
    color = @inherit color (:black, 1.0f0)
    Makie.mixin_generic_plot_attributes()...
end

_unzip(a) = collect(getfield.(a, fld) for fld in fieldnames(eltype(a)))

function Makie.plot!(plt::TreeCladeLabel)
    inputs = [
        :nodepoints,
        :nodelabels,
        :lineoffset,
        :linepadding,
        :lineresolution,
        :labelrotation,
        :transform_func,
    ]
    map!(
        plt.attributes,
        inputs,
        [:line_points, :label_position, :label_text, :rotation],
    ) do nodepoints, nodelabels, lineoffset, linepadding, lineresolution, labelrotation, tf

        ## Default to labeling whole tree
        nodelabels = if isnothing(nodelabels)
            root = first(last(nodepoints))
            [root => BasicTreePlots.label(root)]
        else
            nodelabels
        end

        ## repeat line offset if single number so that zip(nodelabels, lineoffset) works
        lineoffset =
            lineoffset isa Real ? repeat([lineoffset], length(nodelabels)) : lineoffset

        ## For each clade => cladelabel
        line_points, label_positions, labels, rotation =
            map(zip(collect(nodelabels), lineoffset)) do ((node, label), loff)
                ## Get bounding box coordinates
                amin, amax = extrema(n -> first(nodepoints[n]), PreOrderDFS(node))
                bmin, bmax = extrema(n -> last(nodepoints[n]), PreOrderDFS(node))

                ## Extract which coordinates draw line
                depth = tf isa Polar ? bmax : amax
                widthmin, widthmax = tf isa Polar ? (amin, amax) : (bmin, bmax)

                ## Make line
                line_points = Point2f[
                    ((depth+loff, y) for y ∈ range(
                        widthmin-linepadding,
                        widthmax+linepadding,
                        lineresolution,
                    ))...,
                    (NaN, NaN),
                ]
                line_points = tf isa Polar ? reverse.(line_points) : line_points

                ## Put label at center of line
                label_position =
                    Point2f(depth + loff, widthmin + ((widthmax - widthmin) / 2))
                label_position = tf isa Polar ? reverse(label_position) : label_position

                ## Transform coordinate if plotting in Polar Axis
                rotation = if tf isa Polar
                    label_position[1] + labelrotation
                else
                    labelrotation
                end

                return line_points, label_position, label, rotation
            end |> _unzip
        line_points = reduce(vcat, line_points)

        return line_points, label_positions, labels, rotation
    end

    Makie.lines!(plt, plt.attributes, plt.line_points;)
    Makie.text!(
        plt,
        plt.attributes,
        plt.label_position;
        text = plt.label_text,
        offset = plt.labeloffset,
        align = plt.labelalign,
        font = plt.labelfont,
        fontsize = plt.labelfontsize,
    )
end

# treearea ====================================================================================
"""
	treearea!(nodepoints::OrderedDict(node => coordinate); nodes = [node1, node2])

# Examples

```
tree = ((:a, :b), (:c, (:d, :e)))
fig, ax, tp = treeplot(tree)
treearea!(tp.nodepoints; nodes=[tree[1], (:d, :e)])
fig
```
"""
@recipe TreeArea (nodepoints,) begin
    """
    List of nodes for which to draw surrounding regions.
    Assumes that each node and decendent node is accessible as `nodepoints[node]`. `nodepoints` can be accessed
    from `tp = treeplot(tree)` as `tp.nodepoints`.
    """
    nodes = nothing

    # Fill
    """
    Padding value to expand region around clade. Expects `(root_edge, leave_edge, first_leaf_edge, last_leaf_edge)`.
    When plotting on `Axis`, the `first_leaf_edge` is at the bottom. If input is `(num_1, num_2)`,
    the resulting padding will be `(num_1, num_1, num_2, num_2)`, and if the input is `num_1` the padding will
    be `(num_1, num_1, num_1, num_1)`.
    """
    padding = 0.1f0
    """
       Sets the color of the tree area.
       """
    color = @inherit patchcolor
    """
       Sets the alpha value of the shaded region in the tree area.
       """
    alpha = @inherit alpha 0.25
    resolution = 30

    # Stroke
    "Color of stroke around shaded region. If `:transparent` (default) stroke wont be seen."
    strokecolor = (:black, 1.0)
    "Width of stroke line around shaded region"
    strokewidth = @inherit strokewidth 0.0
    # "Style of stroke around region"
    strokestyle = @inherit linestyle :solid
    """
       Sets which attributes to cycle when creating multiple plots. The values to
       cycle through are defined by the parent Theme. Multiple cycled attributes can
       be set by passing a vector. Elements can
       - directly refer to a cycled attribute, e.g. `:color`
       - map a cycled attribute to a palette attribute, e.g. `:linecolor => :color`
       - map multiple cycled attributes to a palette attribute, e.g. `[:linecolor, :markercolor] => :color`
       """
    cycle = [:color => :patchcolor]

    "Allows default shifting of clade areas to back of plot; input into `Makie.translate!(plt, 0, 0, plt.z_shift[])`"
    z_shift = -1
    Makie.mixin_generic_plot_attributes()...
end

function Makie.plot!(plt::TreeArea)
    map!(
        plt.attributes,
        [:nodepoints, :nodes, :resolution, :padding, :transform_func],
        [:clade_regions],
    ) do nodepoints, nodes, resolution, padding, tf

        # if no nodes provided use root
        nodes = isnothing(nodes) ? [first(last(nodepoints))] : nodes

        # expand padding to root, leaves, leftwidth, rightwidth directions
        padding = Makie.to_lrbt_padding(padding)

        clade_regions = map(nodes) do node

            ## Get bounding box coordinates
            amin, amax = extrema(n -> first(nodepoints[n]), PreOrderDFS(node))
            bmin, bmax = extrema(n -> last(nodepoints[n]), PreOrderDFS(node))

            ## Extract which coordinates draw line
            depthmin, depthmax = tf isa Polar ? (bmin, bmax) : (amin, amax)
            widthmin, widthmax = tf isa Polar ? (amin, amax) : (bmin, bmax)

            depthmin -= padding[1]
            depthmax += padding[2]
            widthmin -= padding[3]
            widthmax += padding[4]

            clade_region = Point2f[
                (depthmin, widthmin),
                ((depthmin, i) for i ∈ range(widthmin, widthmax, resolution))...,
                (depthmin, widthmax),
                (depthmax, widthmax),
                ((depthmax, i) for i ∈ range(widthmax, widthmin, resolution))...,
                (depthmax, widthmin),
                (depthmin, widthmin),
            ]
            clade_region =
                tf isa Polar ? Polygon(reverse.(clade_region)) : Polygon(clade_region)
            return clade_region
        end
        clade_regions = length(clade_regions) == 1 ? only(clade_regions) : clade_regions
        return (clade_regions,)
    end


    p = Makie.poly!(
        plt,
        plt.attributes,
        plt.clade_regions;
        # color = plt.fillcolor,
        linestyle = plt.strokestyle,
    )

    Makie.translate!(p, 0, 0, plt.z_shift[])
end

end # module

# # themes ======================================================================================
# # TODO: Figure out best way to expose, may need to be added directly to Makie themes.
# theme_empty() = Makie.Theme(
#     Axis = (;
#         topspinevisible = false,
#         rightspinevisible = false,
#         leftspinevisible = false,
#         bottomspinevisible = false,
#         xticklabelsvisible = false,
#         xgridvisible = false,
#         xminorgridvisible = false,
#         xticksvisible = false,
#         xminorticksvisible = false,
#         xlabelvisible = false,
#         yticklabelsvisible = false,
#         ygridvisible = false,
#         yminorgridvisible = false,
#         yticksvisible = false,
#         yminorticksvisible = false,
#         ylabelvisible = false,
#     ),
#     Axis3 = (;
#         xspinesvisible = false,
#         yightspinesvisible = false,
#         zspinesvisible = false,
#         xticklabelsvisible = false,
#         xgridvisible = false,
#         xminorgridvisible = false,
#         xticksvisible = false,
#         xminorticksvisible = false,
#         xlabelvisible = false,
#         yticklabelsvisible = false,
#         ygridvisible = false,
#         yminorgridvisible = false,
#         yticksvisible = false,
#         yminorticksvisible = false,
#         ylabelvisible = false,
#         zticklabelsvisible = false,
#         zgridvisible = false,
#         zminorgridvisible = false,
#         zticksvisible = false,
#         zminorticksvisible = false,
#         zlabelvisible = false,
#     ),
#     PolarAxis = (;
#         spinevisible = false,
#         rticklabelsvisible = false,
#         rgridvisible = false,
#         rminorgridvisible = false,
#         thetaticklabelsvisible = false,
#         thetagridvisible = false,
#         thetaminorgridvisible = false,
#     ),
# )
