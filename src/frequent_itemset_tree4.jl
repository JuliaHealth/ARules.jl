# This version implements Isabel's idea of only storing
# transaction ID information, and using that to propagate
# information down the nodes of the tree. So only the
# single-item nodes have the actual transaction bitarrays.


struct Node
    id::Int16
    item_ids::Array{Int16, 1}
    transact_ids::Array{Int, 1}
    children::Array{Node, 1}
    mother::Node
    supp::Int
    transactions::BitArray{1}  # only for single-item nodes

    function Node(id::Int16, item_ids::Array{Int16,1}, transactions::BitArray{Int, 1})
        transact_ids = find(transactions)
        children = Array{Node, 1}(0)
        nd = new(id, item_ids, transact_ids, children)
        nd.transactions = transactions
        return nd
    end

    function Node(id::Int16, item_ids::Array{Int16,1}, transact_ids::Array{Int, 1}, mother::Node, supp::Int)
        children = Array{Node,1}(0)
        nd = new(id, item_ids, transact_ids, children, mother, supp)
        return nd
    end

    function Node(id::Int16, item_ids::Array{Int16, 1}, transact_ids::SubArray{Int64,1,Array{Int64,1},Tuple{UnitRange{Int64},Int64},true}, mother::Node, supp::Int)
        children = Array{Node,1}(0)
        nd = new(id, item_ids, transact_ids, children, mother, supp)
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



# This function is used internally and is the workhorse of the frequent()
# function, which generates a frequent itemset tree. The growtree!() function
# builds up the frequent itemset tree recursively.
function growtree!(nd::Node, minsupp, k, maxdepth)
    sibs = older_siblings(nd)

    for j = 1:length(sibs)

        # TODO: This is where the magic needs to happen.
        #       We need `transact_ids` to be computed using
        #       only views all the way back to the original
        #       single-item nodes.
        transact_ids = view(nd.transactions, sibs[j].transact_ids)


        supp = length(transacts)

        if supp ≥ minsupp
            items = zeros(Int16, k)
            items[1:k-1] = nd.item_ids[1:k-1]
            items[end] = sibs[j].item_ids[end]

            child = Node(Int16(j), items, transacts, nd, supp)
            push!(nd.children, child)
        end
    end
    # Recurse on newly created children
    maxdepth -= 1
    if maxdepth > 1
        for kid in nd.children
            # println("running kid: ", kid.item_ids)
            growtree!(kid, minsupp, k+1, maxdepth)
        end
    end
end
