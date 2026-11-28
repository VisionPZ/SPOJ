const flushBlockBytes = 1 shl 17
const missingScore = -(1 shl 60)

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value

proc solveCase(values: seq[int64], targetGroups: int): int64 =
  let bulletCount = values.len
  let totalMasks = 1 shl bulletCount
  var bestScores = newSeq[seq[int64]](totalMasks)
  for maskIndex in 0 ..< totalMasks:
    bestScores[maskIndex] = newSeq[int64](targetGroups + 1)
    for groupCount in 0 .. targetGroups:
      bestScores[maskIndex][groupCount] = missingScore
  bestScores[0][0] = 0

  for maskIndex in 1 ..< totalMasks:
    var firstBit = 0
    while (maskIndex and (1 shl firstBit)) == 0:
      firstBit += 1
    let remainingMask = maskIndex and not (1 shl firstBit)
    var companion = remainingMask
    while true:
      let groupMask = companion or (1 shl firstBit)
      let leftoverMask = remainingMask and not companion
      var groupProduct: int64 = 1
      var bitIndex = 0
      while bitIndex < bulletCount:
        if (groupMask and (1 shl bitIndex)) != 0:
          groupProduct = groupProduct * values[bitIndex]
        bitIndex += 1
      for groupCount in 1 .. targetGroups:
        if bestScores[leftoverMask][groupCount - 1] == missingScore:
          continue
        let candidate = bestScores[leftoverMask][groupCount - 1] + groupProduct
        if candidate > bestScores[maskIndex][groupCount]:
          bestScores[maskIndex][groupCount] = candidate
      if companion == 0:
        break
      companion = (companion - 1) and remainingMask
  return bestScores[totalMasks - 1][targetGroups]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let bulletCount = nextInt(inputData, scanPos)
  let targetGroups = nextInt(inputData, scanPos)
  var bulletValues = newSeq[int64](bulletCount)
  for bulletIndex in 0 .. bulletCount - 1:
    bulletValues[bulletIndex] = int64(nextInt(inputData, scanPos))
  appendOutput($solveCase(bulletValues, targetGroups))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
