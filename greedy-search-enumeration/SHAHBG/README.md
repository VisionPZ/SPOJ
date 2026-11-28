# SHAHBG — SHAHBAG (SPOJ)

<https://www.spoj.com/problems/SHAHBG/>

## Problem

People take distinct positions on a numbered line, one after another. Adjacent occupied positions form one group; report the number of groups after each arrival, then print `Justice` on its own line.

Input has a single test case. The first line gives Q, the number of people. The next line gives Q distinct positions, each between 1 and 20000. Output Q lines of group counts and one final line containing `Justice`.

| item | bound |
|---|---|
| people Q | 1 to 20000 |
| position value | 1 to 20000, all distinct |
| judge limit | 1000 ms, 1536 MB |

Nobody leaves, so the group count only changes when a neighbor is already occupied.

Sample input:

```
6
2 4 3 6 7 5
```

Sample output:

```
1
2
1
2
2
1
Justice
```

## Idea

A new person acts like a bridge between two neighboring clumps of people, like joining two puzzle pieces with a single snap. Count the occupied neighbors: zero neighbors creates a group, one neighbor extends a group, and two neighbors merge two groups.

Track occupancy in a boolean array and update one integer per arrival. Each insertion reads two array cells, so the cost per person is constant. Rebuilding all groups after each arrival would cost quadratic time.

One counter and one occupancy array answer every arrival in constant time.

## Why It Works

1. A group is a maximal run of consecutive occupied positions.
2. With no occupied neighbor, the new position starts its own run, so the count rises by one.
3. With one occupied neighbor, the new position extends that run, so the count stays the same.
4. With two occupied neighbors, two runs join through the new position, so the count drops by one.
5. Positions are distinct, so an arrival never re-counts an occupied cell.

| term | meaning |
|---|---|
| `isOccupied` | array telling whether a position is taken |
| `occupiedNeighbors` | number of taken neighbors of the new position |
| `groupCount` | number of groups after the latest arrival |
| `positionCapacity` | array size, larger than the largest legal position |

A worked trace from the sample:

| position | neighbors | action | groups |
|---|---|---|---|
| 2 | 0 | start | 1 |
| 4 | 0 | start | 2 |
| 3 | 2 | merge | 1 |
| 6 | 0 | start | 2 |
| 7 | 1 | extend | 2 |
| 5 | 2 | merge | 1 |

The final count of 1 matches the sample before `Justice`.

## Code

**Input and buffer.** The reader loads the whole input and sets up buffered output.

```nim
const flushBlockBytes = 1 shl 17
const positionCapacity = 50005

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

The array capacity exceeds the largest stated position.
The scanner skips spaces and line breaks between positions.
The output buffer holds complete lines until it reaches the flush size.

**Arrival loop.** Each arrival checks both neighbors and updates the counter.

```nim
let peopleCount = nextInt(inputData, scanPos)
var isOccupied = newSeq[bool](positionCapacity)
var groupCount = 0
for personIndex in 0 .. peopleCount - 1:
  let position = nextInt(inputData, scanPos)
  var occupiedNeighbors = 0
  if position > 1 and isOccupied[position - 1]:
    occupiedNeighbors += 1
  if position + 1 < positionCapacity and isOccupied[position + 1]:
    occupiedNeighbors += 1
  if occupiedNeighbors == 0:
    groupCount += 1
  elif occupiedNeighbors == 2:
    groupCount -= 1
  isOccupied[position] = true
  appendOutput($groupCount)
  outputBuffer.add '\n'
appendOutput("Justice")
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The left neighbor is checked only above position 1.
A two-neighbor arrival reduces the counter by one.
`Justice` is written once after all arrivals.

## Complexity

Each arrival reads two neighbors and writes one line.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| arrival updates | two checks per person | occupancy array |
| output | one line per person | block buffer |

The arrival loop dominates both time and output size.

| measure | Big O |
|---|---|
| time | O(Q) |
| space | O(position capacity) |

Recounting every run after each arrival would cost O(Q squared) instead of O(Q).
The neighbor rule keeps long arrival lists fast.
