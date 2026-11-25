# NIT241A — Hello NIT OJ (SPOJ)

<https://www.spoj.com/problems/NIT241A/>

## Problem

Print the fixed greeting line, then stop. The judge supplies no input bytes at all.

The input is empty and the output is one line with the exact text `Hello NIT OJ.`. Case and the final period both matter.

The bounds from the statement:

| item | bound |
|---|---|
| input bytes | 0 |
| output lines | 1 |
| output text | Hello NIT OJ. |
| judge limit | 1000 ms, 1536 MB |

The missing input is the only constraint that shapes the program.

Sample input (empty):

```

```

An empty input produces the single greeting line.

Sample output:

```
Hello NIT OJ.
```

The sample answer matches the required text byte for byte.

## Idea

A fixed greeting is like a sign nailed to a wall: it reads the same every time. The algorithm is one string write, so the cost per input item is zero.

A naive program could scan input and branch on each line, yet that adds work without changing the answer. Skip that work and emit the constant.

One write gives the whole answer.

## Why It Works

1. The statement fixes the output text as one exact string.
2. No input bytes exist, so no token can alter that string.
3. A single append and one flush write exactly those bytes.

The main terms:

| term | meaning |
|---|---|
| `inputData` | full text read from standard input |
| `outputBuffer` | pending output bytes |
| `appendOutput` | adds text and flushes a full block |
| `flushBlockBytes` | buffer size that triggers a write |

The buffer keeps output work in one place.

A trace from the generator with visible numbers:

```
input lines: 0
output bytes: 14
output: Hello NIT OJ.
```

The trace confirms that zero input lines still yield fourteen output bytes.

## Code

**Input and output setup.** The driver reads all input, defines the scanner, and buffers output.

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

The read loop handles any input, including none.
The scanner skips non-digits and builds each value digit by digit.
The buffer writes once its size reaches `flushBlockBytes`.

**Fixed greeting.** The program emits one string and flushes the buffer.

```nim
discard nextInt(inputData, scanPos)
appendOutput("Hello NIT OJ.")
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The discard consumes any stray number without using it.
The append adds the greeting and the newline.
The final write flushes the short buffer to standard output.

## Complexity

The work is a single read pass and one write.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| output | one block write | block buffer |

Both phases finish in constant time for this problem.

| measure | Big O |
|---|---|
| time | O(1) |
| space | O(1) |

A naive line-by-line decision would add loops without changing the constant answer.

One append and one flush solve the whole problem.
