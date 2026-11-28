# PRF04STRING02 — String - lTrim (SPOJ)
<https://www.spoj.com/problems/PRF04STRING02/>

## Problem

Read one line of text, remove the whitespace at its left edge, and print the rest. Whitespace inside the line and at its right edge stays in place.

The input is a single text line that may start with spaces or tabs. The output is that line without its leading whitespace, followed by a newline. If the line is all whitespace, the output is an empty line.

The bounds and judge limits are:

| item | bound |
| --- | --- |
| input | one line of text |
| leading blanks | 6 in the first sample |
| characters | not stated; examples use 19 after trimming |
| judge time | 1000 ms |
| judge memory | 1536 MB |

The statement gives no upper bound on the line length.

The sample input follows.

          Lap trinh can ban C

The line starts with 6 spaces before 19 text characters.

The expected output follows.

    Lap trinh can ban C

The output begins at the first text character.

## Idea

Removing leading blanks is like sliding a row of tiles left until the first tile has a mark. A leading-whitespace scan is the real method.

Each skipped blank costs O(1), and the copy costs O(L) for L remaining characters. Rebuilding the line with repeated front deletions would shift every remaining character each time. One forward scan plus one copy avoids that cost.

## Why It Works

1. The read loop loads the whole input into `inputData` before any output.
2. The first scan skips spaces, tabs and carriage returns at the left edge.
3. The second scan copies from the first text character up to the newline marker.
4. Blanks inside the text and at the right edge survive the copy.
5. The final write emits the trimmed line and one newline.

The terms carry the proof.

| term | meaning |
| --- | --- |
| `inputData` | full input text with newline markers |
| `scanPos` | position of the next character to inspect |
| `trimmedLine` | copied text after the leading blanks |
| `appendOutput` | adds text and flushes a full block |
| `flushBlockBytes` | size that triggers a block write |
| `outputBuffer` | pending output text |

These names cover the whole driver.

The generator's oracle counts 6 leading spaces in the sample and writes 19 characters after them. A line of 3 tabs followed by X becomes X. A line of 5 spaces becomes an empty line.

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

**Leading scan and copy.** The driver skips left blanks, then copies the first line.

```nim
var scanPos = 0
while scanPos < inputData.len and (inputData[scanPos] == ' ' or inputData[scanPos] == '\t' or inputData[scanPos] == '\r'):
  scanPos += 1
var trimmedLine = ""
while scanPos < inputData.len and inputData[scanPos] != '\n':
  trimmedLine.add inputData[scanPos]
  scanPos += 1
appendOutput(trimmedLine)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The first scan stops at the first text character. The second scan copies through the newline marker. An all-blank line yields an empty output line.

## Complexity

The scan and copy each visit a prefix of the input once.

| phase | time | space |
| --- | --- | --- |
| input read | one pass over all input lines | one input string |
| leading scan | one pass over B leading blanks | constant |
| copy | one pass over L kept characters | copy of L characters |
| output | a few block writes | output buffer |

The phase table shows where the work goes.

| measure | Big O |
| --- | --- |
| time | O(B + L) |
| space | O(L) |

The measure table gives the growth rates.

Deleting one front blank at a time would cost O(L^2) because every kept character shifts.

The single scan and copy keep the run linear in the line length.
