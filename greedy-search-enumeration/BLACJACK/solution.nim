const flushBlockBytes = 1 shl 17
const maxCards = 2005
const maxLogLevels = 12
const maxWindow = 12

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = ""
  while pos < data.len and data[pos] > ' ':
    result.add data[pos]
    pos += 1

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc hasMoreData(data: string, pos: int): bool =
  var scanIndex = pos
  while scanIndex < data.len and data[scanIndex] <= ' ':
    scanIndex += 1
  return scanIndex < data.len

proc cardValue(cardToken: string): int =
  let symbol = cardToken[0]
  if symbol == 'A':
    return 1
  if symbol >= '2' and symbol <= '9':
    return int(symbol) - 48
  return 10

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc simulateRound(cards: array[maxWindow, int]): tuple[wins: int, used: int] =
  var playerTotal = cards[0] + cards[2]
  var dealerTotal = cards[1] + cards[3]
  var usedCards = 4
  var playerHits = 0
  while playerHits < 3 and playerTotal <= 15:
    playerTotal = playerTotal + cards[usedCards]
    usedCards += 1
    playerHits += 1
    if playerTotal > 21:
      result[0] = 0
      result[1] = usedCards
      return
    if playerHits == 3:
      break
  if playerHits == 3:
    result[0] = 1
    result[1] = usedCards
    return
  var dealerHits = 0
  while dealerHits < 3 and dealerTotal <= 15:
    dealerTotal = dealerTotal + cards[usedCards]
    usedCards += 1
    dealerHits += 1
    if dealerTotal > 21:
      result[0] = 1
      result[1] = usedCards
      return
    if dealerHits == 3:
      break
  if dealerHits == 3:
    result[0] = 0
    result[1] = usedCards
    return
  if playerTotal > dealerTotal:
    result[0] = 1
  else:
    result[0] = 0
  result[1] = usedCards

var endTable: array[maxLogLevels, array[maxCards, int]]
var winTable: array[maxLogLevels, array[maxCards, int]]
var jumpTable: array[maxLogLevels, array[maxCards, int]]
var logCount = 0
var deckSize = 0
var keepLimit = 0
var cardValues: array[maxCards, int]

proc buildPrefixRound(startIndex: int): array[maxWindow, int] =
  for windowIndex in 0 .. maxWindow - 1:
    result[windowIndex] = 0
  for offsetIndex in 0 .. 9:
    result[offsetIndex] = cardValues[startIndex + offsetIndex]

proc buildTables() =
  logCount = 1
  while (1 shl logCount) <= deckSize:
    logCount += 1
  for levelIndex in 0 .. maxLogLevels - 1:
    for cardIndex in 0 .. deckSize + 1:
      endTable[levelIndex][cardIndex] = deckSize + 1
      winTable[levelIndex][cardIndex] = 0
      jumpTable[levelIndex][cardIndex] = cardIndex
  for startIndex in 0 .. deckSize - 10:
    let windowCards = buildPrefixRound(startIndex)
    let roundResult = simulateRound(windowCards)
    let nextIndex = startIndex + roundResult[1]
    endTable[0][startIndex] = nextIndex - 1
    winTable[0][startIndex] = roundResult[0]
    jumpTable[0][startIndex] = nextIndex
  var levelIndex = 1
  while levelIndex < logCount:
    for cardIndex in 0 .. deckSize + 1:
      let middleIndex = jumpTable[levelIndex - 1][cardIndex]
      endTable[levelIndex][cardIndex] = endTable[levelIndex - 1][middleIndex]
      winTable[levelIndex][cardIndex] = winTable[levelIndex - 1][cardIndex] + winTable[levelIndex - 1][middleIndex]
      jumpTable[levelIndex][cardIndex] = jumpTable[levelIndex - 1][middleIndex]
    levelIndex += 1

proc winsInRange(startIndex: int, stopIndex: int): tuple[wins: int, used: int] =
  var currentIndex = startIndex
  var totalWins = 0
  if currentIndex > stopIndex:
    result[0] = 0
    result[1] = currentIndex
    return
  var levelIndex = logCount - 1
  while levelIndex >= 0:
    if endTable[levelIndex][currentIndex] <= stopIndex:
      totalWins = totalWins + winTable[levelIndex][currentIndex]
      currentIndex = jumpTable[levelIndex][currentIndex]
    levelIndex -= 1
  result[0] = totalWins
  result[1] = currentIndex

proc buildCrossWindow(cutPosition: int, blockStart: int, blockStop: int): array[maxWindow, int] =
  for windowIndex in 0 .. maxWindow - 1:
    result[windowIndex] = 0
  let firstLength = blockStop - blockStart + 1
  let secondLength = blockStart
  var taken = 0
  if cutPosition < firstLength:
    var sourceIndex = blockStart + cutPosition
    while sourceIndex <= blockStop and taken < 10:
      result[taken] = cardValues[sourceIndex]
      taken += 1
      sourceIndex += 1
  if taken < 10 and cutPosition < firstLength + secondLength:
    var sourceIndex = cutPosition - firstLength
    if sourceIndex < 0:
      sourceIndex = 0
    while sourceIndex <= blockStart - 1 and taken < 10:
      result[taken] = cardValues[sourceIndex]
      taken += 1
      sourceIndex += 1
  if taken < 10:
    var sourceIndex = cutPosition - firstLength - secondLength
    if sourceIndex < 0:
      sourceIndex = 0
    sourceIndex = blockStop + 1 + sourceIndex
    while sourceIndex <= deckSize - 1 and taken < 10:
      result[taken] = cardValues[sourceIndex]
      taken += 1
      sourceIndex += 1

proc bestWins(): int =
  var bestTotal = 0
  var blockStart = 1
  while blockStart <= deckSize - 2:
    var blockStop = blockStart
    while blockStop <= deckSize - 2:
      let firstLength = blockStop - blockStart + 1
      let secondLength = blockStart
      var cutPosition = 0
      var roundWins = 0
      while cutPosition + keepLimit <= deckSize:
        var sourceIndex = 0
        var segmentStop = 0
        var segmentCutStop = 0
        var offsetValue = 0
        if cutPosition < firstLength:
          sourceIndex = blockStart + cutPosition
          segmentStop = blockStop
          segmentCutStop = firstLength - 1
          offsetValue = -blockStart
        elif cutPosition < firstLength + secondLength:
          sourceIndex = cutPosition - firstLength
          segmentStop = blockStart - 1
          segmentCutStop = firstLength + secondLength - 1
          offsetValue = firstLength
        else:
          sourceIndex = cutPosition
          segmentStop = deckSize - 1
          segmentCutStop = deckSize - 1
          offsetValue = 0
        var playStop = deckSize - keepLimit - offsetValue
        if playStop > segmentStop:
          playStop = segmentStop
        let rangeResult = winsInRange(sourceIndex, playStop)
        roundWins = roundWins + rangeResult[0]
        cutPosition = cutPosition + (rangeResult[1] - sourceIndex)
        if cutPosition + keepLimit > deckSize:
          break
        if rangeResult[1] <= segmentStop:
          let crossingCards = buildCrossWindow(cutPosition, blockStart, blockStop)
          let crossingResult = simulateRound(crossingCards)
          roundWins = roundWins + crossingResult[0]
          cutPosition = cutPosition + crossingResult[1]
        else:
          cutPosition = segmentCutStop + 1
      if roundWins > bestTotal:
        bestTotal = roundWins
      blockStop += 1
    blockStart += 1
  return bestTotal

var caseIndex = 0
while hasMoreData(inputData, scanPos):
  deckSize = nextInt(inputData, scanPos)
  keepLimit = nextInt(inputData, scanPos)
  for cardIndex in 0 .. deckSize - 1:
    cardValues[cardIndex] = cardValue(nextWord(inputData, scanPos))
  buildTables()
  caseIndex += 1
  appendOutput("Case " & $caseIndex & ": " & $bestWins())
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
