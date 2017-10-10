SUPP_COUNT = Dict{Array{Int16, 1}, Int}


struct Node
    item_ids::Array{Int16, 1}
    transactions::BitArray{1}
    children::Array{Int, 1}
    mother::Int
    supp::Int
end

# Strictly for the root nodes
function Node(item_ids::Array{Int16, 1}, transactions::BitArray{1})
    children = Array{Node, 1}(0)
    nd = Node(item_ids, transactions, children)
    return nd
end


function Node(item_ids::Array{Int16, 1}, transactions::BitArray{1}, mother::Int, supp::Int)
    children = Array{Node, 1}(0)
    nd = Node(item_ids, transactions, children, mother, supp)
    return nd
end


function older_siblings(nd::Node, node_arr, node_idx)
    n_sibs = length(node_arr[nd.mother].children)
    are_older = falses(n_sibs)
    for i = 1:n_sibs
        are_older[i] = node_arr[nd.mother].children[i] > node_idx
    end
    return view(node_arr[nd.mother].children, are_older)
end


# This function is used internally and is the workhorse of the frequent()
# function, which generates a frequent itemset tree. The growtree!() function
# builds up the frequent itemset tree recursively.
function growtree!(nd::Node, minsupp, k, maxdepth, node_idx, node_arr)
    n_nodes = length(node_arr)
    sibs = older_siblings(nd, node_arr, node_idx)     # sibs is vector of indices

    for j = 1:length(sibs)
        transacts = nd.transactions .& node_arr[sibs[j]].transactions
        supp = sum(transacts)

        if supp ≥ minsupp
            items = zeros(Int16, k)
            items[1:k-1] = node_arr[node_idx].item_ids[1:k-1]
            items[end] = node_arr[sibs[j]].item_ids[end]

            child = Node(items, transacts, node_idx, supp)
            n_nodes += 1
            push!(node_arr, child)          # add child node to master node array
            push!(nd.children, n_nodes)     # n_nodes is the child's node index
        end
    end
    # Recurse on newly created children
    maxdepth -= 1
    if maxdepth > 1
        for child_idx in nd.children
            # println("running child_idx: ", child_idx.item_ids)
            growtree!(node_arr[child_idx], minsupp, k+1, maxdepth, child_idx, node_arr)
        end
    end
end


function unique_items(transactions::Array{Array{M, 1}, 1}) where {M}
    dict = Dict{M, Bool}()

    for t in transactions
        for i in t
            dict[i] = true
        end
    end
    uniq_items = collect(keys(dict))
    return sort(uniq_items)
end



# This function is used internally by the frequent() function to create the
# initial bitarrays used to represent the first "children" in the itemset tree.
function occurrence(transactions::Array{Array{String, 1}, 1}, uniq_items::Array{String, 1})
    n = length(transactions)
    p = length(uniq_items)

    itm_pos = Dict(zip(uniq_items, 1:p))
    res = falses(n, p)
    for i = 1:n
        for itm in transactions[i]
            j = itm_pos[itm]
            res[i, j] = true
        end
    end
    res
end


"""
    frequent_item_tree(transactions, minsupp, maxdepth)

This function creates a frequent itemset tree from an array of transactions.
The tree is built recursively using calls to the growtree!() function. The
`minsupp` and `maxdepth` parameters control the minimum support needed for an
itemset to be called "frequent", and the max depth of the tree, respectively
"""
function frequent_item_tree(transactions::Array{Array{String, 1}, 1}, uniq_items::Array{String, 1}, minsupp::Int, maxdepth::Int)
    occ = occurrence(transactions, uniq_items)

    # Have to initialize `itms` array like this because type inference
    # seems to be broken for this otherwise (using v0.6.0)
    itms = Array{Int16,1}(1)
    itms[1] = -1
    transacts = BitArray(0)
    root = Node(itms, transacts)
    n_items = length(uniq_items)

    # This loop creates 1-item nodes (i.e., first children)
    for j = 1:n_items
        supp = sum(occ[:, j])
        if supp ≥ minsupp
            nd = Node(Int16(j), occ[:, j], root, supp)
            push!(root.children, nd)
        end
    end
    n_kids = length(root.children)

    # Grow nodes in breadth-first manner
    for j = 1:n_kids
        growtree!(root.children[j], minsupp, 2, maxdepth)
    end
    root
end
