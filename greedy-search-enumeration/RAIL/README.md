# RAIL — Simplify the Railroad System (SPOJ)

<https://www.spoj.com/problems/RAIL/>

## Problem

Given a connected railroad map, delete every station with exactly two direct connections and keep correct distances between the stations that remain. A deleted station joins its two neighbors into one longer segment, so a chain can even become a segment from a station back to itself.

Input starts with the number of test cases, and each case is preceded by a blank line. A case starts with N and M, then M lines of two stations and a segment length. Output the number of remaining segments, then one line per segment as first station, second station, length, with the first station no greater than the second. Sort lines by first station, then second station, then length, and place one blank line between cases.

| item | bound |
|---|---|
| stations N | 1 to 2000 |
| segments M | 1 to 3000 |
| segment length | fits in a C int |
| judge limit | 1000 ms, 1536 MB |

The guarantee of at least two stations that are not degree two keeps every chain anchored.

Sample input:

```
2

3 2
1 2 1
2 3 1

4 4
1 2 1
2 3 2
3 4 3
4 2 1
```

Sample output:

```
1
1 3 2

2
1 2 1
2 2 6
```

## Idea

Think of each ordinary station as a bead on a string between two junctions, and simply add the string lengths when you remove the bead. Each surviving station starts one walk along its incident segments. The walk continues through degree-two stations and stops at the next surviving station. This costs one visit per station, while repeatedly rewriting the whole graph would cost far more. Keep the smallest segment for each walk and sort the result.

## Why It Works

1. A station with two connections lies on one path between two other stations.
2. Replacing that path with a direct segment preserves every shortest distance, because the path is the only route through the station.
3. Walking from a surviving station in a fixed direction therefore reaches another surviving station.
4. Each chain has two ends, so only the walk from the smaller end is kept; a chain that returns to one station is kept by comparing directed edge numbers.
5. Summing segment lengths along the walk gives the distance for the simplified segment.
6. Sorting the collected triples produces the required lexicographic order.

| term | meaning |
|---|---|
| `degreeCounts` | number of direct connections at each station |
| `accumulatedCost` | distance summed along one walk |
| `SimplifiedEdge` | one segment on the simplified map |
| `compareEdges` | ordering rule for first station, second station, then length |

The table lists the values that decide which walks become output lines.

A script trace of the second sample case shows the shrinking map:

```text
remove 3: join 2 and 4, length 2+3=5
remove 4: join 2 and 2, length 1+5=6
station 2 keeps its loop: the loop counts twice toward its degree
final edges: 1 2 1 and 2 2 6
```

The trace keeps station 2 because its loop contributes two connections, matching the sample.

## Code

**Input and scanning.** The hand reader loads all cases into one string.

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
```

Blank lines contain no digits and are skipped.
Every length is positive, so the scanner needs no minus branch.
All tokens are consumed from one input string.

**Output buffer.** One buffer collects every line of every case.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Writes happen only when the block fills.
This keeps large maps cheap to print.
A final write flushes any short tail.

**Segment records.** A record holds the two ends and the summed length.

```nim
type SimplifiedEdge = object
  firstNode: int
  secondNode: int
  pathCost: int64

proc compareEdges(leftEdge: SimplifiedEdge, rightEdge: SimplifiedEdge): int =
  if leftEdge.firstNode < rightEdge.firstNode:
    return -1
  if leftEdge.firstNode > rightEdge.firstNode:
    return 1
  if leftEdge.secondNode < rightEdge.secondNode:
    return -1
  if leftEdge.secondNode > rightEdge.secondNode:
    return 1
  if leftEdge.pathCost < rightEdge.pathCost:
    return -1
  if leftEdge.pathCost > rightEdge.pathCost:
    return 1
  return 0

proc mergeSortEdges(edgeList: var seq[SimplifiedEdge], helperList: var seq[SimplifiedEdge], leftBound: int, rightBound: int) =
  if rightBound - leftBound <= 1:
    return
  let middleIndex = (leftBound + rightBound) div 2
  mergeSortEdges(edgeList, helperList, leftBound, middleIndex)
  mergeSortEdges(edgeList, helperList, middleIndex, rightBound)
  var leftCursor = leftBound
  var rightCursor = middleIndex
  var writeCursor = leftBound
  while leftCursor < middleIndex and rightCursor < rightBound:
    if compareEdges(edgeList[leftCursor], edgeList[rightCursor]) <= 0:
      helperList[writeCursor] = edgeList[leftCursor]
      leftCursor += 1
    else:
      helperList[writeCursor] = edgeList[rightCursor]
      rightCursor += 1
    writeCursor += 1
  while leftCursor < middleIndex:
    helperList[writeCursor] = edgeList[leftCursor]
    leftCursor += 1
    writeCursor += 1
  while rightCursor < rightBound:
    helperList[writeCursor] = edgeList[rightCursor]
    rightCursor += 1
    writeCursor += 1
  for edgeIndex in leftBound .. rightBound - 1:
    edgeList[edgeIndex] = helperList[edgeIndex]
```

The comparator follows the statement field order exactly.
Merge sort avoids a library comparator and runs in O(M log M).
Lengths use int64 even though the statement allows a C int.

**Walking the chains.** Each surviving station walks each incident segment through degree-two stations.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let stationCount = nextInt(inputData, scanPos)
  let segmentCount = nextInt(inputData, scanPos)
  var headEdges = newSeq[int](stationCount + 1)
  for stationIndex in 1 .. stationCount:
    headEdges[stationIndex] = -1
  var edgeTargets = newSeq[int](2 * segmentCount)
  var edgeNexts = newSeq[int](2 * segmentCount)
  var edgeLengths = newSeq[int](2 * segmentCount)
  var degreeCounts = newSeq[int](stationCount + 1)
  var edgeCursor = 0
  for segmentIndex in 0 .. segmentCount - 1:
    let firstStation = nextInt(inputData, scanPos)
    let secondStation = nextInt(inputData, scanPos)
    let segmentLength = nextInt(inputData, scanPos)
    edgeTargets[edgeCursor] = secondStation
    edgeNexts[edgeCursor] = headEdges[firstStation]
    edgeLengths[edgeCursor] = segmentLength
    headEdges[firstStation] = edgeCursor
    degreeCounts[firstStation] += 1
    edgeCursor += 1
    edgeTargets[edgeCursor] = firstStation
    edgeNexts[edgeCursor] = headEdges[secondStation]
    edgeLengths[edgeCursor] = segmentLength
    headEdges[secondStation] = edgeCursor
    degreeCounts[secondStation] += 1
    edgeCursor += 1
  var resultEdges = newSeq[SimplifiedEdge]()
  for startStation in 1 .. stationCount:
    if degreeCounts[startStation] == 2:
      continue
    var scanEdge = headEdges[startStation]
    while scanEdge != -1:
      let startEdge = scanEdge
      scanEdge = edgeNexts[scanEdge]
      var travelEdge = startEdge
      var nextStation = edgeTargets[travelEdge]
      var accumulatedCost: int64 = int64(edgeLengths[travelEdge])
      while degreeCounts[nextStation] == 2:
        var departureEdge = -1
        var candidateEdge = headEdges[nextStation]
        while candidateEdge != -1:
          if candidateEdge != (travelEdge xor 1):
            departureEdge = candidateEdge
            break
          candidateEdge = edgeNexts[candidateEdge]
        travelEdge = departureEdge
        nextStation = edgeTargets[travelEdge]
        accumulatedCost = accumulatedCost + int64(edgeLengths[travelEdge])
      if startStation < nextStation or (startStation == nextStation and startEdge < travelEdge):
        var simplifiedEdge: SimplifiedEdge
        if startStation <= nextStation:
          simplifiedEdge.firstNode = startStation
          simplifiedEdge.secondNode = nextStation
        else:
          simplifiedEdge.firstNode = nextStation
          simplifiedEdge.secondNode = startStation
        simplifiedEdge.pathCost = accumulatedCost
        resultEdges.add simplifiedEdge
  var helperEdges = newSeq[SimplifiedEdge](resultEdges.len)
  mergeSortEdges(resultEdges, helperEdges, 0, resultEdges.len)
  appendOutput($(resultEdges.len))
  outputBuffer.add '\n'
  for edgeIndex in 0 .. resultEdges.len - 1:
    let simplifiedEdge = resultEdges[edgeIndex]
    appendOutput($(simplifiedEdge.firstNode) & " " & $(simplifiedEdge.secondNode) & " " & $(simplifiedEdge.pathCost))
    outputBuffer.add '\n'
  if caseIndex < caseCount - 1:
    appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Directed edges are paired, so the reverse of one edge is found with xor one.
Only one walk per chain passes the endpoint test.
A blank line separates cases and never follows the last case.

## Complexity

Each segment is visited a constant number of times, then the collected segments are sorted.

| phase | time | space |
|---|---|---|
| input read | one pass over segment tokens | one input string |
| adjacency build | one step per directed segment | two arrays per field |
| chain walks | one step per station and segment | result segment array |
| sort and output | M log M comparisons | helper segment array |

Walking and sorting dominate the run.

| measure | Big O |
|---|---|
| time per case | O(M log M) |
| space per case | O(N + M) |

Repeatedly deleting one station at a time and rescanning the whole map would cost far more.
Walking each chain once and sorting the results is the takeaway.
