# WATERWAY — The Water Ringroad (SPOJ)

<https://www.spoj.com/problems/WATERWAY/>

## Problem

Cities sit around a circular waterway. Each arc between neighbors passes boats clockwise `C`, anticlockwise `A`, or both ways `B`. The old boats cannot pass each other, so the council builds new one-way circular channels. Build the fewest circles so every communicating ordered pair gets its own channel, with no two channels sharing an arc.

Input starts with `t ≤ 100`. Each case gives `n`, then a string of exactly `n` letters `A`, `B`, or `C`. Letter `i` describes the arc from city `i` to city `i+1`, wrapping around. Output one integer per case: the minimum circle count.

The bound forces near-linear work.

| Quantity | Bound |
| --- | --- |
| Test cases | 100 |
| Cities per case | 3 to 100000 |
| Time limit | 17000 ms |
| Memory limit | 1536 MB |

The old arcs are read as one string, so parsing stays cheap.

The sample input and output follow verbatim.

```
2
3
AAA
4
BACB
```

```
3
5
```

## Idea

Choose each channel's arc to spread the load, then count the busiest fragment. Think of assigning delivery vans to the least crowded streets, so no street ever needs two vans.

A channel from `u` to `v` uses one of two complementary arcs. A one-way pair must use its forced arc, while a two-way pair may choose either. Channels sharing a fragment conflict on one circle, so the circle count follows a fragment-load formula. The program sweeps the cities left to right and keeps candidate values in a lazy segment tree. Each city costs logarithmic time.

Trying every arc choice takes exponential time. The formula collapses the choice to one maximum over fragments and fragment pairs.

A load formula plus a sweep answers the whole cycle.

## Why It Works

Four facts give the formula and the sweep.

1. On one circle, at most one channel may use a fragment. For any set of fragments, a channel contributes at least the smaller of its two arc counts inside that set. Dividing by the set size gives a lower bound on circles.
2. For these arcs, the worst fragment set has one or two fragments. Let `F[f]` count channels forced across fragment `f`. Let `B[f,g]` count two-way channels whose arcs separate fragments `f` and `g`. The answer is the maximum of `F[f]` and `ceil((F[f] + F[g] + B[f,g]) / 2)`.
3. The program scans `g` left to right. It keeps `F[f] + B[f,g]` for every earlier `f` in a segment tree. Arc starts, ends, and wrap points change that value on contiguous ranges of `f`.
4. Each change is a constant added to one or two index ranges. A lazy range-add tree applies each in logarithmic time and reports the best `f` with one range-max query.

The table names the sweep values.

| Term | Meaning |
| --- | --- |
| `fwdSpan` | reachable distance going clockwise |
| `backSpan` | reachable distance going anticlockwise |
| `forced` | one-way load per fragment |
| `totalCover` | forced load plus two-way coverage |
| `rangeAdd` | adds a constant to a fragment interval |
| `rangeMax` | returns the best stored value in an interval |

A worked example for `BACB`, with cities numbered from zero, shows the formula.

```
n=4  fragments: B A C B
forced one-way channels use fragments 0 and 3
two-way channels: (2,0), (2,1), (2,3)
F = [4, 0, 0, 4]
B[0,3] = 1
answer = ceil((4 + 4 + 1) / 2) = 5
```

The formula agrees with the sample output `5`.

## Code

**Input setup.** Constants, bulk input, the scanner, and the writer set up parsing.

```nim
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
```

The scanner skips separators and reads one integer at a time. Output waits in one block-flushed buffer. Parsing costs one pass over the input.

**Segment tree.** The segment tree keeps maximum values and delays updates with a lazy tag.

```nim
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
```

One add or query crosses logarithmic nodes. The lazy value delays work until a partial update needs it.

**Difference helper.** The difference-array helper adds a linear ramp in constant time.

```nim
proc addLinear(array0, array1: var seq[int64], left, right: int, coef0, coef1: int64) =
  if left > right or left < 0 or right >= array0.len - 2: return
  array0[left] += coef0
  array1[left] += coef1
  array0[right + 1] -= coef0
  array1[right + 1] -= coef1
```

The two arrays store the constant and slope of a ramp. One prefix pass later turns them into values.

**Closed forms.** Easy all-one and all-same-direction cases get closed forms.

```nim
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
```

The wrap case merges the first and last runs before using the closed form. Both branches return before the general sweep.

**Direction spans.** The doubled scans find each cyclic run once and cap it at `n`.

```nim
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
```

The spans give the reachable distances in each direction. Each scan visits two cycles of the string.

**Load arrays.** Difference arrays build the forced load and the two-way coverage in linear time.

```nim
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
```

Each city contributes at most four ramps. The prefix pass turns two ramps into one value per fragment.

**Arc sweep.** The sweep reads arc events and updates the tree, then returns the best candidate.

```nim
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
```

The three event types add or reverse conflicts on fragment intervals. Each city triggers one range-max query.

**Case driver.** The driver locates each arc string and prints the answer.

```nim
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
```

The scanner skips to the first arc letter. Each case costs one solve call and one flushed line.

## Complexity

The run scans, arrays, and events are all linear in the city count.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | one input string |
| Spans and differences | O(n) per case | O(n) arrays |
| Segment tree sweep | O(n log n) per case | O(n) tree |
| Output | one flush per 256 KiB | one flush block |

The sweep dominates, since each city needs one query and a few updates.

The totals use the city count.

| Measure | Big O |
| --- | --- |
| Time | O(n log n) per case |
| Space | O(n) per case |

Trying each arc direction directly takes exponential time in the pair count.
