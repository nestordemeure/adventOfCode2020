
#------------------------------------------------------------------------
# PARSER

# represents a chimical reaction
struct Reaction
  material # the output material
  quantity # the output quantity
  formula # list of inputs/outputs and their quantity concummed/produced by the reaction
end

# takes an input material of the form "1 FUEL" and returns ("FUEL", 1)
function parseMaterial(input)
  tokens = split(input, ' ')
  quantity = parse(Int,tokens[1])
  material = tokens[2]
  (material, quantity)
end

# takes an input list of the form "1 FUEL, 2 ORE, ..." and returns an array of inputs [("FUEL", 1), ("ORE", 2), ...]
function parseInputList(inputList)
  tokens = split(inputList, ", ")
  map(parseMaterial, tokens)
end

# takes the inputs and outputs of a reaction in order to produced a list
# of inputs/outputs and their quantity concummed/produced by the reaction
function makeFormula(outputMaterial,outputQuantity,inputs)
  #formula = map((q,m) -> (-q,m), inputs)
  #push!(formula, (outputQuantity,outputMaterial))
  #formula
  formula = Vector()
  for (m,q) in inputs
    push!(formula, (m,-q))
  end
  push!(formula, (outputMaterial,outputQuantity))
  formula
end

# takes a line and returns a Reaction
function parseReaction(line)
  tokens = split(line, " => ")
  inputs = parseInputList(tokens[1])
  (outputMaterial,outputQuantity) = parseMaterial(tokens[2])
  formula = makeFormula(outputMaterial,outputQuantity,inputs)
  Reaction(outputMaterial, outputQuantity, formula)
end

# takes a text and returns a dictionnary of out-material=>reaction
function parseReactions(str)
  lines = split(str, '\n')
  reactions = map(parseReaction, lines)
  result = Dict()
  for reaction in reactions
    result[reaction.material] = reaction
  end
  result
end

#------------------------------------------------------------------------
# REACTIONS

# lists the materials that need resplendishing
# (except ORE)
function findMissingMaterials(availableMaterials)
  result = Vector()
  for (material,quantity) in availableMaterials
    if (quantity < 0) && (material != "ORE")
      push!(result, (material,-quantity))
    end
  end
  result
end

# updates availableMaterials by applying a given formula n times
function applyFormulaNtimes(availableMaterials, formula, applicationNumber)
  for (material, quantity) in formula
    availableMaterials[material] = get(availableMaterials, material, 0) + quantity*applicationNumber
  end
end

# finds the quantity of ORE needed to produce the given quantity of FUEL
function makeFuel(reactions, nbFuel = 1)
  availableMaterials = Dict("FUEL" => -nbFuel)
  missingMaterials = findMissingMaterials(availableMaterials)
  while !isempty(missingMaterials)
    for (material,quantity) in missingMaterials
      reaction = reactions[material]
      applicationNumber = max(1, quantity ÷ reaction.quantity)
      applyFormulaNtimes(availableMaterials, reaction.formula, applicationNumber)
    end
    missingMaterials = findMissingMaterials(availableMaterials)
  end
  -availableMaterials["ORE"]
end

#------------------------------------------------------------------------
# FUEL

# finds (inf, sup) such that
# inf fuel can be produced with the given quantity of ore
# sup cannot be produced with the given quantity of ore
function findBrackets(reactions, totalOre)
  infFuel = totalOre ÷ makeFuel(reactions, 1)
  supFuel = 2*infFuel
  oreConsummed = makeFuel(reactions, supFuel)
  while oreConsummed <= totalOre
    infFuel = supFuel
    supFuel = 2*supFuel
    oreConsummed = makeFuel(reactions, supFuel)
  end
  (infFuel, supFuel)
end

# finds the maximum quantity of fuel that can be produced with a given ore
function findMaximumFuel(reactions, totalOre=1000000000000)
  (infFuel, supFuel) = findBrackets(reactions, totalOre)
  while (supFuel - infFuel) > 1
    #println("[", infFuel, ", ", supFuel, "]")
    midFuel = (supFuel + infFuel) ÷ 2
    oreConsummed = makeFuel(reactions, midFuel)
    if oreConsummed > totalOre
      supFuel = midFuel
    else
      infFuel = midFuel
    end
  end
  infFuel
end

#------------------------------------------------------------------------
# TEST

println("test 1")
r1 = parseReactions("10 ORE => 10 A
1 ORE => 1 B
7 A, 1 B => 1 C
7 A, 1 C => 1 D
7 A, 1 D => 1 E
7 A, 1 E => 1 FUEL")
o1 = makeFuel(r1)
println("ORE: ", o1, " == 31")

println("test 2")
r2 = parseReactions("9 ORE => 2 A
8 ORE => 3 B
7 ORE => 5 C
3 A, 4 B => 1 AB
5 B, 7 C => 1 BC
4 C, 1 A => 1 CA
2 AB, 3 BC, 4 CA => 1 FUEL")
o2 = makeFuel(r2)
println("ORE: ", o2, " == 165")

println("test 3")
r3 = parseReactions("157 ORE => 5 NZVS
165 ORE => 6 DCFZ
44 XJWVT, 5 KHKGT, 1 QDVJ, 29 NZVS, 9 GPVTF, 48 HKGWZ => 1 FUEL
12 HKGWZ, 1 GPVTF, 8 PSHF => 9 QDVJ
179 ORE => 7 PSHF
177 ORE => 5 HKGWZ
7 DCFZ, 7 PSHF => 2 XJWVT
165 ORE => 2 GPVTF
3 DCFZ, 7 NZVS, 5 HKGWZ, 10 PSHF => 8 KHKGT")
o3 = makeFuel(r3)
println("ORE: ", o3, " == 13312")

println("test 4")
r4 = parseReactions("2 VPVL, 7 FWMGM, 2 CXFTF, 11 MNCFX => 1 STKFG
17 NVRVD, 3 JNWZP => 8 VPVL
53 STKFG, 6 MNCFX, 46 VJHF, 81 HVMC, 68 CXFTF, 25 GNMV => 1 FUEL
22 VJHF, 37 MNCFX => 5 FWMGM
139 ORE => 4 NVRVD
144 ORE => 7 JNWZP
5 MNCFX, 7 RFSQX, 2 FWMGM, 2 VPVL, 19 CXFTF => 3 HVMC
5 VJHF, 7 MNCFX, 9 VPVL, 37 CXFTF => 6 GNMV
145 ORE => 6 MNCFX
1 NVRVD => 8 CXFTF
1 VJHF, 6 MNCFX => 4 RFSQX
176 ORE => 6 VJHF")
o4 = makeFuel(r4)
println("ORE: ", o4, " == 180697")

println("test 5")
r5 = parseReactions("171 ORE => 8 CNZTR
7 ZLQW, 3 BMBT, 9 XCVML, 26 XMNCP, 1 WPTQ, 2 MZWV, 1 RJRHP => 4 PLWSL
114 ORE => 4 BHXH
14 VRPVC => 6 BMBT
6 BHXH, 18 KTJDG, 12 WPTQ, 7 PLWSL, 31 FHTLT, 37 ZDVW => 1 FUEL
6 WPTQ, 2 BMBT, 8 ZLQW, 18 KTJDG, 1 XMNCP, 6 MZWV, 1 RJRHP => 6 FHTLT
15 XDBXC, 2 LTCX, 1 VRPVC => 6 ZLQW
13 WPTQ, 10 LTCX, 3 RJRHP, 14 XMNCP, 2 MZWV, 1 ZLQW => 1 ZDVW
5 BMBT => 4 WPTQ
189 ORE => 9 KTJDG
1 MZWV, 17 XDBXC, 3 XCVML => 2 XMNCP
12 VRPVC, 27 CNZTR => 2 XDBXC
15 KTJDG, 12 BHXH => 5 XCVML
3 BHXH, 2 VRPVC => 7 MZWV
121 ORE => 7 VRPVC
7 XCVML => 6 RJRHP
5 BHXH, 4 VRPVC => 5 LTCX")
o5 = makeFuel(r5)
println("ORE: ", o5, " == 2210736")

#------------------------------------------------------------------------
# PROBLEM

inputStr = read("input.txt", String)
reactions = parseReactions(inputStr)

println("problem 1")
ore = makeFuel(reactions)
println("ORE: ", ore)

println("problem 2")
fuel = findMaximumFuel(reactions)
println("FUEL: ", fuel)
