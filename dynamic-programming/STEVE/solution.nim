{.push checks: off.}
{.passC: "-O3".}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxDonuts = 100
const largeValue = 1 shl 30

var steveEatsTable: array[0..maxDonuts, array[0..maxDonuts, int]]
var roundStateValue: array[0..maxDonuts, array[0..maxDonuts, int]]

proc computeGameValues() =
  for moveLimit in 1..maxDonuts:
    for donutCount in 1..maxDonuts:
      for boxCount in 0..donutCount:
        for currentSide in 0..donutCount:
          roundStateValue[boxCount][currentSide] = 0
      for boxCount in 1..donutCount:
        for currentSide in 0..(donutCount - boxCount):
          let otherSide = donutCount - boxCount - currentSide
          var fewestOpponentDonuts = largeValue
          var takeLimit = moveLimit
          if takeLimit > boxCount:
            takeLimit = boxCount
          for donutsTaken in 1..takeLimit:
            var opponentDonuts: int
            if donutsTaken == boxCount:
              opponentDonuts = steveEatsTable[otherSide][moveLimit]
            else:
              opponentDonuts = roundStateValue[boxCount - donutsTaken][otherSide]
            if opponentDonuts < fewestOpponentDonuts:
              fewestOpponentDonuts = opponentDonuts
          roundStateValue[boxCount][currentSide] = donutCount - fewestOpponentDonuts
      steveEatsTable[donutCount][moveLimit] = roundStateValue[donutCount][0]

computeGameValues()

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

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let donutCount = nextInt(inputData, scanPos)
  let moveLimit = nextInt(inputData, scanPos)
  appendOutput($(steveEatsTable[donutCount][moveLimit]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
