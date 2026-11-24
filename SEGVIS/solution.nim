const
  maxCoordinate = 8000
  doubledLimit = 2 * maxCoordinate
  doubledPointCount = doubledLimit + 1
  treeEntryCount = 4 * doubledPointCount
  flushBlockBytes = 1 shl 18
  zeroCharacter = '0'
  digitBase = 48
  bitsPerWord = 64
  wordShift = 6
  wordMask = 63

var
  inputData = ""
  i = 0
  outputBuffer = ""
  segmentLow: seq[int]
  segmentHigh: seq[int]
  segmentX: seq[int]
  visitOrder: seq[int]
  xCounts: array[0..maxCoordinate, int]
  coverTree: seq[int]
  seenStamp: seq[int]
  adjacency: seq[uint64]
  currentStamp = 0
  wordCount = 0

proc loadInput() =
  var oneLine = ""
  while readLine(stdin, oneLine):
    inputData.add oneLine
    inputData.add '\n'

proc nextInteger(): int =
  var numberValue = 0
  while i < inputData.len and inputData[i] < zeroCharacter:
    inc i
  while i < inputData.len and inputData[i] >= zeroCharacter:
    numberValue = numberValue * 10 + int(inputData[i]) - digitBase
    inc i
  result = numberValue

proc appendResult(answerValue: int64) =
  outputBuffer.add $answerValue
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc countSetBits(value: uint64): int =
  var mixed = value
  mixed = mixed - ((mixed shr 1) and 0x5555555555555555'u64)
  mixed = (mixed and 0x3333333333333333'u64) + ((mixed shr 2) and 0x3333333333333333'u64)
  mixed = (mixed + (mixed shr 4)) and 0x0f0f0f0f0f0f0f0f'u64
  result = int((mixed * 0x0101010101010101'u64) shr 56)

proc countTrailingZeros(value: uint64): int =
  var shifted = value
  if shifted == 0'u64:
    return bitsPerWord
  result = 0
  if (shifted and 0xffffffff'u64) == 0'u64:
    shifted = shifted shr 32
    result += 32
  if (shifted and 0xffff'u64) == 0'u64:
    shifted = shifted shr 16
    result += 16
  if (shifted and 0xff'u64) == 0'u64:
    shifted = shifted shr 8
    result += 8
  if (shifted and 0xf'u64) == 0'u64:
    shifted = shifted shr 4
    result += 4
  if (shifted and 0x3'u64) == 0'u64:
    shifted = shifted shr 2
    result += 2
  if (shifted and 0x1'u64) == 0'u64:
    result += 1

proc assignCover(i: int, leftBound: int, rightBound: int,
                 queryLeft: int, queryRight: int, coverValue: int) =
  if queryLeft <= leftBound and rightBound <= queryRight:
    coverTree[i] = coverValue
    return
  if coverTree[i] >= 0:
    coverTree[i * 2] = coverTree[i]
    coverTree[i * 2 + 1] = coverTree[i]
    coverTree[i] = -1
  let middle = (leftBound + rightBound) div 2
  if queryLeft <= middle:
    assignCover(i * 2, leftBound, middle, queryLeft, queryRight, coverValue)
  if queryRight > middle:
    assignCover(i * 2 + 1, middle + 1, rightBound, queryLeft, queryRight, coverValue)
  if coverTree[i * 2] == coverTree[i * 2 + 1]:
    coverTree[i] = coverTree[i * 2]
  else:
    coverTree[i] = -1

proc collectCovers(i: int, leftBound: int, rightBound: int,
                   queryLeft: int, queryRight: int, collected: var seq[int]) =
  if rightBound < queryLeft or leftBound > queryRight:
    return
  let nodeCover = coverTree[i]
  if nodeCover >= 0:
    if nodeCover > 0:
      collected.add nodeCover
    return
  if leftBound == rightBound:
    return
  let middle = (leftBound + rightBound) div 2
  collectCovers(i * 2, leftBound, middle, queryLeft, queryRight, collected)
  collectCovers(i * 2 + 1, middle + 1, rightBound, queryLeft, queryRight, collected)

proc addEdge(firstId: int, secondId: int) =
  let i = firstId * wordCount + (secondId shr wordShift)
  adjacency[i] = adjacency[i] or (1'u64 shl (secondId and wordMask))

proc solveDataset(segmentCount: int): int64 =
  wordCount = (segmentCount + wordMask) div bitsPerWord
  adjacency = newSeq[uint64](segmentCount * wordCount)
  for i in 0..maxCoordinate:
    xCounts[i] = 0
  for segmentId in 0..<segmentCount:
    inc xCounts[segmentX[segmentId]]
  var j = 0
  for i in 0..maxCoordinate:
    let bucketSize = xCounts[i]
    xCounts[i] = j
    j += bucketSize
  for segmentId in 0..<segmentCount:
    let i = segmentX[segmentId]
    visitOrder[xCounts[i]] = segmentId
    inc xCounts[i]
  for i in 0..<treeEntryCount:
    coverTree[i] = 0
  for segmentId in 0..<segmentCount:
    seenStamp[segmentId] = 0
  currentStamp = 0
  var collected: seq[int] = @[]
  for i in 0..<segmentCount:
    let currentId = visitOrder[i]
    inc currentStamp
    collected.setLen 0
    let lowPosition = 2 * segmentLow[currentId]
    let highPosition = 2 * segmentHigh[currentId]
    collectCovers(1, 0, doubledLimit, lowPosition, highPosition, collected)
    for coverValue in collected:
      let previousId = coverValue - 1
      if seenStamp[previousId] != currentStamp:
        seenStamp[previousId] = currentStamp
        addEdge(previousId, currentId)
        addEdge(currentId, previousId)
    assignCover(1, 0, doubledLimit, lowPosition, highPosition, currentId + 1)
  var triangleSum = 0'i64
  for fromId in 0..<segmentCount:
    let fromBase = fromId * wordCount
    for i in 0..<wordCount:
      var remainingBits = adjacency[fromBase + i]
      while remainingBits != 0'u64:
        let lowestBit = remainingBits and (0'u64 - remainingBits)
        let toId = i * bitsPerWord + countTrailingZeros(lowestBit)
        remainingBits = remainingBits xor lowestBit
        if toId > fromId:
          let toBase = toId * wordCount
          var sharedCount = 0
          for j in 0..<wordCount:
            sharedCount += countSetBits(adjacency[fromBase + j] and
                                        adjacency[toBase + j])
          triangleSum += int64(sharedCount)
  result = triangleSum div 3'i64

proc main() =
  loadInput()
  let datasetCount = nextInteger()
  segmentLow = newSeq[int](maxCoordinate)
  segmentHigh = newSeq[int](maxCoordinate)
  segmentX = newSeq[int](maxCoordinate)
  visitOrder = newSeq[int](maxCoordinate)
  seenStamp = newSeq[int](maxCoordinate)
  coverTree = newSeq[int](treeEntryCount)
  for j in 0..<datasetCount:
    let segmentCount = nextInteger()
    for segmentId in 0..<segmentCount:
      segmentLow[segmentId] = nextInteger()
      segmentHigh[segmentId] = nextInteger()
      segmentX[segmentId] = nextInteger()
    appendResult(solveDataset(segmentCount))
  if outputBuffer.len > 0:
    stdout.write outputBuffer
    outputBuffer.setLen 0

main()
