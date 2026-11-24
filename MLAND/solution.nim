import algorithm, strutils

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const weightTolerance = 1e-6
const searchRounds = 52

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and data[position] != '-' and
      (data[position] < '0' or data[position] > '9'):
    position += 1
  var sign = 1
  if position < data.len and data[position] == '-':
    sign = -1
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc findRoot(parent: var seq[int], node: int): int =
  var root = node
  while parent[root] != root:
    root = parent[root]
  var walk = node
  while parent[walk] != walk:
    let nextNode = parent[walk]
    parent[walk] = root
    walk = nextNode
  return root

proc mstAt(moment: float, edgeFrom, edgeTo, edgeA, edgeB: seq[int],
           cityCount, roadCount: int): tuple[total, slope: float] =
  var edgeWeight = newSeq[float](roadCount)
  for i in 0..<roadCount:
    edgeWeight[i] = float(edgeB[i]) + moment * float(edgeA[i])
  var order = newSeq[int](roadCount)
  for i in 0..<roadCount:
    order[i] = i
  order.sort(proc(x, y: int): int =
    if abs(edgeWeight[x] - edgeWeight[y]) > weightTolerance:
      if edgeWeight[x] < edgeWeight[y]: -1 else: 1
    elif edgeA[x] < edgeA[y]: -1
    elif edgeA[x] > edgeA[y]: 1
    else: 0)
  var parent = newSeq[int](cityCount)
  for i in 0..<cityCount:
    parent[i] = i
  var components = cityCount
  var total = 0.0
  var slope = 0.0
  for k in order:
    if components == 1: break
    let leftRoot = findRoot(parent, edgeFrom[k])
    let rightRoot = findRoot(parent, edgeTo[k])
    if leftRoot != rightRoot:
      parent[leftRoot] = rightRoot
      components -= 1
      total += edgeWeight[k]
      slope += float(edgeA[k])
  return (total, slope)

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let cityCount = nextInt(inputData, scanPos)
  let roadCount = nextInt(inputData, scanPos)
  let startTime = nextInt(inputData, scanPos)
  let endTime = nextInt(inputData, scanPos)
  var edgeFrom = newSeq[int](roadCount)
  var edgeTo = newSeq[int](roadCount)
  var edgeA = newSeq[int](roadCount)
  var edgeB = newSeq[int](roadCount)
  for i in 0..<roadCount:
    edgeFrom[i] = nextInt(inputData, scanPos)
    edgeTo[i] = nextInt(inputData, scanPos)
    edgeA[i] = nextInt(inputData, scanPos)
    edgeB[i] = nextInt(inputData, scanPos)
  var bestMoment: float
  if mstAt(float(startTime), edgeFrom, edgeTo, edgeA, edgeB,
           cityCount, roadCount).slope <= 0.0:
    bestMoment = float(startTime)
  elif mstAt(float(endTime), edgeFrom, edgeTo, edgeA, edgeB,
             cityCount, roadCount).slope > 0.0:
    bestMoment = float(endTime)
  else:
    var low = float(startTime)
    var high = float(endTime)
    for k in 0..<searchRounds:
      let mid = (low + high) * 0.5
      if mstAt(mid, edgeFrom, edgeTo, edgeA, edgeB,
               cityCount, roadCount).slope <= 0.0:
        high = mid
      else:
        low = mid
    bestMoment = high
  var bestValue = mstAt(bestMoment, edgeFrom, edgeTo, edgeA, edgeB,
                        cityCount, roadCount).total
  if abs(bestMoment) < 0.0005: bestMoment = 0.0
  if abs(bestValue) < 0.0005: bestValue = 0.0
  appendOutput(formatFloat(bestMoment, ffDecimal, 3) & " " &
               formatFloat(bestValue, ffDecimal, 3))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
