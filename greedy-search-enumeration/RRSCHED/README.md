# RRSCHED — Round-Robin Scheduling (SPOJ)

<https://www.spoj.com/problems/RRSCHED/>

## Problem

Each task needs a whole number of seconds. The processor gives one second to every unfinished task in index order, then starts a new pass. Report the clock time when each task finishes.

Input has N on the first line and N durations on the following lines. Output has N lines, one finish time per task in input order.

| item | bound |
|---|---|
| tasks N | 1 to 50,000 |
| duration Ti | 1 to 1,000,000,000 seconds |
| judge limit | 305 ms, 1536 MB |

A task runs once per pass, so pass counts can reach one billion.

Sample input and output:

```
5
8
1
3
3
8
```

```
22
2
11
12
23
```

Task 2 finishes at time 2, and tasks 1 and 5 finish in pass 8.

## Idea

A task that needs t seconds finishes in pass t, like a runner who needs one lap per unit of energy. Count how many seconds pass before that pass, then add the task's place among unfinished tasks in that pass.

Sort distinct durations and sweep them upward. Between two durations, the set of unfinished tasks is fixed, so whole blocks of passes cost one multiplication. A Fenwick tree over task indexes gives the place of a task among unfinished tasks. Direct pass-by-pass simulation needs up to one billion passes.

Blocks of equal progress replace the long simulation.

## Why It Works

1. A task finishes in pass Ti because it receives one second per pass.
2. Before pass t, each task j has contributed min(t-1, Tj) seconds of work.
3. For a run of passes with the same active set, elapsed time grows by the active count per pass.
4. The active set changes only at a duration value present in the input.
5. Within one pass, finished tasks are skipped, so a task's place is its rank among still active indexes.
6. The Fenwick tree holds one entry per active task and answers that rank as a prefix sum.
7. All tasks with equal duration belong to the same pass, so the tree is updated after the whole group.

| term | meaning |
|---|---|
| `taskList` | tasks sorted by duration, keeping input indexes |
| `activeCount` | number of tasks active in the current pass |
| `elapsedBefore` | seconds spent before the current duration's pass |
| `skippedRounds` | full passes between two distinct durations |
| `activeTree` | Fenwick tree holding one entry per active task |
| `earlierActive` | active tasks with a smaller input index |

The table maps the sweep quantities to code names.

A scripted trace of the sample uses active counts 5, 4 and 2.

```
duration 1:  elapsed 0, task 2 rank 1 -> time 2
duration 3:  elapsed 0 + 5 + 1*4 = 9, ranks 2 and 3 -> 11, 12
duration 8:  elapsed 9 + 4 + 4*2 = 21, ranks 1 and 2 -> 22, 23
```

The trace reproduces all five lines of the sample output.

## Code

**Input and Fenwick helpers.** The reader loads durations and defines prefix sums over task indexes.

```nim
import algorithm

const flushBlockBytes = 1 shl 17

type ScheduledTask = object
  duration: int64
  originalIndex: int

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

proc prefixQuery(tree: seq[int], upperIndex: int): int =
  var total = 0
  var cursor = upperIndex
  while cursor > 0:
    total += tree[cursor]
    cursor -= cursor and (-cursor)
  return total

proc addToTree(tree: var seq[int], startIndex: int, deltaValue: int) =
  var cursor = startIndex
  while cursor <= tree.len - 1:
    tree[cursor] += deltaValue
    cursor += cursor and (-cursor)
```

Durations are int64 because finish times can exceed 1e13.
Each task is stored at tree index originalIndex + 1.
The tree starts with every task active.

**Duration sweep.** Equal durations share one pass, and the tree gives each task's place.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let taskCount = nextInt(inputData, scanPos)
var taskList = newSeq[ScheduledTask](taskCount)
for taskIndex in 0 .. taskCount - 1:
  taskList[taskIndex].duration = int64(nextInt(inputData, scanPos))
  taskList[taskIndex].originalIndex = taskIndex
taskList.sort(proc (leftTask, rightTask: ScheduledTask): int =
    cmp(leftTask.duration, rightTask.duration))
var answers = newSeq[int64](taskCount)
var activeTree = newSeq[int](taskCount + 1)
for taskIndex in 0 .. taskCount - 1:
  addToTree(activeTree, taskIndex + 1, 1)
var activeCount = taskCount
var elapsedBefore = (taskList[0].duration - 1) * int64(taskCount)
var groupStart = 0
while groupStart < taskCount:
  let currentDuration = taskList[groupStart].duration
  var groupEnd = groupStart + 1
  while groupEnd < taskCount and taskList[groupEnd].duration == currentDuration:
    groupEnd += 1
  for groupIndex in groupStart .. groupEnd - 1:
    let taskIndex = taskList[groupIndex].originalIndex
    let earlierActive = prefixQuery(activeTree, taskIndex)
    answers[taskIndex] = elapsedBefore + int64(earlierActive) + 1
  for groupIndex in groupStart .. groupEnd - 1:
    addToTree(activeTree, taskList[groupIndex].originalIndex + 1, -1)
  let nextActiveCount = activeCount - (groupEnd - groupStart)
  if groupEnd < taskCount:
    let nextDuration = taskList[groupEnd].duration
    let skippedRounds = nextDuration - currentDuration - 1
    elapsedBefore = elapsedBefore + int64(activeCount) +
        skippedRounds * int64(nextActiveCount)
  activeCount = nextActiveCount
  groupStart = groupEnd
for answerValue in answers:
  appendOutput($answerValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The initial elapsed time covers all passes before the first duration.
A group leaves the tree only after every rank is computed.
The final loop writes answers in input order.

## Complexity

The cost is one sort, one sweep and one prefix query per task.

| phase | time | space |
|---|---|---|
| input read | one pass over N durations | one input string |
| sort | sort of N tasks | N task records |
| duration sweep | N tree updates and queries | N tree entries |
| output | N lines | block buffer |

Sorting and the sweep both scale with N, never with Ti.

| measure | Big O |
|---|---|
| time | O(N log N) |
| space | O(N) |

Naive pass simulation costs O(N times the largest duration) and cannot finish here.

Skipping unchanged passes is what makes the schedule cheap.
