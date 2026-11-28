# NITTROAD — Roads of NITT (SPOJ)

<https://www.spoj.com/problems/NITTROAD/>

## Problem

A tree of hostels loses edges one at a time. After each removal, a query asks how many unordered pairs of hostels have no path between them. The answer follows from the sizes of the current connected components.

Input starts with the test count. Each test gives N, then the N-1 roads with their numbers, then Q. Each query is either `Q` alone or `R x`, where x is a road number that is removed. Print one answer line per `Q` query and a blank line after each test case.

| item | bound |
|---|---|
| test cases | up to 5 |
| hostels N | up to 20000 |
| queries Q | up to 20000 |
| judge limit | 1000 ms, 1536 MB |

Sample input:

```
2

3
1 2
1 3
5
Q
R 1
Q
R 2
Q

4
1 2
1 3
1 4
7
Q
R 1
Q
R 2
Q
R 3
Q
```

Sample output:

```
0
2
3

0
3
5
6

```

## Idea

Read the story backwards, like rewinding a film to see a broken bridge rebuilt. Removal becomes union, so one pass of disjoint-set union answers all queries.

Store every query first and mark all roads that get removed. Start the union-find structure with the roads that remain at the end. Walking the queries in reverse adds back one road at each `R` step. The number of disconnected pairs is the total pairs minus the pairs inside components. Each union updates that inside-pair count by the product of the two component sizes.

## Why It Works

1. Removing an edge from a tree splits one component into two.
2. Reversing the query list turns every removal into a merge.
3. A union of components of sizes p and q adds p times q connected pairs.
4. The total pairs of N hostels is N times N-1 divided by two.
5. Disconnected pairs equal total pairs minus connected pairs after each step.

| term | meaning |
|---|---|
| `parentNode` | parent pointer of each hostel in the union-find tree |
| `componentSize` | hostel count of each component root |
| `connectedPairs` | pairs that share a component |
| `removedEdge` | mark for roads removed by some query |

Take the first sample. Initially all three hostels are separate, so all three pairs are disconnected. Removing road 1 leaves hostels 1 and 3 joined, so the count drops to two. Removing road 2 leaves three single hostels, so the count reaches three.

The blank line after each test case is printed from the same buffer as the answers. No work depends on the query order once the removals are known.

## Code

**Input and scanner.** The reader loads stdin once. A second scanner finds the letter that starts each query.

```nim
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

proc nextQueryKind(data: string, pos: var int): int =
  while pos < data.len and data[pos] != 'Q' and data[pos] != 'R':
    pos += 1
  if pos < data.len:
    if data[pos] == 'R':
      result = 1
    else:
      result = 0
    pos += 1
```

The query scanner returns zero for `Q` and one for `R`. The road number follows only an `R`.

**Buffered output and union-find.** The union step updates the connected-pair count at every merge.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var parentNode: seq[int]
var componentSize: seq[int]

proc findRoot(node: int): int =
  var current = node
  while parentNode[current] != current:
    parentNode[current] = parentNode[parentNode[current]]
    current = parentNode[current]
  return current

var connectedPairs: int64 = 0

proc uniteNodes(firstNode, secondNode: int) =
  var firstRoot = findRoot(firstNode)
  var secondRoot = findRoot(secondNode)
  if firstRoot == secondRoot:
    return
  if componentSize[firstRoot] < componentSize[secondRoot]:
    let swapRoot = firstRoot
    firstRoot = secondRoot
    secondRoot = swapRoot
  parentNode[secondRoot] = firstRoot
  connectedPairs += int64(componentSize[firstRoot]) * int64(componentSize[secondRoot])
  componentSize[firstRoot] += componentSize[secondRoot]
```

Path compression keeps each find nearly constant. Union by size keeps the trees shallow.

**Driver.** The test case is stored first, then solved backwards and printed forwards.

```nim
let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let hostelCount = nextInt(inputData, scanPos)
  var edgeFirst = newSeq[int](hostelCount)
  var edgeSecond = newSeq[int](hostelCount)
  for edgeNumber in 1 .. hostelCount - 1:
    edgeFirst[edgeNumber] = nextInt(inputData, scanPos)
    edgeSecond[edgeNumber] = nextInt(inputData, scanPos)
  let queryCount = nextInt(inputData, scanPos)
  var queryKind = newSeq[int](queryCount)
  var queryEdge = newSeq[int](queryCount)
  var removedEdge = newSeq[bool](hostelCount)
  for queryIndex in 0 .. queryCount - 1:
    queryKind[queryIndex] = nextQueryKind(inputData, scanPos)
    if queryKind[queryIndex] == 1:
      queryEdge[queryIndex] = nextInt(inputData, scanPos)
      removedEdge[queryEdge[queryIndex]] = true
  parentNode = newSeq[int](hostelCount + 1)
  componentSize = newSeq[int](hostelCount + 1)
  for hostel in 1 .. hostelCount:
    parentNode[hostel] = hostel
    componentSize[hostel] = 1
  connectedPairs = 0
  for edgeNumber in 1 .. hostelCount - 1:
    if not removedEdge[edgeNumber]:
      uniteNodes(edgeFirst[edgeNumber], edgeSecond[edgeNumber])
  let totalPairs = int64(hostelCount) * int64(hostelCount - 1) div 2
  var answers = newSeq[int64](queryCount)
  var reverseIndex = queryCount - 1
  while reverseIndex >= 0:
    if queryKind[reverseIndex] == 0:
      answers[reverseIndex] = totalPairs - connectedPairs
    else:
      let edgeNumber = queryEdge[reverseIndex]
      uniteNodes(edgeFirst[edgeNumber], edgeSecond[edgeNumber])
    reverseIndex -= 1
  for queryIndex in 0 .. queryCount - 1:
    if queryKind[queryIndex] == 0:
      appendOutput($answers[queryIndex])
      outputBuffer.add '\n'
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Answers are stored at their original positions. The final blank line closes each test case.

## Complexity

Each road joins the initial structure once, and each query is visited twice.

| phase | time | space |
|---|---|---|
| parse test case | one pass over edges and queries | arrays of size N and Q |
| initial unions | N-1 union attempts | union-find arrays |
| reverse sweep | Q steps | one answer per query |
| output | one line per `Q` query | 128 KiB buffer |

| measure | Big O |
|---|---|
| time | O((N + Q) alpha(N)) per test case |
| space | O(N + Q) |

Recomputing connectivity by search at every query would cost O(NQ). The offline union sweep removes that repeated work.
