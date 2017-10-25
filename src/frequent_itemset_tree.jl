# This implements the first attempt at using bitarrays for
# storing and propagating the itemset information at each node


using StatsBase
using DataTables

struct Node
    id::Int16
    item_ids::Array{Int16,1}
    transactions::BitArray{1}
    children::Array{Node,1}
    mother::Node
    supp::Int

    function Node(id::Int16, item_ids::Array{Int16,1}, transactions::BitArray{1})
        children = Array{Node,1}(0)
        nd = new(id, item_ids, transactions, children)
        return nd
    end

    function Node(id::Int16, item_ids::Array{Int16,1}, transactions::BitArray{1}, mother::Node, supp::Int)
        children = Array{Node,1}(0)
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
    # println("length sibs: ", n_sibs)
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
    transacts = BitArray(0)
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
    itms = Array{Int16,1}(1)
    itms[1] = -1
    id = Int16(1)
    transacts = BitArray(0)
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

    # Grow nodes in breadth-first manner
    for j = 1:n_kids
        growtree!(root.children[j], minsupp, 2, maxdepth)
    end
    root
end


function suppdict_to_datatable(supp_lkup, item_lkup)
    n_sets = length(supp_lkup)
    dt = DataTable(itemset = fill("", n_sets),
                   supp = zeros(Int, n_sets))
    i = 1

    for (k, v) in supp_lkup
        item_names = map(x -> item_lkup[x], k)
        itemset_string = "{" * join(item_names, ",") * "}"
        dt[i, :itemset] = itemset_string
        dt[i, :supp] = v
        i += 1
    end
    dt
end



# TODO: Fix the function below so that it handles int `minsupp`

"""
    frequent()
This function just acts as a bit of a convenience function that returns the frequent
item sets and their support count (integer) when given and array of transactions. It
basically just wraps frequent_item_tree() but gives back the plain text of the items, rather than
that Int16 representation.
"""
function frequent(transactions::Array{Array{String, 1}, 1}, minsupp::T, maxdepth) where T <: Real
    n = length(transactions)
    uniq_items = unique_items(transactions)
    item_lkup = Dict{Int16, String}()
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

    freq = suppdict_to_datatable(supp_lkup, item_lkup)
    return freq
end


####################


struct Node4
    item_ids::Array{Int16, 1}
    transact_ids::Array{Int,1}
    supp::Int

    # #constructor for root_node
    # function Node4(item_ids::Array{Int16,1}, transactions::T, supp::Int64) where {T<:SubArray{Bool, 1}}
    #     transact_ids = find(transactions)
    #     nd = new(item_ids, transact_ids, supp)
    #     return nd
    # end

    #constructor
    function Node4(item_ids::Array{Int16,1}, transact_ids::Array{Int,1}, supp::Int)
        nd = new(item_ids, transact_ids, supp)
        return nd
    end

end

# This function is used internally and is the workhorse of the frequent()
# function, which generates a frequent itemset tree. The growtree!() function
# builds up the frequent itemset tree recursively.
function growtree4!(node_dict::Dict{Int16, Vector{Vector{Node4}}}, occ::BitArray{2}, array_idx::Int, level::Int, minsupp::Int)
    
    nitems = length(node_dict[level-1][array_idx]) 
    node_dict[level] = Vector{Vector{Node4}}()
    for item_idx = 1:nitems
        #transaction ids for this node
        push!(node_dict[level], Vector{Node4}())
        node_item_ids = node_dict[level - 1][array_idx][item_idx].item_ids
        node_ti = node_dict[level - 1][array_idx][item_idx].transact_ids

        for sib_idx = item_idx:nitems
             sib_item_id = node_dict[level - 1][array_idx][sib_idx].item_ids[end]
             join_transacts = view(occ, node_ti, sib_item_id) #occ[node_ti, sib_item_id]
             join_ti = node_ti[join_transacts] #view(node_ti, join_transacts)
             supp = length(join_ti)
             if supp ≥ minsupp
                 # join_item_ids = vcat(node_item_ids, sib_item_id)
                 join_item_ids = zeros(Int16, level)
                 join_item_ids[1:level-1] = node_item_ids
                 join_item_ids[end] = sib_item_id
                 nd = Node4(join_item_ids, join_ti, supp)
                 push!(node_dict[level][item_idx], nd)
             end
        end
    end
end


"""
frequent_item_tree4 Board idea + dict
"""
function frequent_item_tree4(occ::BitArray{2}, uniq_items::Array{String, 1}, minsupp::Int, maxdepth::Int)
        
    level = 1
    node_dict = Dict{Int16, Vector{Vector{Node4}}}(level=> [Vector{Node4}()])
    nitems = size(occ, 2)
    ti = collect(1:size(occ, 1))
    # This loop creates 1-item nodes (i.e., first children)
    # If item doesn't have support do not insert
    for j = 1:nitems
        node_transacts = view(occ, :, j) #occ[:,j]
        node_ti = ti[node_transacts] #view(trans_ids, node_transacts)
        supp = length(node_ti)
        if supp ≥ minsupp
            nd = Node4(Int16[j], node_ti, supp)
            push!(node_dict[level][1], nd)
        end
    end
    
    nitems_level1 = length(node_dict[1][1]) #Careful! True if root is not added
    narrays_level1 = length(node_dict[1])
    
    # Loop to create the 2-item nodes 
    # If item doesn't have support insert empty array (to keep children access in dict)
    level = 2 #level of singles
    node_dict[level] = Vector{Vector{Node4}}()
    for item_idx = 1:nitems_level1
        #transaction ids for this node
        push!(node_dict[level], Vector{Node4}())
        node_item_ids = node_dict[level - 1][1][item_idx].item_ids
        node_ti = node_dict[level - 1][1][item_idx].transact_ids
        for sib_idx = (item_idx+1):nitems_level1
            #the item id may not be the same as the sib-idx because level filtered by support
            sib_item_id = node_dict[level - 1][1][sib_idx].item_ids[end]
            # pair_transacts = view(occ, node_ti, sib_item_id) #occ[node_ti, sib_item_id]
            pair_transacts = occ[node_ti, sib_item_id]
            pair_ti = node_ti[pair_transacts] #view(node_ti, pair_transacts)
            supp = length(pair_ti)
            if supp ≥ minsupp
                # pair_item_ids = vcat(node_item_ids, sib_item_id)
                pair_item_ids = zeros(Int16, level)
                pair_item_ids[1:level-1] = node_item_ids
                pair_item_ids[end] = sib_item_id
                nd = Node4(pair_item_ids, pair_ti, supp)
                push!(node_dict[level][item_idx], nd)
            end
        end
    end

    # Grow nodes in breadth-first manner
    while(level < maxdepth)
        narrays_prior_level = length(node_dict[level])
        level = level + 1
        for kid_array_idx = 1:narrays_prior_level
            growtree4!(node_dict, occ, kid_array_idx, level, minsupp)
        end
    end

    node_dict
end



"""
frequent_item_tree5

Same as f4 but use sparse bool for occ. -- seems pretty bad for memory but doesn't show in allocation tracking
"""
function frequent_item_tree5(occ::SparseMatrixCSC{Bool, Int64}, uniq_items::Array{String, 1}, minsupp::Int, maxdepth::Int)

    level = 1
    node_dict = Dict{Int16, Vector{Vector{Node4}}}(level=> [Vector{Node4}()])
    nitems = size(occ, 2)
    # This loop creates 1-item nodes (i.e., first children)
    # If item doesn't have support do not insert
    for j = 1:nitems
        #indeces of non-zero values for the jth column
        node_ti = occ.rowval[occ.colptr[j]:occ.colptr[j+1]-1]; #view(trans_ids, node_transacts)
        supp = length(node_ti)
        if supp ≥ minsupp
            nd = Node4(Int16[j], node_ti, supp)
            push!(node_dict[level][1], nd)
        end
    end
    
    nitems_level1 = length(node_dict[1][1]) #Careful! True if root is not added
    narrays_level1 = length(node_dict[1])
    
    # Loop to create the 2-item nodes 
    # If item doesn't have support insert empty array (to keep children access in dict)
    level = 2 #level of singles
    node_dict[level] = Vector{Vector{Node4}}()
    for item_idx = 1:nitems_level1
        #transaction ids for this node
        push!(node_dict[level], Vector{Node4}())
        node_item_ids = node_dict[level - 1][1][item_idx].item_ids
        node_ti = node_dict[level - 1][1][item_idx].transact_ids
        for sib_idx = (item_idx+1):nitems_level1
            #the item id may not be the same as the sib-idx because level filtered by support
            sib_item_id = node_dict[level - 1][1][sib_idx].item_ids[end]
            pair_transacts = occ[node_ti, sib_item_id]
            pair_ti = node_ti[pair_transacts] #view(node_ti, pair_transacts)
            supp = length(pair_ti)
            if supp ≥ minsupp
                # pair_item_ids = vcat(node_item_ids, sib_item_id)
                pair_item_ids = zeros(Int16, level)
                pair_item_ids[1:level-1] = node_item_ids
                pair_item_ids[end] = sib_item_id
                nd = Node4(pair_item_ids, pair_ti, supp)
                push!(node_dict[level][item_idx], nd)
            end
        end
    end
    
    node_dict
end

# ------------------------- Bit Array - No transacts



struct Node6
    id::Int16
    item_ids::Array{Int16,1}
    children::Array{Node6,1}
    mother::Node6
    supp::Int

    function Node6(id::Int16, item_ids::Array{Int16,1})
        children = Array{Node6,1}(0)
        nd = new(id, item_ids, children)
        return nd
    end

    function Node6(id::Int16, item_ids::Array{Int16,1}, mother::Node6, supp::Int)
        children = Array{Node6,1}(0)
        nd = new(id, item_ids, children, mother, supp)
        return nd
    end
end

function older_siblings(nd::Node6)
    n_sibs = length(nd.mother.children)
    # println("length sibs: ", n_sibs)
    sib_indcs = map(x -> x.id > nd.id, nd.mother.children)
    return view(nd.mother.children, sib_indcs)
end

function compute_support(occ::BitArray{2}, item_ids::Vector{Int16})

    sum = 0
    res = true           
    for row=1:size(occ,1)
        res = true     
        occ_row = view(occ, :, 1)              
        @simd for id in item_ids
            @inbounds val= occ[row,id]
            res &= val
        end
        sum+=res
    end
    sum
end

# This function is used internally and is the workhorse of the frequent()
# function, which generates a frequent itemset tree. The growtree!() function
# builds up the frequent itemset tree recursively.
function growtree6!(occ::BitArray{2}, nd::Node6, minsupp::Int, k::Int, maxdepth::Int)
    sibs = older_siblings(nd)

    for j = 1:length(sibs)
        # transacts = nd.transactions .& sibs[j].transactions
        # supp = sum(transacts)
        items = zeros(Int16, k)
        items[1:k-1] = nd.item_ids[1:k-1]
        items[end] = sibs[j].item_ids[end]

        supp = compute_support(occ, items)
        if supp ≥ minsupp
            child = Node6(Int16(j), items, nd, supp)
            push!(nd.children, child)
        end
    end
    # Recurse on newly created children
    maxdepth -= 1
    if maxdepth > 1
        for kid in nd.children
            # println("running kid: ", kid.item_ids)
            growtree6!(occ, kid, minsupp, k+1, maxdepth)
        end
    end
end

"""
frequent_item_tree6(occurrences, minsupp, maxdepth)

*Bit Array
*Don't store transactions
*compute the support as loop
"""
function frequent_item_tree6(occ::BitArray{2}, minsupp::Int, maxdepth::Int)

    # Have to initialize `itms` array like this because type inference
    # seems to be broken for this otherwise (using v0.6.0)
    itms = Array{Int16,1}(1)
    itms[1] = -1
    id = Int16(1)
    transacts = BitArray(0)
    root = Node6(id, itms)
    n_items = size(occ, 2)

    # This loop creates 1-item nodes (i.e., first children)
    for j = 1:n_items
        supp = sum(occ[:, j])
        if supp ≥ minsupp
            nd = Node6(Int16(j), Int16[j], root, supp)
            push!(root.children, nd)
        end
    end
    n_kids = length(root.children)

    # Grow nodes in breadth-first manner
    for j = 1:n_kids
        growtree6!(occ, root.children[j], minsupp, 2, maxdepth)
    end
    root
end



# ------------------------- No recursion - No transacts

struct Node7
    item_ids::Array{Int16, 1}
    supp::Int

    #constructor
    function Node7(item_ids::Array{Int16,1}, supp::Int)
        nd = new(item_ids, supp)
        return nd
    end

end

# This function is used internally and is the workhorse of the frequent()
# function, which generates a frequent itemset tree. The growtree!() function
# builds up the frequent itemset tree recursively.
function growtree7!(node_dict::Vector{Vector{Vector{Node7}}}, occ::BitArray{2}, array_idx::Int, level::Int, minsupp::Int)
    
    nitems = length(node_dict[level-1][array_idx]) 
    for item_idx = 1:nitems
        push!(node_dict[level], Vector{Node7}())    
        #transaction ids for this node
        node_item_ids = node_dict[level - 1][array_idx][item_idx].item_ids
        for sib_idx = item_idx+1:nitems
             sib_item_id = node_dict[level - 1][array_idx][sib_idx].item_ids[end]
             join_item_ids = zeros(Int16, level)
             join_item_ids[1:level-1] = node_item_ids
             join_item_ids[end] = sib_item_id
             supp = compute_support(occ, join_item_ids)
             if supp ≥ minsupp
                nd = Node7(join_item_ids, supp)
                push!(node_dict[level][item_idx], nd)
             end
        end
    end
end


function frequent_item_tree7(occ::BitArray{2}, minsupp::Int, maxdepth::Int)
    
    level = 1
    # node_dict = Dict{Int16, Vector{Vector{Node7}}}(level=> [Vector{Node7}()])
    node_dict = Vector{Vector{Vector{Node7}}}(maxdepth)
    node_dict[level] = [Vector{Node7}()]  #first level anly contains one vector with all symbols
    nitems = size(occ, 2)
    
    # This loop creates 1-item nodes (i.e., first children)
    # If item doesn't have support do not insert
    for j = 1:nitems
        supp = sum(occ[:, j])
        if supp ≥ minsupp
            nd = Node7(Int16[j], supp)
            push!(node_dict[level][1], nd)
        end
    end

    # Grow nodes in breadth-first manner
    while(level < maxdepth)
        level = level + 1        
        narrays_prior_level = length(node_dict[level-1])
        node_dict[level] = Vector{Vector{Node7}}()
        for kid_array_idx = 1:narrays_prior_level
            growtree7!(node_dict, occ, kid_array_idx, level, minsupp)
        end
    end
    
    node_dict
end

# ------------------------- No recursion - No transacts - OCC transpose


function compute_support8(occ::Array{Bool, 2}, item_ids::Vector{Int16})
    
        sum = 0
        res = true   
        #transactions are columns        
        for col=1:size(occ,2)
            res = true     
            for row in item_ids
                @inbounds val= occ[row, col]
                res &= val
            end
            sum+=res
        end
        sum
end

# This function is used internally and is the workhorse of the frequent()
# function, which generates a frequent itemset tree. The growtree!() function
# builds up the frequent itemset tree recursively.
function growtree8!(node_dict::Vector{Vector{Vector{Node7}}}, occ::Array{Bool, 2}, array_idx::Int, level::Int, minsupp::Int)
    
    nitems = length(node_dict[level-1][array_idx]) 
    for item_idx = 1:nitems
        push!(node_dict[level], Vector{Node7}())    
        #transaction ids for this node
        node_item_ids = node_dict[level - 1][array_idx][item_idx].item_ids
        for sib_idx = item_idx+1:nitems
             sib_item_id = node_dict[level - 1][array_idx][sib_idx].item_ids[end]
             join_item_ids = zeros(Int16, level)
             join_item_ids[1:level-1] = node_item_ids
             join_item_ids[end] = sib_item_id
             supp = compute_support8(occ, join_item_ids)
             if supp ≥ minsupp
                nd = Node7(join_item_ids, supp)
                push!(node_dict[level][item_idx], nd)
             end
        end
    end
end


function frequent_item_tree8(occ::Array{Bool, 2}, minsupp::Int, maxdepth::Int)
    
    level = 1
    # node_dict = Dict{Int16, Vector{Vector{Node7}}}(level=> [Vector{Node7}()])
    node_dict = Vector{Vector{Vector{Node7}}}(maxdepth)
    node_dict[level] = [Vector{Node7}()]  #first level anly contains one vector with all symbols
    nitems = size(occ, 1)
    
    # This loop creates 1-item nodes (i.e., first children)
    # If item doesn't have support do not insert
    for j = 1:nitems
        supp = sum(occ[j, :])
        if supp ≥ minsupp
            nd = Node7(Int16[j], supp)
            push!(node_dict[level][1], nd)
        end
    end

    # Grow nodes in breadth-first manner
    while(level < maxdepth)
        level = level + 1        
        narrays_prior_level = length(node_dict[level-1])
        node_dict[level] = Vector{Vector{Node7}}()
        for kid_array_idx = 1:narrays_prior_level
            growtree8!(node_dict, occ, kid_array_idx, level, minsupp)
        end
    end
    
    node_dict
end