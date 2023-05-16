module func_type
    @enum FuncType x_equals=1 y_equals=2
end
module equality_type
    @enum EqualityType equal_to=1 greater_than=2 less_than=3
end


EQUATION_ε = 0.01  # Epsilon for how close δx is for it to be considered a vertical line.

""" An object representing a straight line equation. """
mutable struct Equation
    """ Whether the variable on the left hand side is x=a+by or y=a+bx. """
    variable::func_type.FuncType
    """ The gradient of the line (according to the appropriate variable). """
    gradient::Float64
    """ The intercept of the line (through the axis specified in `variable`). """
    intercept::Float64
    """ Whether the line is equal to, greater than or less than the other variable. """
    equality::equality_type.EqualityType
end

""" Create a straight line equation that goes through the two supplied points. """
function Equation(p1::Tuple{Float64, Float64}, p2::Tuple{Float64, Float64})::Equation
    x1, y1 = p1
    x2, y2 = p2

    if abs(x1 - x2) > EQUATION_ε
        # Most cases.
        gradient = (y2 - y1) / (x2 - x1)
        intercept = y1 - gradient * x1

        return Equation(func_type.y_equals, gradient, intercept, equality_type.equal_to)
    else
        # When it's really steep.
        gradient = (x2 - x1) / (y2 - y1)
        intercept = x1 - gradient * y1

        return Equation(func_type.x_equals, gradient, intercept, equality_type.equal_to)
    end
end

# Just a version to accept integers into the constructor written above.
""" Create a straight line equation that goes through the two supplied points. """
function Equation(p1::Tuple{Int, Int}, p2::Tuple{Int, Int})::Equation
    x1, y1 = p1
    x2, y2 = p2

    return Equation((float(x1), float(y1)), (float(x2), float(y2)))
end

""" Set which inequality the line is (i.e. `x < ...`, `x > ...`, `y < ...`, `y > ...`) by supplying a point
asserting which side of the line it is. """
function assert_inequality!(equation::Equation, point::Tuple{Real, Real}, satisfies_inequality::Bool)
    x, y = point
    is_greater_than = false

    if equation.variable == func_type.y_equals
        is_greater_than = y > equation.gradient * x + equation.intercept
    else
        is_greater_than = x > equation.gradient * y + equation.intercept
    end

    # These seems complicated but it's just 4 cases to make inequality and is_greater_than match up in `equation`.
    if is_greater_than
        if satisfies_inequality
            equation.equality = equality_type.greater_than
        else
            equation.equality = equality_type.less_than
        end
    else  # is less than
        if satisfies_inequality
            equation.equality = equality_type.less_than
        else
            equation.equality = equality_type.greater_than
        end
    end
end

""" Get whether a point is "in" the equality (i.e. it is on the same side of the line as the pointdefining the inequality). """
function get_inequality(equation::Equation, point::Tuple{Real, Real})::Bool
    # Make sure the line has an inequality to compare the point on.
    if equation.equality == equality_type.equal_to
        error("Error, cannot evaluate whether a point is within inequality because no inequality has been set (currently set to equal_to (==)).")
    end

    x, y = point

    if equation.variable == func_type.y_equals
        if y > equation.gradient * x + equation.intercept
            # In this case, y > x so if the inequality is also y > x, return true, otherwise false.
            return equation.equality == equality_type.greater_than
        else
            return equation.equality == equality_type.less_than
        end
    else
        if x > equation.gradient * y + equation.intercept
            return equation.equality == equality_type.greater_than
        else
            return equation.equality == equality_type.less_than
        end
    end
end

""" Given a line designated by two points, return true if `line` divides `point1` and `point2`. """
function split_by_line(line::Tuple{Tuple{Real, Real}, Tuple{Real, Real}}, point1::Tuple{Real, Real}, point2::Tuple{Real, Real})::Bool
    # I'm not sure why point1 needs the <: in front of real because it is a Tuple so it should allow subtypes, but never mind.
    equation = Equation(line[1], line[2])

    assert_inequality!(equation, point1, true)
    return !get_inequality(equation, point2)
end

""" Get the angle above the x-axis of the line between two points.
(I think..., this function is just a wrapper for `Base.angle()`.) """
function get_angle(anchor::Tuple{Real, Real}, target::Tuple{Real, Real})::Real
    Δx, Δy = target[1] - anchor[1], target[2] - anchor[2]
    return angle(Δx + im * Δy)
end

""" Returns true if the point is within the polygon (it must be convex). """
function point_within(point::Tuple{Real, Real}, polygon::Vector{<:Tuple{Real, Real}})::Bool
    # Reorder the points so that they go round the polygon in a clockwise direction.

    point_num = length(polygon)
    polygon_centre = sum([[x, y] for (x, y) in polygon]) / point_num  # Get the points as arrays to allow `sum()` to work.
    polygon_centre = tuple(polygon_centre...)  # Turn it back into a tuple.

    polygon = sort(polygon, by=(p) -> get_angle(polygon_centre, p))

    for i in eachindex(polygon)
        line = (polygon[i], polygon[(i%point_num) + 1])

        # We know that polygon_centre is somewhere within the polygon, so if `point` is not on the
        # same side of all edges as `polygon_centre`, it must be outside the polygon.
        if split_by_line(line, polygon_centre, point)
            return false
        end
    end

    return true
end