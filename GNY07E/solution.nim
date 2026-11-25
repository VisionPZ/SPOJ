const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextSignedInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and int(data[pos]) != 226 and
        (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var negative = false
  if pos < data.len and (data[pos] == '-' or int(data[pos]) == 226):
    negative = true
    if int(data[pos]) == 226:
      pos += 3
    else:
      pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc flipStack(stack: var seq[int], flipCount: int) =
  for topIndex in 0 .. flipCount - 1:
    stack[topIndex] = -stack[topIndex]
  var leftIndex = 0
  var rightIndex = flipCount - 1
  while leftIndex < rightIndex:
    swap stack[leftIndex], stack[rightIndex]
    leftIndex += 1
    rightIndex -= 1

let caseCount = nextSignedInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let pancakeCount = nextSignedInt(inputData, scanPos)
  var stack = newSeq[int](pancakeCount)
  for pancakeIndex in 0 .. pancakeCount - 1:
    stack[pancakeIndex] = nextSignedInt(inputData, scanPos)
  var flips = newSeq[int](0)
  var activeSize = pancakeCount
  var targetSize = pancakeCount
  while targetSize >= 1:
    var position = -1
    for pancakeIndex in 0 .. activeSize - 1:
      if stack[pancakeIndex] == targetSize or stack[pancakeIndex] == -targetSize:
        position = pancakeIndex
        break
    if position == -1:
      targetSize -= 1
      continue
    let burnedUp = stack[position] < 0
    if position == activeSize - 1 and not burnedUp:
      activeSize -= 1
      targetSize -= 1
      continue
    if position != 0:
      flipStack(stack, position + 1)
      flips.add position + 1
    if stack[0] > 0:
      flipStack(stack, 1)
      flips.add 1
    flipStack(stack, activeSize)
    flips.add activeSize
    activeSize -= 1
    targetSize -= 1
  if stack[0] < 0:
    flipStack(stack, 1)
    flips.add 1
  var line = $caseIndex & " " & $flips.len
  for flipCount in flips:
    line = line & " " & $flipCount
  line.add '\n'
  appendOutput(line)

stdout.write outputBuffer
outputBuffer.setLen 0
