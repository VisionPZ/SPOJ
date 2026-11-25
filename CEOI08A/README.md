<https://www.spoj.com/problems/CEOI08A/>

## Problem

Choose fence posts from the pre-drilled holes so the wire encloses trees at least cost; each post costs 20 and each tree left outside costs 111. Report that minimum cost, including the option of building no fence.

| item | bound |
|---|---|
| holes N | 3 to 100 |
| trees M | 1 to 100 |
| coordinates x, y | 0 to 1000 |
| geometry | no two positions coincide and no three are collinear |
| judge limit | 1000 ms, 1536 MB |

Wire is free, so a chosen set of posts is used as its convex hull; interior holes would add cost without enclosing more.

Sample input:

```
4 3
800 300
200 200
200 700
600 700
400 300
600 500
800 900
```

Sample output:

```
171
```

## Idea

Think of stretching a rubber band around a handful of nails: only the nails on the band need to be bought. Fix the lowest nail as an anchor and list the other holes by angle around it. A chain that always turns left stays convex, and each new edge adds exactly one fan triangle of trees.

The score 111 times enclosed trees minus 20 times posts turns cost minimization into score maximization.

Every convex polygon appears once, under its lowest-leftmost hole as the anchor.

## Why It Works

1. Replacing a chosen set of holes by its convex hull keeps all enclosed trees and uses no more posts.
2. The lowest-leftmost hole of a polygon has all other vertices in its upper half-plane.
3. Sorting by angle around that anchor gives the polygon's boundary order.
4. A fan from the anchor splits the polygon into disjoint triangles on consecutive vertex pairs.
5. A left turn at each new middle vertex keeps the chain convex and simple.
6. Scoring each triangle with 111 and each added post with -20 gives the total cost when subtracted from 111M.

| term | meaning |
|---|---|
| `candidateHoles` | holes above the anchor, ordered by angle |
| `triangleTrees` | trees inside the triangle on the anchor and two chain vertices |
| `chainScores` | best score for a convex chain ending in a pair of holes |
| `bestScore` | best score over every anchor and chain |

The sample's best polygon uses holes (200, 200), (800, 300) and (600, 700).

It encloses two trees, so the cost is 3 times 20 plus 111 equals 171.

## Code

**Input and scanning.** The reader loads holes and trees, then stops at one case.

```nim
const flushBlockBytes = 1 shl 17
const postCost = 20
const treeLoss = 111
const impossibleValue = -1000000000

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc crossAt(originX: int, originY: int, firstX: int, firstY: int, secondX: int, secondY: int): int =
  (firstX - originX) * (secondY - originY) - (firstY - originY) * (secondX - originX)

proc insideTriangle(firstX: int, firstY: int, secondX: int, secondY: int,
                    thirdX: int, thirdY: int, pointX: int, pointY: int): bool =
  let firstCheck = crossAt(firstX, firstY, secondX, secondY, pointX, pointY) >= 0
  let secondCheck = crossAt(secondX, secondY, thirdX, thirdY, pointX, pointY) >= 0
  let thirdCheck = crossAt(thirdX, thirdY, firstX, firstY, pointX, pointY) >= 0
  return firstCheck and secondCheck and thirdCheck
```

Cross products decide both angle order and triangle membership.

All coordinate arithmetic stays within 64-bit integers.

**Anchor setup.** Only holes above the anchor can form a polygon with it as lowest vertex.

```nim
let holeCount = nextInt(inputData, scanPos)
let treeCount = nextInt(inputData, scanPos)
var holeX = newSeq[int](holeCount + 1)
var holeY = newSeq[int](holeCount + 1)
var treeX = newSeq[int](treeCount + 1)
var treeY = newSeq[int](treeCount + 1)
for holeIndex in 1 .. holeCount:
  holeX[holeIndex] = nextInt(inputData, scanPos)
  holeY[holeIndex] = nextInt(inputData, scanPos)
for treeIndex in 1 .. treeCount:
  treeX[treeIndex] = nextInt(inputData, scanPos)
  treeY[treeIndex] = nextInt(inputData, scanPos)

var bestScore = 0
for anchorHole in 1 .. holeCount:
  var candidateHoles = newSeq[int](holeCount)
  var candidateCount = 0
  for holeIndex in 1 .. holeCount:
    if holeY[holeIndex] > holeY[anchorHole] or
       (holeY[holeIndex] == holeY[anchorHole] and holeX[holeIndex] > holeX[anchorHole]):
      candidateHoles[candidateCount] = holeIndex
      candidateCount += 1
  if candidateCount < 2:
    continue

  for sortIndex in 1 .. candidateCount - 1:
    let heldHole = candidateHoles[sortIndex]
    var shiftIndex = sortIndex - 1
    while shiftIndex >= 0:
      let earlierHole = candidateHoles[shiftIndex]
      let orientation = crossAt(holeX[anchorHole], holeY[anchorHole],
                                holeX[earlierHole], holeY[earlierHole],
                                holeX[heldHole], holeY[heldHole])
      if orientation > 0:
        break
      candidateHoles[shiftIndex + 1] = earlierHole
      shiftIndex -= 1
    candidateHoles[shiftIndex + 1] = heldHole
```

Insertion sort replaces a generic comparator and uses the cross product directly.

A positive cross means the held hole comes later around the anchor.

**Triangle counts.** Each pair of candidate holes defines one fan triangle.

```nim
  var triangleTrees = newSeq[seq[int]](candidateCount)
  for rowIndex in 0 .. candidateCount - 1:
    triangleTrees[rowIndex] = newSeq[int](candidateCount)
  for firstIndex in 0 .. candidateCount - 2:
    for secondIndex in firstIndex + 1 .. candidateCount - 1:
      let firstHole = candidateHoles[firstIndex]
      let secondHole = candidateHoles[secondIndex]
      var enclosedTrees = 0
      for treeIndex in 1 .. treeCount:
        if insideTriangle(holeX[anchorHole], holeY[anchorHole],
                          holeX[firstHole], holeY[firstHole],
                          holeX[secondHole], holeY[secondHole],
                          treeX[treeIndex], treeY[treeIndex]):
          enclosedTrees += 1
      triangleTrees[firstIndex][secondIndex] = enclosedTrees
```

A tree inside a fan triangle is inside the polygon.

No collinear positions means a tree never lies on a triangle side.

**Convex chain DP.** Each transition adds one triangle and one post.

```nim
  var chainScores = newSeq[seq[int]](candidateCount)
  for rowIndex in 0 .. candidateCount - 1:
    chainScores[rowIndex] = newSeq[int](candidateCount)
    for columnIndex in 0 .. candidateCount - 1:
      chainScores[rowIndex][columnIndex] = impossibleValue
  for firstIndex in 0 .. candidateCount - 2:
    for secondIndex in firstIndex + 1 .. candidateCount - 1:
      let addedScore = treeLoss * triangleTrees[firstIndex][secondIndex] - 3 * postCost
      var bestHere = addedScore
      let middleHole = candidateHoles[firstIndex]
      let lastHole = candidateHoles[secondIndex]
      for previousIndex in 0 .. firstIndex - 1:
        let previousHole = candidateHoles[previousIndex]
        let turn = crossAt(holeX[previousHole], holeY[previousHole],
                           holeX[middleHole], holeY[middleHole],
                           holeX[lastHole], holeY[lastHole])
        if turn > 0 and chainScores[previousIndex][firstIndex] > impossibleValue:
          let extendedScore = chainScores[previousIndex][firstIndex] +
                              treeLoss * triangleTrees[firstIndex][secondIndex] - postCost
          if extendedScore > bestHere:
            bestHere = extendedScore
      chainScores[firstIndex][secondIndex] = bestHere
      if bestHere > bestScore:
        bestScore = bestHere

appendOutput($(treeLoss * treeCount - bestScore))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A three-hole polygon starts with a score of 111 times its trees minus 60.

A left turn permits extending a chain by one more hole.

The final subtraction converts the best score back into cost.

## Complexity

Each anchor sorts once, counts one triangle per pair, and fills one score table.

| phase | time | space |
|---|---|---|
| anchor sorting | N insertions of up to N holes | one candidate list |
| triangle counts | N squared pairs times M trees | one pair table |
| chain DP | N cubed turn checks per anchor | one score table |

| measure | Big O |
|---|---|
| time | O(N^3 M) worst case |
| space | O(N^2) |

Trying every subset of holes would need exponential time.

Angle order and fan triangles reduce the search to cubic time.
