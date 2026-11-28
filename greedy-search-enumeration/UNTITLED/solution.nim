import algorithm

const flushBlockBytes = 1 shl 17

type
  ChildEntry = object
    label: int
    child: int

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

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let sequenceCount = nextInt(inputData, scanPos)
  var textValues = newSeq[int64]()
  var patternValues = newSeq[seq[int64]]()
  for sequenceIndex in 0 .. sequenceCount - 1:
    let lengthValue = nextInt(inputData, scanPos)
    var currentValues = newSeq[int64](lengthValue)
    for valueIndex in 0 .. lengthValue - 1:
      currentValues[valueIndex] = int64(nextInt(inputData, scanPos))
    if sequenceIndex == 0:
      textValues = currentValues
    else:
      patternValues.add currentValues
  var compressed = newSeq[int64]()
  for value in textValues:
    compressed.add value
  for pattern in patternValues:
    for value in pattern:
      compressed.add value
  proc compareValues(leftValue: int64, rightValue: int64): int =
    if leftValue < rightValue:
      return -1
    if leftValue > rightValue:
      return 1
    return 0

  compressed.sort(compareValues)
  var uniqueValues = newSeq[int64]()
  for value in compressed:
    if uniqueValues.len == 0 or uniqueValues[uniqueValues.len - 1] != value:
      uniqueValues.add value
  let valueCount = uniqueValues.len
  var treeSize = 1
  while treeSize < valueCount:
    treeSize = treeSize shl 1
  var patternLengthTotal = 0
  for pattern in patternValues:
    patternLengthTotal = patternLengthTotal + pattern.len
  let segmentCapacity = (textValues.len + patternLengthTotal) * 22 + 10
  var segmentLeft = newSeq[int](segmentCapacity)
  var segmentRight = newSeq[int](segmentCapacity)
  var segmentCount = newSeq[int](segmentCapacity)
  var segmentUsed = 1

  proc valueRank(value: int64): int =
    var lowIndex = 0
    var highIndex = valueCount - 1
    while lowIndex <= highIndex:
      let middleIndex = (lowIndex + highIndex) div 2
      if uniqueValues[middleIndex] == value:
        return middleIndex
      if uniqueValues[middleIndex] < value:
        lowIndex = middleIndex + 1
      else:
        highIndex = middleIndex - 1
    return valueCount

  proc updateVersion(previousRoot: int, lowBound: int, highBound: int, rankValue: int): int =
    let newNode = segmentUsed
    segmentUsed += 1
    segmentLeft[newNode] = segmentLeft[previousRoot]
    segmentRight[newNode] = segmentRight[previousRoot]
    segmentCount[newNode] = segmentCount[previousRoot]
    if highBound - lowBound == 1:
      segmentCount[newNode] = segmentCount[previousRoot] + 1
      return newNode
    let middleIndex = (lowBound + highBound) div 2
    if rankValue < middleIndex:
      let childRoot = updateVersion(segmentLeft[previousRoot], lowBound, middleIndex, rankValue)
      segmentLeft[newNode] = childRoot
    else:
      let childRoot = updateVersion(segmentRight[previousRoot], middleIndex, highBound, rankValue)
      segmentRight[newNode] = childRoot
    segmentCount[newNode] = segmentCount[segmentLeft[newNode]] + segmentCount[segmentRight[newNode]]
    return newNode

  proc countBelow(rootIndex: int, rankValue: int): int =
    var currentNode = rootIndex
    var lowBound = 0
    var highBound = treeSize
    var total = 0
    while currentNode != 0 and lowBound < highBound:
      if highBound <= rankValue:
        total = total + segmentCount[currentNode]
        break
      let middleIndex = (lowBound + highBound) div 2
      if rankValue < middleIndex:
        currentNode = segmentLeft[currentNode]
        highBound = middleIndex
      else:
        total = total + segmentCount[segmentLeft[currentNode]]
        currentNode = segmentRight[currentNode]
        lowBound = middleIndex
    return total

  var patternRoots = newSeq[int]()
  var patternOffsets = newSeq[int]()
  var patternRanks = newSeq[seq[int]]()
  for pattern in patternValues:
    patternOffsets.add patternRoots.len
    patternRoots.add 0
    var ranks = newSeq[int](pattern.len)
    for valueIndex in 0 .. pattern.len - 1:
      let rankValue = valueRank(pattern[valueIndex])
      ranks[valueIndex] = countBelow(patternRoots[patternOffsets[patternOffsets.len - 1] + valueIndex], rankValue)
      patternRoots.add updateVersion(patternRoots[patternOffsets[patternOffsets.len - 1] + valueIndex], 0, treeSize, rankValue)
    patternRanks.add ranks
  var textRoots = newSeq[int](textValues.len + 1)
  for valueIndex in 0 .. textValues.len - 1:
    textRoots[valueIndex + 1] = updateVersion(textRoots[valueIndex], 0, treeSize, valueRank(textValues[valueIndex]))

  var trieDepth = newSeq[int](1)
  var trieFail = newSeq[int](1)
  var triePattern = newSeq[int](1)
  var triePosition = newSeq[int](1)
  var trieTerminal = newSeq[bool](1)
  var trieTerminalLink = newSeq[int](1)
  trieTerminalLink[0] = -1
  var children = newSeq[seq[ChildEntry]](1)
  for patternIndex in 0 .. patternRanks.len - 1:
    var currentNode = 0
    for rankIndex in 0 .. patternRanks[patternIndex].len - 1:
      let labelValue = patternRanks[patternIndex][rankIndex]
      var foundChild = 0
      for entry in children[currentNode]:
        if entry.label == labelValue:
          foundChild = entry.child
          break
      if foundChild == 0:
        foundChild = children.len
        children.add newSeq[ChildEntry]()
        trieDepth.add rankIndex + 1
        trieFail.add 0
        triePattern.add patternIndex
        triePosition.add rankIndex + 1
        trieTerminal.add false
        trieTerminalLink.add -1
        children[currentNode].add ChildEntry(label: labelValue, child: foundChild)
      currentNode = foundChild
      if rankIndex == patternRanks[patternIndex].len - 1:
        trieTerminal[currentNode] = true

  for nodeIndex in 0 .. children.len - 1:
    for entryIndex in 1 .. children[nodeIndex].len - 1:
      let currentEntry = children[nodeIndex][entryIndex]
      var insertAt = entryIndex
      while insertAt > 0 and children[nodeIndex][insertAt - 1].label > currentEntry.label:
        children[nodeIndex][insertAt] = children[nodeIndex][insertAt - 1]
        insertAt -= 1
      children[nodeIndex][insertAt] = currentEntry

  proc findChild(nodeIndex: int, labelValue: int): int =
    let entryList = children[nodeIndex]
    var lowIndex = 0
    var highIndex = entryList.len - 1
    while lowIndex <= highIndex:
      let middleIndex = (lowIndex + highIndex) div 2
      if entryList[middleIndex].label == labelValue:
        return entryList[middleIndex].child
      if entryList[middleIndex].label < labelValue:
        lowIndex = middleIndex + 1
      else:
        highIndex = middleIndex - 1
    return 0

  proc smallerInSuffix(patternIndex: int, endPosition: int, windowLength: int, value: int64): int =
    if windowLength <= 0:
      return 0
    let offset = patternOffsets[patternIndex]
    let upperRoot = patternRoots[offset + endPosition - 1]
    let lowerRoot = patternRoots[offset + endPosition - windowLength - 1]
    return countBelow(upperRoot, valueRank(value)) - countBelow(lowerRoot, valueRank(value))

  var queue = newSeq[int]()
  for entry in children[0]:
    trieFail[entry.child] = 0
    queue.add entry.child
  var queueHead = 0
  while queueHead < queue.len:
    let parentNode = queue[queueHead]
    queueHead += 1
    if trieTerminal[parentNode]:
      trieTerminalLink[parentNode] = parentNode
    else:
      trieTerminalLink[parentNode] = trieTerminalLink[trieFail[parentNode]]
    for entry in children[parentNode]:
      let childNode = entry.child
      let patternIndex = triePattern[childNode]
      let endPosition = triePosition[childNode]
      let value = patternValues[patternIndex][endPosition - 1]
      var ancestorNode = trieFail[parentNode]
      var assigned = 0
      if ancestorNode != 0:
        var rankValue = smallerInSuffix(patternIndex, endPosition, trieDepth[ancestorNode], value)
        while true:
          let candidate = findChild(ancestorNode, rankValue)
          if candidate != 0:
            assigned = candidate
            break
          ancestorNode = trieFail[ancestorNode]
          if ancestorNode == 0:
            break
          rankValue = smallerInSuffix(patternIndex, endPosition, trieDepth[ancestorNode], value)
      if assigned == 0:
        assigned = findChild(0, 0)
      trieFail[childNode] = assigned
      queue.add childNode

  var stateNode = 0
  for textIndex in 0 .. textValues.len - 1:
    let currentPosition = textIndex + 1
    let currentValue = textValues[textIndex]
    let currentRank = valueRank(currentValue)
    while true:
      if stateNode == 0:
        let candidate = findChild(0, 0)
        if candidate != 0:
          stateNode = candidate
        break
      let windowLength = trieDepth[stateNode]
      let smallerCount = countBelow(textRoots[currentPosition - 1], currentRank) -
                         countBelow(textRoots[currentPosition - windowLength - 1], currentRank)
      let candidate = findChild(stateNode, smallerCount)
      if candidate != 0:
        stateNode = candidate
        break
      stateNode = trieFail[stateNode]
    if trieTerminalLink[stateNode] != -1:
      appendOutput($currentPosition)
      outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
