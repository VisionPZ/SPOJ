const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const unreachable = 1 shl 29
const casePrefix = "Case #"

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1..caseCount:
  let nodeCount = nextInt(inputData, scanPos)
  let edgeCount = nextInt(inputData, scanPos)
  var adjacent = newSeq[seq[int]](nodeCount + 1)
  for e in 0..<edgeCount:
    var firstNode = nextInt(inputData, scanPos)
    var secondNode = nextInt(inputData, scanPos)
    if firstNode > secondNode:
      swap(firstNode, secondNode)
    adjacent[firstNode].add(secondNode)
    adjacent[secondNode].add(firstNode)

  for node in 1..nodeCount:
    var k = 1
    while k < adjacent[node].len:
      let value = adjacent[node][k]
      var p = k - 1
      while p >= 0 and adjacent[node][p] > value:
        adjacent[node][p + 1] = adjacent[node][p]
        p -= 1
      adjacent[node][p + 1] = value
      k += 1

  var distance = newSeq[int](nodeCount + 1)
  var parentNode = newSeq[int](nodeCount + 1)
  var seenGeneration = newSeq[int](nodeCount + 1)
  var queue = newSeq[int](nodeCount + 1)
  var generation = 0

  var girth = unreachable
  var startNode = 1

  for root in 1..nodeCount:
    if girth == 3:
      break
    var largerNeighbors = 0
    for neighbor in adjacent[root]:
      if neighbor > root:
        largerNeighbors += 1
    if largerNeighbors < 2:
      continue

    generation += 1
    let depthCap = if girth >= unreachable: nodeCount else: (girth - 1) div 2
    distance[root] = 0
    parentNode[root] = -1
    seenGeneration[root] = generation
    queue[0] = root
    var head = 0
    var tail = 1
    while head < tail:
      let current = queue[head]
      head += 1
      let currentDepth = distance[current]
      for neighbor in adjacent[current]:
        if neighbor <= root:
          continue
        if seenGeneration[neighbor] == generation:
          if parentNode[current] != neighbor and parentNode[neighbor] != current:
            let candidate = currentDepth + distance[neighbor] + 1
            if candidate < girth:
              girth = candidate
              startNode = root
          continue
        if currentDepth >= depthCap:
          continue
        seenGeneration[neighbor] = generation
        distance[neighbor] = currentDepth + 1
        parentNode[neighbor] = current
        queue[tail] = neighbor
        tail += 1
      if girth == 3:
        break

  appendOutput(casePrefix)
  appendOutput($(caseIndex))
  appendOutput(": ")

  if girth == unreachable:
    appendOutput("-1")
    outputBuffer.add '\n'
    continue

  var used = newSeq[bool](nodeCount + 1)
  used[startNode] = true
  var tour = newSeq[int]()
  tour.add(startNode)

  for step in 0..<(girth - 1):
    let current = tour[tour.len - 1]
    let needed = girth - step - 1
    var chosen = -1
    for candidate in adjacent[current]:
      if candidate <= startNode or used[candidate]:
        continue
      generation += 1
      distance[candidate] = 0
      seenGeneration[candidate] = generation
      queue[0] = candidate
      var head = 0
      var tail = 1
      while head < tail:
        let here = queue[head]
        head += 1
        let hereDepth = distance[here]
        if hereDepth >= needed - 1:
          continue
        for neighbor in adjacent[here]:
          if neighbor <= startNode or used[neighbor]:
            continue
          if seenGeneration[neighbor] != generation:
            seenGeneration[neighbor] = generation
            distance[neighbor] = hereDepth + 1
            queue[tail] = neighbor
            tail += 1
      for neighbor in adjacent[startNode]:
        if (needed == 1 or neighbor != candidate) and not used[neighbor] and
           neighbor > startNode and seenGeneration[neighbor] == generation and
           distance[neighbor] == needed - 1:
          chosen = candidate
          break
      if chosen >= 0:
        break
    tour.add(chosen)
    used[chosen] = true

  appendOutput($(girth))
  for node in tour:
    appendOutput(" ")
    appendOutput($(node))
  appendOutput(" ")
  appendOutput($(startNode))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
