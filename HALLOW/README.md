# HALLOW — Halloween treats (SPOJ)

<https://www.spoj.com/problems/HALLOW/>

## Problem

Children know how many sweets each neighbor gives and want a subset whose total divides evenly.
Find such neighbors, or report that none exists, for every test case.

Each case starts with `c n`, the number of children and neighbors, where `1 ≤ c ≤ n ≤ 100000`.
The next line holds `n` sweet counts, each from 1 to 100000.
A line `0 0` ends the input.
Print indices of one valid subset on one line, or `no sweets`.
Any valid subset is accepted.

| Item | Bound |
|---|---|
| Children c | 1 to 100000 |
| Neighbors n | c to 100000 |
| Sweets per neighbor | 1 to 100000 |
| Judge limit | 2235 ms, 1536 MB |

Each printed child must receive at least one sweet, so the chosen total is positive and divisible by `c`.

Sample input:

```
4 5
1 2 3 7 5
3 6
7 11 2 5 13 17
0 0
```

Sample output:

```
3 5
2 3 4
```

## Idea

Think of a row of prefix totals and two matching remainders, like two identical marks on a ruler.
The sweets between those marks form a block whose sum is divisible by the number of children.
Track the first position for each remainder and stop at the first repeated mark.
One pass over the neighbors finds the block, and printing its indices costs one more pass.

## Why It Works

1. Let P(i) be the sum of the first i sweet counts.
2. The sum between positions left and right equals P(right) minus P(left).
3. That difference is divisible by `c` exactly when both prefix sums have the same remainder.
4. A prefix sum with remainder zero pairs with the empty prefix, giving a block starting at neighbor 1.
5. There are n prefix sums and only c remainders, and n is at least c, so a repeat always exists.
6. Scanning right to left in index order picks the earliest ending position and its earliest partner.
7. The resulting block has at least one neighbor, so every child gets at least one sweet.

| Term | Meaning |
|---|---|
| `runningRemainder` | prefix sum remainder modulo the child count |
| `firstSeenAt` | first neighbor index seen for each remainder |
| `firstNeighbour` | first index of the chosen block |
| `lastNeighbour` | last index of the chosen block |

For the first sample case, the prefix remainders are 1, 3, 2, 1, 2.
The remainder 2 repeats at positions 3 and 5, so the block from neighbor 4 to 5 works.
The statement prints another valid subset, neighbor 3 and neighbor 5.
Both totals divide by 4, and the judge accepts either.

A case with one child ends at the first neighbor.
No rounding or floating-point arithmetic appears in this solution.

## Code

**Input and hand scanner.** The reader loads all text once and parses integers without library calls.

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

proc hasDigits(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len:
    if data[cursor] >= '0' and data[cursor] <= '9':
      return true
    cursor += 1
  return false
```

`hasDigits` detects the end of input.
`scanPos` advances past separators and digits.
The whole input stays in one string.

**Buffered answer loop.** Each case records the first repeated remainder, then prints that index range.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while hasDigits(inputData, scanPos):
  let childCount = nextInt(inputData, scanPos)
  let neighbourCount = nextInt(inputData, scanPos)
  if childCount == 0 and neighbourCount == 0:
    break
  var firstSeenAt = newSeq[int](childCount)
  for remainderIndex in 0 .. childCount - 1:
    firstSeenAt[remainderIndex] = -1
  var runningRemainder = 0
  var firstNeighbour = -1
  var lastNeighbour = -1
  for neighbourIndex in 1 .. neighbourCount:
    let sweets = nextInt(inputData, scanPos)
    runningRemainder = (runningRemainder + sweets) mod childCount
    if firstNeighbour == -1:
      if runningRemainder == 0:
        firstNeighbour = 1
        lastNeighbour = neighbourIndex
      elif firstSeenAt[runningRemainder] != -1:
        firstNeighbour = firstSeenAt[runningRemainder] + 1
        lastNeighbour = neighbourIndex
      else:
        firstSeenAt[runningRemainder] = neighbourIndex
  if firstNeighbour == -1:
    appendOutput("no sweets")
    outputBuffer.add '\n'
  else:
    var outputIndex = firstNeighbour
    while outputIndex <= lastNeighbour:
      appendOutput($outputIndex)
      if outputIndex == lastNeighbour:
        outputBuffer.add '\n'
      else:
        outputBuffer.add ' '
      outputIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0
```

Every sweet count is read even after a block is found.
`firstSeenAt` holds the earliest position for each remainder.
`appendOutput` flushes `stdout` only when the block buffer fills.

## Complexity

Each case reads every neighbor once and prints one chosen block.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over all sweet counts | one input string |
| Remainder scan | one step per neighbor | array of c positions |
| Output | one line per case | one block buffer |

| Measure | Big O |
|---|---|
| Time per case | O(n) |
| Space per case | O(c) |

Checking every subset would take exponential time and is not needed.
The remainder table turns the search into one linear scan.
