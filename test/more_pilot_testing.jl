using ARules


transactions = [["milk", "eggs", "bread"],
			    ["butter", "milk", "sugar", "flour", "eggs"],
			    ["bacon", "eggs", "milk", "beer"],
			    ["bread", "ham", "turkey"],
			    ["cheese", "ham", "bread", "ketchup"],
			    ["mustard", "hot dogs", "buns", "hamburger", "cheese", "beer"]]

# freq = frequent(transactions, 1, 8)
# display(freq)
#
# for x in freq[:itemset]
#     println(x)
# end

unq = unique_items(transactions)

@time node = ARules.frequent_item_tree(transactions, unq, 1, 8)

sup = gen_support_dict(node, 9)


for k in keys(sup)
    println(k)
end

rules = apriori(transactions, supp = 0.01, conf = 0.01, maxlen = 6)
showall(rules)
