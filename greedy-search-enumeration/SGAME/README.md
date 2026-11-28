<https://www.spoj.com/problems/SGAME/>

## Problem

Given an undirected set of lines and a starting point, decide whether every line can be traced once from that point and back to it without lifting the pencil. Print YES when such a closed trail exists, and NO otherwise.

| item | bound |
|---|---|
| test cases t | 1 to 100 |
| point index n | 1 to 300 |
| line endpoints i, j | 1 to 300, i not equal to j |
| terminator | -1 -1 |
| judge limit | 100 ms, 1536 MB |

All listed lines must be used, and none may be retraced.

Sample input:

```
1
1
1 2
1 4
2 3
2 5
2 6
3 6
4 7
5 6
6 7
-1 -1
```

Sample output:

```
YES
```

## Idea

Think of a post carrier who must walk every street once and end at the depot. Each crossing needs one arrival and one departure, so every city degree must be even, and all streets must belong to the depot's connected group. Union-find tracks the groups while the degree counter checks arrivals against departures.

A single odd degree kills the route, as does a street in another component.

The start must touch at least one street when streets exist.

## Why It Works

1. A closed trail enters and leaves each visited city the same number of times.
2. Hence every vertex with a line has an even degree.
3. Consecutive lines share a vertex, so all used vertices form one connected group.
4. Union-find merges the endpoints of each line, giving that group for free.
5. The start vertex must lie in the same group as every used vertex.

| term | meaning |
|---|---|
| `vertexDegrees` | number of lines touching each point |
| `groupParent` | union-find parent for each point |
| `startVertex` | required start and end point |
| `edgeTotal` | number of listed lines in the case |

The sample has nine lines and all degrees even, so the answer is YES.

A single line gives degree one at both ends, so the answer is NO.

## Code

**Input and scanning.** The reader keeps the minus sign so the -1 -1 terminator is visible.

```nim
const flushBlockBytes = 1 shl 17
const maxVertexIndex = 300

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner treats a leading minus as a sign, not as junk.

One string holds the input; another holds the answers.

**Union-find.** Path compression keeps group lookups short.

```nim
var groupParent = newSeq[int](maxVertexIndex + 1)
var vertexDegrees = newSeq[int](maxVertexIndex + 1)

proc findGroup(vertexHere: int): int =
  var walkVertex = vertexHere
  while groupParent[walkVertex] != walkVertex:
    groupParent[walkVertex] = groupParent[groupParent[walkVertex]]
    walkVertex = groupParent[walkVertex]
  return walkVertex

proc joinGroups(firstVertex: int, secondVertex: int) =
  let firstRoot = findGroup(firstVertex)
  let secondRoot = findGroup(secondVertex)
  if firstRoot != secondRoot:
    groupParent[secondRoot] = firstRoot
```

Each point starts as its own group at the beginning of a case.

Merging endpoints while reading avoids a second pass over the lines.

**Case driver.** The degree and group checks decide the answer.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let startVertex = nextInt(inputData, scanPos)
  for vertexIndex in 0 .. maxVertexIndex:
    groupParent[vertexIndex] = vertexIndex
    vertexDegrees[vertexIndex] = 0
  var edgeTotal = 0
  while true:
    let edgeStart = nextInt(inputData, scanPos)
    let edgeEnd = nextInt(inputData, scanPos)
    if edgeStart == -1 and edgeEnd == -1:
      break
    vertexDegrees[edgeStart] += 1
    vertexDegrees[edgeEnd] += 1
    joinGroups(edgeStart, edgeEnd)
    edgeTotal += 1

  var drawable = true
  if edgeTotal > 0 and vertexDegrees[startVertex] == 0:
    drawable = false
  if drawable:
    for vertexIndex in 1 .. maxVertexIndex:
      if vertexDegrees[vertexIndex] > 0:
        if vertexDegrees[vertexIndex] mod 2 != 0:
          drawable = false
          break
        if findGroup(vertexIndex) != findGroup(startVertex):
          drawable = false
          break
  if drawable:
    appendOutput("YES")
  else:
    appendOutput("NO")
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Reading stops at the pair -1 -1, not at end of line.

All answer lines leave in one final flush.

## Complexity

Each line adds one union and two degree increments.

| phase | time | space |
|---|---|---|
| input read | one pass over lines | one input string |
| union-find | one merge per line | one parent array |
| validation | one scan over 300 points | one degree array |

| measure | Big O |
|---|---|
| time | O(total lines + 300 per case) |
| space | O(300) |

Searching every trail by backtracking would grow factorially with the line count.

Two linear checks settle the question instead.
