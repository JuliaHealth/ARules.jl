var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "#ARules.jl-1",
    "page": "Home",
    "title": "ARules.jl",
    "category": "section",
    "text": "A Julia package for mining Association Rules.pages = [\n    \"Guide\" => \"usage.md\",\n    \"API\" => \"documentation.md\"\n    ]"
},

{
    "location": "#Quick-Notes:-1",
    "page": "Home",
    "title": "Quick Notes:",
    "category": "section",
    "text": "Compatible with julia 0.7 and 1.0"
},

{
    "location": "usage/#",
    "page": "Guide",
    "title": "Guide",
    "category": "page",
    "text": ""
},

{
    "location": "usage/#Usage-Guide-1",
    "page": "Guide",
    "title": "Usage Guide",
    "category": "section",
    "text": ""
},

{
    "location": "usage/#A-Rules-Algorithms-1",
    "page": "Guide",
    "title": "A Rules Algorithms",
    "category": "section",
    "text": ""
},

{
    "location": "documentation/#",
    "page": "API",
    "title": "API",
    "category": "page",
    "text": ""
},

{
    "location": "documentation/#ARules.apriori-Tuple{Array{Array{String,1},1}}",
    "page": "API",
    "title": "ARules.apriori",
    "category": "method",
    "text": "apriori(transactions; supp, conf, maxlen)\n\nGiven an array of transactions (a vector of string vectors), this function runs the a-priori algorithm for generating frequent item sets. These frequent items are then used to generate association rules. The supp argument allows us to stipulate the minimum support required for an itemset to be considered frequent. The conf argument allows us to exclude association rules without at least conf level of confidence. The maxlen argument stipulates the maximum length of an association rule (i.e., total items on left- and right-hand sides)\n\n\n\n\n\n"
},

{
    "location": "documentation/#ARules.apriori-Tuple{BitArray{2}}",
    "page": "API",
    "title": "ARules.apriori",
    "category": "method",
    "text": "apriori(occurrences, item_lkup; supp, conf, maxlen)\n\nGiven an boolean occurrence matrix of transactions (rows are transactions, columns are items) and  a lookup dictionary of column-index to items-string, this function runs the a-priori algorithm for generating frequent item sets. These frequent items are then used to generate association rules. The supp argument allows us to stipulate the minimum support required for an itemset to be considered frequent. The conf argument allows us to exclude association rules without at least conf level of confidence. The maxlen argument stipulates the maximum length of an association rule (i.e., total items on left- and right-hand sides)\n\n\n\n\n\n"
},

{
    "location": "documentation/#ARules.frequent-Union{Tuple{T}, Tuple{Array{Array{String,1},1},T,Any}} where T<:Real",
    "page": "API",
    "title": "ARules.frequent",
    "category": "method",
    "text": "frequent()\n\nThis function just acts as a bit of a convenience function that returns the frequent item sets and their support count (integer) when given and array of transactions. It basically just wraps frequentitemtree() but gives back the plain text of the items, rather than that Int16 representation.\n\n\n\n\n\n"
},

{
    "location": "documentation/#ARules.frequent_item_tree-Tuple{Array{Array{String,1},1},Array{String,1},Int64,Int64}",
    "page": "API",
    "title": "ARules.frequent_item_tree",
    "category": "method",
    "text": "frequent_item_tree(transactions, minsupp, maxdepth)\n\nThis function creates a frequent itemset tree from an array of transactions. The tree is built recursively using calls to the growtree!() function. The minsupp and maxdepth parameters control the minimum support needed for an itemset to be called \"frequent\", and the max depth of the tree, respectively\n\n\n\n\n\n"
},

{
    "location": "documentation/#ARules.frequent_item_tree-Tuple{BitArray{2},Int64,Int64}",
    "page": "API",
    "title": "ARules.frequent_item_tree",
    "category": "method",
    "text": "frequentitemtree(occurrences, minsupp, maxdepth)\n\nThis function creates a frequent itemset tree from an occurrence matrix. The tree is built recursively using calls to the growtree!() function. The minsupp and maxdepth parameters control the minimum support needed for an itemset to be called \"frequent\", and the max depth of the tree, respectively\n\n\n\n\n\n"
},

{
    "location": "documentation/#API-Reference-1",
    "page": "API",
    "title": "API Reference",
    "category": "section",
    "text": "Modules = [ARules]"
},

]}
