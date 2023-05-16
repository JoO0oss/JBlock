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

GRAVITY = 5  # Blocks per second squared.

PLAYER_ACCELERATION = 0.005
PLAYER_DECELERATION = PLAYER_ACCELERATION / 2
PLAYER_MAX_SPEED = 2
PLAYER_LOOK_SENSITIVITY = 0.002

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
    project_init(config.width, config.height)
    draw_init(SPACE_WIDTH, SPACE_HEIGHT, SPACE_DEPTH, (config.width, config.height))

    px = 10.1
    py = 10.1
    pz = 20.1  # Start the player a little bit back.
    θv = 0.0
    θh = 0.0

    # Player width and height. (px, py, pz) refers to the bottom of the hitbox in the centre.
    pw = 0.5
    ph = 1.8
    p_head = 1.7  # The height of the player's head.

    vx = 0
    vy = 0
    vz = 0
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

            if keyboard_read(KEYS_W)
                vz -= PLAYER_ACCELERATION * cos(θh) * config.tps
                vx += PLAYER_ACCELERATION * sin(θh) * config.tps
            end
            if keyboard_read(KEYS_S)
                vz += PLAYER_ACCELERATION * cos(θh) * config.tps
                vx -= PLAYER_ACCELERATION * sin(θh) * config.tps
            end
            if keyboard_read(KEYS_A)
                vz -= PLAYER_ACCELERATION * sin(θh) * config.tps
                vx -= PLAYER_ACCELERATION * cos(θh) * config.tps
            end
            if keyboard_read(KEYS_D)
                vz += PLAYER_ACCELERATION * sin(θh) * config.tps
                vx += PLAYER_ACCELERATION * cos(θh) * config.tps
            end
            if keyboard_read(KEYS_SPACE)
                if is_vertically_supported
                    vy += 2
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

                    println("performance_count: $(SDL_GetPerformanceCounter())")
                    println("x: $px")
                    println("y: $py")
                    println("z: $pz")
                    println("vx: $vx")
                    println("vy: $vy")
                    println("vz: $vz")
                    println("θv: $θv")
                    println("θh: $θh")
                    println("is_vertically_supported: $is_vertically_supported")
                    println("crawling: $crawling")

                    println("==================\n")
                end
                dbg_key = false
            end

            # Physics.
            if !is_vertically_supported
                vy -= GRAVITY / config.tps
            end
            if vx > PLAYER_MAX_SPEED
                vx = PLAYER_MAX_SPEED
            elseif vx < -PLAYER_MAX_SPEED
                vx = -PLAYER_MAX_SPEED
            end
            if vz > PLAYER_MAX_SPEED
                vz = PLAYER_MAX_SPEED
            elseif vz < -PLAYER_MAX_SPEED
                vz = -PLAYER_MAX_SPEED
            end
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

            if vx > 0
                vx -= PLAYER_DECELERATION / config.tps
            elseif vx < 0
                vx += PLAYER_DECELERATION / config.tps
            end
            if vz > 0
                vz -= PLAYER_DECELERATION / config.tps
            elseif vz < 0
                vz += PLAYER_DECELERATION / config.tps
            end

            if abs(vx) < PLAYER_DECELERATION / config.tps * 0.51
                vx = 0
            end
            if abs(vz) < PLAYER_DECELERATION / config.tps * 0.51
                vz = 0
            end

            px += vx / config.tps
            pz += vz / config.tps


            # Break and place blocks.
            if is_hovering
                if mouse_get_left_pressed()
                    world[selected_box...] = Block(block_type.Air)
                end

                if mouse_get_right_pressed()
                    if 1 <= facing_box[1] <= SPACE_WIDTH && 1 <= facing_box[2] <= SPACE_HEIGHT && 1 <= facing_box[3] <= SPACE_DEPTH
                        world[facing_box...] = Block(block_type.Dirt)
                    end
                end
            end

            
            # Move the player's camera depending on mouse movement.
            mouse_xy = mouse_get_pos()
            if !paused
                SDL_ShowCursor(SDL_DISABLE)
                mouse_delta = (mouse_xy .- screen_middle) .* PLAYER_LOOK_SENSITIVITY

                θh += mouse_delta[1]
                θv += mouse_delta[2]

                mouse_set_pos(window, config.width ÷ 2, config.height ÷ 2)
            else
                SDL_ShowCursor(SDL_ENABLE)
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