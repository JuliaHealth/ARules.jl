# This implements the first attempt at using bitarrays for
# storing and propagating the itemset information at each node

struct Node
    id::Int16
    item_ids::Array{Int16,1}
    transactions::BitArray{1}
    children::Array{Node,1}
    supp::Int
    mother::Node


    function Node()
        id = Int16(-1)
        item_ids = Int16[]
        transactions = BitArray(undef,0)
        children = Array{Node,1}(undef, 0)
        supp = -1
        return new(id, item_ids, transactions, children, supp)
    end

    function Node(id::Int16, item_ids::Array{Int16,1}, transactions::BitArray{1}, mother::Node, supp::Int)
        children = Array{Node,1}(undef, 0)
        return new(id, item_ids, transactions, children, supp, mother)
    end
end

struct Tree
    root::Node
end

"""
    has_children(node)
Given a node, returns a boolean indicating if the node has children
"""
function has_children(nd::Node)
    return length(nd.children) > 0
end


"""
    older_sibilings(node)
Given a node, returns the nodes that have the same parent, but larger IDs
"""
function older_siblings(nd::Node)
    i = 1
    while i < length(nd.mother.children)
        nd.id == nd.mother.children[i].id && break
        i += 1
    end
    return view(nd.mother.children, (i+1):length(nd.mother.children))
end

# This function is used internally and is the workhorse of the frequent()
# function, which generates a frequent itemset tree. The growtree!() function
# builds up the frequent itemset tree recursively.
function growtree!(nd::Node, minsupp, maxdepth)
    sibs = older_siblings(nd)

    nd_tx = nd.transactions

    for j = 1:length(sibs)
        transacts = nd_tx .& sibs[j].transactions
        supp = sum(transacts)

        if supp ≥ minsupp
            items = union(nd.item_ids, sibs[j].item_ids)

            # child = Node(Int16(j), items, transacts, nd, supp)
            push!(nd.children, Node(Int16(j), items, transacts, nd, supp))
        end
    end
    # Recurse on newly created children
    maxdepth -= 1
    if maxdepth > 1
        for child in nd.children
            growtree!(child, minsupp, maxdepth)
        end
    end

    return nothing
end



function unique_items(transactions::Array{Array{T, 1}, 1}) where T
    dict = Dict{T, Bool}()

    for t in transactions
        for i in t
            dict[i] = true
        end
    end

    return sort(collect(keys(dict)))
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

    return res
end



function suppdict_to_dataframe(supp_lkup, item_lkup)
    n_sets = length(supp_lkup)
    df = DataFrame(itemset = fill("", n_sets), supp = zeros(Int, n_sets))
    i = 1

    for (k, v) in supp_lkup
        item_names = map(x -> item_lkup[x], k)
        itemset_string = "{" * join(item_names, " | ") * "}"
        df[i, :itemset] = itemset_string
        df[i, :supp] = v
        i += 1
    end
    df
end


"""
    frequent(transactions, minsupp, maxdepth)
This function just acts as a bit of a convenience function that returns the frequent
item sets and their support count (integer) when given and array of transactions. It
basically just wraps frequent_item_tree() but gives back the plain text of the items,
rather than that Int16 representation.
"""
function frequent(transactions::Array{Array{S, 1}, 1}, minsupp::T, maxdepth) where {T <: Real, S}
    n = length(transactions)
    uniq_items = unique_items(transactions)
    item_lkup = Dict{Int16, S}()
    for (i, itm) in enumerate(uniq_items)
        item_lkup[i] = itm
    end
    if T <: Integer
        supp = minsupp
    else
        supp = ceil(Int, minsupp * n)
        if supp == 0
            warn("Minimum support should not be 0; setting it to 1.")
            supp = 1
        end
    end
    freq_tree = frequent_item_tree(transactions, uniq_items, supp, maxdepth)

    supp_lkup = gen_support_dict(freq_tree.root, n)

    freq = suppdict_to_dataframe(supp_lkup, item_lkup)
    return freq
end

"""
frequent_item_tree(occurrences, minsupp, maxdepth)

This function creates a frequent itemset tree from an occurrence matrix.
The tree is built recursively using calls to the growtree!() function. The
`minsupp` and `maxdepth` parameters control the minimum support needed for an
itemset to be called "frequent", and the max depth of the tree, respectively
"""
function frequent_item_tree(occ::BitArray{2}, minsupp::Int, maxdepth::Int)

    root = Node()
    tree = Tree(root)
    n_items = size(occ, 2)

    # This loop creates 1-item nodes (i.e., first children)
    for j = 1:n_items
        supp = sum(occ[:, j])
        if supp ≥ minsupp
            nd = Node(Int16(j), Int16[j], occ[:, j], root, supp)
            push!(root.children, nd)
        end
    end
    n_kids = length(root.children)

    # Grow nodes in depth-first manner
    for j = 1:n_kids
        growtree!(root.children[j], minsupp, maxdepth)
    end

    return tree
end

"""
    frequent_item_tree(transactions, unique_items, minsupp, maxdepth)

This function creates a frequent itemset tree from an array of transactions.
The tree is built recursively using calls to the growtree!() function. The
`minsupp` and `maxdepth` parameters control the minimum support needed for an
itemset to be called "frequent", and the max depth of the tree, respectively
"""
function frequent_item_tree(transactions::Array{Array{T, 1}, 1}, uniq_items::Array{T, 1}, minsupp::Int, maxdepth::Int) where T
    occ = occurrence(transactions, uniq_items)

    return frequent_item_tree(occ, minsupp, maxdepth)
end

"""
    frequent_item_tree(transactions, minsupp, maxdepth)

This function creates a frequent itemset tree from an array of transactions.
The tree is built recursively using calls to the growtree!() function. The
`minsupp` and `maxdepth` parameters control the minimum support needed for an
itemset to be called "frequent", and the max depth of the tree, respectively
"""
function frequent_item_tree(transactions::Array{Array{T, 1}, 1}, minsupp::Int, maxdepth::Int) where T
    uniq_items = unique_items(transactions)
    occ = occurrence(transactions, uniq_items)

    return frequent_item_tree(occ, minsupp, maxdepth)
end
