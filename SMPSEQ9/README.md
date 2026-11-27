# SMPSEQ9 — Fun with Sequences (Act 7) (SPOJ)

<https://www.spoj.com/problems/SMPSEQ9/>

## Problem

Pick the first sequence when the second sequence has the smaller average. Otherwise pick the second sequence, and print the chosen integers in input order.

Input: a count `n`, then `n` integers, then a count `m`, then `m` integers.
Output: one line containing the chosen integers, separated by single spaces.

| item | bound |
|---|---|
| `n` | 2 to 100 |
| `m` | 2 to 100 |
| each sequence value | -100 to 100 |
| judge limit | 1000 ms |
| memory | 1536 MB |

Verbatim sample from the statement:

```
5
-2 -1 0 1 4
6
-3 -2 -1 1 2 3
```

```
-2 -1 0 1 4
```

## Idea

Think of two lunch trays, each with a total weight and a number of plates. Compare average plate weights without dividing, by cross multiplying the totals.

The real algorithm is average comparison by integer cross multiplication, plus one pass to sum each sequence. Each item costs one add while reading and one append while writing.

## Why It Works

1. Counts `n` and `m` are positive, so cross multiplication preserves the order relation.
2. `sum(Q) / m < sum(S) / n` is exactly `sum(Q) * n < sum(S) * m`.
3. The strict inequality sends an exact tie to the second sequence.
4. Totals are at most 10 000 in absolute value, so plain integers cannot overflow.

| term | meaning |
|---|---|
| `firstTotal` | sum of the `n` integers in S |
| `secondTotal` | sum of the `m` integers in Q |
| `firstCount` | n, the number of values in S |
| `secondCount` | m, the number of values in Q |
| `chosenValues` | the sequence selected by the comparison |

Script-generated example for sample 1:

```
sum S = 2        sum Q = 0
n = 5            m = 6
sum(Q) * n = 0   sum(S) * m = 12
0 < 12 is true, so S is printed
```

Sample 2 gives `sum S = 3` and `sum Q = 3`. The products are `15` and `18`, so S is printed again.

## Code

**Digit scanner.** Skips separators and handles a leading minus sign.

```nim
proc nextInt(inputData: string, pos: var int): int =
  while pos < inputData.len and inputData[pos] != '-' and
        (inputData[pos] < '0' or inputData[pos] > '9'):
    pos += 1
  var signValue = 1
  if pos < inputData.len and inputData[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < inputData.len and inputData[pos] >= '0' and inputData[pos] <= '9':
    value = value * 10 + int(inputData[pos]) - 48
    pos += 1
  return signValue * value
```

`pos` is a variable parameter, so the scan position survives every call. A digit byte becomes `int(inputData[pos]) - 48`, with no substring allocation.

**Selection.** Reads both sequences, sums them, and compares by cross multiplication.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var pos = 0
let firstCount = nextInt(inputData, pos)
var firstValues: seq[int] = @[]
for _ in 0 ..< firstCount:
  firstValues.add nextInt(inputData, pos)
let secondCount = nextInt(inputData, pos)
var secondValues: seq[int] = @[]
for _ in 0 ..< secondCount:
  secondValues.add nextInt(inputData, pos)

var firstTotal = 0
for value in firstValues:
  firstTotal += value
var secondTotal = 0
for value in secondValues:
  secondTotal += value

var chosenValues: seq[int]
if secondTotal * firstCount < firstTotal * secondCount:
  chosenValues = firstValues
else:
  chosenValues = secondValues
```

Every line is appended to one buffer, so odd spacing cannot desynchronize the reader. The comparison uses products, not floating point, so no rounding enters the decision.

**Output writer.** Emits the chosen values in order with single spaces.

```nim
var outputBuffer = ""
for index in 0 ..< chosenValues.len:
  if index > 0:
    outputBuffer.add ' '
  outputBuffer.add $chosenValues[index]
outputBuffer.add '\n'
stdout.write outputBuffer
```

The index test suppresses a trailing space. One write is enough here because the output is at most a few hundred bytes.

## Complexity

| phase | time | space |
|---|---|---|
| input read | one pass over all lines | input bytes |
| sequence scan | one pass, one add per value | 200 integers |
| comparison | constant time | none extra |
| output | one pass over the chosen values | 400 bytes |

| measure | Big O |
|---|---|
| time | O(n + m) |
| space | O(n + m) |

Computing both averages as floating point would cost two divisions and invite rounding near a tie. Cross multiplication keeps the decision exact with the same linear pass.
