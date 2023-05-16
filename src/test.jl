#!/usr/bin/julia

function test(test_file)
    println("Running $test_file.")
    include(test_file)
    println()
end

test("test_maths.jl")
test("test_iter.jl")

#println("test_project.jl")