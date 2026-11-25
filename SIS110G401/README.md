# SIS110G401 — Suma de Numeros (SPOJ)

<https://www.spoj.com/problems/SIS110G401/>

## Problem

The input holds pairs of integers, one pair per line: a count for the left hand and a count for the right hand. Add the two counts and print one sum per line, reading pairs up to end of input.

There is no test count and no terminator value. Every complete pair produces one output line.

| item | bound |
|---|---|
| input form | pairs of integers, one pair per line |
| pair count | until end of input |
| judge limit | 1000 ms, 1536 MB |

The input can hold more than one pair, so the program must keep reading to EOF.

Sample input:

```
4 4
3 4
```

Sample output:

```
8
7
```

Each line adds its own pair, giving 8 and then 7.

## Idea

Treat each pair like two hands of counters and combine them into one pile. Read every integer in order, pair the values, and add them.

The algorithm is a linear scan with a hand-written integer reader and a block output buffer. Each pair costs one addition and one formatted write. Flushing after every line would issue many small writes, so the buffer flushes only when it grows large.

## Why It Works

1. Consecutive integers form one pair because the input is written pair by pair.
2. Scanning to EOF handles any number of pairs without a count.
3. Widening each value to int64 keeps large sums exact.
4. A block buffer reduces writes while preserving line order.

| term | meaning |
|---|---|
| `inputData` | all stdin text read in one pass |
| `scanPos` | current byte position in the input text |
| `leftHand` | first integer of the current pair |
| `rightHand` | second integer of the current pair |
| `outputBuffer` | pending answer lines |

The scanner skips spaces and line breaks, so extra whitespace is harmless.

The sample trace from the generator is:

```
pair 4 4 -> 4 + 4 = 8
pair 3 4 -> 3 + 4 = 7
output lines: 8, 7
```

The trace reproduces the sample output exactly.

## Code

**Input and scanner.** The program reads all of stdin, then scans integers by hand.

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

One read loop captures the entire input.
The scanner advances over digits and ignores separators.
No parse work happens during the read loop.

**Buffered output.** One helper holds answers until the block is full.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer grows with appended text.
A write happens only after crossing the block size.
The final flush happens after the pair loop.

**Pair loop.** The program reads two integers per iteration until no digits remain.

```nim
while true:
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  if scanPos >= inputData.len:
    break
  let leftHand = int64(nextInt(inputData, scanPos))
  let rightHand = int64(nextInt(inputData, scanPos))
  appendOutput($(leftHand + rightHand))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The guard before each pair stops the loop cleanly at EOF.
Each sum is converted to text and appended with its newline.
The last write clears the remaining buffer once.

## Complexity

The work splits into reading, pairing, and writing.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| parse and add | one pass over integers | constant working space |
| output | one formatted line per pair | block buffer |

All phases are linear in the input size.

| measure | Big O |
|---|---|
| time | O(total input bytes) |
| space | O(total input bytes) for the input string |

Reading and writing line by line with an immediate flush would add many system calls. Scan once, buffer answers, then write in blocks.
