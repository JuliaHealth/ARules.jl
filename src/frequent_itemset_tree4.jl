# This version implements Isabel's idea of only storing
# transaction ID information, and using that to propagate
# information down the nodes of the tree. So only the
# single-item nodes have the actual transaction bitarrays.


struct Node
    id::Int16
    item_ids::Array{Int16, 1}
    transact_ids::Array{Int, 1}
    children::Array{Int, 1} #make Array of ints
    parent::Int
    supp::Int
    # transactions::BitArray{1}  #move outside 

    #constructor for root_node
    function Node(id::Int16, item_ids::Array{Int16,1}, transactions::T, parent::Int, supp::Int) where {T<:SubArray{Bool, 1}}
        transact_ids = find(transactions)
        children = Array{Int, 1}(0)
        nd = new(id, item_ids, transact_ids, children, parent, supp)
        # nd.transactions = transactions #is this needed?
        return nd
    end

    #constructor for root_node
    function Node(id::Int16, item_ids::Array{Int16,1}, transact_ids::T, parent::Int, supp::Int) where {T<: AbstractArray{Int16,1}}
        children = Array{Int,1}(0)
        nd = new(id, item_ids, transact_ids, children, parent, supp)
        return nd
    end

end



# This function is used internally and is the workhorse of the frequent()
# function, which generates a frequent itemset tree. The growtree!() function
# builds up the frequent itemset tree recursively.
# function growtree!(node_dict::Dict{Int16, Vector{Int64}}, level::Int16, node_idx::Int64, minsupp::Int64, maxdepth::Int16)
    
#     # node_arr = node_dict[level]
#     # rhs_arr = node_dict[1] #we are always joining with as single
#     # n_nodes = length(node_arr)
#     # sibs = older_siblings(nd, node_arr, node_idx)     # sibs is vector of indices
#     sibs = 

#     for j = node_idx:length(node_arr)
#         transacts = transactions[]
#         supp = sum(transacts)

#         if supp ≥ minsupp
#             items = zeros(Int16, length())
#             for i = 1:(k - 1)
#                 items[i] = node_arr[node_idx].item_ids[i]
#             end
#             items[end] = node_arr[sibs[j]].item_ids[end]

#             child = Node(items, transacts, node_idx, supp)
#             n_nodes += 1
#             push!(node_arr, child)          # add child node to master node array
#             push!(nd.children, n_nodes)     # n_nodes is the child's node index
#         end
#     end
#     # Recurse on newly created children
#     maxdepth -= 1
#     if maxdepth > 1
#         for child_idx in nd.children
#             # println("running child_idx: ", child_idx.item_ids)
#             growtree!(node_arr[child_idx], minsupp, k+1, maxdepth, child_idx, node_arr)
#         end
#     end
# end

"""
frequent_item_tree(transactions, minsupp, maxdepth)

This function creates a frequent itemset tree from an array of transactions.
The tree is built recursively using calls to the growtree!() function. The
`minsupp` and `maxdepth` parameters control the minimum support needed for an
itemset to be called "frequent", and the max depth of the tree, respectively
"""
function frequent_item_tree(transactions::Array{Array{String, 1}, 1}, uniq_items::Array{String, 1}, minsupp::Int, maxdepth::Int)
    
    occ = occurrence(transactions, uniq_items)
    
    level = 1
    node_dict = Dict{Int16, Vector{Vector{Node}}}(level=> [Vector{Node}()])
    nitems = size(occ, 2)
    # This loop creates 1-item nodes (i.e., first children)
    # If item doesn't have support do not insert
    for j = 1:nitems
        supp = sum(occ[:, j])
        if supp ≥ minsupp
            nd = Node(Int16(j), Int16[j], view(occ, :, j), 0, supp)
            push!(node_dict[level][1], nd)
        end
    end
    
    nitems_level1 = length(node_dict[1][1]) #Careful! True if root is not added
    narrays_level1 = length(node_dict[1])
    
    # Loop to create the 2-item nodes 
    # If item doesn't have support insert empty array (to keep children access in dict)
    level = 2 #level of singles
    node_dict[level] = Vector{Vector{Node}}()
    for item_idx = 1:nitems_level1
        #transaction ids for this node
        push!(node_dict[level], Vector{Node}())
        node_item_ids = node_dict[level - 1][1][item_idx].item_ids
        node_ti = node_dict[level - 1][1][item_idx].transact_ids
        for sib_idx = (item_idx+1):nitems_level1
            #the item id may not be the same as the sib-idx because level filtered by support
            sib_item_id = node_dict[level - 1][1][sib_idx].item_ids[end]
            pair_transacts = view(occ, node_ti, sib_item_id)
            pair_ti = view(node_ti, pair_transacts)
            supp = length(pair_ti)
            if supp ≥ minsupp
                pair_item_ids = vcat(node_item_ids, sib_item_id)
                nd = Node(Int16(sib_idx), pair_item_ids, pair_ti, item_idx, supp)
                push!(node_dict[level][item_idx], nd)
            end
        end
    end
    
    node_dict
end