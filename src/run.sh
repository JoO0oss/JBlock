#!/bin/sh
#printf "Running MODULER.\n"
#if julia MODULER.jl main
#then
#    printf "Completed includes.\n\n"
#
#    export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6
#    julia main.jl
#else
#    printf "(!) Failed to bind includes.\n"
#fi

export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6
julia main.jl