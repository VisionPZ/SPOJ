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

var headArc: seq[int] = @[]
var targetNode: seq[int] = @[]
var nextArc: seq[int] = @[]
var arcCapacity: seq[int] = @[]
var nodeLevel: seq[int] = @[]
var currentArc: seq[int] = @[]
var queueNodes: seq[int] = @[]
var sourceNode = 0
var sinkNode = 0

proc addEdge(startNode: int, endNode: int, capacity: int) =
  targetNode.add endNode
  arcCapacity.add capacity
  nextArc.add headArc[startNode]
  headArc[startNode] = targetNode.len - 1
  targetNode.add startNode
  arcCapacity.add 0
  nextArc.add headArc[endNode]
  headArc[endNode] = targetNode.len - 1

proc buildLevels(): bool =
  for nodeIndex in 0 .. nodeLevel.len - 1:
    nodeLevel[nodeIndex] = -1
  queueNodes.setLen 0
  nodeLevel[sourceNode] = 0
  queueNodes.add sourceNode
  var frontIndex = 0
  while frontIndex < queueNodes.len:
    let node = queueNodes[frontIndex]
    frontIndex += 1
    var arc = headArc[node]
    while arc != -1:
      let reachedNode = targetNode[arc]
      if arcCapacity[arc] > 0 and nodeLevel[reachedNode] == -1:
        nodeLevel[reachedNode] = nodeLevel[node] + 1
        queueNodes.add reachedNode
      arc = nextArc[arc]
  return nodeLevel[sinkNode] != -1

proc sendFlow(node: int, flowLimit: int): int =
  if node == sinkNode:
    return flowLimit
  while currentArc[node] != -1:
    let arc = currentArc[node]
    let reachedNode = targetNode[arc]
    if arcCapacity[arc] > 0 and nodeLevel[reachedNode] == nodeLevel[node] + 1:
      let pushed = sendFlow(reachedNode, min(flowLimit, arcCapacity[arc]))
      if pushed > 0:
        arcCapacity[arc] -= pushed
        arcCapacity[arc xor 1] += pushed
        return pushed
    currentArc[node] = nextArc[arc]
  return 0

proc minimumCost(): int =
  var totalFlow = 0
  while buildLevels():
    for nodeIndex in 0 .. currentArc.len - 1:
      currentArc[nodeIndex] = headArc[nodeIndex]
    while true:
      let pushed = sendFlow(sourceNode, high(int) div 4)
      if pushed == 0:
        break
      totalFlow += pushed
  return totalFlow

while scanPos < inputData.len:
  let guardCount = nextInt(inputData, scanPos)
  let friendCount = nextInt(inputData, scanPos)
  if guardCount == 0 and friendCount == 0:
    break
  let nodeCount = guardCount + 2
  sourceNode = 0
  sinkNode = guardCount + 1
  headArc = newSeq[int](nodeCount)
  nodeLevel = newSeq[int](nodeCount)
  currentArc = newSeq[int](nodeCount)
  targetNode = @[]
  nextArc = @[]
  arcCapacity = @[]
  for nodeIndex in 0 .. nodeCount - 1:
    headArc[nodeIndex] = -1
  for guardIndex in 0 .. guardCount - 1:
    let belief = nextInt(inputData, scanPos)
    if belief == 1:
      addEdge(sourceNode, guardIndex + 1, 1)
    else:
      addEdge(guardIndex + 1, sinkNode, 1)
  for friendIndex in 0 .. friendCount - 1:
    let firstGuard = nextInt(inputData, scanPos)
    let secondGuard = nextInt(inputData, scanPos)
    addEdge(firstGuard, secondGuard, 1)
    addEdge(secondGuard, firstGuard, 1)
  appendOutput($minimumCost())
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
