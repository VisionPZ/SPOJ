## Problem

Cities sit on a circle. Each arc between neighboring cities passes boats clockwise (`C`), anticlockwise (`A`), or both ways (`B`). Build the fewest new circular channels so that every ordered pair of cities communicating in the old waterway gets its own one-way channel. Two channels may not share a fragment of a circle.

| Quantity | Bound |
| --- | --- |
| Test cases | 100 |
| Cities per case | 3 to 100000 |
| Time limit | 17000 ms |
| Memory limit | 1536 MB |

The work per case must stay near linear, because the city count is large.

## Idea

A channel from city `u` to city `v` uses one of two complementary arcs: the clockwise fragments `u..v-1`, or the anticlockwise fragments `v..u-1`. A one-way pair must use its forced arc. A two-way pair may use either arc.

On one circle, channels using the same fragment conflict. So the circles needed for a choice of arcs are the colors of a graph whose vertices are channels and whose edges join channels sharing a fragment. For these arcs the color count equals the largest fragment load. The program chooses arcs to minimize that load, then reports the minimum.

The minimum has a small formula. Let `F[f]` count one-way channels forced across fragment `f`. Let `B[f,g]` count two-way channels whose two arcs separate fragments `f` and `g`, meaning exactly one arc contains each. Then the answer is the maximum of `F[f]` over single fragments and `ceil((F[f] + F[g] + B[f,g]) / 2)` over pairs of fragments.

The program sweeps `g` from left to right. It keeps the value `F[f] + B[f,g]` for every earlier `f` in a segment tree. Arc starts, ends, and wrap-around points change that value on contiguous ranges of `f`. A range-add, range-max tree finds the best partner for each `g` in logarithmic time.

## Why It Works

For any set `S` of fragments, a channel contributes at least the smaller of its two arc counts inside `S`. Since a circle holds at most one channel per fragment, the number of circles is at least that contribution summed over channels, divided by `|S|`. For the arcs of this problem the worst set `S` has one or two fragments, which gives the formula above.

A one-way channel forced across `f` always contributes to `F[f]`. A two-way channel contributes one to `B[f,g]` exactly when `f` and `g` lie on opposite sides of its chosen arc. Because the two arcs of a two-way channel are complements, this side test does not depend on the choice.

The sweep maintains the current value for each earlier fragment. When an arc begins at fragment `u`, fragments outside the arc gain one conflict and fragments inside lose one. When an arc ends, the changes reverse. A wrapping arc also changes sides when it stops covering the low fragments. Each change is a constant added to one or two index ranges, which the segment tree applies lazily.

Worked example for `BACB`, cities numbered from zero:

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

Input is read once into one buffer and parsed by a hand scanner. Output is flushed in blocks.

```nim
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
```

The scanner skips separators and reads each city count. The parser then skips to the first arc letter and advances by that count.

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
```

All input ends in one pass. Each case costs one solve call.

The run lengths `fwd` and `back` give the reachable distances in each direction. The difference arrays below add linear ramps for forced channels and for two-way coverage in constant time per city.

```nim
  var fwd = newSeq[int](n)
  var run = 0
  for p in countdown(2 * n - 1, 0):
    if text[start + (p mod n)] == 'B' or text[start + (p mod n)] == 'C':
      run += 1
    else:
      run = 0
    if p < n and run > 0:
      fwd[p] = min(run, n)

  var back = newSeq[int](n)
  for p in 0..<2 * n:
    let u = p mod n
    let prev = (u - 1 + n) mod n
    if text[start + prev] == 'A' or text[start + prev] == 'B':
      back[u] = min(back[prev] + 1, n)
    else:
      back[u] = 0
```

The doubled scans find each cyclic run once and cap it at `n`.

The segment tree stores maximum values and applies constant range adds lazily.

```nim
type SegmentTree = object
  size: int
  mx: seq[int64]
  lz: seq[int64]

proc initTree(values: seq[int64]): SegmentTree =
  var size = 1
  while size < values.len: size = size shl 1
  result.size = size
  result.mx = newSeq[int64](size shl 1)
  result.lz = newSeq[int64](size shl 1)
  for i in 0..<size shl 1: result.mx[i] = negInf
  for i in 0..<values.len: result.mx[size + i] = values[i]
  for i in countdown(size - 1, 1):
    result.mx[i] = max(result.mx[i shl 1], result.mx[i shl 1 + 1])

proc apply(tree: var SegmentTree, node: int, value: int64) =
  tree.mx[node] += value
  tree.lz[node] += value

proc push(tree: var SegmentTree, node: int) =
  let value = tree.lz[node]
  if value != 0:
    tree.apply(node shl 1, value)
    tree.apply(node shl 1 + 1, value)
    tree.lz[node] = 0

proc rangeAdd(tree: var SegmentTree, node, left, right, ql, qr: int, value: int64) =
  if qr < left or right < ql: return
  if ql <= left and right <= qr:
    tree.apply(node, value)
    return
  tree.push(node)
  let mid = (left + right) shr 1
  tree.rangeAdd(node shl 1, left, mid, ql, qr, value)
  tree.rangeAdd(node shl 1 + 1, mid + 1, right, ql, qr, value)
  tree.mx[node] = max(tree.mx[node shl 1], tree.mx[node shl 1 + 1])
```

One add or query crosses logarithmic nodes. The lazy value delays work until a partial update needs it.

The sweep reads the events at each position and updates the affected fragment ranges.

```nim
  for gpos in 0..<n:
    if gpos > 0:
      let mv = tree.rangeMax(1, 0, tree.size - 1, 0, gpos - 1)
      let cand = (forced[gpos] + mv + 1) div 2
      if cand > answer: answer = cand
    let p = gpos + 1
    if p < events.len:
      for event in events[p]:
        let typ = event.typ
        let u = event.u
        let r = event.r
        let hi1 = min(n - 1, r - 1)
        var hi2 = -1
        if r > n: hi2 = min(n - 1, r - n - 1)
        let compLo = if hi2 >= 0: hi2 + 1 else: 0
        let compHi = u - 1
        let tailLo = if r <= n: r else: n
        if typ == 0:
          if u <= hi1: tree.rangeAdd(1, 0, tree.size - 1, u, hi1, -1)
          if hi2 >= 0: tree.rangeAdd(1, 0, tree.size - 1, 0, hi2, -1)
          if compLo <= compHi and compLo < n:
            tree.rangeAdd(1, 0, tree.size - 1, compLo, min(n - 1, compHi), 1)
          if tailLo < n: tree.rangeAdd(1, 0, tree.size - 1, tailLo, n - 1, 1)
```

The two other event types mirror these adds. The loop visits every fragment once.

## Complexity

Reading input and writing output use one buffer each. The run scans, difference arrays, and event build cost `O(n)` per case. The sweep performs `O(n)` tree operations, each `O(log n)`. Total time is `O(n log n)` per case and total space is `O(n)`. A direct search over channel directions would take exponential time.
