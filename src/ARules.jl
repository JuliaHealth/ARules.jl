module ARules

using StatsBase 
using DataTables 

include("frequent_itemset_tree.jl")
include("utils.jl")
include("rule_generation.jl")

export Node, Rule, apriori, frequent, get_unique_items, shownodes, 
       # these below are for pilotting
       has_children, younger_siblings, growtree!, rands, occurence, gen_support_dict,
       gen_rules!, gen_rules, gen_node_rules!

# package code goes here

end # module
