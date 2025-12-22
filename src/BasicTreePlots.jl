module BasicTreePlots

using Reexport: Reexport, @reexport
using Statistics: mean
using AbstractTrees: nodevalue, children
@reexport using AbstractTrees: PreOrderDFS
using OrderedCollections: OrderedDict
# using Makie: Point2f


const LAYOUTS = (:dendrogram, :cladogram, :radial)
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
    treehilight!



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
    ladderize!(new_t; rev)
end
function ladderize(fun, agg, t; rev = false)
    new_t = deepcopy(t)
    ladderize!(fun, agg, new_t; rev)
end
function ladderize!(t; rev = false)
    ladderize!(n->1, sum, t; rev)
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
    nodedict = OrderedDict{Any,Tuple{Float32,Float32}}()
    nodepositions!(nodedict, tree; kwargs...)
end
function nodepositions(coordtype::Type, tree; kwargs...)
    nodedict = OrderedDict{Any,coordtype}()
    nodepositions!(nodedict, tree; kwargs...)
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
    segs = Vector{Vector{Tuple{Float32,Float32}}}()
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
    res = [(k, v, label(k)) for (k, v) in nodedict if isleaf(k)]
    first.(res), getindex.(res, 2), last.(res)
end

end # module
