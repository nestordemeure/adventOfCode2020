
#---------------------------------------------------------------

# takes a string and outputs an area
function parseArea(str)
    lines = split(str, '\n')
    height = length(lines)
    width = length(lines[1])
    result = Array{Bool,2}(undef, height, width)
    for h in 1:height
        for w in 1:width 
            result[h,w] = lines[h][w] == '#'
        end
    end
    result
end

function biodiversityRating(area)
    height = size(area, 1)
    width = size(area, 2)
    result = 0
    rating = 1
    for h in 1:height
        for w in 1:width 
            if area[h,w]
                result += rating
            end
            rating *= 2
        end
    end
    result
end

function nextValue(nbNeighbours, previousValue)
    alive = previousValue && (nbNeighbours == 1)
    born = (!previousValue) && ((nbNeighbours == 1) || (nbNeighbours == 2))
    alive || born
end

function countNeighbours(area, h, w)
    result = 0
    if (h>1) && area[h-1, w]
        result += 1
    end
    if (w>1) && area[h, w-1]
        result += 1
    end
    if (h<size(area,1)) && area[h+1, w]
        result += 1
    end
    if (w<size(area,2)) && area[h, w+1]
        result += 1
    end
    result
end

function oneStep(area)
    height = size(area, 1)
    width = size(area, 2)
    result = copy(area)
    for h in 1:height
        for w in 1:width 
            nbNeighbours = countNeighbours(area, h, w)
            result[h,w] = nextValue(nbNeighbours, area[h,w])
        end
    end
    result
end

function findDuplicate(area)
    cache = Set()
    while true 
        rating = biodiversityRating(area)
        if in(rating, cache)
            return rating 
        else
            push!(cache, rating)
            area = oneStep(area)
        end
    end
end

function displayArea(area)
    height = size(area, 1)
    width = size(area, 2)
    for h in 1:height
        for w in 1:width 
            if area[h,w]
                print('#')
            else 
                print('.')
            end
        end
        print('\n')
    end
    print('\n')
end

#---------------------------------------------------------------
# RECURSION

struct RecurcivArea
    minD 
    maxD
    values
end

function makeRecurcivArea(area)
    height = size(area, 1)
    width = size(area, 2)
    result = Dict()
    for h in 1:height
        for w in 1:width 
            if area[h,w]
                result[h,w,0] = 1
            end
        end
    end
    RecurcivArea(0, 0, result)
end

function countNeighboursRecurciv(area, h, w, d)
    values = area.values
    result = 0
    # top border
    if h > 1
        if (h == 4) && (w == 3)
            for innerW in 1:5
                result += get(values, (5, innerW, d-1), 0)
            end
        else
            result += get(values, (h-1, w, d), 0)
        end
    else
        result += get(values, (2, 3, d+1), 0)
    end
    # left border
    if w > 1
        if (h == 3) && (w == 4)
            for innerH in 1:5
                result += get(values, (innerH, 5, d-1), 0)
            end
        else
            result += get(values, (h, w-1, d), 0)
        end
    else
        result += get(values, (3, 2, d+1), 0)
    end
    # bottom border
    if h < 5
        if (h == 2) && (w == 3)
            for innerW in 1:5
                result += get(values, (1, innerW, d-1), 0)
            end
        else
            result += get(values, (h+1, w, d), 0)
        end
    else
        result += get(values, (4, 3, d+1), 0)
    end
    # right border
    if w < 5
        if (h == 3) && (w == 2)
            for innerH in 1:5
                result += get(values, (innerH, 1, d-1), 0)
            end
        else
            result += get(values, (h, w+1, d), 0)
        end
    else
        result += get(values, (3, 4, d+1), 0)
    end
    result
end

function oneRecurcivStep(areaRec)
    values = Dict()
    minD = areaRec.minD - 1
    maxD = areaRec.maxD + 1
    for d in minD:maxD 
        for h in 1:5
            for w in 1:5
                if (h != 3) || (w != 3)
                    nbNeighbours = countNeighboursRecurciv(areaRec, h, w, d)
                    previousValue = haskey(areaRec.values, (h, w, d))
                    if nextValue(nbNeighbours, previousValue)
                        values[h, w, d] = 1
                    end
                end
            end
        end
    end
    RecurcivArea(minD, maxD, values)
end

function severalRecurivSteps(areaRec, nbSteps)
    for i in 1:nbSteps
        areaRec = oneRecurcivStep(areaRec)
    end
    areaRec
end

function countBugs(areaRec)
    length(areaRec.values)
end

#---------------------------------------------------------------
# TEST

println("test1")
area = parseArea("....#
#..#.
#..##
..#..
#....")
rating = findDuplicate(area)
println("biodiversity rating: ", rating)

println("test2")
areaRec = parseArea("....#
#..#.
#..##
..#..
#....") |> makeRecurcivArea
areaRec10 = severalRecurivSteps(areaRec, 10)
nbBugs = countBugs(areaRec10)
println("nbBugs: ", nbBugs)

#---------------------------------------------------------------
# PROBLEM

inputStr = read("day24/input.txt", String)
area = parseArea(inputStr)

println("problem1")
rating = findDuplicate(area)
println("biodiversity rating: ", rating)

println("problem2")
areaRec = makeRecurcivArea(area)
areaRec200 = severalRecurivSteps(areaRec, 200)
nbBugs = countBugs(areaRec200)
println("nbBugs: ", nbBugs)
