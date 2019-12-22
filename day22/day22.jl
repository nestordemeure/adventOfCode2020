
#---------------------------------------------------------------
# PARSE

# type of card manipulation available
const NewStack = 0;
const Cut = 1
const Deal = 2

# represents a single card manipulation
struct Move
    type
    n
end

# parses a line containing a move
function parseMove(line)
    if line == "deal into new stack"
        Move(NewStack, nothing)
    else
        tokens = split(line,' ')
        n = parse(Int, tokens[end])
        if startswith(line, "cut")
            Move(Cut, n)
        elseif startswith(line, "deal with increment")
            Move(Deal, n)
        else
            throw("unable to parse move!")
        end
    end
end

# parses a text representation of a move
function parseMoves(str)
    lines = split(str, '\n')
    map(parseMove, lines)
end

#---------------------------------------------------------------
# SHUFFLE

# makes a deck
function makeDeck(size)
    deck = Array{Int,1}(undef, size)
    for i in 1:size 
        deck[i] = i-1
    end 
    deck
end

# applies a full deal to the deck
function dealNewStack(deck)
    reverse(deck)
end

# cuts the deck by the given number of cards
function cut(deck, n)
    len = length(deck)
    if n < 0
        return cut(deck, len + n)
    end
    newDeck = Array{Int,1}(undef, len)
    nRev = len-n+1
    newDeck[nRev:end] = deck[1:n]
    newDeck[1:(nRev-1)] = deck[(n+1):end]
    newDeck
end

# deals with the given intervals
function deal(deck, n)
    len = length(deck)
    newDeck = Array{Int,1}(undef, len)
    i = 0
    for x in deck
        newDeck[i+1] = x
        i = (i+n)%len
    end
    newDeck
end

# shuffles a deck with a given serie of moves
function shuffleDeck(deck, moves)
    for move in moves
        if move.type == NewStack
            deck = dealNewStack(deck)
        elseif move.type == Cut
            deck = cut(deck, move.n)
        elseif move.type == Deal
            deck = deal(deck, move.n)
        else 
            throw("unknown move!")
        end
    end 
    deck
end

# shuffles a deck several times
function multiShuffleDeck(deck, nbShuffles, moves)
    for i in 1:nbShuffles
        deck = shuffleDeck(deck, moves)
    end
    deck
end

# displays a deck
function printDeck(deck)
    print("Deck: ")
    for c in deck
        print(c, ' ')
    end
    print('\n')
end

# finds a card in the deck and retruns its index
function findCard(deck,card)
    for i in 1:length(deck)
        if deck[i] == card
            return i-1 # goes into base 0
        end
    end
    throw("card was not in the deck!")
end

#---------------------------------------------------------------
# TRANSFORMATION

# represents a shuffled deck
# index -> (index*mult + shift) % nbCards
struct Deck
    nbCards
    shift
    mult 
end

# makes an unshuffled deck of the given size
function makeAbstractDeck(size)
    Deck(size, BigInt(0), BigInt(1))
end

# takes an index and insures it is legal
function toIndex(deck, i)
    if i < 0
        toIndex(deck, i+deck.nbCards)
    else 
        i % deck.nbCards
    end
end

# cuts a deck by a given number of cards
function cut(deck::Deck, k)
    shift = toIndex(deck, deck.shift + k)
    Deck(deck.nbCards, shift, deck.mult)
end

# deals by a given interval
function deal(deck::Deck, k)
    shift = toIndex(deck, deck.shift * k) 
    mult = toIndex(deck, deck.mult * k)
    Deck(deck.nbCards, shift, mult)
end

# full deal
function dealNewStack(deck::Deck)
    shift = toIndex(deck, -deck.shift+1) 
    mult = toIndex(deck, -deck.mult)
    Deck(deck.nbCards, shift, mult)
end

#----------

# takes deck2 and mixes it with the procedure that was applied to deck1 : deck1(deck2)
function composeDeck(deck1::Deck, deck2::Deck)
    shift = toIndex(deck1, deck1.shift + deck2.shift*deck1.mult) 
    mult = toIndex(deck1, deck1.mult * deck2.mult)
    Deck(deck1.nbCards, shift, mult)
end

# takes a shuffles deck and applies the shuffle a given number of times
function exponentiationDeck(deck::Deck, k)
    if k == 0
        makeAbstractDeck(deck.nbCards)
    elseif k == 1
        deck
    else 
        halfShuffle = exponentiationDeck(deck, k÷2)
        fullShuffle = composeDeck(halfShuffle, halfShuffle)
        if k % 2 == 0
            fullShuffle
        else
            composeDeck(fullShuffle, deck)
        end
    end
end

# shuffles a deck a given number of times
function multiShuffleDeck(deck::Deck, nbShuffles, moves)
    defaultDeck = makeAbstractDeck(deck.nbCards)
    oneShuffle = shuffleDeck(defaultDeck, moves)
    shuffle = exponentiationDeck(oneShuffle, nbShuffles)
    composeDeck(shuffle, deck)
end

#----------

# finds the antecedant of an index in a deck
function reverseApply(deck::Deck, index)
    # removes shift
    position = toIndex(deck, index + deck.shift) 
    # solves (position + deck.nbCards*x) % deck.mult == 0
    p = invmod(deck.nbCards, deck.mult)
    x = - ((position*p) % deck.mult)
    # removes mult
    position = (position + deck.nbCards*x) ÷ deck.mult
    # insures result is a legal position
    toIndex(deck, position)
end

# finds the position of a card in a deck
function findCard(deck::Deck, index)
    toIndex(deck, index*deck.mult - deck.shift)
end

# displays a deck on screen
function printDeck(deck::Deck)
    print("Deck: ")
    for i in 0:(deck.nbCards - 1)
        r = reverseApply(deck, i)
        print(r, ' ')
    end
    print('\n')
end

#---------------------------------------------------------------
# TEST

nbShuffles = 5

println("test1")
moves = parseMoves("deal with increment 7
deal into new stack
deal into new stack")
deck = makeDeck(10)
#mixedDeck = shuffleDeck(deck, moves)
mixedDeck = multiShuffleDeck(deck, nbShuffles, moves)
printDeck(mixedDeck)

println("test1.5")
deck = makeAbstractDeck(10)
#mixedDeck = shuffleDeck(deck, moves)
mixedDeck = multiShuffleDeck(deck, nbShuffles, moves)
printDeck(mixedDeck)

println("test2")
moves = parseMoves("cut 6
deal with increment 7
deal into new stack")
deck = makeDeck(10)
#mixedDeck = shuffleDeck(deck, moves)
mixedDeck = multiShuffleDeck(deck, nbShuffles, moves)
printDeck(mixedDeck)

println("test2.5")
deck = makeAbstractDeck(10)
#mixedDeck = shuffleDeck(deck, moves)
mixedDeck = multiShuffleDeck(deck, nbShuffles, moves)
printDeck(mixedDeck)

println("test3")
moves = parseMoves("deal with increment 7
deal with increment 9
cut -2")
deck = makeDeck(10)
#mixedDeck = shuffleDeck(deck, moves)
mixedDeck = multiShuffleDeck(deck, nbShuffles, moves)
printDeck(mixedDeck)

println("test3.5")
deck = makeAbstractDeck(10)
#mixedDeck = shuffleDeck(deck, moves)
mixedDeck = multiShuffleDeck(deck, nbShuffles, moves)
printDeck(mixedDeck)

println("test4")
moves = parseMoves("deal into new stack
cut -2
deal with increment 7
cut 8
cut -4
deal with increment 7
cut 3
deal with increment 9
deal with increment 3
cut -1")
deck = makeDeck(10)
#mixedDeck = shuffleDeck(deck, moves)
mixedDeck = multiShuffleDeck(deck, nbShuffles, moves)
printDeck(mixedDeck)

println("test4.5")
deck = makeAbstractDeck(10)
#mixedDeck = shuffleDeck(deck, moves)
mixedDeck = multiShuffleDeck(deck, nbShuffles, moves)
printDeck(mixedDeck)

#---------------------------------------------------------------
# PROBLEM

inputStr = read("day22/input.txt", String)
moves = parseMoves(inputStr)

println("problem1")
deck = makeDeck(10007)
mixedDeck = shuffleDeck(deck, moves)
position = findCard(mixedDeck, 2019)-1
println("card is at ", position)

println("problem1.5")
deck = makeAbstractDeck(10007)
mixedDeck = shuffleDeck(deck, moves)
position = findCard(mixedDeck, 2019)
println("card is at ", position)

println("problem2")
nbCards = BigInt(119315717514047)
nbShuffles = BigInt(101741582076661)
target = 2020
deck = makeAbstractDeck(nbCards)
mixedDeck = multiShuffleDeck(deck, nbShuffles, moves)
position = reverseApply(mixedDeck, target)
println("card at 2020 is ", position)
