# ROADS — Roads (SPOJ)

<https://www.spoj.com/problems/ROADS/>

## Problem

Each test case lists one-way roads with a length and a toll. Find the shortest total length from city 1 to city N among paths whose total toll stays within the budget.

Input: `t`, then `t` cases. Each case gives `budget`, `cityCount`, `roadCount`, then `roadCount` lines of `sourceCity`, `destCity`, `roadLength`, `roadToll` values. Output: one line per case with that shortest length, or `-1` when no affordable path exists.

| Item | Bound |
|---|---|
| Test cases `t` | not bounded in the statement |
| `budget` | 0 ≤ budget ≤ 10 000 |
| `cityCount` | 2 ≤ cityCount ≤ 100 |
| `roadCount` | 1 ≤ roadCount ≤ 10 000 |
| `roadLength` | 1 ≤ roadLength ≤ 100 |
| `roadToll` | 0 ≤ roadToll ≤ 100 |
| judge limits | 7 s, 1536 MB |

The product of `budget` and `roadCount` drives the running time.

The sample input:

```
2
5
6
7
1 2 2 3
2 4 3 3
3 4 2 4
1 3 4 1
4 6 2 1
3 5 2 0
5 4 3 2
0
4
4
1 4 5 2
1 2 1 0
2 3 1 1
3 4 1 0
```

The sample output:

```
11
-1
```

## Idea

Process coin totals in order, like turning calendar pages one day at a time. Each page holds the best length for every city at that exact spend.

The algorithm is layered dynamic programming. Toll-free roads stay on one page, and a small Dijkstra sweep settles every city there. Paid roads write candidate lengths into later pages. Each road is examined once per page, so one page costs O(`roadCount`). A global search over city-and-coin states carries a heap and revisits many more states.

Takeaway: one forward pass over a flat table replaces a large state-space search.

## Why It Works

1. Every paid road raises the coin total, so it points to a later page. Toll-free roads keep the same total.
2. Every road length is positive, so Dijkstra settles each city once on its page. Repeated relaxation adds no improvement.
3. `bestLengths` stores the settled length for each city and coin total. Lower pages are final when higher pages read them.
4. Removing a cycle lowers both length and toll, so an optimal path never needs a repeated city.

The table terms and their meanings:

| Term | Meaning |
|---|---|
| `cityIndex * tollLevels + spentCoins` | slot for city `cityIndex` at coin total `spentCoins` |
| `spentCoins + paidToll[roadIndex]` | coin total after taking a paid road |
| `chosenLength + zeroLength[edgeIndex]` | candidate length after a toll-free road |
| `baseLength + paidLength[roadIndex]` | candidate length after a paid road |
| `unreachableLength` | marker for a slot with no known path |

Every update reads a settled lower page and writes a higher one, so one sweep finishes the case.

A script traces three cities, a budget of three coins, and these roads:

```
K=3 N=3 roads: 1 2 2 1 | 2 3 3 0 | 1 3 9 0
coins=0: settled city1=0 city3=9
  paid road 1->2 sets city2 at coins=1 to 2
coins=1: settled city2=2 city3=5
coins=2: settled none
coins=3: settled none
answer: 5
card: city3 by coins: [9, 5, 1000000000000000000, 1000000000000000000]
```

The toll-free road 2 3 3 0 cuts the answer from 9 to 5 after one coin is spent.

## Code

**Constants and scanner.** Digit base, block size, and the integer reader.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const unreachableLength = 1 shl 60

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

The scanner skips separators, so blank lines cannot desync the case reader. Input values are nonnegative, so no sign branch exists. Each token costs one pass over its digits.

**Bulk input and block output.** One buffer on each side of the program.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Every input line is appended with its newline, then `scanPos` walks that one buffer. `appendOutput` writes only after the buffer reaches `flushBlockBytes`. `setLen 0` reuses the same allocation.

**Road split.** Each case separates toll-free roads from paid roads.

```nim
for _ in 0..<caseCount:
  let budget = nextInt(inputData, scanPos)
  let cityCount = nextInt(inputData, scanPos)
  let roadCount = nextInt(inputData, scanPos)
  let tollLevels = budget + 1

  var zeroHead = newSeq[int](cityCount)
  var zeroNext = newSeq[int](roadCount)
  var zeroDest = newSeq[int](roadCount)
  var zeroLength = newSeq[int](roadCount)
  var paidSource = newSeq[int](roadCount)
  var paidDest = newSeq[int](roadCount)
  var paidLength = newSeq[int](roadCount)
  var paidToll = newSeq[int](roadCount)
  var zeroCount = 0
  var paidCount = 0
  for cityIndex in 0..<cityCount:
    zeroHead[cityIndex] = -1

  for roadIndex in 0..<roadCount:
    let sourceCity = nextInt(inputData, scanPos) - 1
    let destCity = nextInt(inputData, scanPos) - 1
    let roadLength = nextInt(inputData, scanPos)
    let roadToll = nextInt(inputData, scanPos)
    if roadToll == 0:
      zeroDest[zeroCount] = destCity
      zeroLength[zeroCount] = roadLength
      zeroNext[zeroCount] = zeroHead[sourceCity]
      zeroHead[sourceCity] = zeroCount
      zeroCount += 1
    else:
      paidSource[paidCount] = sourceCity
      paidDest[paidCount] = destCity
      paidLength[paidCount] = roadLength
      paidToll[paidCount] = roadToll
      paidCount += 1
```

`tollLevels` is the number of coin pages. `zeroHead` starts at -1, so each linked list ends cleanly. Every road is stored once in flat arrays.

**Tables.** One flat distance table and one reusable scratch row.

```nim
  var bestLengths = newSeq[int](cityCount * tollLevels)
  for slot in 0..<bestLengths.len:
    bestLengths[slot] = unreachableLength
  bestLengths[0] = 0

  var layerLengths = newSeq[int](cityCount)
  var settled = newSeq[bool](cityCount)
```

`bestLengths` has one slot per city and coin total. `layerLengths` is reused for every page. Initialization fills each slot with `unreachableLength`.

**Layer sweep.** Toll-free Dijkstra settles one coin page.

```nim
  for spentCoins in 0..budget:
    for cityIndex in 0..<cityCount:
      layerLengths[cityIndex] = bestLengths[cityIndex * tollLevels + spentCoins]
      settled[cityIndex] = false

    for _ in 0..<cityCount:
      var chosenCity = -1
      var chosenLength = unreachableLength
      for cityIndex in 0..<cityCount:
        if not settled[cityIndex] and layerLengths[cityIndex] < chosenLength:
          chosenLength = layerLengths[cityIndex]
          chosenCity = cityIndex
      if chosenCity < 0: break
      settled[chosenCity] = true
      var edgeIndex = zeroHead[chosenCity]
      while edgeIndex >= 0:
        let neighborCity = zeroDest[edgeIndex]
        let candidate = chosenLength + zeroLength[edgeIndex]
        if candidate < layerLengths[neighborCity]:
          layerLengths[neighborCity] = candidate
        edgeIndex = zeroNext[edgeIndex]

    for cityIndex in 0..<cityCount:
      bestLengths[cityIndex * tollLevels + spentCoins] = layerLengths[cityIndex]
```

The outer loop runs budget plus one times. Selection runs `cityCount` times, so one page costs O(cityCount squared plus zeroCount). The settled values return to `bestLengths` before paid roads read them.

**Paid roads.** Move candidate lengths into later pages.

```nim
    for roadIndex in 0..<paidCount:
      let nextCoins = spentCoins + paidToll[roadIndex]
      if nextCoins > budget: continue
      let fromSlot = paidSource[roadIndex] * tollLevels + spentCoins
      let baseLength = bestLengths[fromSlot]
      if baseLength >= unreachableLength: continue
      let toSlot = paidDest[roadIndex] * tollLevels + nextCoins
      let candidate = baseLength + paidLength[roadIndex]
      if candidate < bestLengths[toSlot]:
        bestLengths[toSlot] = candidate
```

`nextCoins` never exceeds `budget`. Each paid road is scanned once per page. A higher page keeps the smaller candidate.

**Answer and emit.** Pick the best coin total, then write one line.

```nim
  var answer = unreachableLength
  let targetBase = (cityCount - 1) * tollLevels
  for spentCoins in 0..budget:
    if bestLengths[targetBase + spentCoins] < answer:
      answer = bestLengths[targetBase + spentCoins]
  if answer >= unreachableLength:
    appendOutput("-1")
  else:
    appendOutput($answer)
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
```

The scan covers every `spentCoins` up to `budget`. A missing path emits `-1`. The last write covers the buffer tail.

## Complexity

The work splits into input, road setup, and one sweep per coin page.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Road split | one pass over `roadCount` roads | `roadCount` slots |
| Layer sweep | budget plus one times cityCount squared plus zeroCount | `cityCount` slots |
| Paid roads | budget plus one times `paidCount` | flat table |
| Output | one write per block | block buffer |

The sweep and the paid-road scan dominate every other phase.

| Measure | Big O |
|---|---|
| Time per case | O((budget + 1) * (cityCount * cityCount + roadCount)) |
| Space per case | O(cityCount * (budget + 1) + roadCount) |

Enumerating paths grows exponentially with city count, while the layered sweep stays polynomial.
