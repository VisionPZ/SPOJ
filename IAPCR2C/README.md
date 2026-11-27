# IAPCR2C — Study Room (SPOJ)
<https://www.spoj.com/problems/IAPCR2C/>

## Problem

Working computers sit in one row of seats. A student uses a working computer at their own seat or at either neighbor. Count how many students can use a working computer.

Input starts with the case count `T`. Each case gives `n` students and `m` working computer positions on one line. The next line holds the `m` positions, not necessarily sorted. Output one line per case as `Case k: answer`.

| item | bound |
|---|---|
| cases T | 1 to 60 |
| students n | 1 to 100000 |
| working computers m | 1 to n |
| position b | 1 to n |
| judge limit | 1000 ms, 1536 MB |

The row length n drives the design, since each case marks seats in that row.

Sample input:

```
2
6 2
2 5
5 2
2 5
```

Sample output:

```
Case 1: 6
Case 2: 5
```

## Idea

Each working computer lights three seats, like a lamp that reaches its own seat and both neighbors. Mark every lit seat, then count the marks.

The program uses a boolean array of seats. It marks the three seats around each working computer and clips the marks to the row. Marking one computer costs O(1), and counting the row costs O(n).

Checking every student against every working computer costs O(n·m) per case. That grows too fast when both values reach 100000.

Takeaway: mark the covered seats once, then count them once.

## Why It Works

1. A student at seat s can use a working computer at s−1, s, or s+1.
2. A working computer at seat b therefore serves seats b−1, b, and b+1.
3. Clipping to 1 and n keeps marks inside the row.
4. A seat is counted once because the array stores a boolean, not a count.
5. The union of all three-seat blocks is exactly the set of students who can use a computer.

| term | meaning |
|---|---|
| `canUse[seat]` | whether some working computer reaches this seat |
| `computerSeat` | position of one working computer |
| `firstSeat` | leftmost seat lit by that computer |
| `lastSeat` | rightmost seat lit by that computer |
| `happyStudents` | number of lit seats in the row |

The sample lights all six seats, then only five seats when the row ends at five.

```
n = 6, positions 2 5
computer 2 lights seats 1 2 3
computer 5 lights seats 4 5 6
lit seats = 1 2 3 4 5 6 -> answer 6

n = 5, positions 2 5
computer 2 lights seats 1 2 3
computer 5 lights seats 4 5
lit seats = 1 2 3 4 5 -> answer 5
```

Overlapping blocks merge naturally, because a marked seat stays marked.

## Code

**Input and scanner.** The whole stream is read once and scanned by index.

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

The scanner skips spaces and line breaks. Each call returns one nonnegative integer. Reading once keeps input work linear in the file size.

**Output helper.** Text pieces go into one buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after 131072 bytes. No write happens per seat or per number. Final output uses one more write.

**Seat marking.** Each case marks three seats per working computer.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let studentCount = nextInt(inputData, scanPos)
  let workingCount = nextInt(inputData, scanPos)
  var canUse = newSeq[bool](studentCount + 2)
  for computerIndex in 0 .. workingCount - 1:
    let computerSeat = nextInt(inputData, scanPos)
    var firstSeat = computerSeat - 1
    if firstSeat < 1:
      firstSeat = 1
    var lastSeat = computerSeat + 1
    if lastSeat > studentCount:
      lastSeat = studentCount
    var seat = firstSeat
    while seat <= lastSeat:
      canUse[seat] = true
      seat += 1
  var happyStudents = 0
  for seat in 1 .. studentCount:
    if canUse[seat]:
      happyStudents += 1
  appendOutput("Case ")
  appendOutput($(caseIndex + 1))
  appendOutput(": ")
  appendOutput($happyStudents)
  outputBuffer.add '\n'
```

The extra two cells make index `studentCount + 1` safe. Positions need no sort because marks commute. The case label follows the sample format exactly.

## Complexity

Marking and counting are both linear per case.

| phase | time | space |
|---|---|---|
| input read | one pass over the stream | input string |
| seat marking | O(m) marks | n booleans |
| seat counting | O(n) checks | none extra |
| output | one line per case | block buffer |

Seat marking and counting dominate, both linear in the case size.

| measure | Big O |
|---|---|
| time per case | O(n + m) |
| total time | O(sum of n + m) |
| working space | O(n) |

Checking each student against each working computer would cost O(n·m). Marking once per computer reduces that to O(n + m).

Takeaway: coverage is a marking problem, not a matching problem.
