const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxStopsPerCase = 10000

var stopDistances = newSeq[int](maxStopsPerCase + 1)
var stopFuels = newSeq[int](maxStopsPerCase + 1)
var heapFuels = newSeq[int](maxStopsPerCase + 1)
var heapSize = 0

proc pushFuel(fuelAmount: int) =
  heapFuels[heapSize] = fuelAmount
  var childIndex = heapSize
  heapSize += 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if heapFuels[parentIndex] >= heapFuels[childIndex]: break
    swap heapFuels[parentIndex], heapFuels[childIndex]
    childIndex = parentIndex

proc popMaxFuel(): int =
  let largestFuel = heapFuels[0]
  heapSize -= 1
  if heapSize > 0:
    heapFuels[0] = heapFuels[heapSize]
    var parentIndex = 0
    while true:
      let leftChild = 2 * parentIndex + 1
      if leftChild >= heapSize: break
      let rightChild = leftChild + 1
      var largerChild = leftChild
      if rightChild < heapSize and heapFuels[rightChild] > heapFuels[leftChild]:
        largerChild = rightChild
      if heapFuels[parentIndex] >= heapFuels[largerChild]: break
      swap heapFuels[parentIndex], heapFuels[largerChild]
      parentIndex = largerChild
  return largestFuel

proc quickSortStops(lowIndex, highIndex: int) =
  if lowIndex >= highIndex: return
  let pivotDistance = stopDistances[(lowIndex + highIndex) div 2]
  var leftIndex = lowIndex
  var rightIndex = highIndex
  while leftIndex <= rightIndex:
    while stopDistances[leftIndex] < pivotDistance: leftIndex += 1
    while stopDistances[rightIndex] > pivotDistance: rightIndex -= 1
    if leftIndex <= rightIndex:
      swap stopDistances[leftIndex], stopDistances[rightIndex]
      swap stopFuels[leftIndex], stopFuels[rightIndex]
      leftIndex += 1
      rightIndex -= 1
  if lowIndex < rightIndex: quickSortStops(lowIndex, rightIndex)
  if leftIndex < highIndex: quickSortStops(leftIndex, highIndex)

proc sortStops(stopTotal: int) =
  if stopTotal > 1: quickSortStops(0, stopTotal - 1)

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

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
for _ in 0..<caseCount:
  let stopCount = nextInt(inputData, scanPos)
  for stopIndex in 0..<stopCount:
    stopDistances[stopIndex] = nextInt(inputData, scanPos)
    stopFuels[stopIndex] = nextInt(inputData, scanPos)
  let townDistance = nextInt(inputData, scanPos)
  let startingFuel = nextInt(inputData, scanPos)
  var keptCount = 0
  for stopIndex in 0..<stopCount:
    let distanceFromTown = stopDistances[stopIndex]
    if distanceFromTown <= townDistance:
      stopDistances[keptCount] = townDistance - distanceFromTown
      stopFuels[keptCount] = stopFuels[stopIndex]
      keptCount += 1
  sortStops(keptCount)
  heapSize = 0
  var currentFuel = startingFuel
  var currentPosition = 0
  var stopsUsed = 0
  var reachable = true
  for stopIndex in 0..<keptCount:
    let targetPosition = stopDistances[stopIndex]
    let travelDistance = targetPosition - currentPosition
    if travelDistance > currentFuel:
      while currentFuel < travelDistance and heapSize > 0:
        currentFuel += popMaxFuel()
        stopsUsed += 1
      if currentFuel < travelDistance:
        reachable = false
        break
    currentFuel -= travelDistance
    currentPosition = targetPosition
    pushFuel(stopFuels[stopIndex])
  if reachable:
    let remainingDistance = townDistance - currentPosition
    if remainingDistance > currentFuel:
      while currentFuel < remainingDistance and heapSize > 0:
        currentFuel += popMaxFuel()
        stopsUsed += 1
    if currentFuel >= remainingDistance:
      appendOutput($stopsUsed)
    else:
      reachable = false
  if not reachable: appendOutput("-1")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
