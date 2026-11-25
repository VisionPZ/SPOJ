# PRF04STRING01 — String - Input/Output (SPOJ)
<https://www.spoj.com/problems/PRF04STRING01/>

## Problem

Read one line of text and print that same line back. Spaces inside the line stay in place, and the output ends with one newline.

The input is a single text line. The output is the identical text line followed by a newline. No prompts, labels or conversion appear in the output.

The bounds and judge limits are:

| item | bound |
| --- | --- |
| input | one line of text |
| characters | not stated; examples use 20 to 23 characters |
| output | the same line plus one newline |
| judge time | 1000 ms |
| judge memory | 1536 MB |

The statement gives no upper bound on the line length.

The sample input follows.

    Lap trinh can ban C.

The line contains 20 characters including the final period.

The expected output follows.

    Lap trinh can ban C.

The output repeats all 20 characters in the same order.

## Idea

Echoing a written note is like copying a line from one card onto another card, character by character. A buffered character copy is the real method.

Each character costs O(1) to copy, so the run is O(L) for L characters. A naive per-character write would issue one system call per character and waste most of the time. One block buffer collapses those writes into a few large writes.

## Why It Works

1. The read loop loads the whole input into `inputData` before any output.
2. The scan copies characters until the first newline marker.
3. Internal spaces and punctuation pass through unchanged.
4. The copied line reaches `outputBuffer` in one append.
5. The final write emits the buffer and one newline.

The terms carry the proof.

| term | meaning |
| --- | --- |
| `inputData` | full input text with newline markers |
| `scanPos` | position of the next character to copy |
| `textLine` | characters copied from the first line |
| `appendOutput` | adds text and flushes a full block |
| `flushBlockBytes` | size that triggers a block write |
| `outputBuffer` | pending output text |

These names cover the whole driver.

The generator's oracle counts 20 characters in Lap trinh can ban C. and writes the same 20 characters back. The sample in the statement passes byte for byte. A longer generated line of 210000 characters also round trips.

No conversion applies. The newline marker stops the copy, so later lines do not leak into the output.

## Code

**Constants and full input read.** The header sets the block size and loads stdin once.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

The read loop keeps each line and its newline marker. Parsing happens after the read finishes.

**Buffered writer.** One buffer collects output and flushes in large blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Large blocks keep write calls rare. The final write empties any leftover text.

**Line copy and flush.** The driver copies the first line, then writes it once.

```nim
var scanPos = 0
var textLine = ""
while scanPos < inputData.len and inputData[scanPos] != '\n':
  textLine.add inputData[scanPos]
  scanPos += 1
appendOutput(textLine)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The scan stops at the newline marker. One append sends the whole line to the buffer. The last write flushes the result.

## Complexity

The copy visits each character of the first line once.

| phase | time | space |
| --- | --- | --- |
| input read | one pass over all input lines | one input string |
| line copy | one pass over L characters | copy of L characters |
| output | a few block writes | output buffer |

The phase table shows where the work goes.

| measure | Big O |
| --- | --- |
| time | O(L) |
| space | O(L) |

The measure table gives the growth rates.

Writing each character on its own would multiply system calls by L.

The buffered copy keeps the run linear from start to finish.
