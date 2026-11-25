const flushBlockBytes = 1 shl 17
const modulusValue = 1000000007

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

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let soldierCount = nextInt(inputData, scanPos)
  let deathLimit = nextInt(inputData, scanPos)
  var heightValues = newSeq[int](0)
  var heightCounts = newSeq[int](0)
  for soldierIndex in 0 .. soldierCount - 1:
    let soldierHeight = nextInt(inputData, scanPos)
    var foundIndex = -1
    for heightIndex in 0 .. heightValues.len - 1:
      if heightValues[heightIndex] == soldierHeight:
        foundIndex = heightIndex
        break
    if foundIndex < 0:
      heightValues.add soldierHeight
      heightCounts.add 1
    else:
      heightCounts[foundIndex] = heightCounts[foundIndex] + 1

  var heightOrder = newSeq[int](heightValues.len)
  for heightIndex in 0 .. heightValues.len - 1:
    heightOrder[heightIndex] = heightIndex
  for firstIndex in 1 .. heightOrder.len - 1:
    let currentOrder = heightOrder[firstIndex]
    var compareIndex = firstIndex - 1
    while compareIndex >= 0 and heightValues[heightOrder[compareIndex]] > heightValues[currentOrder]:
      heightOrder[compareIndex + 1] = heightOrder[compareIndex]
      compareIndex -= 1
    heightOrder[compareIndex + 1] = currentOrder

  var modularInverse = newSeq[int64](deathLimit + 2)
  if deathLimit + 1 >= 1:
    modularInverse[1] = 1
  for inverseIndex in 2 .. deathLimit + 1:
    modularInverse[inverseIndex] = modulusValue - (modulusValue div inverseIndex) * modularInverse[modulusValue mod inverseIndex] mod modulusValue

  var deleteWays = newSeq[int64](deathLimit + 1)
  deleteWays[0] = 1
  var lengthSoFar = 0
  var reachableDeaths = 0
  for orderIndex in 0 .. heightOrder.len - 1:
    let groupSize = heightCounts[heightOrder[orderIndex]]
    var nextWays = newSeq[int64](deathLimit + 1)
    if lengthSoFar == 0:
      for deathCount in 0 .. reachableDeaths:
        nextWays[deathCount] = deleteWays[deathCount]
    else:
      var kernelValues = newSeq[int64](deathLimit + 1)
      kernelValues[0] = 1
      for deathAdd in 1 .. deathLimit:
        kernelValues[deathAdd] = kernelValues[deathAdd - 1] * int64(lengthSoFar + deathAdd - 1) mod modulusValue
        kernelValues[deathAdd] = kernelValues[deathAdd] * modularInverse[deathAdd] mod modulusValue
      for deathCount in 0 .. reachableDeaths:
        let currentWays = deleteWays[deathCount]
        if currentWays == 0:
          continue
        let maxAdd = groupSize
        let limitAdd = deathLimit - deathCount
        for deathAdd in 0 .. min(maxAdd, limitAdd):
          nextWays[deathCount + deathAdd] = (nextWays[deathCount + deathAdd] + currentWays * kernelValues[deathAdd]) mod modulusValue
    deleteWays = nextWays
    lengthSoFar = lengthSoFar + groupSize
    reachableDeaths = min(deathLimit, lengthSoFar)

  appendOutput("Case " & $caseIndex & ": " & $deleteWays[deathLimit])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
