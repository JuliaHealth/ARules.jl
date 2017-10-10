using ARules
using StatsBase
using BenchmarkTools


itemlist = randstr(100);

n = 100_000
m = 25             # number of items in transactions
mx_depth = 7
t = [sample(itemlist, m, replace = false) for _ in 1:n];

# @code_warntype _frequent(t, 1)
@time unq2 = unique_items(t)
# @benchmark occ2 = occurrence(t, unq2)
@time itree2 = frequent_item_tree(t, unq2, round(Int, 0.01*n), mx_depth)

ARules.shownodes(itree2)
