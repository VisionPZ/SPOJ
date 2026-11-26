# PRF00 — Hello world (SPOJ)

<https://www.spoj.com/problems/PRF00/>

## Problem

Print one fixed greeting and ignore whatever bytes arrive on input. No value is read or computed; the output is the same for every test.

| item | contract |
|---|---|
| input | none |
| output | Hello world! I love C :) |
| judge limit | 1000 ms, 1536 MB |

The colon and closing parenthesis end the line.
A trailing newline completes the output.

Sample input:

```
None
```

Sample output:

```
Hello world! I love C :)
```

## Idea

A vending machine that always dispenses the same snack ignores the button you press. This program behaves that way: it reads stdin for completeness, then prints the same fixed line. The algorithm is a constant string write. Reading costs one pass over whatever input the judge supplies, and the write costs one call. Inspecting that input would add work with no effect on the answer.

## Why It Works

1. The read loop drains stdin into one string before any output.
2. The fixed text is appended to the output buffer verbatim.
3. A newline terminates the only output line.
4. One final write sends the buffered bytes to stdout.
5. No input byte influences the printed text.

| term | meaning |
|---|---|
| `inputData` | text collected from stdin |
| `outputBuffer` | pending output bytes |
| `flushBlockBytes` | size that triggers an early write |

A short script counts the bytes of the sample:

| item | bytes |
|---|---|
| input file containing "None\n" | 5 |
| output line including newline | 25 |
| characters written by the program | 1 |

The output length never changes because the text is fixed.

## Code

**Input drain.** The program consumes stdin even though no value is needed.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

```

Each line keeps its trailing newline.
An empty input ends the loop immediately.
No parser is needed for this problem.

**Fixed output.** The greeting joins the buffer and is written once.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

appendOutput("Hello world! I love C :)")
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The literal matches the required line exactly.
The final write clears the remaining buffer.

## Complexity

Input length is the only variable cost.

| phase | time | space |
|---|---|---|
| input drain | one pass over input bytes | one input string |
| output | one fixed line | one buffer string |

| measure | Big O |
|---|---|
| time | O(L), where L is input length |
| space | O(L) |

Parsing tokens would add work without changing the fixed answer.

The whole run is one read pass and one write.
