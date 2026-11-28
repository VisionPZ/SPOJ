# AR2015PH — Automatic Scholarship Calculation (SPOJ)

<https://www.spoj.com/problems/AR2015PH/>

## Problem

A university splits CGPA values from a chosen lower bound up to 4.00 into slabs of equal width. Slab percentages start at a positive value and rise by a fixed positive step. Count the allocations whose percentages spend exactly P units on the students.

Each data set starts with N and P, followed by N CGPA values. A line `0 0` ends the input. Print the allocation count for each data set.

| item | bound |
|---|---|
| data sets | up to 100 |
| students N | up to 10000 |
| scholarship units P | bounded by 100 times N |
| judge limit | 1000 ms, 1536 MB |

The number of width and lower-bound pairs drives the enumeration design.

Sample input:

```
10 410
3.29
3.96
2.61
2.82
3.93
3.68
3.70
2.91
3.28
3.68
0 0
```

Sample output:

```
79554
```

## Idea

Think of the slab table as a staircase with equal steps, like measuring a wall with one ruler length. Once the ruler and its start are fixed, each student lands in a known slab. The total units become a linear equation in the starting percentage and the step.

Enumerate the width and the lower bound, then maintain two sums over students. The first sum counts qualifying students. The second adds their slab indices. A linear congruence gives the valid percentage pairs. Add one allocation for each pair that respects the 100 percent cap.

## Why It Works

1. A slab of width w covers w plus one CGPA hundredths, and the next starts w plus one later.
2. The slab count is the floor of the span divided by the step, plus one.
3. A student below the lower bound receives no scholarship.
4. A qualifying student in slab i contributes the starting percentage plus i times the step.
5. Total units therefore equal a times S0 plus d times S1.
6. For a fixed d, the starting percentage is determined by the remaining units and S0.

| term | meaning |
|---|---|
| `slabStep` | width plus one, in CGPA hundredths |
| `slabCount` | number of slabs, including a shorter top slab |
| `activeStudents` | S0, the students at or above the lower bound |
| `indexSum` | S1, the sum of slab indices over those students |

The two sums compress every student into one linear equation.

A script-generated trace of the sample solution with a equals 10 and d equals 10:

```
slab: 2.88-3.02 3.03-3.17 3.18-3.32 3.33-3.47
units:       10         0         60         0
slab: 3.48-3.62 3.63-3.77 3.78-3.92 3.93-4.00
units:        0       180         0       160
total: 410
```

The eight slabs spend exactly 410 units, as required.

## Code

**Input and scanner.** The reader loads all lines and extracts integers by hand.

```nim
const flushBlockBytes = 1 shl 17
const lowestCenti = 250
const highestCenti = 400
const maxSlabWidth = 149
const maxPercent = 100

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

CGPA values are read as a whole part and a hundredths part.
The scanner skips the decimal point.
The sentinel line ends the loop.

**Buffered output.** One string holds all answer lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after reaching the block size.
A single answer causes no write.
A final write drains the remaining text.

**Enumeration and counting.** The sweep maintains the two sums for every lower bound.

```nim
while true:
  let studentCount = nextInt(inputData, scanPos)
  let totalUnits = nextInt(inputData, scanPos)
  if studentCount == 0 and totalUnits == 0:
    break
  var scoreCounts = newSeq[int](highestCenti + 1)
  for studentIndex in 0 .. studentCount - 1:
    let wholePart = nextInt(inputData, scanPos)
    let fractionPart = nextInt(inputData, scanPos)
    let scoreValue = wholePart * 100 + fractionPart
    if scoreValue >= 0 and scoreValue <= highestCenti:
      scoreCounts[scoreValue] = scoreCounts[scoreValue] + 1

  var allocationCount: int64 = 0
  for slabWidth in 0 .. maxSlabWidth:
    let slabStep = slabWidth + 1
    var residueCounts = newSeq[int](slabStep)
    var activeStudents = 0
    var indexSum: int64 = 0
    residueCounts[highestCenti mod slabStep] = scoreCounts[highestCenti]
    activeStudents = scoreCounts[highestCenti]
    for lowestStart in countdown(highestCenti, lowestCenti):
      let slabCount = (highestCenti - lowestStart) div slabStep + 1
      if slabCount >= 2 and activeStudents > 0:
        let maxStepSize = min(maxPercent, (maxPercent - 1) div (slabCount - 1))
        for stepSize in 1 .. maxStepSize:
          let remainingUnits = int64(totalUnits) - int64(stepSize) * indexSum
          if remainingUnits <= 0:
            break
          if remainingUnits mod int64(activeStudents) != 0:
            continue
          let basePercent = remainingUnits div int64(activeStudents)
          if basePercent >= 1 and basePercent + int64((slabCount - 1) * stepSize) <= int64(maxPercent):
            allocationCount += 1
      if lowestStart > lowestCenti:
        let nextStart = lowestStart - 1
        indexSum = indexSum + int64(residueCounts[nextStart mod slabStep])
        activeStudents = activeStudents + scoreCounts[nextStart]
        residueCounts[nextStart mod slabStep] = residueCounts[nextStart mod slabStep] + scoreCounts[nextStart]

  appendOutput($allocationCount)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Scores are counted by hundredth value.
Residue counts update the index sum in constant time.
The step loop stops at the percentage cap.

## Complexity

The enumeration covers every width and lower bound, then tests each percentage step.

| phase | time | space |
|---|---|---|
| input read | one pass over N scores | one input string and a score histogram |
| width sweep | at most 150 widths and 151 lower bounds | residue counts per width |
| percentage loop | up to 100 steps per pair | constant space |
| output | one line per data set | block buffer |

The residue update avoids rescanning students for each lower bound.

| measure | Big O |
|---|---|
| time | O(W L D + N), W at most 150, L at most 151, D at most 100 |
| space | O(N + L) |

Rescanning every student for every width and lower bound would replace N with W times L times N. The incremental sums remove that cost.
