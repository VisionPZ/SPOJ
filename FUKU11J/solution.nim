const flushBlockBytes = 1 shl 17
const maskCount = 1 shl 10
const altitudeLevels = 1001

type HeapItem = tuple[costValue: int64, firstTown: int, secondTown: int, paidMask: int]

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

var heapCosts = newSeq[int64]()
var heapFirsts = newSeq[int]()
var heapSeconds = newSeq[int]()
var heapMasks = newSeq[int]()

proc heapPush(item: HeapItem) =
  heapCosts.add item.costValue
  heapFirsts.add item.firstTown
  heapSeconds.add item.secondTown
  heapMasks.add item.paidMask
  var childIndex = heapCosts.len - 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if heapCosts[parentIndex] <= heapCosts[childIndex]:
      break
    swap heapCosts[parentIndex], heapCosts[childIndex]
    swap heapFirsts[parentIndex], heapFirsts[childIndex]
    swap heapSeconds[parentIndex], heapSeconds[childIndex]
    swap heapMasks[parentIndex], heapMasks[childIndex]
    childIndex = parentIndex

proc heapPop(): HeapItem =
  result = (heapCosts[0], heapFirsts[0], heapSeconds[0], heapMasks[0])
  let lastIndex = heapCosts.len - 1
  heapCosts[0] = heapCosts[lastIndex]
  heapFirsts[0] = heapFirsts[lastIndex]
  heapSeconds[0] = heapSeconds[lastIndex]
  heapMasks[0] = heapMasks[lastIndex]
  heapCosts.setLen lastIndex
  heapFirsts.setLen lastIndex
  heapSeconds.setLen lastIndex
  heapMasks.setLen lastIndex
  var parentIndex = 0
  while true:
    let leftIndex = 2 * parentIndex + 1
    if leftIndex >= heapCosts.len:
      break
    let rightIndex = leftIndex + 1
    var smallerIndex = leftIndex
    if rightIndex < heapCosts.len and heapCosts[rightIndex] < heapCosts[leftIndex]:
      smallerIndex = rightIndex
    if heapCosts[parentIndex] <= heapCosts[smallerIndex]:
      break
    swap heapCosts[parentIndex], heapCosts[smallerIndex]
    swap heapFirsts[parentIndex], heapFirsts[smallerIndex]
    swap heapSeconds[parentIndex], heapSeconds[smallerIndex]
    swap heapMasks[parentIndex], heapMasks[smallerIndex]
    parentIndex = smallerIndex

proc solveDataset(townCount, roadCount: int, visaFees: seq[int], altitudes: seq[int], roads: seq[tuple[first: int, second: int, cost: int]]): int64 =
  var goEdges = newSeq[seq[tuple[target: int, cost: int]]](townCount)
  var returnEdges = newSeq[seq[tuple[target: int, cost: int]]](townCount)
  for road in roads:
    if altitudes[road.first] <= altitudes[road.second]:
      goEdges[road.first].add (road.second, road.cost)
    if altitudes[road.first] >= altitudes[road.second]:
      returnEdges[road.second].add (road.first, road.cost)
  var groupIndexes = newSeq[int](townCount)
  for altitudeValue in 0 .. altitudeLevels - 1:
    var memberCount = 0
    for townIndex in 0 .. townCount - 1:
      if altitudes[townIndex] == altitudeValue:
        groupIndexes[townIndex] = memberCount
        memberCount += 1
  let stateCount = townCount * townCount * maskCount
  var distances = newSeq[int64]()
  distances.setLen 0
  distances.setLen stateCount
  heapCosts.setLen 0
  heapFirsts.setLen 0
  heapSeconds.setLen 0
  heapMasks.setLen 0
  distances[0] = 1
  heapPush((0.int64, 0, 0, 0))
  let destinationTown = townCount - 1
  while heapCosts.len > 0:
    let current = heapPop()
    let currentCost = current.costValue
    let firstTown = current.firstTown
    let secondTown = current.secondTown
    let currentMask = current.paidMask
    let currentIndex = (firstTown * townCount + secondTown) * maskCount + currentMask
    if distances[currentIndex] != currentCost + 1:
      continue
    if firstTown == destinationTown and secondTown == destinationTown:
      return currentCost
    if altitudes[firstTown] < altitudes[secondTown]:
      for edge in goEdges[firstTown]:
        let nextTown = edge.target
        var addedCost = int64(edge.cost) + int64(visaFees[nextTown])
        var nextMask = 0
        if altitudes[nextTown] > altitudes[firstTown]:
          if altitudes[nextTown] >= altitudes[secondTown]:
            nextMask = 1 shl groupIndexes[secondTown]
            if altitudes[nextTown] == altitudes[secondTown]:
              nextMask = nextMask or (1 shl groupIndexes[nextTown])
            if nextTown == secondTown:
              addedCost -= int64(visaFees[nextTown])
          else:
            nextMask = 1 shl groupIndexes[nextTown]
        else:
          if (currentMask and (1 shl groupIndexes[nextTown])) != 0:
            addedCost -= int64(visaFees[nextTown])
          nextMask = currentMask or (1 shl groupIndexes[nextTown])
        let nextCost = currentCost + addedCost
        let nextIndex = (nextTown * townCount + secondTown) * maskCount + nextMask
        if distances[nextIndex] == 0 or nextCost + 1 < distances[nextIndex]:
          distances[nextIndex] = nextCost + 1
          heapPush((nextCost, nextTown, secondTown, nextMask))
    else:
      for edge in returnEdges[secondTown]:
        let nextTown = edge.target
        var addedCost = int64(edge.cost) + int64(visaFees[nextTown])
        var nextMask = if altitudes[firstTown] == altitudes[secondTown]: currentMask else: 0
        if altitudes[nextTown] > altitudes[secondTown]:
          if altitudes[nextTown] >= altitudes[firstTown]:
            nextMask = nextMask or (1 shl groupIndexes[firstTown])
            if altitudes[nextTown] == altitudes[firstTown]:
              nextMask = nextMask or (1 shl groupIndexes[nextTown])
            if nextTown == firstTown:
              addedCost -= int64(visaFees[nextTown])
          else:
            nextMask = nextMask or (1 shl groupIndexes[nextTown])
        else:
          if (currentMask and (1 shl groupIndexes[nextTown])) != 0:
            addedCost -= int64(visaFees[nextTown])
          nextMask = currentMask or (1 shl groupIndexes[nextTown])
        let nextCost = currentCost + addedCost
        let nextIndex = (firstTown * townCount + nextTown) * maskCount + nextMask
        if distances[nextIndex] == 0 or nextCost + 1 < distances[nextIndex]:
          distances[nextIndex] = nextCost + 1
          heapPush((nextCost, firstTown, nextTown, nextMask))
  return -1

while true:
  let townCount = nextInt(inputData, scanPos)
  let roadCount = nextInt(inputData, scanPos)
  if townCount == 0 and roadCount == 0:
    break
  var visaFees = newSeq[int](townCount)
  var altitudes = newSeq[int](townCount)
  altitudes[0] = 0
  altitudes[townCount - 1] = 1000
  for townIndex in 1 .. townCount - 2:
    visaFees[townIndex] = nextInt(inputData, scanPos)
    altitudes[townIndex] = nextInt(inputData, scanPos)
  var roads = newSeq[tuple[first: int, second: int, cost: int]]()
  for roadIndex in 0 .. roadCount - 1:
    let startingTown = nextInt(inputData, scanPos) - 1
    let endingTown = nextInt(inputData, scanPos) - 1
    let travelCost = nextInt(inputData, scanPos)
    roads.add (startingTown, endingTown, travelCost)
  let bestCost = solveDataset(townCount, roadCount, visaFees, altitudes, roads)
  appendOutput($bestCost)
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
