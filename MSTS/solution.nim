const flushBlockBytes = 1 shl 17
const answerModulus = 31011
const firstPrime = 3
const secondPrime = 10337
const inverseThree = 3446

type
  GraphEdge = object
    sourceNode: int
    targetNode: int
    weight: int

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

var parentNode = newSeq[int](1)
var componentSize = newSeq[int](1)

proc findRoot(node: int): int =
  var current = node
  while parentNode[current] != current:
    parentNode[current] = parentNode[parentNode[current]]
    current = parentNode[current]
  return current

proc unionRoots(firstRoot: int, secondRoot: int) =
  var firstParent = findRoot(firstRoot)
  var secondParent = findRoot(secondRoot)
  if firstParent == secondParent:
    return
  if componentSize[firstParent] < componentSize[secondParent]:
    swap firstParent, secondParent
  parentNode[secondParent] = firstParent
  componentSize[firstParent] = componentSize[firstParent] + componentSize[secondParent]

proc powerModulo(baseValue: int64, exponent: int64, modulus: int64): int64 =
  var result: int64 = 1
  var current = baseValue mod modulus
  var powerLeft = exponent
  while powerLeft > 0:
    if (powerLeft and 1) == 1:
      result = (result * current) mod modulus
    current = (current * current) mod modulus
    powerLeft = powerLeft shr 1
  return result

proc determinantModulo(matrix: seq[int64], dimension: int, modulus: int64): int64 =
  var work = newSeq[int64](dimension * dimension)
  for rowIndex in 0 .. dimension - 1:
    for columnIndex in 0 .. dimension - 1:
      var value = matrix[rowIndex * dimension + columnIndex] mod modulus
      if value < 0:
        value = value + modulus
      work[rowIndex * dimension + columnIndex] = value
  var result: int64 = 1
  for columnIndex in 0 .. dimension - 1:
    var pivotRow = columnIndex
    while pivotRow < dimension and work[pivotRow * dimension + columnIndex] == 0:
      pivotRow += 1
    if pivotRow == dimension:
      return 0
    if pivotRow != columnIndex:
      for columnScan in 0 .. dimension - 1:
        swap work[pivotRow * dimension + columnScan], work[columnIndex * dimension + columnScan]
      result = (-result) mod modulus
      if result < 0:
        result = result + modulus
    let pivotValue = work[columnIndex * dimension + columnIndex]
    result = (result * pivotValue) mod modulus
    let pivotInverse = powerModulo(pivotValue, modulus - 2, modulus)
    for rowIndex in columnIndex + 1 .. dimension - 1:
      if work[rowIndex * dimension + columnIndex] == 0:
        continue
      let factor = (work[rowIndex * dimension + columnIndex] * pivotInverse) mod modulus
      for columnScan in columnIndex .. dimension - 1:
        var updated = work[rowIndex * dimension + columnScan] - factor * work[columnIndex * dimension + columnScan]
        updated = updated mod modulus
        if updated < 0:
          updated = updated + modulus
        work[rowIndex * dimension + columnScan] = updated
  return result

proc spanningTreeCount(adjacency: seq[seq[int]], members: seq[int], modulus: int64): int64 =
  let vertexCount = members.len
  if vertexCount < 2:
    return 1
  let dimension = vertexCount - 1
  var removedLocal = members[0]
  for memberLocal in members:
    if memberLocal > removedLocal:
      removedLocal = memberLocal
  var matrixIndex = newSeq[int](adjacency.len)
  for indexValue in 0 .. matrixIndex.len - 1:
    matrixIndex[indexValue] = -1
  var nextIndex = 0
  for memberLocal in members:
    if memberLocal != removedLocal:
      matrixIndex[memberLocal] = nextIndex
      nextIndex += 1
  var matrix = newSeq[int64](dimension * dimension)
  for sourceLocal in members:
    for targetLocal in adjacency[sourceLocal]:
      if sourceLocal >= targetLocal:
        continue
      let sourceIndex = matrixIndex[sourceLocal]
      let targetIndex = matrixIndex[targetLocal]
      if sourceIndex != -1:
        matrix[sourceIndex * dimension + sourceIndex] = matrix[sourceIndex * dimension + sourceIndex] + 1
      if targetIndex != -1:
        matrix[targetIndex * dimension + targetIndex] = matrix[targetIndex * dimension + targetIndex] + 1
      if sourceIndex != -1 and targetIndex != -1:
        matrix[sourceIndex * dimension + targetIndex] = matrix[sourceIndex * dimension + targetIndex] - 1
        matrix[targetIndex * dimension + sourceIndex] = matrix[targetIndex * dimension + sourceIndex] - 1
  return determinantModulo(matrix, dimension, modulus)

let nodeCount = nextInt(inputData, scanPos)
let edgeCount = nextInt(inputData, scanPos)
var edges = newSeq[GraphEdge](edgeCount)
for edgeIndex in 0 .. edgeCount - 1:
  edges[edgeIndex].sourceNode = nextInt(inputData, scanPos)
  edges[edgeIndex].targetNode = nextInt(inputData, scanPos)
  edges[edgeIndex].weight = nextInt(inputData, scanPos)
for edgeIndex in 1 .. edgeCount - 1:
  let currentEdge = edges[edgeIndex]
  var insertAt = edgeIndex
  while insertAt > 0 and edges[insertAt - 1].weight > currentEdge.weight:
    edges[insertAt] = edges[insertAt - 1]
    insertAt -= 1
  edges[insertAt] = currentEdge

parentNode = newSeq[int](nodeCount + 1)
componentSize = newSeq[int](nodeCount + 1)
for nodeIndex in 1 .. nodeCount:
  parentNode[nodeIndex] = nodeIndex
  componentSize[nodeIndex] = 1

var answer: int64 = 1
var localIndex = newSeq[int](nodeCount + 1)
for nodeIndex in 0 .. nodeCount:
  localIndex[nodeIndex] = -1
var groupStart = 0
while groupStart < edgeCount:
  var groupEnd = groupStart
  while groupEnd < edgeCount and edges[groupEnd].weight == edges[groupStart].weight:
    groupEnd += 1
  var localRoots = newSeq[int]()
  var auxEdges = newSeq[tuple[first: int, second: int]]()
  for edgeIndex in groupStart .. groupEnd - 1:
    let firstRoot = findRoot(edges[edgeIndex].sourceNode)
    let secondRoot = findRoot(edges[edgeIndex].targetNode)
    if firstRoot == secondRoot:
      continue
    if localIndex[firstRoot] == -1:
      localIndex[firstRoot] = localRoots.len
      localRoots.add firstRoot
    if localIndex[secondRoot] == -1:
      localIndex[secondRoot] = localRoots.len
      localRoots.add secondRoot
    auxEdges.add (localIndex[firstRoot], localIndex[secondRoot])
  let localCount = localRoots.len
  var adjacency = newSeq[seq[int]](localCount)
  for localEdge in auxEdges:
    adjacency[localEdge.first].add localEdge.second
    adjacency[localEdge.second].add localEdge.first
  var visited = newSeq[bool](localCount)
  for startLocal in 0 .. localCount - 1:
    if visited[startLocal]:
      continue
    var members = newSeq[int]()
    var stack = newSeq[int]()
    stack.add startLocal
    visited[startLocal] = true
    while stack.len > 0:
      let currentLocal = stack[stack.len - 1]
      stack.setLen(stack.len - 1)
      members.add currentLocal
      for neighborLocal in adjacency[currentLocal]:
        if not visited[neighborLocal]:
          visited[neighborLocal] = true
          stack.add neighborLocal
    var areaCount = spanningTreeCount(adjacency, members, int64(firstPrime))
    var bigCount = spanningTreeCount(adjacency, members, int64(secondPrime))
    let difference = (bigCount - areaCount mod int64(secondPrime) + int64(secondPrime)) mod int64(secondPrime)
    let combined = (areaCount + int64(firstPrime) * ((difference * int64(inverseThree)) mod int64(secondPrime))) mod int64(answerModulus)
    answer = (answer * combined) mod int64(answerModulus)
  for edgeIndex in groupStart .. groupEnd - 1:
    unionRoots(edges[edgeIndex].sourceNode, edges[edgeIndex].targetNode)
  for localRoot in localRoots:
    localIndex[localRoot] = -1
  groupStart = groupEnd

appendOutput($answer)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
