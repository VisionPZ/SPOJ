# BUET19C — Map (SPOJ)

<https://www.spoj.com/problems/BUET19C/>

## Problem

Every submission carries an ID, and equal IDs mean the same work. Count how many different IDs appear in the list.

Input starts with N, the submission count, then N IDs. Output is one line holding the number of distinct IDs.

| item | bound |
|---|---|
| submission count N | 1 to 100000 |
| each ID | 1 to 100000 |
| judge limit | 1000 ms, 1536 MB |

The ID bound allows a fixed table, and the count sets the pass length.

The sample case:

```
5
2 1 3 2 100
```

```
4
```

## Idea

Tick each ID once on a roster, like a teacher marking names as students arrive; a second tick for the same name adds nothing. The algorithm uses a direct lookup table indexed by ID. Each ID costs one array test, so the pass stays linear. Sorting the IDs first would cost N log N comparisons for the same count. One table and one counter settle the whole list.

## Why It Works

1. The table starts with every box false, so no ID has been counted yet.
2. The first time an ID appears, its box flips to true and the counter rises by one.
3. Later copies find the box already true, so they cannot count twice.
4. Every ID either gets a first tick or was ticked before, so none is missed.
5. IDs stay within the table size, so a plain array replaces a hash map.

| Term | Meaning |
|---|---|
| `seenId` | one box per ID, true once that ID has appeared |
| `distinctCount` | how many IDs got a first tick |
| `offlineCount` | N, the number of submissions |
| `maximumIdValue` | the largest legal ID, which sets the table size |

The counter holds the number of unique IDs after one pass.

A script-traced example for the sample list:

```
ids 2 1 3 2 100
sorted 1 2 2 3 100
run heads 1 2 3 100
answer 4
```

The trace matches the sample answer.

## Code

**Input, hand scanner, and table size.** This block loads the input and reads integers by index.

```nim
const flushBlockBytes = 1 shl 17
const maximumIdValue = 100000

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

The scanner skips all non-digits, so spaces and newlines need no special case.
Each call advances the index past exactly one ID.
The constant fixes the number of boxes in the mark table.

**Buffered marking and output.** This block marks each ID once and writes the count.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let offlineCount = nextInt(inputData, scanPos)
var seenId = newSeq[bool](maximumIdValue + 1)
var distinctCount = 0
var readIndex = 0
while readIndex < offlineCount:
  let submittedId = nextInt(inputData, scanPos)
  if not seenId[submittedId]:
    seenId[submittedId] = true
    distinctCount += 1
  readIndex += 1
appendOutput($distinctCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs exactly N times, one table test per ID.
An ID is counted only when its box was false.
One write emits the final count line.

## Complexity

The cost splits into reading, one table test per ID, and one write.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | one input string |
| Marking | one lookup per ID | one boolean table |
| Output | one write | block buffer |

The boolean table adds a fixed 100001 boxes on top of the input buffer.

| Measure | Big O |
|---|---|
| Time | O(N) |
| Space | O(N) input plus a fixed table |

Every ID is handled once, so the bound tracks the input length.

Sorting first and counting runs costs O(N log N) comparisons. The table keeps the pass linear without any ordering step.
