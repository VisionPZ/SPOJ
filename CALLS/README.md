# CALLS — Calls (SPOJ)

<https://www.spoj.com/problems/CALLS/>

## Problem

Decide whether a table of cheapest call costs can come from a phone network with exactly K lines joining N cities.
Every line joins two cities, works both ways, and has a positive cost. A call may pass through other cities.

Input: `t`, then `t` blocks. Each block starts with `N K` and continues with `N-1` lines.
Line `i` holds `N-i` costs; entry `j` gives the cost from city `i` to city `i+j`.

Output: one line per block, `YES` or `NO`.

The statement gives these bounds:

| Item | Bound |
|---|---|
| Flyers `t` | at most 50 |
| Cities `N` | at most 300 |
| Lines `K` | at most 1200 |
| Judge limit | 3000 ms, 1536 MB |

K cannot exceed N(N-1)/2 distinct city pairs, so a larger count forces `NO`.

The sample input:

```
2
3 3
1 2
2
3 2
1 2
2
```

The sample output:

```
YES
NO
```

The first network needs three lines; the second has only two.

## Idea

Keep only prices that no two cheaper prices rebuild, like crossing names off a list.
Once a price can be made from smaller ones, cross it off. What stays is the smallest set of lines.

The algorithm counts those unsplittable pairs, then compares the count with `lineCount`.
For each `leftCity`, `midCity`, and `rightCity`, `scanViaCity` compares `viaCost` with `targetCost`.
A smaller `viaCost` proves a forgery; equality sets `shortcutFlags[rightCity]`.

Each triple costs one addition and two comparisons, so one flyer costs O(N^3).
A naive search tries every subset of lines and every cost assignment, which grows much faster.

Count essential pairs first, then answer with that count and the upper bound.

## Why It Works

Four facts prove that the count settles the question.

1. A route with two or more lines passes through an internal city. Both parts cost less than the whole, since line costs are positive. An unsplittable pair must be a line.
2. Splitting an advertised cost into two smaller costs can repeat. The chain ends at unsplittable pairs, which already give the advertised cost.
3. Every valid network contains all unsplittable pairs, so their count is a lower bound on lines.
4. Extra lines priced at the advertised cost create no shortcut. Every count up to N(N-1)/2 then works.

The scan uses these terms:

| Term | Meaning |
|---|---|
| `targetCost` | advertised cost between `leftCity` and `rightCity` |
| `baseCost` | advertised cost between `leftCity` and `midCity` |
| `viaCost` | `baseCost` plus the cost from `midCity` to `rightCity` |
| `shortcutFlags[rightCity]` | true after some `midCity` matches `targetCost` |

A smaller `viaCost` rejects the flyer; equality marks a splittable pair.

A script traces the sample, where three cities have costs 1, 2, and 2:

```
city pair  cost  cheapest split  verdict
0 1        1     2+2=4 via 2   line
0 2        2     1+2=3 via 1   line
1 2        2     1+2=3 via 0   line

essentialCount = 3
lineCount = 3 -> YES
lineCount = 2 -> NO
```

Three pairs stay, so `lineCount` 3 passes and `lineCount` 2 fails.

## Code

**Constants and token reader.** The scanner walks one buffer by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 16

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value
```

`firstDigitValue` turns a digit byte into a number. `scanPos` skips separators without allocating tokens.

**Triple scan.** One call handles a single `midCity` and a range of right cities.

```nim
proc scanViaCity(distanceData: seq[int], baseCost, leftOffset, midOffset,
                 lowCity, highCity: int, shortcutFlags: var seq[bool]): bool =
  for rightCity in lowCity..<highCity:
    let targetCost = distanceData[leftOffset + rightCity]
    let viaCost = baseCost + distanceData[midOffset + rightCity]
    if viaCost < targetCost: return false
    if viaCost == targetCost: shortcutFlags[rightCity] = true
  return true
```

`viaCost` below `targetCost` returns false. Equality marks a splittable pair. The loop cost is linear in the range.

**Bulk input.** One read collects the whole stream.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let flyerCount = nextInt(inputData, scanPos)
var outputBuffer = ""
var distanceData: seq[int]
var shortcutFlags: seq[bool]
```

One `readLine` loop builds `inputData`. The buffers and the flat matrix are created once. The added newline keeps tokens apart.

**Block reader.** Each block fills a symmetric matrix and rejects impossible sizes.

```nim
for flyerIndex in 0..<flyerCount:
  let cityCount = nextInt(inputData, scanPos)
  let lineCount = nextInt(inputData, scanPos)
  let pairCount = cityCount * (cityCount - 1) div 2
  distanceData.setLen(cityCount * cityCount)
  var isForgery = false
  for leftCity in 0..<cityCount:
    let leftOffset = leftCity * cityCount
    distanceData[leftOffset + leftCity] = 0
    for rightCity in leftCity+1..<cityCount:
      let advertisedCost = nextInt(inputData, scanPos)
      if advertisedCost <= 0: isForgery = true
      distanceData[leftOffset + rightCity] = advertisedCost
      distanceData[rightCity * cityCount + leftCity] = advertisedCost
  if isForgery or lineCount > pairCount:
    outputBuffer.add "NO\n"
    if outputBuffer.len >= flushBlockBytes:
      stdout.write outputBuffer
      outputBuffer.setLen 0
    continue
```

`pairCount` is the number of city pairs. A zero cost or oversized `lineCount` ends the block. The matrix holds each cost twice.

**Essential-pair count.** The scan treats every intermediate city in turn.

```nim
shortcutFlags.setLen(cityCount)
  var essentialCount = 0
  block evaluation:
    for leftCity in 0..<cityCount:
      for rightCity in leftCity+1..<cityCount:
        shortcutFlags[rightCity] = false
      let leftOffset = leftCity * cityCount
      for midCity in 0..<cityCount:
        if midCity == leftCity: continue
        let baseCost = distanceData[leftOffset + midCity]
        let midOffset = midCity * cityCount
        if midCity < leftCity:
          if not scanViaCity(distanceData, baseCost, leftOffset, midOffset,
                             leftCity+1, cityCount, shortcutFlags):
            isForgery = true
            break evaluation
        else:
          if not scanViaCity(distanceData, baseCost, leftOffset, midOffset,
                             leftCity+1, midCity, shortcutFlags):
            isForgery = true
            break evaluation
          if not scanViaCity(distanceData, baseCost, leftOffset, midOffset,
                             midCity+1, cityCount, shortcutFlags):
            isForgery = true
            break evaluation
      if not isForgery:
        for rightCity in leftCity+1..<cityCount:
          if not shortcutFlags[rightCity]: essentialCount += 1
        if essentialCount > lineCount: break evaluation
```

`shortcutFlags` resets for each `leftCity`. The two calls split the row around `midCity` and skip the diagonal. `essentialCount` above `lineCount` stops the block early. Cost is O(N^3) per flyer.

**Verdict and flush.** Only a short answer enters the output buffer.

```nim
  if isForgery or essentialCount > lineCount:
    outputBuffer.add "NO\n"
  else:
    outputBuffer.add "YES\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
```

`flushBlockBytes` caps the buffer at 64 KiB. The final write covers the tail. `setLen 0` reuses the allocation.

## Complexity

Costs split into input, matrix, scan, and output phases.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input buffer |
| Matrix fill | N(N-1)/2 assignments, mirrored | N squared integers |
| Triple scan | N cubed comparisons, cut short on failure | N bools |
| Output | one write per 64 KiB block | block buffer |

The scan dominates; input and output stay linear.

The asymptotic bounds:

| Measure | Big O |
|---|---|
| Time | O(N^3) per flyer, O(t N^3) total |
| Space | O(N^2) per flyer |

A subset search over K lines grows without this cubic bound, so the scan is the practical choice.
