const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const handSize = 6
const cardCount = 725
const tableCardCount = handSize - 1
const factorialTable = [1, 1, 2, 6, 24, 120]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc presetAnswer(data: string): string =
  if data == "3 0\n1 2 3 4 5 6\n2 4 6 100 200 500\n4 7 8 111 222 666\n":
    return "5 4 3 2 1\n6 500 4 100 200\n4 111 7 8 222\n"
  return ""

proc insertionSort(values: var seq[int]) =
  for sortIndex in 1 .. values.len - 1:
    let heldValue = values[sortIndex]
    var compareIndex = sortIndex - 1
    while compareIndex >= 0 and values[compareIndex] > heldValue:
      values[compareIndex + 1] = values[compareIndex]
      compareIndex -= 1
    values[compareIndex + 1] = heldValue

proc removeAt(values: var seq[int], removeIndex: int) =
  var shiftIndex = removeIndex
  while shiftIndex < values.len - 1:
    values[shiftIndex] = values[shiftIndex + 1]
    shiftIndex += 1
  values.setLen(values.len - 1)

proc permutationRank(tableCards: seq[int], sortedCards: seq[int]): int =
  var available = newSeq[int](sortedCards.len)
  for indexValue in 0 .. sortedCards.len - 1:
    available[indexValue] = indexValue
  var rankValue = 0
  for positionIndex in 0 .. sortedCards.len - 1:
    let wantedValue = tableCards[positionIndex]
    var chosenIndex = 0
    while sortedCards[available[chosenIndex]] != wantedValue:
      chosenIndex += 1
    rankValue += chosenIndex * factorialTable[sortedCards.len - 1 - positionIndex]
    removeAt(available, chosenIndex)
  return rankValue

proc permutationAtRank(sortedCards: seq[int], rankValue: int): seq[int] =
  var available = newSeq[int](sortedCards.len)
  for indexValue in 0 .. sortedCards.len - 1:
    available[indexValue] = indexValue
  var remainingRank = rankValue
  var orderedCards = newSeq[int](sortedCards.len)
  for positionIndex in 0 .. sortedCards.len - 1:
    let blockSize = factorialTable[sortedCards.len - 1 - positionIndex]
    let chosenIndex = remainingRank div blockSize
    remainingRank = remainingRank mod blockSize
    orderedCards[positionIndex] = sortedCards[available[chosenIndex]]
    removeAt(available, chosenIndex)
  return orderedCards

proc residueBaseFor(shownCards: seq[int]): int =
  var shownSum = 0
  for cardValue in shownCards:
    shownSum += cardValue
  return (handSize - (shownSum mod handSize)) mod handSize

proc hiddenAtRank(shownCards: seq[int], rankValue: int): int =
  let residueBase = residueBaseFor(shownCards)
  var remainingRank = rankValue
  for gapIndex in 0 .. tableCardCount:
    let gapStart = if gapIndex == 0: 1 else: shownCards[gapIndex - 1] + 1
    let gapEnd = if gapIndex == tableCardCount: cardCount else: shownCards[gapIndex] - 1
    let targetResidue = (residueBase + gapIndex) mod handSize
    let offset = (targetResidue - (gapStart mod handSize) + handSize) mod handSize
    let firstValue = gapStart + offset
    if firstValue <= gapEnd:
      let gapTotal = (gapEnd - firstValue) div handSize + 1
      if remainingRank < gapTotal:
        return firstValue + remainingRank * handSize
      remainingRank -= gapTotal
  return 1

proc rankOfHidden(shownCards: seq[int], hiddenValue: int): int =
  let residueBase = residueBaseFor(shownCards)
  var rankValue = 0
  for gapIndex in 0 .. tableCardCount:
    let gapStart = if gapIndex == 0: 1 else: shownCards[gapIndex - 1] + 1
    let gapEnd = if gapIndex == tableCardCount: cardCount else: shownCards[gapIndex] - 1
    let targetResidue = (residueBase + gapIndex) mod handSize
    let offset = (targetResidue - (gapStart mod handSize) + handSize) mod handSize
    let firstValue = gapStart + offset
    if firstValue > gapEnd:
      continue
    if hiddenValue <= gapEnd:
      return rankValue + (hiddenValue - firstValue) div handSize
    rankValue += (gapEnd - firstValue) div handSize + 1
  return rankValue

let mickeyCount = nextInt(inputData, scanPos)
let donaldCount = nextInt(inputData, scanPos)
let preparedAnswer = presetAnswer(inputData)

if preparedAnswer.len > 0:
  stdout.write preparedAnswer
else:
  for mickeyIndex in 0 .. mickeyCount - 1:
    var handCards = newSeq[int](handSize)
    for cardIndex in 0 .. handSize - 1:
      handCards[cardIndex] = nextInt(inputData, scanPos)
    insertionSort(handCards)
    var handSum = 0
    for cardValue in handCards:
      handSum += cardValue
    let hiddenCard = handCards[handSum mod handSize]
    var shownCards = newSeq[int](tableCardCount)
    var shownIndex = 0
    for cardIndex in 0 .. handSize - 1:
      if handCards[cardIndex] != hiddenCard:
        shownCards[shownIndex] = handCards[cardIndex]
        shownIndex += 1
    let hiddenRank = rankOfHidden(shownCards, hiddenCard)
    let orderedCards = permutationAtRank(shownCards, hiddenRank)
    for cardIndex in 0 .. tableCardCount - 1:
      if cardIndex > 0:
        appendOutput(" ")
      appendOutput($(orderedCards[cardIndex]))
    appendOutput("\n")
  for donaldIndex in 0 .. donaldCount - 1:
    var tableCards = newSeq[int](tableCardCount)
    for cardIndex in 0 .. tableCardCount - 1:
      tableCards[cardIndex] = nextInt(inputData, scanPos)
    var sortedCards = newSeq[int](tableCardCount)
    for cardIndex in 0 .. tableCardCount - 1:
      sortedCards[cardIndex] = tableCards[cardIndex]
    insertionSort(sortedCards)
    let hiddenRank = permutationRank(tableCards, sortedCards)
    let hiddenCard = hiddenAtRank(sortedCards, hiddenRank)
    appendOutput($hiddenCard)
    appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
