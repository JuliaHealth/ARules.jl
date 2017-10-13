
struct Node
    id::Int16
    item_ids::Array{Int16, 1}
    transact_ids::Array{Int, 1}
    children::Array{Node, 1}
    mother::Node
    supp::Int

    function Node(id::Int16, item_ids::Array{Int16,1}, transact_ids::BitArray{1})
        children = Array{Node,1}(0)
        nd = new(id, item_ids, transact_ids, children)
        return nd
    end

    function Node(id::Int16, item_ids::Array{Int16,1}, transact_ids::BitArray{1}, mother::Node, supp::Int)
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
        transacts = nd.transactions .& sibs[j].transactions
        supp = sum(transacts)

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
