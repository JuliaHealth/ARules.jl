# This implements the first attempt at representing
# transactions as tree where each tree is a transaction.


struct TNode
    id::Int
    items::Array{Int, 1}
    children::Array{TNode, 1}
    parent::TNode

    function TNode(id::Int, items::Array{Int, 1})      # Only used for root node
        tnode = new(id, items, Array{TNode, 1}(0))
        return tnode
    end

    function TNode(id::Int, items::Array{Int, 1}, parent::TNode)
        tnode = new(id, items, Array{TNode}(0), parent)
        return tnode
    end
end


# TODO: Consider using immutable struct and
# using the one-element array trick to store
# `supp`, which is what necessitates mutability.
mutable struct INode
    items::Array{Int, 1}
    supp::Int

    function INode(item::Int, supp::Int)     # NOTE: only used on single-item cases
        inode = new()
        inode.items = [item]
        inode.supp = supp
        return inode
    end

    function INode(items::Array{Int, 1}, supp::Int)
        inode = new(items, supp)
        return inode
    end
end




function tnode_oldersibs(tnode::TNode)
    n_sibs = length(tnode.parent.children)
    older_indcs = (tnode.id + 1):n_sibs
    return view(tnode.parent.children, older_indcs)
end


function increment_itemset_supp!(itemset_arr::Array{INode, 1}, items::Array{Int, 1}, itemset_lkup::Dict{UInt64, Int})
    hashval = hash(items)
    if haskey(itemset_lkup, hashval)
        idx = itemset_lkup[hashval]
        itemset_arr[idx].supp += 1
    else
        inode = INode(items, 1)
        push!(itemset_arr, inode)
        idx = length(itemset_arr)       # length is new index for this itemset
        hashval = hash(items)
        itemset_lkup[hashval] = idx
    end
end



function add_tr_layer!(tnode::TNode, transaction, itemset_arr, itree_lkup, level, maxdepth)
    # assume sorted transaction with unique items
    # println("level :", level)
    if level == 1
        n_kids = length(transaction)
        for i = 1:n_kids
            node = TNode(i, [transaction[i]], tnode)
            increment_itemset_supp!(itemset_arr, node.items, itree_lkup)
            push!(tnode.children, node)
        end
    elseif 1 < level ≤ maxdepth
        if level == 2
            first_sib = tnode.id + 1
            n_items = length(transaction)
            older_sibs = view(transaction, first_sib:n_items)       # NOTE: gets indices of older sibs
        else
            older_sibs = tnode_oldersibs(tnode)
        end
        n_sibs = length(older_sibs)

        for i = 1:n_sibs
            # display(older_sibs)
            println(i)
            itemset = vcat(tnode.items, older_sibs[i])
            # display(itemset)
            node = TNode(i, itemset, tnode)
            increment_itemset_supp!(itemset_arr, node.items, itree_lkup)
            push!(tnode.children, node)

            add_tr_layer!(tnode.parent.children[i], t, itemset_tree, itree_lkup, level, maxdepth)
        end
    end
end

t = [1, 2, 3, 5, 6]

troot = TNode(0, Int[])
iroot = INode(Int[], 100_000_000)
itemset_tree = [iroot]
itree_lkup = Dict{UInt64, Int}()
@time add_tr_layer!(troot, t, itemset_tree, itree_lkup, 1, 2)
@time add_tr_layer!(troot.children[1], t, itemset_tree, itree_lkup, 2, 2)












# function grow_tr_tree!(tnode, transaction, level, maxdepth)
#     # assume sorted transaction with unique items
#     println("level :", level)
#     if level == 1
#         for i = 1:maxdepth
#             println(i)
#             prefix = transaction[i : level]
#             suffix = transaction[(level + i):end]
#             kids = Array{TNode, 1}(0)
#             node = TNode(prefix, suffix, kids)
#             push!(tr_node.children, node)
#             grow_tr_tree!(node, transaction, level + 1, maxdepth)
#         end
#     elseif level < maxdepth
#         n_suffixes = length(tr_node.suffix_items)
#         for i = 1:n_suffixes
#             println(i)
#             prefix = transaction[i : level]
#             suffix = transaction[(level + i):end]
#             kids = Array{TNode, 1}(0)
#             node = TNode(prefix, suffix, kids)
#             push!(tr_node.children, node)
#             grow_tr_tree!(node, transaction, level + 1, maxdepth)
#         end
#     elseif level == maxdepth
#         n_itemsets = length(tr_node.suffix_items)
#         # println(tr_node.suffix_items)
#         res = Array{Array{Int, 1}, 1}(n_itemsets)
#         for i = 1:n_itemsets
#             # println("i inner: ", i)
#             # println(res)
#             res[i] = vcat(tr_node.prefix_items, tr_node.suffix_items[i])
#         end
#         println(res)
#         return res
#     end
# end
#
#
# t = [1, 2, 3, 5, 6]
#
# n1 = TNode(Int[], Int[], TNode[])
#
# @time grow_tr_tree!(n1, t, 1, 3)
#
