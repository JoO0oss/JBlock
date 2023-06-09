tick_count_delta = 0
tick_count_last = 0
tick_count_frame_delta = 0
tick_cpt = 0  # Counts (SDL_GetPerformanceCounter()) between each tick.
tick_cpf = 0  # Counts between each frame.

tick_last_delta_s = 0  # Last tick delta, in seconds.

PERFORMANCE_COUNTER_TPS = 1000000000  # 1 billion ticks occur over a second (on my machine :\ ...).

""" Initialise the tick system, given a whole number of ticks and frames per second. """
function tick_init(tps::Int, fps::Int)
    global tick_count_last
    global tick_cpt
    global tick_cpf

    # Somehow, only now, after finishing everything other than physics, do I find out that
    # SDL_GetPerformanceCounter() is not consistent across platforms.  Ehh. It works fine as it
    # is currently, PERFORMANCE_COUNTER_TPS will just have to change per device.
    tick_count_last = SDL_GetPerformanceCounter()
    tick_cpt = PERFORMANCE_COUNTER_TPS / tps
    tick_cpf = PERFORMANCE_COUNTER_TPS / fps
end

""" Call once per tick and it will wait an appropriate amount of time. """
function tick_tick()
    global tick_count_delta
    global tick_count_last
    global tick_count_frame_delta
    global tick_last_delta_s

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
    tick_last_delta_s = tick_count_delta / PERFORMANCE_COUNTER_TPS  # Record the delta in seconds.
    tick_count_delta -= tick_cpt  # The remaining value here is time *not* to wait in the next tick.

    # If the time since the last tick is too great, set it to 0 so the next few loops don't instantly tick.
    if tick_count_delta > tick_cpt
        tick_count_delta = 0
    end
end

""" Return the duration (in seconds) of the previous tick. """
function tick_previous_delta()::Float64
    # This is just a rough substitute that does fine while I work on other things.
    return tick_last_delta_s
end

""" Return the number of ticks per second. """
function tick_report_tps()::Float64
    return 1 / tick_last_delta_s
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
