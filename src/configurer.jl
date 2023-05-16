# Remember this struct is immutable, the config is created and can't be messed with.
""" A struct for config data, there should only be one instance of this. """
struct ConfigData
    width::Int
    height::Int
    """ Note that title is not set in config.txt. """
    title::String
    tps::Int
    fps::Int
end

""" Take values from config.txt and return a ConfigData struct. """
function configurer_init()::ConfigData
    # These are just a list of keys required in config.txt.
    unset_config_warn = Set(["display_size", "tps", "fps"])
    
    display_size_str = "800x600"
    tps_str = "50"
    fps_str = "30"

    # Extract settings from config.txt.
    if(isfile("config.txt"))
        open("config.txt", "r") do file
            for line in eachline(file)
                # Skip empty lines and comments.
                if line == "" || line[1] == '#'
                    continue
                end

                if !occursin("=", line)
                    println("Warning, invalid config line: $line, 'key=value' required.")
                    continue
                end

                key, value = split(line, "=")
                if key == "display_size"
                    display_size_str = value
                    delete!(unset_config_warn, "display_size")
                elseif key == "tps"
                    tps_str = value
                    delete!(unset_config_warn, "tps")
                elseif key == "fps"
                    fps_str = value
                    delete!(unset_config_warn, "fps")
                else
                    println("Warning, unrecognised config: $key  \t(= $value)")
                end
            end
        end
    else
        println("Warning, config.txt not found, the following warnings below are a direct result of this.")
    end

    for key in unset_config_warn
        println("Warning, $key not set in config.txt, using default.")
    end


    # Parse options into variables.
    width = 0
    height = 0
    try
        width, height = split(display_size_str, "x")
        width = parse(Int, width)
        height = parse(Int, height)
    catch
        println("Warning, invalid display_size in config.txt, using default.")
        width, height = 800, 600
    end

    tps = 0
    try
        tps = parse(Int, tps_str)
    catch
        println("Warning, invalid tps in config.txt, using default.")
        tps = 50
    end
    
    fps = 0
    try
        fps = parse(Int, fps_str)
    catch
        println("Warning, invalid fps in config.txt, using default.")
        fps = 30
    end


    return ConfigData(width, height, "JBlock", tps, fps)

end