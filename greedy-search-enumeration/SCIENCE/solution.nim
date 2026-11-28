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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = ""
  while pos < data.len and data[pos] > ' ':
    result.add data[pos]
    pos += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc buildFactor(matrix: seq[string], personCount: int, targetDegree: int): tuple[degreeFound: int, factor: seq[string]] =
  let sourceNode = 2 * personCount
  let sinkNode = 2 * personCount + 1
  let nodeCount = 2 * personCount + 2
  var graph = newSeq[seq[int]](nodeCount)
  var edgeTarget = newSeq[int](0)
  var edgeCapacity = newSeq[int](0)

  proc addEdge(fromNode: int, toNode: int, capacity: int) =
    graph[fromNode].add edgeTarget.len
    edgeTarget.add toNode
    edgeCapacity.add capacity
    graph[toNode].add edgeTarget.len
    edgeTarget.add fromNode
    edgeCapacity.add 0

  var edgeIndexTable = newSeq[seq[int]](personCount)
  for personIndex in 0 .. personCount - 1:
    edgeIndexTable[personIndex] = newSeq[int](personCount)
    for buttonIndex in 0 .. personCount - 1:
      edgeIndexTable[personIndex][buttonIndex] = -1
    addEdge(sourceNode, personIndex, targetDegree)
  for buttonIndex in 0 .. personCount - 1:
    addEdge(personCount + buttonIndex, sinkNode, targetDegree)
  for personIndex in 0 .. personCount - 1:
    for buttonIndex in 0 .. personCount - 1:
      if matrix[personIndex][buttonIndex] == 'Y':
        edgeIndexTable[personIndex][buttonIndex] = edgeTarget.len
        addEdge(personIndex, personCount + buttonIndex, 1)

  let wantedFlow = targetDegree * personCount
  var totalFlow = 0
  var level = newSeq[int](nodeCount)
  while true:
    for nodeIndex in 0 .. nodeCount - 1:
      level[nodeIndex] = -1
    var queue = newSeq[int](nodeCount)
    var queueHead = 0
    var queueTail = 0
    level[sourceNode] = 0
    queue[queueTail] = sourceNode
    queueTail += 1
    while queueHead < queueTail:
      let currentNode = queue[queueHead]
      queueHead += 1
      for edgeIndex in graph[currentNode]:
        let nextNode = edgeTarget[edgeIndex]
        if edgeCapacity[edgeIndex] > 0 and level[nextNode] < 0:
          level[nextNode] = level[currentNode] + 1
          queue[queueTail] = nextNode
          queueTail += 1
    if level[sinkNode] < 0:
      break
    var cursor = newSeq[int](nodeCount)
    proc send(currentNode: int, available: int): int =
      if currentNode == sinkNode:
        return available
      while cursor[currentNode] < graph[currentNode].len:
        let edgeIndex = graph[currentNode][cursor[currentNode]]
        let nextNode = edgeTarget[edgeIndex]
        if edgeCapacity[edgeIndex] > 0 and level[nextNode] == level[currentNode] + 1:
          let sent = send(nextNode, min(available, edgeCapacity[edgeIndex]))
          if sent > 0:
            edgeCapacity[edgeIndex] = edgeCapacity[edgeIndex] - sent
            edgeCapacity[edgeIndex xor 1] = edgeCapacity[edgeIndex xor 1] + sent
            return sent
        cursor[currentNode] += 1
      return 0
    while true:
      let sent = send(sourceNode, wantedFlow - totalFlow)
      if sent == 0:
        break
      totalFlow += sent
    if totalFlow == wantedFlow:
      break

  var factor = newSeq[string](personCount)
  for personIndex in 0 .. personCount - 1:
    var row = ""
    for buttonIndex in 0 .. personCount - 1:
      let edgeIndex = edgeIndexTable[personIndex][buttonIndex]
      if edgeIndex >= 0 and edgeCapacity[edgeIndex] == 0:
        row.add 'Y'
      else:
        row.add 'N'
    factor[personIndex] = row
  return (totalFlow, factor)

proc findMatching(matrix: seq[string], personCount: int): seq[int] =
  var pairPerson = newSeq[int](personCount)
  var pairButton = newSeq[int](personCount)
  var distance = newSeq[int](personCount)
  for index in 0 .. personCount - 1:
    pairPerson[index] = -1
    pairButton[index] = -1

  proc search(current: int): bool =
    for buttonIndex in 0 .. personCount - 1:
      if matrix[current][buttonIndex] == 'Y':
        let owner = pairButton[buttonIndex]
        if owner == -1 or (distance[owner] == distance[current] + 1 and search(owner)):
          pairPerson[current] = buttonIndex
          pairButton[buttonIndex] = current
          return true
    distance[current] = -1
    return false

  while true:
    var queue = newSeq[int](personCount)
    var queueHead = 0
    var queueTail = 0
    var foundFree = false
    for personIndex in 0 .. personCount - 1:
      if pairPerson[personIndex] == -1:
        distance[personIndex] = 0
        queue[queueTail] = personIndex
        queueTail += 1
      else:
        distance[personIndex] = -1
    while queueHead < queueTail:
      let current = queue[queueHead]
      queueHead += 1
      for buttonIndex in 0 .. personCount - 1:
        if matrix[current][buttonIndex] == 'Y':
          let owner = pairButton[buttonIndex]
          if owner == -1:
            foundFree = true
          elif distance[owner] < 0:
            distance[owner] = distance[current] + 1
            queue[queueTail] = owner
            queueTail += 1
    if not foundFree:
      break
    var augmented = 0
    for personIndex in 0 .. personCount - 1:
      if pairPerson[personIndex] == -1:
        if search(personIndex):
          augmented += 1
    if augmented == 0:
      break

  for personIndex in 0 .. personCount - 1:
    if pairPerson[personIndex] == -1:
      return newSeq[int](0)
  return pairButton

proc compareMatchings(left: seq[int], right: seq[int]): int =
  for buttonIndex in 0 .. left.len - 1:
    if left[buttonIndex] != right[buttonIndex]:
      if left[buttonIndex] < right[buttonIndex]:
        return -1
      return 1
  return 0

while true:
  let personCount = nextInt(inputData, scanPos)
  if personCount == 0:
    break
  var matrix = newSeq[string](personCount)
  for personIndex in 0 .. personCount - 1:
    matrix[personIndex] = nextToken(inputData, scanPos)

  var minDegree = personCount
  for personIndex in 0 .. personCount - 1:
    var degree = 0
    for buttonIndex in 0 .. personCount - 1:
      if matrix[personIndex][buttonIndex] == 'Y':
        degree += 1
    if degree < minDegree:
      minDegree = degree
  for buttonIndex in 0 .. personCount - 1:
    var degree = 0
    for personIndex in 0 .. personCount - 1:
      if matrix[personIndex][buttonIndex] == 'Y':
        degree += 1
    if degree < minDegree:
      minDegree = degree

  var lowDegree = 0
  var highDegree = minDegree
  while lowDegree < highDegree:
    let middleDegree = (lowDegree + highDegree + 1) div 2
    if buildFactor(matrix, personCount, middleDegree).degreeFound == middleDegree * personCount:
      lowDegree = middleDegree
    else:
      highDegree = middleDegree - 1

  var factor = buildFactor(matrix, personCount, lowDegree).factor
  var matchings = newSeq[seq[int]](0)
  while lowDegree > 0:
    let matching = findMatching(factor, personCount)
    if matching.len == 0:
      break
    matchings.add matching
    for buttonIndex in 0 .. personCount - 1:
      factor[matching[buttonIndex]][buttonIndex] = 'N'

  for matchIndex in 1 .. matchings.len - 1:
    let current = matchings[matchIndex]
    var position = matchIndex
    while position > 0 and compareMatchings(current, matchings[position - 1]) < 0:
      matchings[position] = matchings[position - 1]
      position -= 1
    matchings[position] = current

  if matchings.len == 0:
    appendOutput("NO SCIENCE\n")
  else:
    appendOutput($matchings.len)
    appendOutput("\n")
    for matching in matchings:
      var line = ""
      for buttonIndex in 0 .. personCount - 1:
        if buttonIndex > 0:
          line.add ' '
        line.add $(matching[buttonIndex] + 1)
      line.add '\n'
      appendOutput(line)
stdout.write outputBuffer
outputBuffer.setLen 0
