using StatsBase
using Base.Threads


import Base.sort
import Base.isless
import Base.==

type Node
    item_ids::Array{Int16,1} 
    transacts::BitArray 
end

function ==(a::Node, b::Node)
    res = a.item_ids == b.item_ids && a.transacts == b.transacts 
    res 
end 

function ==(x::Array{Node,1}, y::Array{Node,1})
    n = length(x)
    res = length(y) == n
    i = 1
    while res && i < n
        println(i)
        res = x[i] == y[i]
        i += 1
    end
    res 
end


"""
    isless(x::Array{Int,1}, y::Array{Int,1})
This `isless()` method is defined to handle two Array{Int,1} so that we can 
use `sortperm()` function on arrays of arrays.
"""
function isless(x::Array{Int,1}, y::Array{Int,1})
    res = true 
    if length(x) ≠ length(y)
        error("isless() cannot be used to compare vectors of differing lengths")
    else 
        for i = 1:length(x)
            if x[i] > y[i]
                res = false 
                break
            end
        end
    end
    res 
end

function sort(x::Array{Array{Int,1},1})
    perm = sortperm(x)
    x[perm]
end

@code_warntype sortperm([[3, 13, 21], [3, 12, 14]])


function prefix(nd::Node, k::Int)
    res = view(nd.item_ids, 1:k-2)
    res 
end


groceries = ["asparagus", "broccoli", "carrots", "cauliflower", "celery", 
             "corn", "cucumbers", "lettuce", "mushrooms", "onions", 
             "peppers", "potatos", "spinach", "zucchini", "tomatoes",
             "apples", "avocados", "bananas", "berries", "cherries",
             "grapefruit", "grapes", "kiwis", "lemons", "melon",
             "oranges", "peaches", "nectarines", "pears", "plums",
             "butter", "milk", "sour cream", "whipped cream", "yogurt",
             "bacon", "beef", "chicken", "ground beef", "turkey",
             "crab", "lobster", "oysters", "salmon", "shrimp", 
             "tilapia", "tuna", "flour", "sugar", "yeast", 
             "cookies", "crackers", "nuts", "oatmeal", "popcorn",
             "pretzels", "cosmetics", "floss", "mouthwash", "toothpaste",
             "lime", "almonds", "cashews", "ketchup", "mustard"]


transactions = [sample(groceries, 12, replace = false) for x in 1:1_000_000];

function get_unique_items{M}(T::Array{Array{M, 1}, 1})
    dict = Dict{M, Int}()

    for t in T
        for i in t
            dict[i] = 1
        end
    end
    return [x for x in keys(dict)]
end


function occurrence(T::Array{Array{String, 1}, 1})
    n = length(T)
    uniq_items = get_unique_items(T)
    sort!(uniq_items)
    p = length(uniq_items)
    res = BitArray(n, p)

    for j = 1:p 
        for i = 1:n
            res[i, j] = uniq_items[j] ∈ T[i]
        end 
    end 
    res 
end


t = [["a", "b"], 
     ["b", "c", "d"], 
     ["a", "c"],
     ["e", "b"], 
     ["a", "c", "d"], 
     ["a", "e"], 
     ["a", "b", "c"],
     ["c", "b", "e"]]


@code_warntype get_unique_items(t)
@code_warntype occurrence(t)

occ1 = occurrence(t)


function is_frequent(indcs::Array{Int,1}, idx::Int, occ::BitArray{2}, minsupp::Int)
    # NOTE: This function's number of allocations is constant with 
    # respect to the size of its input vectors (this is good!).
    n = size(occ, 1)
    bit_col = trues(n)
    for j in indcs
        bit_col &= view(occ, :, j)
    end
    cnt = sum(bit_col & view(occ, :, idx))
    
    res = cnt ≥ minsupp
    res 
end

transactions = [sample(groceries, 4, replace = false) for x in 1:100_000];
occ2 = occurrence(transactions);
@code_warntype is_frequent([1], 2, occ1, 2)
@time is_frequent([1], 2, occ2, 2)




function bitwise_and!(x::BitArray, y::BitArray)
    # NOTE: This function's number of allocations is constant with respect to the size 
    # of inputs. But it's slower than `x & y`, which doesn't modify in place and uses more mem.
    for i = 1:length(x)
        @inbounds x[i] &= y[i]
    end
end

n = 100_000_000
@code_warntype bitwise_and!(bitrand(n), bitrand(n))
@time bitwise_and!(bitrand(n), bitrand(n))


function inplace_bitwise_and!(res::BitArray, x::BitArray, y::BitArray)
    for i = 1:length(res)
        res[i] = x[i] & y[i]
    end
end

@code_warntype inplace_bitwise_and!(falses(n), bitrand(n), bitrand(n))
@time inplace_bitwise_and!(falses(n), bitrand(n), bitrand(n))



function transactions_to_nodes(T::Array{Array{String,1},1})
    n = length(T)
    uniq_items = get_unique_items(T)
    sort!(uniq_items)
    p = length(uniq_items)
    occur = falses(n, p)

    for j = 1:p 
        @simd for i = 1:n
            @inbounds occur[i, j] = uniq_items[j] ∈ T[i]
        end 
    end 
    nodes = Array{Node,1}(p)
    for j = 1:p
        @inbounds nodes[j] = Node([Int16(j)], occur[:, j])
    end 
    

    return nodes
end


# Get size of largest transaction 
function max_transaction(T::Array{Array{String,1},1})
    res = 0
    n = length(T)
    for i = 1:n
        len = length(T[i])
        res = (len > res) ? len : res 
    end
    res 
end


t = [["a", "b"], 
     ["b", "c", "d"], 
     ["a", "c"],
     ["e", "b"], 
     ["a", "c", "d"], 
     ["a", "e"], 
     ["a", "b", "c"],
     ["c", "b", "e"]]

@code_warntype transactions_to_nodes(t)

@time transactions_to_nodes(t)

n = 100_000
transactions = [sample(groceries, 20, replace = false) for x in 1:n];
@time w1 = transactions_to_nodes(transactions);


function merge_nodes(node1, node2, k)
    ids = Array{Int,1}(k)
    ids[1:k-1] = deepcopy(node1.item_ids[1:(k-1)])
    if k == 2
        ids[k] = node2.item_ids[1]
    elseif k > 2
        ids[k] = node2.item_ids[k-1]
    end
    transacts = node1.transacts & node2.transacts
    nd = Node(ids, transacts)
    return nd 
end


function gen_next_layer(prev::Array{Node,1}, minsupp = 1)
    if length(prev) == 0
        n = 0
    else
        k = length(prev[1].item_ids) + 1
        n = length(prev)
    end
    nodes = Array{Node,1}(0)             # next layer of nodes
    

    for i = 1:(n-1)
        for j = (i+1):n 
            if k == 2 || prefix(prev[i], k) == prefix(prev[j], k)
                nd = merge_nodes(prev[i], prev[j], k, n_obs)
                if sum(nd.transacts) ≥ minsupp
                    push!(nodes, nd)
                end 
            end
        end 
    end
    nodes 
end


a1 = transactions_to_nodes(t)
@code_warntype gen_next_layer(a1)

n = 100_000
transactions = [sample(groceries, 12, replace = false) for x in 1:n]
@time w1 = transactions_to_nodes(transactions);
@time gen_next_layer(w1);
a2 = gen_next_layer(a1)
a3 = gen_next_layer(a2)
a4 = gen_next_layer(a3)


function frequent(T::Array{Array{String,1},1}, minsupp = 0)
    nodes = transactions_to_nodes(T)
    max_items = max_transaction(T)

    F = Array{Array{Node,1},1}(max_items)
    F[1] = nodes
    k = 2

    while k <= max_items 
        # println(k)
        F[k] = gen_next_layer(F[k-1], minsupp)
        k += 1
    end
    F
end

n = 100_000
t = [sample(groceries, 50, replace = false) for _ in 1:n];

@code_warntype frequent(t, 1)
@time f = frequent(t, round(Int, n*0.2));








