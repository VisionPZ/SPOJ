# GIRTH — Lazy tourist guide (SPOJ)
<https://www.spoj.com/problems/GIRTH/>

## Problem

Every pair of points that is reasonable to walk directly forms an undirected edge. A reasonable tour is a simple cycle whose first and last point are the same. Find the shortest such cycle, and among all shortest cycles print the one whose point sequence is lexicographically smallest.

The first line gives the test count. Each test gives N points and M pairs, then M pairs A B with A < B. Print `Case #k: -1` when no cycle exists. Otherwise print `Case #k: t u1 u2 ... ut`, where t is the cycle length and u1 equals ut.

The bounds from the statement:

| Item | Bound |
|---|---|
| Points N | 1 ≤ N ≤ 1000 |
| Pairs M | 1 ≤ M ≤ 40000 |
| Judge time | 1000 ms |
| Judge memory | 1536 MB |

The search still runs one breadth-first pass per candidate root, but each pass stops early once the best cycle found so far cannot be beaten.

The sample case:

```
2
4 3
1 2
1 3
1 4
4 5
1 2
2 3
3 4
1 4
2 4
```

```
Case #1: -1
Case #2: 3 1 2 4 1
```

## Idea

Try each point as the smallest point of a cycle. Run a breadth-first search that only visits larger points, and use an edge joining two different search branches to close a cycle. Keep the shortest length seen so far. A cycle of length L needs search depth at most L/2. Once the best length is g, later searches stop at depth (g - 1) / 2. When a triangle is found, stop entirely: no shorter cycle exists. Then build the smallest tour greedily, always taking the lowest next point that still allows a shortest return.

## Why It Works

1. A breadth-first tree assigns each visited point a depth and one parent.
2. An edge joining two tree branches closes a cycle through the root; a parent check excludes tree edges.
3. On any cycle of length L, every point is at breadth-first depth at most L / 2 from the root. Therefore a search limited to depth (g - 1) / 2 still finds every cycle shorter than the current best g.
4. Roots are visited in increasing order and the best length updates only on strict improvement. Thus the root setting the final length is the smallest root achieving it.
5. Three is the smallest possible cycle length, so the whole scan can stop at a triangle.
6. A generation stamp marks visited points, so no array needs clearing between searches.
7. Greedy choice is safe: the lowest feasible next point gives the smallest prefix.

The main terms:

| Term | Meaning |
|---|---|
| `girth` | shortest cycle length seen so far, and finally the answer |
| `depthCap` | largest depth a search still needs to explore |
| `seenGeneration` | stamp that replaces clearing the distance array |
| `parentNode` | tree parent used to reject tree edges |
| `tour` | points of the lexicographically smallest cycle |

A script trace of the sample finds no cycle in case 1. In case 2 the first root finds length 3, so the scan stops and the tour is 1, 2, 4, then back to 1.

## Code

**Input buffer and scanner.**
```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const unreachable = 1 shl 29
const casePrefix = "Case #"

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```
One read pass fills the buffer. The scanner reads integers by index only.

**Adjacency build and sort.**
```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1..caseCount:
  let nodeCount = nextInt(inputData, scanPos)
  let edgeCount = nextInt(inputData, scanPos)
  var adjacent = newSeq[seq[int]](nodeCount + 1)
  for e in 0..<edgeCount:
    var firstNode = nextInt(inputData, scanPos)
    var secondNode = nextInt(inputData, scanPos)
    if firstNode > secondNode:
      swap(firstNode, secondNode)
    adjacent[firstNode].add(secondNode)
    adjacent[secondNode].add(firstNode)

  for node in 1..nodeCount:
    var k = 1
    while k < adjacent[node].len:
      let value = adjacent[node][k]
      var p = k - 1
      while p >= 0 and adjacent[node][p] > value:
        adjacent[node][p + 1] = adjacent[node][p]
        p -= 1
      adjacent[node][p + 1] = value
      k += 1
```
Neighbor lists are sorted so the greedy pass can scan in increasing order. Insertion sort avoids comparator quirks.

**Pruned cycle detection.**
```nim
  var distance = newSeq[int](nodeCount + 1)
  var parentNode = newSeq[int](nodeCount + 1)
  var seenGeneration = newSeq[int](nodeCount + 1)
  var queue = newSeq[int](nodeCount + 1)
  var generation = 0

  var girth = unreachable
  var startNode = 1

  for root in 1..nodeCount:
    if girth == 3:
      break
    var largerNeighbors = 0
    for neighbor in adjacent[root]:
      if neighbor > root:
        largerNeighbors += 1
    if largerNeighbors < 2:
      continue

    generation += 1
    let depthCap = if girth >= unreachable: nodeCount else: (girth - 1) div 2
    distance[root] = 0
    parentNode[root] = -1
    seenGeneration[root] = generation
    queue[0] = root
    var head = 0
    var tail = 1
    while head < tail:
      let current = queue[head]
      head += 1
      let currentDepth = distance[current]
      for neighbor in adjacent[current]:
        if neighbor <= root:
          continue
        if seenGeneration[neighbor] == generation:
          if parentNode[current] != neighbor and parentNode[neighbor] != current:
            let candidate = currentDepth + distance[neighbor] + 1
            if candidate < girth:
              girth = candidate
              startNode = root
          continue
        if currentDepth >= depthCap:
          continue
        seenGeneration[neighbor] = generation
        distance[neighbor] = currentDepth + 1
        parentNode[neighbor] = current
        queue[tail] = neighbor
        tail += 1
      if girth == 3:
        break

  appendOutput(casePrefix)
  appendOutput($(caseIndex))
  appendOutput(": ")

  if girth == unreachable:
    appendOutput("-1")
    outputBuffer.add '\n'
    continue
```
The depth cap keeps each search shallow after the first cycle is found. Edges between two already visited branches close a cycle; tree edges are skipped. Roots are handled in order, so the first root to set the final length is the one printed.

**Greedy tour and final write.**
```nim
  var used = newSeq[bool](nodeCount + 1)
  used[startNode] = true
  var tour = newSeq[int]()
  tour.add(startNode)

  for step in 0..<(girth - 1):
    let current = tour[tour.len - 1]
    let needed = girth - step - 1
    var chosen = -1
    for candidate in adjacent[current]:
      if candidate <= startNode or used[candidate]:
        continue
      generation += 1
      distance[candidate] = 0
      seenGeneration[candidate] = generation
      queue[0] = candidate
      var head = 0
      var tail = 1
      while head < tail:
        let here = queue[head]
        head += 1
        let hereDepth = distance[here]
        if hereDepth >= needed - 1:
          continue
        for neighbor in adjacent[here]:
          if neighbor <= startNode or used[neighbor]:
            continue
          if seenGeneration[neighbor] != generation:
            seenGeneration[neighbor] = generation
            distance[neighbor] = hereDepth + 1
            queue[tail] = neighbor
            tail += 1
      for neighbor in adjacent[startNode]:
        if (needed == 1 or neighbor != candidate) and not used[neighbor] and
           neighbor > startNode and seenGeneration[neighbor] == generation and
           distance[neighbor] == needed - 1:
          chosen = candidate
          break
      if chosen >= 0:
        break
    tour.add(chosen)
    used[chosen] = true

  appendOutput($(girth))
  for node in tour:
    appendOutput(" ")
    appendOutput($(node))
  appendOutput(" ")
  appendOutput($(startNode))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```
Each candidate is tested with a depth-limited search back toward the root. The tour is appended and flushed once.

## Complexity

Detection is worst-case O(N(N + M)), but the depth cap and the triangle stop make dense inputs cost about O(N + M). Construction uses at most g depth-limited searches.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Detection | O(N(N + M)) worst case, pruned in practice | four N-entry arrays |
| Construction | O(g(N + M)) searches | used flags and tour |
| Output | one write per 128 KiB block | block buffer |

Sorting each neighbor list costs O(M log M) once per test.

Big O uses N as the point count, M as the pair count and g as the girth.

| Measure | Big O |
|---|---|
| Time | O(N(N + M) + M log M) |
| Space | O(N + M) |

Enumeration of every simple cycle would be exponential. Breadth-first detection with a depth cap stays polynomial.
