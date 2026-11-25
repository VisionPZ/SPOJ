# WRONG — Wrong directions (SPOJ)

<https://www.spoj.com/problems/WRONG/>

## Problem

A tractor follows a string of forward and turn commands from the origin facing north. Exactly one character is mistyped; count the distinct final positions over all choices of that one typo.

The single input line holds the intended command string, with length `N`. Each character is `F`, `L`, or `R`. The output is one integer: the number of distinct landing positions.

The statement gives these bounds:

| item | bound |
|---|---|
| string length N | 1 to 100000 |
| characters | F, L, R |
| judge limit | 1000 ms, 1536 MB |

The length bound rules out resimulating the whole string after each typo.

Sample input:

```
FF
```

Sample output:

```
3
```

## Idea

Treat a typo like swapping one carriage in a train: the rest of the coupling stays the same.

Precompute the displacement of every suffix from every possible facing direction. Each typo then adds a saved prefix position to one suffix vector. A hash set removes duplicates.

Resimulating the full string for each typo costs quadratic time. The suffix table turns it into one pass per direction. The takeaway is to precompute suffixes and reuse the saved prefix states.

## Why It Works

1. A forward command adds one unit along the current facing and keeps that facing.
2. A turn command changes the facing and adds no displacement.
3. The suffix table stores the displacement of commands after index i for each incoming facing.
4. A typo at index i leaves the prefix before i unchanged and uses one suffix vector after i.
5. Packing coordinates into an integer key and hashing it keeps only distinct positions.

The main terms are listed here:

| term | meaning |
|---|---|
| `positionX` | x coordinate before each command |
| `facingDirection` | direction before each command |
| `suffixX` | suffix displacement in x for each direction |
| `packedKey` | integer key built from both coordinates |

The table stores four suffix vectors per index, one for each incoming direction.

A script trace for the sample `FF` lists every mistyped string and its landing point:

| mistyped string | landing point |
|---|---|
| FL | (0, 1) |
| FR | (0, 1) |
| LF | (-1, 0) |
| RF | (1, 0) |

Three points appear, so the answer is three.

Guards: the hash table has 524288 slots and the coordinate offset keeps every packed key positive.

## Code

**Input and forward pass.** The reader grabs the command token and saves prefix positions and facings.

```nim
const flushBlockBytes = 1 shl 17
const hashBits = 19
const hashMask = (1 shl hashBits) - 1
const directionNorth = 0
const deltaX = [0, 1, 0, -1]
const deltaY = [1, 0, -1, 0]
const coordinateOffset = 200000
const coordinateBase = 400001

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
while scanPos < inputData.len and inputData[scanPos] <= ' ':
  scanPos += 1
let commandStart = scanPos
while scanPos < inputData.len and inputData[scanPos] > ' ':
  scanPos += 1
let commandString = inputData[commandStart .. scanPos - 1]
let commandCount = commandString.len

var positionX = newSeq[int](commandCount + 1)
var positionY = newSeq[int](commandCount + 1)
var facingDirection = newSeq[int](commandCount + 1)
positionX[0] = 0
positionY[0] = 0
facingDirection[0] = directionNorth
for stepIndex in 0 .. commandCount - 1:
  let beforeX = positionX[stepIndex]
  let beforeY = positionY[stepIndex]
  let facing = facingDirection[stepIndex]
  positionX[stepIndex + 1] = beforeX
  positionY[stepIndex + 1] = beforeY
  facingDirection[stepIndex + 1] = facing
  if commandString[stepIndex] == 'F':
    positionX[stepIndex + 1] = beforeX + deltaX[facing]
    positionY[stepIndex + 1] = beforeY + deltaY[facing]
  elif commandString[stepIndex] == 'L':
    facingDirection[stepIndex + 1] = (facing + 3) mod 4
  else:
    facingDirection[stepIndex + 1] = (facing + 1) mod 4
```

The prefix arrays have one entry per command boundary.
Turns change only `facingDirection`; forward steps change position.
This pass costs one unit per command.

**Suffix table.** Walking backwards builds the displacement of each suffix for all four facings.

```nim
var suffixX = newSeq[array[4, int]](commandCount + 1)
var suffixY = newSeq[array[4, int]](commandCount + 1)
for direction in 0 .. 3:
  suffixX[commandCount][direction] = 0
  suffixY[commandCount][direction] = 0
var reverseIndex = commandCount - 1
while reverseIndex >= 0:
  for direction in 0 .. 3:
    case commandString[reverseIndex]
    of 'F':
      let shifted = direction
      suffixX[reverseIndex][direction] = deltaX[shifted] + suffixX[reverseIndex + 1][shifted]
      suffixY[reverseIndex][direction] = deltaY[shifted] + suffixY[reverseIndex + 1][shifted]
    of 'L':
      let shifted = (direction + 3) mod 4
      suffixX[reverseIndex][direction] = suffixX[reverseIndex + 1][shifted]
      suffixY[reverseIndex][direction] = suffixY[reverseIndex + 1][shifted]
    else:
      let shifted = (direction + 1) mod 4
      suffixX[reverseIndex][direction] = suffixX[reverseIndex + 1][shifted]
      suffixY[reverseIndex][direction] = suffixY[reverseIndex + 1][shifted]
  reverseIndex -= 1
```

The empty suffix at the end has zero displacement.
Each step reuses the already built row to its right.
Four directions make this pass cost four units per command.

**Position set.** Open addressing stores each landing point once.

```nim
var seenPositions = newSeq[int64](1 shl hashBits)
var distinctPositions = 0

proc hashPosition(keyValue: int64): int =
  var mixed = keyValue
  mixed = mixed xor (mixed shr 29)
  mixed = mixed * 1000003'i64
  mixed = mixed xor (mixed shr 21)
  return int(mixed and int64(hashMask))

proc addPosition(pointX: int, pointY: int) =
  let packedKey = (int64(pointX + coordinateOffset) * coordinateBase + int64(pointY + coordinateOffset)) + 1
  var slotIndex = hashPosition(packedKey)
  while seenPositions[slotIndex] != 0:
    if seenPositions[slotIndex] == packedKey:
      return
    slotIndex = (slotIndex + 1) and hashMask
  seenPositions[slotIndex] = packedKey
  distinctPositions += 1
```

The packed key never reaches zero, so zero marks an empty slot.
Linear probing handles collisions without allocation.
Each insertion costs expected constant time.

**Typo sweep and output.** Every index contributes two candidate typos, then the count is written once.

```nim
for stepIndex in 0 .. commandCount - 1:
  let beforeX = positionX[stepIndex]
  let beforeY = positionY[stepIndex]
  let facing = facingDirection[stepIndex]
  if commandString[stepIndex] == 'F':
    let leftFacing = (facing + 3) mod 4
    let rightFacing = (facing + 1) mod 4
    addPosition(beforeX + suffixX[stepIndex + 1][leftFacing], beforeY + suffixY[stepIndex + 1][leftFacing])
    addPosition(beforeX + suffixX[stepIndex + 1][rightFacing], beforeY + suffixY[stepIndex + 1][rightFacing])
  else:
    addPosition(beforeX + deltaX[facing] + suffixX[stepIndex + 1][facing], beforeY + deltaY[facing] + suffixY[stepIndex + 1][facing])
    let swappedFacing = if commandString[stepIndex] == 'L': (facing + 1) mod 4 else: (facing + 3) mod 4
    addPosition(beforeX + suffixX[stepIndex + 1][swappedFacing], beforeY + suffixY[stepIndex + 1][swappedFacing])

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

appendOutput($distinctPositions)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A forward typo becomes a turn, so the position comes from a rotated suffix.
A turn typo either adds one forward step or rotates the other way.
The single output line uses the buffered write path.

## Complexity

Three linear passes and a hash set determine the cost.

| phase | time | space |
|---|---|---|
| input read | one pass over the command token | one input string |
| prefix and suffix tables | two passes over N commands | two arrays of 4N integers |
| typo sweep | two inserts per command | hash table of fixed size |
| output | one line | block buffer |

The table has four entries per command and the hash table has a fixed size.

The overall bounds are:

| measure | Big O |
|---|---|
| time | O(N) expected |
| space | O(N) |

Resimulating after each typo would cost O(N^2). The suffix table makes each typo constant time, so the total is linear.
