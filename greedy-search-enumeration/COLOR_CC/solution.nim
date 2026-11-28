const flushBlockBytes = 1 shl 17
const adjacencyPresent = 'Y'
const maximumSearchWork = 4000000

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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and not ((data[pos] >= 'A' and data[pos] <= 'Z') or (data[pos] >= 'a' and data[pos] <= 'z') or (data[pos] >= '0' and data[pos] <= '9')):
    pos += 1
  var wordValue = ""
  while pos < data.len and ((data[pos] >= 'A' and data[pos] <= 'Z') or (data[pos] >= 'a' and data[pos] <= 'z') or (data[pos] >= '0' and data[pos] <= '9')):
    wordValue.add data[pos]
    pos += 1
  return wordValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let nodeCount = nextInt(inputData, scanPos)
  var adjacencyMasks = newSeq[int](nodeCount)
  for rowIndex in 0 .. nodeCount - 1:
    let matrixRow = nextWord(inputData, scanPos)
    for columnIndex in 0 .. nodeCount - 1:
      if columnIndex < matrixRow.len and matrixRow[columnIndex] == adjacencyPresent:
        adjacencyMasks[rowIndex] = adjacencyMasks[rowIndex] or (1 shl columnIndex)
  var nodeSides = newSeq[int](nodeCount)
  for nodeIndex in 0 .. nodeCount - 1:
    nodeSides[nodeIndex] = -1
  for startNode in 0 .. nodeCount - 1:
    if nodeSides[startNode] != -1:
      continue
    nodeSides[startNode] = 0
    var frontier = newSeq[int](nodeCount)
    var frontierEnd = 1
    frontier[0] = startNode
    var frontierStart = 0
    while frontierStart < frontierEnd:
      let currentNode = frontier[frontierStart]
      frontierStart += 1
      for neighbor in 0 .. nodeCount - 1:
        if (adjacencyMasks[currentNode] and (1 shl neighbor)) == 0:
          continue
        if nodeSides[neighbor] == -1:
          nodeSides[neighbor] = 1 - nodeSides[currentNode]
          frontier[frontierEnd] = neighbor
          frontierEnd += 1
  var distinctColors = newSeq[int](0)
  var nodeColorIndices = newSeq[seq[int]](nodeCount)
  for nodeIndex in 0 .. nodeCount - 1:
    let colorTotal = nextInt(inputData, scanPos)
    var colorIndices = newSeq[int](colorTotal)
    for colorSlot in 0 .. colorTotal - 1:
      let colorValue = nextInt(inputData, scanPos)
      var colorIndex = -1
      for knownIndex in 0 .. distinctColors.len - 1:
        if distinctColors[knownIndex] == colorValue:
          colorIndex = knownIndex
          break
      if colorIndex == -1:
        colorIndex = distinctColors.len
        distinctColors.add colorValue
      colorIndices[colorSlot] = colorIndex
    nodeColorIndices[nodeIndex] = colorIndices
  let colorCount = distinctColors.len
  var blockedCounts = newSeq[int](nodeCount * colorCount)
  var sideZeroWork: int64 = 1
  var sideOneWork: int64 = 1
  for nodeIndex in 0 .. nodeCount - 1:
    let choices = nodeColorIndices[nodeIndex].len
    if nodeSides[nodeIndex] == 0:
      sideZeroWork = sideZeroWork * int64(choices)
    else:
      sideOneWork = sideOneWork * int64(choices)
    if sideZeroWork > maximumSearchWork:
      sideZeroWork = int64(maximumSearchWork)
    if sideOneWork > maximumSearchWork:
      sideOneWork = int64(maximumSearchWork)
  let searchSide = if sideZeroWork <= sideOneWork: 0 else: 1
  var searchNodes = newSeq[int](nodeCount)
  var countNodes = newSeq[int](nodeCount)
  var searchCount = 0
  var countTotal = 0
  for nodeIndex in 0 .. nodeCount - 1:
    if nodeSides[nodeIndex] == searchSide:
      searchNodes[searchCount] = nodeIndex
      searchCount += 1
    else:
      countNodes[countTotal] = nodeIndex
      countTotal += 1
  var totalWays: int64 = 0

  proc explore(searchDepth: int) =
    if searchDepth == searchCount:
      var ways: int64 = 1
      for countIndex in 0 .. countTotal - 1:
        let nodeIndex = countNodes[countIndex]
        var available = 0
        for colorIndex in nodeColorIndices[nodeIndex]:
          if blockedCounts[nodeIndex * colorCount + colorIndex] == 0:
            available += 1
        ways = ways * int64(available)
      totalWays = totalWays + ways
      return
    let nodeIndex = searchNodes[searchDepth]
    for colorIndex in nodeColorIndices[nodeIndex]:
      var changedNodes = newSeq[int](nodeCount)
      var changedCount = 0
      for neighbor in 0 .. nodeCount - 1:
        if (adjacencyMasks[nodeIndex] and (1 shl neighbor)) == 0:
          continue
        let slot = neighbor * colorCount + colorIndex
        changedNodes[changedCount] = neighbor
        changedCount += 1
        blockedCounts[slot] += 1
      explore(searchDepth + 1)
      for changedIndex in 0 .. changedCount - 1:
        blockedCounts[changedNodes[changedIndex] * colorCount + colorIndex] -= 1

  explore(0)
  appendOutput($totalWays)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
