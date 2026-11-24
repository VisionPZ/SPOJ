const
  spaceCode = 32
  firstDigitCode = 48
  flushBlockBytes = 1 shl 18
  maxBlockTypes = 30
  orientationsPerType = 3
  maxOrientations = maxBlockTypes * orientationsPerType

var
  inputData = ""
  i = 0
  outputBuffer = ""
  baseLarge: array[maxOrientations, int]
  baseSmall: array[maxOrientations, int]
  blockHeight: array[maxOrientations, int]
  towerHeight: array[maxOrientations, int]

proc loadInput() =
  var lineContents = ""
  while readLine(stdin, lineContents):
    inputData.add lineContents
    inputData.add '\n'

proc skipWhitespace() =
  while i < inputData.len and ord(inputData[i]) <= spaceCode:
    inc i

proc readInteger(): int =
  skipWhitespace()
  result = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    result = result * 10 + (ord(inputData[i]) - firstDigitCode)
    inc i

proc buildOrientations(blockTypeCount: int) =
  var orientationCount = 0
  for i in 0 ..< blockTypeCount:
    let givenHeight = readInteger()
    let givenWidth = readInteger()
    let givenDepth = readInteger()
    baseLarge[orientationCount] = max(givenWidth, givenDepth)
    baseSmall[orientationCount] = min(givenWidth, givenDepth)
    blockHeight[orientationCount] = givenHeight
    inc orientationCount
    baseLarge[orientationCount] = max(givenHeight, givenDepth)
    baseSmall[orientationCount] = min(givenHeight, givenDepth)
    blockHeight[orientationCount] = givenWidth
    inc orientationCount
    baseLarge[orientationCount] = max(givenHeight, givenWidth)
    baseSmall[orientationCount] = min(givenHeight, givenWidth)
    blockHeight[orientationCount] = givenDepth
    inc orientationCount

proc sortOrientations(orientationCount: int) =
  for i in 1 ..< orientationCount:
    var j = i
    while j > 0:
      let k = j - 1
      let outOfOrder = baseLarge[k] < baseLarge[j] or
                       (baseLarge[k] == baseLarge[j] and baseSmall[k] < baseSmall[j])
      if not outOfOrder: break
      let largeValue = baseLarge[j]
      let smallValue = baseSmall[j]
      let heightValue = blockHeight[j]
      baseLarge[j] = baseLarge[k]
      baseSmall[j] = baseSmall[k]
      blockHeight[j] = blockHeight[k]
      baseLarge[k] = largeValue
      baseSmall[k] = smallValue
      blockHeight[k] = heightValue
      dec j

proc tallestTower(orientationCount: int): int =
  var bestTower = 0
  for i in 0 ..< orientationCount:
    var bestBelow = 0
    for j in 0 ..< i:
      if baseLarge[j] > baseLarge[i] and baseSmall[j] > baseSmall[i]:
        if towerHeight[j] > bestBelow:
          bestBelow = towerHeight[j]
    towerHeight[i] = blockHeight[i] + bestBelow
    if towerHeight[i] > bestTower:
      bestTower = towerHeight[i]
  result = bestTower

proc flushOutput(forceAll: bool) =
  if forceAll or outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

loadInput()
while true:
  skipWhitespace()
  if i >= inputData.len: break
  let blockTypeCount = readInteger()
  if blockTypeCount == 0: break
  let orientationCount = blockTypeCount * orientationsPerType
  buildOrientations(blockTypeCount)
  sortOrientations(orientationCount)
  outputBuffer.add $tallestTower(orientationCount)
  outputBuffer.add '\n'
  flushOutput(false)
flushOutput(true)
