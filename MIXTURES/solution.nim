const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const colorModulus = 100
const maxMixtures = 100
const largeSmoke = 1 shl 60

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

proc hasMoreTokens(data: string, pos: int): bool =
  var scanIndex = pos
  while scanIndex < data.len:
    if data[scanIndex] >= '0' and data[scanIndex] <= '9':
      return true
    scanIndex += 1
  return false

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var smokeTable: array[maxMixtures, array[maxMixtures, int]]
var colors: array[maxMixtures, int]
var prefixColors: array[maxMixtures + 1, int]

while hasMoreTokens(inputData, scanPos):
  let mixtureCount = nextInt(inputData, scanPos)
  prefixColors[0] = 0
  for colorIndex in 0..<mixtureCount:
    colors[colorIndex] = nextInt(inputData, scanPos)
    prefixColors[colorIndex + 1] = prefixColors[colorIndex] + colors[colorIndex]
  for leftIndex in 0..<mixtureCount:
    smokeTable[leftIndex][leftIndex] = 0
  var windowLength = 2
  while windowLength <= mixtureCount:
    var leftIndex = 0
    while leftIndex + windowLength <= mixtureCount:
      let rightIndex = leftIndex + windowLength - 1
      let rangeColor = (prefixColors[rightIndex + 1] - prefixColors[leftIndex]) mod colorModulus
      var bestSmoke = largeSmoke
      for splitIndex in leftIndex..<rightIndex:
        let leftColor = (prefixColors[splitIndex + 1] - prefixColors[leftIndex]) mod colorModulus
        let rightColor = (rangeColor - leftColor + colorModulus) mod colorModulus
        let candidateSmoke = smokeTable[leftIndex][splitIndex] + smokeTable[splitIndex + 1][rightIndex] + leftColor * rightColor
        if candidateSmoke < bestSmoke:
          bestSmoke = candidateSmoke
      smokeTable[leftIndex][rightIndex] = bestSmoke
      leftIndex += 1
    windowLength += 1
  appendOutput($(smokeTable[0][mixtureCount - 1]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
