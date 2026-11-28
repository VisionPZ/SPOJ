const digitBase = 48
const flushBlockBytes = 1 shl 17
const maxWindmills = 100

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] <= ' ': pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - digitBase
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var heights: array[maxWindmills + 1, int]

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let windmillCount = nextInt(inputData, scanPos)
  let halfCount = windmillCount div 2
  if windmillCount == 1:
    heights[0] = 1
  elif windmillCount == 2:
    heights[0] = 1
    heights[1] = 2
  elif windmillCount == 3:
    heights[0] = 2
    heights[1] = 4
    heights[2] = 1
  elif (windmillCount mod 2) == 0:
    for i in 0..<halfCount:
      heights[i] = i * (windmillCount - 1) + halfCount + 1
    for i in 0..<halfCount:
      heights[halfCount + i] = i * (windmillCount - 1) + 1
  else:
    let tailLength = (windmillCount - 3) div 2
    heights[0] = halfCount + 1
    for i in 0..<tailLength:
      heights[1 + i] = (tailLength - i) * windmillCount + 2
    heights[halfCount] = (windmillCount * windmillCount - 2 * windmillCount + 7) div 2
    for i in 0..<halfCount:
      heights[halfCount + 1 + i] = heights[i] - halfCount
  for i in 0..<windmillCount:
    appendOutput($heights[i])
    if i == windmillCount - 1:
      outputBuffer.add '\n'
    else:
      outputBuffer.add ' '
stdout.write outputBuffer
outputBuffer.setLen 0
