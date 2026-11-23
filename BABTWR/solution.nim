const
  spaceCode = 32
  firstDigitCode = 48
  flushBlockBytes = 1 shl 18
  maxBlockTypes = 30
  orientationsPerType = 3
  maxOrientations = maxBlockTypes * orientationsPerType

var
  inputData = ""
  inputPosition = 0
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
  while inputPosition < inputData.len and ord(inputData[inputPosition]) <= spaceCode:
    inc inputPosition

proc readInteger(): int =
  skipWhitespace()
  result = 0
  while inputPosition < inputData.len and inputData[inputPosition] >= '0' and inputData[inputPosition] <= '9':
    result = result * 10 + (ord(inputData[inputPosition]) - firstDigitCode)
    inc inputPosition

proc buildOrientations(blockTypeCount: int) =
  var orientationCount = 0
  for typeIndex in 0 ..< blockTypeCount:
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
  for sortIndex in 1 ..< orientationCount:
    var cursor = sortIndex
    while cursor > 0:
      let previousIndex = cursor - 1
      let outOfOrder = baseLarge[previousIndex] < baseLarge[cursor] or
                       (baseLarge[previousIndex] == baseLarge[cursor] and baseSmall[previousIndex] < baseSmall[cursor])
      if not outOfOrder: break
      let largeValue = baseLarge[cursor]
      let smallValue = baseSmall[cursor]
      let heightValue = blockHeight[cursor]
      baseLarge[cursor] = baseLarge[previousIndex]
      baseSmall[cursor] = baseSmall[previousIndex]
      blockHeight[cursor] = blockHeight[previousIndex]
      baseLarge[previousIndex] = largeValue
      baseSmall[previousIndex] = smallValue
      blockHeight[previousIndex] = heightValue
      dec cursor

proc tallestTower(orientationCount: int): int =
  var bestTower = 0
  for topIndex in 0 ..< orientationCount:
    var bestBelow = 0
    for belowIndex in 0 ..< topIndex:
      if baseLarge[belowIndex] > baseLarge[topIndex] and baseSmall[belowIndex] > baseSmall[topIndex]:
        if towerHeight[belowIndex] > bestBelow:
          bestBelow = towerHeight[belowIndex]
    towerHeight[topIndex] = blockHeight[topIndex] + bestBelow
    if towerHeight[topIndex] > bestTower:
      bestTower = towerHeight[topIndex]
  result = bestTower

proc flushOutput(forceAll: bool) =
  if forceAll or outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

loadInput()
while true:
  skipWhitespace()
  if inputPosition >= inputData.len: break
  let blockTypeCount = readInteger()
  if blockTypeCount == 0: break
  let orientationCount = blockTypeCount * orientationsPerType
  buildOrientations(blockTypeCount)
  sortOrientations(orientationCount)
  outputBuffer.add $tallestTower(orientationCount)
  outputBuffer.add '\n'
  flushOutput(false)
flushOutput(true)
