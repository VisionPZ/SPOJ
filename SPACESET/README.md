# SPACESET — Space settlement (SPOJ)

<https://www.spoj.com/problems/SPACESET/>

## Problem

A colony has m ring-shaped levels, each holding n settlements, with every settlement linked to all settlements on neighbouring levels. Count the routes that use exactly k stops, starting settlement included, modulo a fixed number.

The first input line holds the test count `T`. Each test line holds `m`, `n`, and `k` in that order. Print one line per test with the route count modulo 12345678.

The bounds from the statement:

| item | bound |
|---|---|
| tests T | 1 to 100 |
| levels m | 1 to 100000000 |
| settlements n | 1 to 100000000 |
| stops k | 1 to 100000 |
| judge limit | 5000 ms |

The top and bottom levels connect only when they differ, so m equals 1 has no cross-level routes.

Sample input:

```
5
1 1 1
1 2 1
3 3 56
4 3 4
691 60 97764
```

Sample output:

```
1
2
8019378
6144
470730
```

## Idea

Every settlement in the colony offers the same number of next stops, like a newsletter sent to an equal-size mailing list from each address. The total number of routes then multiplies by that same number at each of the k minus 1 moves.

The algorithm counts the outgoing stops at one settlement and raises that count to the power of k minus 1, then multiplies by the number of starting settlements. Modular exponentiation handles large exponents in logarithmic time.

A ring with one or two settlements offers one ring move; a larger ring offers two. Cross-level moves offer n choices for each neighbouring level, of which there are none, one, or two depending on m.

Walking the whole graph once per test would need m times n vertices, which is impossible at the stated bounds.

The uniform out-degree reduces each test to one short exponentiation.

## Why It Works

1. A route with k stops makes k minus 1 moves between settlements.
2. Each settlement has `ringMoves` ring choices and `levelNeighbors` neighbouring levels.
3. Each neighbouring level contributes n choices, so the out-degree is the ring moves plus those choices.
4. Every settlement has this same out-degree, so the walk count is the starting places times that degree raised to d.
5. With d equal to k minus 1 and arithmetic modulo 12345678, fast exponentiation gives the answer directly.

The main terms and formulas:

| term | meaning |
|---|---|
| `ringMoves` | ring choices at one settlement |
| `levelNeighbors` | count of distinct neighbouring levels |
| `baseMoves` | total choices at one settlement |
| `crossings` | k minus 1, the number of moves |

The table lists the three small cases that feed the power.

The gen.py oracle walks the explicit adjacency matrix on small graphs. On the fourth sample case it produces this trace:

```
m = 4, n = 3, k = 4 -> 3 moves
ringMoves = 2, levelNeighbors = 2, baseMoves = 2 + 6 = 8
starting places = 4 * 3 = 12, routes = 12 * 8 cubed = 6144
```

The trace matches the fourth line of the sample output.

## Code

**Input and scanner.** One read loads the tests, and the output buffer collects one line per test.

```nim
const flushBlockBytes = 1 shl 17
const moduloValue: int64 = 12345678

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

proc modPower(baseValue: int64, exponentValue: int64): int64 =
  var resultValue: int64 = 1
  var baseMod = baseValue mod moduloValue
  var exponentLeft = exponentValue
  while exponentLeft > 0:
    if exponentLeft mod 2 == 1:
      resultValue = (resultValue * baseMod) mod moduloValue
    baseMod = (baseMod * baseMod) mod moduloValue
    exponentLeft = exponentLeft div 2
  return resultValue
```

The modulus is typed as `int64` to keep products safe.
Squaring halves the exponent on every loop step.
The scanner skips line breaks between test values.

**Case loop.** Each test computes its out-degree and one power.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let levelCount = int64(nextInt(inputData, scanPos))
  let settlementCount = int64(nextInt(inputData, scanPos))
  let stopCount = int64(nextInt(inputData, scanPos))
  var ringMoves: int64 = 2
  if settlementCount <= 2:
    ringMoves = 1
  var levelNeighbors: int64 = 2
  if levelCount == 1:
    levelNeighbors = 0
  elif levelCount == 2:
    levelNeighbors = 1
  let baseMoves = (ringMoves + levelNeighbors * settlementCount) mod moduloValue
  let crossings = stopCount - 1
  let startingPlaces = ((levelCount mod moduloValue) * (settlementCount mod moduloValue)) mod moduloValue
  let routeCount = (startingPlaces * modPower(baseMoves, crossings)) mod moduloValue
  appendOutput($routeCount)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

One level removes cross-level travel entirely.
Two levels meet only once, so they count as one neighbour.
One buffered write emits all test answers.

## Complexity

Each test uses one exponentiation with a binary exponent, independent of the graph size.

| phase | time | space |
|---|---|---|
| input read | one pass over T triples | one input string |
| out-degree setup | constant work per test | a few integers |
| exponentiation | logarithmic in k multiplications | a few integers |
| output | one line per test | block buffer |

The exponentiation dominates the work per test.

The overall asymptotic bounds:

| measure | Big O |
|---|---|
| time | O(T log k) |
| space | O(1) beyond the input string |

Walking every settlement for every stop would cost O(k times m times n) time.

The degree shortcut keeps all tests fast even at the maximum bounds.
