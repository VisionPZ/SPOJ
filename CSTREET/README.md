# CSTREET — Cobbled Streets (SPOJ)

<https://www.spoj.com/problems/CSTREET/>

## Problem

Pave the cheapest set of streets that keeps every main building reachable from every other one. The cost is the total paved length times the price per furlong.

The input starts with the test case count. Each case gives the price per furlong, the building count, the street count, then one line per street with its two endpoints and its length. Buildings are numbered from 1 to n, and the graph is connected.

The output holds one line per case: the price of the cheapest paving.

The bounds from the statement and judge page:

| Item | Bound |
|---|---|
| Test cases | 1 to 100 |
| Buildings n | 1 to 1000 |
| Streets m | 1 to 300000 |
| Street length and price | positive integers |
| Printed result | less than 2^32 |
| Judge limit | 15 s, 1536 MB |

The building count stays small while the street count grows large, so per-building work beats sorting every street.

The sample case:

```
1
2
5
7
1 2 1
2 3 2
2 4 6
5 2 1
5 1 3
4 5 2
3 4 3
```

```
12
```

The chosen streets have total length 6, and price 2 gives 12.

## Idea

Grow the paved set one building at a time, always taking the nearest outside building. Think of spreading paint from one building: each new touch reaches the closest unpainted building through its shortest street.

This is dense Prim's algorithm for a minimum spanning tree. An array holds the shortest street from the painted set to each building. A linear scan picks the smallest entry, and the chosen building relaxes its own streets. Each case costs n scans of n buildings plus two relaxations per street.

Trying every set of streets is exponential, and even sorting all streets costs m log m comparisons. When n is 1000 and m is 300000, the dense scan does less work.

Takeaway: grow the tree one building at a time and leave the street list unsorted.

## Why It Works

Four facts carry the proof.

1. A spanning tree connects all n buildings with exactly n minus 1 streets and no cycle.
2. The shortest street that crosses from the painted set to an outside building is safe to add. This rule is the cut property.
3. `bestEdge` holds that shortest crossing street for every outside building, so one scan finds the next building.
4. A street is relaxed only when one of its endpoints joins the tree, so the total number of relaxations is 2m.

The terms used in the program:

| Term | Meaning |
|---|---|
| `bestEdge` | shortest street from the tree to one building |
| `firstEdge` | first entry of a building's street list |
| `edgeLink` | next entry in the same linked list |
| `edgeTarget` | building at the other end of a street |
| `treeLength` | sum of the chosen street lengths |
| `pavingPrice` | multiplier applied once after the tree is complete |

Every term maps to one flat array or one integer, with no per-street object.

A traced run on the sample graph:

```
start   best = 0 inf inf inf inf
pick 1 (0) total 0 best 0 1 inf inf 3 relax 2->1 5->3
pick 2 (1) total 1 best 0 1 2 6 1 relax 3->2 4->6 5->1
pick 5 (1) total 2 best 0 1 2 2 1 relax 4->2
pick 3 (2) total 4 best 0 1 2 2 1 relax -
pick 4 (2) total 6 best 0 1 2 2 1 relax -
price 2 * 6 = 12
```

The five picks add lengths 0, 1, 1, 2 and 2. Their sum is 6, and price 2 gives the sample answer 12.

## Code

**Constants and digit reader.** Scan one integer at a time from the shared input buffer.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  var parsedValue = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    parsedValue = parsedValue * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return parsedValue
```

`nextInt` moves `scanPos` past whitespace and builds each value one digit at a time. All values are positive, so no sign branch is needed. No token object or parse call is created.

**Street storage.** Store every street twice, once for each endpoint.

```nim
proc minimumTreeLength(buildingCount, streetCount: int, inputData: string, scanPos: var int): int64 =
  var firstEdge = newSeq[int](buildingCount + 1)
  for buildingIndex in 1..buildingCount:
    firstEdge[buildingIndex] = -1
  var edgeTarget = newSeq[int](2 * streetCount)
  var edgeWeight = newSeq[int](2 * streetCount)
  var edgeLink = newSeq[int](2 * streetCount)
  var edgeIndex = 0
  for streetIndex in 0..<streetCount:
    let fromBuilding = nextInt(inputData, scanPos)
    let toBuilding = nextInt(inputData, scanPos)
    let streetLength = nextInt(inputData, scanPos)
    edgeTarget[edgeIndex] = toBuilding
    edgeWeight[edgeIndex] = streetLength
    edgeLink[edgeIndex] = firstEdge[fromBuilding]
    firstEdge[fromBuilding] = edgeIndex
    edgeIndex += 1
    edgeTarget[edgeIndex] = fromBuilding
    edgeWeight[edgeIndex] = streetLength
    edgeLink[edgeIndex] = firstEdge[toBuilding]
    firstEdge[toBuilding] = edgeIndex
    edgeIndex += 1
```

The arrays are sized from `streetCount` once per case. `firstEdge` starts each building's list, and `edgeLink` chains the entries. Index 0 stays unused because buildings are numbered from 1.

**Tree growth.** Pick the nearest outside building and relax its streets.

```nim
  var bestEdge = newSeq[int](buildingCount + 1)
  var inTree = newSeq[bool](buildingCount + 1)
  for buildingIndex in 1..buildingCount:
    bestEdge[buildingIndex] = high(int) div 4
  bestEdge[1] = 0
  var treeLength = 0.int64
  for selectionStep in 0..<buildingCount:
    var chosenBuilding = 0
    var bestLength = high(int) div 4
    for buildingIndex in 1..buildingCount:
      if not inTree[buildingIndex] and bestEdge[buildingIndex] < bestLength:
        bestLength = bestEdge[buildingIndex]
        chosenBuilding = buildingIndex
    if chosenBuilding == 0: break
    inTree[chosenBuilding] = true
    treeLength += bestLength.int64
    var edgeCursor = firstEdge[chosenBuilding]
    while edgeCursor != -1:
      let neighborBuilding = edgeTarget[edgeCursor]
      if not inTree[neighborBuilding] and edgeWeight[edgeCursor] < bestEdge[neighborBuilding]:
        bestEdge[neighborBuilding] = edgeWeight[edgeCursor]
      edgeCursor = edgeLink[edgeCursor]
  return treeLength
```

The scan visits `buildingCount` entries on every pick. `bestEdge[1]` starts at zero, so building 1 joins first. `inTree` stops a building from being picked twice. The return passes `treeLength` to the price multiplication.

**Input and output buffers.** Read the whole stream, then write in large blocks.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add "\n"

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Every line is appended to one `inputData` string before parsing starts. `appendOutput` flushes after `flushBlockBytes` bytes and reuses the same allocation. One write per block keeps the output path off the per-number path.

**Driver.** Read one case, build its tree, then print the price.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let pavingPrice = nextInt(inputData, scanPos).int64
  let buildingCount = nextInt(inputData, scanPos)
  let streetCount = nextInt(inputData, scanPos)
  let treeLength = minimumTreeLength(buildingCount, streetCount, inputData, scanPos)
  appendOutput($(pavingPrice * treeLength))
  outputBuffer.add "\n"

stdout.write outputBuffer
outputBuffer.setLen 0
```

`caseCount` comes from the first token, and each case consumes three headers plus its streets. `pavingPrice` multiplies `treeLength` once, after the tree is complete. The last write flushes the tail, so the output always ends with a newline.

## Complexity

The cost splits into reading, tree growth and writing.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the lines, one digit pass per token | input bytes |
| Street storage | two writes per street | 6m integers |
| Tree growth | n scans of n buildings plus 2m relaxations | n integers |
| Output | one write per 128 KiB block | block buffer |

The largest case does about one million comparisons and 600000 relaxations per test case.

The overall asymptotic bounds:

| Measure | Big O |
|---|---|
| Time | O(n^2 + m) per case |
| Space | O(n + m) per case |

Kruskal's algorithm sorts the streets and costs O(m log m) per case, which is larger when m reaches 300000. Dense Prim keeps the work tied to the building count instead.
