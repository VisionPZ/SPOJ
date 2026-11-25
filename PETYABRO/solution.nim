import algorithm

const flushBlockBytes = 1 shl 17
const infiniteDistance = 2305843009213693951

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

type Road = object
  firstCity: int
  secondCity: int
  repairCost: int

let cityCount = nextInt(inputData, scanPos)
let roadCount = nextInt(inputData, scanPos)

var isMilkman = newSeq[int](cityCount)
for cityIndex in 0 .. cityCount - 1:
  isMilkman[cityIndex] = nextInt(inputData, scanPos)

var roads = newSeq[Road](roadCount)
var firstNeighbour = newSeq[int](cityCount)
for cityIndex in 0 .. cityCount - 1:
  firstNeighbour[cityIndex] = -1
var neighbourCity = newSeq[int](2 * roadCount)
var neighbourCost = newSeq[int](2 * roadCount)
var nextNeighbour = newSeq[int](2 * roadCount)

for roadIndex in 0 .. roadCount - 1:
  let firstCity = nextInt(inputData, scanPos) - 1
  let secondCity = nextInt(inputData, scanPos) - 1
  let repairCost = nextInt(inputData, scanPos)
  roads[roadIndex] = Road(firstCity: firstCity, secondCity: secondCity, repairCost: repairCost)

  neighbourCity[2 * roadIndex] = secondCity
  neighbourCost[2 * roadIndex] = repairCost
  nextNeighbour[2 * roadIndex] = firstNeighbour[firstCity]
  firstNeighbour[firstCity] = 2 * roadIndex

  neighbourCity[2 * roadIndex + 1] = firstCity
  neighbourCost[2 * roadIndex + 1] = repairCost
  nextNeighbour[2 * roadIndex + 1] = firstNeighbour[secondCity]
  firstNeighbour[secondCity] = 2 * roadIndex + 1

var shortestDistance = newSeq[int64](cityCount)
var nearestMilkman = newSeq[int](cityCount)
for cityIndex in 0 .. cityCount - 1:
  shortestDistance[cityIndex] = infiniteDistance
  nearestMilkman[cityIndex] = -1

var heapCities = newSeq[int]()
var heapDistances = newSeq[int64]()

proc heapPush(cityIndex: int, distanceValue: int64) =
  heapCities.add cityIndex
  heapDistances.add distanceValue
  var childIndex = heapCities.len - 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if heapDistances[parentIndex] <= heapDistances[childIndex]:
      break
    swap heapDistances[parentIndex], heapDistances[childIndex]
    swap heapCities[parentIndex], heapCities[childIndex]
    childIndex = parentIndex

proc heapPop(): (int, int64) =
  let poppedCity = heapCities[0]
  let poppedDistance = heapDistances[0]
  let lastCity = heapCities[heapCities.len - 1]
  let lastDistance = heapDistances[heapDistances.len - 1]
  heapCities.setLen(heapCities.len - 1)
  heapDistances.setLen(heapDistances.len - 1)
  if heapCities.len > 0:
    heapCities[0] = lastCity
    heapDistances[0] = lastDistance
    var parentIndex = 0
    while true:
      let leftChild = 2 * parentIndex + 1
      if leftChild >= heapCities.len:
        break
      let rightChild = leftChild + 1
      var smallerChild = leftChild
      if rightChild < heapCities.len and heapDistances[rightChild] < heapDistances[leftChild]:
        smallerChild = rightChild
      if heapDistances[parentIndex] <= heapDistances[smallerChild]:
        break
      swap heapDistances[parentIndex], heapDistances[smallerChild]
      swap heapCities[parentIndex], heapCities[smallerChild]
      parentIndex = smallerChild
  return (poppedCity, poppedDistance)

for cityIndex in 0 .. cityCount - 1:
  if isMilkman[cityIndex] == 1:
    shortestDistance[cityIndex] = 0
    nearestMilkman[cityIndex] = cityIndex
    heapPush(cityIndex, 0)

while heapCities.len > 0:
  let (cityIndex, distanceValue) = heapPop()
  if distanceValue != shortestDistance[cityIndex]:
    continue
  var edgeIndex = firstNeighbour[cityIndex]
  while edgeIndex != -1:
    let neighbour = neighbourCity[edgeIndex]
    let candidate = distanceValue + int64(neighbourCost[edgeIndex])
    if candidate < shortestDistance[neighbour]:
      shortestDistance[neighbour] = candidate
      nearestMilkman[neighbour] = nearestMilkman[cityIndex]
      heapPush(neighbour, candidate)
    edgeIndex = nextNeighbour[edgeIndex]

roads.sort(proc(leftRoad, rightRoad: Road): int = cmp(leftRoad.repairCost, rightRoad.repairCost))

var parentCity = newSeq[int](cityCount)
var componentSize = newSeq[int](cityCount)
var componentMilkman = newSeq[int](cityCount)
var componentHasMilkman = newSeq[bool](cityCount)
for cityIndex in 0 .. cityCount - 1:
  parentCity[cityIndex] = cityIndex
  componentSize[cityIndex] = 1
  componentMilkman[cityIndex] = nearestMilkman[cityIndex]
  componentHasMilkman[cityIndex] = nearestMilkman[cityIndex] == cityIndex

proc findRoot(cityIndex: int): int =
  var current = cityIndex
  while parentCity[current] != current:
    parentCity[current] = parentCity[parentCity[current]]
    current = parentCity[current]
  return current

var totalCost: int64 = 0
for roadIndex in 0 .. roadCount - 1:
  let firstRoot = findRoot(roads[roadIndex].firstCity)
  let secondRoot = findRoot(roads[roadIndex].secondCity)
  if firstRoot == secondRoot:
    continue
  if componentMilkman[firstRoot] < 0 or componentMilkman[secondRoot] < 0:
    continue
  if componentMilkman[firstRoot] != componentMilkman[secondRoot]:
    continue
  var largerRoot = firstRoot
  var smallerRoot = secondRoot
  if componentSize[largerRoot] < componentSize[smallerRoot]:
    swap largerRoot, smallerRoot
  parentCity[smallerRoot] = largerRoot
  componentSize[largerRoot] += componentSize[smallerRoot]
  componentHasMilkman[largerRoot] = componentHasMilkman[largerRoot] or componentHasMilkman[smallerRoot]
  totalCost += int64(roads[roadIndex].repairCost)

var impossible = false
for cityIndex in 0 .. cityCount - 1:
  if nearestMilkman[cityIndex] < 0:
    impossible = true
    break
  let rootIndex = findRoot(cityIndex)
  if not componentHasMilkman[rootIndex]:
    impossible = true
    break

if impossible:
  appendOutput("impossible\n")
else:
  appendOutput($totalCost)
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
