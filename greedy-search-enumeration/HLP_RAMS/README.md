# HLP_RAMS — Topper Rama Rao (SPOJ)

<https://www.spoj.com/problems/HLP_RAMS/>

## Problem

For a row n of Pascal's triangle, count how many of its n plus 1 entries are even and how many are odd. Report both counts on one line for every test.

Input starts with the test count t. Each following line holds one row index n, from 0 to 1000000000000. Output the even count and the odd count separated by a space.

| item | bound |
|---|---|
| test count t | 1 to 100000 |
| row index n | 0 to 1000000000000 |
| judge limit | 1000 ms, 1536 MB |

The huge row index rules out building any row.

Sample input:

```
2
3
4
```

Sample output:

```
0 4
3 2
```

## Idea

A binomial coefficient is odd exactly when every set bit of n also appears in the chosen position, like a lock whose every open notch must match. The real algorithm counts set bits and applies the Lucas parity rule. Each test costs O(log n) bit steps, while expanding a row costs O(n) entries.

Two small counts replace an entire row of numbers.

## Why It Works

1. By Lucas' theorem, C(n, k) modulo 2 equals the product of C(n bit, k bit) over all binary positions.
2. A single binary factor is zero only when n has bit 0 and k has bit 1.
3. An odd coefficient therefore needs k to have 1 bits only where n has 1 bits.
4. Each set bit of n offers two choices for k, so the odd count is 2 raised to the set bit count.
5. The even count is the row length minus the odd count.

| term | meaning |
|---|---|
| `rowNumber` | the row index n |
| `setBits` | number of 1 bits in n |
| `oddCount` | 2 raised to `setBits` |
| `evenCount` | n plus 1 minus `oddCount` |

For the sample row 4, binary 100 has one set bit. The odd count is 2 and the row length is 5, so the even count is 3. The row 1 4 6 4 1 matches those counts.

The counts fit in int64 because n is at most 1e12.

## Code

**Input and scanner.** The reader loads all tests and parses non-negative integers.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips spaces and line breaks.
The buffer collects every answer before writing.
One read pass handles all 100000 tests.

**Bit count and output.** Each test counts bits and prints two numbers.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rowNumber = int64(nextInt(inputData, scanPos))
  var setBits = 0
  var remaining = rowNumber
  while remaining > 0:
    if (remaining and 1) == 1:
      setBits += 1
    remaining = remaining shr 1
  var oddCount: int64 = 1
  for bitIndex in 0 .. setBits - 1:
    oddCount = oddCount * 2
  let evenCount = rowNumber + 1 - oddCount
  appendOutput($evenCount)
  outputBuffer.add ' '
  appendOutput($oddCount)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop shifts until the row index becomes zero.
Row zero has one set bit count of zero and one odd entry.
Doubling one at a time avoids any large shift type.

## Complexity

The bit loop is the only work per test.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| bit count | one shift per binary digit | constant |
| output | one flush per block | block buffer |

Tests with small row indices finish after a few shifts.

| measure | Big O |
|---|---|
| time | O(t log n), at most 40 shifts per test |
| space | O(1) beyond input and output buffers |

Generating each row entry would cost O(n) per test.

The bit rule keeps all 100000 tests well inside the time limit.
