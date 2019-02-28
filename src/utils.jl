
function shownodes(node::Node, k::Int = 0)
    if has_children(node)
        for nd in node.children
            print("k = $(k + 1): ")
            println(nd.item_ids)
        end
        for nd in node.children
            shownodes(nd, k+1)
        end
    end
end

function randstr(n::Int, len::Int = 16)
    vals = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
            "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
    upper = map(uppercase, vals)
    append!(vals, upper)
    append!(vals, map(string, 0:9))
    res = Array{String,1}(undef, n)
    for i = 1:n
        res[i] = join(rand(vals, len))
    end
    res
end
