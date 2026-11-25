import algorithm

const flushBlockBytes = 1 shl 17
const noCity = -1

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

proc compareIntegers(left: int, right: int): int =
  if left < right:
    return -1
  elif left > right:
    return 1
  return 0

proc compareCliqueLists(left: seq[int], right: seq[int]): int =
  let sharedLength = min(left.len, right.len)
  for position in 0 .. sharedLength - 1:
    if left[position] != right[position]:
      return compareIntegers(left[position], right[position])
  return compareIntegers(left.len, right.len)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let roadCount = nextInt(inputData, scanPos)
var roadAdjacency = newSeq[seq[int]](roadCount)
for roadIndex in 0 .. roadCount - 1:
  let neighbourCount = nextInt(inputData, scanPos)
  var neighbours = newSeq[int](neighbourCount)
  for neighbourIndex in 0 .. neighbourCount - 1:
    neighbours[neighbourIndex] = nextInt(inputData, scanPos) - 1
  sort(neighbours, compareIntegers)
  roadAdjacency[roadIndex] = neighbours

proc hasNeighbour(source: int, target: int): bool =
  let neighbours = roadAdjacency[source]
  var lowIndex = 0
  var highIndex = neighbours.len - 1
  while lowIndex <= highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if neighbours[middleIndex] < target:
      lowIndex = middleIndex + 1
    elif neighbours[middleIndex] > target:
      highIndex = middleIndex - 1
    else:
      return true
  return false

var candidateCliques = newSeq[seq[int]]()
var validMap = true
var coveredPairs = newSeq[bool](roadCount * roadCount)
for firstRoad in 0 .. roadCount - 1:
  for secondRoad in firstRoad + 1 .. roadCount - 1:
    if coveredPairs[firstRoad * roadCount + secondRoad]:
      continue
    if not hasNeighbour(firstRoad, secondRoad):
      continue
    var shared = newSeq[int]()
    var firstPos = 0
    var secondPos = 0
    while firstPos < roadAdjacency[firstRoad].len and secondPos < roadAdjacency[secondRoad].len:
      let leftValue = roadAdjacency[firstRoad][firstPos]
      let rightValue = roadAdjacency[secondRoad][secondPos]
      if leftValue == rightValue:
        shared.add(leftValue)
        firstPos += 1
        secondPos += 1
      elif leftValue < rightValue:
        firstPos += 1
      else:
        secondPos += 1
    shared.add(firstRoad)
    shared.add(secondRoad)
    sort(shared, compareIntegers)
    for firstMember in 0 .. shared.len - 1:
      for secondMember in firstMember + 1 .. shared.len - 1:
        if not hasNeighbour(shared[firstMember], shared[secondMember]):
          validMap = false
        coveredPairs[shared[firstMember] * roadCount + shared[secondMember]] = true
    candidateCliques.add(shared)

sort(candidateCliques, compareCliqueLists)
var cliques = newSeq[seq[int]]()
for candidate in candidateCliques:
  if cliques.len > 0 and compareCliqueLists(cliques[cliques.len - 1], candidate) == 0:
    continue
  cliques.add(candidate)

var memberships = newSeq[seq[int]](roadCount)
for cliqueIndex in 0 .. cliques.len - 1:
  for roadIndex in cliques[cliqueIndex]:
    memberships[roadIndex].add(cliqueIndex)

var cityCount = cliques.len
var cityEdges = newSeq[seq[int]](cityCount + roadCount + 2)
var edgeEnds = newSeq[tuple[firstCity: int, secondCity: int]](roadCount)
var buildValid = validMap
for roadIndex in 0 .. roadCount - 1:
  let membership = memberships[roadIndex]
  if membership.len == 2:
    let firstCity = membership[0]
    let secondCity = membership[1]
    edgeEnds[roadIndex] = (firstCity, secondCity)
    cityEdges[firstCity].add(secondCity)
    cityEdges[secondCity].add(firstCity)
  elif membership.len == 1:
    let firstCity = membership[0]
    let secondCity = cityCount
    cityCount += 1
    edgeEnds[roadIndex] = (firstCity, secondCity)
    cityEdges[firstCity].add(secondCity)
    cityEdges[secondCity].add(firstCity)
  else:
    if roadCount != 1:
      buildValid = false
    else:
      edgeEnds[roadIndex] = (0, 1)
      cityCount = 2
      cityEdges[0].add(1)
      cityEdges[1].add(0)

if cityCount != roadCount + 1:
  buildValid = false

if buildValid:
  var visited = newSeq[bool](cityCount)
  var stack = newSeq[tuple[city: int, parent: int]]()
  visited[0] = true
  stack.add((0, noCity))
  while stack.len > 0:
    let frame = stack[stack.len - 1]
    stack.setLen(stack.len - 1)
    for neighbour in cityEdges[frame.city]:
      if neighbour == frame.parent:
        continue
      if visited[neighbour]:
        buildValid = false
      visited[neighbour] = true
      stack.add((neighbour, frame.city))
  for cityIndex in 0 .. cityCount - 1:
    if not visited[cityIndex]:
      buildValid = false

if buildValid:
  for firstRoad in 0 .. roadCount - 1:
    for secondRoad in firstRoad + 1 .. roadCount - 1:
      let firstEnds = edgeEnds[firstRoad]
      let secondEnds = edgeEnds[secondRoad]
      let shareCity = firstEnds.firstCity == secondEnds.firstCity or
                      firstEnds.firstCity == secondEnds.secondCity or
                      firstEnds.secondCity == secondEnds.firstCity or
                      firstEnds.secondCity == secondEnds.secondCity
      let claimedAdjacent = hasNeighbour(firstRoad, secondRoad)
      if shareCity != claimedAdjacent:
        buildValid = false

if not buildValid:
  appendOutput("NO\n")
  stdout.write outputBuffer
  outputBuffer.setLen 0
else:
  appendOutput("YES\n")
  for roadIndex in 0 .. roadCount - 1:
    appendOutput($(edgeEnds[roadIndex].firstCity + 1) & " " & $(edgeEnds[roadIndex].secondCity + 1) & "\n")
  stdout.write outputBuffer
  outputBuffer.setLen 0
