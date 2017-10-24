module ARules
using DataTables

export Node, Rule, apriori, frequent, unique_items, shownodes,     
# these below are for pilotting
       frequent_item_tree, randstr, frequent_item_tree4


include("frequent_itemset_tree.jl")
include("utils.jl")
include("rule_generation.jl")


# package code goes here

end # module
