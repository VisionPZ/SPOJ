# CRAN04 — Audition (SPOJ)

<https://www.spoj.com/problems/CRAN04/>

## Problem

Count index pairs whose enclosed segment holds a target number of boys. Each case gives a binary line, where 1 marks a boy and 0 marks a girl.

Input starts with the test count. Each case gives the line length and the target, then a string of that length. Output one count per case. A pair with i equal to j is valid.

The bounds from the statement:

| item | bound |
|---|---|
| test cases | 1 to 10 |
| line length N | 1 to 1,000,000 |
| target K | 0 to 1,000,000 |
| judge limit | 2000 ms, 1536 MB |

Pair counts reach N squared, so the answer needs 64 bits.

Sample input:

```
3
4 1
0101
5 2
01010
5 4
01010
```

Sample output:

```
6
4
0
```

## Idea

Count matching boy totals the way you match ticket stubs with the same number.

A pair encloses K boys when the prefix totals at its endpoints differ by K. A frequency table over prefix totals counts those endpoints in one pass. The algorithm is prefix-sum frequency counting. Each character costs one lookup and one increment. Checking every pair costs quadratic time.

One linear pass replaces all start and end pairs.

## Why It Works

1. `boysSoFar` counts the boys up to the current position.
2. A pair from i to j encloses the difference of their prefix totals.
3. For that difference to equal `boyTarget`, the earlier prefix must be `boysSoFar` minus `boyTarget`.
4. A negative needed prefix cannot occur, so the code skips it.
5. Every prefix total lies between zero and the number of boys.

The code uses these names:

| term | meaning |
|---|---|
| `peopleCount` | length of the binary line |
| `boyTarget` | required number of boys in a pair |
| `boysSoFar` | boys counted up to the current position |
| `prefixFrequency` | count of earlier prefixes at each total |
| `pairCount` | number of valid pairs found so far |

The table links each name to one step of the count.

The first sample case with target one traces as follows:

```
start: frequency(0) = 1, boys = 0
pos 0 '0': boys 0, need -1, add 0, frequency(0) = 2
pos 1 '1': boys 1, need  0, add 2, frequency(1) = 1
pos 2 '0': boys 1, need  0, add 2, frequency(1) = 2
pos 3 '1': boys 2, need  1, add 2, frequency(2) = 1
total = 6
```

The six additions match the sample output.

A target above the boy count gives no pairs, because the needed prefix stays negative.

## Code

**Input and scanning.** The reader loads the header values and finds the binary token.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc skipWhitespace(data: string, pos: var int) =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
```

`skipWhitespace` moves the cursor to the next non-space byte.
The token loop records its start and end without copying it.
Integer tokens need no sign in this problem.

**Prefix count.** Each position adds the frequency of its needed prefix.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let peopleCount = nextInt(inputData, scanPos)
  let boyTarget = nextInt(inputData, scanPos)
  skipWhitespace(inputData, scanPos)
  let tokenStart = scanPos
  while scanPos < inputData.len and inputData[scanPos] > ' ':
    scanPos += 1
  let tokenLength = scanPos - tokenStart
  var prefixFrequency = newSeq[int64](peopleCount + 1)
  prefixFrequency[0] = 1
  var boysSoFar = 0
  var pairCount: int64 = 0
  for personIndex in 0 ..< tokenLength:
    if inputData[tokenStart + personIndex] == '1':
      boysSoFar = boysSoFar + 1
    let neededPrefix = boysSoFar - boyTarget
    if neededPrefix >= 0:
      pairCount = pairCount + prefixFrequency[neededPrefix]
    prefixFrequency[boysSoFar] = prefixFrequency[boysSoFar] + 1
  appendOutput($pairCount)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The frequency table uses 64-bit counts for large pair totals.
`neededPrefix` is checked before it indexes the table.
The output buffer flushes in large blocks.

## Complexity

Each case scans the line once and allocates one frequency table.

| phase | time | space |
|---|---|---|
| input read | one pass over tokens | one input string |
| prefix count | one pass over characters | table of N+1 counts |
| output | one line per case | block buffer |

The phase table shows one dominant linear pass.

| measure | Big O |
|---|---|
| time | O(N) per case |
| space | O(N) per case |

Testing every pair costs O(N^2) time per case.
Prefix frequencies reduce that work to one pass.
