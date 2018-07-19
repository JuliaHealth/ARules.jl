using ARules
using StatsBase
using BenchmarkTools


const itemlist = randstr(100);

n = 100_000
const m = 25             # number of items in transactions
const mx_depth = 7
t = [sample(itemlist, m, replace = false) for _ in 1:n];

# @code_warntype _frequent(t, 1)
const unq2 = unique_items(t)
# @benchmark occ2 = occurrence(t, unq2)
@time itree2 = frequent_item_tree(t, unq2, round(Int, 0.01*n), mx_depth);

Profile.clear_malloc_data()
itree2 = frequent_item_tree(t, unq2, round(Int, 0.01*n), mx_depth)


# ARules.shownodes(itree2)
