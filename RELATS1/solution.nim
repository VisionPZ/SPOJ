const flushBlockBytes = 1 shl 18
const digitZeroValue = 48

proc nextInt(inputData: string, i: var int): int =
  var byteCount = inputData.len
  while i < byteCount and (inputData[i] < '0' or inputData[i] > '9') and inputData[i] != '-':
    i = i + 1
  var signValue = 1
  if i < byteCount and inputData[i] == '-':
    signValue = -1
    i = i + 1
  var value = 0
  while i < byteCount and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - digitZeroValue
    i = i + 1
  return signValue * value

proc findRoot(parent: var seq[int], i: int): int =
  var root = i
  while parent[root] != root:
    root = parent[root]
  var j = i
  while parent[j] != root:
    var nextVertex = parent[j]
    parent[j] = root
    j = nextVertex
  return root

var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"

var i = 0
var caseCount = nextInt(inputData, i)
var outputBuffer: string

for j in 1 .. caseCount:
  var vertexCount = nextInt(inputData, i)
  var edgeCount = nextInt(inputData, i)
  var parent = newSeq[int](vertexCount + 1)
  for k in 1 .. vertexCount:
    parent[k] = k
  var strictFrom = newSeq[int](edgeCount)
  var strictTo = newSeq[int](edgeCount)
  var strictCount = 0
  for k in 0 ..< edgeCount:
    var fromVertex = nextInt(inputData, i)
    var toVertex = nextInt(inputData, i)
    var edgeLabel = nextInt(inputData, i)
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
  for k in 1 .. vertexCount:
    var componentRoot = findRoot(parent, k)
    if componentOf[componentRoot] == 0:
      componentCount = componentCount + 1
      componentOf[componentRoot] = componentCount
    componentOf[k] = componentOf[componentRoot]

  var adjacency = newSeq[seq[int]](componentCount + 1)
  var inDegree = newSeq[int](componentCount + 1)
  for k in 0 ..< strictCount:
    var sourceComponent = componentOf[strictFrom[k]]
    var targetComponent = componentOf[strictTo[k]]
    adjacency[sourceComponent].add targetComponent
    inDegree[targetComponent] = inDegree[targetComponent] + 1

  var queue = newSeq[int](componentCount + 1)
  var queueHead = 0
  var queueTail = 0
  for k in 1 .. componentCount:
    if inDegree[k] == 0:
      queue[queueTail] = k
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
