{.push checks: off.}
{.push overflowChecks: off.}
{.push rangeChecks: off.}
{.push boundChecks: off.}
{.push stackTrace: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maximumCutCost = 1000

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

var verticalCount: array[maximumCutCost + 1, int]
var horizontalCount: array[maximumCutCost + 1, int]

let caseCount = nextInt(inputData, scanPos)
for j in 0..<caseCount:
  let columnCount = nextInt(inputData, scanPos)
  let rowCount = nextInt(inputData, scanPos)
  for k in 0..maximumCutCost:
    verticalCount[k] = 0
    horizontalCount[k] = 0
  var remainingVertical = columnCount - 1
  var remainingHorizontal = rowCount - 1
  for k in 0..<remainingVertical:
    let cutCost = nextInt(inputData, scanPos)
    verticalCount[cutCost] += 1
  for k in 0..<remainingHorizontal:
    let cutCost = nextInt(inputData, scanPos)
    horizontalCount[cutCost] += 1
  var verticalValue = maximumCutCost
  var horizontalValue = maximumCutCost
  var verticalPieces = 1
  var horizontalPieces = 1
  var totalCost: int64 = 0
  while remainingVertical > 0 or remainingHorizontal > 0:
    if remainingVertical > 0:
      while verticalCount[verticalValue] == 0:
        verticalValue -= 1
    if remainingHorizontal > 0:
      while horizontalCount[horizontalValue] == 0:
        horizontalValue -= 1
    if remainingVertical > 0 and (remainingHorizontal == 0 or verticalValue >= horizontalValue):
      totalCost += int64(verticalValue) * int64(horizontalPieces)
      verticalPieces += 1
      verticalCount[verticalValue] -= 1
      remainingVertical -= 1
    else:
      totalCost += int64(horizontalValue) * int64(verticalPieces)
      horizontalPieces += 1
      horizontalCount[horizontalValue] -= 1
      remainingHorizontal -= 1
  appendOutput($(totalCost))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
