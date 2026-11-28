const flushBlockBytes = 1 shl 17
const bigBase = 1000000000

type BigNumber = seq[int]

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

proc hasDigits(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len:
    if data[cursor] >= '0' and data[cursor] <= '9':
      return true
    cursor += 1
  return false

proc bigFromSmall(value: int): BigNumber =
  if value == 0:
    return @[0]
  return @[value]

proc bigAdd(left: BigNumber, right: BigNumber): BigNumber =
  result = newSeq[int](max(left.len, right.len))
  var carry = 0
  for chunkIndex in 0 ..< result.len:
    var total = carry
    if chunkIndex < left.len:
      total += left[chunkIndex]
    if chunkIndex < right.len:
      total += right[chunkIndex]
    result[chunkIndex] = total mod bigBase
    carry = total div bigBase
  if carry > 0:
    result.add carry
  return result

proc bigMultiply(left: BigNumber, right: BigNumber): BigNumber =
  result = newSeq[int](left.len + right.len)
  for leftIndex in 0 ..< left.len:
    var carry = 0
    for rightIndex in 0 ..< right.len:
      let cellIndex = leftIndex + rightIndex
      let current = result[cellIndex] + left[leftIndex] * right[rightIndex] + carry
      result[cellIndex] = current mod bigBase
      carry = current div bigBase
    var carryIndex = leftIndex + right.len
    while carry > 0:
      let current = result[carryIndex] + carry
      result[carryIndex] = current mod bigBase
      carry = current div bigBase
      carryIndex += 1
  while result.len > 0 and result[result.len - 1] == 0:
    result.setLen(result.len - 1)
  return result

proc bigToDecimal(value: BigNumber): string =
  var work = value
  var chunks: seq[int] = @[]
  while work.len > 0:
    var remainder = 0
    var quotient = newSeq[int](work.len)
    for chunkIndex in countdown(work.len - 1, 0):
      let current = remainder * bigBase + work[chunkIndex]
      quotient[chunkIndex] = current div bigBase
      remainder = current mod bigBase
    chunks.add remainder
    while quotient.len > 0 and quotient[quotient.len - 1] == 0:
      quotient.setLen(quotient.len - 1)
    work = quotient
  result = ""
  for chunkIndex in countdown(chunks.len - 1, 0):
    if chunkIndex == chunks.len - 1:
      result.add $(chunks[chunkIndex])
    else:
      var part = $(chunks[chunkIndex])
      while part.len < 9:
        part = "0" & part
      result.add part
  return result

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while hasDigits(inputData, scanPos):
  let clerkCount = nextInt(inputData, scanPos)
  var childrenHead = newSeq[int](clerkCount + 1)
  var childrenNext = newSeq[int](clerkCount + 1)
  var childClerk = newSeq[int](clerkCount + 1)
  var presentationOrder = newSeq[int](clerkCount)
  var edgeIndex = 0
  for clerkIndex in 0 .. clerkCount - 1:
    childrenHead[clerkIndex + 1] = -1
  for clerkIndex in 0 .. clerkCount - 1:
    let clerkId = nextInt(inputData, scanPos)
    let subordinateCount = nextInt(inputData, scanPos)
    presentationOrder[clerkIndex] = clerkId
    for subordinateIndex in 0 .. subordinateCount - 1:
      let subordinateId = nextInt(inputData, scanPos)
      childClerk[edgeIndex] = subordinateId
      childrenNext[edgeIndex] = childrenHead[clerkId]
      childrenHead[clerkId] = edgeIndex
      edgeIndex += 1
  var pairCount = newSeq[int](clerkCount + 1)
  var matchedCount = newSeq[int](clerkCount + 1)
  var waysFree = newSeq[BigNumber](clerkCount + 1)
  var waysMatched = newSeq[BigNumber](clerkCount + 1)
  for orderIndex in countdown(clerkCount - 1, 0):
    let clerkId = presentationOrder[orderIndex]
    var childList: seq[int] = @[]
    var edgeCursor = childrenHead[clerkId]
    while edgeCursor != -1:
      childList.add childClerk[edgeCursor]
      edgeCursor = childrenNext[edgeCursor]
    let childTotal = childList.len
    var prefixProducts = newSeq[BigNumber](childTotal + 1)
    var suffixProducts = newSeq[BigNumber](childTotal + 1)
    prefixProducts[0] = bigFromSmall(1)
    suffixProducts[childTotal] = bigFromSmall(1)
    var basePairs = 0
    for childIndex in 0 .. childTotal - 1:
      let childId = childList[childIndex]
      basePairs += pairCount[childId]
      prefixProducts[childIndex + 1] = bigMultiply(prefixProducts[childIndex], waysFree[childId])
    for childIndex in countdown(childTotal - 1, 0):
      let childId = childList[childIndex]
      suffixProducts[childIndex] = bigMultiply(waysFree[childId], suffixProducts[childIndex + 1])
    matchedCount[clerkId] = basePairs
    waysMatched[clerkId] = prefixProducts[childTotal]
    var bestPairs = basePairs
    var bestWays = prefixProducts[childTotal]
    for childIndex in 0 .. childTotal - 1:
      let childId = childList[childIndex]
      let candidatePairs = 1 + matchedCount[childId] + basePairs - pairCount[childId]
      if candidatePairs < bestPairs:
        continue
      let candidateWays = bigMultiply(waysMatched[childId],
                                      bigMultiply(prefixProducts[childIndex],
                                                  suffixProducts[childIndex + 1]))
      if candidatePairs > bestPairs:
        bestPairs = candidatePairs
        bestWays = candidateWays
      else:
        bestWays = bigAdd(bestWays, candidateWays)
    pairCount[clerkId] = bestPairs
    waysFree[clerkId] = bestWays
  appendOutput($pairCount[1])
  outputBuffer.add '\n'
  appendOutput(bigToDecimal(waysFree[1]))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
