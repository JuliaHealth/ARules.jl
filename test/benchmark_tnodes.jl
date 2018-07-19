include("/Users/pstey/projects_code/ARules/src/frequent_itemset_tree6.jl")

n = 50
m = 12                # NOTE: most impactful for runtime complexity (num. items in transactions)
mx_depth = 10        # max depth of itemset tree (max size of transactions explored)
t_arr = [sample(1:100, m, replace = false) for _ in 1:n];
t_arr = map(t -> sort!(t), t_arr)

itree2 = frequent_item_tree(t_arr, 1, mx_depth)

n = 100
m = 12                # NOTE: most impactful for runtime complexity (num. items in transactions)
mx_depth = 10        # max depth of itemset tree (max size of transactions explored)
t_arr = [sample(1:100, m, replace = false) for _ in 1:n];
t_arr = map(t -> sort!(t), t_arr)

Profile.clear_malloc_data()
itree2 = frequent_item_tree(t_arr, 1, mx_depth);
