
# reads a file line by line to get the masses of every modules
masses = open("inputs/input.txt") do file
    lines = readlines(file)
    map(x -> parse(Int64,x), lines)
end

# converts a mass into the required fuel
function fuelOfMass(mass)
    mass ÷ 3 - 2
end

# converts mass into fuel but then takes the fuel needed to carry the fuel into account
# and then the fuel need to cary this fuel and ...
function recurciveFuelOfMass(mass)
    fuel = fuelOfMass(mass)
    if fuel <= 0
        0
    else
        fuel + recurciveFuelOfMass(fuel)
    end
end

# total fuel needed
totalFuel = mapreduce(fuelOfMass, +, masses)

# total fuel needed including the fuel needed to carry the fuel
totalRecurcivFuel = mapreduce(recurciveFuelOfMass, +, masses)
