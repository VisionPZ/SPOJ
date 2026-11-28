# RETOCALENTAMIENT — Pertre (SPOJ)

<https://www.spoj.com/problems/RETOCALENTAMIENT/>

## Problem

Given n consecutive moon sizes from a repeating 30-day cycle, decide whether the next size is surely larger, surely smaller, or undetermined.

Each case gives n followed by n recorded sizes. Print CRECIENTE for a larger next size, MENGUANTE for a smaller one, and -1 when the data cannot decide. Print one answer per case.

The statement and judge give these bounds:

| item | bound |
|---|---|
| recorded days n | 1 to 92 |
| recorded sizes | 0 to 15 |
| cycle length | 30 |
| judge limit | 1000 ms, 1536 MB |

The short cycle makes every alignment cheap to test.

Sample input:

```
5
3 4 5 6 7
```

Sample output:

```
CRECIENTE
```

## Idea

Slide the record over the repeating cycle like a paper strip over a calendar, and let every fitting position vote on the next day.

The algorithm tries all 30 phases and compares up to n days per phase. Each comparison costs constant time. Searching a long repeated string would redo the same comparisons many times. Thirty short alignments settle the answer directly.

A fixed set of alignments gives the answer with a few thousand comparisons.

## Why It Works

1. The moon cycle has 30 entries and then repeats.
2. A phase marks where the first recorded day sits in the cycle.
3. A phase fits when all n recorded sizes match the cycle at that offset.
4. A fitting phase predicts one next size from the cycle.
5. Adjacent cycle sizes differ, so each prediction rises or falls.
6. Two different predictions mean the next size is unknown.
7. No fitting phase also means the next size is unknown.

The main terms are these:

| term | meaning |
|---|---|
| `moonCycle` | the 30 sizes of one full lunar cycle |
| `moonRecord` | the n sizes from the input case |
| `phase` | the cycle position of the first recorded day |
| `decidedDirection` | the direction shared by the fitting phases |
| `mixedDirections` | a flag for two disagreeing phases |

The flags turn many alignments into one verdict.

A script-traced example from `gen.py`:

```
record 3 4 5 6 7
phase 3 in 30-day cycle
next size 8
```

The next size 8 exceeds 7, so the sample answer is CRECIENTE.

## Code

**Bulk input and hand scanner.** This block builds the cycle and reads the case integers.

```nim
const flushBlockBytes = 1 shl 17
const cycleLength = 30
const risingHalf = 16
const fallingHalf = 14

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  if pos >= data.len:
    return -1
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

A negative return marks the end of the input stream.
The scanner skips all spaces and line breaks between sizes.
The output buffer flushes after about 128 KiB of text.
Each token costs one pass over its digits.

**Cycle construction.** This block writes the rising and falling halves.

```nim
var moonCycle = newSeq[int](cycleLength)
for dayIndex in 0 .. risingHalf - 1:
  moonCycle[dayIndex] = dayIndex
for dayIndex in 0 .. fallingHalf - 1:
  moonCycle[risingHalf + dayIndex] = fallingHalf - dayIndex
```

The first 16 positions rise from 0 to 15.
The last 14 positions fall from 14 to 1.
Both loops run once at program start.
The table costs 30 integers of space.

**Phase scan and output.** This block tests every alignment and prints the verdict.

```nim
while true:
  let dayCount = nextInt(inputData, scanPos)
  if dayCount < 0:
    break
  var moonRecord = newSeq[int](dayCount)
  for recordIndex in 0 .. dayCount - 1:
    moonRecord[recordIndex] = nextInt(inputData, scanPos)
  var decidedDirection = 0
  var mixedDirections = 0
  for phase in 0 .. cycleLength - 1:
    var matches = 1
    for recordIndex in 0 .. dayCount - 1:
      if moonCycle[(phase + recordIndex) mod cycleLength] != moonRecord[recordIndex]:
        matches = 0
        break
    if matches == 0:
      continue
    let lastSize = moonCycle[(phase + dayCount - 1) mod cycleLength]
    let nextSize = moonCycle[(phase + dayCount) mod cycleLength]
    let direction = if nextSize > lastSize: 1 else: -1
    if decidedDirection == 0:
      decidedDirection = direction
    elif decidedDirection != direction:
      mixedDirections = 1
      break
  if mixedDirections == 1 or decidedDirection == 0:
    appendOutput("-1\n")
  elif decidedDirection > 0:
    appendOutput("CRECIENTE\n")
  else:
    appendOutput("MENGUANTE\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

A mismatched day ends that phase early.
A disagreement between two fitting phases ends the whole scan.
The last matching phase supplies the predicted next size.
One final write flushes the remaining text.

## Complexity

The cost splits into input, the phase scan, and output.

| phase | time | space |
|---|---|---|
| input read | one pass over stdin bytes | one input string |
| phase scan | up to 30 × n comparisons per case | one record array |
| output | one line per case | block buffer |

The phase scan dominates because n stays small and the cycle is fixed.

The asymptotic costs are these:

| measure | Big O |
|---|---|
| time | O(n) per case, with a constant factor of 30 |
| space | O(input bytes + n) |

Reading only the last two sizes would miss ambiguous alignments.
Testing all 30 phases catches every possible future.
