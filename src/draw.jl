if false
    #using SimpleDirectMediaLayer.LibSDL2
    include("maths.jl")
    include("iter.jl")
end

Import("maths.jl")
Import("iter.jl")

draw_world_width = 0
draw_world_height = 0
draw_world_depth = 0

draw_screen_size = (0, 0)
draw_screen_centre = (0, 0)

draw_dbg_info = Dict{String, Any}()


""" Initialise the drawing utilities, just a few integer parameters. """
function draw_init(world_width::Int, world_height::Int, world_depth::Int, screen_size::Tuple{Int, Int})
    global draw_world_width, draw_world_height, draw_world_depth
    global draw_screen_size
    global draw_screen_centre
    
    draw_world_width = world_width
    draw_world_height = world_height
    draw_world_depth = world_depth

    draw_screen_size = screen_size
    draw_screen_centre = screen_size .÷ 2
end

""" Debug information about the drawing process. """
function draw_get_dbg_info()
    return draw_dbg_info
end

""" Draw a diagonal cross with a radius of `width` around `centre`. """
function draw_cross(renderer::Ptr{SDL_Renderer}, centre::Tuple{Int, Int}, width::Int=5)
    x, y = centre
    draw_lines(renderer, [(x - width, y - width), (x + width, y + width)])
    draw_lines(renderer, [(x + width, y - width), (x - width, y + width)])
end

""" Draw joined up lines. """
function draw_lines(renderer::Ptr{SDL_Renderer}, lines::Vector{Tuple{Int, Int}})
    prev_pos = lines[1]
    poses = lines[2:end]

    for pos in poses
        SDL_RenderDrawLine(renderer, prev_pos[1], prev_pos[2], pos[1], pos[2])
        prev_pos = pos
    end
end

""" Draw the edges/frame of a supplied box.

This assumes `vertices` is an array of 8 points (already projected into 2 dimensions) making up the frame, where each point,
`vertices[2n-1]`, is the x axis mirrored point of `vertices[2n]`; each point,
`vertices[n={1,2,5,6}]`, is the y axis mirror to `vertices[n+2]` and each point `vertices[n={1-4}]`
is the z axis mirror to `vertices[n+4]`.


*ie*:

p1 = (x1, y1, z1)

p2 = (x2, y1, z1)

p3 = (x1, y2, z1)

p4 = (x2, y2, z1)

p5 = (x1, y1, z2)

p6 = (x2, y1, z2)

p7 = (x1, y2, z2)

p8 = (x2, y2, z2)
""" 
function draw_flat_box_frame(renderer::Ptr{SDL_Renderer}, vertices::Array{Tuple{Int, Int}, 1})
    p1, p2, p3, p4, p5, p6, p7, p8 = vertices
    SDL_RenderDrawLine(renderer, p1[1], p1[2], p2[1], p2[2]) # 1-2
    SDL_RenderDrawLine(renderer, p3[1], p3[2], p4[1], p4[2]) # 3-4
    SDL_RenderDrawLine(renderer, p1[1], p1[2], p3[1], p3[2]) # 1-3
    SDL_RenderDrawLine(renderer, p2[1], p2[2], p4[1], p4[2]) # 2-4

    SDL_RenderDrawLine(renderer, p5[1], p5[2], p6[1], p6[2]) # 5-6
    SDL_RenderDrawLine(renderer, p7[1], p7[2], p8[1], p8[2]) # 7-8
    SDL_RenderDrawLine(renderer, p5[1], p5[2], p7[1], p7[2]) # 5-7
    SDL_RenderDrawLine(renderer, p6[1], p6[2], p8[1], p8[2]) # 6-8

    SDL_RenderDrawLine(renderer, p1[1], p1[2], p5[1], p5[2]) # 1-5
    SDL_RenderDrawLine(renderer, p2[1], p2[2], p6[1], p6[2]) # 2-6
    SDL_RenderDrawLine(renderer, p3[1], p3[2], p7[1], p7[2]) # 3-7
    SDL_RenderDrawLine(renderer, p4[1], p4[2], p8[1], p8[2]) # 4-8

    draw_dbg_info["last_box_frame"] = vertices
end

""" Draw a box at the specified 3d coordinates. """
function draw_cube_frame(renderer::Ptr{SDL_Renderer}, box_x::Int, box_y::Int, box_z::Int, px::Float64, py::Float64, pz::Float64, θv::Float64, θh::Float64)
    cube_arr = project_tocube((box_x, box_y, box_z))  # Turn the block into an array of 8 vertices in 3D space.
    camera = (px, py, pz, θv, θh)

    projected_vertices_with_z = [project_project(point, camera) for point in cube_arr]
    projected_vertices = [(x, y) for (x, y, _) in projected_vertices_with_z]

    if project_behindcamera(projected_vertices_with_z)
        return
    end

    translated_vertices = map(project_translate, projected_vertices)

    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255)
    draw_flat_box_frame(renderer, translated_vertices)
end

""" Draw a convex quadrilateral. This will not work for concave shapes.

`corners` must have 4 points of the form, `(x::Int, y::Int)`. 

Returns whether the shape was successfully drawn."""
function draw_solid_convex_quad(renderer::Ptr{SDL_Renderer}, corners::Array{Tuple{Int, Int}})::Bool

    # Slightly cursed optimisation: the algorithm works by drawing each row, but sometimes it's
    # efficient to draw each column. Instead of rewriting the algorithm and rewriting all the
    # comments explaining everything, we could just swap x and y temporarily, so it thinks it's
    # still drawing rows.
    width = maximum(map(first, corners)) - minimum(map(first, corners))
    height = maximum(map(last, corners)) - minimum(map(last, corners))

    if width > 4*draw_screen_size[1] || height > 4*draw_screen_size[2]
        return false
    end

    swapped_coords = false
    if height > width
        corners = [(y, x) for (x, y) in corners]
        swapped_coords = true
    end


    sort!(corners, by=p->p[2]) # Sort by y value.

    
    # Sort out some edge cases that will cause NaNs and Infs to appear down the line due to division by zero.

    # If the top two points have the same y position.
    if corners[1][2] == corners[2][2]

        # Arrange the order in corners to artificially induce trap_shape=true below.

        # If corners[1] and corners[4] do not make up the long side of the "trapezium", swap
        # corners[1] and corners[2] so that corners[1] and corners[4] do make the long side.
        if split_by_line((corners[1], corners[4]), corners[2], corners[3])
            corners[1], corners[2] = corners[2], corners[1]
        end

        # If the top three points have the same y position, just draw a single line and be done.
        # On the off chance the last point isn't also the same y position, it will be 1 pixel off,
        # so ignore its y position.
        if corners[2][2] == corners[3][2]
            y = corners[1][2]
            x1 = minimum(map(first, corners))
            x2 = maximum(map(first, corners))

            SDL_RenderDrawLine(renderer, x1, y, x2, y)
            return true
        end
    end

    # If the bottom two points have the same y position.
    if corners[3][2] == corners[4][2]
        
        # Arrange the order in corners to artificially induce trap_shape=true below.
        if split_by_line((corners[1], corners[4]), corners[2], corners[3])
            corners[3], corners[4] = corners[4], corners[3]
        end

        # If the bottom three points have the same y position, just draw a single line and be done.
        if corners[2][2] == corners[3][2]
            y = corners[3][2]
            x1 = minimum(map(first, corners))
            x2 = maximum(map(first, corners))

            SDL_RenderDrawLine(renderer, x1, y, x2, y)
            return true
        end
    end


    # Corners are now in order, note that order is bias toward height, so if you have a corner
    # above everything and left of everything, it will count as the "top" point, then the next
    # least point x is the "left" point (assuming the very bottom isn't also to the left).

    top = corners[1]
    left = corners[2]
    right = corners[3]
    bottom = corners[4]

    # So called because these points are near the top/bottom but aren't quite. Sorry ;).
    op = corners[2]
    ottom = corners[3]

    # Swap left and right if they are the wrong way round for x position.
    if left[1] > right[1]
        left, right = right, left
    end


    trap_shape = !split_by_line((top, bottom), left, right) || top == op || bottom == ottom

        # The drawing algorithm draws lots of horizontal lines to make up the whole shape.
        # It has a "left track" and a "right track" to draw horizontal lines between, the left track
        # follows top->left->bottom and the right track follows top->right->bottom, those lines, a->b->c
        # make up the box frame of the quadrilateral, but obviously we want to fill in the space between.

        # The left and right tracks therefore assume the top point, a, an intermediate point, b, and
        # the bottom point, c to make up the track as a->b->c.

        #    a
        #    -
        #   ----
        # b-------
        #    -------b'
        #      ----
        #        -
        #        c


        # In the case where the two bs fall the same side of the line a->c,

        #  a
        #  ..
        #   ......
        #    .........     b
        #     ............
        #      ............
        #       ............
        #        ............
        #         ............
        #          ............
        #           ............ b'
        #            ..........
        #             ........
        #              ......
        #               ....
        #                ..
        #                 c
        
        # the right track would be made up of 3 parts and the left 1 (or vice versa).

    # That's just something to be aware of, that's what the variable trap_shape is for.


    top_y = top[2]
    bottom_y = bottom[2]


    left_x = 0  # Left track x position.
    right_x = 0  # Right track x position.

    for cur_y = top_y:bottom_y
        # "For each horizontal line..."
        
        if !trap_shape  # (In most cases)
            # Calculate left track's x position.
            if cur_y < left[2]  # a-b in the first diagram above.
                #          X               (ΔX         ÷         ΔY)         ×         Δcur_y
                left_x = top[1]  +  (top[1] - left[1]) / (top[2] - left[2])  *  (cur_y - top[2])
            else                # b-c
                left_x = left[1]  +  (left[1] - bottom[1]) / (left[2] - bottom[2])  *  (cur_y - left[2])
            end

            # Calculate right track's x position.
            if cur_y < right[2]  # a-b'
                right_x = top[1]  +  (top[1] - right[1]) / (top[2] - right[2])  *  (cur_y - top[2])
            else                 # b'-c
                right_x = right[1]  +  (right[1] - bottom[1]) / (right[2] - bottom[2])  *  (cur_y - right[2])
            end

        else  # Where the line topbottom_eq actually makes up one of the edges.
            left_x = top[1] + (top[1] - bottom[1]) / (top[2] - bottom[2]) * (cur_y - top[2])
            # Left and right aren't really relevant, so I'm just assuming left is the long edge.

            if cur_y <= op[2]       # a-b
                right_x = top[1] + (top[1] - op[1]) / (top[2] - op[2]) * (cur_y - top[2])
                
                if isnan(right_x)  # If Top and Left/Right exactly the same y level.
                    right_x = op[1]
                end
            elseif cur_y < ottom[2] # b-b'
                right_x = op[1] + (op[1] - ottom[1]) / (op[2] - ottom[2]) * (cur_y - op[2])

                if isnan(right_x)
                    println("shit.")
                end
            else                    # b'-c
                right_x = ottom[1] + (ottom[1] - bottom[1]) / (ottom[2] - bottom[2]) * (cur_y - ottom[2])

                if isnan(right_x)  # If Bottom and Right/Left exactly the same y level.
                    right_x = ottom[1]
                end
            end
        end

        try
            if !swapped_coords
                SDL_RenderDrawLine(renderer, round(left_x), round(cur_y), round(right_x), round(cur_y))
            else
                SDL_RenderDrawLine(renderer, round(cur_y), round(left_x), round(cur_y), round(right_x))
            end
        catch err
            println("\nFailed to draw quadrilateral. Stacktrace will follow information below:")
            println("trap_shape = ", trap_shape)
            println("corners = ", corners)
            println()

            rethrow(err)
        end

    end

    return true
end

""" Draw all the boxes in the world, as well as the frame showing what the cursor is pointing at. 

Returns 2 blocks, the block looked at (ie the block that would be broken) and the facing block (ie
the block that would be placed) in the form `(looking_at, placable)`.

If the player is not looking at any blocks, returns an emtpy tuple."""
function draw_world(renderer::Ptr{SDL_Renderer}, world::Array{Block, 3}, px::Float64, py::Float64, pz::Float64, θv::Float64, θh::Float64)::Union{Tuple{Tuple{Int, Int, Int}, Tuple{Int, Int, Int}}, Tuple{}}

    px_i = min(max( Int(floor(px)) , 1), draw_world_width)  # px Integer.
    py_i = min(max( Int(floor(py)) , 1), draw_world_height)
    pz_i = min(max( Int(floor(pz)) , 1), draw_world_depth)

    x_iter = reverse(iter_centred(1:draw_world_width, px_i))
    y_iter = reverse(iter_centred(1:draw_world_height, py_i))
    z_iter = reverse(iter_centred(1:draw_world_depth, pz_i))

    is_hovering = false
    selected_box = (0, 0, 0)  # The block that would be broken upon left click.
    facing_box = (0, 0, 0)  # The block that would be placed upon right click.

    dbg_face_count = 0  # Count of how many quadrilaterals have been drawn.
    
    # Convenience function to help check if neighbouring blocks are air (to see if faces should be rendered).
    function is_air(x, y, z)
        if 1 <= x <= draw_world_width && 1 <= y <= draw_world_height && 1 <= z <= draw_world_depth
            return world[x, y, z].type == block_type.Air
        else
            return true
        end
    end

    for tbx = x_iter, tby = y_iter, tbz = z_iter
        # Don't render invisible blocks.
        if world[tbx, tby, tbz].type == block_type.Air
            continue
        end

        cube_arr = project_tocube((tbx, tby, tbz))  # Turn the block into an array of 8 vertices in 3D space.
        camera = (px, py, pz, θv, θh)

        projected_vertices_with_z = [project_project(point, camera) for point in cube_arr]
        projected_vertices = [(x, y) for (x, y, _) in projected_vertices_with_z]

        if project_behindcamera(projected_vertices_with_z)
            continue
        end
        

        translated_vertices = map(project_translate, projected_vertices)

        
        colour_mod = ((((tbx + 2*tby + 4*tbz) ^ 2) % 7) % 20) - 10

        block_colour = block_colours[world[tbx, tby, tbz].type]
        block_colour_ll = block_colour .+ 15 .+ colour_mod
        block_colour_l = block_colour .+ 5 .+ colour_mod
        block_colour_d = block_colour .- 5 .+ colour_mod
        block_colour_dd = block_colour .- 15 .+ colour_mod

        SDL_SetRenderDrawColor(renderer, block_colour_dd..., 255)
        if py < tby && is_air(tbx, tby - 1, tbz)
            # Colour in the "bottom" face.
            if draw_solid_convex_quad(renderer, [translated_vertices[1], translated_vertices[2], translated_vertices[5], translated_vertices[6]])
                dbg_face_count += 1
                
                if point_within(draw_screen_centre, [translated_vertices[1], translated_vertices[2], translated_vertices[5], translated_vertices[6]])
                    is_hovering = true
                    selected_box = (tbx, tby, tbz)
                    facing_box = (tbx, tby - 1, tbz)
                    draw_dbg_info["selected_face"] = "bottom"
                    draw_dbg_info["selected_face_rendering_location"] = [translated_vertices[1], translated_vertices[2], translated_vertices[5], translated_vertices[6]]
                end
            end
        end
        
        SDL_SetRenderDrawColor(renderer, block_colour_ll..., 255)
        if py > tby + 1 && is_air(tbx, tby + 1, tbz)
            # Top.
            if draw_solid_convex_quad(renderer, [translated_vertices[3], translated_vertices[4], translated_vertices[7], translated_vertices[8]])
                dbg_face_count += 1
                
                if point_within(draw_screen_centre, [translated_vertices[3], translated_vertices[4], translated_vertices[7], translated_vertices[8]])
                    is_hovering = true
                    selected_box = (tbx, tby, tbz)
                    facing_box = (tbx, tby + 1, tbz)
                    draw_dbg_info["selected_face"] = "top"
                    draw_dbg_info["selected_face_rendering_location"] = [translated_vertices[3], translated_vertices[4], translated_vertices[7], translated_vertices[8]]
                end
            end
        end

        SDL_SetRenderDrawColor(renderer, block_colour_l..., 255)
        if px < tbx && is_air(tbx - 1, tby, tbz)
            # Left.
            if draw_solid_convex_quad(renderer, [translated_vertices[1], translated_vertices[3], translated_vertices[7], translated_vertices[5]])
                dbg_face_count += 1

                if point_within(draw_screen_centre, [translated_vertices[1], translated_vertices[3], translated_vertices[7], translated_vertices[5]])
                    is_hovering = true
                    selected_box = (tbx, tby, tbz)
                    facing_box = (tbx - 1, tby, tbz)
                    draw_dbg_info["selected_face"] = "left"
                    draw_dbg_info["selected_face_rendering_location"] = [translated_vertices[1], translated_vertices[3], translated_vertices[7], translated_vertices[5]]
                end
            end
        end

        if px > tbx + 1 && is_air(tbx + 1, tby, tbz)
            # Right.
            if draw_solid_convex_quad(renderer, [translated_vertices[2], translated_vertices[4], translated_vertices[8], translated_vertices[6]])
                dbg_face_count += 1

                if point_within(draw_screen_centre, [translated_vertices[2], translated_vertices[4], translated_vertices[8], translated_vertices[6]])
                    is_hovering = true
                    selected_box = (tbx, tby, tbz)
                    facing_box = (tbx + 1, tby, tbz)
                    draw_dbg_info["selected_face"] = "right"
                    draw_dbg_info["selected_face_rendering_location"] = [translated_vertices[2], translated_vertices[4], translated_vertices[8], translated_vertices[6]]
                end
            end
        end

        SDL_SetRenderDrawColor(renderer, block_colour_d..., 255)
        if pz < tbz && is_air(tbx, tby, tbz - 1)
            # Front.
            if draw_solid_convex_quad(renderer, [translated_vertices[1], translated_vertices[2], translated_vertices[4], translated_vertices[3]])
                dbg_face_count += 1

                if point_within(draw_screen_centre, [translated_vertices[1], translated_vertices[2], translated_vertices[4], translated_vertices[3]])
                    is_hovering = true
                    selected_box = (tbx, tby, tbz)
                    facing_box = (tbx, tby, tbz - 1)
                    draw_dbg_info["selected_face"] = "front"
                    draw_dbg_info["selected_face_rendering_location"] = [translated_vertices[1], translated_vertices[2], translated_vertices[4], translated_vertices[3]]
                end
            end
        end

        if pz > tbz + 1 && is_air(tbx, tby, tbz + 1)
            # Back.
            if draw_solid_convex_quad(renderer, [translated_vertices[5], translated_vertices[6], translated_vertices[8], translated_vertices[7]])
                dbg_face_count += 1

                if point_within(draw_screen_centre, [translated_vertices[5], translated_vertices[6], translated_vertices[8], translated_vertices[7]])
                    is_hovering = true
                    selected_box = (tbx, tby, tbz)
                    facing_box = (tbx, tby, tbz + 1)
                    draw_dbg_info["selected_face"] = "back"
                    draw_dbg_info["selected_face_rendering_location"] = [translated_vertices[5], translated_vertices[6], translated_vertices[8], translated_vertices[7]]
                end
            end
        end
    end

    draw_dbg_info["face_count"] = dbg_face_count

    if is_hovering
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255)
        draw_cube_frame(renderer, selected_box..., px, py, pz, θv, θh)

        draw_dbg_info["selected_box"] = selected_box
        draw_dbg_info["facing_box"] = facing_box
        draw_dbg_info["looking_at_block"] = true

        return (selected_box, facing_box)
    else
        draw_dbg_info["looking_at_block"] = false

        return ()
    end
end