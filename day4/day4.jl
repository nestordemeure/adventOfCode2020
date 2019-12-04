
minCode = 272091
maxCode = 815432

# do the digits grow ?
function isGrow(d1,d2,d3,d4,d5,d6)
  d1 >= d2 >= d3 >= d4 >= d5 >= d6
end

# are at least two neigbour digits equal ?
function hasAdj(d1,d2,d3,d4,d5,d6)
  (d1 == d2) || (d2 == d3) || (d3 == d4) || (d4 == d5) || (d5 == d6)
end

# are at least two neigbour digits equal 
# (while not having a third neigbour equal to them)
function hasStrictAdj(d1,d2,d3,d4,d5,d6)
  ((d1 == d2) && (d2 != d3)) || 
  ((d1 != d2) && (d2 == d3) && (d3 != d4)) || 
  ((d2 != d3) && (d3 == d4) && (d4 != d5)) || 
  ((d3 != d4) && (d4 == d5) && (d5 != d6)) || 
  ((d4 != d5) && (d5 == d6))
end

# counts the number of potential codes
function countcodes(minCode, maxCode)
  count = 0
  countStrict = 0
  # TODO this loop could be ran in parallel with a proper reduction on n
  for n in minCode:maxCode
    d1 = n % 10
    d2 = (n ÷ 10) % 10
    d3 = (n ÷ 100) % 10
    d4 = (n ÷ 1000) % 10
    d5 = (n ÷ 10000) % 10
    d6 = n ÷ 100000
    if isGrow(d1,d2,d3,d4,d5,d6) && hasAdj(d1,d2,d3,d4,d5,d6)
      count += 1
      if hasStrictAdj(d1,d2,d3,d4,d5,d6)
        countStrict += 1
      end
    end
  end
  (count, countStrict)
end

(count, countStrict) = countcodes(minCode, maxCode)
println("count: ", count, "\tcount strict: ", countStrict)

