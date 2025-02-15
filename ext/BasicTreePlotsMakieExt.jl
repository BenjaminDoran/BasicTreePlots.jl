module BasicTreePlotsMakieExt

import BasicTreePlots
import BasicTreePlots: treeplot, treeplot!, treescatter, treescatter!

import Makie
import Makie: Point2f

Makie.@recipe(TreePlot, tree) do scene
    attr = Makie.Attributes(
        showroot = false,
        layoutstyle = :dendrogram,
        branchstyle = :square,
        ignorebranchlengths = false,
        linevisible = true,
        linecolor = @something(Makie.theme(scene, :color), :black),
        linewidth = @something(Makie.theme(scene, :linewidth), 1),
        linecolormap = @something(Makie.theme(scene, :colormap), :viridis),
        branch_point_resolution = 25,
        usemaxdepth = false,
        tipannotationsvisible = true,
        tipannotations = nothing,
        tipfontsize = 9.0f0,
        leafdata = nothing,
        openangle = 0,
        tipalign = @something(Makie.theme(scene, :align), (:left, :center)),
        tipannotationoffset = @something(Makie.theme(scene, :offset), (3.0f0, 0.0f0)),
    )
    Makie.MakieCore.generic_plot_attributes!(attr)
    return Makie.MakieCore.colormap_attributes!(attr, Makie.theme(scene, :colormap))
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

    ## Get all tip positions and labels
    tippositions_start, tiplabels = BasicTreePlots.tipannotations(nodecoords)

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

        Makie.lines!(plt, linestomaxdepth; color = (:grey, 0.1), linewidth = 0.5)
    end


    ## Handle tip annotations
    if plt.tipannotationsvisible[]
        tippositions = plt.usemaxdepth[] ? tippositions_end : tippositions_start
        tiprotations = zeros(length(tiplabels))
        if occursin("Polar", string(plt.transformation.transform_func[]))

            tiprotations = map(tippositions) do pos
                toangle(pos[2])
            end

            tippositions = map(tippositions) do pos
                Point2f(toangle(pos[2]), pos[1])
            end
            plt.tipannotationoffset[] = (0.0f0, 0.0f0)
        end

        Makie.text!(
            tippositions;
            text = tiplabels,
            fontsize = plt.tipfontsize,
            align = plt.tipalign,
            offset = plt.tipannotationoffset,
            rotation = tiprotations,
            Makie.shared_attributes(plt, Makie.Text)...,
        )
    end
end

Makie.@recipe(TreeScatter, tree) do scene
    attr = Makie.Attributes(
        alpha = @something(Makie.theme(scene, :alpha), 1.0),
        showroot = false,
        layoutstyle = :dendrogram,
        marker = @something(Makie.theme(scene, :marker), :circle),
        markercolor = @something(Makie.theme(scene, :color), :black),
        markersize = @something(Makie.theme(scene, :markersize), 5),
        openangle = 0,
    )
    Makie.MakieCore.generic_plot_attributes!(attr)
    return Makie.MakieCore.colormap_attributes!(attr, Makie.theme(scene, :colormap))
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
    return Makie.scatter!(
        plt,
        collect(values(nodecoords)),
        alpha = plt.alpha[],
        marker = plt.marker[],
        markersize = plt.markersize[],
        color = plt.markercolor[],
        colormap = plt.colormap[],
    )
end

theme_empty() = Makie.Theme(
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

end
