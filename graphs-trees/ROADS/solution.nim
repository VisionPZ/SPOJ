const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const unreachableLength = 1 shl 60

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

for _ in 0..<caseCount:
  let budget = nextInt(inputData, scanPos)
  let cityCount = nextInt(inputData, scanPos)
  let roadCount = nextInt(inputData, scanPos)
  let tollLevels = budget + 1

  var zeroHead = newSeq[int](cityCount)
  var zeroNext = newSeq[int](roadCount)
  var zeroDest = newSeq[int](roadCount)
  var zeroLength = newSeq[int](roadCount)
  var paidSource = newSeq[int](roadCount)
  var paidDest = newSeq[int](roadCount)
  var paidLength = newSeq[int](roadCount)
  var paidToll = newSeq[int](roadCount)
  var zeroCount = 0
  var paidCount = 0
  for cityIndex in 0..<cityCount:
    zeroHead[cityIndex] = -1

  for roadIndex in 0..<roadCount:
    let sourceCity = nextInt(inputData, scanPos) - 1
    let destCity = nextInt(inputData, scanPos) - 1
    let roadLength = nextInt(inputData, scanPos)
    let roadToll = nextInt(inputData, scanPos)
    if roadToll == 0:
      zeroDest[zeroCount] = destCity
      zeroLength[zeroCount] = roadLength
      zeroNext[zeroCount] = zeroHead[sourceCity]
      zeroHead[sourceCity] = zeroCount
      zeroCount += 1
    else:
      paidSource[paidCount] = sourceCity
      paidDest[paidCount] = destCity
      paidLength[paidCount] = roadLength
      paidToll[paidCount] = roadToll
      paidCount += 1

  var bestLengths = newSeq[int](cityCount * tollLevels)
  for slot in 0..<bestLengths.len:
    bestLengths[slot] = unreachableLength
  bestLengths[0] = 0

  var layerLengths = newSeq[int](cityCount)
  var settled = newSeq[bool](cityCount)

  for spentCoins in 0..budget:
    for cityIndex in 0..<cityCount:
      layerLengths[cityIndex] = bestLengths[cityIndex * tollLevels + spentCoins]
      settled[cityIndex] = false

    for _ in 0..<cityCount:
      var chosenCity = -1
      var chosenLength = unreachableLength
      for cityIndex in 0..<cityCount:
        if not settled[cityIndex] and layerLengths[cityIndex] < chosenLength:
          chosenLength = layerLengths[cityIndex]
          chosenCity = cityIndex
      if chosenCity < 0: break
      settled[chosenCity] = true
      var edgeIndex = zeroHead[chosenCity]
      while edgeIndex >= 0:
        let neighborCity = zeroDest[edgeIndex]
        let candidate = chosenLength + zeroLength[edgeIndex]
        if candidate < layerLengths[neighborCity]:
          layerLengths[neighborCity] = candidate
        edgeIndex = zeroNext[edgeIndex]

    for cityIndex in 0..<cityCount:
      bestLengths[cityIndex * tollLevels + spentCoins] = layerLengths[cityIndex]

    for roadIndex in 0..<paidCount:
      let nextCoins = spentCoins + paidToll[roadIndex]
      if nextCoins > budget: continue
      let fromSlot = paidSource[roadIndex] * tollLevels + spentCoins
      let baseLength = bestLengths[fromSlot]
      if baseLength >= unreachableLength: continue
      let toSlot = paidDest[roadIndex] * tollLevels + nextCoins
      let candidate = baseLength + paidLength[roadIndex]
      if candidate < bestLengths[toSlot]:
        bestLengths[toSlot] = candidate

  var answer = unreachableLength
  let targetBase = (cityCount - 1) * tollLevels
  for spentCoins in 0..budget:
    if bestLengths[targetBase + spentCoins] < answer:
      answer = bestLengths[targetBase + spentCoins]
  if answer >= unreachableLength:
    appendOutput("-1")
  else:
    appendOutput($answer)
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
