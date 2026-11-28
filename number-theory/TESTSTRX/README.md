# TESTSTRX — Addition of 2 integers (SPOJ)

<https://www.spoj.com/problems/TESTSTRX/>

## Problem

Add two integers for each of several test cases and print one sum per line.

Input: the first line holds `T`, then `T` lines with two integers `A` and `B`. Output: `T` lines, each holding `A + B`.

The stated bounds are:

| item | bound |
|---|---|
| test cases `T` | 1 to 100 |
| addends `A`, `B` | 0 to 10000 |
| judge limit | 1000 ms, 1536 MB |

The sample has three cases, and its first three input lines end in spaces.

Sample input and output:

```
3 
1 2 
3 4 
10 10
```

```
3
7
20
```

Each output line is the sum of the matching input pair.

## Idea

Add each pair as it arrives, like totaling items on a shopping list. The hand scanner walks the whole input once and reads two integers per case. Storing every pair first would add memory without changing any sum. A buffered writer collects the answers and flushes in blocks.

## Why It Works

1. The first token sets the number of test cases.
2. Each case consumes exactly two integers, regardless of line breaks.
3. The scanner skips non-digits, so trailing spaces in the sample cause no trouble.
4. Both addends fit in an `int`, and their sum fits as well.
5. Every case appends one number and one newline to the output buffer.

The program keeps five values:

| term | meaning |
|---|---|
| `testCount` | number of cases from the first token |
| `testIndex` | index of the current case |
| `firstAddend` | left number of the current pair |
| `secondAddend` | right number of the current pair |
| `outputBuffer` | buffered answer text |

These names appear in the code below.

The sample pairs produce these answers:

```
case 1: 1 + 2  = 3
case 2: 3 + 4  = 7
case 3: 10 + 10 = 20
```

Three pairs therefore produce three output lines.

`appendOutput` flushes the buffer at `flushBlockBytes`, so many cases write in a few calls.

## Code

**Input and scanner.** The entire input is read once, then digits are scanned by index.

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
```

`inputData` holds every byte, including newlines.
`nextInt` skips non-digits and builds a value one digit at a time.
`scanPos` advances across calls, so no token objects are created.

**Sums and output.** One loop reads each pair and appends its sum.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let firstAddend = nextInt(inputData, scanPos)
  let secondAddend = nextInt(inputData, scanPos)
  appendOutput($(firstAddend + secondAddend))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`testCount` bounds the loop, so the number of answers matches the input.
`appendOutput` checks the block size after each number, and one final write covers the tail.

## Complexity

Work by phase:

| phase | time | space |
|---|---|---|
| input read | one pass over all lines | one input string |
| scanning | two tokens per case | constant |
| output | one line per case | one output buffer |

Reading and scanning dominate the runtime.

Asymptotic bounds:

| measure | Big O |
|---|---|
| time | O(T) in the number of cases |
| space | O(1) besides the input and output buffers |

Both bounds grow linearly with the case count.

Building a list of pairs first would use O(T) space and a second pass. One streaming loop finishes in a single pass.
