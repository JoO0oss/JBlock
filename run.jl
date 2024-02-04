# OS Agnostic entry point with `julia` command.
if Sys.islinux()
    run(`chmod +x run.sh`)
    run(`./run.sh`)
else
    cd("src")
    run(`julia main.jl`)
end