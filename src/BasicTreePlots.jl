module BasicTreePlots

using Reexport: Reexport
using Statistics: mean
using AbstractTrees: nodevalue, children, PreOrderDFS
# using Makie: Point2f

const LAYOUTS = (:dendrogram, :cladogram, :radial)
const BRANCHTYPES = (:square, :straight)

export treeplot, treeplot!

"""
    treeplot(tree; kwargs...)

# Args:

- tree, the root node of a tree that has `AbstractTrees.children()` defined.
    All nodes should be reachable by using `AbstractTrees.PreOrderDFS()` iterator.

# Keyword arguments:

- `showroot::Bool = false`, if `BasicTreePlots.distance()` is not `nan` for root, show line linking root to parent.

- `layoutstyle::Symbol = :dendrogram` available options are `:dendrogram`, or `:cladogram`
    -  `:dendrogram` displays tree taking into account the distance between parent and children nodes as calculated from `BasicTreePlots.distance(node)`.
        If the distance is not defined, it defaults to `1` and is equivalent to the `:cladogram` layout
    - `:cladogram` displays the tree where each distance from a child node to their parent is set to `1`.

- `branchstyle::Symbol = :square` available options are `:square` or `:straight`
    - `:square` will display line from child to parent as going back to the height of the parent,
        before connecting back to the parent node at a right angle.
    -  `straight` will display line from child to parent as a straight line from child to parent.

- `linecolor = :black`, should match the `color` option in Makie's `lines` plot.
    Can be either a single color `:black`, color plus alpha transperency `(:black, 0.5)`, or a vector of numbers for each node in pre-walk order.
    color for each node is associated to the line connecting it to its parent.

- `linewidth = 1`, should match the `linewidth` option in Makie's `lines` plot.
    Can be either a single width or a vector of numbers for each node in pre-walk order.
    width for each node is associated to the line connecting it to its parent.

- `linecolormap=:viridis`  color map associated to `linecolor`. can be symbel of known colormap or gradient created from `cgrad()`.
    see [Makie's color documentation](https://docs.makie.org/v0.21/explanations/colors)

- `branch_point_resolution = 25`, number of points associated to each line segment.
    Can be decreased to increase plotting speed.
    Or, increased if lines that should be smooth are not.

- `usemaxdepth = false`, if `true` draw guide lines from each leaf tip to the depth of the leaf that is maximally distant from root.
    Useful for connecting leaves to there location on the y axis (or θ axis if plotted on `PolarAxis`).

- `tipannotationsvisible::Bool = true`, whether to show text labels for each leaf tip.

- `tipfontsize = 9.0f0`, font size that tip labels are displayed at.

- `openangle = 0`, Angle in radians that limits span of tree around the circle when plotted on `PolarAxis`.
    if `openangle = deg2rad(5)` then leaf tips will spread across angles `0` to `(2π - openangle)`.

- `tipalign = (:left, :center)` text alignment of tip labels.
    see [Makie options](https://docs.makie.org/v0.21/reference/plots/text#alignment)

- `tipannotationoffset = (3.0f0, 0.0f0)` offset of tip label from actual tip position.
    The first value is associated with the `x` axis, and the second is associated with the `y` axis.
    (Currently, only available for cartisian axis)

"""
function treeplot end
function treeplot! end

# public distance, label

"""
    distance(node)

return scaler distance from node to parent of node. Defaults to `1`

To extend `treeplot` to your type define method for `BasicTreePlots.distance(node::YourNodeType)`
"""
distance() = 1
distance(node) = 1

"""
    label(node)

return string typed value or description of node.

Defaults to `string(nodevalue(node))`

To extend `treeplot` to your type define method for `BasicTreePlots.label(node::YourNodeType)`
"""
label(n) = string(nodevalue(n))

isleaf(n) = (isempty ∘ children)(n)
leafcount(t) = mapreduce(isleaf, +, PreOrderDFS(t))

function nodepositions(tree; showroot = false, layoutstyle = :dendrogram)
    nodedict = Dict{Any,Tuple{Float64,Float64}}()
    currdepth = showroot ? distance(tree) : 0.0
    leafcount = [-1]
    if layoutstyle == :dendrogram
        coord_positions_dendrogram!(nodedict, tree, currdepth, leafcount)
    elseif layoutstyle == :cladogram
        coord_positions_cladogram!(nodedict, tree, currdepth, leafcount)
    else
        throw(ArgumentError("""layoutstyle $layoutstyle not in $LAYOUTS"""))
    end
    return nodedict
end

function coord_positions_dendrogram!(nodedict, node, curr_depth, leafcount)
    if isleaf(node)
        leafcount[begin] += 1
        return nodedict[node] = (curr_depth, only(leafcount))
    end
    childs = map(children(node)) do child
        coord_positions_dendrogram!(nodedict, child, curr_depth + distance(child), leafcount)
    end
    height = mean(last.(childs))
    return nodedict[node] = (curr_depth, height)
end

function coord_positions_cladogram!(nodedict, node, curr_depth, leafcount)
    if isleaf(node)
        leafcount[begin] += 1
        return nodedict[node] = (curr_depth, only(leafcount))
    end
    childs = map(children(node)) do child
        coord_positions_cladogram!(nodedict, child, curr_depth + distance(), leafcount)
    end
    height = mean(last.(childs))
    return nodedict[node] = (curr_depth, height)
end

function extend_tips!(nodecoords)
    maxleafposition = argmax(x -> x[1], values(nodecoords))
    for (k, v) in nodecoords
        if isleaf(k)
            nodecoords[k] = (maxleafposition[1], v[2])
        end
    end
end

function makesegments(nodedict, tree; resolution = 25, branchstyle = :square)
    segs = Vector{Vector{Tuple{Float64,Float64}}}()
    if branchstyle == :square
        make_square_segments!(segs, nodedict, tree; resolution)
    elseif branchstyle == :straight
        make_straight_segments!(segs, nodedict, tree)
    else
        throw(ArgumentError("""branchstyle $branchstyle not in $BRANCHTYPES"""))
    end
    return segs
end

function make_square_segments!(segs, nodedict, tree; resolution = 25)
    function segment_prewalk!(segs, node, parent_node)
        px, py = nodedict[parent_node]
        cx, cy = nodedict[node]

        if node == parent_node # isroot
            push!(
                segs,
                [
                    (0.0, py),
                    [(tx, cy) for tx in range(0.0, cx, length = resolution)]...,
                    (cx, cy),
                    (NaN, NaN),
                ],
            )
        else
            push!(
                segs,
                [
                    (px, py),
                    [(px, ty) for ty in range(py, cy, length = resolution)]...,
                    (cx, cy),
                    (NaN, NaN),
                ],
            )
        end

        if !isleaf(node)
            for c in children(node)
                segment_prewalk!(segs, c, node)
            end
        end
    end
    segment_prewalk!(segs, tree, tree)
    segs
end


function make_straight_segments!(segs, nodedict, tree)
    function segment_prewalk!(segs, node, parent_node)
        px, py = nodedict[parent_node]
        cx, cy = nodedict[node]

        if node == parent_node # isroot
            push!(segs, [(0.0, py), (cx, cy), (NaN, NaN)])
        else
            push!(segs, [(px, py), (cx, cy), (NaN, NaN)])
        end

        if !isleaf(node)
            for c in children(node)
                segment_prewalk!(segs, c, node)
            end
        end
    end
    segment_prewalk!(segs, tree, tree)
    segs
end

function tipannotations(nodedict)
    tipnames = String[]
    tippositions = Tuple{Float32,Float32}[]
    for (k, v) in nodedict
        isleaf(k) || continue
        push!(tipnames, (label(k)))
        push!(tippositions, v)
    end
    tippositions, tipnames
end

# include("./MakieRecipe.jl")
# @reexport using .MakieRecipe: treeplot, treeplot!
# using .MakieRecipe: theme_empty

end # module
