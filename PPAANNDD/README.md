# PPAANNDD — Panda (SPOJ)

<https://www.spoj.com/problems/PPAANNDD/>

## Problem

Find the largest level x that survives deletion. The remaining text must show x copies of P, then x of A, then x of N, then x of D, then x of A. Print that level as one integer.

The input is a single string of the letters P, A, N and D. Its length does not exceed 100000. The empty string always achieves level zero.

| item | bound |
|---|---|
| string length | up to 100000 |
| alphabet | P, A, N, D |
| judge limit | 1000 ms, 1536 MB |

Deleting characters never reorders the remaining ones.

Sample input:

```
PADPAPAAANDNDNPANDADDDAAADA
```

Sample output:

```
3
```

## Idea

Think of matching five consecutive blocks of tickets, each block needing the same number of tickets. Try a level, walk the string once, and grab the earliest matching letter for each needed copy. If every block fills, the level is reachable.

The real algorithm pairs a linear feasibility test with binary search on the level. The test costs O(n) and the search tries O(log n) levels. Testing levels one by one without binary search would cost O(n^2). The takeaway is that feasibility is monotone, so halving the range finds the maximum.

## Why It Works

1. Choosing the earliest possible match never hurts later blocks, because it leaves the most letters unused.
2. A level that is reachable makes every smaller level reachable too.
3. Binary search on that monotone property needs only O(log n) feasibility calls.
4. The largest possible level is the string length divided by five.
5. The search stops when the low and high levels become neighbours.

| term | meaning |
|---|---|
| `letterData` | the input letters in their original order |
| `patternWord` | the five letters PANDA, one per phase |
| `canBuild` | linear test that fills five blocks of equal size |
| `lowLevel` | greatest level known to be reachable |
| `highLevel` | smallest level known to be unreachable |

For the sample, level 3 fills three P copies early. Three A copies, three N copies, three D copies and three final A copies follow. Level 4 cannot fill all five blocks, so the answer is 3.

The binary search never tests a level outside the string bounds.

## Code

**Input and letter scan.** The reader keeps only the four allowed letters.

```nim
const flushBlockBytes = 1 shl 17
const patternWord = "PANDA"

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var letterData = ""
for charIndex in 0 .. inputData.len - 1:
  let currentChar = inputData[charIndex]
  if currentChar == 'P' or currentChar == 'A' or currentChar == 'N' or currentChar == 'D':
    letterData.add currentChar

let stringLength = letterData.len

```

Only PANDA letters enter the working string.
Line breaks and spaces are ignored here.
The length sets the binary search ceiling.

**Feasibility test.** Each phase takes the earliest matching letters it can find.

```nim
proc canBuild(level: int): bool =
  if level == 0:
    return true
  var matchPos = 0
  for phaseIndex in 0 .. 4:
    let wantedChar = patternWord[phaseIndex]
    var matchedCount = 0
    while matchPos < stringLength and matchedCount < level:
      if letterData[matchPos] == wantedChar:
        matchedCount += 1
      matchPos += 1
    if matchedCount < level:
      return false
  return true
```

A phase stops once it has enough letters.
An early failure ends the test immediately.
The scan position always moves forward.

**Binary search and output.** The search narrows the reachable level and writes it once.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var lowLevel = 0
var highLevel = stringLength div 5 + 1
while highLevel - lowLevel > 1:
  let midLevel = (lowLevel + highLevel) div 2
  if canBuild(midLevel):
    lowLevel = midLevel
  else:
    highLevel = midLevel
appendOutput($lowLevel)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The high bound is unreachable by construction.
Each step halves the remaining range.
The final flush writes the single answer line.

## Complexity

Each feasibility call scans the string once, and the binary search calls it logarithmically many times.

| phase | time | space |
|---|---|---|
| input read | one pass over all characters | one input string |
| letter filter | one pass over all characters | one letter string |
| binary search | O(log n) linear tests | constant extra space |

| measure | Big O |
|---|---|
| time | O(n log n) |
| space | O(n) |

Testing every possible level with a linear scan would cost O(n^2) time.
Monotonic feasibility reduces that to O(n log n).
