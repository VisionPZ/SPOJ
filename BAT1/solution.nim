const flushBlockBytes = 1 shl 17
const unreachableValue = -1

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
for caseNumber in 1 .. caseCount:
  let batchCount = nextInt(inputData, scanPos)
  let weaponKinds = nextInt(inputData, scanPos)
  let budget = nextInt(inputData, scanPos)
  let totalWeaponKinds = batchCount * weaponKinds
  var openCosts = newSeq[int](batchCount)
  for batchIndex in 0 ..< batchCount:
    openCosts[batchIndex] = nextInt(inputData, scanPos)
  var weaponCosts = newSeq[int](totalWeaponKinds)
  for weaponIndex in 0 ..< totalWeaponKinds:
    weaponCosts[weaponIndex] = nextInt(inputData, scanPos)
  var weaponRatings = newSeq[int](totalWeaponKinds)
  for weaponIndex in 0 ..< totalWeaponKinds:
    weaponRatings[weaponIndex] = nextInt(inputData, scanPos)
  var bestBySpent = newSeq[int](budget + 1)
  for spent in 0 .. budget:
    bestBySpent[spent] = unreachableValue
  bestBySpent[0] = 0
  for batchIndex in 0 ..< batchCount:
    var openedBatch = newSeq[int](budget + 1)
    for spent in 0 .. budget:
      openedBatch[spent] = unreachableValue
    let openingPrice = openCosts[batchIndex]
    if openingPrice <= budget:
      for spent in 0 .. budget - openingPrice:
        if bestBySpent[spent] >= 0:
          let targetSpent = spent + openingPrice
          if openedBatch[targetSpent] < bestBySpent[spent]:
            openedBatch[targetSpent] = bestBySpent[spent]
    for weaponIndex in 0 ..< weaponKinds:
      let flatIndex = batchIndex * weaponKinds + weaponIndex
      let weaponPrice = weaponCosts[flatIndex]
      let weaponPower = weaponRatings[flatIndex]
      if weaponPrice <= 0 or weaponPrice > budget:
        continue
      for spent in weaponPrice .. budget:
        if openedBatch[spent - weaponPrice] >= 0:
          let candidate = openedBatch[spent - weaponPrice] + weaponPower
          if openedBatch[spent] < candidate:
            openedBatch[spent] = candidate
    for spent in 0 .. budget:
      if openedBatch[spent] > bestBySpent[spent]:
        bestBySpent[spent] = openedBatch[spent]
  var bestRating = 0
  for spent in 0 .. budget:
    if bestBySpent[spent] > bestRating:
      bestRating = bestBySpent[spent]
  appendOutput($bestRating)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
