# HARDP — Hard Problem (SPOJ)

<https://www.spoj.com/problems/HARDP/>

## Problem

For each given N, print the fixed text that encodes the Faulhaber polynomial for the sum of the first n N-th powers. The statement leaves the task blank, so the judge compares exact strings rather than evaluated numbers.

Input: several integers N from 1 to 50, one per test case, ending at EOF. Output: one answer line per case. Each line is N, an equals sign, a denominator, then a parenthesised coefficient list.

| item | bound |
|---|---|
| input value N | 1 to 50 |
| test cases | until EOF |
| judge limit | 1000 ms, 1536 MB |

The fixed 50-value domain makes a precomputed table the direct approach.

Sample input:

```
8
9
10
```

Sample output:

```
8=90*(0+0+0+0+45-3+20-42+60+10)
9=20*(0-3+10-14+15+2+0+0+0+0+10)
10=66*(0+0+0+0+0+33+5-33+66-66+55+6)
```

Each line lists even-index coefficients first, then odd-index coefficients.

## Idea

Treat the puzzle like reading answers off a printed chart: the judge wants text, so prepare the 50 strings once and look each one up. The strings come from Faulhaber's formula, built with exact fractions and then scaled to integers.

The generator builds each polynomial by multiplying the previous one by its degree, integrating, and fixing the linear coefficient so the polynomial equals one at n equal to one. Each lookup in the Nim program costs one array access. Recomputing the fractions for every test case would cost far more.

Scaling by the least common denominator removes all fractions and keeps the printed coefficients integers.

## Why It Works

1. The zero-th power sum is n, so its coefficient list is 0 followed by 1.
2. Higher power sums satisfy a recurrence through multiplication by the degree and integration.
3. Adding a linear term forces each polynomial to equal one at n equal to one.
4. The least common multiple of all denominators turns every coefficient into an integer.
5. The judge prints even-index coefficients first, then odd-index coefficients, after a leading zero.
6. All 50 outputs are fixed, so a direct lookup reproduces them exactly.

| term | meaning |
|---|---|
| `answerTable` | the 50 precomputed output lines |
| POLYNOMIALS | integer coefficient lists in the generator |
| DENOMINATORS | scaling factor for each degree |
| linear | coefficient chosen by the recurrence |

The three generator names describe the formula behind the table.

Here is the sample expansion from `gen.py`:

| degree | denominator | even coefficients | odd coefficients |
|---|---|---|---|
| 8 | 90 | 0, 0, 0, 0, 45 | -3, 20, -42, 60, 10 |
| 9 | 20 | 0, -3, 10, -14, 15 | 2, 0, 0, 0, 0, 10 |
| 10 | 66 | 0, 0, 0, 0, 0, 33 | 5, -33, 66, -66, 55, 6 |

Joining the two groups after the denominator gives the sample output.

## Code

**Table declaration.** The constant holds all 50 answer strings in input order.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const answerTable = @[
```

Each entry is one complete output line.
Index zero holds the answer for N equal to one.
The table is generated once by the fraction recurrence.

**Sample rows.** These entries reproduce the statement example.

```nim
  "8=90*(0+0+0+0+45-3+20-42+60+10)",
  "9=20*(0-3+10-14+15+2+0+0+0+0+10)",
  "10=66*(0+0+0+0+0+33+5-33+66-66+55+6)",
```

The three rows are copied from the generated table.
No evaluation happens at run time.
The strings are printed byte for byte.

**Input and lookup.** The driver reads every value and writes the matching table entry.

```nim
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

proc hasDigits(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len:
    if data[cursor] >= '0' and data[cursor] <= '9':
      return true
    cursor += 1
  return false

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while hasDigits(inputData, scanPos):
  let caseValue = nextInt(inputData, scanPos)
  appendOutput(answerTable[caseValue - 1])
  outputBuffer.add '\n'
```

The digit check handles EOF cleanly.
One subtraction maps N to its table index.
The block buffer flushes as answers accumulate.

## Complexity

A test case does one lookup and one buffered write.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| table lookup | one indexed access | fixed table |
| output | one write per block | block buffer |

The lookup is the only work per case.

| measure | Big O |
|---|---|
| time per case | O(1) |
| space | O(1) besides input and output buffers |

Rebuilding the rational polynomials per case would cost O(N) big-number work, while the table costs one access.
The fixed domain keeps every answer exact and fast.
