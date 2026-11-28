{.passC: "-O3".}
{.optimization: speed.}
{.push checks: off.}
{.push overflowChecks: off.}
{.push rangeChecks: off.}
{.push boundChecks: off.}
{.push stackTrace: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const negInf = -1000000000000000000'i64

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

type SegmentTree = object
  size: int
  maxVal: seq[int64]
  lazyAdd: seq[int64]

proc initTree(values: seq[int64]): SegmentTree =
  var size = 1
  while size < values.len: size = size shl 1
  result.size = size
  result.maxVal = newSeq[int64](size shl 1)
  result.lazyAdd = newSeq[int64](size shl 1)
  for idx in 0..<size shl 1: result.maxVal[idx] = negInf
  for idx in 0..<values.len: result.maxVal[size + idx] = values[idx]
  for idx in countdown(size - 1, 1):
    result.maxVal[idx] = max(result.maxVal[idx shl 1], result.maxVal[idx shl 1 + 1])

proc apply(tree: var SegmentTree, node: int, value: int64) =
  tree.maxVal[node] += value
  tree.lazyAdd[node] += value

proc push(tree: var SegmentTree, node: int) =
  let value = tree.lazyAdd[node]
  if value != 0:
    tree.apply(node shl 1, value)
    tree.apply(node shl 1 + 1, value)
    tree.lazyAdd[node] = 0

proc rangeAdd(tree: var SegmentTree, node, left, right, queryLeft, queryRight: int, value: int64) =
  if queryRight < left or right < queryLeft: return
  if queryLeft <= left and right <= queryRight:
    tree.apply(node, value)
    return
  tree.push(node)
  let mid = (left + right) shr 1
  tree.rangeAdd(node shl 1, left, mid, queryLeft, queryRight, value)
  tree.rangeAdd(node shl 1 + 1, mid + 1, right, queryLeft, queryRight, value)
  tree.maxVal[node] = max(tree.maxVal[node shl 1], tree.maxVal[node shl 1 + 1])

proc rangeMax(tree: var SegmentTree, node, left, right, queryLeft, queryRight: int): int64 =
  if queryRight < left or right < queryLeft: return negInf
  if queryLeft <= left and right <= queryRight: return tree.maxVal[node]
  tree.push(node)
  let mid = (left + right) shr 1
  return max(tree.rangeMax(node shl 1, left, mid, queryLeft, queryRight),
             tree.rangeMax(node shl 1 + 1, mid + 1, right, queryLeft, queryRight))

proc addLinear(array0, array1: var seq[int64], left, right: int, coef0, coef1: int64) =
  if left > right or left < 0 or right >= array0.len - 2: return
  array0[left] += coef0
  array1[left] += coef1
  array0[right + 1] -= coef0
  array1[right + 1] -= coef1

proc solveCase(text: openArray[char], start: int, cityCount: int): int64 =
  var countA = 0
  var countC = 0
  for idx in 0..<cityCount:
    if text[start + idx] == 'A': countA += 1
    elif text[start + idx] == 'C': countC += 1
  if countA == 0 and countC == 0:
    return int64(cityCount) * int64(cityCount) div 4
  if countA == 0 or countC == 0:
    var runLengths = newSeq[int]()
    var currentRun = 0
    for idx in 0..<cityCount:
      if text[start + idx] == 'B':
        currentRun += 1
      elif currentRun > 0:
        runLengths.add currentRun
        currentRun = 0
    if currentRun > 0:
      if runLengths.len > 0 and text[start] == 'B' and text[start + cityCount - 1] == 'B':
        runLengths[0] += currentRun
      else:
        runLengths.add currentRun
    if runLengths.len == 0:
      return int64(cityCount) * int64(cityCount - 1) div 2
    var pairTotal = 0'i64
    var bestBalance = 0'i64
    var capacities = newSeq[int64](runLengths.len)
    for runIdx in 0..<runLengths.len:
      let runLen = int64(runLengths[runIdx])
      pairTotal += runLen * (runLen + 1) div 2
      capacities[runIdx] = (runLen + 1) * (runLen + 1) div 4
    for runIndex in 0..<runLengths.len:
      var outside = -1'i64
      for other in 0..<runLengths.len:
        if other != runIndex: outside = max(outside, capacities[other])
      let runLen = int64(runLengths[runIndex])
      for take in 1..runLengths[runIndex]:
        let takeVal = int64(take)
        let base = takeVal * (runLen - takeVal + 1)
        if outside >= 0: bestBalance = max(bestBalance, base + outside)
        bestBalance = max(bestBalance, takeVal * takeVal div 4 + base)
        if take < runLengths[runIndex]:
          var vertex = (runLen + 1 + takeVal) div 2
          var valueAt = max(takeVal + 1, min(runLen, vertex))
          bestBalance = max(bestBalance, valueAt * (runLen + 1 + takeVal - valueAt) - takeVal * takeVal)
          vertex += 1
          valueAt = max(takeVal + 1, min(runLen, vertex))
          bestBalance = max(bestBalance, valueAt * (runLen + 1 + takeVal - valueAt) - takeVal * takeVal)
    return int64(cityCount) * int64(cityCount - 1) div 2 - pairTotal + bestBalance

  var fwdSpan = newSeq[int](cityCount)
  var run = 0
  for stepIdx in countdown(2 * cityCount - 1, 0):
    if text[start + (stepIdx mod cityCount)] == 'B' or text[start + (stepIdx mod cityCount)] == 'C':
      run += 1
    else:
      run = 0
    if stepIdx < cityCount and run > 0:
      fwdSpan[stepIdx] = min(run, cityCount)

  var backSpan = newSeq[int](cityCount)
  for stepIdx in 0..<2 * cityCount:
    let pos = stepIdx mod cityCount
    let prev = (pos - 1 + cityCount) mod cityCount
    if text[start + prev] == 'A' or text[start + prev] == 'B':
      backSpan[pos] = min(backSpan[prev] + 1, cityCount)
    else:
      backSpan[pos] = 0

  var diff0 = newSeq[int64](cityCount + 2)
  var diff1 = newSeq[int64](cityCount + 2)
  for pos in 0..<cityCount:
    let fwdLimit = min(fwdSpan[pos], cityCount - backSpan[pos] - 1)
    if fwdLimit >= 1:
      let directSpan = min(fwdLimit - 1, cityCount - 1 - pos)
      addLinear(diff0, diff1, pos, pos + directSpan, int64(pos + fwdLimit), -1)
      if fwdLimit - 1 > directSpan:
        addLinear(diff0, diff1, 0, fwdLimit - 1 - directSpan - 1, int64(pos + fwdLimit - cityCount), -1)
    let backLimit = min(backSpan[pos], cityCount - fwdSpan[pos] - 1)
    if backLimit >= 1:
      let directBack = min(backLimit, pos)
      if directBack >= 1:
        addLinear(diff0, diff1, pos - directBack, pos - 1, int64(backLimit + 1 - pos), 1)
      if backLimit > directBack:
        addLinear(diff0, diff1, cityCount + pos - backLimit, cityCount - 1, int64(backLimit + 1 - pos - cityCount), 1)
  var forced = newSeq[int64](cityCount)
  var constAcc = 0'i64
  var slopeAcc = 0'i64
  for pos in 0..<cityCount:
    constAcc += diff0[pos]
    slopeAcc += diff1[pos]
    forced[pos] = constAcc + int64(pos) * slopeAcc

  var diffA0 = newSeq[int64](cityCount + 2)
  var diffA1 = newSeq[int64](cityCount + 2)
  proc addRange(base: var seq[int64], left, right: int, value: int64) =
    if left > right or left < 0 or right >= cityCount: return
    base[left] += value
    base[right + 1] -= value
  proc addArcLinear(origin, offsetLow, offsetHigh: int, coef0, coef1: int64) =
    if offsetLow > offsetHigh: return
    let rangeLeft = origin + offsetLow
    let rangeRight = origin + offsetHigh
    if rangeRight < cityCount:
      addLinear(diffA0, diffA1, rangeLeft, rangeRight, coef0, coef1)
    elif rangeLeft >= cityCount:
      addLinear(diffA0, diffA1, rangeLeft - cityCount, rangeRight - cityCount, coef0 + coef1 * int64(cityCount), coef1)
    else:
      addLinear(diffA0, diffA1, rangeLeft, cityCount - 1, coef0, coef1)
      addLinear(diffA0, diffA1, 0, rangeRight - cityCount, coef0 + coef1 * int64(cityCount), coef1)

  var arcMinLen = newSeq[int](cityCount)
  var arcMaxLen = newSeq[int](cityCount)
  var arcStart = newSeq[int]()
  var arcEnd = newSeq[int]()
  for pos in 0..<cityCount:
    let minLen = max(1, cityCount - backSpan[pos])
    let maxLen = min(fwdSpan[pos], cityCount - 1)
    if minLen <= maxLen:
      arcMinLen[pos] = minLen
      arcMaxLen[pos] = maxLen
      addArcLinear(pos, 0, minLen - 1, int64(maxLen - minLen + 1), 0)
      addArcLinear(pos, minLen, maxLen - 1, int64(maxLen + pos), -1)
      for arcLen in minLen..maxLen:
        arcStart.add(pos)
        arcEnd.add(pos + arcLen)
  var cover = newSeq[int64](cityCount)
  var arcConstAcc = 0'i64
  var arcSlopeAcc = 0'i64
  for pos in 0..<cityCount:
    arcConstAcc += diffA0[pos]
    arcSlopeAcc += diffA1[pos]
    cover[pos] = arcConstAcc + int64(pos) * arcSlopeAcc
  var totalCover = newSeq[int64](cityCount)
  for pos in 0..<cityCount: totalCover[pos] = forced[pos] + cover[pos]

  var wrapFromZero = newSeq[int64](cityCount)
  if arcMaxLen[0] >= arcMinLen[0]:
    for pos in 0..<cityCount:
      var count = 0'i64
      for arcLen in arcMinLen[0]..arcMaxLen[0]:
        if arcLen > pos: count += 1
      wrapFromZero[pos] = count
  var wrapDiff = newSeq[int64](cityCount + 2)
  for pos in 0..<cityCount:
    if arcMaxLen[pos] >= arcMinLen[pos]:
      let endLow = pos + arcMinLen[pos]
      let endHigh = pos + arcMaxLen[pos]
      let wrapCount = max(0, endHigh - max(endLow, cityCount + 1) + 1)
      if wrapCount > 0:
        addRange(wrapDiff, pos, cityCount - 1, int64(wrapCount))
  var wrapStartBefore = newSeq[int64](cityCount)
  var runningWrap = 0'i64
  for pos in 0..<cityCount:
    runningWrap += wrapDiff[pos]
    wrapStartBefore[pos] = runningWrap
  var endCount = newSeq[int64](2 * cityCount + 2)
  for idx in 0..<arcStart.len:
    endCount[arcEnd[idx]] += 1
  var wrapEndAfter = newSeq[int64](cityCount)
  var suffixSum = 0'i64
  for endPos in countdown(2 * cityCount + 1, 0):
    suffixSum += endCount[endPos]
    let idx = endPos - cityCount - 1
    if idx >= 0 and idx < cityCount: wrapEndAfter[idx] = suffixSum

  var values = newSeq[int64](cityCount)
  for pos in 0..<cityCount:
    values[pos] = totalCover[pos] + cover[0] - 2 * wrapFromZero[pos] - 2 * wrapStartBefore[pos] - 2 * wrapEndAfter[pos]

  type ArcEvent = tuple[kind, startPos, endPos: int]
  var events = newSeq[seq[ArcEvent]](2 * cityCount + 2)
  for idx in 0..<arcStart.len:
    let startPos = arcStart[idx]
    let endPos = arcEnd[idx]
    events[startPos].add((0, startPos, endPos))
    events[endPos].add((1, startPos, endPos))
    if endPos > cityCount: events[endPos - cityCount].add((2, startPos, endPos))

  var tree = initTree(values)
  var answer = 0'i64
  for pos in 0..<cityCount: answer = max(answer, forced[pos])
  for cutPos in 0..<cityCount:
    if cutPos > 0:
      let maxPrev = tree.rangeMax(1, 0, tree.size - 1, 0, cutPos - 1)
      let candidate = (forced[cutPos] + maxPrev + 1) div 2
      if candidate > answer: answer = candidate
    let eventPos = cutPos + 1
    if eventPos < events.len:
      for event in events[eventPos]:
        let kind = event.kind
        let startPos = event.startPos
        let endPos = event.endPos
        let firstHi = min(cityCount - 1, endPos - 1)
        var wrapHi = -1
        if endPos > cityCount: wrapHi = min(cityCount - 1, endPos - cityCount - 1)
        let compLo = if wrapHi >= 0: wrapHi + 1 else: 0
        let compHi = startPos - 1
        let tailLo = if endPos <= cityCount: endPos else: cityCount
        if kind == 0:
          if startPos <= firstHi: tree.rangeAdd(1, 0, tree.size - 1, startPos, firstHi, -1)
          if wrapHi >= 0: tree.rangeAdd(1, 0, tree.size - 1, 0, wrapHi, -1)
          if compLo <= compHi and compLo < cityCount:
            tree.rangeAdd(1, 0, tree.size - 1, compLo, min(cityCount - 1, compHi), 1)
          if tailLo < cityCount: tree.rangeAdd(1, 0, tree.size - 1, tailLo, cityCount - 1, 1)
        elif kind == 1:
          if startPos <= firstHi: tree.rangeAdd(1, 0, tree.size - 1, startPos, firstHi, 1)
          if wrapHi >= 0: tree.rangeAdd(1, 0, tree.size - 1, 0, wrapHi, 1)
          if compLo <= compHi and compLo < cityCount:
            tree.rangeAdd(1, 0, tree.size - 1, compLo, min(cityCount - 1, compHi), -1)
          if tailLo < cityCount: tree.rangeAdd(1, 0, tree.size - 1, tailLo, cityCount - 1, -1)
        else:
          let wrapLimit = endPos - cityCount - 1
          if wrapLimit >= 0 and wrapLimit < cityCount: tree.rangeAdd(1, 0, tree.size - 1, 0, wrapLimit, 1)
          if endPos - cityCount <= startPos - 1 and endPos - cityCount < cityCount:
            tree.rangeAdd(1, 0, tree.size - 1, endPos - cityCount, min(cityCount - 1, startPos - 1), -1)
          if startPos < cityCount: tree.rangeAdd(1, 0, tree.size - 1, startPos, cityCount - 1, 1)
  return answer

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let cityCount = nextInt(inputData, scanPos)
  while scanPos < inputData.len and inputData[scanPos] != 'A' and
        inputData[scanPos] != 'B' and inputData[scanPos] != 'C':
    scanPos += 1
  let textStart = scanPos
  scanPos += cityCount
  let answer = solveCase(inputData, textStart, cityCount)
  appendOutput($(answer))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
