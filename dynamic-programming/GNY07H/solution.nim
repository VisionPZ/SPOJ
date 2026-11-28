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

let caseCount = nextInt(inputData, scanPos)
var widths = newSeq[int](caseCount)
var largestWidth = 1
for caseIndex in 0 .. caseCount - 1:
  widths[caseIndex] = nextInt(inputData, scanPos)
  if widths[caseIndex] > largestWidth:
    largestWidth = widths[caseIndex]

var fullTileCounts = newSeq[int64](largestWidth + 1)
var cornerGapCounts = newSeq[int64](largestWidth + 1)
var edgeNotchCounts = newSeq[int64](largestWidth + 1)
fullTileCounts[0] = 1
fullTileCounts[1] = 1
cornerGapCounts[1] = 1
edgeNotchCounts[1] = 1
var widthIndex = 2
while widthIndex <= largestWidth:
  fullTileCounts[widthIndex] = fullTileCounts[widthIndex - 1] + fullTileCounts[widthIndex - 2] + cornerGapCounts[widthIndex - 1] + 2 * edgeNotchCounts[widthIndex - 1]
  cornerGapCounts[widthIndex] = fullTileCounts[widthIndex - 1] + cornerGapCounts[widthIndex - 2]
  edgeNotchCounts[widthIndex] = fullTileCounts[widthIndex - 1] + edgeNotchCounts[widthIndex - 1]
  widthIndex += 1

for caseIndex in 0 .. caseCount - 1:
  appendOutput($(caseIndex + 1))
  outputBuffer.add ' '
  appendOutput($fullTileCounts[widths[caseIndex]])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
