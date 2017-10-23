# This version implements Isabel's idea of only storing
# transaction ID information, and using that to propagate
# information down the nodes of the tree. So only the
# single-item nodes have the actual transaction bitarrays.


struct Node
    id::Int16
    item_ids::Array{Int16, 1}
    transact_ids::Array{Int, 1}
    children::Array{Int, 1} #make Array of ints
    left_parent::Int
    right_parent::Int   
    supp::Int
    # transactions::BitArray{1}  #move outside 

    #constructor for root_node
    function Node(id::Int16, item_ids::Array{Int16,1}, transactions::T, left_parent::Int, right_parent::Int, supp::Int) where {T<:SubArray{Bool, 1}}
        transact_ids = find(transactions)
        children = Array{Int, 1}(0)
        nd = new(id, item_ids, transact_ids, children, left_parent, right_parent, supp)
        # nd.transactions = transactions #is this needed?
        return nd
    end

    #constructor for root_node
    function Node(id::Int16, item_ids::Array{Int16,1}, transact_ids::T, left_parent::Int, right_parent::Int, supp::Int) where {T<: AbstractArray{Int16,1}}
        children = Array{Int,1}(0)
        nd = new(id, item_ids, transact_ids, children, left_parent, right_parent, supp)
        return nd
    end

end


function older_siblings(nd::Node)
    n_sibs = length(nd.mother.children)
    is_older = falses(n_sibs)

    for i = 1:n_sibs
        if nd.mother.children[i].id > nd.id
            is_older[i] = true
        end
    end
    return view(nd.mother.children, is_older)
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
# function growtree!(nd::Node, minsupp, k, maxdepth)
#     sibs = older_siblings(nd)

#     for j = 1:length(sibs)

#         # TODO: This is where the magic needs to happen.
#         #       We need `transact_ids` to be computed using
#         #       only views all the way back to the original
#         #       single-item nodes.
#         transact_ids = view(nd.transactions, sibs[j].transact_ids)


#         supp = length(transacts)

#         if supp ≥ minsupp
#             items = zeros(Int16, k)
#             items[1:k-1] = nd.item_ids[1:k-1]
#             items[end] = sibs[j].item_ids[end]

#             child = Node(Int16(j), items, transacts, nd, supp)
#             push!(nd.children, child)
#         end
#     end
#     # Recurse on newly created children
#     maxdepth -= 1
#     if maxdepth > 1
#         for kid in nd.children
#             # println("running kid: ", kid.item_ids)
#             growtree!(kid, minsupp, k+1, maxdepth)
#         end
#     end
# end


# This function is used internally and is the workhorse of the frequent()
# function, which generates a frequent itemset tree. The growtree!() function
# builds up the frequent itemset tree recursively.
function growtree!(node_dict::Dict{Int16, Vector{Int64}}, level::Int16, node_idx::Int64, minsupp::Int64, maxdepth::Int16)
    
    node_arr = node_dict[level]
    rhs_arr = node_dict[1] #we are always joining with as single
    n_nodes = length(node_arr)
    # sibs = older_siblings(nd, node_arr, node_idx)     # sibs is vector of indices

    for j = node_idx:length(node_arr)
        transacts = transactions[]
        supp = sum(transacts)

        if supp ≥ minsupp
            items = zeros(Int16, length())
            for i = 1:(k - 1)
                items[i] = node_arr[node_idx].item_ids[i]
            end
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
    id = Int16(1)
    transacts = BitArray(0)
    root = Node(id, itms, transacts)
    n_items = length(uniq_items)

    level = 1
    node_dict = Dict{Int16, Vector{Node}}(level=> Vector{Node}())

    # This loop creates 1-item nodes (i.e., first children)
    for j = 1:n_items
        supp = sum(occ[:, j])
        if supp ≥ minsupp
            nd = Node(Int16(j), Int16[j], view(occ, :, j), -1, -1, supp)
            push!(node_dict[level], nd)
        end
    end

    n_kids = length(node_arr) #Careful! True is root is not added
    level = 2 #level of singles
    node_dict[level] = Vector{Node}()

    # Loop to create the 2-item nodes 
    for child_idx = 1:n_kids

        #****************************** Here First merge!!!!!
        supp = sum(occ[:, j])
        #******************************

        if supp ≥ minsupp
            nd = Node(Int16(j), Int16[j], view(occ, :, j), -1, -1, supp)
            push!(node_dict[level], nd)
        end
    end
    

    # Grow nodes in breadth-first manner
    for child_idx = 1:n_kids
        growtree!(node_dict, level, child_idx, minsupp, maxdepth)
    end

    root
end


nd = Node(Int16[j], occ[:, j], 1, supp)
push!(node_arr[1].children, j+1)
push!(node_arr, nd)