const flushBlockBytes = 1 shl 17
const moduloValue = 1000000007

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

proc reverseArc(arc: int): int =
  if (arc mod 2) == 1:
    return arc + 1
  return arc - 1

proc nextEvent(data: string, pos: var int): char =
  while pos < data.len and data[pos] != 'T' and data[pos] != 'S':
    pos += 1
  result = data[pos]
  pos += 1

proc fenwickAdd(bit: var seq[int], index: int, value: int) =
  var position = index
  while position < bit.len:
    bit[position] = (bit[position] + value) mod moduloValue
    position += position and (-position)

proc fenwickSum(bit: seq[int], index: int): int =
  var position = index
  var total = 0
  while position > 0:
    total = (total + bit[position]) mod moduloValue
    position -= position and (-position)
  return total

proc addRange(bit: var seq[int], leftIndex: int, rightIndex: int, value: int) =
  fenwickAdd(bit, leftIndex, value)
  let negated = if value == 0: 0 else: moduloValue - value
  fenwickAdd(bit, rightIndex + 1, negated)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let buildingCount = nextInt(inputData, scanPos)
  let walkwayCount = nextInt(inputData, scanPos)
  let eventCount = nextInt(inputData, scanPos)
  var firstArc = newSeq[int](buildingCount + 1)
  var arcTarget = newSeq[int](2 * walkwayCount + 2)
  var nextArc = newSeq[int](2 * walkwayCount + 2)
  var arcCount = 0
  for walkwayIndex in 0 .. walkwayCount - 1:
    let leftBuilding = nextInt(inputData, scanPos)
    let rightBuilding = nextInt(inputData, scanPos)
    arcCount += 1
    arcTarget[arcCount] = rightBuilding
    nextArc[arcCount] = firstArc[leftBuilding]
    firstArc[leftBuilding] = arcCount
    arcCount += 1
    arcTarget[arcCount] = leftBuilding
    nextArc[arcCount] = firstArc[rightBuilding]
    firstArc[rightBuilding] = arcCount
  var discoveryTime = newSeq[int](buildingCount + 1)
  var lowLink = newSeq[int](buildingCount + 1)
  var parentBuilding = newSeq[int](buildingCount + 1)
  var parentWalkway = newSeq[int](buildingCount + 1)
  var bridgeMark = newSeq[int](2 * walkwayCount + 2)
  var treeRoot = newSeq[int](buildingCount + 1)
  var stackBuildings = newSeq[int](buildingCount + 1)
  var stackArcs = newSeq[int](buildingCount + 1)
  var timerValue = 0
  for startBuilding in 1 .. buildingCount:
    if discoveryTime[startBuilding] != 0:
      continue
    timerValue += 1
    discoveryTime[startBuilding] = timerValue
    lowLink[startBuilding] = timerValue
    treeRoot[startBuilding] = startBuilding
    parentBuilding[startBuilding] = 0
    parentWalkway[startBuilding] = 0
    var stackTop = 0
    stackTop += 1
    stackBuildings[stackTop] = startBuilding
    stackArcs[stackTop] = firstArc[startBuilding]
    while stackTop > 0:
      let currentBuilding = stackBuildings[stackTop]
      var currentArc = stackArcs[stackTop]
      if currentArc != 0:
        stackArcs[stackTop] = nextArc[currentArc]
        let neighbor = arcTarget[currentArc]
        if parentWalkway[currentBuilding] != 0 and currentArc == reverseArc(parentWalkway[currentBuilding]):
          continue
        if discoveryTime[neighbor] == 0:
          parentBuilding[neighbor] = currentBuilding
          parentWalkway[neighbor] = currentArc
          treeRoot[neighbor] = startBuilding
          timerValue += 1
          discoveryTime[neighbor] = timerValue
          lowLink[neighbor] = timerValue
          stackTop += 1
          stackBuildings[stackTop] = neighbor
          stackArcs[stackTop] = firstArc[neighbor]
        else:
          if discoveryTime[neighbor] < lowLink[currentBuilding]:
            lowLink[currentBuilding] = discoveryTime[neighbor]
      else:
        stackTop -= 1
        if stackTop > 0:
          let parentNode = stackBuildings[stackTop]
          if lowLink[currentBuilding] < lowLink[parentNode]:
            lowLink[parentNode] = lowLink[currentBuilding]
          if lowLink[currentBuilding] > discoveryTime[parentNode]:
            let bridgeArc = parentWalkway[currentBuilding]
            bridgeMark[bridgeArc] = 1
            bridgeMark[reverseArc(bridgeArc)] = 2
  var componentOf = newSeq[int](buildingCount + 1)
  var buildQueue = newSeq[int](buildingCount + 1)
  var componentCount = 0
  for startBuilding in 1 .. buildingCount:
    if componentOf[startBuilding] != 0:
      continue
    componentCount += 1
    var queueHead = 0
    var queueTail = 0
    queueTail += 1
    buildQueue[queueTail] = startBuilding
    componentOf[startBuilding] = componentCount
    while queueHead < queueTail:
      queueHead += 1
      let currentBuilding = buildQueue[queueHead]
      var currentArc = firstArc[currentBuilding]
      while currentArc != 0:
        if bridgeMark[currentArc] == 0:
          let neighbor = arcTarget[currentArc]
          if componentOf[neighbor] == 0:
            componentOf[neighbor] = componentCount
            queueTail += 1
            buildQueue[queueTail] = neighbor
        currentArc = nextArc[currentArc]
  var treeFirst = newSeq[int](componentCount + 1)
  var treeTarget = newSeq[int](2 * componentCount + 2)
  var treeNext = newSeq[int](2 * componentCount + 2)
  var treeArcCount = 0
  for arc in 1 .. arcCount:
    if bridgeMark[arc] == 1:
      let leftComponent = componentOf[arcTarget[arc]]
      let rightComponent = componentOf[arcTarget[reverseArc(arc)]]
      treeArcCount += 1
      treeTarget[treeArcCount] = rightComponent
      treeNext[treeArcCount] = treeFirst[leftComponent]
      treeFirst[leftComponent] = treeArcCount
      treeArcCount += 1
      treeTarget[treeArcCount] = leftComponent
      treeNext[treeArcCount] = treeFirst[rightComponent]
      treeFirst[rightComponent] = treeArcCount
  var treeParent = newSeq[int](componentCount + 1)
  var treeDepth = newSeq[int](componentCount + 1)
  var traversalOrder = newSeq[int](componentCount + 1)
  var componentStack = newSeq[int](componentCount + 1)
  var orderSize = 0
  for rootComponent in 1 .. componentCount:
    if treeParent[rootComponent] != 0:
      continue
    treeParent[rootComponent] = rootComponent
    var stackTop = 0
    stackTop += 1
    componentStack[stackTop] = rootComponent
    while stackTop > 0:
      let currentComponent = componentStack[stackTop]
      stackTop -= 1
      orderSize += 1
      traversalOrder[orderSize] = currentComponent
      var arc = treeFirst[currentComponent]
      while arc != 0:
        let neighbor = treeTarget[arc]
        if neighbor != treeParent[currentComponent] and treeParent[neighbor] == 0:
          treeParent[neighbor] = currentComponent
          treeDepth[neighbor] = treeDepth[currentComponent] + 1
          stackTop += 1
          componentStack[stackTop] = neighbor
        arc = treeNext[arc]
  var subtreeSize = newSeq[int](componentCount + 1)
  var heavyChild = newSeq[int](componentCount + 1)
  for componentIndex in 1 .. componentCount:
    subtreeSize[componentIndex] = 1
  for orderIndex in countdown(orderSize, 1):
    let currentComponent = traversalOrder[orderIndex]
    var arc = treeFirst[currentComponent]
    while arc != 0:
      let neighbor = treeTarget[arc]
      if treeParent[neighbor] == currentComponent:
        subtreeSize[currentComponent] += subtreeSize[neighbor]
        if subtreeSize[neighbor] > subtreeSize[heavyChild[currentComponent]]:
          heavyChild[currentComponent] = neighbor
      arc = treeNext[arc]
  var chainHead = newSeq[int](componentCount + 1)
  var basePosition = newSeq[int](componentCount + 1)
  var chainStack = newSeq[int](componentCount + 1)
  var baseIndex = 0
  for rootComponent in 1 .. componentCount:
    if chainHead[rootComponent] != 0:
      continue
    var stackTop = 0
    stackTop += 1
    chainStack[stackTop] = rootComponent
    chainHead[rootComponent] = rootComponent
    while stackTop > 0:
      let chainRoot = chainStack[stackTop]
      stackTop -= 1
      var currentComponent = chainRoot
      while currentComponent != 0:
        baseIndex += 1
        basePosition[currentComponent] = baseIndex
        chainHead[currentComponent] = chainRoot
        var arc = treeFirst[currentComponent]
        while arc != 0:
          let neighbor = treeTarget[arc]
          if treeParent[neighbor] == currentComponent and neighbor != heavyChild[currentComponent]:
            stackTop += 1
            chainStack[stackTop] = neighbor
            chainHead[neighbor] = neighbor
          arc = treeNext[arc]
        currentComponent = heavyChild[currentComponent]
  var bitTree = newSeq[int](componentCount + 2)
  var buildingOffset = newSeq[int](buildingCount + 1)
  var totalEscorted = 0
  for eventIndex in 0 .. eventCount - 1:
    let eventType = nextEvent(inputData, scanPos)
    if eventType == 'T':
      let tourStart = nextInt(inputData, scanPos)
      let tourEnd = nextInt(inputData, scanPos)
      let outsiderCount = nextInt(inputData, scanPos)
      if treeRoot[tourStart] == treeRoot[tourEnd]:
        let amount = outsiderCount mod moduloValue
        var leftComponent = componentOf[tourStart]
        var rightComponent = componentOf[tourEnd]
        while chainHead[leftComponent] != chainHead[rightComponent]:
          if treeDepth[chainHead[leftComponent]] < treeDepth[chainHead[rightComponent]]:
            swap(leftComponent, rightComponent)
          addRange(bitTree, basePosition[chainHead[leftComponent]], basePosition[leftComponent], amount)
          leftComponent = treeParent[chainHead[leftComponent]]
        if treeDepth[leftComponent] > treeDepth[rightComponent]:
          swap(leftComponent, rightComponent)
        addRange(bitTree, basePosition[leftComponent], basePosition[rightComponent], amount)
    else:
      let sweptBuilding = nextInt(inputData, scanPos)
      let sweptComponent = componentOf[sweptBuilding]
      let groupAmount = fenwickSum(bitTree, basePosition[sweptComponent])
      let foundHere = (groupAmount + buildingOffset[sweptBuilding]) mod moduloValue
      totalEscorted = (totalEscorted + foundHere) mod moduloValue
      buildingOffset[sweptBuilding] = (moduloValue - groupAmount) mod moduloValue
  appendOutput($totalEscorted)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
