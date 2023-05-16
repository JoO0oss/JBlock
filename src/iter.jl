""" Create an iterator that iterates over a range, starting at the centre. """
function iter_centred(range::AbstractVector, centre_index::Int)
    if centre_index < 1 || centre_index > length(range)
        throw(ArgumentError("Centre index must be within range."))
    end

    ind = centre_index
    iterer = []
    while 0 < ind <= length(range)
        push!(iterer, range[ind])
        if ind <= centre_index
            ind += 2 * (centre_index - ind) + 1
        else
            ind -= 2 * (ind - centre_index)
        end
    end

    # If ind went past the end, then add the rest of the beginning.
    if ind > length(range)
        ind -= 2 * (ind - centre_index)
        append!(iterer, reverse(range[1:ind]))  # Remember, bits before centre_index come in reverse order.
    
    # If ind went past the beginning, then add the rest of the end.
    else
        ind += 2 * (centre_index - ind) + 1
        append!(iterer, range[ind:end])
    end

    return iterer
end