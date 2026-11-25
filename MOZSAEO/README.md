# MOZSAEO — Sharmeen and Even Odd (SPOJ)

<https://www.spoj.com/problems/MOZSAEO/>

## Problem

Sharmeen adds two large non-negative integers and reports whether the sum is even or odd. Each number can hold tens of thousands of digits, so building the sum is impractical.

The first line gives the case count. Each case then gives two integers separated by whitespace. Print `even` or `odd` on its own line for every case.

The limits from the statement:

| Item | Bound |
|---|---|
| Test cases | 1 ≤ t ≤ 50 |
| Addends | 0 ≤ A, B ≤ 10^50000 |
| Addend length | at most 50,001 digits |
| Judge limit | 1000 ms, 1536 MB |

Digit length drives the design, not the case count.

The sample case appears below. The statement renders it without line breaks.

```
2
1 2
2 2
```

```
odd
even
```

## Idea

Only the final digit decides parity, like checking the unit digit on a calculator to settle even or odd. The program reads each number with an index scanner and keeps its last digit. Two addends with equal parity produce an even sum, and mixed parity produces an odd sum. Each number costs one linear scan over its digits, with no big integer allocation. Building full sums would allocate enormous values and run slower.

Reading only the final digit keeps the work bounded by input size.

## Why It Works

1. A decimal integer equals ten times its earlier digits plus its final digit.
2. Ten times any integer is even, so the final digit fixes that integer's parity.
3. Two integers with equal parity have an even sum, and mixed parity gives an odd sum.
4. The scanner advances an index and stores one digit per number, so memory stays small.

The terms used by the program:

| Term | Meaning |
|---|---|
| `firstDigitValue` | digit value of the character `0` |
| `scanPos` | index of the next unread input byte |
| `nextLastDigit` | scanner returning the final digit of one number |
| `firstLastDigit` | final digit of A in the current case |
| `outputBuffer` | string that collects answer lines |

The scanner never allocates a copy of a 50,001-digit number.

A script-traced example from `gen.py`:

```
pair 1 2
sum 3
answer odd
pair 2 2
sum 4
answer even
```

The second pair sums to four, so the sample prints `even`.

## Code

**Input buffer and hand scanners.** This block reads all input and defines both index scanners.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value

proc nextLastDigit(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var lastDigit = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    lastDigit = ord(data[position]) - firstDigitValue
    position += 1
  return lastDigit
```

One readLine loop collects stdin into `inputData`.
`nextInt` reads the case count by advancing `scanPos`.
`nextLastDigit` walks every digit and keeps the most recent one.
Both scanners cost one pass over their bytes.

**Buffered output.** This block stores answer lines and flushes large blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes once it reaches 128 KiB.
One final write emits any remaining bytes after the loop.

**Parity decision loop.** This block answers every test case.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let firstLastDigit = nextLastDigit(inputData, scanPos)
  let secondLastDigit = nextLastDigit(inputData, scanPos)
  if (firstLastDigit + secondLastDigit) mod 2 == 0:
    appendOutput("even\n")
  else:
    appendOutput("odd\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs exactly `caseCount` times.
Each case reads two final digits and appends one short line.
The `mod` operation compares their parity.

## Complexity

The work splits into input scanning, parity decisions, and output.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Case scan | O(D) digits per number | one digit per number |
| Output | one write per 128 KiB block | block buffer |

D is the digit length of one addend, at most 50,001.

The overall bounds:

| Measure | Big O |
|---|---|
| Time | O(D · t) |
| Space | O(input bytes) |

Adding full integers would cost large-integer work per case, so final-digit scanning wins.
