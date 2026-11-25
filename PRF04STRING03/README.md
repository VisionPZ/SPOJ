# PRF04STRING03 — String - rTrim (SPOJ)
<https://www.spoj.com/problems/PRF04STRING03/>

## Problem

Read one line of text, remove the whitespace at its right edge, and print the rest. Whitespace at the left edge and inside the line stays in place.

The input is a single text line that may end with spaces or tabs. The output is that line without its trailing whitespace, followed by a newline. If the line is all whitespace, the output is an empty line.

The bounds and judge limits are:

| item | bound |
| --- | --- |
| input | one line of text |
| trailing blanks | 13 in the first sample |
| characters | not stated; examples use 19 after trimming |
| judge time | 1000 ms |
| judge memory | 1536 MB |

The statement gives no upper bound on the line length.

The sample input follows.

    Lap trinh can ban C             

The line holds 19 text characters before 13 trailing spaces.

The expected output follows.

    Lap trinh can ban C

The output ends at the last text character.

## Idea

Trimming the right edge is like cutting the frayed end off a ribbon and keeping the clean part. A trailing-whitespace scan is the real method.

Each step from the right costs O(1), and the copy costs O(L) for L kept characters. Rebuilding the line with repeated back deletions would rescan the kept prefix each time. One backward scan plus one forward copy avoids that cost.

## Why It Works

1. The read loop loads the whole input into `inputData` before any output.
2. The first scan copies the leading line into `textLine` up to the newline marker.
3. The second scan steps back over spaces, tabs and carriage returns.
4. The copy writes characters up to `trimEnd`, so left blanks and inner spaces stay.
5. The final write emits the trimmed line and one newline.

The terms carry the proof.

| term | meaning |
| --- | --- |
| `inputData` | full input text with newline markers |
| `textLine` | characters copied from the first line |
| `trimEnd` | count of characters kept after trimming |
| `trimmedLine` | copied text without trailing blanks |
| `writePos` | position of the next character to copy |
| `appendOutput` | adds text and flushes a full block |
| `flushBlockBytes` | size that triggers a block write |
| `outputBuffer` | pending output text |

These names cover the whole driver.

The generator's oracle counts 13 trailing spaces in the sample and writes 19 characters before them. A line of X followed by 2 tabs becomes X. A line of 5 spaces becomes an empty line.

No conversion applies. The newline marker stops the first scan, so later lines do not leak into the output.

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

**Backward scan and copy.** The driver finds the kept prefix, then copies the first line.

```nim
var scanPos = 0
var textLine = ""
while scanPos < inputData.len and inputData[scanPos] != '\n':
  textLine.add inputData[scanPos]
  scanPos += 1
var trimEnd = textLine.len
while trimEnd > 0 and (textLine[trimEnd - 1] == ' ' or textLine[trimEnd - 1] == '\t' or textLine[trimEnd - 1] == '\r'):
  trimEnd -= 1
var trimmedLine = ""
var writePos = 0
while writePos < trimEnd:
  trimmedLine.add textLine[writePos]
  writePos += 1
appendOutput(trimmedLine)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The backward scan sets the kept length. The copy stops at that length. An all-blank line yields an empty output line.

## Complexity

The copy and the backward scan each visit a prefix of the input once.

| phase | time | space |
| --- | --- | --- |
| input read | one pass over all input lines | one input string |
| line copy | one pass over L line characters | copy of L characters |
| trailing scan | one pass over T trailing blanks | constant |
| output | a few block writes | output buffer |

The phase table shows where the work goes.

| measure | Big O |
| --- | --- |
| time | O(L + T) |
| space | O(L) |

The measure table gives the growth rates.

Deleting one trailing blank at a time would rescan the kept prefix each time.

The single backward scan and copy keep the run linear in the line length.
