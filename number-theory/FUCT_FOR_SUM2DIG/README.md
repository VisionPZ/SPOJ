# FUCT_FOR_SUM2DIG — Sum 2 digits (SPOJ)

<https://www.spoj.com/problems/FUCT_FOR_SUM2DIG/>

## Problem

The input gives a target sum n. The task is to print every two-digit number whose two digits add to n, one per line, written as `17 = 1 + 7 = 8`. If no two-digit number works, print `NO`.

Input holds one integer. Output holds one line per solution, or `NO`.

| Item | Bound |
|---|---|
| Target sum | 1 ≤ n ≤ 18 |
| Judge limit | 1000 ms, 1536 MB |

The sample case:

```
8
```

```
17 = 1 + 7 = 8
26 = 2 + 6 = 8
35 = 3 + 5 = 8
44 = 4 + 4 = 8
53 = 5 + 3 = 8
62 = 6 + 2 = 8
71 = 7 + 1 = 8
80 = 8 + 0 = 8
```

## Idea

Once the tens digit is chosen, the ones digit is forced: it must be n minus the tens digit. So the program only loops over the legal tens digits instead of testing all 90 two-digit numbers. Analogy: filling a two-slot form where the second box is computed from the first. The loop runs at most 9 times per target, versus 90 digit-sum checks for the scan-everything version.

## Why It Works

1. A two-digit number with tens digit a and ones digit b has digit sum a + b, so b = n − a is the only candidate for each a.
2. The tens digit of a two-digit number is 1..9, and the ones digit must be 0..9, which forces a into [max(1, n − 9), min(9, n)].
3. Walking a upward lists the numbers in ascending order, as the sample shows.
4. An empty range, such as n = 0 or n = 19, prints `NO`.
5. The program answers every integer in the input, which matches the single-number spec.

| Term | Meaning |
|---|---|
| `targetSum` | digit sum asked for by the input |
| `lowTens`, `highTens` | first and last legal tens digit |
| `onesDigit` | forced value targetSum − tensDigit |
| `foundAny` | remembers whether at least one line was printed |

The loop prints each solution exactly once.

A script-traced example from `gen.py`:

```
target 8 scan 10..99 hits: [17, 26, 35, 44, 53, 62, 71, 80]
```

The hits match the eight sample lines.

## Code

**Input and hand scanner.** This block loads stdin and reads integers by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextIntOrNegative(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  if position >= data.len:
    return -1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value
```

One readLine loop collects all input bytes.
The -1 return marks end of input because real targets are non-negative.
Scanning costs one pass over the consumed characters.

**Buffered output.** This block collects finished answer lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after reaching 128 KiB.
One final write emits any remaining bytes.

**Solution loop.** This block fixes the tens digit and derives the ones digit.

```nim
while true:
  let targetSum = nextIntOrNegative(inputData, scanPos)
  if targetSum < 0:
    break
  var lowTens = targetSum - 9
  if lowTens < 1:
    lowTens = 1
  var highTens = targetSum
  if highTens > 9:
    highTens = 9
  var foundAny = false
  for tensDigit in lowTens..highTens:
    let onesDigit = targetSum - tensDigit
    appendOutput($(tensDigit * 10 + onesDigit))
    appendOutput(" = ")
    appendOutput($(tensDigit))
    appendOutput(" + ")
    appendOutput($(onesDigit))
    appendOutput(" = ")
    appendOutput($(targetSum))
    appendOutput("\n")
    foundAny = true
  if not foundAny:
    appendOutput("NO\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

`lowTens` keeps the ones digit at most 9; `highTens` keeps it at least 0.
An empty range leaves `foundAny` false and prints `NO`.
Each line costs nine buffer appends.

## Complexity

The cost is the input pass plus the printed lines.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Solving | at most 9 checks per target | constant |
| Output | one write per 128 KiB block | block buffer |

At most 9 lines appear per target.

| Measure | Big O |
|---|---|
| Time | O(N + number of printed lines) |
| Space | O(N) for the input buffer |

Scanning all 90 two-digit numbers per target costs O(90) checks; the forced-ones-digit loop cuts that to at most 9.
