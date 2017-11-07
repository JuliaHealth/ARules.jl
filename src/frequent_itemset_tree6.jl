# This implements the first attempt at representing
# transactions as tree where each tree is a transaction.
using StatsBase

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


function has_children(tnode)
    res = length(tnode.children) > 0
    return res
end

function tnode_oldersibs(tnode::TNode)
    n_sibs = length(tnode.parent.children)
    older_indcs = (tnode.id + 1):n_sibs
    return view(tnode.parent.children, older_indcs)
end


function increment_itemset_supp!(inode_arr::Array{INode, 1}, items::Array{Int, 1}, itemset_lkup::Dict{UInt64, Int})
    hashval = hash(items)
    if haskey(itemset_lkup, hashval)
        idx = itemset_lkup[hashval]
        inode_arr[idx].supp += 1
    else
        inode = INode(items, 1)
        push!(inode_arr, inode)
        idx = length(inode_arr)       # length is new index for this itemset
        hashval = hash(items)
        itemset_lkup[hashval] = idx
    end
end



function grow_tnode_children!(tnode::TNode, transaction, inode_arr, itree_lkup, level)
    # assume sorted transaction with unique items
    # println("level :", level)
    if level == 1
        n_kids = length(transaction)
        for i = 1:n_kids
            node = TNode(i, [transaction[i]], tnode)
            increment_itemset_supp!(inode_arr, node.items, itree_lkup)
            push!(tnode.children, node)
        end
    elseif level > 1
        if level == 2
            first_sib = tnode.id + 1
            n_items = length(transaction)
            older_sibs = view(transaction, first_sib:n_items)
        else
            older_sibs = tnode_oldersibs(tnode)
        end
        n_sibs = length(older_sibs)
        # display(older_sibs)
        for i = 1:n_sibs

            # println(i)
            if level == 2
                itemset = vcat(tnode.items, older_sibs[i])
            elseif level > 2
                itemset = vcat(tnode.items, older_sibs[i].items[end])
            end
            # display(itemset)
            node = TNode(i, itemset, tnode)
            increment_itemset_supp!(inode_arr, node.items, itree_lkup)
            push!(tnode.children, node)
        end
    end
end

t = [1, 2, 3, 5, 6]

troot = TNode(0, Int[])
iroot = INode(Int[], 100_000_000)
itemset_tree = [iroot]
itree_lkup = Dict{UInt64, Int}()
@time grow_tnode_children!(troot, t, itemset_tree, itree_lkup, 1)
@time grow_tnode_children!(troot.children[1], t, itemset_tree, itree_lkup, 2)


function add_tnode_level!(root, transaction, inode_arr, itree_lkup, level)
    if level == 1
        grow_tnode_children!(root, transaction, inode_arr, itree_lkup, level)
    elseif level > 1 && has_children(root)
        current_layer = length(root.children[1].items)
        n_kids = length(root.children)
        if current_layer == (level - 1)
            for i = 1:n_kids
                grow_tnode_children!(root.children[i], transaction, inode_arr, itree_lkup, level)
            end
        else
            for i = 1:n_kids
                add_tnode_level!(root.children[i], transaction, inode_arr, itree_lkup, level)
            end
        end
    end
end

troot = TNode(0, Int[])
iroot = INode(Int[], 100_000_000)
itemset_tree = [iroot]
itree_lkup = Dict{UInt64, Int}()
@code_warntype add_tnode_level!(troot, t, itemset_tree, itree_lkup, 1)
@time add_tnode_level!(troot, t, itemset_tree, itree_lkup, 2)




function grow_tnodes_arr!(transactions, tnode_arr, inode_arr, itree_lkup, level)
    n = length(tnode_arr)
    if level == 1
        for i = 1:n
            tnode_arr[i] = TNode(0, Int[])

            add_tnode_level!(tnode_arr[i], transactions[i], inode_arr, itree_lkup, level)
        end
    elseif level > 1
        for i = 1:n
            add_tnode_level!(tnode_arr[i], transactions[i], inode_arr, itree_lkup, level)
        end
    end
end


function build_tnode_arr(transactions::Array{Array{Int, 1}, 1}, inode_arr, itree_lkup)
    n = length(transactions)
    tnode_arr = Array{TNode, 1}(n)
    grow_tnodes_arr!(transactions, tnode_arr, inode_arr, itree_lkup, 1)
    return tnode_arr
end


function frequent_item_tree(transactions, minsupp, maxdepth)
    itree_lkup = Dict{UInt64, Int}()
    n = length(transactions)
    iroot = INode(Int[], n)
    inode_arr = [iroot]
    tnode_arr = build_tnode_arr(transactions, inode_arr, itree_lkup)
    for i = 2:maxdepth
        grow_tnodes_arr!(transactions, tnode_arr, inode_arr, itree_lkup, i)
    end
    return inode_arr
end

t_arr = [[1, 2, 3, 5, 6], [2, 3, 4, 5], [5, 6]]

@time itree1 = frequent_item_tree(t_arr, 1, 3)

function pprint(itree_arr)
    n = length(itree_arr)
    for i = 1:n
        println("Node: ", itree_arr[i].items, " support: ", itree_arr[i].supp)
    end
end

pprint(itree1)




n = 50
m = 4                # NOTE: most impactful for runtime complexity (num. items in transactions)
mx_depth = 3        # max depth of itemset tree (max size of transactions explored)
t_arr = [sample(1:10, m, replace = false) for _ in 1:n];
t_arr = map(t -> sort!(t), t_arr)


@time itree1 = frequent_item_tree(t_arr, 1, mx_depth)
pprint(itree1)




n = 1000
m = 12                # NOTE: most impactful for runtime complexity (num. items in transactions)
mx_depth = 10        # max depth of itemset tree (max size of transactions explored)
t_arr = [sample(1:100, m, replace = false) for _ in 1:n];
t_arr = map(t -> sort!(t), t_arr)


@time itree2 = frequent_item_tree(t_arr, 1, mx_depth)
pprint(itree2)
