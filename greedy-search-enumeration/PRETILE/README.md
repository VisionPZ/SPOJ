# PRETILE — Prefix Tiling (SPOJ)

<https://www.spoj.com/problems/PRETILE/>

## Problem

For each length L, count how many leading characters of S agree with the length-L prefix repeated forever. Add those counts over every L from 1 to N. Report one sum per test string.

The first line gives T, the number of tests. Each next line gives one string of N uppercase letters. Output holds T lines, one integer per string.

| item | bound |
|---|---|
| tests T | 1 to 10 |
| string length N | 1 to 100,000 |
| letters | A to Z |
| judge limit | 1000 ms, 1536 MB |

The total answer can reach N squared, so it needs a 64-bit accumulator.

Sample input and output:

```
2
ABCAB
ZZZZZZ
```

```
17
36
```

The first string contributes 1 + 2 + 5 + 4 + 5, and the second contributes six sixes.

## Idea

A repeated prefix is a shifted copy of the same text, like sliding a transparent strip along a row of tiles. The Z array already measures how far any shifted copy agrees with the start. For shift L, the match length is simply L plus Z at L.

The algorithm computes the Z array in one pass with a comparison box. It then adds L and Z[L] for every shift. Z construction costs O(N), so each string is linear. A direct character-by-character retry for every L costs O(N^2) and fails on long strings.

One Z pass replaces all repeated prefix checks.

## Why It Works

1. Z[L] is the longest prefix of S equal to the substring starting at L.
2. While j is below Z[L], position L+j holds the same letter as position j.
3. Repeating that equality down the chain gives S[k] = S[k mod L] for every k below L + Z[L].
4. At k = L + Z[L] the two letters differ, so the repeated prefix stops there.
5. Hence match(L) = L + Z[L], capped by N because Z[L] never exceeds N - L.
6. The base sum of L from 1 to N is N times (N+1) divided by 2.

| term | meaning |
|---|---|
| `zValues` | longest common prefix of S with the suffix at each shift |
| `boxLeft`, `boxRight` | current interval of Z values known to be exact |
| `shiftLength` | the candidate period L |
| `totalMatches` | sum of every match length, held in int64 |

The table maps the proof facts to code names.

A scripted trace of the first sample string uses S = `ABCAB` and N = 5.

```
Z[1] = 0, match(1) = 1 + 0 = 1
Z[2] = 0, match(2) = 2 + 0 = 2
Z[3] = 2, match(3) = 3 + 2 = 5
Z[4] = 0, match(4) = 4 + 0 = 4
Z[5] treated as 0, match(5) = 5
sum = 1 + 2 + 5 + 4 + 5 = 17
```

The trace reproduces the first line of the sample output.

## Code

**Input and word scanning.** The reader loads all lines and pulls each uppercase word.

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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < 'A' or data[pos] > 'Z'):
    pos += 1
  var word = ""
  while pos < data.len and data[pos] >= 'A' and data[pos] <= 'Z':
    word.add data[pos]
    pos += 1
  return word
```

The integer scanner reads the test count.
The word scanner stops at the line break.
Both scanners advance one character per step.

**Z construction and sum.** A moving box shares comparisons across shifts.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let text = nextWord(inputData, scanPos)
  let textLength = text.len
  var zValues = newSeq[int](textLength)
  if textLength > 0:
    zValues[0] = textLength
  var boxLeft = 0
  var boxRight = 0
  for shiftLength in 1 .. textLength - 1:
    if shiftLength < boxRight:
      zValues[shiftLength] = min(boxRight - shiftLength,
          zValues[shiftLength - boxLeft])
    while shiftLength + zValues[shiftLength] < textLength and
        text[zValues[shiftLength]] == text[shiftLength + zValues[shiftLength]]:
      zValues[shiftLength] += 1
    if shiftLength + zValues[shiftLength] > boxRight:
      boxLeft = shiftLength
      boxRight = shiftLength + zValues[shiftLength]
  var totalMatches = int64(textLength) * int64(textLength + 1) div 2
  for shiftLength in 1 .. textLength - 1:
    totalMatches += int64(zValues[shiftLength])
  appendOutput($totalMatches)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each position is compared only while the box expands.
The shift at N needs no Z entry because its match is N.
The accumulator is int64 to hold N squared.

## Complexity

The work is one Z pass and one addition pass per string.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| Z construction | one expanding box over N | N integers |
| sum and output | N additions | block buffer |

Z construction dominates each test.

| measure | Big O |
|---|---|
| time | O(N) per test |
| space | O(N) per test |

Naive retries for every L cost O(N^2) and time out at N = 100,000.

The single Z pass makes every period cheap.
