using ARules
using StatsBase
using Test

# write your own tests here
itemlist = randstr(100, 16);

n = 100_000
m = 20               # NOTE: most impactful for runtime complexity (num. items in transactions)
mx_depth = 10        # max depth of itemset tree (max size of transactions explored)
t = [sample(itemlist, m, replace = false) for _ in 1:n];

unq = unique_items(t);
@test typeof(unq) == Array{String, 1}

occ = occurrence(t, unq);
@test typeof(occ) == BitArray{2}

xtree1 = frequent_item_tree(t, unq, round(Int, 0.01*n), mx_depth);
@test typeof(xtree1) == Node

rules = apriori(t, supp = 0.01, conf = 0.1, maxlen = mx_depth);

t2 = [["a", "b"],
     ["b", "c", "d"],
     ["a", "c"],
     ["e", "b"],
     ["a", "c", "d"],
     ["a", "e"],
     ["a", "b", "c"],
     ["c", "b", "e", "f"]]

unq2 = unique_items(t2)
@test length(unq2) == 6


xtree2 = frequent_item_tree(t2, unq2, 1, 4);
xsup = gen_support_dict(xtree2, length(t2))
@test length(xsup) == 27
@test typeof(xsup) == Dict{Array{Int16,1}, Int64}

xrules = gen_node_rules(xtree2.children[1].children[1].children[1], xsup, 3, 8, 0.1)
@test length(xrules) == 3


rule_arr = Array{Rule, 1}(undef, 0)
gen_rules!(rule_arr, xtree2.children[1], xsup, 2, 8, 0.1)
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

xunq3 = unique_items(a_list)
xtree3 = frequent_item_tree(a_list, xunq3, 1, 6);
xsup3 = gen_support_dict(xtree3, length(a_list))


rules = apriori(a_list, supp = 0.01, conf = 0.01, maxlen = 6)

transactions = [["milk", "eggs", "bread"],
			    ["butter", "milk", "sugar", "flour", "eggs"],
			    ["bacon", "eggs", "milk", "beer"],
			    ["bread", "ham", "turkey"],
			    ["cheese", "ham", "bread", "ketchup"],
			    ["mustard", "hot dogs", "buns", "hamburger", "cheese", "beer"]]

freq = frequent(transactions, 1, 8)


rules = apriori(transactions, supp = 0.01, conf = 0.01, maxlen = 6)
@test size(rules) == (329, 5)

unq = unique_items(transactions);
occ = occurrence(transactions, unq);
rules = apriori(occ, supp = 0.01, conf = 0.01, maxlen = 6)
@test length(rules) == 329
