
# reads a file line by line to get the masses of every modules
masses = open("inputs/input.txt") do file
    lines = readlines(file)
    map(x -> parse(Int64,x), lines)
end
