# POLYGAME — The Game of Polygons (SPOJ)
<https://www.spoj.com/problems/POLYGAME/>

## Problem

A convex polygon is cut into triangles, one of them black. Players alternate removing a triangle along a given diagonal. Whoever removes the black triangle wins.

Determine whether the first player has a winning strategy.

Input: the first integer is t, the number of cases; cases are separated by a blank line. Each case gives n vertices, then n − 2 triangles; the first triangle is black. Output: `YES` or `NO` per case.

These are the bounds and the judge limits:

| Item | Bound |
| --- | --- |
| Test cases t | from the input |
| Vertices n | 4 to 50000 |
| Triangles | n − 2, first is black |
| Vertex numbering | 0 to n − 1, clockwise |
| Time limit | 7000 ms |
| Memory limit | 1536 MB |

The sample uses a hexagon with four triangles:

```
1
6
0 1 2
2 4 3
4 2 0
0 5 4
```

```
YES
```

The black triangle has one neighbor, so the first player removes it at once.

## Idea

Check how exposed the black triangle is, then use parity. Picture a Jenga tower. If the target block sits on the outside, take it now. Otherwise the number of remaining blocks decides who gets the last move.

The dual graph of a triangulation is a tree: each triangle is a node, and an edge joins two triangles sharing a diagonal. Cutting a triangle removes a leaf of that tree. The black triangle can be cut only when it has at most one neighbor left.

The program counts triangles sharing two vertices with the black triangle. If that count is at most one, the first player wins immediately. Otherwise the answer is `YES` exactly when n is even.

Counting shared vertices costs O(n) per case. Searching the game tree would take exponential time.

Takeaway: one neighbor count plus vertex parity decides the whole game.

## Why It Works

Four facts prove the rule.

1. The dual graph of a triangulation with n vertices has n − 2 nodes and is a tree. Two triangles are neighbors when they share a diagonal, which means they share two vertices.
2. A legal cut removes a leaf of the dual tree. The black triangle is removable exactly when its degree falls to one or zero.
3. If black starts with degree 0 or 1, it is already a leaf. The first player cuts it on the first move and wins.
4. If black has degree at least two, players remove white leaves from the branches around it. The winner is set by parity. An odd count of white triangles, n − 3, gives the first player the win. That happens when n is even.

These are the values used in the decision:

| Term | Meaning |
| --- | --- |
| `vertexCount` | n, the number of polygon vertices |
| `triangleCount` | n − 2, the number of triangles |
| `blackFirst`, `blackSecond`, `blackThird` | corners of the black triangle |
| `sharedCount` | corners a white triangle shares with black |
| `blackDegree` | number of dual neighbors of the black triangle |

A script inspects the sample case:

```
black neighbors: 1
non-black triangles: 3
answer: YES
```

Triangle (4, 2, 0) shares the diagonal (0, 2) with black triangle (0, 1, 2). With one neighbor, black is a leaf and the first player wins.

## Code

**Input.** One buffer holds the cases, and the scanner skips blank lines.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value
```

The scanner treats the blank separator between cases like any other whitespace. No triangle list is stored. Cost is one pass over the input bytes.

**Output.** Answers gather in a block-flushed buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The flush triggers every `flushBlockBytes` bytes. No write happens inside the triangle loop. The cost is one pass over the answer text.

**Driver.** Each case counts black's neighbors and applies the rule.

```nim
let caseCount = nextInt(inputData, scanPos)
for i in 0..<caseCount:
  let vertexCount = nextInt(inputData, scanPos)
  let triangleCount = vertexCount - 2
  let blackFirst = nextInt(inputData, scanPos)
  let blackSecond = nextInt(inputData, scanPos)
  let blackThird = nextInt(inputData, scanPos)
  var blackDegree = 0
  for j in 1..<triangleCount:
    var sharedCount = 0
    for k in 0..<3:
      let vertex = nextInt(inputData, scanPos)
      if vertex == blackFirst or vertex == blackSecond or vertex == blackThird:
        sharedCount += 1
    if sharedCount >= 2:
      blackDegree += 1
  if blackDegree <= 1 or vertexCount mod 2 == 0:
    appendOutput("YES\n")
  else:
    appendOutput("NO\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop starts at j = 1 because triangle 0 is black. Two shared corners identify a diagonal, so `sharedCount >= 2` marks a neighbor. The whole case needs O(n) input reads and no stored graph.

## Complexity

Reading triangles is the only work.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(total tokens) | O(input size) |
| Neighbor count | O(n) | O(1) |
| Decision | O(1) | O(1) |
| Output | O(cases) | O(block size) |

Each case costs O(n) time and O(1) working space.

| Measure | Big O |
| --- | --- |
| Time per case | O(n) |
| Total time | O(sum of n over cases) |
| Working space | O(1) |

Searching the game tree would take exponential time in the number of triangles.
