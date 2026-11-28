const flushBlockBytes = 1 shl 17
const decimalPlaces = 10000
const impossibleCost = 1e100

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

proc appendRounded(value: float) =
  let scaledValue = int64(value * float(decimalPlaces) + 0.5)
  var fractionDigits = $(scaledValue mod decimalPlaces)
  while fractionDigits.len < 4:
    fractionDigits = "0" & fractionDigits
  appendOutput($(scaledValue div decimalPlaces) & "." & fractionDigits)
  outputBuffer.add '\n'

while true:
  let pizzaCount = nextInt(inputData, scanPos)
  if pizzaCount == 0:
    break
  var prices = newSeq[int](pizzaCount)
  var areas = newSeq[int](pizzaCount)
  var discountFactors = newSeq[seq[float]](pizzaCount)
  for pizzaIndex in 0 .. pizzaCount - 1:
    prices[pizzaIndex] = nextInt(inputData, scanPos)
    areas[pizzaIndex] = nextInt(inputData, scanPos)
    let couponCount = nextInt(inputData, scanPos)
    discountFactors[pizzaIndex] = newSeq[float](pizzaCount)
    for targetIndex in 0 .. pizzaCount - 1:
      discountFactors[pizzaIndex][targetIndex] = 1.0
    for couponIndex in 0 .. couponCount - 1:
      let couponTarget = nextInt(inputData, scanPos) - 1
      let discountPercent = nextInt(inputData, scanPos)
      discountFactors[pizzaIndex][couponTarget] = discountFactors[pizzaIndex][couponTarget] *
        (100.0 - float(discountPercent)) / 100.0

  let maskCount = 1 shl pizzaCount
  var factorTable = newSeq[seq[float]](maskCount)
  var areaTotals = newSeq[int](maskCount)
  for mask in 0 .. maskCount - 1:
    factorTable[mask] = newSeq[float](pizzaCount)
    if mask == 0:
      for pizzaIndex in 0 .. pizzaCount - 1:
        factorTable[mask][pizzaIndex] = 1.0
    else:
      var lowestIndex = 0
      while ((mask shr lowestIndex) and 1) == 0:
        lowestIndex += 1
      let previousMask = mask xor (1 shl lowestIndex)
      for pizzaIndex in 0 .. pizzaCount - 1:
        factorTable[mask][pizzaIndex] = factorTable[previousMask][pizzaIndex] *
          discountFactors[lowestIndex][pizzaIndex]
      areaTotals[mask] = areaTotals[previousMask] + areas[lowestIndex]

  var minimumCosts = newSeq[float](maskCount)
  for mask in 0 .. maskCount - 1:
    minimumCosts[mask] = impossibleCost
  minimumCosts[0] = 0.0
  for mask in 0 .. maskCount - 1:
    if minimumCosts[mask] >= impossibleCost:
      continue
    for pizzaIndex in 0 .. pizzaCount - 1:
      let pizzaBit = 1 shl pizzaIndex
      if (mask and pizzaBit) != 0:
        continue
      let nextMask = mask or pizzaBit
      let nextCost = minimumCosts[mask] + float(prices[pizzaIndex]) * factorTable[mask][pizzaIndex]
      if nextCost < minimumCosts[nextMask]:
        minimumCosts[nextMask] = nextCost

  var bestRatio = impossibleCost
  for mask in 1 .. maskCount - 1:
    let currentRatio = minimumCosts[mask] / float(areaTotals[mask])
    if currentRatio < bestRatio:
      bestRatio = currentRatio
  appendRounded(bestRatio)

stdout.write outputBuffer
outputBuffer.setLen 0
