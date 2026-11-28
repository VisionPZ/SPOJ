# DONALDO — DONALDO (SPOJ)

<https://www.spoj.com/problems/DONALDO/>

## Problem

Texts arrive at known moments during one day, and no girlfriend sends two texts inside the same `I`-second window. Report the fewest girlfriends that could explain all the moments.

Input starts with `T`. Each case gives `N`, then `N` moments written as `H:M:S`, then the window length `I`. Output one line per case in the form `Case X: Y`.

| item | bound |
|---|---|
| test cases `T` | 0 to 50 |
| texts `N` | 0 to 20000 |
| hour `H` | 0 to 23 |
| minute `M`, second `S` | 0 to 59 |
| window length `I` | 1 to 86400 seconds |
| judge limit | 1000 ms, 1536 MB |

A moment `H:M:S` means `3600H + 60M + S` seconds after midnight, and `N²` means N squared. The notation `I` counts seconds, so a window starting at `t` ends at `t + I - 1`.

Sample input:

```
2
3
8:39:17
17:17:17
21:59:59
86400
3
17:17:17
21:59:59
8:39:16
48042
```

Sample output:

```
Case 1: 3
Case 2: 2
```

## Idea

Two texts less than `I` seconds apart cannot share a sender, like overlapping meetings that need separate rooms. The answer is the largest number of texts inside any window of length `I`. The solution counts texts per second, builds prefix sums, then tests every possible window start. Each case costs one pass over 86400 seconds, so neither sorting nor pairwise checks are needed.

## Why It Works

1. A window of length `I` covers the seconds `t` through `t + I - 1`, inclusive.
2. Two texts conflict exactly when their second difference is below `I`.
3. Texts and conflict edges form an interval graph, whose clique size equals the number of colors needed.
4. The largest clique is the fullest window, so its size is the required answer.
5. Prefix sums give each window count with one subtraction.

| term | meaning |
|---|---|
| `secondCounts` | number of texts at each second of the day |
| `prefixCounts` | cumulative text counts up to each second |
| `intervalLength` | window length `I` in seconds |
| `bestCrowd` | largest window count found |

A script converted the second sample case to seconds and listed its windows.

| window start | window end | texts inside |
|---|---|---|
| 31156 | 79197 | 31156, 62237 |
| 62237 | 110278 | 62237, 79199 |

The full window gives two, matching `Case 2: 2`.

## Code

**Input and scanning.** The reader loads all lines and provides a digit-only scanner.

```nim
const flushBlockBytes = 1 shl 17
const secondsPerDay = 86400
const secondsPerHour = 3600
const secondsPerMinute = 60

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

Colons are skipped as non-digits.
Each `H:M:S` becomes three numbers.
The day length supports counting arrays.

**Output buffering.** One buffer collects all case lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Each case appends one formatted line.
Large blocks flush during the loop.
A final flush ends the run.

**Counting and window sweep.** Each case fills counts, builds prefixes, and scans windows.

```nim
var secondCounts = newSeq[int](secondsPerDay)
var prefixCounts = newSeq[int](secondsPerDay + 1)

let testCount = nextInt(inputData, scanPos)
for caseNumber in 1 .. testCount:
  secondCounts.setLen 0
  secondCounts.setLen secondsPerDay
  let textCount = nextInt(inputData, scanPos)
  for textIndex in 0 .. textCount - 1:
    let hourValue = nextInt(inputData, scanPos)
    let minuteValue = nextInt(inputData, scanPos)
    let secondValue = nextInt(inputData, scanPos)
    let totalSeconds = hourValue * secondsPerHour + minuteValue * secondsPerMinute + secondValue
    secondCounts[totalSeconds] += 1
  let intervalLength = nextInt(inputData, scanPos)
  prefixCounts[0] = 0
  for secondIndex in 0 .. secondsPerDay - 1:
    prefixCounts[secondIndex + 1] = prefixCounts[secondIndex] + secondCounts[secondIndex]
  var bestCrowd = 0
  for startSecond in 0 .. secondsPerDay - 1:
    var endSecond = startSecond + intervalLength - 1
    if endSecond >= secondsPerDay:
      endSecond = secondsPerDay - 1
    let crowdSize = prefixCounts[endSecond + 1] - prefixCounts[startSecond]
    if crowdSize > bestCrowd:
      bestCrowd = crowdSize
  appendOutput("Case " & $caseNumber & ": " & $bestCrowd & "\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Resetting the counts handles empty cases.
The window end clips at the last second of the day.
The answer is written with the case number.

## Complexity

The sweep visits every second once per case.

| phase | time | space |
|---|---|---|
| input read | one pass over `N` moments | one input string |
| count and prefix | one pass over 86400 seconds | two counting arrays |
| window sweep | one pass over 86400 starts | constant extra space |

| measure | Big O |
|---|---|
| time | O(T × 86400 + total N) |
| space | O(86400) |

Checking every pair of texts would need `N²` comparisons and would stall on the largest cases.

The fixed-day sweep keeps every case at the same predictable cost.
