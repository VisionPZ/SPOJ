# SICT1000 — Sum (SPOJ)

<https://www.spoj.com/problems/SICT1000/>

## Problem

Add two integers and print their sum. This is the shortest arithmetic task on the judge.

Input has one line with two integers separated by a space. Output has one line with the sum.

| item | bound |
|---|---|
| integer count | 2 |
| sign | either sign permitted |
| judge limit | 1000 ms, 1536 MB |

Sample input:

```
10 35
```

Sample output:

```
45
```

## Idea

Adding two numbers is like combining two piles of coins into one pile. The hand scanner reads both values, and one addition produces the answer.

The scanner `nextInt` skips separators and builds each value from its digits. The buffer `outputBuffer` holds the result until the single flush. A direct addition costs one operation, so no faster method exists. Takeaway: read both values, add once, write once.

## Why It Works

1. The scanner skips any character that is not a digit or a minus sign.
2. Each digit contributes its face value times its place value.
3. A leading minus sign negates the accumulated value.
4. The sum of two signed integers fits in a 64-bit word for the given bounds.
5. One buffered write emits the complete answer line.

| term | meaning |
|---|---|
| `inputData` | all of stdin held as one string |
| `scanPos` | current byte position in the input string |
| `firstNumber` | value parsed from the first token |
| `secondNumber` | value parsed from the second token |
| `outputBuffer` | assembled output text before the final write |

A script adds 10 and 35 by combining digit values: 5 plus 0 gives 5, 3 plus 1 gives 4, so the result reads 45. This matches the printed sample.

The minus branch handles signed input. No rounding or overflow guard is needed inside the stated bounds.

## Code

**Input reader.** The whole stream is loaded and parsed by hand.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var sign = 1'i64
  if pos < data.len and data[pos] == '-':
    sign = -1'i64
    pos += 1
  var value = 0'i64
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return sign * value
```

The reader appends a newline after every line.
The scanner handles a leading minus sign.
Digits are converted with `int(data[pos]) - 48`.

**Output path.** One addition is buffered and flushed once.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let firstNumber = nextInt(inputData, scanPos)
let secondNumber = nextInt(inputData, scanPos)
appendOutput($(firstNumber + secondNumber))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`appendOutput` flushes large buffers in blocks.
The sum is converted to text with `$`.
The final newline is appended before the last write.

## Complexity

The program scans two tokens and writes one line.

| phase | time | space |
|---|---|---|
| read all input | one pass over the stream | one input string |
| parse two values | one pass over their digits | constant |
| output | one buffered write | one output string |

| measure | Big O |
|---|---|
| time | O(L) for input length L |
| space | O(L) |

A per-digit print loop would add needless calls, while one buffered write avoids them. Takeaway: parse both values, add them, and flush the result once.
