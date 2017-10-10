using BenchmarkTools

mutable struct Node
    id::Int
    kids::Vector{Node}
    data::Vector{Float64}
end

mutable struct FlatNode
    id::Int
    data::Vector{Float64}
end


function buildtree!(root, level, mxdepth, n_kids = 4)
    if level < mxdepth

        for i = 1:n_kids
            push!(root.kids, Node(i, Node[], rand(1000)))
        end
        for j = 1:n_kids
            buildtree!(root.kids[j], level+1, mxdepth, n_kids)
        end
    end
end


function count_nodes(mxdepth, n_kids = 4)
    n_nodes = 0
    for l = 1:mxdepth
        n_nodes += n_kids^(l - 1)
    end
    n_nodes
end


function flatnode_array(n_nodes)
    res = Vector{FlatNode}(0)
    for i = 1:n_nodes
        push!(res, FlatNode(i, rand(1000)))
    end
    return res
end


LEVEL = 6
N_KIDS = 6

xroot = Node(1, Node[], rand(1000))
n_nodes = count_nodes(LEVEL, N_KIDS)

@time buildtree!(xroot, 0, LEVEL, N_KIDS)
@time a = flatnode_array(n_nodes)

# With 4 kids, here are the MiB allcoation ratios
2.667 / 10.734
10.654 / 42.969
42.623 / 171.906
170.498 / 687.656


# With 6 kids
2.024 / 12.44
12.133 / 73.508
72.865 / 441.093
