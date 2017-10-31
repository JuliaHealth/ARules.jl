using Revise
using ARules

using StatsBase
using BenchmarkTools

itemlist = randstr(10);
n = 50   #ntransactions
m = 5   #number of items in transactions
mx_depth = 3
minsupp = round(Int, 0.1*n)
transactions = [sample(itemlist, m, replace = false) for _ in 1:n];
uniq_items = unique_items(transactions);
occ = ARules.occurrence(transactions, uniq_items);
occ_t = Array(occ');

# warm-up 
@time tree = frequent_item_tree(occ, minsupp, mx_depth);
# tree4 = frequent_item_tree4(occ, uniq_items, minsupp, mx_depth);
# @time tree6 = ARules.frequent_item_tree6(occ, minsupp, mx_depth);
# @time tree7 = ARules.frequent_item_tree7(occ, minsupp, mx_depth);
@time tree8 = ARules.frequent_item_tree8(occ_t, minsupp, mx_depth);

shownodes(tree)
shownodes(tree8)

# tree5 = ARules.frequent_item_tree5(occ_sp, uniq_items, minsupp, mx_depth);

#benchmark
itemlist = randstr(100);
n = 100_000
m = 25           # number of items in transactions
mx_depth = 7
minsupp = round(Int, 0.01*n)
transactions = [sample(itemlist, m, replace = false) for _ in 1:n];
uniq_items = unique_items(transactions);
occ = ARules.occurrence(transactions, uniq_items);
occ_t = Array(occ');
Profile.clear_malloc_data()

@profile tree = frequent_item_tree(occ, minsupp, mx_depth);
# @time tree4 = frequent_item_tree4(occ, uniq_items, minsupp, mx_depth);
# @time tree6 = ARules.frequent_item_tree6(occ, minsupp, mx_depth);
# @time tree7 = ARules.frequent_item_tree7(occ, minsupp, mx_depth);
@time tree8 = ARules.frequent_item_tree8(occ_t, minsupp, mx_depth);



@time ARules.frequent_item_tree7(occ, minsupp, mx_depth);
Profile.clear_malloc_data()
@profile ARules.frequent_item_tree8(occ_t, minsupp, mx_depth)
Profile.print()


shownodes(tree)
shownodes(tree7)

#10 seconds, 2.232 GiBP


# occ_sp = sparse(occ);

# Profile.clear_malloc_data()
# @time tree5 = ARules.frequent_item_tree5(occ_sp, uniq_items, minsupp, mx_depth);

# tree4 = frequent_item_tree4(transactions, uniq_items, minsupp, mx_depth);
# Profile.clear_malloc_data()
# @time tree4 = frequent_item_tree4(transactions, uniq_items, minsupp, mx_depth);

# # @benchmark occ2 = occurrence(t, unq2)
# itree2 = frequent_item_tree(transactions, uniq_items, minsupp, mx_depth);
# Profile.clear_malloc_data()
# @time itree2 = frequent_item_tree(transactions, uniq_items, minsupp, mx_depth);

# Profile.clear_malloc_data()
# itree2 = frequent_item_tree(t, unq2, round(Int, 0.01*n), mx_depth)


# ARules.shownodes(itree2)


# occ = ARules.occurrence(transactions, uniq_items)

# level = 1
# node_dict = Dict{Int16, Vector{Vector{Node4}}}(level=> [Vector{Node4}()])
# nitems = size(occ, 2)
# # This loop creates 1-item nodes (i.e., first children)
# # If item doesn't have support do not insert
# for j = 1:nitems
#     supp = sum(occ[:, j])
#     if supp ≥ minsupp
#         nd = Node4(Int16(j), Int16[j], view(occ, :, j), 0, supp)
#         push!(node_dict[level][1], nd)
#     end
# end

# nitems_level1 = length(node_dict[1][1]) #Careful! True if root is not added
# narrays_level1 = length(node_dict[1])

# # Loop to create the 2-item nodes 
# # If item doesn't have support insert empty array (to keep children access in dict)
# level = 2 #level of singles
# node_dict[level] = Vector{Vector{Node4}}()
# for item_idx = 1:nitems_level1
#     #transaction ids for this node
#     push!(node_dict[level], Vector{Node4}())
#     node_item_ids = node_dict[level - 1][1][item_idx].item_ids
#     node_ti = node_dict[level - 1][1][item_idx].transact_ids
#     for sib_idx = (item_idx+1):nitems_level1
#         #the item id may not be the same as the sib-idx because level filtered by support
#         sib_item_id = node_dict[level - 1][1][sib_idx].item_ids[end]
#         pair_transacts = view(occ, node_ti, sib_item_id)
#         pair_ti = view(node_ti, pair_transacts)
#         supp = length(pair_ti)
#         if supp ≥ minsupp
#             pair_item_ids = vcat(node_item_ids, sib_item_id)
#             nd = Node4(Int16(sib_idx), pair_item_ids, pair_ti, item_idx, supp)
#             push!(node_dict[level][item_idx], nd)
#         end
#     end
# end

# node_dict