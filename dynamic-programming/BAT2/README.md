# BAT2 — BATMAN2 (SPOJ)

<https://www.spoj.com/problems/BAT2/>

## Problem

Two searchers walk through a row of tagged rooms in opposite directions. Each step must reach a higher tag, and the goal is the largest combined room count.

Each test case gives the room count, then that many tags. Print one maximum per test case.

| item | bound |
|---|---|
| rooms per case | 1 to 100 |
| room tags | integers, repeats allowed |
| judge limit | 1000 ms, 1536 MB |

A room can be skipped or used by one searcher.

Sample input:

```
1
6
5 3 4 6 1 2
```

Sample output:

```
5
```

## Idea

Picture two shelves: books rise on the left shelf and fall on the right shelf, and each book goes to at most one shelf.

The algorithm is a two-track subsequence DP. A state stores the last room used by each searcher. Each new room updates every state in O(n^2), so one case costs O(n^3).

Trying every skip, forward, or backward assignment costs 3^n. The DP keeps only the best count per pair of tails.

The state pair captures everything a future step needs.

## Why It Works

1. A forward searcher visits tags in strictly increasing order.
2. A backward searcher visits tags in strictly decreasing order.
3. Each room is skipped, used forward, or used backward.
4. A state records the last room assigned to each track.
5. A new room joins a track only when its tag beats that track's tail.
6. The largest state count after the last room is the answer.

| term | meaning |
|---|---|
| `forwardTail` | last room index on the increasing track |
| `backwardTail` | last room index on the decreasing track |
| `emptyTail` | sentinel for a track with no room yet |
| `currentStates` | best counts for all tail pairs before a room |
| `bestSearched` | largest count found after all rooms |

The sentinel lets either track start at any room.

A script trace shows the best count after each prefix of `5 3 4 6 1 2`:

```
prefix 5        -> 1
prefix 5 3      -> 2
prefix 5 3 4    -> 3
prefix 5 3 4 6  -> 4
prefix 5 3 4 6 1 -> 5
prefix 5 3 4 6 1 2 -> 5
```

The trace ends at 5, which matches the sample output.

## Code

**Input and scanning.** The reader loads the case count, room count, and tags.

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

The scanner skips separators and reads positive integers.
Only digit characters drive the value.
One input string serves every case.

**Two-track state DP.** Each room extends legal states or goes unused.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let roomCount = nextInt(inputData, scanPos)
  var roomTags = newSeq[int](roomCount)
  for roomIndex in 0 .. roomCount - 1:
    roomTags[roomIndex] = nextInt(inputData, scanPos)
  let stateSize = roomCount + 1
  let emptyTail = roomCount
  var currentStates = newSeq[int](stateSize * stateSize)
  for stateSlot in 0 .. currentStates.len - 1:
    currentStates[stateSlot] = -1
  currentStates[emptyTail * stateSize + emptyTail] = 0
  for roomIndex in 0 .. roomCount - 1:
    var nextStates = newSeq[int](currentStates.len)
    for stateSlot in 0 .. currentStates.len - 1:
      nextStates[stateSlot] = currentStates[stateSlot]
    for forwardTail in 0 .. roomCount:
      for backwardTail in 0 .. roomCount:
        let searchedCount = currentStates[forwardTail * stateSize + backwardTail]
        if searchedCount < 0:
          continue
        if forwardTail == emptyTail or roomTags[forwardTail] < roomTags[roomIndex]:
          let targetSlot = roomIndex * stateSize + backwardTail
          if searchedCount + 1 > nextStates[targetSlot]:
            nextStates[targetSlot] = searchedCount + 1
        if backwardTail == emptyTail or roomTags[backwardTail] > roomTags[roomIndex]:
          let targetSlot = forwardTail * stateSize + roomIndex
          if searchedCount + 1 > nextStates[targetSlot]:
            nextStates[targetSlot] = searchedCount + 1
    currentStates = nextStates
  var bestSearched = 0
  for stateSlot in 0 .. currentStates.len - 1:
    if currentStates[stateSlot] > bestSearched:
      bestSearched = currentStates[stateSlot]
  appendOutput($bestSearched)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Invalid states hold -1 and are skipped.
Copying old states implements the skip choice.
Strict comparisons keep equal tags apart.

## Complexity

The DP visits one state pair for each new room.

| phase | time | space |
|---|---|---|
| input read | one pass over tags | one input string |
| state DP | n rooms times n^2 pairs | two n^2 tables |
| output | one line per case | block buffer |

The two tables dominate memory at 100 rooms.

| measure | Big O |
|---|---|
| time per case | O(n^3) |
| space per case | O(n^2) |

Enumerating all assignments costs 3^n instead of n^3.

The pair-state DP is the takeaway for small n.
