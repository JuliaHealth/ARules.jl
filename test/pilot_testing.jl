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

@code_warntype get_unique_items(t);
@time get_unique_items(t);


unq = get_unique_items(t)
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

unq = get_unique_items(t)

@code_warntype frequent(t, unq, 0.01, 3)
xtree1 = frequent(t, unq, 0.01, 4)




itemlist = rands(25, 16);

n = 10_000
m = 20              # number of items in transactions
mx_depth = 5
t = [sample(itemlist, m, replace = false) for _ in 1:n];

# @code_warntype frequent(t, 1)
@time unq2 = get_unique_items(t);
@time occ2 = occurrence(t, unq2);
@time xtree1 = frequent(t, unq2, round(Int, 0.01*n), mx_depth);


