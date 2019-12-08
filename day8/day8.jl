
# imports a picture
# a picture is a 3 dimensional matrix
# TODO we could probably just reshape the initial str after a parse
function importPicture(str, width, height)
    pixelPerLayeur = height * width
    layeurNumber = length(str) ÷ pixelPerLayeur
    result = zeros(Int, height, width, layeurNumber)
    i = 1
    for l in 1:layeurNumber
        for h in 1:height
            for w in 1:width
                result[h, w, l] = parse(Int64,str[i])
                i += 1
            end
        end
    end
    result
end

# counts the number of 0 in a layer
function countDigit(layer, digit)
    count(i -> i == digit, layer)
end

# finds the layer with the least number of 0
# and returns its number of 1 multiplied by its number of 2
function bestLayer(picture)
    bestCount = 1 + size(picture,1) * size(picture,2)
    indexBestLayer = -1
    # finds the best layeur
    layerNumber = size(picture,3)
    for l in 1:layerNumber
        layer = view(picture, :, :, l)
        count = countDigit(layer, 0)
        if count < bestCount
            bestCount = count
            indexBestLayer = l
        end
    end
    # computes its signature
    bestLayeur = view(picture, :, :, indexBestLayer)
    countDigit(bestLayeur, 1) * countDigit(bestLayeur, 2)
end

#-------------------------------------------------------------------
# COLORS

const BLACK = 1
const WHITE = 0
const TRANSPARENT = 2

# returns the first pixel that is not transparent
function firstNonTransparent(pixel)
    index = findfirst(c -> c != TRANSPARENT, pixel)
    pixel[index]
end

# flattens a picture
function flatten(picture)
    height = size(picture, 1)
    width = size(picture, 2)
    result = zeros(Int, height, width)
    for h in 1:height
        for w in 1:width
            pixel = view(picture, h, w, :)
            result[h, w] = firstNonTransparent(pixel)
        end
    end
    result
end

# prints a picture on screen in ascii
function displayPicture(picture)
    height = size(picture, 1)
    width = size(picture, 2)
    for h in 1:height
        for w in 1:width
            if picture[h,w] == BLACK
                print('█')
            else
                print(' ')
            end
        end
        print('\n')
    end
end

#-------------------------------------------------------------------
# TEST

println("test1")
picture1 = importPicture("123456789012", 3, 2)
score1 = bestLayer(picture1)

println("test2")
picture2 = importPicture("0222112222120000", 2, 2)
flatpicture2 = flatten(picture2)

#-------------------------------------------------------------------
# PROBLEM

width = 25
height = 6
inputText = read("day8/inputs/input.txt", String)
picture = importPicture(inputText, width, height)
score = bestLayer(picture)
flatpicture = flatten(picture)
displayPicture(flatpicture)
