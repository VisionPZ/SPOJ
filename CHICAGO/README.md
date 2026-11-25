# CHICAGO — 106 miles to Chicago (SPOJ)

<https://www.spoj.com/problems/CHICAGO/>

## Problem

Each street in an undirected network has a success chance. Find the route from intersection 1 to intersection n with the highest overall chance. Print that chance as a percentage with exactly six digits after the decimal point.

Input: each case starts with n m, then m lines a b p. Here a and b are the endpoints. The value p is the street chance in percent. A line containing `0` ends the input.

Output: one line per case with the percentage, six digits after the decimal point, then ` percent`.

The bounds from the statement:

| Item | Bound |
|---|---|
| Intersections n | 2 to 100 |
| Streets m | 1 to n(n-1)/2 |
| Street chance p | 1 to 100 percent |
| Test cases | until a line containing 0 |
| Judge limit | 5000 ms, 1536 MB |

The small node cap drives the matrix design, while the case count drives bulk input and output.

The sample case:

```
5 7
5 2 100
3 5 80
2 3 70
2 1 50
3 4 90
4 1 85
3 1 70
0
```

```
61.200000 percent
```

## Idea

Multiply the success chances along a route, then keep the largest product you can reach. Think of a relay race: every handoff has a success chance, and the team picks the chain with the best overall chance.

The program uses a Dijkstra-style widest-path search. It settles one node at a time, taking the unsettled node with the largest current product. Each settled node scans all n nodes once, so a case costs about n squared comparisons plus its street lookups. Enumerating simple paths instead grows exponentially with n.

Takeaway: at most n settle steps produce the answer, and no path list is ever built.

## Why It Works

1. A route's overall chance is the product of its street chances, and every factor is at most 1.
2. Extending a route can only lower or keep its product, so cycles never help and an optimal route stays simple.
3. A settled node holds the largest unsettled product. Any later route to it passes an unsettled node and multiplies by at most 1, so its value is final.
4. A flat matrix stores each street at `fromNode * stride + toNode`, so a case needs no map or per-street object.

The terms used in the loop:

| Term | Meaning |
|---|---|
| `edgeProb` | chance of one street, stored in both directions |
| `bestProb` | largest product reaching a node from intersection 1 |
| `chosenProb` | product at the settled node |
| `candidateProb` | chosenProb multiplied by one street chance |
| `roundedUnits` | percentage scaled by one million before printing |

Every term is a plain number, so the loop needs no priority queue and no path storage.

A script trace of the sample case prints every improvement:

```
start: best = [0, 1.000000, 0, 0, 0, 0]
pick 1 with 100.0000 percent
  1 -> 2: 100.0000 x 50% = 50.0000, best[2] 0.0000 -> 50.0000
  1 -> 3: 100.0000 x 70% = 70.0000, best[3] 0.0000 -> 70.0000
  1 -> 4: 100.0000 x 85% = 85.0000, best[4] 0.0000 -> 85.0000
pick 4 with 85.0000 percent
  4 -> 3: 85.0000 x 90% = 76.5000, best[3] 70.0000 -> 76.5000
pick 3 with 76.5000 percent
  3 -> 2: 76.5000 x 70% = 53.5500, best[2] 50.0000 -> 53.5500
  3 -> 5: 76.5000 x 80% = 61.2000, best[5] 0.0000 -> 61.2000
pick 5 with 61.2000 percent
answer: 61.200000 percent
```

The last line equals the sample answer, via the route 1 -> 4 -> 3 -> 5.

## Code

**Constants and scanner.** These lines set the fixed sizes and parse tokens by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxNodeCount = 100
const stride = maxNodeCount + 1

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value
```

The four constants set the digit base, flush size, node cap, and row stride. The scanner skips non-digits, so the terminating zero cannot desync it. It builds each value from bytes and allocates no token string.

**Fixed-point printer.** This routine appends one perfectly formatted result line.

```nim
proc appendProbability(value: float, outputBuffer: var string) =
  let roundedUnits = int(value * 1000000.0 + 0.5)
  let wholePart = roundedUnits div 1000000
  let fractionPart = roundedUnits mod 1000000
  outputBuffer.add $wholePart
  outputBuffer.add '.'
  var divisor = 100000
  while divisor >= 1:
    outputBuffer.add chr(firstDigitValue + (fractionPart div divisor) mod 10)
    divisor = divisor div 10
  outputBuffer.add " percent\n"
```

Adding 0.5 rounds the scaled percentage to the nearest millionth. The divisor loop emits six digits, including leading zeros. The line lands in the shared buffer, never in a direct stream write.

**Tables and bulk read.** These lines hold the graph and load the whole input once.

```nim
var edgeProb: array[stride * stride, float]
var bestProb: array[stride, float]
var visited: array[stride, bool]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""
```

Three flat arrays cover at most 101 nodes and 10201 street slots. Every line is appended to `inputData`, so parsing is one later pass. The single `outputBuffer` survives across all cases.

**Driver.** The main loop settles nodes and flushes output in blocks.

```nim
while true:
  let nodeCount = nextInt(inputData, scanPos)
  if nodeCount == 0: break
  let streetCount = nextInt(inputData, scanPos)
  for index in 0 .. stride * stride - 1:
    edgeProb[index] = 0.0
  for streetIndex in 0 ..< streetCount:
    let fromNode = nextInt(inputData, scanPos)
    let toNode = nextInt(inputData, scanPos)
    let percent = nextInt(inputData, scanPos)
    let chance = float(percent) / 100.0
    let forwardIndex = fromNode * stride + toNode
    let reverseIndex = toNode * stride + fromNode
    if chance > edgeProb[forwardIndex]: edgeProb[forwardIndex] = chance
    if chance > edgeProb[reverseIndex]: edgeProb[reverseIndex] = chance
  for nodeIndex in 0 .. nodeCount:
    bestProb[nodeIndex] = 0.0
    visited[nodeIndex] = false
  bestProb[1] = 1.0
  for pickIndex in 0 ..< nodeCount:
    var chosenNode = 0
    var chosenProb = 0.0
    for nodeIndex in 1 .. nodeCount:
      if not visited[nodeIndex] and bestProb[nodeIndex] > chosenProb:
        chosenProb = bestProb[nodeIndex]
        chosenNode = nodeIndex
    if chosenNode == 0: break
    visited[chosenNode] = true
    if chosenNode == nodeCount: break
    for nodeIndex in 1 .. nodeCount:
      let edgeChance = edgeProb[chosenNode * stride + nodeIndex]
      if edgeChance > 0.0:
        let candidateProb = chosenProb * edgeChance
        if candidateProb > bestProb[nodeIndex]:
          bestProb[nodeIndex] = candidateProb
  appendProbability(bestProb[nodeCount] * 100.0, outputBuffer)
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
```

A zero node count ends the input, and the matrix is cleared once per case. Each street fills two symmetric slots using percent divided by 100. The inner loop settles at most n nodes and scans at most n candidates each. Block flushing caps memory, and the final write emits the tail.

## Complexity

Costs are per test case, with n capped at 100.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | one input string |
| Matrix clear | 10201 assignments | 81 KB |
| Settle loop | n squared comparisons plus street lookups | 101 products and flags |
| Output | one write per 256 KiB block | 256 KiB |

At the largest case, the loop performs about 10000 comparisons and 4950 street lookups.

The overall asymptotic bounds:

| Measure | Big O |
|---|---|
| Time | O(n^2 + m) per case, plus one pass over input bytes |
| Space | O(n^2), capped at 101 rows |

Enumerating simple paths takes factorial time in the worst case. The settle loop stays small at n = 100, so it scales where enumeration cannot.
