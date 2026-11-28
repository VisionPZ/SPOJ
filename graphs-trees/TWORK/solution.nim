{.define: release.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const variantCount = 16
const bucketCount = 5

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var rngState: uint32 = 2463534242'u32

proc nextRandom(): uint32 =
  rngState = rngState xor (rngState shl 13'u32)
  rngState = rngState xor (rngState shr 17'u32)
  rngState = rngState xor (rngState shl 5'u32)
  return rngState

proc pickBetter(candidate: int, current: int, degrees: seq[int], preferMax: bool,
                reverseTie: bool): bool =
  if preferMax:
    if degrees[candidate] > degrees[current]: return true
    if degrees[candidate] < degrees[current]: return false
  else:
    if degrees[candidate] < degrees[current]: return true
    if degrees[candidate] > degrees[current]: return false
  if reverseTie:
    return candidate > current
  return candidate < current

proc centerScore(scientist: int, edgeHead: seq[int], edgeTo: seq[int],
                 edgeLink: seq[int], available: seq[bool],
                 remainingDegree: seq[int]): int =
  var smallest = 4
  var second = 4
  var neighborTotal = 0
  var edgeIndex = edgeHead[scientist]
  while edgeIndex != -1:
    let neighbor = edgeTo[edgeIndex]
    if available[neighbor]:
      let value = remainingDegree[neighbor]
      if value < smallest:
        second = smallest
        smallest = value
      elif value < second:
        second = value
      neighborTotal += 1
    edgeIndex = edgeLink[edgeIndex]
  if neighborTotal < 2:
    return -1
  let score = smallest + second
  if score < 2:
    return 2
  if score > 6:
    return 6
  return score

proc pushBucket(slot: int, scientist: int, capacity: int, store: var seq[int],
                lengths: var array[bucketCount, int]) =
  store[slot * capacity + lengths[slot]] = scientist
  lengths[slot] += 1

proc runPacking(variant: int, caseIndex: int, scientistCount: int,
                edgeHead: seq[int], edgeTo: seq[int], edgeLink: seq[int],
                baseDegree: seq[int], available: var seq[bool],
                remainingDegree: var seq[int], stack: var seq[int],
                stackLength: var int, bucketStore: var seq[int],
                bucketLengths: var array[bucketCount, int], bucketCapacity: int,
                groupLeft: var seq[int], groupCenter: var seq[int],
                groupRight: var seq[int]): int =
  var index = 0
  while index < scientistCount:
    available[index] = true
    remainingDegree[index] = baseDegree[index]
    index += 1

  let bucketMode = variant >= 12
  let preferMax = (variant mod 2) == 1
  let reverseTie = (variant div 4) mod 2 == 1
  let useRandom = variant >= 8 and variant < 12
  var groupCount = 0

  if bucketMode:
    index = 0
    while index < bucketCount:
      bucketLengths[index] = 0
      index += 1
    if (variant div 2) mod 2 == 0:
      index = 0
      while index < scientistCount:
        let score = centerScore(index, edgeHead, edgeTo, edgeLink,
                                available, remainingDegree)
        if score >= 2:
          pushBucket(score - 2, index, bucketCapacity, bucketStore, bucketLengths)
        index += 1
    else:
      index = scientistCount - 1
      while index >= 0:
        let score = centerScore(index, edgeHead, edgeTo, edgeLink,
                                available, remainingDegree)
        if score >= 2:
          pushBucket(score - 2, index, bucketCapacity, bucketStore, bucketLengths)
        index -= 1
  else:
    stackLength = 0
    if useRandom:
      rngState = uint32(362437 + variant * 7919 + caseIndex * 104729 + 1)
      index = 0
      while index < scientistCount:
        stack[stackLength] = index
        stackLength += 1
        index += 1
      index = scientistCount - 1
      while index > 0:
        let swapIndex = int(nextRandom() mod uint32(index + 1))
        let held = stack[index]
        stack[index] = stack[swapIndex]
        stack[swapIndex] = held
        index -= 1
    elif (variant div 2) mod 2 == 0:
      index = 0
      while index < scientistCount:
        stack[stackLength] = index
        stackLength += 1
        index += 1
    else:
      index = scientistCount - 1
      while index >= 0:
        stack[stackLength] = index
        stackLength += 1
        index -= 1

  while true:
    var center = -1
    if bucketMode:
      var slot = 0
      while slot < bucketCount and bucketLengths[slot] == 0:
        slot += 1
      if slot == bucketCount:
        break
      bucketLengths[slot] -= 1
      let candidate = bucketStore[slot * bucketCapacity + bucketLengths[slot]]
      if not available[candidate]:
        continue
      let score = centerScore(candidate, edgeHead, edgeTo, edgeLink,
                              available, remainingDegree)
      if score == -1:
        continue
      if score != slot + 2:
        pushBucket(score - 2, candidate, bucketCapacity,
                   bucketStore, bucketLengths)
        continue
      center = candidate
    else:
      if stackLength == 0:
        break
      stackLength -= 1
      let candidate = stack[stackLength]
      if not available[candidate] or remainingDegree[candidate] < 2:
        continue
      center = candidate

    var neighborBuf: array[3, int]
    var neighborCount = 0
    var edgeIndex = edgeHead[center]
    while edgeIndex != -1:
      let neighbor = edgeTo[edgeIndex]
      if available[neighbor]:
        neighborBuf[neighborCount] = neighbor
        neighborCount += 1
      edgeIndex = edgeLink[edgeIndex]
    if neighborCount < 2:
      continue

    var left: int
    var right: int
    if useRandom:
      let firstSlot = int(nextRandom() mod uint32(neighborCount))
      var secondSlot = int(nextRandom() mod uint32(neighborCount - 1))
      if secondSlot >= firstSlot:
        secondSlot += 1
      left = neighborBuf[firstSlot]
      right = neighborBuf[secondSlot]
    else:
      var firstSlot = 0
      var slot = 1
      while slot < neighborCount:
        if pickBetter(neighborBuf[slot], neighborBuf[firstSlot],
                      remainingDegree, preferMax, reverseTie):
          firstSlot = slot
        slot += 1
      var secondSlot = -1
      slot = 0
      while slot < neighborCount:
        if slot != firstSlot and (secondSlot == -1 or
            pickBetter(neighborBuf[slot], neighborBuf[secondSlot],
                       remainingDegree, preferMax, reverseTie)):
          secondSlot = slot
        slot += 1
      left = neighborBuf[firstSlot]
      right = neighborBuf[secondSlot]

    groupLeft[groupCount] = left
    groupCenter[groupCount] = center
    groupRight[groupCount] = right
    groupCount += 1

    available[center] = false
    available[left] = false
    available[right] = false

    var removedIndex = 0
    while removedIndex < 3:
      var removed: int
      case removedIndex
      of 0:
        removed = center
      of 1:
        removed = left
      else:
        removed = right
      var linkIndex = edgeHead[removed]
      while linkIndex != -1:
        let neighbor = edgeTo[linkIndex]
        if available[neighbor]:
          remainingDegree[neighbor] -= 1
          if bucketMode:
            let score = centerScore(neighbor, edgeHead, edgeTo, edgeLink,
                                    available, remainingDegree)
            if score >= 2:
              pushBucket(score - 2, neighbor, bucketCapacity,
                         bucketStore, bucketLengths)
          elif remainingDegree[neighbor] >= 2:
            stack[stackLength] = neighbor
            stackLength += 1
        linkIndex = edgeLink[linkIndex]
      removedIndex += 1

  return groupCount

let caseCount = nextInt(inputData, scanPos)
var caseIndex = 0
while caseIndex < caseCount:
  let scientistCount = nextInt(inputData, scanPos)
  let relationCount = nextInt(inputData, scanPos)

  var edgeHead = newSeq[int](scientistCount)
  var edgeTo = newSeq[int](relationCount * 2)
  var edgeLink = newSeq[int](relationCount * 2)
  var baseDegree = newSeq[int](scientistCount)
  var edgeCursor = 0
  var index = 0
  while index < scientistCount:
    edgeHead[index] = -1
    index += 1
  index = 0
  while index < relationCount:
    let firstScientist = nextInt(inputData, scanPos) - 1
    let secondScientist = nextInt(inputData, scanPos) - 1
    edgeTo[edgeCursor] = secondScientist
    edgeLink[edgeCursor] = edgeHead[firstScientist]
    edgeHead[firstScientist] = edgeCursor
    edgeCursor += 1
    edgeTo[edgeCursor] = firstScientist
    edgeLink[edgeCursor] = edgeHead[secondScientist]
    edgeHead[secondScientist] = edgeCursor
    edgeCursor += 1
    baseDegree[firstScientist] += 1
    baseDegree[secondScientist] += 1
    index += 1

  var available = newSeq[bool](scientistCount)
  var remainingDegree = newSeq[int](scientistCount)
  var stack = newSeq[int](scientistCount * 4 + 8)
  var stackLength = 0
  let bucketCapacity = scientistCount * 8 + 16
  var bucketStore = newSeq[int](bucketCapacity * bucketCount)
  var bucketLengths: array[bucketCount, int]
  let groupCapacity = scientistCount div 3
  var trialLeft = newSeq[int](groupCapacity)
  var trialCenter = newSeq[int](groupCapacity)
  var trialRight = newSeq[int](groupCapacity)
  var bestLeft = newSeq[int](groupCapacity)
  var bestCenter = newSeq[int](groupCapacity)
  var bestRight = newSeq[int](groupCapacity)
  var bestCount = 0

  var variant = 0
  while variant < variantCount:
    let found = runPacking(variant, caseIndex, scientistCount, edgeHead, edgeTo,
                           edgeLink, baseDegree, available, remainingDegree,
                           stack, stackLength, bucketStore, bucketLengths,
                           bucketCapacity, trialLeft, trialCenter, trialRight)
    if found > bestCount:
      bestCount = found
      index = 0
      while index < found:
        bestLeft[index] = trialLeft[index]
        bestCenter[index] = trialCenter[index]
        bestRight[index] = trialRight[index]
        index += 1
    variant += 1

  appendOutput($(bestCount))
  outputBuffer.add '\n'
  index = 0
  while index < bestCount:
    appendOutput($(bestLeft[index] + 1))
    outputBuffer.add ' '
    appendOutput($(bestCenter[index] + 1))
    outputBuffer.add ' '
    appendOutput($(bestRight[index] + 1))
    outputBuffer.add '\n'
    index += 1
  caseIndex += 1

stdout.write outputBuffer
outputBuffer.setLen 0
