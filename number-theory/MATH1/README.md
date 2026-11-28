# MATH1 — Math I (SPOJ)

<https://www.spoj.com/problems/MATH1/>

## Problem

Choose integers x1 through xn so each step around the circle adds either a_i or a_i minus one. Among all choices, minimize the sum of absolute values of x1 through xn.

Input: one integer t, then t cases. Each case gives n on a line, then n integers a_1 through a_n on the next line. Output: one line per case with that smallest sum.

In the explanation, S is the sum of the a values, b_j is arrivals minus departures, and m is the level.

The statement bounds are:

| Item | Bound |
|---|---|
| Test cases t | at most 20 |
| Length n | 1 to 1000 |
| Each a_i | 0 to n |
| Sum of a values S | at most n |
| Judge limit | 20 s, 1536 MB |

The sum bound keeps the number of departures at most n.

The sample case:

```
2
4
2 1 0 0
5
0 1 2 2 0
```

```
1
3
```

Both sample answers match the x choices printed in the statement.

## Idea

Treat the x values as a queue length. At step i, a_i customers arrive, and one customer may leave. Pick the S departure steps that hold the queue nearest one level.

Dynamic programming over the departure count finds the best queue path for one level. Ternary search over the level finds the global best, because the cost curve is convex. Each level costs O(n S) work, and about log n levels are tried.

Trying every set of departure steps takes C(n, S) choices, which explodes at n = 1000. Scanning all levels with a full DP adds another factor of n. Two small loops replace that search.

## Why It Works

1. Set ε_j to x_(j-1) minus x_j plus a_j, with index zero meaning n. Every ε_j is 0 or 1.
2. Unrolling the steps gives x_j = z + b_j. The value z shifts every x by the same amount.
3. The wrap-around rule forces b_n = 0, so exactly S of the ε values are 1.
4. For fixed ε, the best z is a median of b_1 through b_n. The cost is the sum of |b_j - m|.
5. The minimum of that sum over all ε is convex in m. Ternary search finds the best level.

The main terms:

| Term | Meaning |
|---|---|
| S | sum of all a values, and the number of departures |
| b_j | arrivals up to j minus departures up to j |
| m | centering level, a median of the b values |
| `previous[ones]` | least cost after the prefix with that many departures |
| `difference` | distance from the current backlog to the level |

The DP state counts departures, so the recurrence needs no path history.

A script trace of the first sample case at level m = 1:

```
level 1
start e=0..3: 0 INF INF INF
j=1 a=2 prefix=2: 1 0 INF INF
j=2 a=1 prefix=3: 3 1 0 INF
j=3 a=0 prefix=3: 5 2 0 1
j=4 a=0 prefix=3: 7 3 0 1
answer 1
```

The last row gives cost 1 at three departures, matching the sample output.

## Code

**Constants and token reader.** Read the whole stream, then scan digits by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const hugeCost = 1000000000

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

`firstDigitValue` converts a digit byte into its value. `pos` moves by index, so no token object appears. The input holds no negative numbers, so no sign branch is needed.

**Level solver.** One DP pass for one centering level.

```nim
proc minCost(values: seq[int], valueCount, onesTotal, level: int,
             previous: var seq[int], current: var seq[int]): int =
  for ones in 0..onesTotal:
    previous[ones] = hugeCost
    current[ones] = hugeCost
  previous[0] = 0
  var prefixSum = 0
  for valueIndex in 0..<valueCount:
    prefixSum += values[valueIndex]
    let maxOnes = min(valueIndex + 1, onesTotal)
    for ones in 0..maxOnes:
      var bestPrevious = previous[ones]
      if ones > 0 and previous[ones - 1] < bestPrevious:
        bestPrevious = previous[ones - 1]
      var difference = prefixSum - ones - level
      if difference < 0: difference = -difference
      current[ones] = bestPrevious + difference
    swap(previous, current)
  return previous[onesTotal]
```

`maxOnes` bounds the state by prefix length and departure total. `swap` reuses both arrays at every position. The added `difference` is the distance from backlog to `level`.

**Level search.** Ternary search, then a short scan of the final bracket.

```nim
proc solveCase(values: seq[int], valueCount: int): int =
  var onesTotal = 0
  for valueIndex in 0..<valueCount:
    onesTotal += values[valueIndex]
  var previous = newSeq[int](onesTotal + 1)
  var current = newSeq[int](onesTotal + 1)
  var lowLevel = -valueCount
  var highLevel = onesTotal
  while highLevel - lowLevel > 3:
    let thirdSpan = (highLevel - lowLevel) div 3
    let leftLevel = lowLevel + thirdSpan
    let rightLevel = highLevel - thirdSpan
    let leftCost = minCost(values, valueCount, onesTotal, leftLevel, previous, current)
    let rightCost = minCost(values, valueCount, onesTotal, rightLevel, previous, current)
    if leftCost <= rightCost:
      highLevel = rightLevel - 1
    else:
      lowLevel = leftLevel + 1
  var bestAnswer = hugeCost
  for level in lowLevel..highLevel:
    let cost = minCost(values, valueCount, onesTotal, level, previous, current)
    if cost < bestAnswer:
      bestAnswer = cost
  return bestAnswer
```

`lowLevel` and `highLevel` bracket every possible median. Each turn shrinks the bracket by a third. The final loop covers the last four levels, where the curve may be flat.

**Driver.** Bulk input, one answer per case, block output.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""
for caseIndex in 0..<caseCount:
  let valueCount = nextInt(inputData, scanPos)
  var values = newSeq[int](valueCount)
  for valueIndex in 0..<valueCount:
    values[valueIndex] = nextInt(inputData, scanPos)
  outputBuffer.add $(solveCase(values, valueCount))
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

`readLine` appends every line into one `inputData` buffer. `outputBuffer` collects all answers and flushes at `flushBlockBytes`. `setLen 0` reuses that allocation. The final `stdout.write` emits the tail.

## Complexity

Work for one case:

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over lines, then one digit pass | input bytes |
| One level | valueCount times onesTotal states | two arrays of onesTotal + 1 |
| Level search | about log n levels | the same two arrays |
| Output | one write per block | block buffer |

Both DP arrays survive every level, so the search adds no allocation.

Overall bounds:

| Measure | Big O |
|---|---|
| Time | O(n S log n) per case, with S at most n |
| Space | O(S) for the DP plus the input bytes |

Enumerating departure sets costs C(n, S) choices, and scanning every level costs O(n^2 S). Ternary search removes the extra factor of n.
