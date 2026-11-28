const firstDigitValue = 48
const flushBlockBytes = 1 shl 16

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value

proc scanViaCity(distanceData: seq[int], baseCost, leftOffset, midOffset,
                 lowCity, highCity: int, shortcutFlags: var seq[bool]): bool =
  for rightCity in lowCity..<highCity:
    let targetCost = distanceData[leftOffset + rightCity]
    let viaCost = baseCost + distanceData[midOffset + rightCity]
    if viaCost < targetCost: return false
    if viaCost == targetCost: shortcutFlags[rightCity] = true
  return true

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let flyerCount = nextInt(inputData, scanPos)
var outputBuffer = ""
var distanceData: seq[int]
var shortcutFlags: seq[bool]

for flyerIndex in 0..<flyerCount:
  let cityCount = nextInt(inputData, scanPos)
  let lineCount = nextInt(inputData, scanPos)
  let pairCount = cityCount * (cityCount - 1) div 2
  distanceData.setLen(cityCount * cityCount)
  var isForgery = false
  for leftCity in 0..<cityCount:
    let leftOffset = leftCity * cityCount
    distanceData[leftOffset + leftCity] = 0
    for rightCity in leftCity+1..<cityCount:
      let advertisedCost = nextInt(inputData, scanPos)
      if advertisedCost <= 0: isForgery = true
      distanceData[leftOffset + rightCity] = advertisedCost
      distanceData[rightCity * cityCount + leftCity] = advertisedCost
  if isForgery or lineCount > pairCount:
    outputBuffer.add "NO\n"
    if outputBuffer.len >= flushBlockBytes:
      stdout.write outputBuffer
      outputBuffer.setLen 0
    continue
  shortcutFlags.setLen(cityCount)
  var essentialCount = 0
  block evaluation:
    for leftCity in 0..<cityCount:
      for rightCity in leftCity+1..<cityCount:
        shortcutFlags[rightCity] = false
      let leftOffset = leftCity * cityCount
      for midCity in 0..<cityCount:
        if midCity == leftCity: continue
        let baseCost = distanceData[leftOffset + midCity]
        let midOffset = midCity * cityCount
        if midCity < leftCity:
          if not scanViaCity(distanceData, baseCost, leftOffset, midOffset,
                             leftCity+1, cityCount, shortcutFlags):
            isForgery = true
            break evaluation
        else:
          if not scanViaCity(distanceData, baseCost, leftOffset, midOffset,
                             leftCity+1, midCity, shortcutFlags):
            isForgery = true
            break evaluation
          if not scanViaCity(distanceData, baseCost, leftOffset, midOffset,
                             midCity+1, cityCount, shortcutFlags):
            isForgery = true
            break evaluation
      if not isForgery:
        for rightCity in leftCity+1..<cityCount:
          if not shortcutFlags[rightCity]: essentialCount += 1
        if essentialCount > lineCount: break evaluation
  if isForgery or essentialCount > lineCount:
    outputBuffer.add "NO\n"
  else:
    outputBuffer.add "YES\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
