# This implements the first attempt at using bitarrays for
# storing and propagating the itemset information at each node


struct Node
    id::Int16
    item_ids::Array{Int16,1}
    transactions::BitArray{1}
    children::Array{Node,1}
    mother::Node
    supp::Int

    function Node(id::Int16, item_ids::Array{Int16,1}, transactions::BitArray{1})
        children = Array{Node,1}(undef, 0)
        nd = new(id, item_ids, transactions, children)
        return nd
    end

    function Node(id::Int16, item_ids::Array{Int16,1}, transactions::BitArray{1}, mother::Node, supp::Int)
        children = Array{Node,1}(undef, 0)
        nd = new(id, item_ids, transactions, children, mother, supp)
        return nd
    end
end


function has_children(nd::Node)
    res = length(nd.children) > 0
    res
end



function older_siblings(nd::Node)
    n_sibs = length(nd.mother.children)

    sib_indcs = map(x -> x.id > nd.id, nd.mother.children)
    return view(nd.mother.children, sib_indcs)
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
            growtree!(kid, minsupp, k+1, maxdepth)
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
function occurrence(transactions::Array{Array{S, 1}, 1}, uniq_items::Array{S, 1}) where S
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
function frequent_item_tree(transactions::Array{Array{S, 1}, 1}, uniq_items::Array{S, 1}, minsupp::Int, maxdepth::Int) where S
    occ = occurrence(transactions, uniq_items)

    # Have to initialize `itms` array like this because type inference
    # seems to be broken for this otherwise (using v0.6.0)
    itms = Array{Int16,1}(undef, 1)
    itms[1] = -1
    id = Int16(1)
    transacts = BitArray(undef, 0)
    root = Node(id, itms, transacts)
    n_items = length(uniq_items)

    # This loop creates 1-item nodes (i.e., first children)
    for j = 1:n_items
        supp = sum(occ[:, j])
        if supp ≥ minsupp
            nd = Node(Int16(j), Int16[j], occ[:, j], root, supp)
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



# TODO: Fix the function below so that it handles int `minsupp`

"""
    frequent()
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
    elseif T == Float64
        supp = floor(Int, minsupp * n)
        if supp == 0
            warn("Minimum support should not be 0; setting it to 1 now.")
            supp = 1
        end
    end
    freq_tree = frequent_item_tree(transactions, uniq_items, supp, maxdepth)

    supp_lkup = gen_support_dict(freq_tree, n)

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

    # Have to initialize `itms` array like this because type inference
    # seems to be broken for this otherwise (using v0.6.0)
    itms = Array{Int16,1}(undef, 1)
    itms[1] = -1
    id = Int16(1)
    transacts = BitArray(undef, 0)
    root = Node(id, itms, transacts)
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
        growtree!(root.children[j], minsupp, 2, maxdepth)
    end
    root
end
