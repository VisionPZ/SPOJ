const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let dataSetCount = nextInt(inputData, scanPos)
for dataSetIndex in 0..<dataSetCount:
  let pairCount = nextInt(inputData, scanPos)
  let fixedCount = nextInt(inputData, scanPos)
  var mustOpen = newSeq[bool](2 * pairCount + 1)
  for fixedIndex in 0..<fixedCount:
    let position = nextInt(inputData, scanPos)
    mustOpen[position] = true
  var ways = newSeq[int64](pairCount + 1)
  ways[0] = 1
  for position in 1..(2 * pairCount):
    var nextWays = newSeq[int64](pairCount + 1)
    for balance in 0..pairCount:
      if ways[balance] == 0:
        continue
      if not mustOpen[position]:
        if balance > 0:
          nextWays[balance - 1] += ways[balance]
      if balance < pairCount:
        nextWays[balance + 1] += ways[balance]
    ways = nextWays
  appendOutput($ways[0])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
