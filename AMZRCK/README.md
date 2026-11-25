# AMZRCK — Amz Rock (SPOJ)

<https://www.spoj.com/problems/AMZRCK/>

## Problem

Count playlists chosen from tracks labelled 1 through n with no two consecutive labels in the same playlist. The empty playlist counts, and the input holds several test cases with one value n each.

| item | bound |
|---|---|
| test cases | given by the first input number |
| tracks n | positive integer with answer below 1000000000 |
| judge limit | 100 ms, 1536 MB |

The answer bound keeps n below 44, so repeated addition stays cheap.

Sample input:

```
2
1
2
```

Sample output:

```
2
3
```

## Idea

Decide the fate of the last track, like choosing seats in a row with no neighbours. If the last track is skipped, the earlier tracks form any valid playlist. If it is chosen, the previous track must be skipped, leaving any valid playlist of the earlier tracks.

This gives the Fibonacci recurrence, with one addition per track. Checking every subset costs exponential work and is far slower.

## Why It Works

1. Let W(n) count valid playlists from n tracks.
2. Playlists without track n number W(n-1).
3. Playlists with track n cannot contain track n-1, so they number W(n-2).
4. The two groups are disjoint and cover every playlist, so W(n) = W(n-1) + W(n-2).
5. The base values are W(0) = 1 and W(1) = 2, which include the empty playlist.

| term | meaning |
|---|---|
| `waysTable` | W(n) for every size up to the largest case |
| `trackCounts` | number of tracks in each test case |
| `largestCount` | largest track count in the input |
| `trackSize` | size currently being filled in the table |

One table serves every case, so cases share the same additions.

A script-generated trace lists the first values by hand enumeration.

| tracks n | valid playlists |
|---|---|
| 0 | 1 |
| 1 | 2 |
| 2 | 3 |
| 3 | 5 |
| 4 | 8 |

The row for n = 2 matches the second sample answer.

## Code

**Input and scanning.** The hand reader loads the case count and each track count.

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

The scanner skips line breaks between test cases.
It reads only positive integers, so no sign branch is needed.
Reading once keeps parsing separate from counting.

**Table build and output.** One sweep fills all answers up to the largest case.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
var trackCounts = newSeq[int](caseCount)
var largestCount = 0
for caseIndex in 0 .. caseCount - 1:
  trackCounts[caseIndex] = nextInt(inputData, scanPos)
  if trackCounts[caseIndex] > largestCount:
    largestCount = trackCounts[caseIndex]
var waysTable = newSeq[int64](largestCount + 1)
waysTable[0] = 1
if largestCount >= 1:
  waysTable[1] = 2
for trackSize in 2 .. largestCount:
  waysTable[trackSize] = waysTable[trackSize - 1] + waysTable[trackSize - 2]
for caseIndex in 0 .. caseCount - 1:
  appendOutput($(waysTable[trackCounts[caseIndex]]))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The table loop adds once per newly built size.
Every answer is appended to one buffered string.
The final write flushes all accumulated lines together.

## Complexity

Work grows with the largest track count, not with the number of subsets.

| phase | time | space |
|---|---|---|
| input read | one pass over the input string | one input string |
| count extension | one addition per new size | two counters |
| output | one line per case | block buffer |

The phase table shows that all cases share the same growing table.

| measure | Big O |
|---|---|
| time | O(T + n_max) |
| space | O(1) beyond the input string |

Testing every subset costs O(2^n) per case, while this sweep costs O(n).
