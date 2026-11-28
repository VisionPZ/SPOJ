# CRAN02 — Roommate Agreement (SPOJ)

<https://www.spoj.com/problems/CRAN02/>

## Problem

Count the contiguous blocks of a signed list whose total is zero. Each test case gives one list, and the answer is the number of those blocks.

Input starts with the test count. Each case gives the list length, then that many integers. Output one count per case, in order.

The bounds from the statement:

| item | bound |
|---|---|
| test cases | 1 to 5 |
| list length | 1 to 1,000,000 |
| each value | -10 to 10 |
| judge limit | 3000 ms, 1536 MB |

The signed values set the prefix range and shape the design.

Sample input:

```
2
4
0 1 -1 0
6
5 2 -2 5 -5 9
```

Sample output:

```
6
3
```

## Idea

Count matching prefix totals the way you pair socks of the same color.

A zero-sum block runs between two prefixes with the same total. A frequency table over prefix totals turns the count into one scan. The algorithm uses direct-index frequency counting over prefix sums. Each value costs one lookup and one increment. A naive scan over every start and end costs quadratic time.

One scan replaces every start and end pair.

## Why It Works

1. A prefix total is the sum of all values up to a position.
2. The block between two prefixes equals their difference.
3. That block sums to zero exactly when the two prefix totals match.
4. A group of k equal prefixes contributes k times (k-1) divided by 2 blocks.
5. Values stay within -10..10, so prefix totals stay within -10n..10n.

The code uses these names:

| term | meaning |
|---|---|
| `runningPrefix` | current prefix total held in 64 bits |
| `prefixOffset` | shift from a prefix total to an array index |
| `prefixFrequency` | count of earlier prefixes at each total |
| `zeroSumCount` | number of zero-sum blocks found so far |

Every name maps to one quantity in the count.

The first sample case traces as follows:

```
initial prefix 0  -> frequency(0) = 1
value 0  -> prefix 0  -> add 1  -> total 1
value 1  -> prefix 1  -> add 0  -> total 1
value -1 -> prefix 0  -> add 2  -> total 3
value 0  -> prefix 0  -> add 3  -> total 6
```

Four prefixes share total zero, and they form six blocks.

Counts fit in 64 bits because one case holds at most 1,000,000 values.

## Code

**Input and scanning.** The reader loads all tokens and parses signed integers.

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
  while pos < data.len and ((data[pos] < '0' or data[pos] > '9') and data[pos] != '-'):
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return signValue * value
```

The scanner skips separators and reads the minus sign when present.
`firstDigitValue` converts a digit character to its numeric value.
Tokens never need a second pass over the input.

**Frequency count.** Each prefix adds its group size to the answer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let elementCount = nextInt(inputData, scanPos)
  let prefixOffset = 10 * elementCount
  var prefixFrequency = newSeq[int32](2 * prefixOffset + 1)
  var runningPrefix: int64 = 0
  prefixFrequency[prefixOffset] = 1
  var zeroSumCount: int64 = 0
  for elementIndex in 0 ..< elementCount:
    runningPrefix = runningPrefix + int64(nextInt(inputData, scanPos))
    let frequencyIndex = int(runningPrefix) + prefixOffset
    zeroSumCount = zeroSumCount + int64(prefixFrequency[frequencyIndex])
    prefixFrequency[frequencyIndex] = prefixFrequency[frequencyIndex] + 1
  appendOutput($zeroSumCount)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The offset keeps every prefix index inside the table.
`zeroSumCount` accumulates in 64 bits before one final write.
The output buffer flushes in large blocks.

## Complexity

Each case scans the list once and allocates one frequency table.

| phase | time | space |
|---|---|---|
| input read | one pass over tokens | one input string |
| prefix count | one pass over values | table of 20n+1 slots |
| output | one line per case | block buffer |

The phase table shows one dominant linear pass.

| measure | Big O |
|---|---|
| time | O(n) per case |
| space | O(n) per case |

Checking every start and end costs O(n^2) time per case.
Direct frequency counting keeps the scan linear.
