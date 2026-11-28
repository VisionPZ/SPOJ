# CARINA — Carina (SPOJ)

<https://www.spoj.com/problems/CARINA/>

## Problem

Move copies from a depot to a shop past a row of customs checkpoints, and maximize the copies arriving. The truck carries at most C copies, pays one copy at each checkpoint it reaches with cargo, and may return to the depot only X times.

Input is one line with four integers: total copies, capacity, checkpoint count, and the return limit.

Output one integer, the largest number of copies that can reach the shop.

| item | bound |
|---|---|
| total copies N | 1 to 10^18 |
| capacity C | 1 to 10^18 |
| checkpoints L | 1 to 10^18 |
| returns X | 0 to 10^6 |
| judge limit | 500 ms, 1536 MB |

The huge checkpoint count forces blocks of equal loss to be skipped at once.

Sample input:

```
4000 1000 1000 1
```

Sample output:

```
500
```

## Idea

Think of each checkpoint as a toll booth that charges one copy per loaded crossing, like paying a coin at every gate. The truck can shuttle back and forth without returning to the depot, so a checkpoint costs exactly the number of loaded crossings needed there. X returns allow X+1 departures from the depot, so at most that many truckloads ever leave it. Push the largest legal load past every checkpoint, and jump over long runs where the toll stays unchanged. A simulation over one trillion checkpoints would never finish; block skipping finishes in a few steps.

## Why It Works

1. X returns allow X+1 departures, so at most that many truckloads cross the first checkpoint.
2. Sending more copies across a checkpoint always leaves at least as many beyond it.
3. To move u copies across one checkpoint needs ceil(u/C) loaded crossings, each paying one copy.
4. After that checkpoint, u minus ceil(u/C) copies remain, and the same rule applies at the next one.
5. ceil(u/C) stays constant while u lies in one band of width C, so many checkpoints can share one subtraction.

| term | meaning |
|---|---|
| `departureCount` | X+1, the number of trips away from the depot |
| `copiesLeavingDepot` | largest load that can cross the first checkpoint |
| `crossingLoad` | loaded crossings needed for the current copies |
| `equalLoadSteps` | checkpoints that share the same crossing load |

The table tracks the quantities used by one block of the sweep.

A worked example from the generator:

```
departures = 2, copies leaving depot = 2000
checkpoint 1: 2000 - 2 = 1998
next 499 checkpoints: 1998 - 499*2 = 1000
last 500 checkpoints: 1000 - 500*1 = 500
delivered = 500
```

The total loss matches the sample answer of 500 copies.

## Code

**Input and initial load.** The reader takes the four values and caps the copies leaving the depot.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let totalCopies = nextInt(inputData, scanPos)
let truckCapacity = nextInt(inputData, scanPos)
let checkpointCount = nextInt(inputData, scanPos)
let allowedReturns = nextInt(inputData, scanPos)
let departureCount = allowedReturns + 1

var copiesLeavingDepot = totalCopies
if truckCapacity <= totalCopies div departureCount:
  copiesLeavingDepot = truckCapacity * departureCount
```

The division check avoids overflow in the capacity product.
Every copy that leaves the depot crosses the first checkpoint.

**Block sweep.** Each iteration skips all checkpoints with the same toll.

```nim
var deliveredCopies = copiesLeavingDepot
var checkpointsRemaining = checkpointCount
while checkpointsRemaining > 0 and deliveredCopies > 0:
  let crossingLoad = (deliveredCopies + truckCapacity - 1) div truckCapacity
  let previousBandTop = (crossingLoad - 1) * truckCapacity
  var equalLoadSteps = (deliveredCopies - previousBandTop + crossingLoad - 1) div crossingLoad
  if equalLoadSteps > checkpointsRemaining:
    equalLoadSteps = checkpointsRemaining
  deliveredCopies = deliveredCopies - equalLoadSteps * crossingLoad
  checkpointsRemaining = checkpointsRemaining - equalLoadSteps

appendOutput($deliveredCopies)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The band top is the largest count with the same crossing load.
Block length is clipped to the checkpoints that remain.
All arithmetic uses int64, so values near 10 to the 18 stay exact.

## Complexity

The sweep makes one jump per distinct crossing load.

| phase | time | space |
|---|---|---|
| input read | one line of four numbers | one input string |
| initial load | one division | constant |
| block sweep | one iteration per load band | constant |
| output | one line | block buffer |

Even huge checkpoint counts finish in a small number of jumps.

| measure | Big O |
|---|---|
| time | O(number of load bands) |
| space | O(total input bytes) |

Visiting each checkpoint separately would cost O(L), which fails for 10 to the 18 checkpoints.
The band jump keeps each iteration proportional to the drop in the load.
