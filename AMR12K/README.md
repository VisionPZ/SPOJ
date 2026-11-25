<https://www.spoj.com/problems/AMR12K/>

## Problem

Soldiers form a tree rooted at soldier 1, and some are dead. Input gives the test count, superior links and dead labels; output the expected number of saved roll-calls per test. Answers allow an error below `1e-6`.
| item | bound |
|---|---|
| tests | 1 to 5 |
| soldiers per test | 1 to 100000 |
| dead labels | 0 to N |
| judge limit | 1000 ms, 1536 MB |

A skipped soldier is never marked dead, even when that soldier is dead.

Sample input:

```
2
2
1 2
1
1
2
1 2
1
2
```

Sample output:

```
0.5
0
```

## Idea

A random order makes each soldier equally likely to be first among its dead ancestors and itself, like drawing one name from a hat. So the chance of being checked is one over that set's size. Sum the complement over all soldiers to get the expected saves.

Count dead ancestors once per soldier with a tree walk. Each soldier contributes one division, so the work stays linear. Checking all orders instead needs factorials.

The expectation reduces to one count per soldier.

## Why It Works

1. For a soldier, the dead strict ancestors plus the soldier form a chain in the tree.
2. The earliest member of that chain in the random order is always checked.
3. That checked member is dead, so every later member of the chain is skipped.
4. A uniform random order makes each chain member equally likely to be earliest.
5. The checked probability is therefore one over the chain size.
6. Summing `count / (count + 1)` over soldiers gives the expected saves.

| term | meaning |
|---|---|
| `isDead` | flag indexed by soldier label |
| `deadAncestors` | number of dead strict ancestors of a soldier |
| `expectedSaves` | accumulated expectation for one test |
| `formatResult` | prints six decimals, then trims trailing zeros |

Take two soldiers with soldier 1 dead. Soldier 1 has zero dead ancestors and contributes zero. Soldier 2 has one dead ancestor and contributes `1/2`.

The sample prints `0.5` because trailing zeros are removed. The judge accepts either spelling within `1e-6`.

## Code

**Input and output helpers.** The reader loads all tokens through one scanner.

```nim
import strutils

const flushBlockBytes = 1 shl 17

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

proc formatResult(value: float): string =
  let text = formatFloat(value, ffDecimal, 6)
  var lastIndex = text.len - 1
  while lastIndex >= 0 and text[lastIndex] == '0':
    lastIndex -= 1
  if lastIndex >= 0 and text[lastIndex] == '.':
    lastIndex -= 1
  return text[0 .. lastIndex]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Every number is read from one string.
`formatResult` keeps six decimals where needed.
The buffer flushes only when it grows large.

**Tree walk.** An explicit stack visits every soldier once from the root.

```nim
let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let orcCount = nextInt(inputData, scanPos)
  var headEdges = newSeq[int](orcCount + 1)
  var toNodes = newSeq[int](2 * orcCount)
  var nextEdges = newSeq[int](2 * orcCount)
  for edgeIndex in 0 .. orcCount:
    headEdges[edgeIndex] = -1
  var edgePos = 0
  for pairIndex in 0 .. orcCount - 2:
    let firstOrc = nextInt(inputData, scanPos)
    let secondOrc = nextInt(inputData, scanPos)
    toNodes[edgePos] = secondOrc
    nextEdges[edgePos] = headEdges[firstOrc]
    headEdges[firstOrc] = edgePos
    edgePos += 1
    toNodes[edgePos] = firstOrc
    nextEdges[edgePos] = headEdges[secondOrc]
    headEdges[secondOrc] = edgePos
    edgePos += 1
  let deadCount = nextInt(inputData, scanPos)
  var isDead = newSeq[bool](orcCount + 1)
  for deadIndex in 0 .. deadCount - 1:
    let deadOrc = nextInt(inputData, scanPos)
    isDead[deadOrc] = true
  var deadAncestors = newSeq[int](orcCount + 1)
  var visitedOrcs = newSeq[bool](orcCount + 1)
  var walkNodes = newSeq[int](orcCount)
  var walkCounts = newSeq[int](orcCount)
  var walkSize = 0
  walkNodes[walkSize] = 1
  walkCounts[walkSize] = 0
  visitedOrcs[1] = true
  walkSize += 1
  while walkSize > 0:
    walkSize -= 1
    let currentOrc = walkNodes[walkSize]
    let ancestorCount = walkCounts[walkSize]
    deadAncestors[currentOrc] = ancestorCount
    var childCount = ancestorCount
    if isDead[currentOrc]:
      childCount += 1
    var edgePointer = headEdges[currentOrc]
    while edgePointer != -1:
      let childOrc = toNodes[edgePointer]
      if not visitedOrcs[childOrc]:
        visitedOrcs[childOrc] = true
        walkNodes[walkSize] = childOrc
        walkCounts[walkSize] = childCount
        walkSize += 1
      edgePointer = nextEdges[edgePointer]
```

Adjacency arrays store the superior links.
A visited flag prevents walking back up each edge.
The carried count equals the dead ancestors of the parent.

**Expectation and output.** One division per soldier builds the answer.

```nim
  var expectedSaves: float = 0.0
  for orcLabel in 1 .. orcCount:
    let ancestorCount = deadAncestors[orcLabel]
    expectedSaves = expectedSaves + float(ancestorCount) / float(ancestorCount + 1)
  appendOutput(formatResult(expectedSaves))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop follows label order for stable rounding.
A single flush emits every test result.

## Complexity

Each test reads its links once and visits each soldier once.

| phase | time | space |
|---|---|---|
| input read | one pass over tokens | one input string |
| adjacency build | two entries per link | two edge arrays |
| tree walk | one visit per soldier | stack and flags |
| expectation | one division per soldier | one result value |

| measure | Big O |
|---|---|
| time | O(N) per test |
| space | O(N) |

Enumerating all orders would need O(N!) time and fail for large armies.

The chain rule turns a probability question into a single tree walk.
