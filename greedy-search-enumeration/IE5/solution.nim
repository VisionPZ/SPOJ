const flushBlockBytes = 1 shl 17
const cycleModulus = 9901
const inverseOfTwo = 4951

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

proc findRoot(parent: var seq[int], vertex: int): int =
  var current = vertex
  while parent[current] != current:
    parent[current] = parent[parent[current]]
    current = parent[current]
  return current

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let nodeCount = nextInt(inputData, scanPos)
  let forbiddenCount = nextInt(inputData, scanPos)
  var edgeStart = newSeq[int](forbiddenCount)
  var edgeEnd = newSeq[int](forbiddenCount)
  for edgeIndex in 0 .. forbiddenCount - 1:
    edgeStart[edgeIndex] = nextInt(inputData, scanPos) - 1
    edgeEnd[edgeIndex] = nextInt(inputData, scanPos) - 1
  var factorial = newSeq[int](nodeCount + 1)
  factorial[0] = 1
  for position in 1 .. nodeCount:
    factorial[position] = factorial[position - 1] * position mod cycleModulus
  var powersOfTwo = newSeq[int](forbiddenCount + 1)
  powersOfTwo[0] = 1
  for position in 1 .. forbiddenCount:
    powersOfTwo[position] = powersOfTwo[position - 1] * 2 mod cycleModulus
  var degree = newSeq[int](nodeCount)
  var parent = newSeq[int](nodeCount)
  var edgeTally = newSeq[int](nodeCount)
  var vertexTally = newSeq[int](nodeCount)
  var answer = 0
  if nodeCount >= 3:
    for subset in 0 .. (1 shl forbiddenCount) - 1:
      for nodeIndex in 0 .. nodeCount - 1:
        degree[nodeIndex] = 0
        parent[nodeIndex] = nodeIndex
        edgeTally[nodeIndex] = 0
        vertexTally[nodeIndex] = 0
      var invalid = false
      var selectedEdges = 0
      for edgeIndex in 0 .. forbiddenCount - 1:
        if (subset and (1 shl edgeIndex)) != 0:
          let startNode = edgeStart[edgeIndex]
          let endNode = edgeEnd[edgeIndex]
          degree[startNode] += 1
          degree[endNode] += 1
          selectedEdges += 1
          if degree[startNode] > 2 or degree[endNode] > 2:
            invalid = true
      if invalid:
        continue
      var usedVertices = 0
      for nodeIndex in 0 .. nodeCount - 1:
        if degree[nodeIndex] > 0:
          usedVertices += 1
      var contribution = 0
      if selectedEdges == 0:
        contribution = factorial[nodeCount - 1] * inverseOfTwo mod cycleModulus
      else:
        for edgeIndex in 0 .. forbiddenCount - 1:
          if (subset and (1 shl edgeIndex)) != 0:
            let startRoot = findRoot(parent, edgeStart[edgeIndex])
            let endRoot = findRoot(parent, edgeEnd[edgeIndex])
            if startRoot != endRoot:
              parent[startRoot] = endRoot
        for nodeIndex in 0 .. nodeCount - 1:
          if degree[nodeIndex] > 0:
            let rootNode = findRoot(parent, nodeIndex)
            vertexTally[rootNode] += 1
        for edgeIndex in 0 .. forbiddenCount - 1:
          if (subset and (1 shl edgeIndex)) != 0:
            let rootNode = findRoot(parent, edgeStart[edgeIndex])
            edgeTally[rootNode] += 1
        var hasCycle = false
        var componentCount = 0
        for nodeIndex in 0 .. nodeCount - 1:
          if vertexTally[nodeIndex] > 0:
            componentCount += 1
            if edgeTally[nodeIndex] == vertexTally[nodeIndex]:
              hasCycle = true
        if hasCycle:
          if selectedEdges == nodeCount and usedVertices == nodeCount and componentCount == 1:
            contribution = 1
        else:
          var pathComponents = 0
          for nodeIndex in 0 .. nodeCount - 1:
            if edgeTally[nodeIndex] > 0:
              pathComponents += 1
          contribution = factorial[nodeCount - selectedEdges - 1] * inverseOfTwo mod cycleModulus
          contribution = contribution * powersOfTwo[pathComponents] mod cycleModulus
      if (selectedEdges mod 2) == 1:
        answer = (answer - contribution) mod cycleModulus
      else:
        answer = (answer + contribution) mod cycleModulus
      if answer < 0:
        answer = answer + cycleModulus
  appendOutput("Case #" & $(caseIndex + 1) & ": " & $answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
