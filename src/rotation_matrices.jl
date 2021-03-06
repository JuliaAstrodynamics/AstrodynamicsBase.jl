export rotation_matrix, rate_matrix

axes_numbers(axes) = replace(replace(replace(lowercase(axes), "x"=>"1"), "y"=>"2"), "z"=>"3")

function rotation_axes(ord::AbstractString)
    if !occursin(r"^[xzy]{3}$|^[123]{3}$", lowercase(ord))
        throw(ArgumentError("Rotation axes must be indicated as a triple of either X, Y, Z or 1, 2, 3."))
    end

    order = axes_numbers(ord)

    if length(order) == 3 && (order[1] == order[2] || order[2] == order[3])
        throw(ArgumentError("Subsequent rotations around the same axis are meaningless."))
    end
    parse(Int, order[1]), parse(Int, order[2]), parse(Int, order[3])
end

isinvalid(x) = x < 1 || x > 3

function rotation_axes(ord::Int)
    ord = abs(ord)
    ax1 = trunc(Int, ord/100)
    ax2 = trunc(Int, (ord-100ax1)/10)
    ax3 = ord - 100ax1 - 10ax2
    if any(isinvalid.((ax1, ax2, ax3)))
        throw(ArgumentError("Rotation axes must be either 1, 2, or 3."))
    end

    if ax1 == ax2 || ax2 == ax3
        throw(ArgumentError("Subsequent rotations around the same axis are meaningless."))
    end
    ax1, ax2, ax3
end

function rotation_axis(axis::AbstractString)
    if !occursin(r"^[xzy123]$", lowercase(axis))
        throw(ArgumentError("Rotation axis must be indicated as either X, Y, Z or 1, 2, 3."))
    end
    parse(Int, axes_numbers(axis))
end

function rotation_matrix(order, angle1, angle2, angle3)
    ax1, ax2, ax3 = rotation_axes(order)
    rotation_matrix(ax3, angle3)*rotation_matrix(ax2, angle2)*rotation_matrix(ax1, angle1)
end

function rate_matrix(order, angle1, rate1, angle2, rate2, angle3, rate3)
    ax1, ax2, ax3 = rotation_axes(order)
    ((rate_matrix(ax3, angle3, rate3) * rotation_matrix(ax2, angle2) * rotation_matrix(ax1, angle1))
    + (rotation_matrix(ax3, angle3) * rate_matrix(ax2, angle2, rate2) * rotation_matrix(ax1, angle1))
    + (rotation_matrix(ax3, angle3) * rotation_matrix(ax2, angle2) * rate_matrix(ax1, angle1, rate1)))
end

rotation_matrix(axis::AbstractString, angle) = rotation_matrix(rotation_axis(axis), angle)

function rotation_matrix(axis::Int, angle)
    mat = zeros(3, 3)
    cosa = cos(angle)
    sina = sin(angle)
    if axis == 1
        mat[1,1] = 1
        mat[2,2] = cosa
        mat[2,3] = sina
        mat[3,2] = -sina
        mat[3,3] = cosa
    elseif axis == 2
        mat[1,1] = cosa
        mat[1,3] = sina
        mat[2,2] = 1
        mat[3,1] = -sina
        mat[3,3] = cosa
    elseif axis == 3
        mat[1,1] = cosa
        mat[1,2] = sina
        mat[2,1] = -sina
        mat[2,2] = cosa
        mat[3,3] = 1
    else
        throw(ArgumentError("'$axis' is not a valid rotation axis."))
    end
    return mat
end

function rate_matrix(axis::Int, angle, rate)
    mat = zeros(typeof(rate), 3, 3)
    cosa = cos(angle)
    sina = sin(angle)
    if axis == 1
        mat[2,2] = -rate * sina
        mat[2,3] = rate * cosa
        mat[3,2] = -rate * cosa
        mat[3,3] = -rate * sina
    elseif axis == 2
        mat[1,1] = -rate * sina
        mat[1,3] = rate * cosa
        mat[3,1] = -rate * cosa
        mat[3,3] = -rate * sina
    elseif axis == 3
        mat[1,1] = -rate * sina
        mat[1,2] = rate * cosa
        mat[2,1] = -rate * cosa
        mat[2,2] = -rate * sina
    else
        throw(ArgumentError("'$axis' is not a valid rotation axis."))
    end
    return mat
end

rate_matrix(axis::AbstractString, angle, rate) = rate_matrix(rotation_axis(axis), angle, rate)
