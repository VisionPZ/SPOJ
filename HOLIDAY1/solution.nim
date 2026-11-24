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
proc gcdVal(a, b: int64): int64 =
  var x = a
  var y = b
  while y != 0:
    let r = x mod y
    x = y
    y = r
  x
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
      var v = 0
      var shifted = lowBit
      while shifted > 1:
        shifted = shifted shr 1
        v += 1
      rest = rest xor lowBit
      if (classMask and adjacency[v]) == 0:
        classMask = classMask or lowBit
        uncolored = uncolored xor lowBit
        orderList[count] = v
        colorCap[count] = colorNum
        count += 1
  count
proc cliqueExists(need: int, candidates: int): bool =
  if need == 0: return true
  if candidates == 0: return false
  let count = colorSort(candidates)
  var pool = candidates
  for i in countdown(count - 1, 0):
    if need > colorCap[i]: return false
    let v = orderList[i]
    if cliqueExists(need - 1, pool and adjacency[v]): return true
    pool = pool xor (1 shl v)
  false
proc buildAdjacency(level: int64) =
  for i in 0 .. vertexCount - 1:
    adjacency[i] = 0
    for j in 0 .. vertexCount - 1:
      if i != j and gcdVal(periods[i], periods[j]) >= level:
        adjacency[i] = adjacency[i] or (1 shl j)
var scanPos = 0
let caseCount = int(nextNum(scanPos))
var outputText = ""
for caseIdx in 0 ..< caseCount:
  vertexCount = int(nextNum(scanPos))
  let removeCount = int(nextNum(scanPos))
  periods = @[]
  periods.setLen vertexCount
  for i in 0 .. vertexCount - 1: periods[i] = nextNum(scanPos)
  var need = vertexCount - removeCount
  removeBits = 0
  if need == 1:
    var keepIndex = 0
    for i in 1 .. vertexCount - 1:
      if periods[i] >= periods[keepIndex]: keepIndex = i
    removeBits = ((1 shl vertexCount) - 1) and not (1 shl keepIndex)
  else:
    var gcdList: seq[int64] = @[]
    for i in 0 .. vertexCount - 1:
      for j in i + 1 .. vertexCount - 1: gcdList.add gcdVal(periods[i], periods[j])
    gcdList.sort(system.cmp[int64])
    var lo = 0
    var hi = gcdList.len - 1
    var bestVal = gcdList[0]
    while lo <= hi:
      let mid = (lo + hi) div 2
      let level = gcdList[mid]
      buildAdjacency(level)
      if cliqueExists(need, (1 shl vertexCount) - 1):
        bestVal = level
        lo = mid + 1
      else:
        hi = mid - 1
    buildAdjacency(bestVal)
    var candidates = (1 shl vertexCount) - 1
    var allowed = candidates
    for i in 0 .. vertexCount - 1:
      if (candidates and (1 shl i)) == 0: continue
      if cliqueExists(need, (candidates and not (1 shl i)) and allowed):
        removeBits = removeBits or (1 shl i)
        candidates = candidates and not (1 shl i)
      else:
        candidates = candidates and not (1 shl i)
        allowed = allowed and adjacency[i]
        need -= 1
  var showSpace = false
  for i in 0 .. vertexCount - 1:
    if (removeBits and (1 shl i)) != 0:
      if showSpace: outputText.add ' '
      outputText.add $(i + 1)
      showSpace = true
  outputText.add '\n'
  if outputText.len >= flushBlockBytes:
    stdout.write outputText
    outputText.setLen 0
stdout.write outputText
