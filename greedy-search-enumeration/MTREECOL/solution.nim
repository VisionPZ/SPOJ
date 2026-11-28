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

proc solveCase(nodeCount: int, rootNode: int, costFactors: seq[int], parentNodes: var seq[int]): int64 =
  var groupCosts = newSeq[int64](nodeCount + 1)
  var groupSizes = newSeq[int](nodeCount + 1)
  var aliveNodes = newSeq[bool](nodeCount + 1)
  var childLists = newSeq[seq[int]](nodeCount + 1)
  var totalCost: int64 = 0
  for nodeIndex in 1 .. nodeCount:
    groupCosts[nodeIndex] = int64(costFactors[nodeIndex])
    groupSizes[nodeIndex] = 1
    aliveNodes[nodeIndex] = true
    totalCost = totalCost + int64(costFactors[nodeIndex])
  for nodeIndex in 1 .. nodeCount:
    if nodeIndex != rootNode:
      childLists[parentNodes[nodeIndex]].add nodeIndex
  var remainingNodes = nodeCount
  while remainingNodes > 1:
    var bestNode = 0
    for candidateNode in 1 .. nodeCount:
      if not aliveNodes[candidateNode] or candidateNode == rootNode:
        continue
      if bestNode == 0:
        bestNode = candidateNode
      elif groupCosts[candidateNode] * int64(groupSizes[bestNode]) >
           groupCosts[bestNode] * int64(groupSizes[candidateNode]):
        bestNode = candidateNode
    let parentNode = parentNodes[bestNode]
    let mergedCost = groupCosts[bestNode]
    let mergedSize = groupSizes[bestNode]
    totalCost = totalCost + mergedCost * int64(groupSizes[parentNode])
    groupCosts[parentNode] = groupCosts[parentNode] + mergedCost
    groupSizes[parentNode] = groupSizes[parentNode] + mergedSize
    for childNode in childLists[bestNode]:
      if aliveNodes[childNode]:
        parentNodes[childNode] = parentNode
        childLists[parentNode].add childNode
    childLists[bestNode].setLen 0
    aliveNodes[bestNode] = false
    remainingNodes -= 1
  return totalCost

while true:
  let nodeCount = nextInt(inputData, scanPos)
  let rootNode = nextInt(inputData, scanPos)
  if nodeCount == 0 and rootNode == 0:
    break
  var costFactors = newSeq[int](nodeCount + 1)
  for nodeIndex in 1 .. nodeCount:
    costFactors[nodeIndex] = nextInt(inputData, scanPos)
  var parentNodes = newSeq[int](nodeCount + 1)
  for edgeIndex in 1 .. nodeCount - 1:
    let fatherNode = nextInt(inputData, scanPos)
    let childNode = nextInt(inputData, scanPos)
    parentNodes[childNode] = fatherNode
  let answerValue = solveCase(nodeCount, rootNode, costFactors, parentNodes)
  appendOutput($answerValue)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
