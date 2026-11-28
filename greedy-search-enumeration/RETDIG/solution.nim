import algorithm

const flushBlockBytes = 1 shl 17
const impossibleCost = 1000000000

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

proc ascending(left: int, right: int): int =
  if left < right:
    return -1
  if left > right:
    return 1
  return 0

proc firstRockBelow(depths: seq[int], currentDepth: int): int =
  var low = 0
  var high = depths.len
  while low < high:
    let middle = (low + high) div 2
    if depths[middle] <= currentDepth:
      low = middle + 1
    else:
      high = middle
  if low == depths.len:
    return 0
  return depths[low]

proc depthIndex(depths: seq[int], target: int): int =
  var low = 0
  var high = depths.len
  while low < high:
    let middle = (low + high) div 2
    if depths[middle] < target:
      low = middle + 1
    else:
      high = middle
  return low

let landLength = nextInt(inputData, scanPos)
let rockCount = nextInt(inputData, scanPos)
var columnRocks = newSeq[seq[int]](landLength + 1)
var stopDepths = newSeq[int]()
stopDepths.add 0
for rockIndex in 0 .. rockCount - 1:
  let rockDepth = nextInt(inputData, scanPos)
  let rockColumn = nextInt(inputData, scanPos)
  columnRocks[rockColumn].add rockDepth
  stopDepths.add rockDepth - 1
let treasureDepth = nextInt(inputData, scanPos)
let treasureColumn = nextInt(inputData, scanPos)
for column in 0 .. landLength:
  columnRocks[column].sort(ascending)
stopDepths.sort(ascending)
var uniqueDepths = newSeq[int]()
for depth in stopDepths:
  if uniqueDepths.len == 0 or uniqueDepths[uniqueDepths.len - 1] != depth:
    uniqueDepths.add depth
var costDirt = newSeq[int](uniqueDepths.len)
var costTreasure = newSeq[int](uniqueDepths.len)
for index in 0 .. uniqueDepths.len - 1:
  costDirt[index] = impossibleCost
  costTreasure[index] = impossibleCost
costDirt[0] = 0
var bestCost = impossibleCost
for depthIndex in 0 .. uniqueDepths.len - 1:
  let currentDepth = uniqueDepths[depthIndex]
  for carriedTreasure in 0 .. 1:
    let currentCost = if carriedTreasure == 0: costDirt[depthIndex] else: costTreasure[depthIndex]
    if currentCost >= impossibleCost:
      continue
    var activeFlag = carriedTreasure
    if carriedTreasure == 0 and currentDepth == treasureDepth:
      activeFlag = 1
    if activeFlag == 0 and currentDepth > treasureDepth:
      continue
    for column in 0 .. landLength:
      let rockAhead = firstRockBelow(columnRocks[column], currentDepth)
      var nextFlag = activeFlag
      if nextFlag == 0:
        if currentDepth < treasureDepth:
          if column == treasureColumn:
            if rockAhead == 0 or rockAhead > treasureDepth + 1:
              continue
            if rockAhead == treasureDepth + 1:
              nextFlag = 1
          elif column == treasureColumn - 1 or column == treasureColumn + 1:
            if rockAhead == 0 or rockAhead >= treasureDepth + 1:
              nextFlag = 1
        elif currentDepth == treasureDepth:
          nextFlag = 1
        else:
          continue
      if rockAhead == 0:
        if nextFlag == 1 and currentCost < bestCost:
          bestCost = currentCost
      else:
        let nextDepth = rockAhead - 1
        if nextDepth <= currentDepth:
          continue
        let nextIndex = depthIndex(uniqueDepths, nextDepth)
        if nextFlag == 0:
          if currentCost + 1 < costDirt[nextIndex]:
            costDirt[nextIndex] = currentCost + 1
        else:
          if currentCost + 1 < costTreasure[nextIndex]:
            costTreasure[nextIndex] = currentCost + 1
if bestCost == impossibleCost:
  appendOutput("Use dynamite")
else:
  appendOutput($bestCost)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
