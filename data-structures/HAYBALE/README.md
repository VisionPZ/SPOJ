# HAYBALE — Haybale stacking (SPOJ)
<https://www.spoj.com/problems/HAYBALE/>

## Problem

N stacks start empty, and K instructions each add one bale to every stack in an inclusive range. Report the median of the final stack heights, with N odd.

Input starts with N and K. The next K lines each hold two integers A and B with 1 ≤ A ≤ B ≤ N. Output the median height on one line.

| item | bound |
|---|---|
| stacks N | 1 to 1000000, odd |
| instructions K | 1 to 25000 |
| range endpoints | 1 to N |
| judge limit | 1000 ms, 1536 MB |

Stack heights never exceed K, because each instruction adds at most one bale to a stack.

Sample input:

```
7 4
5 5
2 4
4 6
3 5
```

Sample output:

```
1
```

## Idea

A range add is like marking the start and end of a fence segment, then walking the fence once to count planks.

The algorithm uses a difference array. For each instruction, increment the start and decrement the position after the end. One prefix pass recovers every height, and a histogram indexed by height finds the median without sorting.

A direct simulation touches up to N stacks per instruction, costing O(NK). The difference array touches two entries per instruction and costs O(N + K).

Build the histogram while scanning heights, then read cumulative counts until the middle rank is reached.

## Why It Works

1. Adding one at the range start and subtracting one after the range end encodes one instruction.
2. The prefix sum at stack i equals the number of instructions covering stack i.
3. Every stack is visited once, so all heights are known after one pass.
4. The median is the height at rank `N div 2 + 1` in sorted order.
5. Cumulative histogram counts locate that rank in increasing height order.

| term | meaning |
|---|---|
| `heightChanges` | difference array of range events |
| `currentHeight` | prefix sum, the height of one stack |
| `heightFrequency` | count of stacks at each height |
| `middleRank` | one-based position of the median |

The histogram index never exceeds K, so its size stays small.

For the sample the final heights are 0, 1, 2, 3, 3, 1, 0. Sorted, they are 0, 0, 1, 1, 2, 3, 3.

| height | stacks at that height | cumulative count |
|---|---|---|
| 0 | 2 | 2 |
| 1 | 2 | 4 |
| 2 | 1 | 5 |
| 3 | 2 | 7 |

With N = 7 the middle rank is 4, and the first cumulative count reaching 4 belongs to height 1.

All heights fit in a 32-bit integer, but the arrays are indexed by position, so bounds come from N + 2 and K + 1. No rounding occurs anywhere.

## Code

**Input and output setup.** The reader loads all instruction tokens, and the writer flushes in blocks.

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

The scanner skips line breaks and spaces.
Each number is built digit by digit.
No negative input values appear in this problem.

**Range events and median.** Two events per instruction replace a full range walk.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let stackCount = nextInt(inputData, scanPos)
let instructionCount = nextInt(inputData, scanPos)
var heightChanges = newSeq[int](stackCount + 2)
for instructionIndex in 0 .. instructionCount - 1:
  let firstStack = nextInt(inputData, scanPos)
  let lastStack = nextInt(inputData, scanPos)
  heightChanges[firstStack] += 1
  heightChanges[lastStack + 1] -= 1
var heightFrequency = newSeq[int](instructionCount + 1)
var currentHeight = 0
for stackIndex in 1 .. stackCount:
  currentHeight += heightChanges[stackIndex]
  heightFrequency[currentHeight] += 1
let middleRank = stackCount div 2 + 1
var seenStacks = 0
var medianHeight = 0
for heightValue in 0 .. instructionCount:
  seenStacks += heightFrequency[heightValue]
  if seenStacks >= middleRank:
    medianHeight = heightValue
    break
appendOutput($medianHeight)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The event at `lastStack + 1` cancels the add after the range.
The prefix pass fills the histogram in one sweep.
The cumulative scan stops at the middle rank.

## Complexity

The prefix pass over N stacks dominates the two events per instruction.

| phase | time | space |
|---|---|---|
| input read | one pass over K pairs | one input string |
| difference pass | N prefix additions | array of N + 2 integers |
| histogram scan | up to K + 1 heights | array of K + 1 integers |
| output | one line | block buffer |

Each instruction changes exactly two difference entries.

| measure | Big O |
|---|---|
| time | O(N + K) |
| space | O(N + K) |

Replaying every range over its stacks would cost O(NK) and miss the 1000 ms limit.

The difference array and histogram reduce the work to one pass per stack, so large inputs stay fast.
