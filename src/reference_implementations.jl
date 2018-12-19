# ------------- eclat -----------------------------
# Python reference implementation
# http://adrem.ua.ac.be/~goethals/software/files/eclat.py

function eclat!(prefix::Vector{T}, items::Vector{Pair{T,Vector{Int}}}, minsupp::Int, sets::Vector{Pair{Tuple,Int}}, maxlen::Int) where T
    item_supp = minsupp
    while length(items) > 0 && item_supp >= minsupp && length(items[1]) < maxlen
        item, tx_ids = popfirst!(items)
        item_supp = length(tx_ids)
        if item_supp >= minsupp
            suffix = Array{Pair{T,Array{Int,1}},1}()
            for (oitem, otx_ids) in items
                new_tx_ids = intersect(tx_ids, otx_ids)
                supp = length(new_tx_ids)
                if supp >= minsupp
                    push!(sets, (prefix..., item, oitem) => supp)
                    push!(suffix, (oitem => new_tx_ids))
                end
            end
            suffix_sorted = sort(collect(suffix), rev=true, by=x->length(x[2]))
            eclat!(vcat(prefix, [item]), suffix_sorted, minsupp, sets, maxlen)
        end
    end

    return nothing
end

function eclat_start(transactions::Vector{Vector{T}}, minsupp::Int, maxlen::Int) where T
    data = Dict{T,Vector{Int}}()
    sets = Vector{Pair{Tuple,Int}}()

    for i = 1:length(transactions)
        for item in transactions[i]
            if !haskey(data,item)
                data[item] = [i]
            else
                push!(data[item], i)
            end
        end
    end

    data_pairs = sort(filter(x->length(x[2]) >= minsupp, collect(data)), rev=true, by=x->length(x[2]))

    append!(sets, map(x -> (x[1],) => length(x[2]), data_pairs))

    eclat!(Vector{T}(), data_pairs, minsupp, sets, maxlen)

    return sets
end

# ------------- apriori ---------------------------
using IterTools

function intx(tx::Vector{Vector{T}}, c::NTuple{N,T}) where {N,T}
    found = true
    for item in c
        if !(item in tx)
            found = false
            break
        end
    end
    return found
end

function build_counts(txs::Vector{Vector{T}}) where T
    dict = Dict{Tuple{T},Int}()
    for tx in txs
        for item in tx
            dict[(item,)] = get(dict, (item,), 0) + 1
        end
    end

    return dict
end

function get_qual_itemsets(count_dict::Dict{NTuple{N,T},Int}, minsupp::Int) where {N, T}
    itemsets = Dict{NTuple{N,T},Int}()
    for (k,v) in count_dict
        if v >= minsupp
            itemsets[k] = v
        end
    end

    return itemsets
end


function split_tuple(t::NTuple{1,T}) where {T}
    return (), t[1]
end

function split_tuple(t::NTuple{N,T}) where {N, T}
    return t[1:end-1], t[end]
end

function join_step(itemsets::Vector{NTuple{N,T}}) where {N, T}
    k = N + 1
    next_k_itemsets = Vector{NTuple{k,T}}()
    i = 1
    while i <= length(itemsets)
        # The number of rows to skip in the while-loop, initially set to 1
        skip = 1

        # get tuple of first items, and then the last item in the itemset
        itemset_first, itemset_last = split_tuple(itemsets[i])

        # keep track of tail items to check later
        tail_items = [itemset_last]

        # iterate through the following itemsets to look for similar prefixes and add tail_items to list
        for j = (i+1):length(itemsets)
            itemset_j_first, itemset_j_last = split_tuple(itemsets[j])

            if itemset_j_first == itemset_first
                push!(tail_items, itemset_j_last)
                skip += 1
            else
                break
            end
        end

        # add sorted combinations of tail_items to prefix and add to return list
        for pair in IterTools.subsets(tail_items,2)
            push!(next_k_itemsets, (itemset_first..., pair...))
        end

        i += skip
    end

    return next_k_itemsets
end

function prune_step(itemsets::Vector{NTuple{N,T}}, possible_itemsets::Vector{NTuple{S,T}}) where {N, S, T}
    pruned_itemsets = falses(length(possible_itemsets))
    for (i,pi) in enumerate(possible_itemsets)
        for subset in IterTools.subsets(pi, N)
            if !(subset in itemsets)
                pruned_itemsets[i] = true
                break
            end
        end
    end

    return deleteat!(possible_itemsets, pruned_itemsets)
end

function apriori!(txs::Vector{Vector{T}}, curr_itemset::Dict{NTuple{N,T},Int}, minsupp::Int, use_tx::Dict{Int,Bool}, large_itemsets::Dict{Int,Dict}, maxlen::Int) where {N,T}
    itemsets_list = sort(collect(keys(curr_itemset))) ::Vector{NTuple{N,T}}

    C_k = prune_step(itemsets_list, join_step(itemsets_list))

    # find supports for all the candidate sets
    k_sets_counts = Dict{NTuple{N+1,T},Int}()

    isempty(C_k) && return k_sets_counts

    for (row, tx) in enumerate(txs)
        # if we've excluded this row, skip it
        haskey(use_tx, row) && continue

        found_any = false
        for candidate in C_k
            if intx(tx, candidate)
                k_sets_counts[candidate] = get(k_sets_counts, candidate, 0) + 1
                found_any = true
            end
        end

        if !found_any
            use_tx[row] = false
        end
    end

    # sets must meet minimum support
    kn_itemsets = get_qual_itemsets(k_sets_counts, minsupp) :: Dict{NTuple{N+1,T},Int}

    isempty(kn_itemsets) && return nothing

    large_itemsets[N] = kn_itemsets

    N + 1 > maxlen && return nothing

    apriori!(txs, kn_itemsets, minsupp, use_tx, large_itemsets, maxlen)

    return nothing
end

function apriori_start(txs::Vector{Vector{T}}, minsupp::Int, maxlen::Int) where T

    # process data and find items that meet criteria
    counts = build_counts(txs)

    large_itemsets = Dict{Int, Dict}()
    curr_itemset = get_qual_itemsets(counts, minsupp)

    isempty(curr_itemset) && return large_itemsets
    large_itemsets[1] = curr_itemset

    # build up the size of the itemsets
    use_tx = Dict{Int, Bool}()

    maxlen > 1 && apriori!(txs, curr_itemset, minsupp, use_tx, large_itemsets, maxlen)

    return large_itemsets
end


# ------------- fp-growth -------------------------



# ------------- NDI -------------------------------




# ------------- DIC -------------------------------



# ------------- Rank-correlated set mining --------
