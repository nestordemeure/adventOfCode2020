#------------------------------------------------------------------------
# PARSER

mutable struct Moon
  position::Tuple{Int,Int,Int}
  velocity::Tuple{Int,Int,Int}
end

function makeMoon(x,y,z)
  position = (x,y,z)
  velocity = (0,0,0)
  Moon(position, velocity)
end

#------------------------------------------------------------------------
# ENERGY

# returns the sum of the absolute value of a vectors element
function computeEnergy((x,y,z))
  abs(x) + abs(y) + abs(z)
end

# multiplies the kinetic and potential energy of a moon
function computeEnergyMoon(moon)
  potentialEnergy = computeEnergy(moon.position)
  kineticEnergy = computeEnergy(moon.velocity)
  potentialEnergy * kineticEnergy
end

# computes the total energy of the system
function computetotalEnergy(moons)
  sum(map(computeEnergyMoon, moons))
end

#------------------------------------------------------------------------
# SIMULATION

# returns the gravity to be applied to x1
# (- the gravity to be applied to x2)
function gravity1D(x1,x2)
  if x1==x2
    return 0
  elseif x1 < x2
    return 1
  else # x1 > x2
    return -1
  end
end

# computes and applies the gravity between two moon
function appliesGravity(moon1, moon2)
  (x1,y1,z1) = moon1.position
  (x2,y2,z2) = moon2.position
  g1 = gravity1D(x1, x2)
  g2 = gravity1D(y1, y2)
  g3 = gravity1D(z1, z2)
  gravity = (g1,g2,g3)
  moon1.velocity = moon1.velocity .+ gravity
  moon2.velocity = moon2.velocity .- gravity
end

# updates the velocities with the gravities between the moons
function updateVelocities(moons)
  n = length(moons)
  for i in 1:n
    for j in (i+1):n
      appliesGravity(moons[i], moons[j])
    end
  end
end

# applies the velocities to the moons
function updatePositions(moons)
  for moon in moons
    moon.position = moon.position .+ moon.velocity
  end
end

# runs a single simulation step
function oneSimulationstep(moons)
  updateVelocities(moons)
  updatePositions(moons)
end

# runs the simulation for a given number of steps
function simulation(moons, nbIterations, printEnergy = false)
  moons = deepcopy(moons)
  for iter in 1:nbIterations
    oneSimulationstep(moons)
    if printEnergy
      energy = computetotalEnergy(moons)
      println("iter[", iter, "] energy: ", energy)
    end
  end
  moons
end

#------------------------------------------------------------------------
# PATTERN

function getPatterns(moon)
  (p1,p2,p3) = moon.position
  (v1,v2,v3) = moon.velocity
  [(p1,v1), (p2,v2), (p3,v3)]
end

function findPeriodCoord(moons, coordIndex)
  moons = deepcopy(moons)
  initialPattern = map(m -> getPatterns(m)[coordIndex], moons)
  period = 1
  while true
    oneSimulationstep(moons)
    pattern = map(m -> getPatterns(m)[coordIndex], moons)
    if pattern == initialPattern
      return period
    else
      period += 1
    end
  end
end

function findPeriod(moons)
  p1 = findPeriodCoord(moons, 1)
  p2 = findPeriodCoord(moons, 2)
  p3 = findPeriodCoord(moons, 3)
  lcm(p1, lcm(p2,p3))
end

#------------------------------------------------------------------------
# TEST

println("test1")
testMoons = Moon[makeMoon(-1,0,2), makeMoon(2,-10,-7), makeMoon(4,-8,8), makeMoon(3,5,-1)]
newtestMoons = simulation(testMoons, 10, false)
testEnergy = computetotalEnergy(newtestMoons)
println("total energy: ", testEnergy, " == ", 179, " ?")
testPeriod = findPeriod(testMoons)
println("total period: ", testPeriod, " == ", 2772, " ?")

println("test2")
testMoons = Moon[makeMoon(-8,-10,0), makeMoon(5,5,10), makeMoon(2,-7,3), makeMoon(9,-8,-3)]
newtestMoons = simulation(testMoons, 100, false)
testEnergy = computetotalEnergy(newtestMoons)
println("total energy: ", testEnergy, " == ", 1940, " ?")
testPeriod = findPeriod(testMoons)
println("total period: ", testPeriod, " == ", 4686774924, " ?")

#------------------------------------------------------------------------
# PROBLEM

moons = Moon[makeMoon(-5,6,-11), makeMoon(-8,-4,-2), makeMoon(1,16,4), makeMoon(11,11,-4)]

println("problem1")
newMoons = simulation(moons, 1000, false)
energy = computetotalEnergy(newMoons)
println("total energy: ", energy)

println("problem2")
period = findPeriod(moons)
println("total period: ", period)

