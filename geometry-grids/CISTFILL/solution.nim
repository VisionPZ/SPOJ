import strutils

const levelLimit = 1_050_000
const firstDigitValue = 48
const flushBlockBytes = 1 shl 16

var startArea: array[0..levelLimit, int64]
var endArea: array[0..levelLimit, int64]

proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ': inc i
  result = 0
  while i < inputData.len and inputData[i] >= '0':
    result = result * 10 + (int(inputData[i]) - firstDigitValue)
    inc i

proc readStreamBytes(): string =
  var res = ""
  var chunk = newString(1 shl 16)
  while true:
    let got = readBuffer(stdin, addr chunk[0], chunk.len)
    if got <= 0:
      break
    let oldLen = res.len
    res.setLen(oldLen + got)
    copyMem(addr res[oldLen], addr chunk[0], got)
  return res

proc solve() =
  let inputData = readStreamBytes()
  var i = 0
  let dataSetCount = nextInt(inputData, i)
  var outputBuffer = ""
  var clearedThrough = 0
  for j in 0 ..< dataSetCount:
    for k in 0 .. clearedThrough:
      startArea[k] = 0
      endArea[k] = 0
    let cisternCount = nextInt(inputData, i)
    var highestLevel = 0
    for k in 0 ..< cisternCount:
      let baseLevel = nextInt(inputData, i)
      let cisternHeight = nextInt(inputData, i)
      let cisternWidth = nextInt(inputData, i)
      let cisternDepth = nextInt(inputData, i)
      let crossArea = int64(cisternWidth * cisternDepth)
      let topLevel = baseLevel + cisternHeight
      startArea[baseLevel] += crossArea
      endArea[topLevel] += crossArea
      if topLevel > highestLevel: highestLevel = topLevel
    clearedThrough = highestLevel
    let waterVolume = int64(nextInt(inputData, i))
    var activeArea: int64 = 0
    var filledVolume: int64 = 0
    var reachedLevel = 0.0
    var answerFound = false
    var k = 0
    while k <= highestLevel:
      activeArea += startArea[k] - endArea[k]
      if activeArea > 0:
        let neededVolume = waterVolume - filledVolume
        if neededVolume <= activeArea:
          reachedLevel = float(k * activeArea + neededVolume) / float(activeArea)
          answerFound = true
          break
        filledVolume += activeArea
      inc k
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
