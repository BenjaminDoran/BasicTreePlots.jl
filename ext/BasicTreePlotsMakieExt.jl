module BasicTreePlotsMakieExt

using BasicTreePlots: BasicTreePlots
import BasicTreePlots:
    treeplot,
    treeplot!,
    treescatter,
    treescatter!,
    treelabels,
    treelabels!,
    treecladelabel,
    treecladelabel!,
    treehilight,
    treehilight!

using Makie
using Makie: Point2f, @recipe, automatic, Polar, Polygon

using AbstractTrees: AbstractTrees
using AbstractTrees: PreOrderDFS, children

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

This can then be annotated with `treehilight`, `treelabels`, and `treecladelabel` plots
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
    Available options are `:dendrogram`, `:cladogram`, `:unrooted_dendrogram`, or `:unrooted_cladogram`.
    `:dendrogram` displays tree taking into account the distance between parent and children nodes as
    calculated from `BasicTreePlots.distance(node)`. If the distance is not defined, it defaults to `1` and
    is equivalent to the `:cladogram` layout. `:cladogram` displays the tree where each distance from a child
    node to their parent is set to `1`.
    `:unrooted_dendrogram` displays the tree using the equal-angle algorithm (Felsenstein) with branch
    lengths from `BasicTreePlots.distance(node)`, producing a radial layout where the root is at the center
    and branches fan outward. Not compatible with `PolarAxis`; `orientation`, `branchstyle`, and `usemaxdepth`
    are ignored.
    `:unrooted_cladogram` is like `:unrooted_dendrogram` but with all branch lengths set to `1`.
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
    If `true` draw lines of each leaf tip to the depth of the leaf that is maximally distant from root.
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
        :usemaxdepth,
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
    usemaxdepth,
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


        is_unrooted = layoutstyle in BasicTreePlots.UNROOTED_LAYOUTS
        maxtreedepth = if is_unrooted
            root_x, root_y = nodepoints[tree]
            maximum(values(nodepoints)) do (x, y)
                hypot(x - root_x, y - root_y)
            end
        else
            maximum(x -> x[1], values(nodepoints))
        end

        if usemaxdepth && !is_unrooted
            foreach(PreOrderDFS(tree)) do node
                if BasicTreePlots.isleaf(node)
                    (x, y) = nodepoints[node]
                    nodepoints[node] = (maxtreedepth, y)
                end
            end
        end

        branchsegments = BasicTreePlots.makesegments(nodepoints, tree; branchstyle, resolution, layoutstyle)

        if is_unrooted
            if tf isa Polar
                error(
                    "Unrooted and daylight layouts are not compatible with PolarAxis. Use a regular Axis instead."
                )
            end
            if orientation !== :right
                @warn "orientation=$orientation is ignored for unrooted layouts"
            end
            if usemaxdepth
                @warn "usemaxdepth is ignored for unrooted layouts"
            end
        else
            if orientation !== :right && tf isa Polar
                @warn("Orientation of $orientation is not well tested on PolarAxis")
            end

            if orientation === :right || orientation === :out
            elseif orientation === :left || orientation === :in
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
    map!(plt.attributes, [:branchcolor, :branchsegments], :color) do branchcolor, branchsegments
        if branchcolor isa Union{AbstractVector,AbstractRange}
            return repeat(branchcolor, inner = length(first(branchsegments)))
        end
        return branchcolor
    end

    # Setup linewidth
    map!(plt.attributes, [:branchwidth, :branchsegments], :linewidth) do branchwidth, branchsegments
        if branchwidth isa Union{AbstractVector,AbstractRange}
            return repeat(branchwidth, inner = length(first(branchsegments)))
        end
        return branchwidth
    end


    Makie.lines!(plt, plt.attributes, plt.expandedbranchsegments;)
end

# treescatter ====================================================================================
"""
treescatter(tp::TreePlot; kwargs...)
treescatter!(tp::TreePlot; kwargs...)

Equivalent to calling `Makie.scatter!(tp.orderedpoints; kwargs...)`. The `tp.orderedpoints` is a `Point2f[]` vector
holding the coordinates of each node in the tree in the order returned by `AbstractTrees.PreOrderDFS`.
"""
BasicTreePlots.treescatter(tp::Plot{treeplot}; kwargs...) = scatter(tp.orderedpoints; kwargs...)
BasicTreePlots.treescatter!(tp::Plot{treeplot}; kwargs...) = scatter!(tp.orderedpoints; kwargs...)
BasicTreePlots.treescatter!(
    ax::Union{Makie.Block,Makie.GridPosition},
    tp::Plot{treeplot};
    kwargs...,
) = scatter!(ax, tp.orderedpoints; kwargs...)

BasicTreePlots.treescatter(
    ax::Union{Makie.Block,Makie.GridPosition},
    tp::Plot{treeplot};
    kwargs...,
) = scatter(ax, tp.orderedpoints; kwargs...)


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
    Available options:
    `nothing` (default) in which case the anchorpoints for the labels are directly on the nodes being labeled.
    `depth=:align`, Places the anchorpoints at a constant depth equal to the leaf node maximally distant from the root.
    `depth=<:Real`, sets the custom constant depth at which the label anchorpoints are set.
    `depth=(node,pos)->Point2f`, Determines a custom function that takes a node and its coordinate and returns
    where the label anchorpoint should be.
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
    Offset in pixel space to push text label anchor points. Available options:
    `automatic` (default) if plotting on `Axis()` the offset is (5px, 0), if on `PolarAxis()` the default is
    `5px * (cos(θ), sin(θ))` where θ is the radian angle of the node.
    `labeloffset::Real` defaults to offsetting the label in pixels toward the x direction for `Axis`` and in radius for `PolarAxis`
    `labeloffset=Tuple{<:Real, <:Real}`, if plotting on an `Axis` provide `(x,y)`, if on `PolarAxis` provide `(θ, r)`
    in pixel units for the offset relative to the label anchorpoint.
    `labeloffset::Function=(node,pos)->(x px, y px)`, Provide a custom function that takes a node and its coordinate
    in dataspace and return a pixel space offset. Note that pixel space does not get converted like the `PolarAxis`,
    so conversion of coordinates may be required `r_off * (cos(θ+θ_off), sin(θ+θ_off))`.
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

    "Tree orientation"
    treeorientation = :right

    "Tree root node, used to compute branch angles for unrooted layouts. Forwarded automatically from `treeplot`."
    tree = nothing

    "Layout style of the parent treeplot. Forwarded automatically from `treeplot`."
    treelayoutstyle = :dendrogram

    Makie.mixin_generic_plot_attributes()...
end

# I think this covers the main ways of calling the functions with a treeplot directly
treelabels!(plt::TreePlot; kwargs...) =
    treelabels!(plt.nodepoints; treeorientation = plt.orientation, tree = plt.tree, treelayoutstyle = plt.layoutstyle, kwargs...)
treelabels(plt::TreePlot; kwargs...) =
    treelabels(plt.nodepoints; treeorientation = plt.orientation, tree = plt.tree, treelayoutstyle = plt.layoutstyle, kwargs...)
treelabels!(ax::Union{Makie.Block,Makie.GridPosition}, plt::TreePlot; kwargs...) =
    treelabels!(ax, plt.nodepoints; treeorientation = plt.orientation, tree = plt.tree, treelayoutstyle = plt.layoutstyle, kwargs...)
treelabels(ax::Union{Makie.Block,Makie.GridPosition}, plt::TreePlot; kwargs...) =
    treelabels(ax, plt.nodepoints; treeorientation = plt.orientation, tree = plt.tree, treelayoutstyle = plt.layoutstyle, kwargs...)
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
            :treeorientation,
            :transform_func,
            :tree,
            :treelayoutstyle,
        ],
        [:label_points, :labels, :align, :rotation, :offset, :guides_points], # outputs
    ) do nodepoints, nodelabels, depth, lalign, lrotation, loffset, torientation, tf, tree, treelayoutstyle
        is_unrooted = treelayoutstyle in BasicTreePlots.UNROOTED_LAYOUTS

        ## Build parent lookup for computing branch angles (unrooted layouts only)
        parent_of = Dict()
        if is_unrooted && !isnothing(tree)
            function _build_parent_map!(node)
                for c in children(node)
                    parent_of[c] = node
                    _build_parent_map!(c)
                end
            end
            _build_parent_map!(tree)
        end

        ## Get all tip positions and labels
        if isnothing(nodelabels)
            labeled_nodes, label_points_start, labels = BasicTreePlots.tipannotations(nodepoints)
        else
            labels = []
            labeled_nodes = []
            label_points_start = Point2f[]
            for (node, label) in nodelabels
                push!(labels, label)
                push!(labeled_nodes, node)
                push!(label_points_start, nodepoints[node])
            end
        end

        ## Compute branch angles for each labeled node (unrooted layouts only)
        branch_angles = if is_unrooted && !isnothing(tree)
            map(labeled_nodes) do node
                if haskey(parent_of, node)
                    ppos = nodepoints[parent_of[node]]
                    npos = nodepoints[node]
                    Float32(atan(npos[2] - ppos[2], npos[1] - ppos[1]))
                else
                    0.0f0  # root node has no incoming branch
                end
            end
        else
            nothing
        end

        root_position = is_unrooted && !isnothing(tree) ? nodepoints[tree] : nothing

        function unrooted_label_endpoint(position, branch_angle, radius)
            root_x, root_y = root_position
            relative_x = position[1] - root_x
            relative_y = position[2] - root_y
            direction_x = cos(branch_angle)
            direction_y = sin(branch_angle)
            projection = relative_x * direction_x + relative_y * direction_y

            if projection < 0.0f0
                norm = hypot(relative_x, relative_y)
                if !iszero(norm)
                    direction_x = relative_x / norm
                    direction_y = relative_y / norm
                    projection = norm
                end
            end

            perpendicular_squared =
                relative_x^2 + relative_y^2 - projection^2
            discriminant = radius^2 - max(perpendicular_squared, 0.0f0)
            if discriminant < 0.0f0
                norm = hypot(relative_x, relative_y)
                iszero(norm) && return Point2f(root_x + radius, root_y)
                scale = radius / norm
                return Point2f(
                    root_x + relative_x * scale,
                    root_y + relative_y * scale,
                )
            end

            extension = -projection + sqrt(discriminant)
            return Point2f(
                position[1] + extension * direction_x,
                position[2] + extension * direction_y,
            )
        end

        ## Lines from each tip to max tip depth
        guides_points = Point2f[]
        if !isnothing(depth)
            label_points_end = # update to max depth
                if depth === :align
                    if tf isa Polar
                        maxdepth = maximum(x -> x[2], values(nodepoints))
                        map(pos -> Point2f(pos[1], maxdepth), label_points_start)
                    elseif is_unrooted && !isnothing(branch_angles)
                        root_x, root_y = root_position
                        maxdepth = maximum(values(nodepoints)) do (x, y)
                            hypot(x - root_x, y - root_y)
                        end
                        map(unrooted_label_endpoint, label_points_start, branch_angles, Iterators.repeated(maxdepth))
                    else
                        maxdepth = maximum(x -> x[1], values(nodepoints))
                        map(pos -> Point2f(maxdepth, pos[2]), label_points_start)
                    end
                elseif depth isa Real
                    if tf isa Polar
                        map(pos -> Point2f(pos[1], depth), label_points_start)
                    elseif is_unrooted && !isnothing(branch_angles)
                        map(unrooted_label_endpoint, label_points_start, branch_angles, Iterators.repeated(Float32(depth)))
                    else
                        map(pos -> Point2f(depth, pos[2]), label_points_start)
                    end
                elseif depth isa Function
                    depth.(labeled_nodes, label_points_start)
                else
                    @error """
                    	Unrecognized option for `depth` = $depth
                    	Options are `nothing`, `:align`, `depth<:Real`, `(node, pos)->newpos::Point2f`
                    """
                end
            for (beginpos, endpos) in zip(label_points_start, label_points_end)
                push!(guides_points, beginpos)
                push!(guides_points, endpos)
                push!(guides_points, Point2f(NaN, NaN))
            end
        end

        # finalize points for labels
        label_points = !isnothing(depth) ? label_points_end : label_points_start

        # set default rotation option
        lrot = if lrotation === automatic
            if tf isa Polar
                :aligned
            elseif is_unrooted && !isnothing(branch_angles)
                :aligned
            else
                :horizontal
            end
        else
            lrotation
        end

        # Handle rotation and alignment of labels, particularly for the Polar axis
        if lrot isa Real
            rotation = lrot
        elseif lrot isa AbstractArray{<:Number}
            rotation = lrot
        elseif lrot === :horizontal
            if torientation in (:top, :bottom)
                rotation = Float32(π/2)
            else
                rotation=0.0f0
            end
        elseif lrot === :radial
            if is_unrooted && !isnothing(root_position)
                root_x, root_y = root_position
                rotation = map(label_points) do pos
                    Float32(atan(pos[2] - root_y, pos[1] - root_x))
                end
            else
                rotation = map(pos -> pos[1], label_points)
            end
        elseif lrot === :aligned
            if is_unrooted && !isnothing(branch_angles)
                # Align with branch angle, flip text on left half so it reads left-to-right
                rotation = map(branch_angles) do θ
                    cos(θ) >= 0.0 ? θ : θ + Float32(π)
                end
                lalign = map(branch_angles) do θ
                    cos(θ) >= 0.0 ? (:left, :center) : (:right, :center)
                end
            else
                rotation = map(label_points) do pos
                    cos(pos[1]) > 0.0 ? pos[1] : pos[1] + pi
                end
                lalign = map(label_points) do pos
                    cos(pos[1]) > 0.0 ? (:left, :center) : (:right, :center)
                end
            end
        else
            rotation = lrot
        end

        # Alignment of text; left-center by default unless provided or rotation=:aligned
        align = if lalign === automatic
            if torientation in (:right, :top, :out)
                (:left, :center)
            elseif torientation in (:left, :bottom, :in)
                (:right, :center)
            else
                @error "Unrecognized treeorintation=$torientation\nOptions are (:right,:left, :bottom, :top, :out, :in)"
            end
        else
            lalign
        end

        # Compute label offsets in pixel space either in polar or cartisian coordinates
        offset = if loffset === automatic
            if is_unrooted && !isnothing(branch_angles)
                map(branch_angles) do θ
                    (5.0f0 * cos(θ), 5.0f0 * sin(θ))
                end
            elseif tf isa Polar && torientation in (:right, :out)
                map((θ)->(5*cos(θ), 5*sin(θ)), first.(label_points))
            elseif tf isa Polar && torientation in (:left, :in)
                map((θ)->(-5*cos(θ), -5*sin(θ)), first.(label_points))
            elseif torientation in (:right, :out)
                (10, 0)
            elseif torientation === :top
                (0, 10)
            elseif torientation in (:left, :in)
                (-10, 0)
            elseif torientation === :bottom
                (0, -10)
            else
                (0, 0)
            end
        elseif loffset isa Tuple{<:Real,<:Real} && tf isa Polar
            toff, roff = loffset
            map(first.(label_points)) do θ
                roff .* (cos(θ+toff), sin(θ+toff))
            end
        elseif loffset isa Real
            if tf isa Polar
                map((θ)->loffset .* (cos(θ), sin(θ)), first.(label_points))
            else
                (loffset, 0)
            end
        elseif loffset isa Function
            loffset.(labeled_nodes, label_points)
        else
            loffset
        end

        return label_points, labels, align, rotation, offset, guides_points
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
treecladelabel!(tp; cladelabels=[(:a, :b) => "Node 1", tree[2] => "Node 2"])
fig
```

"""
@recipe TreeCladeLabel (nodepoints,) begin
    """
    List of nodes and associated labels for which to draw a clade label. Should be an iterable where
    each element is a pair `node => label`. Basically `[(node, label) for (node, label) in nodelabels]` should
    not error and provide each node and label you want plotted.

    if `nodelabels` is nothing, will default to `first(last(nodepoints))`, and will plot an area surrounding
    the full tree (assuming `nodepoints` has been calculated from `treeplot`).

    Nodes and their decendent nodes should have coordinates accessible via `nodepoints[node]`.
    These coordinates can be calculated with `tp = treeplot!(tree)` and accessed with `tp.nodepoints`.
    """
    cladelabels = nothing

    "Branch geometry from the parent tree plot. Forwarded automatically from `treeplot`."
    branchsegments = nothing

    "Tree root node. Forwarded automatically from `treeplot`."
    tree = nothing

    "Layout style of the parent tree plot. Forwarded automatically from `treeplot`."
    treelayoutstyle = :dendrogram

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

function _minimum_angular_span(points, center)
    angles = Float32[]
    for point in points
        dx = point[1] - center[1]
        dy = point[2] - center[2]
        iszero(dx) && iszero(dy) && continue
        push!(angles, mod(Float32(atan(dy, dx)), 2.0f0 * Float32(π)))
    end
    isempty(angles) && return (0.0f0, 0.0f0)
    length(angles) == 1 && return (only(angles), 0.0f0)

    sort!(angles)
    largest_gap, gap_index = findmax(eachindex(angles)) do index
        next_angle = index == lastindex(angles) ? first(angles) + 2.0f0 * Float32(π) : angles[index + 1]
        next_angle - angles[index]
    end
    start_index = gap_index == lastindex(angles) ? firstindex(angles) : gap_index + 1
    return (angles[start_index], 2.0f0 * Float32(π) - largest_gap)
end

function _terminal_branch_rays(nodepoints, branchsegments, tree, node)
    parent_of = Dict{Any,Any}()
    for parent_node in PreOrderDFS(tree)
        for child in children(parent_node)
            parent_of[child] = parent_node
        end
    end

    segment_by_node = if isnothing(branchsegments)
        Dict{Any,Any}()
    else
        Dict(
            full_tree_node => segment for
                (full_tree_node, segment) in zip(PreOrderDFS(tree), branchsegments)
        )
    end

    rays = Tuple{Point2f,Point2f}[]
    for leaf in Iterators.filter(BasicTreePlots.isleaf, PreOrderDFS(node))
        segment = get(segment_by_node, leaf, ())
        finite_segment = Point2f[Point2f(point) for point in segment if all(isfinite, point)]
        if length(finite_segment) >= 2
            ray_origin = finite_segment[end - 1]
            ray_tip = finite_segment[end]
        elseif haskey(parent_of, leaf)
            ray_origin = nodepoints[parent_of[leaf]]
            ray_tip = nodepoints[leaf]
        else
            continue
        end

        direction = ray_tip - ray_origin
        direction_norm = hypot(direction[1], direction[2])
        iszero(direction_norm) && continue
        push!(rays, (ray_tip, direction / direction_norm))
    end

    if isempty(rays)
        clade_center = nodepoints[node]
        tree_center = nodepoints[tree]
        direction = clade_center - tree_center
        direction_norm = hypot(direction[1], direction[2])
        unit_direction = iszero(direction_norm) ? Point2f(1, 0) : direction / direction_norm
        push!(rays, (clade_center, unit_direction))
    end
    return rays
end

function _ray_circle_intersection(ray_origin, ray_direction, center, radius)
    relative_origin = ray_origin - center
    projection = relative_origin[1] * ray_direction[1] + relative_origin[2] * ray_direction[2]
    discriminant = max(
        projection^2 + radius^2 - relative_origin[1]^2 - relative_origin[2]^2,
        0.0f0,
    )
    ray_distance = -projection + sqrt(discriminant)
    return ray_origin + ray_distance * ray_direction
end

function _unrooted_clade_label_geometry(
        points,
        rays,
        clade_center,
        lineoffset,
        linepadding,
        lineresolution,
        labelrotation,
    )
    clade_radius = maximum(points) do point
        hypot(point[1] - clade_center[1], point[2] - clade_center[2])
    end
    radius_tolerance = sqrt(eps(Float32)) * max(Float32(clade_radius), 1.0f0)
    line_radius = max(Float32(clade_radius + lineoffset), Float32(clade_radius) + radius_tolerance)
    boundary_points = Point2f[
        _ray_circle_intersection(ray_origin, ray_direction, clade_center, line_radius) for
            (ray_origin, ray_direction) in rays
    ]

    start_angle, angular_width = _minimum_angular_span(boundary_points, clade_center)
    angular_padding = Float32(linepadding / line_radius)
    start_angle -= angular_padding
    angular_width = max(angular_width + 2.0f0 * angular_padding, 0.0f0)
    stop_angle = start_angle + angular_width

    line_points = Point2f[
        clade_center + line_radius * Point2f(cos(angle), sin(angle)) for
            angle in range(start_angle, stop_angle; length = lineresolution)
    ]
    push!(line_points, Point2f(NaN, NaN))

    label_angle = start_angle + angular_width / 2.0f0
    label_position =
        clade_center + line_radius * Point2f(cos(label_angle), sin(label_angle))
    rotation = mod(
        Float32(label_angle + labelrotation) + Float32(π) / 2,
        Float32(π),
    ) - Float32(π) / 2
    return line_points, label_position, rotation
end

# I think this covers the main ways of calling the functions with a treeplot directly
_treecladelabel_kwargs(plt::TreePlot) = (;
    branchsegments = plt.branchsegments,
    tree = plt.tree,
    treelayoutstyle = plt.layoutstyle,
)
treecladelabel!(plt::TreePlot; kwargs...) =
    treecladelabel!(plt.nodepoints; _treecladelabel_kwargs(plt)..., kwargs...)
treecladelabel(plt::TreePlot; kwargs...) =
    treecladelabel(plt.nodepoints; _treecladelabel_kwargs(plt)..., kwargs...)
treecladelabel!(ax::Union{Makie.Block,Makie.GridPosition}, plt::TreePlot; kwargs...) =
    treecladelabel!(ax, plt.nodepoints; _treecladelabel_kwargs(plt)..., kwargs...)
treecladelabel(ax::Union{Makie.Block,Makie.GridPosition}, plt::TreePlot; kwargs...) =
    treecladelabel(ax, plt.nodepoints; _treecladelabel_kwargs(plt)..., kwargs...)
function Makie.plot!(plt::TreeCladeLabel)
    inputs = [
        :nodepoints,
        :branchsegments,
        :tree,
        :treelayoutstyle,
        :cladelabels,
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
    ) do nodepoints,
    branchsegments,
    tree,
    treelayoutstyle,
    cladelabels,
    lineoffset,
    linepadding,
    lineresolution,
    labelrotation,
    tf
        is_unrooted = treelayoutstyle in BasicTreePlots.UNROOTED_LAYOUTS
        if isnothing(tree)
            tree = is_unrooted ? first(keys(nodepoints)) : first(last(nodepoints))
        end

        ## Default to labeling whole tree
        cladelabels = if isnothing(cladelabels)
            [tree => BasicTreePlots.label(tree)]
        else
            cladelabels
        end

        ## repeat line offset if single number so that zip(cladelabels, lineoffset) works
        lineoffset = lineoffset isa Real ? repeat([lineoffset], length(cladelabels)) : lineoffset

        ## For each clade => cladelabel
        line_points, label_positions, labels, rotation =
            map(zip(collect(cladelabels), lineoffset)) do ((node, label), loff)
                if is_unrooted
                    points = _unrooted_clade_geometry(nodepoints, branchsegments, tree, node)
                    rays = _terminal_branch_rays(nodepoints, branchsegments, tree, node)
                    line_points, label_position, rotation =
                        _unrooted_clade_label_geometry(
                            points,
                            rays,
                            nodepoints[node],
                            loff,
                            linepadding,
                            lineresolution,
                            labelrotation,
                        )
                    return line_points, label_position, label, rotation
                end

                ## Get bounding box coordinates
                amin, amax = extrema(n -> first(nodepoints[n]), PreOrderDFS(node))
                bmin, bmax = extrema(n -> last(nodepoints[n]), PreOrderDFS(node))

                ## Extract which coordinates draw line
                depth = tf isa Polar ? bmax : amax
                widthmin, widthmax = tf isa Polar ? (amin, amax) : (bmin, bmax)

                ## Make line
                line_points = Point2f[
                    ((depth+loff, y) for
                     y ∈ range(widthmin-linepadding, widthmax+linepadding, lineresolution))...,
                    (NaN, NaN),
                ]
                line_points = tf isa Polar ? reverse.(line_points) : line_points

                ## Put label at center of line
                label_position = Point2f(depth + loff, widthmin + ((widthmax - widthmin) / 2))
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

# treehilight ====================================================================================
"""
treehilight!(nodepoints::OrderedDict(node => coordinate); nodes = [node1, node2])

# Examples

```
tree = ((:a, :b), (:c, (:d, :e)))
fig, ax, tp = treeplot(tree)
treehilight!(tp; nodes=[tree[1], (:d, :e)])
fig
```
"""
@recipe TreeHilight (nodepoints,) begin
    """
    List of nodes for which to draw surrounding regions.
    Assumes that each node and decendent node is accessible as `nodepoints[node]`. `nodepoints` can be accessed
    from `tp = treeplot(tree)` as `tp.nodepoints`.
    """
    nodes = nothing

    "Branch geometry from the parent tree plot. Forwarded automatically from `treeplot`."
    branchsegments = nothing

    "Tree root node. Forwarded automatically from `treeplot`."
    tree = nothing

    "Layout style of the parent tree plot. Forwarded automatically from `treeplot`."
    treelayoutstyle = :dendrogram

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
    "Color of stroke around shaded region."
    strokecolor = (:black, 1.0)
    "Width of stroke line around shaded region"
    strokewidth = @inherit strokewidth 0.0
    # "Style of stroke around region"
    # strokestyle = @inherit linestyle :solid
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

function _convex_hull(points)
    hull_points = unique(Point2f.(points))
    length(hull_points) <= 1 && return hull_points
    sort!(hull_points; by = point -> (point[1], point[2]))

    cross(origin, a, b) =
        (a[1] - origin[1]) * (b[2] - origin[2]) -
        (a[2] - origin[2]) * (b[1] - origin[1])

    lower = Point2f[]
    for point in hull_points
        while length(lower) >= 2 && cross(lower[end - 1], lower[end], point) <= 0
            pop!(lower)
        end
        push!(lower, point)
    end

    upper = Point2f[]
    for point in Iterators.reverse(hull_points)
        while length(upper) >= 2 && cross(upper[end - 1], upper[end], point) <= 0
            pop!(upper)
        end
        push!(upper, point)
    end

    pop!(lower)
    pop!(upper)
    return append!(lower, upper)
end

function _arc_points(center, radius, start_angle, end_angle, resolution)
    while end_angle < start_angle
        end_angle += 2.0f0 * Float32(π)
    end
    return Point2f[
        center + radius * Point2f(cos(angle), sin(angle)) for
            angle in range(start_angle, end_angle; length = max(resolution, 2) + 1)
    ]
end

function _rounded_hull(hull, padding, resolution)
    coordinate_scale = maximum(point -> max(abs(point[1]), abs(point[2])), hull; init = 1.0f0)
    radius = max(Float32(padding), sqrt(eps(Float32)) * coordinate_scale)

    if length(hull) == 1
        center = only(hull)
        angles = range(0.0f0, 2.0f0 * Float32(π); length = max(resolution, 3) + 1)
        return Point2f[
            center + radius * Point2f(cos(angle), sin(angle)) for angle in angles
        ]
    elseif length(hull) == 2
        first_point, last_point = hull
        dx = last_point[1] - first_point[1]
        dy = last_point[2] - first_point[2]
        segment_length = hypot(dx, dy)
        iszero(segment_length) && return _rounded_hull(hull[begin:begin], padding, resolution)
        segment_angle = Float32(atan(dy, dx))
        first_arc = _arc_points(
            last_point,
            radius,
            segment_angle - Float32(π) / 2,
            segment_angle + Float32(π) / 2,
            resolution,
        )
        last_arc = _arc_points(
            first_point,
            radius,
            segment_angle + Float32(π) / 2,
            segment_angle + 3.0f0 * Float32(π) / 2,
            resolution,
        )
        return append!(first_arc, last_arc)
    end

    expanded = Point2f[]
    for index in eachindex(hull)
        previous = hull[mod1(index - 1, length(hull))]
        vertex = hull[index]
        following = hull[mod1(index + 1, length(hull))]

        previous_dx = vertex[1] - previous[1]
        previous_dy = vertex[2] - previous[2]
        following_dx = following[1] - vertex[1]
        following_dy = following[2] - vertex[2]
        previous_length = hypot(previous_dx, previous_dy)
        following_length = hypot(following_dx, following_dy)
        previous_normal = Point2f(previous_dy, -previous_dx) / previous_length
        following_normal = Point2f(following_dy, -following_dx) / following_length
        start_angle = Float32(atan(previous_normal[2], previous_normal[1]))
        end_angle = Float32(atan(following_normal[2], following_normal[1]))
        append!(expanded, _arc_points(vertex, radius, start_angle, end_angle, resolution))
    end
    return expanded
end

function _unrooted_clade_geometry(nodepoints, branchsegments, tree, node)
    clade_nodes = collect(PreOrderDFS(node))
    points = Point2f[nodepoints[clade_node] for clade_node in clade_nodes]
    isnothing(branchsegments) && return points

    segment_by_node = Dict(
        full_tree_node => segment for
            (full_tree_node, segment) in zip(PreOrderDFS(tree), branchsegments)
    )
    for clade_node in Iterators.drop(clade_nodes, 1)
        for point in get(segment_by_node, clade_node, ())
            all(isfinite, point) && push!(points, Point2f(point))
        end
    end
    return points
end

# I think this covers the main ways of calling the functions with a treeplot directly
_treehilight_kwargs(plt::TreePlot) = (;
    branchsegments = plt.branchsegments,
    tree = plt.tree,
    treelayoutstyle = plt.layoutstyle,
)
treehilight!(plt::TreePlot; kwargs...) =
    treehilight!(plt.nodepoints; _treehilight_kwargs(plt)..., kwargs...)
treehilight(plt::TreePlot; kwargs...) =
    treehilight(plt.nodepoints; _treehilight_kwargs(plt)..., kwargs...)
treehilight!(ax::Union{Makie.Block, Makie.GridPosition}, plt::TreePlot; kwargs...) =
    treehilight!(ax, plt.nodepoints; _treehilight_kwargs(plt)..., kwargs...)
treehilight(ax::Union{Makie.Block, Makie.GridPosition}, plt::TreePlot; kwargs...) =
    treehilight(ax, plt.nodepoints; _treehilight_kwargs(plt)..., kwargs...)
function Makie.plot!(plt::TreeHilight)
    map!(
        plt.attributes,
        [
            :nodepoints,
            :branchsegments,
            :tree,
            :treelayoutstyle,
            :nodes,
            :resolution,
            :padding,
            :transform_func,
        ],
        [:clade_regions],
    ) do nodepoints, branchsegments, tree, treelayoutstyle, nodes, resolution, padding, tf

        # if no nodes provided use root
        is_unrooted = treelayoutstyle in BasicTreePlots.UNROOTED_LAYOUTS
        if isnothing(tree)
            tree = is_unrooted ? first(keys(nodepoints)) : first(last(nodepoints))
        end
        nodes = isnothing(nodes) ? [tree] : nodes

        # expand padding to root, leaves, leftwidth, rightwidth directions
        padding = Makie.to_lrbt_padding(padding)

        clade_regions = map(nodes) do node
            if is_unrooted
                points = _unrooted_clade_geometry(nodepoints, branchsegments, tree, node)
                hull = _convex_hull(points)
                radial_padding = maximum(padding)
                return Polygon(_rounded_hull(hull, radial_padding, resolution))
            end

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
                ((depthmin, i) for i in range(widthmin, widthmax, resolution))...,
                (depthmin, widthmax),
                (depthmax, widthmax),
                ((depthmax, i) for i in range(widthmax, widthmin, resolution))...,
                (depthmax, widthmin),
                (depthmin, widthmin),
            ]
            return tf isa Polar ? Polygon(reverse.(clade_region)) : Polygon(clade_region)
        end
        clade_regions = length(clade_regions) == 1 ? only(clade_regions) : clade_regions
        return (clade_regions,)
    end


    p = Makie.poly!(plt, plt.attributes, plt.clade_regions)
    return Makie.translate!(p, 0, 0, plt.z_shift[])
end

# # themes ======================================================================================
# # TODO: Figure out best way to expose, may need to be added directly to Makie themes.
BasicTreePlots.theme_empty() = Makie.Theme(
    Axis = (;
        topspinevisible = false,
        rightspinevisible = false,
        leftspinevisible = false,
        bottomspinevisible = false,
        xticklabelsvisible = false,
        xgridvisible = false,
        xminorgridvisible = false,
        xticksvisible = false,
        xminorticksvisible = false,
        xlabelvisible = false,
        yticklabelsvisible = false,
        ygridvisible = false,
        yminorgridvisible = false,
        yticksvisible = false,
        yminorticksvisible = false,
        ylabelvisible = false,
    ),
    Axis3 = (;
        xspinesvisible = false,
        yightspinesvisible = false,
        zspinesvisible = false,
        xticklabelsvisible = false,
        xgridvisible = false,
        xminorgridvisible = false,
        xticksvisible = false,
        xminorticksvisible = false,
        xlabelvisible = false,
        yticklabelsvisible = false,
        ygridvisible = false,
        yminorgridvisible = false,
        yticksvisible = false,
        yminorticksvisible = false,
        ylabelvisible = false,
        zticklabelsvisible = false,
        zgridvisible = false,
        zminorgridvisible = false,
        zticksvisible = false,
        zminorticksvisible = false,
        zlabelvisible = false,
    ),
    PolarAxis = (;
        spinevisible = false,
        rticklabelsvisible = false,
        rgridvisible = false,
        rminorgridvisible = false,
        thetaticklabelsvisible = false,
        thetagridvisible = false,
        thetaminorgridvisible = false,
    ),
)

end # module
