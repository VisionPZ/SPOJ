# BABTWR — Tower of Babylon (SPOJ)
<https://www.spoj.com/problems/BABTWR/>

## Problem

A museum stacks stone blocks into the tallest tower it can build, and each block can be turned three ways.
A block rests on another only when both sides of its base are shorter.

Each case starts with n block types, followed by n lines of height, width, and depth. A line with n=0 ends the input. Print one line with the tallest tower height.

The bounds and judge limits are:

| Constraint | Value |
| --- | --- |
| Block types n | up to 30 |
| Each dimension | at most 2500 |
| Input end | case with n = 0 |
| Judge time | 3 s |
| Judge memory | 1536 MB |

At most 90 orientations keep the quadratic dynamic program small.

The sample input and its expected output follow byte for byte.

```
5
31 41 59
26 53 58
97 93 23
84 62 64
33 83 27
1
1 1 1
0
```

```
342
1
```


## Idea

Turn each block into three orientations (choices of height axis) and sort them by base, like stacking plates from the widest base upward.
The program stores each orientation by its large base, its small base, and its height. Sorting puts the widest bases first, so every legal support appears earlier in the array.
For each orientation, the code scans earlier orientations with strictly larger bases and keeps the tallest chain. That costs O(n squared) with at most 90 items.
Trying every stack and rotation order is exponential, while one pass over sorted orientations settles each case.
Sorting by base turns stacking into a short dynamic program.

## Why It Works

1. Three orientations per block cover every choice of which dimension becomes the height.
2. Sorting by large base, then small base, places every legal support earlier in the array.
3. A block fits only when both stored base dimensions are strictly larger, which the comparison checks.
4. `towerHeight[i]` holds the best tower ending at orientation i, so each support is examined once.
5. The maximum entry is the tallest complete tower, since any stack ends somewhere in the array.

Four terms carry the proof.

| Term | Meaning |
| --- | --- |
| orientation | one block with a chosen height axis |
| base pair | large and small base side of an orientation |
| support | earlier orientation with a strictly larger base |
| tower height | best total height ending at an orientation |

They explain why one sorted scan finds the tallest stack.

A script check of the sample follows bases (97,93), (84,64), (64,62), (59,41), (41,31), and (33,27).
Their heights are 23, 62, 84, 31, 59, and 83.
The sum is 342, which matches the first sample answer.

## Code

**Orientation builder.**
```nim
proc buildOrientations(blockTypeCount: int) =
  var orientationCount = 0
  for i in 0 ..< blockTypeCount:
    let givenHeight = readInteger()
    let givenWidth = readInteger()
    let givenDepth = readInteger()
    baseLarge[orientationCount] = max(givenWidth, givenDepth)
    baseSmall[orientationCount] = min(givenWidth, givenDepth)
    blockHeight[orientationCount] = givenHeight
    inc orientationCount
    baseLarge[orientationCount] = max(givenHeight, givenDepth)
    baseSmall[orientationCount] = min(givenHeight, givenDepth)
    blockHeight[orientationCount] = givenWidth
    inc orientationCount
    baseLarge[orientationCount] = max(givenHeight, givenWidth)
    baseSmall[orientationCount] = min(givenHeight, givenWidth)
    blockHeight[orientationCount] = givenDepth
    inc orientationCount
```

The builder writes three orientations per block type. Each one picks a different height axis. The base pair always stores the larger side first.

**Base sort.**
```nim
proc sortOrientations(orientationCount: int) =
  for i in 1 ..< orientationCount:
    var j = i
    while j > 0:
      let k = j - 1
      let outOfOrder = baseLarge[k] < baseLarge[j] or
                       (baseLarge[k] == baseLarge[j] and baseSmall[k] < baseSmall[j])
      if not outOfOrder: break
      let largeValue = baseLarge[j]
      let smallValue = baseSmall[j]
      let heightValue = blockHeight[j]
      baseLarge[j] = baseLarge[k]
      baseSmall[j] = baseSmall[k]
      blockHeight[j] = blockHeight[k]
      baseLarge[k] = largeValue
      baseSmall[k] = smallValue
      blockHeight[k] = heightValue
      dec j
```

Insertion sort orders bases from widest to narrowest. The large side breaks ties before the small side. After this pass, every possible support sits earlier.

**Tallest chain dynamic program.**
```nim
proc tallestTower(orientationCount: int): int =
  var bestTower = 0
  for i in 0 ..< orientationCount:
    var bestBelow = 0
    for j in 0 ..< i:
      if baseLarge[j] > baseLarge[i] and baseSmall[j] > baseSmall[i]:
        if towerHeight[j] > bestBelow:
          bestBelow = towerHeight[j]
    towerHeight[i] = blockHeight[i] + bestBelow
    if towerHeight[i] > bestTower:
      bestTower = towerHeight[i]
  result = bestTower
```

The outer loop fixes one orientation as the top block. The inner loop keeps the best strictly larger support. The running maximum is the case answer.

**Input and output driver.**
```nim
loadInput()
while true:
  skipWhitespace()
  if i >= inputData.len: break
  let blockTypeCount = readInteger()
  if blockTypeCount == 0: break
  let orientationCount = blockTypeCount * orientationsPerType
  buildOrientations(blockTypeCount)
  sortOrientations(orientationCount)
  outputBuffer.add $tallestTower(orientationCount)
  outputBuffer.add '\n'
  flushOutput(false)
flushOutput(true)
```

The driver reads cases until it sees zero. Each case rebuilds the orientation arrays. A block flush emits all answers together.


## Complexity

The dynamic program is quadratic in the number of orientations, which is at most 90.

| Phase | Time | Space |
| --- | --- | --- |
| parsing and orientations | O(n) | three arrays |
| base sort | O(n squared) worst | constant extra |
| tallest chain | O(n squared) | one height array |

Unlimited copies still fit this model, because repeats cannot share a base size.

Big O uses block types n.

| Measure | Big O |
| --- | --- |
| time | O(n squared) per case |
| space | O(n) |

Enumerating stacks and rotations would grow far faster than this sorted scan.
