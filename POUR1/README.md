## Problem

Read a case count, then three positive integers per case. The first two are the
capacities of the vessels. The third is the wanted amount. Print the fewest steps
that leave exactly that amount in either vessel. Print -1 when no sequence of
steps can reach it.

The bounds keep every number small.

| item | bound |
|---|---|
| test cases | at most 100 |
| capacity of each vessel | at most 40000 |
| wanted amount | at most 40000 |
| judge limit | 2 s, 1536 MB |

Both capacities fit in sixteen bits, and the case count stays tiny.

The sample uses capacities 5 and 2 with target 3, then capacities 2 and 3 with
target 4. The answers are 2 and -1. The output holds one answer per case.

## Idea

Two directed procedures cover the shortest answer. One keeps filling the left
vessel and pours it into the right vessel, and it empties the right vessel when
the right one fills. The other does the same with the vessels swapped. Each
fill, empty, and pour counts as one step. A full search over pairs of amounts
visits far more states than either walk.

Each simulated step costs a fixed handful of arithmetic operations. The step
count stays below twice the capacity sum divided by the greatest common
divisor.

## Why It Works

Three facts prove the program.

1. After every step, at least one vessel is full or empty. The start has both
   vessels empty, and each fill, empty, or pour keeps that property.
2. Both amounts stay multiples of the greatest common divisor of the
   capacities. The target must also be a multiple of that divisor, and it must
   fit in at least one vessel.
3. The directed walk reaches every reachable goal before it repeats. Every goal
   sits on that boundary, so the first visit gives the step count in that
   direction. The swapped walk covers the other direction. A shortest path
   keeps one direction, so the smaller first visit is the answer.

Two tests decide reachability before the simulation.

| test | meaning |
|---|---|
| target > larger capacity | no vessel can hold the wanted amount |
| target mod gcd != 0 | the target is not a multiple of the measurable unit |

A case that passes both tests always has an answer.

For capacities 7 and 3 with target 5, the left-first walk visits these states.

| step | first vessel | second vessel | action |
|---|---|---|---|
| 0 | 0 | 0 | fill first |
| 1 | 7 | 0 | pour 3 |
| 2 | 4 | 3 | empty second |
| 3 | 4 | 0 | pour 3 |
| 4 | 1 | 3 | empty second |
| 5 | 1 | 0 | pour 1 |
| 6 | 0 | 1 | fill first |
| 7 | 7 | 1 | pour 2 |
| 8 | 5 | 3 | goal |

The left walk reaches the target at step 8.

The swapped walk visits these states.

| step | first vessel | second vessel | action |
|---|---|---|---|
| 0 | 0 | 0 | fill first |
| 1 | 3 | 0 | pour 3 |
| 2 | 0 | 3 | fill first |
| 3 | 3 | 3 | pour 3 |
| 4 | 0 | 6 | fill first |
| 5 | 3 | 6 | pour 1 |
| 6 | 2 | 7 | empty second |
| 7 | 2 | 0 | pour 2 |
| 8 | 0 | 2 | fill first |
| 9 | 3 | 2 | pour 3 |
| 10 | 0 | 5 | goal |

The right walk reaches the target at step 10. The answer is 8.

## Code

The ceiling exceeds twice the largest possible capacity sum, so a reachable
target always appears before the loop stops. The block size keeps each write
near 128 KiB.

```nim
const flushBlockBytes = 1 shl 17
const stepCeiling = 1 shl 20
```

The gcd loop shrinks the pair until the smaller value reaches zero. The mod
operation gives the remainder, and Nim spells the remainder operation as mod.
The loop runs once per Euclidean division.

```nim
proc gcdOf(leftValue, rightValue: int): int =
  var larger = leftValue
  var smaller = rightValue
  while smaller != 0:
    var remainder = larger mod smaller
    larger = smaller
    smaller = remainder
  return larger
```

The walk stops at the target or at the step ceiling. The pour amount is the
smaller of the amount on hand and the room left in the other vessel. That
choice avoids a spill and keeps both amounts inside their capacities. Each
turn costs a few comparisons and additions.

```nim
proc stepsFor(firstCapacity, secondCapacity, target: int): int =
  var firstAmount = 0
  var secondAmount = 0
  var stepCount = 0
  while stepCount < stepCeiling:
    if firstAmount == target or secondAmount == target:
      return stepCount
    if firstAmount == 0:
      firstAmount = firstCapacity
    elif secondAmount == secondCapacity:
      secondAmount = 0
    else:
      var poured = firstAmount
      if secondCapacity - secondAmount < poured:
        poured = secondCapacity - secondAmount
      firstAmount = firstAmount - poured
      secondAmount = secondAmount + poured
    stepCount = stepCount + 1
  return -1
```

The scanner walks the input buffer by index and builds each integer from its
digits. It needs no sign branch because the spec gives only positive values.
Work grows with the number of input bytes.

```nim
proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ': scanPos = scanPos + 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - 48
    scanPos = scanPos + 1
  return value
```

The read loop collects whole lines into one buffer before scanning. The case
loop runs exactly caseCount times, and each turn appends one answer and a
newline. The flush guard writes a block when it fills, and the last write
emits the tail. The program uses one input buffer and one output buffer.

```nim
var inputData: string
var lineBuffer: string
while readLine(stdin, lineBuffer):
  inputData.add lineBuffer
  inputData.add "\n"
var scanPos = 0
var caseCount = nextInt(inputData, scanPos)
var outputBuffer: string
for caseIndex in 1 .. caseCount:
  var firstCapacity = nextInt(inputData, scanPos)
  var secondCapacity = nextInt(inputData, scanPos)
  var target = nextInt(inputData, scanPos)
  var answer: int
  if target > firstCapacity and target > secondCapacity:
    answer = -1
  elif target mod gcdOf(firstCapacity, secondCapacity) != 0:
    answer = -1
  else:
    var firstWay = stepsFor(firstCapacity, secondCapacity, target)
    var secondWay = stepsFor(secondCapacity, firstCapacity, target)
    if firstWay < 0 or secondWay < 0:
      answer = max(firstWay, secondWay)
    else:
      answer = min(firstWay, secondWay)
  outputBuffer.add $answer
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

## Complexity

| phase | time | space |
|---|---|---|
| input read | one pass over lines, then one pass over digits | input bytes |
| gcd and reachability | one Euclidean division per round | a few integers |
| one directed walk | one pass per step up to the ceiling | constant |
| output write | one write per 128 KiB block | one block |

The case count bounds the total work at one hundred times the per-case walk.

| measure | Big O |
|---|---|
| time | O(capacity sum / gcd) per case |
| space | O(input bytes) for the buffer, plus constant work space |

A breadth-first search stores every reachable pair of amounts, which costs
O(capacity sum) states and a queue for each case. The directed walks use no
state table and stop at the first visit.
