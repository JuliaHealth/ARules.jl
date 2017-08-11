module ARules

include("frequent_itemset_tree.jl")
include("rules.jl")
include("utils.jl")

export Node, 
       Rule, 
       apriori, 
       frequent,
       get_unique_items,
       shownodes

# package code goes here

end # module
