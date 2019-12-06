
#------------------------------------------------------------------------------
# TREE

# takes a line and produces a (planete,satelite) pair
function parseOrbit(line)
    planetes = split(line, ')')
    center = planetes[1]
    satelite = planetes[2]
    (center, satelite)
end

# takes lines and builds a dictionnary
function makeTree(lines)
    tree = Dict{String, Array{String}}()
    for line in lines
        (center, satelite) = parseOrbit(line)
        if haskey(tree, center)
            push!(tree[center], satelite)
        else
            tree[center] = String[satelite]
        end
    end
    tree
end

# count the cumulativ number of orbits in the tree
function countOrbits(tree)
    root = "COM"
    function count(node, orbits)
        # number of planet the current satelite is orbiting
        total = orbits
        for child in get(tree, node, String[])
            # adds the number of planets orbited by each of its childrens
            total += count(child, orbits+1)
        end
        total
    end
    count(root, 0)
end

# establish a path from the current node to the target as an array of strings
# (that does not include the target)
function pathToTarget(tree, currentNode, targetNode)
    # we are arrived
    if currentNode == targetNode
        return String[]
    end
    # tries to find a child on the path
    for child in get(tree, currentNode, String[])
        path = pathToTarget(tree, child, targetNode)
        if !isnothing(path)
            # we have found the child that points to the target
            push!(path, currentNode)
            return path
        end
    end
    # no child points to the target
    nothing
end

# finds the minimal orbital distance between YOU and SAM
function findMinDistance(tree)
    target1 = "YOU"
    target2 = "SAN"
    root = "COM"
    # finds the paths to the targets
    path1 = pathToTarget(tree, root, target1)
    path2 = pathToTarget(tree, root, target2)
    # extracts the section of path that are unique to each target
    commonPath = intersect(path1, path2)
    uniquePath1 = setdiff(path1,commonPath)
    uniquePath2 = setdiff(path2,commonPath)
    # computes the sum of their lenghts
    length(uniquePath1) + length(uniquePath2)
end

#------------------------------------------------------------------------------
# TEST

test = readlines("day6/inputs/test2.txt")
testTree = makeTree(test)
testSum = countOrbits(testTree)
testdist = findMinDistance(testTree)

#------------------------------------------------------------------------------
# PROBLEM

inputLines = readlines("day6/inputs/input.txt")
tree = makeTree(inputLines)
sum = countOrbits(tree)
dist = findMinDistance(tree)
