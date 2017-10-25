
function shownodes(node::Node, k::Int = 0)
    if has_children(node)
        for nd in node.children 
            print("k = $(k + 1): ")
            println("Symbols: ", nd.item_ids, " Support: ", nd.supp)
        end
        for nd in node.children
            shownodes(nd, k+1)
        end
    end
end

function shownodes(node::Node6, k::Int = 0)
    if has_children(node)
        for nd in node.children 
            print("k = $(k + 1): ")
            println("Symbols: ", nd.item_ids, " Support: ", nd.supp)
        end
        for nd in node.children
            shownodes(nd, k+1)
        end
    end
end

function shownodes(node_dict::Dict{Int16, Vector{Vector{Node}}})

    for (key, chidren_arrays) in node_dict
        println("Level = $(key): ")
        for child_array in chidren_arrays
            for node in child_array
                println(node.item_ids)
            end
        end
    end
end

function shownodes(node_dict::Vector{Vector{Vector{Node7}}})
    
    for (level, chidren_arrays) in enumerate(node_dict)
        println("Level = $(level): ")
        for child_array in chidren_arrays
            for node in child_array
                println("Symbols: ", node.item_ids, " Support: ", node.supp)
            end
        end
    end
end

function randstr(n::Int, len::Int = 16)
    vals = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", 
            "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
    upper = map(uppercase, vals)
    append!(vals, upper)
    append!(vals, map(string, 0:9))
    res = Array{String,1}(n)
    for i = 1:n
        res[i] = join(rand(vals, len))
    end
    res
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
