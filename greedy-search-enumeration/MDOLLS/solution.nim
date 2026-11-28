const flushBlockBytes = 1 shl 17
const maxDimension = 10000

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

proc bitPrefix(bit: seq[int], index: int): int =
  var position = index
  result = 0
  while position > 0:
    result = result + bit[position]
    position = position - (position and -position)

proc bitAdd(bit: var seq[int], index: int, delta: int) =
  var position = index
  while position <= maxDimension:
    bit[position] = bit[position] + delta
    position = position + (position and -position)

proc bitFindByOrder(bit: seq[int], order: int): int =
  var position = 0
  var stepSize = 1
  while stepSize shl 1 <= maxDimension:
    stepSize = stepSize shl 1
  var remaining = order
  while stepSize > 0:
    let nextPosition = position + stepSize
    if nextPosition <= maxDimension and bit[nextPosition] < remaining:
      position = nextPosition
      remaining = remaining - bit[nextPosition]
    stepSize = stepSize shr 1
  return position + 1

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let dollCount = nextInt(inputData, scanPos)
  var widths = newSeq[int](dollCount)
  var heights = newSeq[int](dollCount)
  var widthCount = newSeq[int](maxDimension + 1)
  var heightCount = newSeq[int](maxDimension + 1)
  var maxWidth = 0
  var maxHeight = 0
  for dollIndex in 0 .. dollCount - 1:
    let dollWidth = nextInt(inputData, scanPos)
    let dollHeight = nextInt(inputData, scanPos)
    widths[dollIndex] = dollWidth
    heights[dollIndex] = dollHeight
    widthCount[dollWidth] = widthCount[dollWidth] + 1
    heightCount[dollHeight] = heightCount[dollHeight] + 1
    if dollWidth > maxWidth:
      maxWidth = dollWidth
    if dollHeight > maxHeight:
      maxHeight = dollHeight
  var heightStart = newSeq[int](maxDimension + 2)
  var writePosition = 0
  for heightValue in countdown(maxHeight, 1):
    heightStart[heightValue] = writePosition
    writePosition = writePosition + heightCount[heightValue]
  var firstOrder = newSeq[int](dollCount)
  for dollIndex in 0 .. dollCount - 1:
    let dollHeight = heights[dollIndex]
    firstOrder[heightStart[dollHeight]] = dollIndex
    heightStart[dollHeight] = heightStart[dollHeight] + 1
  var widthStart = newSeq[int](maxDimension + 2)
  writePosition = 0
  for widthValue in 1 .. maxWidth:
    widthStart[widthValue] = writePosition
    writePosition = writePosition + widthCount[widthValue]
  var sortedOrder = newSeq[int](dollCount)
  for orderIndex in 0 .. dollCount - 1:
    let dollIndex = firstOrder[orderIndex]
    let dollWidth = widths[dollIndex]
    sortedOrder[widthStart[dollWidth]] = dollIndex
    widthStart[dollWidth] = widthStart[dollWidth] + 1
  var pileTops = newSeq[int](maxDimension + 1)
  var pileCount = 0
  for orderIndex in 0 .. dollCount - 1:
    let dollIndex = sortedOrder[orderIndex]
    let dollHeight = heights[dollIndex]
    let smallerTops = bitPrefix(pileTops, dollHeight - 1)
    if smallerTops > 0:
      let oldHeight = bitFindByOrder(pileTops, smallerTops)
      bitAdd(pileTops, oldHeight, -1)
    else:
      pileCount = pileCount + 1
    bitAdd(pileTops, dollHeight, 1)
  appendOutput($pileCount)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
