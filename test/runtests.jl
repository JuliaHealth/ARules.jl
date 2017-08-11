using ARules
using StatsBase
using Base.Test

# write your own tests here


itemlist = randstr(25, 16);

n = 100
m = 10              # number of items in transactions
mx_depth = 5        # max depth of itemset tree (max size of transactions explored)
t = [sample(itemlist, m, replace = false) for _ in 1:n];

# @code_warntype frequent(t, 1)
unq = get_unique_items(t);
@test typeof(unq) == Array{String, 1}

occ = occurrence(t, unq);
@test typeof(occ) == BitArray{2}

xtree1 = frequent(t, unq, round(Int, 0.01*n), mx_depth);
@test typeof(xtree1) == Node



t2 = [["a", "b"], 
     ["b", "c", "d"], 
     ["a", "c"],
     ["e", "b"], 
     ["a", "c", "d"], 
     ["a", "e"], 
     ["a", "b", "c"],
     ["c", "b", "e", "f"]]

unq2 = get_unique_items(t2)
@test length(unq2) == 6


xtree2 = frequent(t2, unq2, 1, 4);
xsup = gen_support_dict(xtree2, length(t2))
@test length(xsup) == 27
@test typeof(xsup) == Dict{Array{Int16,1}, Int64}

xrules = gen_node_rules(xtree2.children[1], xsup, 3, 8)
@test length(xrules) == 3


rule_arr = Array{Rule, 1}(0)
gen_rules!(rule_arr, xtree2.children[1], xsup, 2, 8)
@test eltype(rule_arr) == Rule  
@test length(rule_arr) == 14


# A full run through
a_list = [
    ["a", "b"],
    ["a", "c"],
    ["a", "b", "c"],
    ["a", "b", "d"], 
    ["a", "c", "d"], 
    ["a", "b", "c", "d"],    
    ["a", "b", "c", "e"],
    ["b", "d", "e", "f"],
    ["a", "c", "e", "f"],
    ["b", "c", "d", "e", "f"],
    ["a", "c", "d", "e", "f"],
    ["b", "c", "d", "e", "f"]
]

xunq3 = get_unique_items(a_list)
xtree3 = frequent(a_list, xunq3, 1, 6);
xsup3 = gen_support_dict(xtree3, length(a_list))

xrules3 = gen_rules(xtree3, xsup3, 12)

apriori(a_list, 0.01, 6)
