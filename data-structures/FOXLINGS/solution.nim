import algorithm

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

let nodeCount = int64(nextInt(inputData, scanPos))
let friendshipCount = nextInt(inputData, scanPos)
var firstEndpoints = newSeq[int](friendshipCount)
var secondEndpoints = newSeq[int](friendshipCount)
var allIds = newSeq[int](friendshipCount * 2)
for pairIndex in 0 .. friendshipCount - 1:
  let firstId = nextInt(inputData, scanPos)
  let secondId = nextInt(inputData, scanPos)
  firstEndpoints[pairIndex] = firstId
  secondEndpoints[pairIndex] = secondId
  allIds[pairIndex * 2] = firstId
  allIds[pairIndex * 2 + 1] = secondId

proc compareIds(left: int, right: int): int =
  if left < right: return -1
  if left > right: return 1
  return 0

allIds.sort(compareIds)
var uniqueIds = newSeq[int](allIds.len)
var uniqueCount = 0
for index in 0 .. allIds.len - 1:
  if index == 0 or allIds[index] != allIds[index - 1]:
    uniqueIds[uniqueCount] = allIds[index]
    uniqueCount += 1
uniqueIds.setLen(uniqueCount)

proc findId(ids: seq[int], target: int): int =
  var low = 0
  var high = ids.len - 1
  while low <= high:
    let middle = (low + high) div 2
    if ids[middle] == target: return middle
    if ids[middle] < target: low = middle + 1
    else: high = middle - 1
  return -1

var parent = newSeq[int](uniqueCount)
var groupSize = newSeq[int](uniqueCount)
for index in 0 .. uniqueCount - 1:
  parent[index] = index
  groupSize[index] = 1

proc findRoot(node: int): int =
  var current = node
  while parent[current] != current:
    parent[current] = parent[parent[current]]
    current = parent[current]
  return current

var componentCount = uniqueCount
for pairIndex in 0 .. friendshipCount - 1:
  let rootFirst = findRoot(findId(uniqueIds, firstEndpoints[pairIndex]))
  let rootSecond = findRoot(findId(uniqueIds, secondEndpoints[pairIndex]))
  if rootFirst != rootSecond:
    if groupSize[rootFirst] < groupSize[rootSecond]:
      parent[rootFirst] = rootSecond
      groupSize[rootSecond] += groupSize[rootFirst]
    else:
      parent[rootSecond] = rootFirst
      groupSize[rootFirst] += groupSize[rootSecond]
    componentCount -= 1

let crackerCount = int64(componentCount) + (nodeCount - int64(uniqueCount))
appendOutput($crackerCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
