# rule_generation.jl


struct Rule
    p::Array{Int16,1}
    q::Int16
    supp::Float64
    conf::Float64
    lift::Float64
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
function gen_node_rules(node::Node, supp_dict::Dict{Array{Int16,1}, Int}, k, num_transacts, minconf)
    lhs_keep = trues(k)
    rules = Array{Rule, 1}(undef, 0)
    for i = 1:k
        lhs_keep[i] = false
        if i > 1
            lhs_keep[i-1] = true
        end
        p = node.item_ids[lhs_keep]
        supp = node.supp/num_transacts
        # for debugging
        if supp == 0.0
            warn("zero supp for: ", node.item_ids)
            return rules            # NOTE: returning early if zero support
        else
            conf = supp/((supp_dict[node.item_ids[lhs_keep]])/num_transacts)
            if conf ≥ minconf
                rhs_keep = .!lhs_keep
                q = first(node.item_ids[rhs_keep])
                lift = conf/((supp_dict[node.item_ids[rhs_keep]])/num_transacts)

                rule = Rule(p, q, supp, conf, lift)
                push!(rules, rule)
            end
        end
    end
    rules
end


function gen_rules!(rules::Array{Rule, 1}, node::Node, supp_dict::Dict{Array{Int16, 1}, Int}, k, num_transacts, minconf)
    m = length(node.children)

    for child in node.children
        rules_tmp = gen_node_rules(child, supp_dict, k, num_transacts, minconf)
        append!(rules, rules_tmp)
        if !isempty(child.children)
            gen_rules!(rules, child, supp_dict, k+1, num_transacts, minconf)
        end
    end
end


function gen_rules(root::Node, supp_dict::Dict{Array{Int16, 1}, Int}, num_transacts, minconf)
    rules = Array{Rule, 1}(undef, 0)
    n_kids = length(root.children)
    if n_kids > 0
        for i = 1:n_kids
            gen_rules!(rules, root.children[i], supp_dict, 2, num_transacts, minconf)
        end
    end
    rules
end


function rules_to_dataframe(rules::Array{Rule, 1}, item_lkup::Dict{T, S}; join_str = " | ") where {T <: Integer, S}
    n_rules = length(rules)
    dt = DataFrame(lhs = fill("", n_rules),
                   rhs = fill("", n_rules),
                   supp = zeros(n_rules),
                   conf = zeros(n_rules),
                   lift = zeros(n_rules))
    for i = 1:n_rules
        lhs_items = map(x -> string.(item_lkup[x]), rules[i].p)

        lhs_string = "{" * join(lhs_items, join_str) * "}"
        dt[i, :lhs] = lhs_string
        dt[i, :rhs] = string.(item_lkup[rules[i].q])
        dt[i, :supp] = rules[i].supp
        dt[i, :conf] = rules[i].conf
        dt[i, :lift] = rules[i].lift
    end
    dt
end


"""
    apriori(transactions; supp, conf, maxlen)
Given an array of transactions (a vector of string vectors), this function runs the a-priori
algorithm for generating frequent item sets. These frequent items are then used to generate
association rules. The `supp` argument allows us to stipulate the minimum support
required for an itemset to be considered frequent. The `conf` argument allows us to exclude
association rules without at least `conf` level of confidence. The `maxlen` argument stipulates
the maximum length of an association rule (i.e., total items on left- and right-hand sides)
"""
function apriori(transactions::Array{Array{S, 1}, 1}; supp::Float64 = 0.01, conf = 0.8, maxlen::Int = 5) where S
    n = length(transactions)
    uniq_items = unique_items(transactions)
    item_lkup = Dict{Int16, S}()
    for (i, itm) in enumerate(uniq_items)
        item_lkup[i] = itm
    end
    minsupp = floor(Int, supp * n)
    if minsupp == 0
        minsupp += 1
    end
    freq_tree = frequent_item_tree(transactions, uniq_items, minsupp, maxlen)
    supp_lkup = gen_support_dict(freq_tree, n)
    rules = gen_rules(freq_tree, supp_lkup, n, conf)
    rules_dt = rules_to_dataframe(rules, item_lkup)
    return rules_dt
end


"""
apriori(occurrences, item_lkup; supp, conf, maxlen)

Given an boolean occurrence matrix of transactions (rows are transactions, columns are items) and
a lookup dictionary of column-index to items-string, this function runs the a-priori
algorithm for generating frequent item sets. These frequent items are then used to generate
association rules. The `supp` argument allows us to stipulate the minimum support
required for an itemset to be considered frequent. The `conf` argument allows us to exclude
association rules without at least `conf` level of confidence. The `maxlen` argument stipulates
the maximum length of an association rule (i.e., total items on left- and right-hand sides)
"""
function apriori(occurrences::BitArray{2}; supp::Float64 = 0.01, conf = 0.8, maxlen::Int = 5)
    n = size(occurrences, 1)
    minsupp = floor(Int, supp * n)
    if minsupp == 0
        minsupp = 1
    end
    freq_tree = frequent_item_tree(occurrences, minsupp, maxlen)
    supp_lkup = gen_support_dict(freq_tree, n)
    rules = gen_rules(freq_tree, supp_lkup, n, conf)

    return rules
end
