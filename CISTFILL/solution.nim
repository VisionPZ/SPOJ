import strutils

const levelLimit = 1_050_000
const firstDigitValue = 48
const flushBlockBytes = 1 shl 16

var startArea: array[0..levelLimit, int64]
var endArea: array[0..levelLimit, int64]

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ': inc scanPos
  result = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0':
    result = result * 10 + (int(inputData[scanPos]) - firstDigitValue)
    inc scanPos

proc solve() =
  let inputData = stdin.readAll()
  var scanPos = 0
  let dataSetCount = nextInt(inputData, scanPos)
  var outputBuffer = ""
  var clearedThrough = 0
  for dataSetIndex in 0 ..< dataSetCount:
    for levelIndex in 0 .. clearedThrough:
      startArea[levelIndex] = 0
      endArea[levelIndex] = 0
    let cisternCount = nextInt(inputData, scanPos)
    var highestLevel = 0
    for cisternIndex in 0 ..< cisternCount:
      let baseLevel = nextInt(inputData, scanPos)
      let cisternHeight = nextInt(inputData, scanPos)
      let cisternWidth = nextInt(inputData, scanPos)
      let cisternDepth = nextInt(inputData, scanPos)
      let crossArea = int64(cisternWidth * cisternDepth)
      let topLevel = baseLevel + cisternHeight
      startArea[baseLevel] += crossArea
      endArea[topLevel] += crossArea
      if topLevel > highestLevel: highestLevel = topLevel
    clearedThrough = highestLevel
    let waterVolume = int64(nextInt(inputData, scanPos))
    var activeArea: int64 = 0
    var filledVolume: int64 = 0
    var reachedLevel = 0.0
    var answerFound = false
    var levelIndex = 0
    while levelIndex <= highestLevel:
      activeArea += startArea[levelIndex] - endArea[levelIndex]
      if activeArea > 0:
        let neededVolume = waterVolume - filledVolume
        if neededVolume <= activeArea:
          reachedLevel = float(levelIndex * activeArea + neededVolume) / float(activeArea)
          answerFound = true
          break
        filledVolume += activeArea
      inc levelIndex
    if answerFound:
      outputBuffer.add(formatFloat(reachedLevel, ffDecimal, 2))
    else:
      outputBuffer.add("OVERFLOW")
    outputBuffer.add('\n')
    if outputBuffer.len >= flushBlockBytes:
      stdout.write(outputBuffer)
      outputBuffer.setLen(0)
  stdout.write(outputBuffer)

solve()
