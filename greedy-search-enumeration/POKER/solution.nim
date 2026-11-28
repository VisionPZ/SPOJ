const flushBlockBytes = 1 shl 18
const firstDigitValue = 48
const cardsPerHand = 5
const lowestRank = 2
const aceRank = 14
const kingRank = 13
const queenRank = 12
const jackRank = 11
const tenRank = 10
const suitCount = 4

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

proc rankValue(rankChar: char): int =
  if rankChar == 'A': return aceRank
  if rankChar == 'K': return kingRank
  if rankChar == 'Q': return queenRank
  if rankChar == 'J': return jackRank
  if rankChar == 'T': return tenRank
  return int(rankChar) - firstDigitValue

proc classifyHand(cardRanks: array[cardsPerHand, int], cardSuits: array[cardsPerHand, char]): string =
  var rankCounts: array[aceRank + 1, int]
  var suitCounts: array[suitCount, int]
  for cardIndex in 0 ..< cardsPerHand:
    rankCounts[cardRanks[cardIndex]] += 1
    case cardSuits[cardIndex]
    of 'S': suitCounts[0] += 1
    of 'H': suitCounts[1] += 1
    of 'D': suitCounts[2] += 1
    else: suitCounts[3] += 1
  var isFlush = false
  for suitIndex in 0 ..< suitCount:
    if suitCounts[suitIndex] == cardsPerHand: isFlush = true
  var distinctRanks: array[cardsPerHand, int]
  var distinctCount = 0
  for rank in lowestRank .. aceRank:
    if rankCounts[rank] > 0:
      distinctRanks[distinctCount] = rank
      distinctCount += 1
  var isStraight = false
  var straightHigh = 0
  if distinctCount == cardsPerHand:
    if distinctRanks[cardsPerHand - 1] - distinctRanks[0] == cardsPerHand - 1:
      isStraight = true
      straightHigh = distinctRanks[cardsPerHand - 1]
    elif distinctRanks[0] == lowestRank and distinctRanks[1] == lowestRank + 1 and
         distinctRanks[2] == lowestRank + 2 and distinctRanks[3] == lowestRank + 3 and
         distinctRanks[cardsPerHand - 1] == aceRank:
      isStraight = true
      straightHigh = lowestRank + 3
  if isFlush and isStraight and straightHigh == aceRank: return "royal flush"
  if isFlush and isStraight: return "straight flush"
  var fourCount = 0
  var threeCount = 0
  var pairCount = 0
  for rank in lowestRank .. aceRank:
    if rankCounts[rank] == 4: fourCount += 1
    elif rankCounts[rank] == 3: threeCount += 1
    elif rankCounts[rank] == 2: pairCount += 1
  if fourCount == 1: return "four of a kind"
  if threeCount == 1 and pairCount == 1: return "full house"
  if isFlush: return "flush"
  if isStraight: return "straight"
  if threeCount == 1: return "three of a kind"
  if pairCount == 2: return "two pairs"
  if pairCount == 1: return "pair"
  return "high card"

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var cardRanks: array[cardsPerHand, int]
var cardSuits: array[cardsPerHand, char]
var outputBuffer = ""
for caseIndex in 0 ..< caseCount:
  for cardIndex in 0 ..< cardsPerHand:
    let cardToken = nextToken(inputData, scanPos)
    cardRanks[cardIndex] = rankValue(cardToken[0])
    cardSuits[cardIndex] = cardToken[1]
  outputBuffer.add classifyHand(cardRanks, cardSuits)
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
outputBuffer.setLen 0
