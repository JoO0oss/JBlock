include("iter.jl")

lst_a = ["a", "b", "c", "d", "e", "f"]
itr_a = iter_centred(lst_a, 3)
test1 = itr_a == ["c", "d", "b", "e", "a", "f"]
println("test1: ", test1)

lst_b = ["a", "b", "c", "d", "e", "f"]
itr_b = iter_centred(lst_b, 4)
test2 = itr_b == ["d", "e", "c", "f", "b", "a"]
println("test2: ", test2)

lst_c = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"]
itr_c = iter_centred(lst_c, 4)
test3 = itr_c == ["d", "e", "c", "f", "b", "g", "a", "h", "i", "j"]
println("test3: ", test3)
