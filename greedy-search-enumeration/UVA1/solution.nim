import algorithm

const flushBlockBytes = 1 shl 17

type
  House = object
    distanceFirst: int64
    distanceSecond: int64
    secondRank: int

  Query = object
    radiusFirstSq: int64
    radiusSecondSq: int64
    originalIndex: int
    answer: int

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

proc compareBySecond(left: House, right: House): int =
  if left.distanceSecond < right.distanceSecond:
    return -1
  if left.distanceSecond > right.distanceSecond:
    return 1
  return 0

proc compareByFirst(left: House, right: House): int =
  if left.distanceFirst < right.distanceFirst:
    return -1
  if left.distanceFirst > right.distanceFirst:
    return 1
  return 0

proc compareByRadius(left: Query, right: Query): int =
  if left.radiusFirstSq < right.radiusFirstSq:
    return -1
  if left.radiusFirstSq > right.radiusFirstSq:
    return 1
  return 0

proc upperBound(values: seq[int64], target: int64): int =
  var low = 0
  var high = values.len
  while low < high:
    let middle = (low + high) div 2
    if values[middle] <= target:
      low = middle + 1
    else:
      high = middle
  return low

proc fenwickAdd(tree: var seq[int], index: int) =
  var position = index
  while position < tree.len:
    tree[position] += 1
    position += position and (-position)

proc fenwickSum(tree: var seq[int], index: int): int =
  var total = 0
  var position = index
  while position > 0:
    total += tree[position]
    position -= position and (-position)
  return total

var caseNumber = 0
while true:
  let houseCount = nextInt(inputData, scanPos)
  if houseCount == 0:
    break
  caseNumber += 1
  var houseX = newSeq[int](houseCount)
  var houseY = newSeq[int](houseCount)
  for houseIndex in 0 .. houseCount - 1:
    houseX[houseIndex] = nextInt(inputData, scanPos)
    houseY[houseIndex] = nextInt(inputData, scanPos)
  let centerAx = nextInt(inputData, scanPos)
  let centerAy = nextInt(inputData, scanPos)
  let centerBx = nextInt(inputData, scanPos)
  let centerBy = nextInt(inputData, scanPos)
  let queryCount = nextInt(inputData, scanPos)
  var houses = newSeq[House](houseCount)
  for houseIndex in 0 .. houseCount - 1:
    let deltaAx = int64(houseX[houseIndex] - centerAx)
    let deltaAy = int64(houseY[houseIndex] - centerAy)
    let deltaBx = int64(houseX[houseIndex] - centerBx)
    let deltaBy = int64(houseY[houseIndex] - centerBy)
    houses[houseIndex].distanceFirst = deltaAx * deltaAx + deltaAy * deltaAy
    houses[houseIndex].distanceSecond = deltaBx * deltaBx + deltaBy * deltaBy
  houses.sort(compareBySecond)
  var sortedSecond = newSeq[int64](houseCount)
  for houseIndex in 0 .. houseCount - 1:
    houses[houseIndex].secondRank = houseIndex + 1
    sortedSecond[houseIndex] = houses[houseIndex].distanceSecond
  var queries = newSeq[Query](queryCount)
  for queryIndex in 0 .. queryCount - 1:
    let radiusFirst = int64(nextInt(inputData, scanPos))
    let radiusSecond = int64(nextInt(inputData, scanPos))
    queries[queryIndex].radiusFirstSq = radiusFirst * radiusFirst
    queries[queryIndex].radiusSecondSq = radiusSecond * radiusSecond
    queries[queryIndex].originalIndex = queryIndex
  var sortedQueries = queries
  sortedQueries.sort(compareByRadius)
  houses.sort(compareByFirst)
  var fenwickTree = newSeq[int](houseCount + 1)
  var nextHouse = 0
  for queryItem in sortedQueries:
    while nextHouse < houseCount and houses[nextHouse].distanceFirst <= queryItem.radiusFirstSq:
      fenwickAdd(fenwickTree, houses[nextHouse].secondRank)
      nextHouse += 1
    let secondCount = upperBound(sortedSecond, queryItem.radiusSecondSq)
    queries[queryItem.originalIndex].answer = fenwickSum(fenwickTree, secondCount)
  appendOutput("Case " & $caseNumber & ":\n")
  for queryIndex in 0 .. queryCount - 1:
    appendOutput($queries[queryIndex].answer)
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
