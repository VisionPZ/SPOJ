import algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const coordBound = 30000
const keyShift = 16
const keyMask = (1 shl keyShift) - 1

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

var sortKeys: seq[int] = @[]
var lisTails: seq[int] = @[]

proc compareKey(left, right: int): int =
  if left < right: return -1
  if left > right: return 1
  return 0

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let pointCount = nextInt(inputData, scanPos)
  sortKeys.setLen(pointCount)
  for i in 0..<pointCount:
    let x = nextInt(inputData, scanPos)
    let y = nextInt(inputData, scanPos)
    let upValue = y - x
    let downValue = y + x
    sortKeys[i] = (upValue + coordBound) * (1 shl keyShift) + (keyMask - downValue)

  sort(sortKeys, compareKey)

  lisTails.setLen(0)
  for i in 0..<pointCount:
    let downValue = keyMask - (sortKeys[i] and keyMask)
    var lo = 0
    var hi = lisTails.len
    while lo < hi:
      let mid = (lo + hi) div 2
      if lisTails[mid] < downValue:
        lo = mid + 1
      else:
        hi = mid
    if lo == lisTails.len:
      lisTails.add downValue
    else:
      lisTails[lo] = downValue

  appendOutput($(lisTails.len))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
