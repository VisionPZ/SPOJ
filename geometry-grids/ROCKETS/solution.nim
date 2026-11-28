{.push checks: off, optimization: speed, stackTrace: off, lineDir: off.}
{.emit: "#pragma GCC optimize(\"O3\")".}
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const maxPoints = 20000
const maxCaseSize = 10000
const insertionLimit = 16

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9') and data[position] != '-':
    position += 1
  var negative = false
  if position < data.len and data[position] == '-':
    negative = true
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var xCoord: array[maxPoints, int]
var yCoord: array[maxPoints, int]
var isRocketPoint: array[maxPoints, bool]
var sourceIndex: array[maxPoints, int]
var pointIds: array[maxPoints, int]
var matchResult: array[maxCaseSize + 1, int]
var stackLo: array[maxPoints, int]
var stackHi: array[maxPoints, int]
var pivotX = 0
var pivotY = 0
var randomState: uint32 = 2463534242'u32

proc nextIndex(rangeSize: int): int =
  randomState = randomState xor (randomState shl 13)
  randomState = randomState xor (randomState shr 17)
  randomState = randomState xor (randomState shl 5)
  return int(randomState mod uint32(rangeSize))

proc slopeLess(leftId, rightId: int): bool =
  let leftDx = xCoord[leftId] - pivotX
  let rightDx = xCoord[rightId] - pivotX
  if leftDx == 0:
    if rightDx == 0:
      return yCoord[leftId] < yCoord[rightId]
    return false
  if rightDx == 0:
    return true
  return int64(yCoord[leftId] - pivotY) * int64(rightDx) < int64(yCoord[rightId] - pivotY) * int64(leftDx)

proc insertionSort(lo, hi: int) =
  for i in lo + 1..<hi:
    let value = pointIds[i]
    var j = i - 1
    while j >= lo and slopeLess(value, pointIds[j]):
      pointIds[j + 1] = pointIds[j]
      j -= 1
    pointIds[j + 1] = value

proc quickSort(lo, hi: int) =
  if hi - lo <= insertionLimit:
    insertionSort(lo, hi)
    return
  let last = hi - 1
  let chosen = lo + nextIndex(hi - lo)
  swap pointIds[chosen], pointIds[last]
  let pivotValue = pointIds[last]
  var store = lo
  for i in lo..<last:
    if slopeLess(pointIds[i], pivotValue):
      swap pointIds[i], pointIds[store]
      store += 1
  swap pointIds[store], pointIds[last]
  quickSort(lo, store)
  quickSort(store + 1, hi)

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let pointCount = nextInt(inputData, scanPos)
  let totalPoints = 2 * pointCount
  for i in 0..<totalPoints:
    xCoord[i] = nextInt(inputData, scanPos)
    yCoord[i] = nextInt(inputData, scanPos)
    isRocketPoint[i] = i < pointCount
    sourceIndex[i] = if i < pointCount: i + 1 else: i - pointCount + 1
    pointIds[i] = i

  var stackSize = 1
  stackLo[0] = 0
  stackHi[0] = totalPoints
  while stackSize > 0:
    stackSize -= 1
    let lo = stackLo[stackSize]
    let hi = stackHi[stackSize]
    if hi - lo <= 0:
      continue
    var leftPos = lo
    for i in lo + 1..<hi:
      let candidate = pointIds[i]
      let best = pointIds[leftPos]
      if xCoord[candidate] < xCoord[best] or (xCoord[candidate] == xCoord[best] and yCoord[candidate] < yCoord[best]):
        leftPos = i
    swap pointIds[lo], pointIds[leftPos]
    let pivotId = pointIds[lo]
    pivotX = xCoord[pivotId]
    pivotY = yCoord[pivotId]
    quickSort(lo + 1, hi)
    var balanceValue = 0
    var matchPos = lo + 1
    var bestDistance = hi - lo
    let middlePos = (lo + hi) div 2
    for i in lo + 1..<hi:
      let otherId = pointIds[i]
      if isRocketPoint[otherId] == isRocketPoint[pivotId]:
        balanceValue += 1
      else:
        if balanceValue == 0:
          let distance = if i > middlePos: i - middlePos else: middlePos - i
          if distance < bestDistance:
            bestDistance = distance
            matchPos = i
        balanceValue -= 1
    if isRocketPoint[pivotId]:
      matchResult[sourceIndex[pivotId]] = sourceIndex[pointIds[matchPos]]
    else:
      matchResult[sourceIndex[pointIds[matchPos]]] = sourceIndex[pivotId]
    stackLo[stackSize] = lo + 1
    stackHi[stackSize] = matchPos
    stackSize += 1
    stackLo[stackSize] = matchPos + 1
    stackHi[stackSize] = hi
    stackSize += 1

  for i in 1..pointCount:
    appendOutput($(matchResult[i]))
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
{.pop.}
