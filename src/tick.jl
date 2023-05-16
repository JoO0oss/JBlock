tick_count_delta = 0
tick_count_last = 0
tick_count_frame_delta = 0
tick_cpt = 0  # Counts (SDL_GetPerformanceCounter()) between each tick.
tick_cpf = 0  # Counts between each frame.

""" Initialise the tick system, given a whole number of ticks and frames per second. """
function tick_init(tps::Int, fps::Int)
    global tick_count_last
    global tick_cpt
    global tick_cpf

    tick_count_last = SDL_GetPerformanceCounter()
    tick_cpt = 100
    tick_cpf = 100
end

""" Call once per tick and it will wait an appropriate amount of time. """
function tick_tick()
    global tick_count_delta
    global tick_count_last
    global tick_count_frame_delta

    # While the time since the last tick < tick duration, wait.
    t1 = SDL_GetPerformanceCounter()
    while tick_count_delta < tick_cpt
        SDL_Delay(5)
        
        t2 = SDL_GetPerformanceCounter()
        tick_count_delta += t2 - t1  # Add to the delta in little bits.
        t1 = t2
    end

    # Record the time since the "last" tick (so the next loop has an anchor point in "now", here).
    tick_count_last = SDL_GetPerformanceCounter()
    # While tick_count_delta records the time since the last tick (ie now), add to frame delta.
    tick_count_frame_delta += tick_count_delta
    tick_count_delta -= tick_cpt  # The remaining value here is time *not* to wait in the next tick.

    # If the time since the last tick is too great, set it to 0 so the next few loops don't instantly tick.
    if tick_count_delta > tick_cpt
        tick_count_delta = 0
    end
end

""" Returns true if a frame should be drawn. """
function tick_should_render()::Bool
    global tick_count_frame_delta

    if tick_count_frame_delta >= tick_cpf
        tick_count_frame_delta -= tick_cpf
        return true
    end

    return false
end
