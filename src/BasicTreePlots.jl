module BasicTreePlots

using Reexport: Reexport, @reexport
using Statistics: mean
using AbstractTrees: nodevalue, children, treebreadth
@reexport using AbstractTrees: PreOrderDFS
using OrderedCollections: OrderedDict
# using Makie: Point2f


const LAYOUTS = (
    :dendrogram,
    :cladogram,
    :radial,
    :unrooted_dendrogram,
    :unrooted_cladogram,
    :daylight_dendrogram,
    :daylight_cladogram,
)
const UNROOTED_LAYOUTS = (
    :unrooted_dendrogram,
    :unrooted_cladogram,
    :daylight_dendrogram,
    :daylight_cladogram,
)
const BRANCHTYPES = (:square, :straight)

export treeplot,
    treeplot!,
    treescatter,
    treescatter!,
    treelabels,
    treelabels!,
    treecladelabel,
    treecladelabel!,
    treehilight,
    treehilight!,
    theme_empty


# Documentation for plotting functions are in extensions
function treeplot end
function treeplot! end

function treescatter end
function treescatter! end


function treelabels end
function treelabels! end


function treecladelabel end
function treecladelabel! end


function treehilight end
function treehilight! end

function theme_empty end
# public distance, label

"""
    distance(node)

return scaler distance from node to parent of node. Defaults to `1`

To extend `treeplot` to your type define method for `BasicTreePlots.distance(node::YourNodeType)`
"""
distance() = 1.0f0
distance(node) = 1.0f0

"""
    label(node)

return string typed value or description of node.

Defaults to `string(nodevalue(node))`

To extend `treeplot` to your type define method for `BasicTreePlots.label(node::YourNodeType)`
"""
label(n) = string(nodevalue(n))

isleaf(n) = (isempty ∘ children)(n)

leafcount(t) = mapreduce(isleaf, +, PreOrderDFS(t))


"""
    ladderize!([fun::Function, agg::Function,] tree; rev=false)
    ladderize([fun::Function, agg::Function,] tree; rev=false)

Perform inplace sorting 'ladderization' of the children of each node in the provided tree
based on user provided scaler functions `fun` and aggregating function `agg`. `ladderize`
(without the exlamation point) performs a `deepcopy` of the tree before sorting the tree

Calling `ladderize` with no funtion arguments is equivalent to calling `ladderize!(n->1, sum, t; rev)` which
will sort the tree by the node's count of descendents.

# Args:
* `fun::Function`: function that takes leaves of the tree and outputs scaler value
* `agg::Function`: aggregating function, takes collection of outputs from `fun` and returns scaler output
* `tree`: tree object that fulfills `AbstractTrees` interface. `AbstractTrees.children(node)`
    should provide sortable collection children of the node.
* `rev::Bool=false`: whether to sort children of each node in acending (default) or desending order.

# Examples

```
ladderize!(tree)
```

```
tree = ladderize(tree)
```

```
ladderize!(mean, tree) do leaf
    leafdata_dict[name(leaf)]["fitness"]
end
```
"""
function ladderize(t; rev = false)
    new_t = deepcopy(t)
    return ladderize!(new_t; rev)
end
function ladderize(fun, agg, t; rev = false)
    new_t = deepcopy(t)
    return ladderize!(fun, agg, new_t; rev)
end
function ladderize!(t; rev = false)
    return ladderize!(n -> 1, sum, t; rev)
end
function ladderize!(fun::Function, agg::Function, t; rev = false)
    function walk!(n)
        if isleaf(n)
            return fun(n)
        else
            node_children = children(n)
            child_results = [walk!(c) for c in node_children]
            node_children .= node_children[sortperm(child_results; rev)]
            return agg(child_results)
        end
    end
    walk!(t)
    return t
end


function nodepositions(tree; kwargs...)
    nodedict = OrderedDict{Any, Tuple{Float32, Float32}}()
    return nodepositions!(nodedict, tree; kwargs...)
end
function nodepositions(coordtype::Type, tree; kwargs...)
    nodedict = OrderedDict{Any, coordtype}()
    return nodepositions!(nodedict, tree; kwargs...)
end
function nodepositions!(
        nodedict,
        tree;
        showroot = false,
        layoutstyle = :dendrogram,
        nodeoffset = 0.0f0,
    )
    currdepth = showroot ? distance(tree) : 0.0f0
    leafcount = [0.0f0 + nodeoffset]
    if layoutstyle == :dendrogram
        coord_positions_dendrogram!(nodedict, tree, currdepth, leafcount)
    elseif layoutstyle == :cladogram
        coord_positions_cladogram!(nodedict, tree, currdepth, leafcount)
    elseif layoutstyle == :unrooted_dendrogram
        coord_positions_unrooted!(nodedict, tree; cladogram = false)
    elseif layoutstyle == :unrooted_cladogram
        coord_positions_unrooted!(nodedict, tree; cladogram = true)
    elseif layoutstyle == :daylight_dendrogram
        coord_positions_daylight!(nodedict, tree; cladogram = false)
    elseif layoutstyle == :daylight_cladogram
        coord_positions_daylight!(nodedict, tree; cladogram = true)
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


function coord_positions_unrooted!(nodedict, tree; cladogram::Bool = false)
    function recurse!(node, px, py, θ_min, θ_max)
        nodedict[node] = (px, py)
        isleaf(node) && return
        total = treebreadth(node)
        θ_cursor = θ_min
        for child in children(node)
            nleaves = treebreadth(child)
            Δθ = (nleaves / total) * (θ_max - θ_min)
            θ_mid = θ_cursor + Δθ / 2
            ℓ = cladogram ? 1.0f0 : Float32(distance(child))
            cx = px + ℓ * cos(θ_mid)
            cy = py + ℓ * sin(θ_mid)
            recurse!(child, cx, cy, θ_cursor, θ_cursor + Δθ)
            θ_cursor += Δθ
        end
        return
    end
    recurse!(tree, 0.0f0, 0.0f0, 0.0f0, 2.0f0 * Float32(π))
    return nodedict
end


function coord_positions_daylight!(
    nodedict,
    tree;
    cladogram::Bool = false,
    max_iterations::Int = 5,
    tolerance::Float32 = 0.05f0 * Float32(π),
)
    coord_positions_unrooted!(nodedict, tree; cladogram)
    adjust_daylight!(nodedict, tree; max_iterations, tolerance)
    return nodedict
end


function adjust_daylight!(
    nodedict,
    tree;
    max_iterations::Int = 5,
    tolerance::Float32 = 0.05f0 * Float32(π),
)
    all_nodes = collect(PreOrderDFS(tree))
    internal_nodes = Any[]
    queue = Any[tree]
    cursor = 1
    while cursor <= length(queue)
        node = queue[cursor]
        cursor += 1
        node_children = collect(children(node))
        if !isempty(node_children)
            push!(internal_nodes, node)
            append!(queue, node_children)
        end
    end

    components = Dict{Any,Vector{Vector{Any}}}()
    all_nodes_set = Set(all_nodes)
    for node in internal_nodes
        node_components = Vector{Vector{Any}}()
        covered = Set{Any}([node])
        for child in children(node)
            component = Any[PreOrderDFS(child)...]
            push!(node_components, component)
            union!(covered, component)
        end
        if node != tree
            parent_component = Any[n for n in all_nodes_set if n ∉ covered]
            !isempty(parent_component) && push!(node_components, parent_component)
        end
        components[node] = node_components
    end

    for _ in 1:max_iterations
        total_change = 0.0f0
        changed_nodes = 0
        for node in internal_nodes
            node_components = components[node]
            length(node_components) <= 2 && continue
            arcs = map(node_components) do component
                daylight_arc(nodedict, node, component)
            end
            order = sortperm(first.(arcs))
            widths = last.(arcs)
            daylight = (2.0f0 * Float32(π) - sum(widths)) / length(arcs)
            desired_start = first(arcs[order[begin]])
            max_change = 0.0f0
            for order_index in 2:length(order)
                previous = order[order_index - 1]
                current = order[order_index]
                desired_start += widths[previous] + daylight
                raw_adjustment = desired_start - first(arcs[current])
                adjustment = mod(
                    raw_adjustment + Float32(π), 2.0f0 * Float32(π)
                ) - Float32(π)
                rotate_component!(nodedict, node, node_components[current], adjustment)
                max_change = max(max_change, abs(adjustment))
            end
            total_change += max_change
            changed_nodes += 1
        end
        changed_nodes == 0 && break
        total_change / changed_nodes <= tolerance && break
    end

    root_x, root_y = nodedict[tree]
    for node in all_nodes
        x, y = nodedict[node]
        nodedict[node] = (Float32(x - root_x), Float32(y - root_y))
    end
    return nodedict
end


function daylight_arc(nodedict, origin, component)
    ox, oy = nodedict[origin]
    angles = Float32[]
    for node in component
        x, y = nodedict[node]
        dx = Float32(x - ox)
        dy = Float32(y - oy)
        iszero(dx) && iszero(dy) && continue
        push!(angles, mod(Float32(atan(dy, dx)), 2.0f0 * Float32(π)))
    end
    isempty(angles) && return (0.0f0, 0.0f0)
    length(angles) == 1 && return (only(angles), 0.0f0)

    sort!(angles)
    largest_gap = -1.0f0
    gap_index = 0
    for i in eachindex(angles)
        next_angle = i == lastindex(angles) ? first(angles) + 2.0f0 * Float32(π) : angles[i + 1]
        gap = next_angle - angles[i]
        if gap > largest_gap
            largest_gap = gap
            gap_index = i
        end
    end
    start_index = gap_index == lastindex(angles) ? firstindex(angles) : gap_index + 1
    start_angle = angles[start_index]
    width = 2.0f0 * Float32(π) - largest_gap
    return (start_angle, width)
end


function rotate_component!(nodedict, pivot, component, angle)
    px, py = nodedict[pivot]
    sine, cosine = sincos(angle)
    for node in component
        x, y = nodedict[node]
        dx = x - px
        dy = y - py
        nodedict[node] = (
            Float32(cosine * dx - sine * dy + px),
            Float32(sine * dx + cosine * dy + py),
        )
    end
    return nodedict
end


function extend_tips!(nodecoords)
    maxleafposition = argmax(x -> x[1], values(nodecoords))
    for (k, v) in nodecoords
        if isleaf(k)
            nodecoords[k] = (maxleafposition[1], v[2])
        end
    end
    return
end


function makesegments(nodedict, tree; resolution = 25, branchstyle = :square, layoutstyle = :dendrogram)
    segs = Vector{Vector{Tuple{Float32, Float32}}}()
    if layoutstyle in UNROOTED_LAYOUTS
        make_unrooted_segments!(segs, nodedict, tree)
    elseif branchstyle == :square
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

        return if !isleaf(node)
            for c in children(node)
                segment_prewalk!(segs, c, node)
            end
        end
    end
    segment_prewalk!(segs, tree, tree)
    return segs
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

        return if !isleaf(node)
            for c in children(node)
                segment_prewalk!(segs, c, node)
            end
        end
    end
    segment_prewalk!(segs, tree, tree)
    return segs
end


function make_unrooted_segments!(segs, nodedict, tree)
    root_x, root_y = nodedict[tree]
    push!(segs, [(root_x, root_y), (root_x, root_y), (NaN32, NaN32)])

    function segment_prewalk!(node)
        return if !isleaf(node)
            px, py = nodedict[node]
            for c in children(node)
                cx, cy = nodedict[c]
                push!(segs, [(px, py), (cx, cy), (NaN32, NaN32)])
                segment_prewalk!(c)
            end
        end
    end
    segment_prewalk!(tree)
    return segs
end


function tipannotations(nodedict)
    res = [(k, v, label(k)) for (k, v) in nodedict if isleaf(k)]
    return first.(res), getindex.(res, 2), last.(res)
end

polaroffset(pos, off) = off[2] .* (cos(pos[1] + off[1]), sin(pos[1] + off[1]))

end # module
