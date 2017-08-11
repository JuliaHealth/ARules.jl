# rule_generation.jl 


function grow_support_dict!(supp_cnt::Dict{Array{Int16,1}, Int}, node::Node) 
    if has_children(node)
        for nd in node.children
            update_support_cnt!(supp_cnt, nd)
            grow_support_dict!(supp_cnt, nd)
        end
    end
end

# This function generates a dictionary whose keys are the frequent 
# itemsets (their integer represenations, actually), and whose values 
# are the support count for the given itemset. This function is used 
# for computing support, confidence, and lift of association rules.
function gen_support_dict(root::Node, num_transacts)
    supp_cnt = Dict{Array{Int16, 1}, Int}()
    supp_cnt[Int16[]] = num_transacts
    grow_support_dict!(supp_cnt, root)
    return supp_cnt 
end


# Given a single node in a frequent item tree, this function generates all the 
# rules for that node. This does not include rules for the node's children.
function gen_node_rules(node::Node, supp_dict::Dict{Array{Int16,1}, Int}, k, num_transacts)
    mask = trues(k)
    rules = Array{Rule, 1}(k)
    for i = 1:k 
        mask[i] = false 
        if i > 1 
            mask[i-1] = true 
        end
        rules[i] = Rule(node, mask, supp_dict, num_transacts)
    end
    rules 
end


function gen_rules!(rules::Array{Rule, 1}, node::Node, supp_dict::Dict{Array{Int16, 1}, Int}, k, num_transacts)
    for child in node.children 
        rules_tmp = gen_node_rules(child, supp_dict, k, num_transacts)
        append!(rules, rules_tmp)
        if !isempty(child.children)
            gen_rules!(rules, child, supp_dict, k+1, num_transacts)
        end
    end
end


function gen_rules(root::Node, supp_dict::Dict{Array{Int16, 1}, Int}, num_transacts)
    rules = Array{Rule, 1}(0)
    n_kids = length(root.children)
    if n_kids > 0
        for i = 1:n_kids 
            gen_rules!(rules, xtree1.children[i], xsup, 2, num_transacts)
        end 
    end 
    rules 
end 


function rules_to_datatable(rules::Array{Rule, 1}, item_lkup::Dict{Int16, String})
    n_rules = length(rules)
    dt = DataTable(lhs = fill("", n_rules), 
                   rhs = fill("", n_rules), 
                   supp = zeros(n_rules), 
                   conf = zeros(n_rules), 
                   lift = zeros(n_rules))
    for i = 1:n_rules 
        println(rules[i].p)
        lhs_items = map(x -> item_lkup[x], rules[i].p)
       
        lhs_string = "{" * join(lhs_items, ",") * "}"
        dt[i, :lhs] = lhs_string
        dt[i, :rhs] = item_lkup[rules[i].q]
        dt[i, :supp] = rules[i].supp
        dt[i, :conf] = rules[i].conf
        dt[i, :lift] = rules[i].lift
    end 
    dt 
end 



function apriori(transactions::Array{Array{String, 1}, 1}, supp::Float64, maxdepth::Int)
    n = length(transactions)
    uniq_items = get_unique_items(transactions)
    item_lkup = Dict{Int16, String}()
    for (i, itm) in enumerate(uniq_items)
        item_lkup[i] = itm 
    end 

    freq_tree = frequent(transactions, uniq_items, round(Int, supp * n), maxdepth)
    supp_lkup = gen_support_dict(freq_tree, n)
    rules = gen_rules(freq_tree, supp_lkup, n)
    rules_dt = rules_to_datatable(xrules, item_lkup)
    return rules_dt 
end 




# function compute_metrics(root::Node)
#     # supp_dict = gen_support_dict(root)
# end

# function get_cousins(node::Node)
#     cousins = Array{Node,1}(0)
#     if isdefined(node, :mother) && isdefined(node.mother, :mother) 
#         for aunt in younger_siblings(node.mother)
#             for nd in aunt.children
#                 push!(cousins, nd)
#             end
#         end
#     end
#     cousins
# end

# get_cousins(xtree1.children[1])

