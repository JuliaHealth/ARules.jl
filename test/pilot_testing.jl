# pilot_testing.jl


# @code_warntype Node(Int16(1), Int16[1], trues(3))
n1 = Node(Int16(1), Int16[1], trues(3))

# @code_warntype Node(Int16(1), Int16[1, 2], trues(3), n1)
n2 = Node(Int16(1), Int16[1, 2], trues(3), n1, 1)
n3 = Node(Int16(1), Int16[1, 3], trues(3), n1, 1)
n4 = Node(Int16(1), Int16[1, 4], trues(3), n1, 1)
n5 = Node(Int16(1), Int16[1, 5], trues(3), n1, 1)
n6 = Node(Int16(1), Int16[1, 6], trues(3), n1, 1)
n7 = Node(Int16(1), Int16[2, 3], trues(3), n1, 1)
n8 = Node(Int16(1), Int16[2, 4], trues(3), n1, 1)
n9 = Node(Int16(1), Int16[2, 5], trues(3), n1, 1)
n10 = Node(Int16(1), Int16[2, 6], trues(3), n1, 1)


push!(n1.children, n2)
push!(n1.children, n3)
push!(n1.children, n4)
push!(n1.children, n5)
push!(n1.children, n6)
push!(n1.children, n7)
push!(n1.children, n8)
push!(n1.children, n9)
push!(n1.children, n10)

@code_warntype has_children(n1)

@code_warntype younger_siblings(n1.children[1])
younger_siblings(n1.children[1])


@code_warntype growtree!(n2, 1, 3, 3)
growtree!(n2, 1, 3, 3)



t = [["a", "b"], 
     ["b", "c", "d"], 
     ["a", "c"],
     ["e", "b"], 
     ["a", "c", "d"], 
     ["a", "e"], 
     ["a", "b", "c"],
     ["c", "b", "e"]]

@code_warntype unique_items(t);
@time unique_items(t);


unq = unique_items(t)
@code_warntype occurrence(t, unq)
@time occurrence(t, unq)




t = [["a", "b"], 
     ["b", "c", "d"], 
     ["a", "c"],
     ["e", "b"], 
     ["a", "c", "d"], 
     ["a", "e"], 
     ["a", "b", "c"],
     ["c", "b", "e", "f"]]

unq = unique_items(t)

@code_warntype _frequent(t, unq, 0.01, 3)
xtree1 = _frequent(t, unq, 0.01, 4)




itemlist = randstr(25, 16);

n = 100_000
m = 25             # number of items in transactions
mx_depth = 7
t = [sample(itemlist, m, replace = false) for _ in 1:n];

# @code_warntype _frequent(t, 1)
@time unq2 = unique_items(t);
@time occ2 = occurrence(t, unq2);
@time xtree1 = _frequent(t, unq2, round(Int, 0.01*n), mx_depth);







# Rule Generation Testing
@code_warntype gen_support_dict(xtree1, n)



t1 = [["a", "b"], 
     ["b", "c", "d"], 
     ["a", "c"],
     ["e", "b"], 
     ["a", "c", "d"], 
     ["a", "e"], 
     ["a", "b", "c"],
     ["c", "b", "e", "f"]]

@code_warntype _frequent(t1, 1, 3)
unq3 = unique_items(t1)
xtree1 = _frequent(t1, unq3, 1, 4);
@code_warntype gen_support_dict(xtree1, length(t1))
xsup = gen_support_dict(xtree1, length(t1))



@code_warntype gen_node_rules(xtree1.children[1].children[1].children[1], xsup, 3, 8)

xrules = gen_node_rules(xtree1.children[1].children[1].children[1], xsup, 3, 8)



rule_arr = Array{Rule, 1}(0)
gen_rules!(rule_arr, xtree1.children[1], xsup, 2, 8)
      




t1 = [["a", "b"], 
     ["b", "c", "d"], 
     ["a", "c"],
     ["e", "b"], 
     ["a", "c", "d"], 
     ["a", "e"], 
     ["a", "b", "c"],
     ["c", "b", "e", "f"]]

unq = unique_items(t1)
xtree = _frequent(t1, unq, 1, 4);
shownodes(xtree)



# Comparing with R 
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

xunq = unique_items(a_list)
xtree1 = _frequent(a_list, xunq, 1, 6);
xsup = gen_support_dict(xtree1, length(a_list))

xrules = gen_rules(xtree1, xsup, 12)

apriori(a_list, 0.01, 6)







# Example below used to track down bug of unexplored node Int16[4, 10, 14]
transactions = [["milk", "eggs", "bread"],
                ["butter", "milk", "sugar", "flour", "eggs"],
                ["bacon", "eggs", "milk", "beer"],
                ["bread", "ham", "turkey"],
                ["cheese", "ham", "bread", "ketchup"],
                ["mustard", "hot dogs", "buns", "hamburger", "cheese", "beer"],
                ["milk", "sugar", "eggs"],
                ["hamburger", "ketchup", "milk", "beer"],
                ["ham", "cheese", "bacon", "eggs"]]

freq = frequent(transactions, 1, 7)
display(freq)

for x in freq[:itemset] 
    println(x)
end

unq = unique_items(transactions)

node = _frequent(transactions, unq, 0.01, 6)
sup = gen_support_dict(node, 9)

for k in keys(sup)
    println(k)
end

rules = apriori(transactions, 0.1, 4)








transactions = [["milk", "eggs", "bread"],
                ["butter", "milk", "sugar", "flour", "eggs"],
                ["bacon", "eggs", "milk", "beer"],
                ["bread", "ham", "turkey"],
                ["cheese", "ham", "bread", "ketchup"],
                ["mustard", "hot dogs", "buns", "hamburger", "cheese", "beer"]]

freq = frequent(transactions, 1, 7)
# display(freq)

unq = unique_items(transactions)
unq[[4, 10, 14]]

node = _frequent(transactions, unq, 0.01, 6)
shownodes(node)

sup = gen_support_dict(node, 9)








