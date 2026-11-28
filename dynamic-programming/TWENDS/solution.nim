const flushBlockBytes = 1 shl 17

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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var gameNumber = 0
while true:
  let cardCount = nextInt(inputData, scanPos)
  if cardCount == 0:
    break
  gameNumber += 1
  var cards = newSeq[int](cardCount)
  for cardIndex in 0 .. cardCount - 1:
    cards[cardIndex] = nextInt(inputData, scanPos)
  var previous = newSeq[int](cardCount + 2)
  var current = newSeq[int](cardCount + 2)
  var intervalLength = 2
  while intervalLength <= cardCount:
    for leftIndex in 0 .. cardCount - intervalLength:
      let rightIndex = leftIndex + intervalLength - 1
      var firstValue = 0
      if cards[leftIndex + 1] >= cards[rightIndex]:
        firstValue = cards[leftIndex] - cards[leftIndex + 1] + previous[leftIndex + 2]
      else:
        firstValue = cards[leftIndex] - cards[rightIndex] + previous[leftIndex + 1]
      var secondValue = 0
      if cards[leftIndex] >= cards[rightIndex - 1]:
        secondValue = cards[rightIndex] - cards[leftIndex] + previous[leftIndex + 1]
      else:
        secondValue = cards[rightIndex] - cards[rightIndex - 1] + previous[leftIndex]
      if firstValue > secondValue:
        current[leftIndex] = firstValue
      else:
        current[leftIndex] = secondValue
    swap previous, current
    intervalLength += 2
  appendOutput("In game ")
  appendOutput($gameNumber)
  appendOutput(", the greedy strategy might lose by as many as ")
  appendOutput($previous[0])
  appendOutput(" points.\n")

stdout.write outputBuffer
outputBuffer.setLen 0
