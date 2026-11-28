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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

proc hasMoreData(data: string, pos: int): bool =
  var scanIndex = pos
  while scanIndex < data.len and data[scanIndex] <= ' ':
    scanIndex += 1
  return scanIndex < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while hasMoreData(inputData, scanPos):
  let firstLength = nextInt(inputData, scanPos)
  let secondLength = nextInt(inputData, scanPos)
  var letterPrices = newSeq[int64](26)
  for letterIndex in 0 .. 25:
    letterPrices[letterIndex] = int64(nextInt(inputData, scanPos))
  let firstString = nextToken(inputData, scanPos)
  let secondString = nextToken(inputData, scanPos)
  var previousRow = newSeq[int64](secondLength + 1)
  var currentRow = newSeq[int64](secondLength + 1)
  for firstIndex in 1 .. firstLength:
    currentRow[0] = 0
    for secondIndex in 1 .. secondLength:
      var bestValue = previousRow[secondIndex]
      if currentRow[secondIndex - 1] > bestValue:
        bestValue = currentRow[secondIndex - 1]
      if firstString[firstIndex - 1] == secondString[secondIndex - 1]:
        let letterId = int(firstString[firstIndex - 1]) - 97
        let pairedValue = previousRow[secondIndex - 1] + letterPrices[letterId]
        if pairedValue > bestValue:
          bestValue = pairedValue
      currentRow[secondIndex] = bestValue
    swap previousRow, currentRow
  appendOutput($previousRow[secondLength])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
