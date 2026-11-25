import algorithm
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
var inputData = ""
var line = ""
while readLine(stdin, line):
  inputData.add line
  inputData.add '\n'
proc nextNum(pos: var int): int64 =
  while pos < inputData.len and (inputData[pos] < '0' or inputData[pos] > '9'): pos += 1
  result = 0
  while pos < inputData.len and inputData[pos] >= '0' and inputData[pos] <= '9':
    result = result * 10 + int64(int(inputData[pos]) - firstDigitValue)
    pos += 1
proc gcdVal(left, right: int64): int64 =
  var first = left
  var second = right
  while second != 0:
    let rem = first mod second
    first = second
    second = rem
  first
var vertexCount = 0
var periods: seq[int64]
var adjacency: array[30, int]
var removeBits = 0
var orderList: array[30, int]
var colorCap: array[30, int]
proc colorSort(candidates: int): int =
  var uncolored = candidates
  var colorNum = 0
  var count = 0
  while uncolored != 0:
    colorNum += 1
    var classMask = 0
    var rest = uncolored
    while rest != 0:
      let lowBit = rest and (-rest)
      var node = 0
      var shifted = lowBit
      while shifted > 1:
        shifted = shifted shr 1
        node += 1
      rest = rest xor lowBit
      if (classMask and adjacency[node]) == 0:
        classMask = classMask or lowBit
        uncolored = uncolored xor lowBit
        orderList[count] = node
        colorCap[count] = colorNum
        count += 1
  count
proc cliqueExists(need: int, candidates: int): bool =
  if need == 0: return true
  if candidates == 0: return false
  let count = colorSort(candidates)
  var pool = candidates
  for idx in countdown(count - 1, 0):
    if need > colorCap[idx]: return false
    let node = orderList[idx]
    if cliqueExists(need - 1, pool and adjacency[node]): return true
    pool = pool xor (1 shl node)
  false
proc buildAdjacency(level: int64) =
  for row in 0 ..< vertexCount:
    adjacency[row] = 0
    for col in 0 ..< vertexCount:
      if row != col and gcdVal(periods[row], periods[col]) >= level:
        adjacency[row] = adjacency[row] or (1 shl col)
var scanPos = 0
let caseCount = int(nextNum(scanPos))
var outputBuffer = ""
for caseIdx in 0 ..< caseCount:
  vertexCount = int(nextNum(scanPos))
  let removeCount = int(nextNum(scanPos))
  periods = @[]
  periods.setLen vertexCount
  for i in 0 ..< vertexCount: periods[i] = nextNum(scanPos)
  var need = vertexCount - removeCount
  removeBits = 0
  if need == 1:
    var keepIndex = 0
    for idx in 1 ..< vertexCount:
      if periods[idx] >= periods[keepIndex]: keepIndex = idx
    removeBits = ((1 shl vertexCount) - 1) and not (1 shl keepIndex)
  else:
    var gcdList: seq[int64] = @[]
    for row in 0 ..< vertexCount:
      for col in row + 1 ..< vertexCount: gcdList.add gcdVal(periods[row], periods[col])
    gcdList.sort(system.cmp[int64])
    var lowIdx = 0
    var highIdx = gcdList.len - 1
    var bestVal = gcdList[0]
    while lowIdx <= highIdx:
      let midIdx = (lowIdx + highIdx) div 2
      let level = gcdList[midIdx]
      buildAdjacency(level)
      if cliqueExists(need, (1 shl vertexCount) - 1):
        bestVal = level
        lowIdx = midIdx + 1
      else:
        highIdx = midIdx - 1
    buildAdjacency(bestVal)
    var candidates = (1 shl vertexCount) - 1
    var allowed = candidates
    for node in 0 ..< vertexCount:
      if (candidates and (1 shl node)) == 0: continue
      if cliqueExists(need, (candidates and not (1 shl node)) and allowed):
        removeBits = removeBits or (1 shl node)
        candidates = candidates and not (1 shl node)
      else:
        candidates = candidates and not (1 shl node)
        allowed = allowed and adjacency[node]
        need -= 1
  var showSpace = false
  for node in 0 ..< vertexCount:
    if (removeBits and (1 shl node)) != 0:
      if showSpace: outputBuffer.add ' '
      outputBuffer.add $(node + 1)
      showSpace = true
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
