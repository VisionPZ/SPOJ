# RPLL — Lifesavers (SPOJ)

<https://www.spoj.com/problems/RPLL/>

## Problem

Three ships move in fixed compass directions. Find the last integer hour when their triangle area still fits inside a search limit.

The first line holds the number of cases. Each case has one maximum area, then three lines of the form x y direction speed. Directions are north, south, east, or west. Print `Scenario #i: ` followed by the latest valid integer time.

| item | bound |
|---|---|
| cases T | 1 to 100 |
| coordinates x and y | -1000000 to 1000000 |
| speed | 1 to 10 |
| maximum area | 1 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

The large area bound drives the design, since stepping through hours one by one can take millions of steps.

Sample input:

```
2
150
1 4 north 2
2 0 south 2
3 1 east 2
12
0 -2 north 1
0 0 north 2
0 0 east 3
```

Sample output:

```
Scenario #1: 5
Scenario #2: 2
```

## Idea

The triangle area grows as a quadratic, so find the last valid hour by bracketing and bisecting it. Think of climbing a ladder and stopping at the last rung below a ceiling.

Each position is start plus velocity times time. Expanding the cross product gives three small coefficients, so one area test costs a few multiplications. Doubling finds an upper bracket, and binary search finds the largest valid time in O(log t) tests.

Walking from hour zero upward would take up to billions of iterations. The quadratic form removes that walk. The takeaway is to evaluate the predicate at chosen times instead of at every time.

## Why It Works

1. At time t a ship sits at its start point plus velocity times t.
2. Twice the signed triangle area is the cross product of two relative position vectors.
3. Each relative position is linear in t, so the cross product expands to A t^2 + B t + C.
4. The absolute value of that expression is twice the area, and the input guarantees it increases.
5. Comparing against twice the maximum area avoids fractions at every step.
6. Doubling brackets the answer, and binary search returns the last time inside the bracket.

| term | meaning |
|---|---|
| `ShipState` | start point and velocity of one ship |
| `squareCoefficient` | quadratic coefficient A of the doubled area |
| `linearCoefficient` | linear coefficient B of the doubled area |
| `constantCoefficient` | constant coefficient C of the doubled area |
| `allowedTwiceArea` | maximum area multiplied by two |
| `safeTime` | time cap that keeps 64-bit products safe |
| `twiceAreaAt` | evaluates the absolute doubled area at one time |

The table names the values used by the search.

A script trace for the second sample uses ships at (0, -2) north 1, (0, 0) north 2, and (0, 0) east 3. Expansion gives A = -3, B = -6, and C = 0, so the doubled area is 3 t^2 + 6 t.

| time | doubled area | area | allowed |
|---|---|---|---|
| 2 | 24 | 12 | 24 |
| 3 | 45 | 22.5 | 24 |

Hour 2 fits and hour 3 does not, so the answer is 2.

The scanner keeps the minus sign on negative coordinates. The time cap bounds every product below the 64-bit limit. No rounding enters the comparison because both sides are doubled integers.

## Code

**Input and ship parsing.** The reader loads all lines, scans signed integers, and maps compass words to velocities.

```nim
const flushBlockBytes = 1 shl 17
const quadraticTimeLimit: int64 = 100000000
const linearTimeLimit: int64 = 10000000000

type ShipState = object
  startX: int64
  startY: int64
  velocityX: int64
  velocityY: int64

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value

proc nextDirection(data: string, pos: var int): int =
  while pos < data.len and data[pos] != 'n' and data[pos] != 's' and
        data[pos] != 'e' and data[pos] != 'w':
    pos += 1
  let initialLetter = data[pos]
  while pos < data.len and data[pos] >= 'a' and data[pos] <= 'z':
    pos += 1
  case initialLetter
  of 'n': return 0
  of 's': return 1
  of 'e': return 2
  else: return 3

proc velocityXFrom(directionCode: int, speedValue: int64): int64 =
  case directionCode
  of 2: return speedValue
  of 3: return -speedValue
  else: return 0

proc velocityYFrom(directionCode: int, speedValue: int64): int64 =
  case directionCode
  of 0: return speedValue
  of 1: return -speedValue
  else: return 0
```

`nextInt` preserves negative coordinates.
Each compass word has a distinct first letter.
Velocities are stored as signed components.

**Area evaluation.** One routine returns the absolute doubled area at a chosen time.

```nim
proc twiceAreaAt(timeValue: int64, squareCoefficient: int64,
                 linearCoefficient: int64, constantCoefficient: int64): int64 =
  let signedArea = squareCoefficient * timeValue * timeValue +
                   linearCoefficient * timeValue + constantCoefficient
  if signedArea < 0:
    return -signedArea
  return signedArea

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The quadratic evaluates with three 64-bit products.
The sign is removed after evaluation.
`appendOutput` flushes after a full block.

**Coefficient expansion and search.** Each case expands the cross product, brackets the answer, and bisects it.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let searchLimit = int64(nextInt(inputData, scanPos))
  var ships: seq[ShipState] = @[]
  for shipIndex in 1 .. 3:
    var ship: ShipState
    ship.startX = int64(nextInt(inputData, scanPos))
    ship.startY = int64(nextInt(inputData, scanPos))
    let directionCode = nextDirection(inputData, scanPos)
    let speedValue = int64(nextInt(inputData, scanPos))
    ship.velocityX = velocityXFrom(directionCode, speedValue)
    ship.velocityY = velocityYFrom(directionCode, speedValue)
    ships.add ship
  let relativeX = ships[1].startX - ships[0].startX
  let relativeY = ships[1].startY - ships[0].startY
  let otherX = ships[2].startX - ships[0].startX
  let otherY = ships[2].startY - ships[0].startY
  let velocityX = ships[1].velocityX - ships[0].velocityX
  let velocityY = ships[1].velocityY - ships[0].velocityY
  let otherVelocityX = ships[2].velocityX - ships[0].velocityX
  let otherVelocityY = ships[2].velocityY - ships[0].velocityY
  let constantCoefficient = relativeX * otherY - relativeY * otherX
  let squareCoefficient = velocityX * otherVelocityY - velocityY * otherVelocityX
  let linearCoefficient = (velocityX * otherY - velocityY * otherX) +
                          (relativeX * otherVelocityY - relativeY * otherVelocityX)
  let allowedTwiceArea = 2 * searchLimit
  var safeTime = quadraticTimeLimit
  if squareCoefficient == 0:
    safeTime = linearTimeLimit
  var lowTime: int64 = 0
  var highTime: int64 = 1
  while highTime < safeTime and
        twiceAreaAt(highTime, squareCoefficient, linearCoefficient,
                    constantCoefficient) <= allowedTwiceArea:
    highTime *= 2
  if highTime > safeTime:
    highTime = safeTime
  while lowTime + 1 < highTime:
    let middleTime = lowTime + (highTime - lowTime) div 2
    if twiceAreaAt(middleTime, squareCoefficient, linearCoefficient,
                   constantCoefficient) <= allowedTwiceArea:
      lowTime = middleTime
    else:
      highTime = middleTime
  appendOutput("Scenario #")
  appendOutput($caseIndex)
  appendOutput(": ")
  appendOutput($lowTime)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The three coefficients come from one cross product expansion.
Doubling stops before the time cap is exceeded.
`lowTime` holds the last valid integer hour.

## Complexity

Each case expands three ships into one quadratic, then searches a time range.

| phase | time | space |
|---|---|---|
| input read | one pass over ship lines | one input string |
| expansion | constant cross products | three ship records |
| binary search | O(log t) area tests | constant scratch |
| output | buffered writes | one output buffer |

The binary search dominates the constant-size expansion.

| measure | Big O |
|---|---|
| time | O(log t) per case, where t is the answer |
| space | O(1) beyond the input string |

Testing every hour from zero would cost O(t) per case. The quadratic predicate reduces that to a few dozen evaluations.
