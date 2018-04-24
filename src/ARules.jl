module ARules
using DataFrames

export Node, Rule, apriori, frequent, unique_items, shownodes,
       # these below are for pilotting
       has_children, younger_siblings, growtree!, randstr, occurence, gen_support_dict, frequent_item_tree,
       gen_rules!, gen_rules, gen_node_rules, occurrence


include("frequent_itemset_tree.jl")
include("utils.jl")
include("rule_generation.jl")


# package code goes here

end # module
