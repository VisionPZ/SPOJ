const flushBlockBytes = 1 shl 17
const windowSize = 5
const windowMasks = 32
const stateCount = 16
const prefixCount = 16
const unreachable = -1000000000

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

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let enclosureCount = nextInt(inputData, scanPos)
  let childCount = nextInt(inputData, scanPos)
  var happyCounts = newSeq[int]((enclosureCount + 1) * windowMasks)
  for childIndex in 0 .. childCount - 1:
    let firstEnclosure = nextInt(inputData, scanPos)
    let fearTotal = nextInt(inputData, scanPos)
    let loveTotal = nextInt(inputData, scanPos)
    var fearMask = 0
    var loveMask = 0
    for fearIndex in 0 .. fearTotal - 1:
      let fearedEnclosure = nextInt(inputData, scanPos)
      var offset = fearedEnclosure - firstEnclosure
      if offset < 0:
        offset = offset + enclosureCount
      fearMask = fearMask or (1 shl (windowSize - 1 - offset))
    for loveIndex in 0 .. loveTotal - 1:
      let lovedEnclosure = nextInt(inputData, scanPos)
      var offset = lovedEnclosure - firstEnclosure
      if offset < 0:
        offset = offset + enclosureCount
      loveMask = loveMask or (1 shl (windowSize - 1 - offset))
    for windowMask in 0 .. windowMasks - 1:
      let fearRemoved = (fearMask and windowMask) != 0
      let loveKept = (loveMask and (windowMasks - 1 xor windowMask)) != 0
      if fearRemoved or loveKept:
        happyCounts[firstEnclosure * windowMasks + windowMask] += 1
  var bestResult = -1
  for prefixMask in 0 .. prefixCount - 1:
    var currentDp = newSeq[int](stateCount)
    var nextDp = newSeq[int](stateCount)
    for state in 0 .. stateCount - 1:
      currentDp[state] = unreachable
    var initialState = 0
    for prefixIndex in 0 .. windowSize - 2:
      if (prefixMask and (1 shl prefixIndex)) != 0:
        initialState = initialState or (1 shl (windowSize - 2 - prefixIndex))
    currentDp[initialState] = 0
    for position in windowSize .. enclosureCount + windowSize - 1:
      let childStart = position - windowSize + 1
      for state in 0 .. stateCount - 1:
        nextDp[state] = unreachable
      var firstBit = 0
      var lastBit = 1
      if position > enclosureCount:
        firstBit = (prefixMask shr (position - enclosureCount - 1)) and 1
        lastBit = firstBit
      for state in 0 .. stateCount - 1:
        if currentDp[state] <= unreachable div 2:
          continue
        for removedBit in firstBit .. lastBit:
          let windowMask = (state shl 1) or removedBit
          let nextState = windowMask and (stateCount - 1)
          let gain = happyCounts[childStart * windowMasks + windowMask]
          let candidate = currentDp[state] + gain
          if candidate > nextDp[nextState]:
            nextDp[nextState] = candidate
      let previousDp = currentDp
      currentDp = nextDp
      nextDp = previousDp
    for state in 0 .. stateCount - 1:
      if currentDp[state] > bestResult:
        bestResult = currentDp[state]
  appendOutput($bestResult)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
