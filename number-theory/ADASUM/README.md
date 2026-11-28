# ADASUM — Ada and Expenses (SPOJ)

<https://www.spoj.com/problems/ADASUM/>

## Problem

Treat the input as a string of digits and add every contiguous block of digits as a decimal number. Report that sum modulo 1000000007. Leading zeros inside a block contribute nothing, so `001` gives three.

Input is one line of digits from `0` to `9`. Output is one line with the reduced sum.

| Item | Bound |
|---|---|
| Digit count | 1 to 2000000 |
| Modulus | 1000000007 |
| Judge limit | 1000 ms, 1536 MB |

The two million digits make a linear scan necessary.

The first sample case:

```
123
```

The expected output is:

```
164
```

The six blocks are `1`, `2`, `3`, `12`, `23`, `123`, and their sum is 164.

## Idea

A digit contributes to many blocks, like one brick supporting several overlapping arches. Count how many blocks start at or before that digit and how many end after it. Those counts give a closed-form contribution per digit, so one right-to-left pass handles every block. Scanning all blocks would cost quadratic time.

## Why It Works

1. A digit at index `i` can start a block at any index from zero through `i`.
2. That gives `i + 1` possible starts for the digit.
3. If the block ends at index `r`, the digit keeps place value `10^(r-i)`.
4. Summing over all ends gives the repunit `1 + 10 + ... + 10^(n-1-i)`.
5. Multiply the digit, the start count, and that repunit, then reduce modulo the modulus.

| Term | Meaning |
|---|---|
| `repunitValue` | the repunit for digits still to the right |
| `startCount` | number of block starts at or before the current digit |
| `subsequenceSum` | running sum of all contributions |

The formula needs only three numbers per digit.

A script-traced run on the first sample:

```
index digit repunit startCount contribution total
2     3     1        3           9            9
1     2     11       2           44           53
0     1     111      1           111          164
```

The last total matches the sample output.

## Code

**Input and scanning.** The hand reader loads the digit line and splits it into values.

```nim
const flushBlockBytes = 1 shl 17
const modulusValue = 1000000007

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextDigitValue(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  if pos >= data.len:
    return -1
  let digitValue = int(data[pos]) - 48
  pos += 1
  return digitValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips the trailing newline.
It returns minus one after the last digit.
The buffer writes only when it grows past the block size.

**Right-to-left accumulation.** Each digit uses the repunit built from digits on its right.

```nim
var digitValues = newSeq[int8]()
var currentDigit = nextDigitValue(inputData, scanPos)
while currentDigit >= 0:
  digitValues.add int8(currentDigit)
  currentDigit = nextDigitValue(inputData, scanPos)

let digitCount = digitValues.len
var repunitValue: int64 = 1
var subsequenceSum: int64 = 0
var digitIndex = digitCount - 1
while digitIndex >= 0:
  let digitValue = int64(digitValues[digitIndex])
  let startCount = int64(digitIndex + 1)
  subsequenceSum = (subsequenceSum + digitValue * startCount * repunitValue) mod int64(modulusValue)
  repunitValue = (repunitValue * 10 + 1) mod int64(modulusValue)
  digitIndex -= 1
appendOutput($subsequenceSum)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The repunit starts at one for the rightmost digit.
The product stays below two times ten to the sixteenth, so int64 holds it.
The final flush writes one answer line.

## Complexity

The scan visits each digit once, and output is one line.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the digit line | one input string |
| Accumulation | one step per digit | one byte per digit |
| Output | one line | block buffer |

Every phase scales linearly with the digit count.

| Measure | Big O |
|---|---|
| Time | O(n) |
| Space | O(n) |

Enumerating every block would cost O(n^2) and fail on two million digits.
