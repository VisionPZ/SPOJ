# M1101 — Мэндчилгээ (SPOJ)

<https://www.spoj.com/problems/M1101/>

## Problem

Print the fixed greeting line and nothing else. The judge sends no input bytes.

The output is one line with the exact text `Hello MONCODER!`. Uppercase letters and the final exclamation mark are part of the answer.

The bounds from the statement:

| item | bound |
|---|---|
| input bytes | 0 |
| output lines | 1 |
| output text | Hello MONCODER! |
| judge limit | 1000 ms, 1536 MB |

The empty input makes the output a constant.

Sample input (empty):

```

```

No input token can change the greeting.

Sample output:

```
Hello MONCODER!
```

The sample answer is exactly the required line.

## Idea

A constant greeting is like a stamped envelope: every run gets the same words. The algorithm is one string write, so the cost per input item is zero.

A naive program could read and inspect lines, yet that work never changes the answer. Emit the constant instead.

One append settles the whole problem.

## Why It Works

1. The statement names one exact output string.
2. The input section declares no data, so no value can vary.
3. One append plus one flush writes that string with a newline.

The main terms:

| term | meaning |
|---|---|
| `inputData` | full text read from standard input |
| `outputBuffer` | pending output bytes |
| `appendOutput` | adds text and flushes a full block |
| `flushBlockBytes` | buffer size that triggers a write |

The buffer holds output until a block is ready.

A trace from the generator with visible numbers:

```
input lines: 0
output bytes: 16
output: Hello MONCODER!
```

The trace shows sixteen output bytes from zero input lines.

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

The read loop accepts any input, including none.
The scanner skips non-digits and builds each value digit by digit.
The buffer writes once its size reaches `flushBlockBytes`.

**Fixed greeting.** The program emits one string and flushes the buffer.

```nim
discard nextInt(inputData, scanPos)
appendOutput("Hello MONCODER!")
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
