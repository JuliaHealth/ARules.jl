

struct Node
    id::Int16
    item_ids::Array{Int16, 1}
    transact_ids::Array{Int, 1}
    children::Array{Node, 1}
    mother::Node

    function Node(id::Int16, item_ids::Array{Int16, 1}, transact_ids::Array{Int, 1})
        children = Array{Node, 1}(0)
        nd = new(id, item_ids, transact_ids, children)
        return nd
    end

    function Node(id::Int16, item_ids::Array{Int16,1}, transact_ids::Array{Int, 1}, mother::Node)
        children = Array{Node,1}(0)
        nd = new(id, item_ids, transactions, children, mother)
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
        transacts_ids = intersect(nd.transact_ids, sibs[j].transact_ids)


        if length(transacts_ids) ≥ minsupp
            items = zeros(Int16, k)
            for i = 1:(k - 1)
                items[i] = nd.item_ids[i]
            end
            items[end] = sibs[j].item_ids[end]

            child = Node(Int16(j), items, transact_ids, nd)
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


function unique_items{M}(transactions::Array{Array{M, 1}, 1})
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
    id = Int16(1)
    transact_ids = Array{Int,1}(0)
    root = Node(id, itms, transact_ids)
    n_items = length(uniq_items)

    # This loop creates 1-item nodes (i.e., first children)
    for j = 1:n_items
        transact_ids = find(occ[:, j])
        if supp ≥ minsupp
            nd = Node(Int16(j), Int16[j], transact_ids, root)
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
