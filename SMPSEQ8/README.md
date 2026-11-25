# SMPSEQ8 — Fun with Sequences, Act 6 (SPOJ)

<https://www.spoj.com/problems/SMPSEQ8/>

## Problem

Compare the totals of two number rows. Keep the first row when the second total is strictly smaller; otherwise keep the second row.

Input: a length `n`, `n` integers of S, a length `m`, then `m` integers of Q. Output: the kept integers in their original order, separated by single spaces, then a newline.

| Item | Bound |
|---|---|
| Lengths `n`, `m` | 2 to 100 |
| Values | -100 to 100 |
| Judge limit | 1000 ms, 1536 MB |

The samples, verbatim:

```
5
-2 -1 0 1 4
6
-3 -2 -1 1 2 3
```

```
-2 -1 0 1 4
```

```
5
-2 -1 0 1 2
6
-3 -2 -1 1 2 3
```

```
-3 -2 -1 1 2 3
```

## Idea

Think of comparing two shopping bills and keeping the receipt with the larger total. Running totals decide which row to print.

The code adds each value as it is read, then compares the two totals once. Each input value costs one addition. Sorting or storing both rows before comparing would add work.

A single chosen row is printed, so no extra pass over the other row is needed.

## Why It Works

1. `firstSum` equals the total of S, and `secondSum` equals the total of Q.
2. The statement prints S only when the total of Q is strictly smaller than the total of S.
3. Equal totals therefore print Q, which the second sample confirms.
4. The separator is written only before a later value, so the line has no trailing space.

| Term | Meaning |
|---|---|
| `firstLength`, `secondLength` | the `n` and `m` of the input |
| `firstSequence`, `secondSequence` | the rows S and Q |
| `firstSum`, `secondSum` | the running totals |
| `outputSequence` | the row selected for printing |

The strict comparison decides the printed row.

A traced run of the first sample, produced by the generator:

```
first sum 2
second sum 0
second sum below first sum: True
answer -2 -1 0 1 4
```

The trace matches the first sample output line.

## Code

**Constants and input read.** One string holds every input line.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

The digit offset is the byte of `0`. The block size bounds the output buffer.

**Digit scanner.** Each call advances the shared scan position past one signed integer.

```nim
var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
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

The minus sign is part of the token, not a separator. The `var` parameter keeps the position between calls.

**Output buffer.** Appends collect bytes and write one block at a time.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`setLen 0` reuses the storage after a write.

**Both rows and choice.** Totals are accumulated while reading.

```nim
let firstLength = nextInt(inputData, scanPos)
var firstSequence = newSeq[int](firstLength)
var firstSum = 0
var positionIndex = 0
while positionIndex < firstLength:
  let currentValue = nextInt(inputData, scanPos)
  firstSequence[positionIndex] = currentValue
  firstSum += currentValue
  positionIndex += 1

let secondLength = nextInt(inputData, scanPos)
var secondSequence = newSeq[int](secondLength)
var secondSum = 0
positionIndex = 0
while positionIndex < secondLength:
  let currentValue = nextInt(inputData, scanPos)
  secondSequence[positionIndex] = currentValue
  secondSum += currentValue
  positionIndex += 1

var outputSequence = firstSequence
if secondSum >= firstSum:
  outputSequence = secondSequence
positionIndex = 0
while positionIndex < outputSequence.len:
  if positionIndex > 0:
    appendOutput(" ")
  appendOutput($(outputSequence[positionIndex]))
  positionIndex += 1
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The reads fill `n` and `m` slots. The comparison uses `>=` as the complement of the strict rule. The final write covers the answer line.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the lines | input bytes |
| Digit scan | one pass over `n+m+2` integers | constant |
| Totals | one addition per value | two sequences |
| Output | one write per block | one buffer |

The number of values bounds the work.

| Measure | Big O |
|---|---|
| Time | O(input bytes + n + m) |
| Space | O(n + m) plus one output block |

Computing each total by repeated summation over prefixes would add O(n squared plus m squared) work.
