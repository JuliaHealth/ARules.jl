using ARules

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

node = ARules._frequent(transactions, unq, 0.01, 6)
sup = gen_support_dict(node, 9)

for k in keys(sup)
    println(k)
end

rules = apriori(transactions, 0.1, 4)
display(rules)
