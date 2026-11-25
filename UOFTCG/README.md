<https://www.spoj.com/problems/UOFTCG/>

## Problem

Students sit in one row of desks. Two neighbouring students must be friends, and an empty desk separates each pair of groups. Find the fewest desks that seat every student.

Input starts with T. Each case gives N students and M friendships, followed by M pairs of friends. Output prints one minimum desk count per case.

| item | bound |
|---|---|
| test cases T | 1 to 50 |
| students N | up to 100000 |
| friendships M | up to N-1 |
| input file | at most 2 MB |
| judge limit | 2000 ms, 1536 MB |

Every subset of K students spans at most K-1 friendships. That condition makes the friendship graph a forest.

Sample input:

```
1
6 5
1 2
1 3
1 4
4 5
4 6
```

Sample output:

```
7
```

## Idea

A seating group is a path inside a tree, like linking train cars where each link must join two friends. One tree may need several paths when a student has too many friends. Remove the fewest edges until no student has more than two links, then count the resulting paths. A depth-first sweep finds those removals in one pass.

## Why It Works

1. A forest splits into components, each one tree.
2. A seating block is a path, so every student keeps at most two links inside blocks.
3. A student with degree d above 2 must lose at least d-2 friendship edges.
4. Removing one edge reduces the demand of both of its ends by one.
5. A child whose demand is not met must lose its edge to its parent.
6. Deleting that edge also helps the parent, so the sweep passes one unit upward.
7. A tree with one plus deletions paths uses its size plus one fewer desks.

| term | meaning |
|---|---|
| `degreeCount` | number of friends of each student |
| `passToParent` | one unit when the edge to the parent is removed |
| `deletionCount` | total removed edges in all trees |
| `componentCount` | number of friendship trees |
| `pathCount` | number of seating blocks, components plus deletions |
| `deskCount` | students plus blocks minus one |

In the sample, students 1 and 4 each have degree 3, so each must lose one edge. Removing edge 1-4 fixes both at once. Four friendship edges remain, so six students form two paths and need 6+2-1 = 7 desks. One valid seating is 2-1-3, empty, 5-4-6.

## Code

**Input and scanner.** The reader loads input once and parses each integer by hand.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc reverseArc(arc: int): int =
  if (arc mod 2) == 1:
    return arc + 1
  return arc - 1

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value
```

The scanner skips whitespace between pairs.
Each arc stores its target and the next arc.
Degrees count one unit per friendship.

**Tree traversal.** An iterative depth-first walk collects every component in order.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let studentCount = nextInt(inputData, scanPos)
  let friendshipCount = nextInt(inputData, scanPos)
  var firstArc = newSeq[int](studentCount + 1)
  var arcTarget = newSeq[int](2 * friendshipCount + 2)
  var nextArc = newSeq[int](2 * friendshipCount + 2)
  var degreeCount = newSeq[int](studentCount + 1)
  var arcCount = 0
  for edgeIndex in 0 .. friendshipCount - 1:
    let leftStudent = nextInt(inputData, scanPos)
    let rightStudent = nextInt(inputData, scanPos)
    arcCount += 1
    arcTarget[arcCount] = rightStudent
    nextArc[arcCount] = firstArc[leftStudent]
    firstArc[leftStudent] = arcCount
    arcCount += 1
    arcTarget[arcCount] = leftStudent
    nextArc[arcCount] = firstArc[rightStudent]
    firstArc[rightStudent] = arcCount
    degreeCount[leftStudent] += 1
    degreeCount[rightStudent] += 1
  var visited = newSeq[int](studentCount + 1)
  var parentVertex = newSeq[int](studentCount + 1)
  var parentArc = newSeq[int](studentCount + 1)
  var traversalOrder = newSeq[int](studentCount + 1)
  var stackNodes = newSeq[int](studentCount + 1)
  var orderSize = 0
  var componentCount = 0
  for startStudent in 1 .. studentCount:
    if visited[startStudent] != 0:
      continue
    componentCount += 1
    var stackTop = 0
    stackTop += 1
    stackNodes[stackTop] = startStudent
    visited[startStudent] = 1
    parentVertex[startStudent] = 0
    parentArc[startStudent] = 0
    while stackTop > 0:
      let currentStudent = stackNodes[stackTop]
      stackTop -= 1
      orderSize += 1
      traversalOrder[orderSize] = currentStudent
      var arc = firstArc[currentStudent]
      while arc != 0:
        let neighbor = arcTarget[arc]
        if parentArc[currentStudent] != 0 and arc == reverseArc(parentArc[currentStudent]):
          arc = nextArc[arc]
          continue
        if visited[neighbor] == 0:
          visited[neighbor] = 1
          parentVertex[neighbor] = currentStudent
          parentArc[neighbor] = arc
          stackTop += 1
          stackNodes[stackTop] = neighbor
        arc = nextArc[arc]
```

An explicit stack avoids deep recursion.
Each component adds one tree root.
The reverse arc is skipped during the walk.

**Deletion sweep.** Processing children before parents covers demands from the leaves upward.

```nim
  var passToParent = newSeq[int](studentCount + 1)
  var deletionCount = 0
  for orderIndex in countdown(orderSize, 1):
    let currentStudent = traversalOrder[orderIndex]
    var needed = degreeCount[currentStudent] - 2
    if needed < 0:
      needed = 0
    let covered = passToParent[currentStudent]
    if covered < needed:
      let deficit = needed - covered
      if parentVertex[currentStudent] != 0:
        deletionCount += deficit
        passToParent[parentVertex[currentStudent]] += 1
      else:
        deletionCount += deficit
  let pathCount = componentCount + deletionCount
  let deskCount = studentCount + pathCount - 1
  appendOutput($deskCount)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A deficit costs one deletion per missing unit.
A parent receives one unit when its edge is cut.
The final formula adds one empty desk between blocks.

## Complexity

The traversal visits each vertex and each friendship arc once.

| phase | time | space |
|---|---|---|
| read graph | one scan of all pairs | two arcs per friendship |
| depth-first walk | one visit per vertex and arc | order and stack arrays |
| deletion sweep | one step per vertex | one parent counter per student |

| measure | Big O |
|---|---|
| time per case | O(N + M) |
| space per case | O(N + M) |

Trying all edge subsets to find the best paths grows exponentially, while the sweep settles each edge once.
