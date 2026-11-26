# VZLA2019J — Jump! (SPOJ)

<https://www.spoj.com/problems/VZLA2019J/>

## Problem

A dinosaur must jump over cacti standing in a row. It cannot jump two cacti that sit one step apart (positions differing by 1), because it would crash into the second. For each test case, print `Case #X: Survival!` if no two cacti are one step apart, otherwise `Case #X: Oh no!`.

| item | bound |
|---|---|
| test cases `T` | 1 to 1000 |
| cacti per case `K` | 1 to 1000 |
| positions `Ci` | 0 to 1000, ascending, distinct |
| judge limit | 1000 ms, 1536 MB |

Sample input:

```
2
5
1 4 7 10 15
5
1 5 6 20 34
```

Sample output:

```
Case #1: Survival!
Case #2: Oh no!
```

## Idea

The cacti arrive already sorted. A pair one step apart can only be neighbours in that sorted list, so one left-to-right scan per case is enough: compare each cactus with the one before it and shout `Oh no!` the moment the gap is 1.

## Why It Works

1. Positions are distinct and ascending, so if two cacti differ by 1, nothing else can sit between them and they appear next to each other in the list.
2. Therefore a bad pair exists exactly when some consecutive pair has difference 1, which the scan tests for every neighbour.
3. Once a bad pair is seen the answer cannot change, but the scan keeps reading the remaining numbers so the next case starts at the right token.
4. The independent oracle uses a different route: it puts all positions in a set and asks whether `x + 1` is in the set for any cactus `x`. Set membership finds the same pairs as the neighbour scan.
5. In the sample, case 1 has gaps 3, 3, 3 and 5, all safe, while case 2 has cacti at 5 and 6, a gap of 1, so the verdicts are `Survival!` and `Oh no!`.

| term | meaning |
|---|---|
| `cactusCount` | number of cacti in one case |
| `previousCactus` | position of the cactus just read |
| `currentCactus` | position of the cactus being read |
| `canSurvive` | stays true while no gap of 1 is seen |

## Code

**Input, scanner and output buffer.** This block loads stdin and prepares the writer.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The whole input is read once into a string, and the scanner skips any non-digit, so line breaks never matter.

**The scan and the verdicts.** This block walks each case and prints its line.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseNumber in 1 .. caseCount:
  let cactusCount = nextInt(inputData, scanPos)
  var previousCactus = nextInt(inputData, scanPos)
  var canSurvive = true
  for cactusIndex in 1 .. cactusCount - 1:
    let currentCactus = nextInt(inputData, scanPos)
    if currentCactus - previousCactus == 1:
      canSurvive = false
    previousCactus = currentCactus
  appendOutput("Case #" & $caseNumber & ": ")
  if canSurvive:
    appendOutput("Survival!\n")
  else:
    appendOutput("Oh no!\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The first cactus is read outside the inner loop so every later cactus has a left neighbour to compare against. A case with one cactus runs the inner loop zero times and survives, which is right because there is nothing to crash into.

## Complexity

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | input bytes |
| scans | O(sum of K) comparisons | O(1) |
| output | one line per case, buffered | block buffer |

| measure | big O |
|---|---|
| time | O(T x K) |
| space | O(1) beyond the input |

At the limits that is about 10^6 comparisons, done in a blink.
