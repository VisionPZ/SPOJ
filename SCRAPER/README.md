## Problem

Read several skyscrapers. Each has floors numbered from zero, several elevators, and two floors named `A` and `B`. An elevator with step `X` and start `Y` stops at floors `Y`, `Y + X`, `Y + 2X`, and so on below the top floor. Decide whether a piece of furniture can travel from `A` to `B` using only elevators. Print one sentence per skyscraper.

| Quantity | Bound |
| --- | --- |
| Skyscrapers per file | about 2000 |
| Floors `F` | 1 to 49,999,999 |
| Elevators `E` | 1 to 99 |
| Time limit | 13000 ms |
| Memory limit | 1536 MB |

The floor count can be large, so the program never stores one entry per floor.

## Idea

Treat every elevator as a node in a small graph. Add an edge between two elevators when their lines meet on some floor below the top. Start from every elevator that serves floor `A`, then walk the graph. If a reached elevator serves floor `B`, the furniture can move.

Each pair of elevators is tested once with a congruence solver, so the cost per case is O(E²). Walking all floors instead would cost O(F · E).

## Why It Works

An elevator connects every pair of floors on its own line, in both directions. A trip is therefore a chain of elevators where consecutive lines share a floor. The graph captures exactly those chains.

Two lines meet when a floor `f` satisfies both `f = Y₁ + t₁X₁` and `f = Y₂ + t₂X₂`. This system has a solution only when `Y₂ - Y₁` is divisible by `gcd(X₁, X₂)`. When it is, the following steps build the smallest shared floor at least `max(Y₁, Y₂)`:

- divide both steps and the difference by the gcd
- solve `t ≡ (difference / gcd) · inverse(step₁ / gcd) (mod step₂ / gcd)`
- form `f = Y₁ + t · X₁`, then reduce it modulo `lcm(X₁, X₂)`
- add whole lcm cycles until `f` reaches the lower bound

The candidate is valid only when it stays below `F`. If `A` equals `B`, the answer is yes even with no elevators.

## Code

The program reads all input at once and parses it with a digit scanner.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const possibleMessage = "It is possible to move the furniture."
const impossibleMessage = "The furniture cannot be moved."

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int64 =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value: int64 = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int64(int(data[position]) - firstDigitValue)
    position += 1
  return value
```

Floor numbers fit in 64 bits, and every input number is non-negative. Parsing one number visits each digit once.

The helpers test one floor and solve the two-line congruence.

```nim
proc greatestCommonDivisor(firstValue: int64, secondValue: int64): int64 =
  var leftValue = firstValue
  var rightValue = secondValue
  while rightValue != 0:
    let remainder = leftValue mod rightValue
    leftValue = rightValue
    rightValue = remainder
  return leftValue

proc modularInverse(value: int64, modulus: int64): int64 =
  var oldRemainder = value mod modulus
  var remainder = modulus
  var oldCoefficient: int64 = 1
  var coefficient: int64 = 0
  while remainder != 0:
    let quotient = oldRemainder div remainder
    let nextRemainder = oldRemainder - quotient * remainder
    oldRemainder = remainder
    remainder = nextRemainder
    let nextCoefficient = oldCoefficient - quotient * coefficient
    oldCoefficient = coefficient
    coefficient = nextCoefficient
  return ((oldCoefficient mod modulus) + modulus) mod modulus

proc elevatorServesFloor(step: int64, start: int64, floor: int64): bool =
  return floor >= start and (floor - start) mod step == 0

proc elevatorsShareFloor(firstStep: int64, firstStart: int64,
                         secondStep: int64, secondStart: int64,
                         topFloor: int64): bool =
  let divisor = greatestCommonDivisor(firstStep, secondStep)
  let startDifference = secondStart - firstStart
  if startDifference mod divisor != 0:
    return false
  let reducedSecondStep = secondStep div divisor
  let reducedDifference = startDifference div divisor
  var offset: int64 = 0
  if reducedSecondStep > 1:
    let inverseStep = modularInverse(firstStep div divisor, reducedSecondStep)
    offset = (((reducedDifference mod reducedSecondStep) + reducedSecondStep) mod
              reducedSecondStep) * inverseStep mod reducedSecondStep
  let cycleLength = firstStep * reducedSecondStep
  var meetingFloor = firstStart + offset * firstStep
  meetingFloor = meetingFloor mod cycleLength
  let lowestFloor = if firstStart > secondStart: firstStart else: secondStart
  if lowestFloor >= topFloor:
    return false
  if meetingFloor < lowestFloor:
    let missingFloors = lowestFloor - meetingFloor
    let cyclesNeeded = (missingFloors + cycleLength - 1) div cycleLength
    meetingFloor += cyclesNeeded * cycleLength
  return meetingFloor < topFloor
```

The inverse step exists because the reduced steps are coprime. When the reduced second step is one, the first start already satisfies both lines. The final comparison enforces the top floor bound.

The driver builds the queue and walks the elevator graph.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1..caseCount:
  let floorCount = nextInt(inputData, scanPos)
  let elevatorCount = int(nextInt(inputData, scanPos))
  let originFloor = nextInt(inputData, scanPos)
  let targetFloor = nextInt(inputData, scanPos)
  var elevatorStep = newSeq[int64](elevatorCount)
  var elevatorStart = newSeq[int64](elevatorCount)
  for elevatorIndex in 0..<elevatorCount:
    elevatorStep[elevatorIndex] = nextInt(inputData, scanPos)
    elevatorStart[elevatorIndex] = nextInt(inputData, scanPos)
  var reachable = newSeq[bool](elevatorCount)
  var queue = newSeq[int](elevatorCount)
  var queueHead = 0
  var queueTail = 0
  for elevatorIndex in 0..<elevatorCount:
    if elevatorServesFloor(elevatorStep[elevatorIndex],
                           elevatorStart[elevatorIndex], originFloor):
      reachable[elevatorIndex] = true
      queue[queueTail] = elevatorIndex
      queueTail += 1
  var canMove = false
  if originFloor == targetFloor:
    canMove = true
  while not canMove and queueHead < queueTail:
    let currentElevator = queue[queueHead]
    queueHead += 1
    if elevatorServesFloor(elevatorStep[currentElevator],
                           elevatorStart[currentElevator], targetFloor):
      canMove = true
      break
    for otherElevator in 0..<elevatorCount:
      if reachable[otherElevator]:
        continue
      if elevatorsShareFloor(elevatorStep[currentElevator],
                             elevatorStart[currentElevator],
                             elevatorStep[otherElevator],
                             elevatorStart[otherElevator], floorCount):
        reachable[otherElevator] = true
        queue[queueTail] = otherElevator
        queueTail += 1
  if canMove:
    appendOutput(possibleMessage)
  else:
    appendOutput(impossibleMessage)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The queue is an array of elevator indices with two moving ends. A reached elevator is never tested again. The output buffer flushes in blocks, never once per case.

## Complexity

| Phase | Time | Space |
| --- | --- | --- |
| Parse one case | O(E) | O(E) |
| Shared-floor tests | O(E² log F) | O(1) extra |
| Queue walk | O(E) | O(E) |
| Output | O(1) per case | one block |

Total time is O(E² log F) per case and total space is O(E). Enumerating floors would cost O(F · E) per case instead.
