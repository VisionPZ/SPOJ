# BMJ — Bee Maja (SPOJ)

<https://www.spoj.com/problems/BMJ/>

## Problem

Honeycomb cells form an infinite hexagonal spiral. Willi numbers them clockwise from 1 at the center, while Maja uses two-dimensional coordinates. Convert each Willi number to Maja coordinates.

The input contains one or more integers, each on its own line, all below 100000. Read until end of input. Print one coordinate pair per line, with x and y separated by one space.

| item | bound |
|---|---|
| honeycomb number | positive and less than 100000 |
| input length | one or more lines until end of input |
| judge limit | 3409 ms, 1536 MB |

The number bound limits the spiral to roughly 183 rings, so a direct ring walk is cheap.

Sample input:

```
1
2
3
4
5
```

Sample output:

```
0 0
0 1
-1 1
-1 0
0 -1
```

## Idea

Peel the spiral into rings, like counting the turns of a coiled rope. Each ring starts at a known cell, then moves through six straight sides. The method is a direct ring walk with six fixed direction vectors. Scanning outward from the center for every number costs work proportional to the ring number, while the walk costs constant work per cell. Takeaway: jump straight to the ring, then walk at most six sides.

## Why It Works

1. Ring r contains numbers from 3r(r-1)+2 through 3r(r+1)+1, so r grows like the square root of the number.
2. Ring r starts at (r-1, 1) in Maja coordinates.
3. The six side directions are (-1,1), (-1,0), (0,-1), (1,-1), (1,0), (0,1).
4. The first side advances r-1 steps and each remaining side advances r steps.
5. Adding the steps for the cell's position in the ring gives its exact coordinates.

| term | meaning |
|---|---|
| `honeyNumber` | Willi's cell number from the input |
| `ringIndex` | ring that holds that number |
| `ringStart` | first Willi number in the ring |
| `stepsRemaining` | distance walked from the ring start |
| `coordX`, `coordY` | Maja coordinates being accumulated |

The generator checks each number up to 200 against a full spiral walk, so the side lengths agree with the formula.

## Code

**Input and scanning.** All input lines are joined, then parsed by a digit scanner.

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

The loop reads stdin once and preserves line breaks.
The scanner skips spacing and stops at the first non-digit.
Each parsed value occupies one integer.

**Ring walk and output.** Six side vectors turn the ring position into coordinates.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var deltaX: array[6, int] = [-1, -1, 0, 1, 1, 0]
var deltaY: array[6, int] = [1, 0, -1, -1, 0, 1]

while scanPos < inputData.len:
  let honeyNumber = nextInt(inputData, scanPos)
  if honeyNumber == 0:
    break
  if honeyNumber == 1:
    appendOutput("0 0")
    outputBuffer.add '\n'
    continue
  var ringIndex = 1
  while honeyNumber > 3 * ringIndex * (ringIndex + 1) + 1:
    ringIndex += 1
  let ringStart = 3 * ringIndex * (ringIndex - 1) + 2
  var stepsRemaining = honeyNumber - ringStart
  var coordX = ringIndex - 1
  var coordY = 1
  var segmentLength = ringIndex - 1
  for segmentIndex in 0 .. 5:
    var applied = segmentLength
    if applied > stepsRemaining:
      applied = stepsRemaining
    coordX += deltaX[segmentIndex] * applied
    coordY += deltaY[segmentIndex] * applied
    stepsRemaining -= applied
    segmentLength = ringIndex
  appendOutput($coordX)
  appendOutput(" ")
  appendOutput($coordY)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The center is handled before any ring search.
The side loop caps each step count at the remaining distance.
One buffered write emits all coordinate pairs.

## Complexity

Each number is located by a short ring search and a six-step walk.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| ring location | up to about 183 comparisons per number | constant |
| coordinate walk | six side steps per number | two small arrays |
| output | one line per number | block buffer |

| measure | Big O |
|---|---|
| time | O(K sqrt M) for K numbers up to M |
| space | O(1) besides input |

Walking from the center for each number would cost O(M) per query, while the ring jump keeps each conversion short.
