const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxCity = 100
const maxParcel = 12
const infinite = int64(1) shl 60

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var distTable: array[0..maxCity, array[0..maxCity, int64]]
var parcelSource: array[0..maxParcel - 1, int]
var parcelTarget: array[0..maxParcel - 1, int]
var carryCostOf: array[0..maxParcel - 1, int64]
var bestCost = newSeq[int64]((1 shl maxParcel) * maxParcel)

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let cityCount = nextInt(inputData, scanPos)
  let roadCount = nextInt(inputData, scanPos)
  let homeCity = nextInt(inputData, scanPos)
  for i in 0..maxCity:
    for j in 0..maxCity:
      distTable[i][j] = if i == j: int64(0) else: infinite
  for i in 0..<roadCount:
    let fromCity = nextInt(inputData, scanPos)
    let toCity = nextInt(inputData, scanPos)
    let roadLength = int64(nextInt(inputData, scanPos))
    if roadLength < distTable[fromCity][toCity]:
      distTable[fromCity][toCity] = roadLength
      distTable[toCity][fromCity] = roadLength
  for k in 0..cityCount:
    for i in 1..cityCount:
      let throughCost = distTable[i][k]
      if throughCost >= infinite: continue
      for j in 1..cityCount:
        let beyondCost = distTable[k][j]
        if beyondCost >= infinite: continue
        let candidate = throughCost + beyondCost
        if candidate < distTable[i][j]:
          distTable[i][j] = candidate
  let requestCount = nextInt(inputData, scanPos)
  var parcelCount = 0
  for i in 0..<requestCount:
    let fromCity = nextInt(inputData, scanPos)
    let toCity = nextInt(inputData, scanPos)
    let parcelTotal = nextInt(inputData, scanPos)
    for j in 0..<parcelTotal:
      parcelSource[parcelCount] = fromCity
      parcelTarget[parcelCount] = toCity
      parcelCount += 1
  if parcelCount == 0:
    appendOutput("0")
    outputBuffer.add '\n'
    continue
  for i in 0..<parcelCount:
    carryCostOf[i] = distTable[parcelSource[i]][parcelTarget[i]]
  let stateCount = 1 shl parcelCount
  for stateIndex in 0..<(stateCount * parcelCount):
    bestCost[stateIndex] = infinite
  for i in 0..<parcelCount:
    let entryCost = distTable[homeCity][parcelSource[i]]
    if entryCost >= infinite or carryCostOf[i] >= infinite: continue
    bestCost[(1 shl i) * parcelCount + i] = entryCost + carryCostOf[i]
  for mask in 1..<stateCount:
    for i in 0..<parcelCount:
      if (mask and (1 shl i)) == 0: continue
      let currentCost = bestCost[mask * parcelCount + i]
      if currentCost >= infinite: continue
      for j in 0..<parcelCount:
        if (mask and (1 shl j)) != 0: continue
        let approachCost = distTable[parcelTarget[i]][parcelSource[j]]
        if approachCost >= infinite or carryCostOf[j] >= infinite: continue
        let candidate = currentCost + approachCost + carryCostOf[j]
        let stateIndex = (mask or (1 shl j)) * parcelCount + j
        if candidate < bestCost[stateIndex]:
          bestCost[stateIndex] = candidate
  let fullMask = stateCount - 1
  var answer = infinite
  for i in 0..<parcelCount:
    let returnCost = distTable[parcelTarget[i]][homeCity]
    if returnCost >= infinite: continue
    let candidate = bestCost[fullMask * parcelCount + i] + returnCost
    if candidate < answer:
      answer = candidate
  appendOutput($answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
