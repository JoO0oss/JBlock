# using SimpleDirectMediaLayer.LibSDL2

# Use these to work out if the mouse has been clicked or released.
mouse_left_down = false
mouse_left_down_prev = false
mouse_middle_down = false
mouse_middle_down_prev = false
mouse_right_down = false
mouse_right_down_prev = false

mouse_button_state = 0
mouse_location = (0, 0)

""" Update the internal mouse state. Run once every tick. """
function mouse_update()
    global mouse_left_down
    global mouse_left_down_prev
    global mouse_middle_down
    global mouse_middle_down_prev
    global mouse_right_down
    global mouse_right_down_prev
    
    global mouse_button_state
    global mouse_location

    mouse_x_ref = Ref{Cint}()
    mouse_y_ref = Ref{Cint}()
    
    mouse_button_state = SDL_GetMouseState(mouse_x_ref, mouse_y_ref)
    mouse_location = (mouse_x_ref[], mouse_y_ref[])

    mouse_left_down_prev = mouse_left_down
    if mouse_button_state & SDL_BUTTON_LMASK > 0
        mouse_left_down = true
    else
        mouse_left_down = false
    end

    mouse_middle_down_prev = mouse_middle_down
    if mouse_button_state & SDL_BUTTON_MMASK > 0
        mouse_middle_down = true
    else
        mouse_middle_down = false
    end

    mouse_right_down_prev = mouse_right_down
    if mouse_button_state & SDL_BUTTON_RMASK > 0
        mouse_right_down = true
    else
        mouse_right_down = false
    end
end

""" Get mouse location as a tuple of `(x, y)`. """
function mouse_get_pos()::Tuple{Int32, Int32}
    return mouse_location
end

""" Set mouse location. """
function mouse_set_pos(window::Ptr{SDL_Window}, x::Int, y::Int)
    SDL_WarpMouseInWindow(window, x, y)
end


""" Get whether the left mouse button has just been pressed. """
function mouse_get_left_pressed()
    return mouse_left_down && !mouse_left_down_prev
end

""" Get whether the left mouse button has just been released. """
function mouse_get_left_released()
    return mouse_left_down_prev && !mouse_left_down
end

""" Get whether the middle mouse button has just been pressed. """
function mouse_get_middle_pressed()
    return mouse_middle_down && !mouse_middle_down_prev
end

""" Get whether the middle mouse button has just been released. """
function mouse_get_middle_released()
    return mouse_middle_down_prev && !mouse_middle_down
end

""" Get whether the right mouse button has just been pressed. """
function mouse_get_right_pressed()
    return mouse_right_down && !mouse_right_down_prev
end

""" Get whether the right mouse button has just been released. """
function mouse_get_right_released()
    return mouse_right_down_prev && !mouse_right_down
end