# rule_generation.jl


struct Rule
    p::Array{Int16,1}
    q::Int16
    supp::Float64
    conf::Float64
    lift::Float64

    function Rule(node::Node, lhs_keep::BitArray{1}, supp_dict::Dict{Array{Int16,1}, Int}, num_transacts::Int)
        p = node.item_ids[lhs_keep]
        supp = node.supp/num_transacts
        conf = node.supp/supp_dict[node.item_ids[lhs_keep]]
        rhs_keep = .!lhs_keep
        q_idx = findfirst(rhs_keep)
        q = node.item_ids[q_idx]
        lift = conf/supp_dict[node.item_ids[rhs_keep]]

        rule = new(p, q, supp, conf, lift)
        return rule
    end
end


function update_support_cnt!(supp_dict::Dict, nd::Node)
    supp_dict[nd.item_ids] = nd.supp
end


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
    lhs_keep = trues(k)
    rules = Array{Rule, 1}(k)
    for i = 1:k
        lhs_keep[i] = false
        if i > 1
            lhs_keep[i-1] = true
        end
        rules[i] = Rule(node, lhs_keep, supp_dict, num_transacts)
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
            gen_rules!(rules, root.children[i], supp_dict, 2, num_transacts)
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
    uniq_items = unique_items(transactions)
    item_lkup = Dict{Int16, String}()
    for (i, itm) in enumerate(uniq_items)
        item_lkup[i] = itm
    end

    freq_tree = frequent_item_tree(transactions, uniq_items, floor(Int, supp * n), maxdepth)
    supp_lkup = gen_support_dict(freq_tree, n)
    rules = gen_rules(freq_tree, supp_lkup, n)
    rules_dt = rules_to_datatable(rules, item_lkup)
    return rules_dt
end
