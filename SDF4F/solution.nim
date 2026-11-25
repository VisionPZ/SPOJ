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

proc findRoot(parent: var seq[int], node: int): int =
  var current = node
  while parent[current] != current:
    parent[current] = parent[parent[current]]
    current = parent[current]
  return current

proc joinSets(parent: var seq[int], firstNode, secondNode: int) =
  let firstRoot = findRoot(parent, firstNode)
  let secondRoot = findRoot(parent, secondNode)
  if firstRoot != secondRoot:
    parent[firstRoot] = secondRoot

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let islandCount = nextInt(inputData, scanPos)
let connectionCount = nextInt(inputData, scanPos)
var parent = newSeq[int](islandCount)
for islandIndex in 0 .. islandCount - 1:
  parent[islandIndex] = islandIndex
for connectionIndex in 0 .. connectionCount - 1:
  let firstIsland = nextInt(inputData, scanPos) - 1
  let secondIsland = nextInt(inputData, scanPos) - 1
  joinSets(parent, firstIsland, secondIsland)
var bridgeCount = 0
for islandIndex in 0 .. islandCount - 2:
  if findRoot(parent, islandIndex) != findRoot(parent, islandIndex + 1):
    joinSets(parent, islandIndex, islandIndex + 1)
    bridgeCount += 1
appendOutput($bridgeCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
