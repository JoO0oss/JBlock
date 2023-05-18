project_centre = 0, 0
project_scale = 1.0

PROJECTION_Z_EPSILON = 0.2

""" An integral 3D point. """
IntPoint = Tuple{Int, Int, Int}
""" A 3D point with [up to] floating point coordinates. """
RealPoint = Tuple{Real, Real, Real}
""" A 3D point with direction data (x, y, z, pitch, yaw). """
CameraPoint = Tuple{Real, Real, Real, Real, Real}

""" Initialise the projection system, given the screen width and height. """
function project_init(screen_width::Int, screen_height::Int)
    global project_centre, project_scale

    project_centre = screen_width ÷ 2, screen_height ÷ 2
    project_scale = 0.5*√(screen_width * screen_height)  # Geometric mean of the two dimensions.
end

""" Project a 3D point onto 2D space. Point is of the form `(x, y, z)`, camera is of the form `(x, y,
z, pitch, yaw)`.

Returns the projected location of the point, including "depth" into the screen. """
function project_project(point::RealPoint, camera::CameraPoint)::RealPoint
    # Remember +ve z comes *out* of the screen.
    px, py, pz = point
    cx, cy, cz, θv, θh = camera

    # Offset by camera position.
    px = px - cx
    py = py - cy
    pz = pz - cz


    # Clockwise rotation around the vertical axis.
    horizontal_plane_rotation = [cos(θh) sin(θh); -sin(θh) cos(θh)]
    px, pz = horizontal_plane_rotation * [px; pz]

    # Rotation around the horizontal axis normal to the player's direction (+ve θv moves it up).
    vertical_plane_rotation = [cos(θv) sin(θv); -sin(θv) cos(θv)]
    py, pz = vertical_plane_rotation * [py; pz]

    # Project to perspective.
    px /= -pz
    py /= -pz

    return px, py, pz
end

""" Check if a now projected point comes "out of the screen"."""
function project_behindcamera(points::Array{Tuple{Float64, Float64, Float64}, 1})::Bool
    return any(map(project_behindcamera, points))
end

""" Check if a now projected point comes "out of the screen"."""
function project_behindcamera(point::Tuple{Float64, Float64, Float64})::Bool
    return point[3] > PROJECTION_Z_EPSILON
end

""" Translate a point centered on `(0, 0)` where 1 is 1 world unit to a pixel centered on the middle
of the screen where 1 is a pixel - and ~600 is one world unit, or whatever `project_scale` is set to
by `project_init()`. """
function project_translate(point::Tuple{Real, Real}, fov_scale::Float64=2.0)::Tuple{Int, Int}
    # Flip the y axis because the TOP of the screen is y0, the bottom of the screen is y~600.
    x, y = point .* (1, -1) .* (project_scale * fov_scale) .+ project_centre
    return round(x), round(y)
end

""" Take 1 (integral) 3D point and return 8 points, one for each corner of the cube.

Each point, `vertices[2n-1]`, is the x axis mirrored point of `vertices[2n]`;
each point, `vertices[n={1,2,5,6}]`, is the y axis mirror to `vertices[n+2]`
and each point `vertices[n={1-4}]` is the z axis mirror to `vertices[n+4]`.


*ie*:

p1 = (x1, y1, z1)

p2 = (x2, y1, z1)

p3 = (x1, y2, z1)

p4 = (x2, y2, z1)

p5 = (x1, y1, z2)

p6 = (x2, y1, z2)

p7 = (x1, y2, z2)

p8 = (x2, y2, z2)"""
function project_tocube(point::IntPoint)::Array{IntPoint, 1}
    x, y, z = point
    
    return [(x, y, z),
            (x + 1, y, z),
            (x, y + 1, z),
            (x + 1, y + 1, z),
            (x, y, z + 1),
            (x + 1, y, z + 1),
            (x, y + 1, z + 1),
            (x + 1, y + 1, z + 1)]
end