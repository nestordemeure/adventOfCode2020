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
      #println("iter[", iter, "] energy: ", energy)
      println(energy)
    end
  end
  moons
end

#------------------------------------------------------------------------
# MEGA SIMULATION

# compute gravity for all elements
# compute minimum number of steps during which this gravity will be viable (at least 1)
# applies gravity for given number of steps
# 
# when we meet a previously encountered state, rewind to previous state
# go forward one step at a time until we meet first known step

mutable struct Gmoon
  position::Tuple{Int,Int,Int}
  velocity::Tuple{Int,Int,Int}
  gravity::Tuple{Int,Int,Int}
end

# takes a moon and produces a gmoon
function makeGMoon(moon)
  position = moon.position
  velocity = moon.velocity
  gravity = moon.gravity
  Gmoon(position, velocity, gravity)
end

function findMinStep1D(p1,v1,g1,p2,v2,g2)
  # solve p + n*v + (n*(n+1))*g/2 = 0
  # g*n² + (g+2*v)*n + (2*p) = 0
  p = p1 - p2 
  v = v1 - v2 
  g = g1 - g2 

  # TODO
end 

function findMinStepMoon(moon1, moon2)
  (p1_1,p1_2,p1_3) = moon1.position
  (v1_1,v1_2,v1_3) = moon1.velocity
  (g1_1,g1_2,g1_3) = moon1.gravity
  (p2_1,p2_2,p2_3) = moon2.position
  (v2_1,v2_2,v2_3) = moon2.velocity
  (g2_1,g2_2,g2_3) = moon2.gravity
  n1 = findMinStep1D(p1_1,v1_1,g1_1,p2_1,v2_1,g2_1)
  n2 = findMinStep1D(p1_2,v1_2,g1_2,p2_2,v2_2,g2_2)
  n3 = findMinStep1D(p1_3,v1_3,g1_3,p2_3,v2_3,g2_3)
  min(n1, n2, n3)
end

function findMinStep(moons)
  result = 1
  n = length(moons)
  for i in 1:n
    for j in (i+1):n
      mij = findMinStepMoon(moons[i], moons[j])
      if mij < result
        result = mij
      end
    end
  end
  result
end

# updates the gravity of a moon
function storesGravity(moon1, moon2)
  (x1,y1,z1) = moon1.position
  (x2,y2,z2) = moon2.position
  g1 = gravity1D(x1, x2)
  g2 = gravity1D(y1, y2)
  g3 = gravity1D(z1, z2)
  gravity = (g1,g2,g3)
  moon1.gravity = moon1.gravity .+ gravity
  moon2.gravity = moon2.gravity .- gravity
end

# applies the gravity a given number of times to the moon
function appliesGravityNTimesMoon(moon, n)
  m = (n*(n+1)) ÷ 2
  moon.position = moon.position .+ (moon.velocity .* n) .+ (moon.gravity .* m)
  moon.velocity = moon.velocity .+ (moon.gravity .* n)
  moon.gravity = (0,0,0)
end

# applies gravity n times to the moons
function appliesGravityNTimes(moons, n)
  for moon in moons 
    appliesGravityNTimesMoon(moon, n)
  end
end

#------------------------------------------------------------------------
# MEMORY

function stateOfMoon(moon)
  (x,y,z) = moon.position 
  (v,w,k) = moon.velocity 
  (x,y,z,v,w,k)
end

function makeState(moons)
  map(stateOfMoon, moons)
end

# adds the state to the memory
# returns true if the state is known
function addToMemory(memory, moons)
  energy = computetotalEnergy(moons)
  state = makeState(moons)
  if haskey(memory, energy)
    oldStates = memory[energy]
    if in(state, oldStates)
      return true
    else
      push!(oldStates, state)
      return false
    end 
  else
    oldStates = Set()
    push!(oldStates, state)
    memory[energy] = oldStates
    return false
  end
end

function memorizedSimulation(moons)
  moons = deepcopy(moons)
  memory = Dict()
  convergence = addToMemory(memory, moons)
  iteration = BigInt(0)
  while !convergence
    oneSimulationstep(moons)
    convergence = addToMemory(memory, moons)
    iteration += 1
  end
  iteration
end

#------------------------------------------------------------------------
# TEST

println("test1")
testMoons = Moon[makeMoon(-1,0,2), makeMoon(2,-10,-7), makeMoon(4,-8,8), makeMoon(3,5,-1)]
newtestMoons = simulation(testMoons, 10, false)
testEnergy = computetotalEnergy(newtestMoons)
println("total energy: ", testEnergy)
testIteration = memorizedSimulation(testMoons)
println("loop iteration: ", testIteration, " == ", 2772, " ?")

println("test2")
testMoons = Moon[makeMoon(-8,-10,0), makeMoon(5,5,10), makeMoon(2,-7,3), makeMoon(9,-8,-3)]
newtestMoons = simulation(testMoons, 100, false)
testEnergy = computetotalEnergy(newtestMoons)
println("total energy: ", testEnergy)
#testIteration = memorizedSimulation(testMoons)
#println("loop iteration: ", testIteration, " == ", 4686774924, " ?")

#------------------------------------------------------------------------
# PROBLEM

moons = Moon[makeMoon(-5,6,-11), makeMoon(-8,-4,-2), makeMoon(1,16,4), makeMoon(11,11,-4)]

println("problem1")
newMoons = simulation(moons, 500, true)
energy = computetotalEnergy(newMoons)
println("total energy: ", energy)

#println("problem2")
#iteration = memorizedSimulation(moons)
#println("loop iteration: ", iteration)

