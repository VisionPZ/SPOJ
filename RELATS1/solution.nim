const flushBlockBytes = 1 shl 18
const digitZeroValue = 48

proc nextInt(inputData: string, scanPos: var int): int =
  var byteCount = inputData.len
  while scanPos < byteCount and (inputData[scanPos] < '0' or inputData[scanPos] > '9') and inputData[scanPos] != '-':
    scanPos = scanPos + 1
  var signValue = 1
  if scanPos < byteCount and inputData[scanPos] == '-':
    signValue = -1
    scanPos = scanPos + 1
  var value = 0
  while scanPos < byteCount and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - digitZeroValue
    scanPos = scanPos + 1
  return signValue * value

proc findRoot(parent: var seq[int], vertex: int): int =
  var root = vertex
  while parent[root] != root:
    root = parent[root]
  var walk = vertex
  while parent[walk] != root:
    var nextVertex = parent[walk]
    parent[walk] = root
    walk = nextVertex
  return root

var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"

var scanPos = 0
var caseCount = nextInt(inputData, scanPos)
var outputBuffer: string

for caseIndex in 1 .. caseCount:
  var vertexCount = nextInt(inputData, scanPos)
  var edgeCount = nextInt(inputData, scanPos)
  var parent = newSeq[int](vertexCount + 1)
  for vertex in 1 .. vertexCount:
    parent[vertex] = vertex
  var strictFrom = newSeq[int](edgeCount)
  var strictTo = newSeq[int](edgeCount)
  var strictCount = 0
  for edgeIndex in 0 ..< edgeCount:
    var fromVertex = nextInt(inputData, scanPos)
    var toVertex = nextInt(inputData, scanPos)
    var edgeLabel = nextInt(inputData, scanPos)
    if edgeLabel == 0:
      var fromRoot = findRoot(parent, fromVertex)
      var toRoot = findRoot(parent, toVertex)
      if fromRoot != toRoot:
        parent[toRoot] = fromRoot
    else:
      strictFrom[strictCount] = fromVertex
      strictTo[strictCount] = toVertex
      if edgeLabel > 0:
        swap strictFrom[strictCount], strictTo[strictCount]
      strictCount = strictCount + 1

  var componentOf = newSeq[int](vertexCount + 1)
  var componentCount = 0
  for vertex in 1 .. vertexCount:
    var componentRoot = findRoot(parent, vertex)
    if componentOf[componentRoot] == 0:
      componentCount = componentCount + 1
      componentOf[componentRoot] = componentCount
    componentOf[vertex] = componentOf[componentRoot]

  var adjacency = newSeq[seq[int]](componentCount + 1)
  var inDegree = newSeq[int](componentCount + 1)
  for edgeIndex in 0 ..< strictCount:
    var sourceComponent = componentOf[strictFrom[edgeIndex]]
    var targetComponent = componentOf[strictTo[edgeIndex]]
    adjacency[sourceComponent].add targetComponent
    inDegree[targetComponent] = inDegree[targetComponent] + 1

  var queue = newSeq[int](componentCount + 1)
  var queueHead = 0
  var queueTail = 0
  for component in 1 .. componentCount:
    if inDegree[component] == 0:
      queue[queueTail] = component
      queueTail = queueTail + 1

  var longestPath = newSeq[int](componentCount + 1)
  var maxLongestPath = 0
  var processedCount = 0
  while queueHead < queueTail:
    var currentComponent = queue[queueHead]
    queueHead = queueHead + 1
    processedCount = processedCount + 1
    if longestPath[currentComponent] > maxLongestPath:
      maxLongestPath = longestPath[currentComponent]
    for neighbor in adjacency[currentComponent]:
      if longestPath[neighbor] < longestPath[currentComponent] + 1:
        longestPath[neighbor] = longestPath[currentComponent] + 1
      inDegree[neighbor] = inDegree[neighbor] - 1
      if inDegree[neighbor] == 0:
        queue[queueTail] = neighbor
        queueTail = queueTail + 1

  if processedCount < componentCount:
    outputBuffer.add "NO\n"
  else:
    outputBuffer.add $maxLongestPath
    outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
