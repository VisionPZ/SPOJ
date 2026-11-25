const flushBlockBytes = 1 shl 17
const negativeInfinity = -1000000000000000000'i64
const positiveInfinity = 1000000000000000000'i64

proc makeEmptyArray(limitValue: int, initializer: int64): seq[int64] =
  var resultArray = newSeq[int64](limitValue + 1)
  for sizeValue in 0 .. limitValue:
    resultArray[sizeValue] = initializer
  resultArray[0] = 0
  return resultArray

proc mergeMaximum(leftArray, rightArray: seq[int64], limitValue: int): seq[int64] =
  var mergedArray = makeEmptyArray(limitValue, negativeInfinity)
  for leftSize in 1 .. limitValue:
    if leftArray[leftSize] <= negativeInfinity div 2:
      continue
    for rightSize in 0 .. limitValue - leftSize:
      if rightArray[rightSize] <= negativeInfinity div 2:
        continue
      let combinedValue = leftArray[leftSize] + rightArray[rightSize]
      if combinedValue > mergedArray[leftSize + rightSize]:
        mergedArray[leftSize + rightSize] = combinedValue
  return mergedArray

proc mergeMinimum(leftArray, rightArray: seq[int64], limitValue: int): seq[int64] =
  var mergedArray = makeEmptyArray(limitValue, positiveInfinity)
  for leftSize in 1 .. limitValue:
    if leftArray[leftSize] >= positiveInfinity div 2:
      continue
    for rightSize in 0 .. limitValue - leftSize:
      if rightArray[rightSize] >= positiveInfinity div 2:
        continue
      let combinedValue = leftArray[leftSize] + rightArray[rightSize]
      if combinedValue < mergedArray[leftSize + rightSize]:
        mergedArray[leftSize + rightSize] = combinedValue
  return mergedArray

proc mergeSiblingMaximum(leftArray, rightArray: seq[int64], limitValue: int): seq[int64] =
  var mergedArray = makeEmptyArray(limitValue, negativeInfinity)
  for leftSize in 0 .. limitValue:
    if leftArray[leftSize] <= negativeInfinity div 2 and leftSize > 0:
      continue
    for rightSize in 0 .. limitValue - leftSize:
      if rightArray[rightSize] <= negativeInfinity div 2 and rightSize > 0:
        continue
      let combinedValue = leftArray[leftSize] + rightArray[rightSize]
      if combinedValue > mergedArray[leftSize + rightSize]:
        mergedArray[leftSize + rightSize] = combinedValue
  return mergedArray

proc mergeSiblingMinimum(leftArray, rightArray: seq[int64], limitValue: int): seq[int64] =
  var mergedArray = makeEmptyArray(limitValue, positiveInfinity)
  for leftSize in 0 .. limitValue:
    if leftArray[leftSize] >= positiveInfinity div 2 and leftSize > 0:
      continue
    for rightSize in 0 .. limitValue - leftSize:
      if rightArray[rightSize] >= positiveInfinity div 2 and rightSize > 0:
        continue
      let combinedValue = leftArray[leftSize] + rightArray[rightSize]
      if combinedValue < mergedArray[leftSize + rightSize]:
        mergedArray[leftSize + rightSize] = combinedValue
  return mergedArray

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let vertexCount = nextInt(inputData, scanPos)
  let firstSize = nextInt(inputData, scanPos)
  let secondSize = nextInt(inputData, scanPos)
  let sizeLimit = max(firstSize, secondSize)
  var vertexValues = newSeq[int64](vertexCount)
  for vertex in 0 .. vertexCount - 1:
    vertexValues[vertex] = int64(nextInt(inputData, scanPos))
  var adjacency = newSeq[seq[int]](vertexCount)
  for edgeIndex in 0 .. vertexCount - 2:
    let endpointLeft = nextInt(inputData, scanPos)
    let endpointRight = nextInt(inputData, scanPos)
    adjacency[endpointLeft].add endpointRight
    adjacency[endpointRight].add endpointLeft

  var parentVertex = newSeq[int](vertexCount)
  for vertex in 0 .. vertexCount - 1:
    parentVertex[vertex] = -1
  var traversalOrder = newSeq[int]()
  traversalOrder.add 0
  var traversalIndex = 0
  while traversalIndex < traversalOrder.len:
    let currentVertex = traversalOrder[traversalIndex]
    for neighbor in adjacency[currentVertex]:
      if neighbor != parentVertex[currentVertex]:
        parentVertex[neighbor] = currentVertex
        traversalOrder.add neighbor
    traversalIndex += 1

  var downMax = newSeq[seq[int64]](vertexCount)
  var downMin = newSeq[seq[int64]](vertexCount)
  var subtreeMax = newSeq[seq[int64]](vertexCount)
  var subtreeMin = newSeq[seq[int64]](vertexCount)
  for vertex in 0 .. vertexCount - 1:
    downMax[vertex] = makeEmptyArray(sizeLimit, negativeInfinity)
    downMin[vertex] = makeEmptyArray(sizeLimit, positiveInfinity)
    downMax[vertex][1] = vertexValues[vertex]
    downMin[vertex][1] = vertexValues[vertex]

  for orderIndex in countdown(traversalOrder.len - 1, 0):
    let currentVertex = traversalOrder[orderIndex]
    for neighbor in adjacency[currentVertex]:
      if parentVertex[neighbor] == currentVertex:
        downMax[currentVertex] = mergeMaximum(downMax[currentVertex], downMax[neighbor], sizeLimit)
        downMin[currentVertex] = mergeMinimum(downMin[currentVertex], downMin[neighbor], sizeLimit)
    subtreeMax[currentVertex] = downMax[currentVertex]
    subtreeMin[currentVertex] = downMin[currentVertex]
    for neighbor in adjacency[currentVertex]:
      if parentVertex[neighbor] == currentVertex:
        for sizeValue in 0 .. sizeLimit:
          if subtreeMax[neighbor][sizeValue] > subtreeMax[currentVertex][sizeValue]:
            subtreeMax[currentVertex][sizeValue] = subtreeMax[neighbor][sizeValue]
          if subtreeMin[neighbor][sizeValue] < subtreeMin[currentVertex][sizeValue]:
            subtreeMin[currentVertex][sizeValue] = subtreeMin[neighbor][sizeValue]

  var upBaseMax = newSeq[seq[int64]](vertexCount)
  var upBaseMin = newSeq[seq[int64]](vertexCount)
  var complementMax = newSeq[seq[int64]](vertexCount)
  var complementMin = newSeq[seq[int64]](vertexCount)
  for vertex in 0 .. vertexCount - 1:
    upBaseMax[vertex] = makeEmptyArray(sizeLimit, negativeInfinity)
    upBaseMin[vertex] = makeEmptyArray(sizeLimit, positiveInfinity)
    complementMax[vertex] = makeEmptyArray(sizeLimit, negativeInfinity)
    complementMin[vertex] = makeEmptyArray(sizeLimit, positiveInfinity)
  upBaseMax[0][1] = vertexValues[0]
  upBaseMin[0][1] = vertexValues[0]

  for orderIndex in 0 .. traversalOrder.len - 1:
    let currentVertex = traversalOrder[orderIndex]
    var childVertices = newSeq[int]()
    for neighbor in adjacency[currentVertex]:
      if parentVertex[neighbor] == currentVertex:
        childVertices.add neighbor
    let childCount = childVertices.len
    var prefixMax = newSeq[seq[int64]](childCount + 1)
    var prefixMin = newSeq[seq[int64]](childCount + 1)
    var suffixMax = newSeq[seq[int64]](childCount + 1)
    var suffixMin = newSeq[seq[int64]](childCount + 1)
    prefixMax[0] = upBaseMax[currentVertex]
    prefixMin[0] = upBaseMin[currentVertex]
    for childIndex in 0 .. childCount - 1:
      let childVertex = childVertices[childIndex]
      prefixMax[childIndex + 1] = mergeMaximum(prefixMax[childIndex], downMax[childVertex], sizeLimit)
      prefixMin[childIndex + 1] = mergeMinimum(prefixMin[childIndex], downMin[childVertex], sizeLimit)
    suffixMax[childCount] = makeEmptyArray(sizeLimit, negativeInfinity)
    suffixMin[childCount] = makeEmptyArray(sizeLimit, positiveInfinity)
    for childIndex in countdown(childCount - 1, 0):
      let childVertex = childVertices[childIndex]
      suffixMax[childIndex] = mergeSiblingMaximum(downMax[childVertex], suffixMax[childIndex + 1], sizeLimit)
      suffixMin[childIndex] = mergeSiblingMinimum(downMin[childVertex], suffixMin[childIndex + 1], sizeLimit)

    var precedingMax = newSeq[seq[int64]](childCount + 1)
    var precedingMin = newSeq[seq[int64]](childCount + 1)
    var followingMax = newSeq[seq[int64]](childCount + 1)
    var followingMin = newSeq[seq[int64]](childCount + 1)
    precedingMax[0] = makeEmptyArray(sizeLimit, negativeInfinity)
    precedingMin[0] = makeEmptyArray(sizeLimit, positiveInfinity)
    for childIndex in 0 .. childCount - 1:
      let childVertex = childVertices[childIndex]
      precedingMax[childIndex + 1] = makeEmptyArray(sizeLimit, negativeInfinity)
      precedingMin[childIndex + 1] = makeEmptyArray(sizeLimit, positiveInfinity)
      for sizeValue in 0 .. sizeLimit:
        precedingMax[childIndex + 1][sizeValue] = max(precedingMax[childIndex][sizeValue], subtreeMax[childVertex][sizeValue])
        precedingMin[childIndex + 1][sizeValue] = min(precedingMin[childIndex][sizeValue], subtreeMin[childVertex][sizeValue])
    followingMax[childCount] = makeEmptyArray(sizeLimit, negativeInfinity)
    followingMin[childCount] = makeEmptyArray(sizeLimit, positiveInfinity)
    for childIndex in countdown(childCount - 1, 0):
      let childVertex = childVertices[childIndex]
      followingMax[childIndex] = makeEmptyArray(sizeLimit, negativeInfinity)
      followingMin[childIndex] = makeEmptyArray(sizeLimit, positiveInfinity)
      for sizeValue in 0 .. sizeLimit:
        followingMax[childIndex][sizeValue] = max(followingMax[childIndex + 1][sizeValue], subtreeMax[childVertex][sizeValue])
        followingMin[childIndex][sizeValue] = min(followingMin[childIndex + 1][sizeValue], subtreeMin[childVertex][sizeValue])

    for childIndex in 0 .. childCount - 1:
      let childVertex = childVertices[childIndex]
      let excludedMax = mergeMaximum(prefixMax[childIndex], suffixMax[childIndex + 1], sizeLimit)
      let excludedMin = mergeMinimum(prefixMin[childIndex], suffixMin[childIndex + 1], sizeLimit)
      for sizeValue in 1 .. sizeLimit:
        if excludedMax[sizeValue - 1] > negativeInfinity div 2:
          upBaseMax[childVertex][sizeValue] = vertexValues[childVertex] + excludedMax[sizeValue - 1]
        if excludedMin[sizeValue - 1] < positiveInfinity div 2:
          upBaseMin[childVertex][sizeValue] = vertexValues[childVertex] + excludedMin[sizeValue - 1]
        complementMax[childVertex][sizeValue] = max(complementMax[currentVertex][sizeValue],
                                                     max(excludedMax[sizeValue], followingMax[childIndex + 1][sizeValue]))
        complementMin[childVertex][sizeValue] = min(complementMin[currentVertex][sizeValue],
                                                     min(excludedMin[sizeValue], followingMin[childIndex + 1][sizeValue]))
        if childIndex > 0:
          complementMax[childVertex][sizeValue] = max(complementMax[childVertex][sizeValue], precedingMax[childIndex][sizeValue])
          complementMin[childVertex][sizeValue] = min(complementMin[childVertex][sizeValue], precedingMin[childIndex][sizeValue])

  var bestAnswer = negativeInfinity
  for vertex in 1 .. vertexCount - 1:
    let insideFirst = subtreeMax[vertex][firstSize]
    let insideSecond = subtreeMin[vertex][secondSize]
    let outsideFirst = complementMax[vertex][firstSize]
    let outsideSecond = complementMin[vertex][secondSize]
    if insideFirst > negativeInfinity div 2 and outsideSecond < positiveInfinity div 2:
      let candidateValue = insideFirst - outsideSecond
      if candidateValue > bestAnswer:
        bestAnswer = candidateValue
    if outsideFirst > negativeInfinity div 2 and insideSecond < positiveInfinity div 2:
      let candidateValue = outsideFirst - insideSecond
      if candidateValue > bestAnswer:
        bestAnswer = candidateValue

  if bestAnswer <= negativeInfinity div 2:
    appendOutput("-1")
  else:
    appendOutput($bestAnswer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
