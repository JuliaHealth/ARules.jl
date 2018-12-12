import Base.show

function Base.show(io::IO, node::Node)
    id_string = ""
    for id in node.item_ids
        id_string *= string(id) * " "
    end

    print(rpad("", 2*length(node.item_ids)))
    print("Item IDs: ")
    print(rpad(id_string, 10))
    print("| Support: ")
    println(node.supp)

    return nothing
end

function Base.show(io::IO, tree::Tree)
    queue = Array{Node}(undef,0)
    push!(queue, tree.root)

    while length(queue) > 0
        curr = popfirst!(queue)
        append!(queue, curr.children)
        show(curr)
    end

    return nothing
end
