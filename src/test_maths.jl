#!/usr/bin/julia
include("maths.jl")

p1_a = (4, 5)
p2_a = (2, 3)
p3_a = (5, 3)
p4_a = (3, 1)

eq_a = Equation(p1_a, p4_a)
assert_inequality!(eq_a, p2_a, true)
test1 = (get_inequality(eq_a, p3_a) == false)

println("test1: ", test1)


p1_b = (2, 6)
p2_b = (5, 5)
p3_b = (6, 4)
p4_b = (3, 1)
eq_b = Equation(p1_b, p4_b)
assert_inequality!(eq_b, p2_b, true)
test2 = (get_inequality(eq_b, p3_b) == true)

println("test2: ", test2)


p1_c = (880, 120)
p2_c = (1120, 120)
p3_c = (853, 147)
p4_c = (1067, 147)
eq_c = Equation(p1_c, p4_c)
assert_inequality!(eq_c, p2_c, true)
test3 = (get_inequality(eq_c, p3_c) == false)

println("test3: ", test3)


p1_d = (1, 1)
p2_d = (2, 1)
p3_d = (1, 2)
p4_d = (2, 2)
middle_d = (1.5, 1.5)
test4 = point_within(middle_d, [p1_d, p2_d, p3_d, p4_d]) == true

println("test4: ", test4)

p1_e = (1, 1)
p2_e = (2, 1)
p3_e = (1, 2)
p4_e = (2, 2)
middle_e = (3, 4)
test5 = point_within(middle_e, [p1_e, p2_e, p3_e, p4_e]) == false

println("test5: ", test5)

pts_f = [(504, 290), (812, 270), (540, 440), (898, 413)]
middle_f = (640, 360)
test6 = point_within(middle_f, pts_f) == true

println("test6: ", test6)

pts_g = [(578,651),(705,141),(699,455),(571,300)]
middle_g = (638.25,386.75)
test7 = point_within(middle_g, pts_g) == true

println("test7: ", test7)