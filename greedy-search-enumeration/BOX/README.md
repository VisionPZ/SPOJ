# BOX — Boxes (Hard) (SPOJ)

<https://www.spoj.com/problems/BOX/>

## Problem

Balls sit in boxes arranged in a circle, with at most one ball per box allowed at the end. Move one ball to a neighboring box per step and minimize the total number of steps.

Input starts with the test count. Each test has `n` and then `n` counts, one per box. The count sum never exceeds `n`.

Output one minimum-step count per test case.

| item | bound |
|---|---|
| test cases | 19 for the small file, 3 for the large file |
| box count n | up to 1000 small, up to 200000 large |
| total balls | at most n |
| judge limit | 100 ms small file, 2000 ms large file |

The ball count bound gives every ball a distinct final box.

Sample input:

```
1
12
0 0 2 4 3 1 0 0 0 0 0 1
```

Sample output:

```
19
```

## Idea

Give each source box one ball that stays put, like reserving one seat for each group. Every extra ball then joins its group by expanding the group's occupied block one box at a time.

The algorithm is a greedy block expansion. For each extra ball, try extending its block left and right. Pick the side whose full assignment costs less.

Rescanning all assignments for every candidate set would be exponential. The greedy step decides locally with an exact global cost check.

## Why It Works

1. Balls from one source always occupy one contiguous block of boxes.
2. The first ball of a source stays at its own box, so a block always exists.
3. An extra ball extends its block by one box on one side.
4. Extending shifts intervening balls by one step toward the free box.
5. Comparing both full assignment costs picks the cheaper legal extension.
6. Circular distance is the shorter of the direct gap and its complement.

| term | meaning |
|---|---|
| `spareBalls` | extra balls still waiting at a source box |
| `assignment` | source label stored in each final box |
| `shiftBlockLeft` | candidate that extends a block anticlockwise |
| `arrangementCost` | total circular distance for one assignment |

A worked example with the sample data:

```
initial kept balls: boxes 2, 3, 4, 5, 11
extra balls: 1 at box 2, 3 at box 3, 2 at box 4
final owners by box: 2, 3, 3, 3, 3, 4, 4, 4, 5, empty, 11, 2
total circular distance: 19
```

Every source occupies one block, and the one empty box is box 9.

## Code

**Input and buffered output.** The whole input is read once; answers go to one buffer.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner ignores all spacing between counts.
The buffer flushes after reaching the block threshold.
Only the final flush is needed for the small answers here.

**Cost and shifts.** Distance uses the shorter way around the circle.

```nim
proc circularDistance(boxCount: int, firstBox: int, secondBox: int): int =
  let direct = abs(firstBox - secondBox)
  if direct < boxCount - direct:
    return direct
  return boxCount - direct

proc arrangementCost(boxCount: int, assignment: seq[int]): int64 =
  var total: int64 = 0
  for boxIndex in 0 .. boxCount - 1:
    if assignment[boxIndex] >= 0:
      total += int64(circularDistance(boxCount, boxIndex, assignment[boxIndex]))
  return total

proc shiftBlockLeft(boxCount: int, sourceBox: int, leftmostBox: int,
                    assignment: seq[int]): seq[int] =
  var shifted = assignment
  var displaced = sourceBox
  var cursor = leftmostBox
  while true:
    cursor = (cursor + boxCount - 1) mod boxCount
    swap(shifted[cursor], displaced)
    if displaced == -1:
      break
  return shifted

proc shiftBlockRight(boxCount: int, sourceBox: int, rightmostBox: int,
                     assignment: seq[int]): seq[int] =
  var shifted = assignment
  var displaced = sourceBox
  var cursor = rightmostBox
  while true:
    cursor = (cursor + 1) mod boxCount
    swap(shifted[cursor], displaced)
    if displaced == -1:
      break
  return shifted
```

A shift stops at the first empty final box.
Each swapped owner moves one position toward that gap.
The cost sum stays in 64-bit integers for large circles.

**Greedy placement.** Each spare ball compares the two legal extensions.

```nim
let testCount = nextInt(inputData, scanPos)

for testIndex in 0 .. testCount - 1:
  let boxCount = nextInt(inputData, scanPos)
  var spareBalls = newSeq[int](boxCount)
  var assignment = newSeq[int](boxCount)
  for boxIndex in 0 .. boxCount - 1:
    let ballCount = nextInt(inputData, scanPos)
    assignment[boxIndex] = -1
    if ballCount > 0:
      spareBalls[boxIndex] = ballCount - 1
      assignment[boxIndex] = boxIndex

  for sourceBox in 0 .. boxCount - 1:
    while spareBalls[sourceBox] > 0:
      spareBalls[sourceBox] -= 1
      var leftmostBox = sourceBox
      while assignment[leftmostBox] != sourceBox:
        leftmostBox = (leftmostBox + 1) mod boxCount
      while assignment[(leftmostBox + boxCount - 1) mod boxCount] == sourceBox:
        leftmostBox = (leftmostBox + boxCount - 1) mod boxCount

      var rightmostBox = sourceBox
      while assignment[rightmostBox] != sourceBox:
        rightmostBox = (rightmostBox + boxCount - 1) mod boxCount
      while assignment[(rightmostBox + 1) mod boxCount] == sourceBox:
        rightmostBox = (rightmostBox + 1) mod boxCount

      let leftPlan = shiftBlockLeft(boxCount, sourceBox, leftmostBox, assignment)
      let rightPlan = shiftBlockRight(boxCount, sourceBox, rightmostBox, assignment)
      if arrangementCost(boxCount, leftPlan) <= arrangementCost(boxCount, rightPlan):
        assignment = leftPlan
      else:
        assignment = rightPlan

  appendOutput($(arrangementCost(boxCount, assignment)))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The first ball of each nonempty source stays at its own box.
The searches wrap around the circle to find block ends.
Ties choose the left extension, which keeps the result deterministic.

## Complexity

Each spare ball builds two candidate assignments and scores both.

| phase | time | space |
|---|---|---|
| input read | one pass over n counts | one input string |
| block search | one walk per spare ball | assignment array |
| scoring | one pass over n boxes | two candidate arrays |
| output | one line per test | block buffer |

The cost of one spare ball grows with n, and there are at most n spare balls.

| measure | Big O |
|---|---|
| time | O(n k) for k spare balls, at most O(n^2) |
| space | O(n) |

Enumerating all placements of k balls into n boxes would be exponential, while block expansion settles each ball one at a time.
