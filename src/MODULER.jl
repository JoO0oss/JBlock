""" It's *very* dirty to do this, but have this at the top of your main file and assume that this
is accessible from anywhere. """

if false
# Running MODULER.jl as a standalone file compiles together all modules used.
if abspath(PROGRAM_FILE) == @__FILE__
    # TODO: Add provision for files in subdirectories.
    script_list = readdir()
    
    skip_list = vcat([arg * ".jl" for arg in ARGS], ["MODULER.jl", "MODULES.jl"])
    is_valid(filename) = (endswith(filename, ".jl")  # Make sure it's a julia file.
        && !(filename in skip_list)  # Make sure it's a file that *does* want to be included.
        && match(Regex("[A-Z,a-z][A-Z,a-z,0-9,_,-]*.jl"), filename).match == filename  # Something something regex, cyber security.
        && !(filename[end-3] in ['_', '-']))  # Ignore files that end in _ or -.

    # The regex above checks it starts with a letter and is only followed by letters, numbers,
    # underscores or hyphens and ends with ".jl".

    filter!(is_valid, script_list)


    to_variable(filename) = replace(replace(filename, r".jl$"=>""), "-" => "_")

    # Construct the MODULES.jl file (this is a very dirty way of doing things).
    lines = ["_$(to_variable(filename)) = \"$(filename)\"" for filename in script_list]
    # "...abc$" is a regex for the end of the string (accepts "abc" and "abc123" but not "123abc").

    # This is really cursed. Never do this.
    open("MODULES.jl", "w") do file
        write(file, join(lines, "\n"))
    end

    exit()
end


if isfile("MODULES.jl")
    include("MODULES.jl")    
end
end


MODULER_modules = []  # A list of all modules in the package.

""" This is basically a fancy include function that stops code from being run twice. """
function Import(module_name::String)
    # TODO: Record differences between includes within modules and includes within main.
    global MODULER_modules
    if !(module_name in MODULER_modules)
        #println("Importing $(module_name).")
        include(module_name)
        push!(MODULER_modules, module_name)
    end
end