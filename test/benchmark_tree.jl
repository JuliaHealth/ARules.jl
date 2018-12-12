using Random

function randtree(n::Int; len::Int = 12, seed::Int = 100)
    vals = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
            "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
    upper = map(uppercase, vals)
    append!(vals, upper)
    append!(vals, map(string, 0:9))
    res = Array{Array{String,1},1}(undef, n)

    Random.seed!(seed)
    for i = 1:n
        res[i] = rand(vals, rand((len-5):(len+5)))
    end

    return res
end

bm_tree = randtree(1000);

tree = frequent_item_tree(bm_tree,4,10);

# @benchmark frequent_item_tree($bm_tree,4,10)

# 2018-12-10: 22.158 s,  27.32m allocs, 10.04 GiB
# 2018-12-11: 14.163 s,  25.76m allocs, 10.00 GiB
