# EDUPT52 — Round Robin Task Scheduler (SPOJ)

<https://www.spoj.com/problems/EDUPT52/>

## Problem

N processes arrive in order and share one CPU under Round Robin scheduling. Report the process IDs in the exact order in which they finish.

The first line holds N and Q, with 1 ≤ N ≤ 100000 and 1 ≤ Q ≤ 10^9. The second line holds the N burst times T_i, each between 1 and 10^9. Print one line with N IDs separated by single spaces.

| item | bound |
|---|---|
| processes N | 1 to 100000 |
| quantum Q | 1 to 10^9 |
| burst T_i | 1 to 10^9 |
| judge limit | 1000 ms, 1536 MB |

A process leaves the queue for good on the visit that finishes its burst.

Sample input:

```
4 3
5 10 3 8
```

Sample output:

```
3 1 4 2
```

## Idea

Each job finishes on its own numbered visit, like shoppers at one counter who each need a known number of turns.

The method counts visits with a ceiling division and sorts by visit count, then by arrival index. Counting costs one division per process. Simulating every quantum costs up to 10^9 steps for one process when Q is 1.

Takeaway: count the visits instead of replaying them.

## Why It Works

1. A process with burst T and quantum Q needs ceil(T / Q) visits to the CPU.
2. On its last visit the remaining time fits inside one quantum, so it finishes there.
3. Each unfinished visit returns the process to the back of the queue.
4. After every full round, the surviving processes are still in arrival order.
5. Therefore processes with the same visit count finish in increasing ID order.
6. Sorting by (turnCount, processId) reproduces the exact completion order.

| term | meaning |
|---|---|
| `processCount` | how many processes arrive |
| `quantumSize` | the fixed time slice Q |
| `burstTime` | the total CPU time T_i of one process |
| `turnCount` | ceil of burst divided by quantum |
| `processList` | records of visit count and process ID |

Every process becomes one record with two comparable fields.

For the sample, Q is 3 and the bursts are 5 10 3 8. The visit counts are 2 4 1 3. Sorting by visit count, then ID, gives process 3, then 1, then 4, then 2.

The numerator `burstTime + quantumSize - 1` is kept in `int64`, so large values stay exact. Ties are broken by ID, which matches the queue order.

## Code

**Input and scanning.** The hand reader loads the header and all burst times.

```nim
import algorithm

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

The algorithm module supplies the sort.
Whitespace between numbers is ignored.
All inputs are positive, so no minus branch is needed.

**Buffered output.** One string collects the final line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes only when it grows past the block size.
The last write emits the completed line.

**Completion order.** The comparison orders visits first and IDs second.

```nim
type ProcessRecord = tuple[turnCount: int64; processId: int]

proc finishesEarlier(firstRecord, secondRecord: ProcessRecord): int =
  if firstRecord.turnCount < secondRecord.turnCount: return -1
  if firstRecord.turnCount > secondRecord.turnCount: return 1
  if firstRecord.processId < secondRecord.processId: return -1
  if firstRecord.processId > secondRecord.processId: return 1
  return 0
```

The first two tests compare visit counts.
The next two tests break ties by arrival ID.
Equal records compare as equal.

**Count and emit.** Each burst becomes one visit count, then records are sorted.

```nim
let processCount = nextInt(inputData, scanPos)
let quantumSize = int64(nextInt(inputData, scanPos))
var processList = newSeq[ProcessRecord](processCount)
for processIndex in 0 .. processCount - 1:
  let burstTime = int64(nextInt(inputData, scanPos))
  let turnCount = (burstTime + quantumSize - 1) div quantumSize
  processList[processIndex] = (turnCount, processIndex + 1)
sort(processList, finishesEarlier)
var outputLine = ""
for processIndex in 0 .. processCount - 1:
  if processIndex > 0:
    outputLine.add ' '
  outputLine.add $processList[processIndex].processId
appendOutput(outputLine)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Ceiling division uses the standard add-before-divide form.
Process IDs start at 1, matching the arrival order.
Spaces are added before every ID except the first.

## Complexity

Counting is linear, and sorting orders all N records.

| phase | time | space |
|---|---|---|
| input read | one pass over N bursts | one input string |
| visit count | one division per process | N records |
| sort | N comparisons at each level | constant extra |
| output | one line | one block buffer |

| measure | Big O |
|---|---|
| time | O(N log N) |
| space | O(N) |

Replaying every quantum slice costs O(sum of T_i divided by Q) steps.

Takeaway: a visit count and one sort replace the whole simulation.
