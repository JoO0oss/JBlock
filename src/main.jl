include("MODULER.jl")  # Very cursed. Never do this.
if false  # Similarly cursed, this just makes code completion, navigation etc. work.
    include("configurer.jl")
    include("game.jl")
end

println("Running JBlock.")

using SimpleDirectMediaLayer.LibSDL2
Import("configurer.jl")
Import("game.jl")

# Check if LD_PRELOAD exists/is correct, use shortcircuting to avoid error
if !("LD_PRELOAD" in keys(ENV)) || ENV["LD_PRELOAD"] != "/usr/lib/x86_64-linux-gnu/libstdc++.so.6"
    println("WARNING: LD_PRELOAD is not set, this may cause issues with SDL2.")
    println("Please run `export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6` before running this script.")
    exit()
end

main_config = configurer_init()

SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 16)
SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 16)

@assert SDL_Init(SDL_INIT_EVERYTHING) == 0 "error initializing SDL: $(unsafe_string(SDL_GetError()))"


main_window = SDL_CreateWindow(main_config.title, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, main_config.width, main_config.height, SDL_WINDOW_SHOWN)
SDL_SetWindowResizable(main_window, SDL_TRUE)

icon = IMG_Load("assets/icon.png")
SDL_SetWindowIcon(main_window, icon)
SDL_FreeSurface(icon)

main_renderer = SDL_CreateRenderer(main_window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC)

game_play(main_renderer, main_window, main_config)

println("JBlock closed without error.")
