if false
    include("keys.jl")
end
Import("keys.jl")

KEYBOARD_WIDTH = 200

keyboard_state = zeros(UInt8, KEYBOARD_WIDTH)
keyboard_mod_state = 0

""" Update the internal keyboard state. Run once every tick. """
function keyboard_update()
    global keyboard_state
    global keyboard_mod_state
    sdl_keyboard_state = SDL_GetKeyboardState(C_NULL)
    keyboard_state = unsafe_wrap(Array, sdl_keyboard_state, KEYBOARD_WIDTH)

    keyboard_mod_state = SDL_GetModState()
end

""" Check if a key is held down. """
function keyboard_read(key::Keys)::Bool
    if !key.is_mod
        return keyboard_state[key.code] > 0
    else
        return keyboard_mod_state & key.code > 0
    end
end

""" Check if a key belonging to a set/union is held down. """
function keyboard_read(key::KeysUnion)::Bool
    for key_instance in key.keys
        if keyboard_read(key_instance)
            return true
        end
    end

    return false
end
