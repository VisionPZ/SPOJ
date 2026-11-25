# ROMANRDS — Roman Roads (SPOJ)

<https://www.spoj.com/problems/ROMANRDS/>

## Problem

Given the adjacency of N roads, decide whether they can be the edges of a cheapest connected network, that is a tree. If yes, print YES and the two cities joined by each road. Otherwise print NO.

Road labels run from 1 to N. The i-th input line starts with the number of roads listed on road i's signpost, then those road labels. City labels may be any integers from 1 to the city count. Any labeling that describes a tree with the given line graph is accepted.

| item | bound |
|---|---|
| roads N | 1 to 500 |
| signpost entries | road labels, symmetric input |
| output | YES plus N edges, or NO |
| judge limit | 8614 ms, 1536 MB |

A city incident to several roads creates one complete group in the input graph.

Sample input:

```
3
2 3 2
2 1 3
2 2 1
```

Sample output:

```
YES
1 3
4 1
1 2
```

## Idea

Treat groups of mutually adjacent roads as cities, like gathering all spokes that meet at one hub. Each maximal group becomes one city, and each road joins the one or two cities whose groups contain it. The resulting graph must be a tree whose line graph matches the input. Testing every possible tree would explode with 500 roads; finding maximal groups and rebuilding the tree settles the map in polynomial time. The takeaway is that the groups are the cities.

## Why It Works

1. Roads meeting at one city form a clique in the given adjacency graph.
2. That clique is maximal for the city, since no other road meets all of them there.
3. Two roads share at most one city, so each road pair belongs to at most one clique.
4. A road joins the two cities whose cliques contain it, or one city if its other endpoint is a leaf.
5. A single-road network has two leaf cities and no clique.
6. The rebuilt graph must be connected, acyclic, and reproduce the given adjacency.

| term | meaning |
|---|---|
| `roadAdjacency` | sorted neighbours of each road in the input graph |
| `candidateCliques` | maximal groups of mutually adjacent roads |
| `memberships` | cliques containing each road |
| `cityEdges` | adjacency of the reconstructed city graph |
| `edgeEnds` | two city labels for each road |

Marking covered road pairs keeps clique discovery short for large groups.

A script trace of the sample gives these numbers:

```
one clique holds roads 1, 2, 3
three leaf cities, one for each road
four cities and three edges form a tree
answer YES
```

The script confirms the sample map is valid; city labels may differ between valid outputs.

## Code

**Input and scanner.** The reader loads the signpost lists and shifts labels to zero-based indices.

```nim
import algorithm

const flushBlockBytes = 1 shl 17
const noCity = -1

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

proc compareIntegers(left: int, right: int): int =
  if left < right:
    return -1
  elif left > right:
    return 1
  return 0

proc compareCliqueLists(left: seq[int], right: seq[int]): int =
  let sharedLength = min(left.len, right.len)
  for position in 0 .. sharedLength - 1:
    if left[position] != right[position]:
      return compareIntegers(left[position], right[position])
  return compareIntegers(left.len, right.len)
```

Road labels become array indexes after the shift.
The integer comparator sorts signpost lists.
The clique comparator fixes the city numbering.

**Output buffer and adjacency.** One buffer holds the decision and each edge line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let roadCount = nextInt(inputData, scanPos)
var roadAdjacency = newSeq[seq[int]](roadCount)
for roadIndex in 0 .. roadCount - 1:
  let neighbourCount = nextInt(inputData, scanPos)
  var neighbours = newSeq[int](neighbourCount)
  for neighbourIndex in 0 .. neighbourCount - 1:
    neighbours[neighbourIndex] = nextInt(inputData, scanPos) - 1
  sort(neighbours, compareIntegers)
  roadAdjacency[roadIndex] = neighbours

proc hasNeighbour(source: int, target: int): bool =
  let neighbours = roadAdjacency[source]
  var lowIndex = 0
  var highIndex = neighbours.len - 1
  while lowIndex <= highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if neighbours[middleIndex] < target:
      lowIndex = middleIndex + 1
    elif neighbours[middleIndex] > target:
      highIndex = middleIndex - 1
    else:
      return true
  return false
```

Sorted lists make neighbour tests logarithmic.
The buffer flushes at 131072 bytes.
No write happens per road.

**Clique discovery.** Each uncovered adjacent pair seeds one maximal group.

```nim
var candidateCliques = newSeq[seq[int]]()
var validMap = true
var coveredPairs = newSeq[bool](roadCount * roadCount)
for firstRoad in 0 .. roadCount - 1:
  for secondRoad in firstRoad + 1 .. roadCount - 1:
    if coveredPairs[firstRoad * roadCount + secondRoad]:
      continue
    if not hasNeighbour(firstRoad, secondRoad):
      continue
    var shared = newSeq[int]()
    var firstPos = 0
    var secondPos = 0
    while firstPos < roadAdjacency[firstRoad].len and secondPos < roadAdjacency[secondRoad].len:
      let leftValue = roadAdjacency[firstRoad][firstPos]
      let rightValue = roadAdjacency[secondRoad][secondPos]
      if leftValue == rightValue:
        shared.add(leftValue)
        firstPos += 1
        secondPos += 1
      elif leftValue < rightValue:
        firstPos += 1
      else:
        secondPos += 1
    shared.add(firstRoad)
    shared.add(secondRoad)
    sort(shared, compareIntegers)
    for firstMember in 0 .. shared.len - 1:
      for secondMember in firstMember + 1 .. shared.len - 1:
        if not hasNeighbour(shared[firstMember], shared[secondMember]):
          validMap = false
        coveredPairs[shared[firstMember] * roadCount + shared[secondMember]] = true
    candidateCliques.add(shared)

sort(candidateCliques, compareCliqueLists)
var cliques = newSeq[seq[int]]()
for candidate in candidateCliques:
  if cliques.len > 0 and compareCliqueLists(cliques[cliques.len - 1], candidate) == 0:
    continue
  cliques.add(candidate)

var memberships = newSeq[seq[int]](roadCount)
for cliqueIndex in 0 .. cliques.len - 1:
  for roadIndex in cliques[cliqueIndex]:
    memberships[roadIndex].add(cliqueIndex)
```

The intersection of two signpost lists gives one group.
Covered pairs are skipped after the first group.
Each road records the one or two cities it meets.

**Tree reconstruction.** Roads become city-to-city edges, then the tree is checked.

```nim
var cityCount = cliques.len
var cityEdges = newSeq[seq[int]](cityCount + roadCount + 2)
var edgeEnds = newSeq[tuple[firstCity: int, secondCity: int]](roadCount)
var buildValid = validMap
for roadIndex in 0 .. roadCount - 1:
  let membership = memberships[roadIndex]
  if membership.len == 2:
    let firstCity = membership[0]
    let secondCity = membership[1]
    edgeEnds[roadIndex] = (firstCity, secondCity)
    cityEdges[firstCity].add(secondCity)
    cityEdges[secondCity].add(firstCity)
  elif membership.len == 1:
    let firstCity = membership[0]
    let secondCity = cityCount
    cityCount += 1
    edgeEnds[roadIndex] = (firstCity, secondCity)
    cityEdges[firstCity].add(secondCity)
    cityEdges[secondCity].add(firstCity)
  else:
    if roadCount != 1:
      buildValid = false
    else:
      edgeEnds[roadIndex] = (0, 1)
      cityCount = 2
      cityEdges[0].add(1)
      cityEdges[1].add(0)

if cityCount != roadCount + 1:
  buildValid = false

if buildValid:
  var visited = newSeq[bool](cityCount)
  var stack = newSeq[tuple[city: int, parent: int]]()
  visited[0] = true
  stack.add((0, noCity))
  while stack.len > 0:
    let frame = stack[stack.len - 1]
    stack.setLen(stack.len - 1)
    for neighbour in cityEdges[frame.city]:
      if neighbour == frame.parent:
        continue
      if visited[neighbour]:
        buildValid = false
      visited[neighbour] = true
      stack.add((neighbour, frame.city))
  for cityIndex in 0 .. cityCount - 1:
    if not visited[cityIndex]:
      buildValid = false
```

A road with one group gets a fresh leaf city.
A single road gets two cities and no group.
The walk rejects cycles and disconnected cities.

**Final check and output.** The rebuilt line graph must equal the input.

```nim
if buildValid:
  for firstRoad in 0 .. roadCount - 1:
    for secondRoad in firstRoad + 1 .. roadCount - 1:
      let firstEnds = edgeEnds[firstRoad]
      let secondEnds = edgeEnds[secondRoad]
      let shareCity = firstEnds.firstCity == secondEnds.firstCity or
                      firstEnds.firstCity == secondEnds.secondCity or
                      firstEnds.secondCity == secondEnds.firstCity or
                      firstEnds.secondCity == secondEnds.secondCity
      let claimedAdjacent = hasNeighbour(firstRoad, secondRoad)
      if shareCity != claimedAdjacent:
        buildValid = false

if not buildValid:
  appendOutput("NO\n")
  stdout.write outputBuffer
  outputBuffer.setLen 0
else:
  appendOutput("YES\n")
  for roadIndex in 0 .. roadCount - 1:
    appendOutput($(edgeEnds[roadIndex].firstCity + 1) & " " & $(edgeEnds[roadIndex].secondCity + 1) & "\n")
  stdout.write outputBuffer
  outputBuffer.setLen 0
```

The check compares every road pair with its signpost entry.
Labels shift back to one-based form on output.
The final write emits the buffered lines.

## Complexity

Clique discovery dominates for dense signpost lists.

| phase | time | space |
|---|---|---|
| input read | one pass over signpost entries | adjacency lists |
| clique discovery | O(N squared) pair checks | covered-pair matrix |
| reconstruction | O(N) city edges | city adjacency |
| verification | O(N squared) road pairs | edge ends |

The covered-pair matrix keeps each group discovered once.

| measure | Big O |
|---|---|
| time | O(N squared) |
| space | O(N squared) |

Enumerating all trees on N+1 cities would take far longer.
The clique view settles the map in quadratic time.
