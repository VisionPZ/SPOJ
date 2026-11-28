const flushBlockBytes = 1 shl 17
const maxBuildingHeight = 10000

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

var costAtHeight = newSeq[int](maxBuildingHeight + 1)

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let buildingCount = nextInt(inputData, scanPos)
  var heights = newSeq[int](buildingCount)
  var costs = newSeq[int](buildingCount)
  for index in 0 .. buildingCount - 1:
    heights[index] = nextInt(inputData, scanPos)
  var totalWeight: int64 = 0
  for index in 0 .. buildingCount - 1:
    costs[index] = nextInt(inputData, scanPos)
    totalWeight += int64(costs[index])
  for heightIndex in 0 .. maxBuildingHeight:
    costAtHeight[heightIndex] = 0
  for index in 0 .. buildingCount - 1:
    costAtHeight[heights[index]] += costs[index]
  var bestHeight = 0
  var cumulativeWeight: int64 = 0
  for heightIndex in 0 .. maxBuildingHeight:
    cumulativeWeight += int64(costAtHeight[heightIndex])
    if 2 * cumulativeWeight >= totalWeight:
      bestHeight = heightIndex
      break
  var totalCost: int64 = 0
  for index in 0 .. buildingCount - 1:
    let heightGap = abs(heights[index] - bestHeight)
    totalCost += int64(costs[index]) * int64(heightGap)
  appendOutput($totalCost)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
