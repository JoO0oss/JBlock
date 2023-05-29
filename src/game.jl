if false  # Cursed, never do this.
    include("tick.jl")
    include("keyboard.jl")
    include("mouse.jl")
    include("block.jl")
    include("project.jl")
    include("draw.jl")
    include("configurer.jl")
end
Import("tick.jl")
Import("keyboard.jl")
Import("mouse.jl")
Import("block.jl")
Import("project.jl")
Import("draw.jl")
Import("configurer.jl")

SPACE_WIDTH = 20
SPACE_HEIGHT = 20
SPACE_DEPTH = 20

GRAVITY = 120  # Blocks per second squared.
JUMP_VELOCITY = 20

PLAYER_SPEED = 10
PLAYER_SPRINT_SPEED = 20
PLAYER_ACCELERATION = 2  # Blocks per second squared (allegedly).
PLAYER_LOOK_SENSITIVITY = 0.002
FOV_SCALE = 0.75

game_dbg_info = Dict{String, Any}()

world::Array{Block, 3} = fill(Block(block_type.Air), (SPACE_WIDTH, SPACE_HEIGHT, SPACE_DEPTH))

for x = 5:15, y = 3:5, z = 5:15
    world[x, y, z] = Block(block_type.Stone)
end
for x = 5:15, y = 6:7, z = 5:15
    world[x, y, z] = Block(block_type.Dirt)
end
for x = 5:15, y = 8:8, z = 5:15
    world[x, y, z] = Block(block_type.Grass)
end

function game_play(renderer::Ptr{SDL_Renderer}, window::Ptr{SDL_Window}, config::ConfigData)
    tick_init(config.tps, config.fps)
    project_init(config.width, config.height, FOV_SCALE)
    draw_init(SPACE_WIDTH, SPACE_HEIGHT, SPACE_DEPTH, (config.width, config.height))

    px = 10.1
    py = 15.1
    pz = 10.1
    θv = -1.4  # Start looking down.
    θh = 0.0

    # Player width and height. (px, py, pz) refers to the bottom of the hitbox in the centre.
    pw = 0.5
    ph = 1.8
    p_head = 1.7  # The height of the player's head.
    pϵ = 0.1  # The gap within which to detect collisions.
    p_collision_offset = 0.01  # The offset to use when adjusting position as part of a collision.

    vx = 0.0
    vy = 0.0
    vz = 0.0

    is_vertically_supported = false
    crawling = false

    p_height_full = 1.8
    p_height_crawl = 0.9
    p_hd_full = 1.7  # The height of the player's head when standing.
    p_hd_crawl = 0.8  # The height of the player's head when crawling.


    is_hovering = false
    selected_box = (0, 0, 0)  # The block that would be broken upon left click.
    facing_box = (0, 0, 0)  # The block that would be placed upon right click.

    mouse_xy = (0.0, 0.0)

    screen_middle = config.width ÷ 2, config.height ÷ 2

    mouse_set_pos(window, screen_middle...)

    paused = false
    paused_key = false
    dbg_key = false

    """ Convenience function for checking if a 3d point is inside a filled block. """
    function is_filled(x::Float64, y::Float64, z::Float64)
        xi = floor(Int, x)
        yi = floor(Int, y)
        zi = floor(Int, z)

        if xi <= 0 || yi <= 0 || zi <= 0 || xi > SPACE_WIDTH || yi > SPACE_HEIGHT || zi > SPACE_DEPTH
            return false
        end
        return world[xi, yi, zi].type != block_type.Air
    end



    """ Convenience function to check if any of the player is colliding downwards into a block. """
    function is_colliding_bottom(x::Float64, y::Float64, z::Float64)
            return is_filled(x - pw/2 + pϵ, y, z - pw/2 + pϵ) ||
                    is_filled(x + pw/2 - pϵ, y, z - pw/2 + pϵ) ||
                    is_filled(x - pw/2 + pϵ, y, z + pw/2 - pϵ) ||
                    is_filled(x + pw/2 - pϵ, y, z + pw/2 - pϵ)
    end

    """ Convenience function to check if any of the player is colliding upwards into a block. """
    function is_colliding_top(x::Float64, y::Float64, z::Float64)
            return is_filled(x - pw/2 + pϵ, y + ph, z - pw/2 + pϵ) ||
                    is_filled(x + pw/2 - pϵ, y + ph, z - pw/2 + pϵ) ||
                    is_filled(x - pw/2 + pϵ, y + ph, z + pw/2 - pϵ) ||
                    is_filled(x + pw/2 - pϵ, y + ph, z + pw/2 - pϵ)
    end

    """ Convenience function to check if any of the player is colliding left into a block. """
    function is_colliding_left(x::Float64, y::Float64, z::Float64)
            return is_filled(x - pw/2, y + pϵ, z - pw/2 + pϵ) ||
                    is_filled(x - pw/2, y + pϵ, z + pw/2 - pϵ) ||
                    is_filled(x - pw/2, y + ph - pϵ, z - pw/2 + pϵ) ||
                    is_filled(x - pw/2, y + ph - pϵ, z + pw/2 - pϵ)
    end

    """ Convenience function to check if any of the player is colliding right into a block. """
    function is_colliding_right(x::Float64, y::Float64, z::Float64)
            return is_filled(x + pw/2, y + pϵ, z - pw/2 + pϵ) ||
                    is_filled(x + pw/2, y + pϵ, z + pw/2 - pϵ) ||
                    is_filled(x + pw/2, y + ph - pϵ, z - pw/2 + pϵ) ||
                    is_filled(x + pw/2, y + ph - pϵ, z + pw/2 - pϵ)
    end

    """ Convenience function to check if any of the player is colliding forwards into a block. """
    function is_colliding_front(x::Float64, y::Float64, z::Float64)
            return is_filled(x - pw/2 + pϵ, y + pϵ, z - pw/2) ||
                    is_filled(x + pw/2 - pϵ, y + pϵ, z - pw/2) ||
                    is_filled(x - pw/2 + pϵ, y + ph - pϵ, z - pw/2) ||
                    is_filled(x + pw/2 - pϵ, y + ph - pϵ, z - pw/2)
    end

    """ Convenience function to check if any of the player is colliding backwards into a block. """
    function is_colliding_back(x::Float64, y::Float64, z::Float64)
            return is_filled(x - pw/2 + pϵ, y + pϵ, z + pw/2) ||
                    is_filled(x + pw/2 - pϵ, y + pϵ, z + pw/2) ||
                    is_filled(x - pw/2 + pϵ, y + ph - pϵ, z + pw/2) ||
                    is_filled(x + pw/2 - pϵ, y + ph - pϵ, z + pw/2)
    end


    try
        run = true

        while run
            event_ref = Ref{SDL_Event}()
            while Bool(SDL_PollEvent(event_ref))
                evt = event_ref[]
                evt_ty = evt.type
                if evt_ty == SDL_QUIT
                    run = false
                    break
                end
    
                if evt_ty == SDL_KEYDOWN && evt.key.keysym.scancode == SDL_SCANCODE_ESCAPE
                    run = false
                    break
                end
            end
            
            # Tick:
            mouse_update()
            keyboard_update()


            # These aren't for inertia in the typical sense, they're more for smoothness player movement.
            v_forwards = 0.0
            v_rightwards = 0.0

            if keyboard_read(KEYS_W)
                v_forwards += PLAYER_SPEED

                if keyboard_read(KEYS_LCTRL)
                    v_forwards = PLAYER_SPRINT_SPEED
                end
            end
            if keyboard_read(KEYS_S)
                v_forwards -= PLAYER_SPEED
            end
            if keyboard_read(KEYS_A)
                v_rightwards -= PLAYER_SPEED
            end
            if keyboard_read(KEYS_D)
                v_rightwards += PLAYER_SPEED
            end
            if keyboard_read(KEYS_SPACE)
                if is_vertically_supported
                    vy += JUMP_VELOCITY
                end
            end
            
            if keyboard_read(KEYS_LSHIFT)
                crawling = true
                ph = p_height_crawl
                p_head = p_hd_crawl
            else
                crawling = false
                ph = p_height_full
                p_head = p_hd_full
            end

            if keyboard_read(KEYS_F3)
                dbg_key = true
            else
                if dbg_key
                    println("\n=== DEBUG INFO ===")
                    for (key, value) in draw_get_dbg_info()
                        println("$key: $value")
                    end
                    println()

                    for (key, value) in game_dbg_info
                        println("$key: $value")
                    end
                    println()
                    println()


                    println("performance_count: $(SDL_GetPerformanceCounter())")
                    println("previous_tick_delta: $(tick_previous_delta())")
                    println("position: ", round(px, sigdigits=3), ", ", round(py, sigdigits=3), ", ", round(pz, sigdigits=3))
                    println("block_position: ", floor(px), ", ", floor(py), ", ", floor(pz))
                    println()
                    println("velocity: ", round(vx, sigdigits=3), ", ", round(vy, sigdigits=3), ", ", round(vz, sigdigits=3))
                    println("(θh, θv) : (", round(θh, sigdigits=3), ", ", round(θv, sigdigits=3), ")")
                    println("(v_forwards, v_rightwards): (", round(v_forwards, sigdigits=3), ", ", round(v_rightwards, sigdigits=3), ")")
                    println("is_vertically_supported: $is_vertically_supported")
                    println("crawling: $crawling")

                    println("==================\n")
                end
                dbg_key = false
            end

            # Move the player's camera depending on mouse movement.
            mouse_xy = mouse_get_pos()
            if !paused
                SDL_ShowCursor(SDL_DISABLE)
                mouse_delta = (mouse_xy .- screen_middle) .* PLAYER_LOOK_SENSITIVITY

                θh += mouse_delta[1]
                θv -= mouse_delta[2]

                mouse_set_pos(window, config.width ÷ 2, config.height ÷ 2)
            else
                SDL_ShowCursor(SDL_ENABLE)
            end

            # Just make sure the number storing rotation stays in a sensible range.
            if θv > π / 2
                θv = π / 2
            elseif θv < -π / 2
                θv = -π / 2
            end
            if θh > 2π
                θh -= 2π
            end
            if θh < 0
                θh += 2π
            end



            # Physics:
            
            is_vertically_supported = vy <= 0 && (
                                        is_filled(px - pw/2, py-pϵ, pz - pw/2) ||
                                        is_filled(px + pw/2, py-pϵ, pz - pw/2) ||
                                        is_filled(px - pw/2, py-pϵ, pz + pw/2) ||
                                        is_filled(px + pw/2, py-pϵ, pz + pw/2) )


            if !is_vertically_supported
                vy -= GRAVITY * tick_previous_delta()
            else
                vy = max(vy, 0)
            end


            target_vz = -cos(θh) * v_forwards + sin(θh) * v_rightwards
            target_vx = sin(θh) * v_forwards + cos(θh) * v_rightwards

            game_dbg_info["target_vx"] = target_vx
            game_dbg_info["target_vz"] = target_vz

            Δvx = (target_vx - vx) * tick_previous_delta()
            Δvz = (target_vz - vz) * tick_previous_delta()

            # Normalise Δv.
            Δv_length = sqrt(Δvx^2 + Δvz^2)
            if Δv_length != 0
                Δvx /= Δv_length
                Δvz /= Δv_length
            end

            Δvx *= PLAYER_ACCELERATION
            Δvz *= PLAYER_ACCELERATION

            # If vx + Δvx would overshoot...
            if (vx <= target_vx && vx + Δvx > target_vx) || (vx >= target_vx && vx + Δvx < target_vx)
                vx = target_vx
            else
                vx += Δvx
            end
            if (vz < target_vz && vz + Δvz > target_vz) || (vz > target_vz && vz + Δvz < target_vz)
                vz = target_vz
            else
                vz += Δvz
            end

            # Abbreviate v_ * tick_previous_delta() to Δ_ for the 6 if statements below.
            Δx = vx * tick_previous_delta()
            Δy = vy * tick_previous_delta()
            Δz = vz * tick_previous_delta()


            # Set vx, vy, vz to 0 if the player is about to bump into something.

            # if (your_position + your_velocity) makes you hit a wall but (your_position) doesn't...
            if is_colliding_bottom(px + Δx, py + Δy, pz + Δz) && !is_colliding_bottom(px, py + Δy, pz)
                # max() is here so you don't just get stuck with vx = 0 when you enter the zone specified with is_colliding(...) above.
                println("left bump")
                vy = max(vy, 0)
                Δy = max(Δy, 0)
                py = floor(py) + p_collision_offset
            end
            if is_colliding_top(px + Δx, py + Δy, pz + Δz) && !is_colliding_top(px, py + Δy, pz)
                vy = min(vy, 0)
                Δy = min(Δy, 0)
                py = ceil(py + ph) - ph - p_collision_offset
            end
            if is_colliding_left(px + Δx, py + Δy, pz + Δz) && !is_colliding_left(px, py + Δy, pz + Δz)
                vx = max(vx, 0)
                Δx = max(Δx, 0)
                # Evaluate floor(left_hand_side_of_player) to get the position of the wall.
                px = floor(px - pw/2) + pw/2 + p_collision_offset
            end
            if is_colliding_right(px + Δx, py + Δy, pz + Δz) && !is_colliding_right(px, py + Δy, pz + Δz)
                vx = min(vx, 0)
                Δx = min(Δx, 0)
                px = ceil(px + pw/2) - pw/2 - p_collision_offset
            end
            if is_colliding_front(px + Δx, py + Δy, pz + Δz) && !is_colliding_front(pz, py + Δy, pz)
                vz = max(vz, 0)
                Δz = max(Δz, 0)
                pz = floor(pz - pw/2) + pw/2 + p_collision_offset
            end
            if is_colliding_back(px + Δx, py + Δy, pz + Δz) && !is_colliding_back(pz, py + Δy, pz)
                vz = min(vz, 0)
                Δz = min(Δz, 0)
                pz = ceil(pz + pw/2) - pw/2 - p_collision_offset
            end
            
            """
            println(is_filled(px - pw/2, py + pϵ, pz - pw/2 + pϵ))
            println(is_filled(px - pw/2, py + pϵ, pz + pw/2 - pϵ))
            println(is_filled(px - pw/2, py + ph - pϵ, pz - pw/2 + pϵ))
            println(is_filled(px - pw/2, py + ph - pϵ, pz + pw/2 - pϵ))
            println()"""

            px += Δx
            py += Δy
            pz += Δz


            # Break and place blocks.
            if is_hovering && !paused
                if mouse_get_left_pressed()
                    world[selected_box...] = Block(block_type.Air)
                end

                if mouse_get_right_pressed()
                    if 1 <= facing_box[1] <= SPACE_WIDTH && 1 <= facing_box[2] <= SPACE_HEIGHT && 1 <= facing_box[3] <= SPACE_DEPTH
                        world[facing_box...] = Block(block_type.Dirt)
                    end
                end
            end


            # Render:

            if tick_should_render()
                # Make the sky a bit darker if you're looking down.
                if θv < 0
                    SDL_SetRenderDrawColor(renderer, 150, 215, 255, 255)
                else
                    SDL_SetRenderDrawColor(renderer, 140, 205, 245, 255)
                end

                SDL_RenderClear(renderer)

                looking_at = draw_world(renderer, world, px, py + p_head, pz, θv, θh)
                
                is_hovering = false
                if looking_at != ()
                    is_hovering = true
                    selected_box, facing_box = looking_at
                end

                SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255)
                draw_cross(renderer, (config.width ÷ 2, config.height ÷ 2))
                

                SDL_RenderPresent(renderer)
            end


            # This bit has to go after querying pause and before calling tick() because, when
            # unpausing, moving the mouse back to the centre needs an extra tick to update.
            if keyboard_read(KEYS_P)
                paused_key = true
            else  # Do this on the release of the key.
                if paused_key
                    paused = !paused
                    mouse_set_pos(window, config.width ÷ 2, config.height ÷ 2)
                end
                paused_key = false
            end

            tick_tick()
        end
    
        SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255)
        SDL_RenderClear(renderer)
        SDL_RenderPresent(renderer)
        SDL_Delay(200)
    
    finally
        println("Cleaning up.")

        SDL_DestroyRenderer(renderer)
        SDL_DestroyWindow(window)
        SDL_Quit()
    end
end