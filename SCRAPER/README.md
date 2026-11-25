# SCRAPER — Skyscraper Floors (SPOJ)
<https://www.spoj.com/problems/SCRAPER/>

## Problem

A large piece of furniture must move between two floors of a skyscraper. Each elevator starts at a floor and stops every X floors above it. The high-capacity elevator is broken, so transfers happen only where two elevators share a floor.

Input: an integer N, then N cases. Each case gives floors F, elevators E, and floors A and B, followed by E lines with step X and start Y. Output: one sentence per case, either `It is possible to move the furniture.` or `The furniture cannot be moved.`

The statement sets these bounds.

| Item | Bound |
| --- | --- |
| Cases | about 2000 |
| Floors F | 1 to 49999999 |
| Elevators E | 1 to 99 |
| Step X and start Y | positive X, nonnegative Y |
| Judge time limit | 13000 ms |
| Judge memory limit | 1536 MB |

The floor count is huge, so the program never stores one entry per floor.

The sample input:

```
2
22 4 0 6
3 2
4 7
13 6
10 0
1000 2 500 777
2 0
2 1
```

The sample output:

```
It is possible to move the furniture.
The furniture cannot be moved.
```

## Idea

Picture every elevator as a station and every shared floor as a connecting corridor. You start at the stations serving floor A and walk the corridors. If you reach a station serving floor B, the furniture can move.

The program builds that graph on the fly. A congruence solver decides whether two elevators meet on a floor below the top. It uses the greatest common divisor and a modular inverse. Each pair is tested once, so a case costs O(E squared). Walking every floor instead would cost O(F times E), which is impossible for millions of floors.

A small graph replaces a huge floor list.

## Why It Works

Four facts carry the program.

1. An elevator connects every pair of floors on its own line, in both directions. A trip is a chain of elevators where consecutive lines share a floor.
2. Two lines meet when a floor f satisfies both `f = Y1 + t1 * X1` and `f = Y2 + t2 * X2`. A solution exists only when `Y2 - Y1` is divisible by the gcd of the steps.
3. Dividing steps and difference by the gcd makes the steps coprime. A modular inverse then gives one meeting floor, and the cycle length is the least common multiple.
4. Adding whole cycles lifts that floor to at least the higher start. The candidate is valid only below the top floor F. Equal origin and target always succeed.

Each term has one job.

| Term | Meaning |
| --- | --- |
| `divisor` | greatest common divisor of the two steps |
| `reducedSecondStep` | second step divided by the divisor |
| `cycleLength` | least common multiple of the two steps |
| `meetingFloor` | smallest shared floor above both starts |

Every value uses 64 bits, so floors near 50 million stay exact.

A script traces one pair with steps 3 and 4 and starts 2 and 7.

```text
divisor gcd(3, 4) = 1
start difference 7 - 2 = 5, divisible by 1
reduced step 4, inverse of 3 mod 4 is 3
offset 5 mod 4 times 3 mod 4 = 3
cycle length 3 times 4 = 12
meeting floor 2 + 3 times 3 = 11 mod 12 = 11
11 is above both starts and below the top
```

The elevators share floor 11, so an edge joins them. No rounding appears because all values are integers.

## Code

**Constants and scanner.** Input numbers are nonnegative and fit in 64 bits.

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

var i = 0

proc nextInt(data: string, i: var int): int64 =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value: int64 = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int64(int(data[i]) - firstDigitValue)
    i += 1
  return value
```

The read loop appends into one buffer, so parsing never calls the stream. Each number costs one pass over its digits. The two messages are constants, so output never builds sentences.

**Congruence helpers.** Euclid solves the two-line meeting test.

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

The inverse exists because the reduced steps are coprime. When the reduced second step is one, the first start already works. The final comparison enforces the top floor bound.

**Graph walk.** A queue discovers elevators reachable from floor A.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, i)
for j in 1..caseCount:
  let floorCount = nextInt(inputData, i)
  let elevatorCount = int(nextInt(inputData, i))
  let originFloor = nextInt(inputData, i)
  let targetFloor = nextInt(inputData, i)
  var elevatorStep = newSeq[int64](elevatorCount)
  var elevatorStart = newSeq[int64](elevatorCount)
  for k in 0..<elevatorCount:
    elevatorStep[k] = nextInt(inputData, i)
    elevatorStart[k] = nextInt(inputData, i)
  var reachable = newSeq[bool](elevatorCount)
  var queue = newSeq[int](elevatorCount)
  var queueHead = 0
  var queueTail = 0
  for k in 0..<elevatorCount:
    if elevatorServesFloor(elevatorStep[k],
                           elevatorStart[k], originFloor):
      reachable[k] = true
      queue[queueTail] = k
      queueTail += 1
  var canMove = false
  if originFloor == targetFloor:
    canMove = true
  while not canMove and queueHead < queueTail:
    let k = queue[queueHead]
    queueHead += 1
    if elevatorServesFloor(elevatorStep[k],
                           elevatorStart[k], targetFloor):
      canMove = true
      break
    for l in 0..<elevatorCount:
      if reachable[l]:
        continue
      if elevatorsShareFloor(elevatorStep[k],
                             elevatorStart[k],
                             elevatorStep[l],
                             elevatorStart[l], floorCount):
        reachable[l] = true
        queue[queueTail] = l
        queueTail += 1
  if canMove:
    appendOutput(possibleMessage)
  else:
    appendOutput(impossibleMessage)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The queue holds elevator indices with two moving ends. A reached elevator is never tested again. The output buffer flushes in blocks, never once per case.

## Complexity

Parsing, pair tests and the queue walk make up each case.

| Phase | Time | Space |
| --- | --- | --- |
| Parse one case | O(E) | O(E) |
| Shared-floor tests | O(E squared log F) | O(1) extra |
| Queue walk | O(E) | O(E) |
| Output | O(1) per case | one block |

E is at most 99, so the pair tests stay small.

| Measure | Big O |
| --- | --- |
| Time | O(E squared log F) per case |
| Space | O(E) per case |

Enumerating floors would cost O(F times E) per case instead.
