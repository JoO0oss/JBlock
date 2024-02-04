# OS Agnostic entry point with `julia` command.
if Sys.iswindows()
    cd("src")
    run(`julia main.jl`)
else
    run(`chmod +x run.sh`)
    run(`./run.sh`)
end