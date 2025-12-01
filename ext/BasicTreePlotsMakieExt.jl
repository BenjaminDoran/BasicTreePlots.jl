module BasicTreePlotsMakieExt

using BasicTreePlots: BasicTreePlots
import BasicTreePlots:
    treeplot,
    treeplot!,
    treelabels,
    treelabels!,
    treescatter,
    treescatter!,
    treearea,
    treearea!,
    treecladelabel,
    treecladelabel!

using Makie
using Makie: Point2f, @recipe

using AbstractTrees: AbstractTrees
using AbstractTrees: PreOrderDFS

# treeplot ====================================================================================
@recipe TreePlot (tree,) begin
    showroot = false
    layoutstyle = :dendrogram
    branchstyle = :square
    ignorebranchlengths = false
    openangle = 0
    linevisible = true
    branch_point_resolution = 25
    usemaxdepth = false
    linecolor = @inherit color :black
    linewidth = @inherit linewidth 1.0
    linecolormap = @inherit colormap :viridis
    Makie.mixin_generic_plot_attributes()...
end

function Makie.plot!(plt::TreePlot)
    nleaves = BasicTreePlots.leafcount(plt.tree[])
    toangle(y) = (y / (nleaves)) * (2π - (plt.openangle[] % 2pi))

    ## Setup tree layout
    nodecoords = BasicTreePlots.nodepositions(
        plt.tree[];
        showroot = plt.showroot[],
        layoutstyle = plt.layoutstyle[],
    )
    maxleafposition = argmax(x -> x[1], values(nodecoords))
    segs = BasicTreePlots.makesegments(
        nodecoords,
        plt.tree[];
        resolution = plt.branch_point_resolution[],
        branchstyle = plt.branchstyle[],
    )
    # setup linecolor
    if plt.linecolor[] isa Union{AbstractVector,AbstractRange}
        length(plt.linecolor[]) == length(segs) || throw(
            ArgumentError(
                """length of linecolor ($(length(plt.linecolor[]))) must match number of branches in tree ($(length(segs)))""",
            ),
        )
        plt.linecolor[] = repeat(plt.linecolor[], inner = length(first(segs)))
    end
    # setup linewidth
    if plt.linewidth[] isa Union{AbstractVector,AbstractRange}
        length(plt.linewidth[]) == length(segs) || throw(
            ArgumentError(
                """length of linewidth ($(length(plt.linewidth[]))) must match number of branches in tree ($(length(segs)))""",
            ),
        )
        plt.linewidth[] = repeat(plt.linewidth[], inner = length(first(segs)))
    end

    # modify all points if axis is polar
    if occursin("Polar", string(plt.transformation.transform_func[]))
        segs = map(segs) do seg
            [(toangle(y), x) for (x, y) in seg]
        end
    end

    Makie.lines!(
        plt,
        reduce(vcat, segs);
        color = plt.linecolor,
        linewidth = plt.linewidth,
        Makie.shared_attributes(plt, Makie.Lines)...,
    )
end

# treelabels ==================================================================================
@recipe TreeLabels (tree, tipannotations) begin
    showroot = false
    layoutstyle = :dendrogram
    branchstyle = :square
    openangle = 0
    branch_point_resolution = 25
    usemaxdepth = false
    tiplabelfontsize = 9.0f0
    tiplabelalign = @inherit align (:left, :center)
    tiplabeloffset = @inherit offset (1.0f0, 0.0f0)
    # clip_planes = @inherit clip_planes Plane3f[]
    Makie.mixin_generic_plot_attributes()...
end

function Makie.plot!(plt::TreeLabels)
    nleaves = BasicTreePlots.leafcount(plt.tree[])
    toangle(y) = (y / (nleaves)) * (2π - (plt.openangle[] % 2pi))

    ## Setup tree layout
    nodecoords = BasicTreePlots.nodepositions(
        plt.tree[];
        showroot = plt.showroot[],
        layoutstyle = plt.layoutstyle[],
    )
    maxleafposition = argmax(x -> x[1], values(nodecoords))

    ## Get all tip positions and labels
    if isnothing(plt.tipannotations[])
        tippositions_start, tiplabels = BasicTreePlots.tipannotations(nodecoords)
    else
        tiplabels = []
        tippositions_start = Tuple{Float32,Float32}[]
        for (nodeid, label) in plt.tipannotations[]
            push!(tiplabels, label)
            push!(tippositions_start, nodecoords[nodeid])
        end
    end

    ## Lines from each tip to max tip depth
    if plt.usemaxdepth[]
        tippositions_end = Point2f[]
        for pos in tippositions_start
            push!(
                tippositions_end,
                (maxleafposition[1] + 0.01 * maxleafposition[1], pos[2]),
            )
        end

        linestomaxdepth = Point2f[]
        for (beginpos, endpos) in zip(tippositions_start, tippositions_end)
            push!(linestomaxdepth, beginpos)
            push!(linestomaxdepth, endpos)
            push!(linestomaxdepth, Point2f(NaN, NaN))
        end

        if occursin("Polar", string(plt.transformation.transform_func[]))
            linestomaxdepth = map(linestomaxdepth) do pos
                Point2f(toangle(pos[2]), pos[1])
            end
        end

        Makie.lines!(
            plt,
            linestomaxdepth;
            color = (:gray, 0.5),
            linestyle = :dash,
            linewidth = 0.5,
        )
    end

    ## Handle tip annotations
    tippositions = plt.usemaxdepth[] ? tippositions_end : tippositions_start
    tiprotations = zeros(length(tiplabels))
    if occursin("Polar", string(plt.transformation.transform_func[]))
        tiprotations = map(tippositions) do pos
            toangle(pos[2])
        end
        tippositions = map(tippositions) do pos
            xoff, yoff = plt.tiplabeloffset[] ./ 10
            Point2f(toangle(pos[2] + yoff), pos[1] + xoff)
        end
    end

    Makie.text!(
        plt,
        tippositions;
        text = tiplabels,
        fontsize = plt.tiplabelfontsize,
        align = plt.tiplabelalign,
        offset = plt.tiplabeloffset,
        rotation = tiprotations,
        Makie.shared_attributes(plt, Makie.Text)...,
    )
end


# # treescatter =================================================================================
# TODO: add argument that maps value to colormap or size
@recipe TreeScatter (tree,) begin
    showroot = false
    layoutstyle = :dendrogram
    openangle = 0
    nodeordering = AbstractTrees.PreOrderDFS
    alpha = @inherit alpha 1.0
    marker = @inherit marker :circle
    markercolor = @inherit color :black
    markersize = @inherit markersize 5
    colormap = @inherit colormap :viridis
    Makie.mixin_generic_plot_attributes()...
end

function Makie.plot!(plt::TreeScatter)
    nleaves = BasicTreePlots.leafcount(plt.tree[])
    toangle(y) = (y / (nleaves)) * (2π - (plt.openangle[] % 2pi))

    ## Setup tree layout
    nodecoords = BasicTreePlots.nodepositions(
        plt.tree[];
        showroot = plt.showroot[],
        layoutstyle = plt.layoutstyle[],
    )

    ## Transform coordinate if plotting in Polar Axis
    if occursin("Polar", string(plt.transformation.transform_func[]))
        nodecoords = Dict(node => (toangle(y), x) for (node, (x, y)) in nodecoords)
    end

    ## Add markers in nodes
    Makie.scatter!(
        plt,
        [nodecoords[node] for node in plt.nodeordering[](plt.tree[])],
        alpha = plt.alpha[],
        marker = plt.marker[],
        markersize = plt.markersize[],
        color = plt.markercolor[],
        colormap = plt.colormap[];
    )
end


# # treecladelabel ==============================================================================
@recipe TreeCladeLabel (tree,) begin
    node = nothing
    label = nothing
    linepadding = 0.1
    lineoffset = 0.5
    linestyle = @inherit linestyle :solid
    linewidth = @inherit linewidth 1
    labelalign = @inherit align (:left, :center)
    # labelrotation = @inherit rotation 0.0
    labeloffset = @inherit offset (5.0f0, 0.0f0)
    showroot = false
    layoutstyle = :dendrogram
    openangle = 0
    resolution = 25
    alpha = @inherit alpha 1.0
    color = @inherit color :black
    font = @inherit font :regular
    rotation = @inherit rotation 0.0
    align = @inherit align (:left, :center)
    Makie.mixin_generic_plot_attributes()...
end

function Makie.plot!(plt::TreeCladeLabel)
    nleaves = BasicTreePlots.leafcount(plt.tree[])
    toangle(y) = (y / (nleaves)) * (2π - (plt.openangle[] % 2pi))

    ## Setup tree layout
    nodecoords = BasicTreePlots.nodepositions(
        plt.tree[];
        showroot = plt.showroot[],
        layoutstyle = plt.layoutstyle[],
    )

    ## Default to labeling whole tree using tiplabels
    plt.node[] = isnothing(plt.node[]) ? plt.tree[] : plt.node[]
    plt.label[] = isnothing(plt.label[]) ? repr(plt.node[]) : plt.label[]

    ## Get coordinates
    x = first(nodecoords[argmax(n -> first(nodecoords[n]), PreOrderDFS(plt.node[]))])
    ymin = last(nodecoords[argmin(n -> last(nodecoords[n]), PreOrderDFS(plt.node[]))])
    ymax = last(nodecoords[argmax(n -> last(nodecoords[n]), PreOrderDFS(plt.node[]))])

    linecoordinates = [
        (x + plt.lineoffset[], ymin - plt.linepadding[]),
        [
            (x + plt.lineoffset[], y) for y in range(
                ymin - plt.linepadding[],
                ymax + plt.linepadding[],
                length = plt.resolution[],
            )
        ]...,
        (x + plt.lineoffset[], ymax + plt.linepadding[]),
        (NaN, NaN),
    ]
    labelposition = (x + plt.lineoffset[], ymin + ((ymax - ymin) / 2))

    ## Transform coordinate if plotting in Polar Axis
    if occursin("Polar", string(plt.transformation.transform_func[]))
        linecoordinates = map(linecoordinates) do xy
            (toangle(xy[2]), xy[1])
        end
        labelposition = (toangle(labelposition[2]), labelposition[1])
        plt.rotation[] = labelposition[1] + plt.rotation[]
    end

    Makie.lines!(
        plt,
        linecoordinates,
        color = (plt.color[], plt.alpha[]),
        linewidth = plt.linewidth,
        linestyle = plt.linestyle,
    )

    Makie.text!(
        plt,
        labelposition;
        text = plt.label,
        offset = plt.labeloffset,
        align = plt.labelalign,
        color = (plt.color[], plt.alpha[]),
        Makie.shared_attributes(plt, Makie.Text)...,
    )
end

# # treearea ====================================================================================
@recipe TreeArea (tree,) begin
    node = nothing
    # Tree
    showroot = false
    layoutstyle = :dendrogram
    openangle = 0
    # Fill
    alpha = @inherit alpha 1.0
    color = @inherit color :transparent
    padding = ((0.1f0, 0.1f0), (0.1f0, 0.1f0))
    resolution = 25
    # Stroke
    addstroke = false
    strokestyle = @inherit linestyle :solid
    strokecolor = @inherit color (:black, 1.0)
    strokewidth = @inherit linewidth 1.0
    Makie.mixin_generic_plot_attributes()...
end

function Makie.plot!(plt::TreeArea)
    nleaves = BasicTreePlots.leafcount(plt.tree[])
    toangle(y) = (y / (nleaves)) * (2π - (plt.openangle[] % 2pi))

    ## Setup tree layout
    nodecoords = BasicTreePlots.nodepositions(
        plt.tree[];
        showroot = plt.showroot[],
        layoutstyle = plt.layoutstyle[],
    )

    ## Default to adding area to whole tree
    if isnothing(plt.node[])
        plt.node[] = plt.tree[]
    end
    ## Ensure alpha is applied
    if plt.color[] isa Tuple{Any,AbstractFloat}
        plt.color[], plt.alpha[] = (plt.color[][1], plt.color[][2] * plt.alpha[])
    end

    # Get bounding box coordinates
    # FIX: instead of getting list of nodes to traverse, directly extract coordinates to
    # simplify the calculation of extrema values
    allnodes = PreOrderDFS(plt.node[])
    xmin =
        first(nodecoords[argmin(n -> first(nodecoords[n]), allnodes)]) - plt.padding[][1][1]
    xmax =
        first(nodecoords[argmax(n -> first(nodecoords[n]), allnodes)]) + plt.padding[][1][2]
    ymin =
        last(nodecoords[argmin(n -> last(nodecoords[n]), allnodes)]) - plt.padding[][2][1]
    ymax =
        last(nodecoords[argmax(n -> last(nodecoords[n]), allnodes)]) + plt.padding[][2][2]

    clade_region = Point2f[
        (xmin, ymin),
        ((xmin, i) for i in range(ymin, ymax, length = plt.resolution[]))...,
        (xmin, ymax),
        (xmax, ymax),
        ((xmax, i) for i in range(ymax, ymin, length = plt.resolution[]))...,
        (xmax, ymin),
    ]

    ## Transform coordinate if plotting in Polar Axis
    if occursin("Polar", string(plt.transformation.transform_func[]))
        clade_region = Point2f[(toangle(y), x) for (x, y) in clade_region]
    end

    # FIX: Do this in a more intelligent way
    if plt.addstroke[]
        Makie.poly!(
            plt,
            clade_region,
            color = (plt.color[], plt.alpha[]),
            linestyle = plt.strokestyle[],
            strokecolor = plt.strokecolor[],
            strokewidth = plt.strokewidth[],
        )
    else
        Makie.poly!(plt, clade_region, color = (plt.color[], plt.alpha[]))
    end
end



# # themes ======================================================================================
# # TODO: Will this be exposed eventually?
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

end
