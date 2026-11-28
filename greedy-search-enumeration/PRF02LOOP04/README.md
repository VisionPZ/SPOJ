# PRF02LOOP04 — LOOP (SPOJ)
<https://www.spoj.com/problems/PRF02LOOP04/>

## Problem

Read one integer N. Print a prompt with no newline, then reject a non-positive N with a short message or draw a triangle of N lines. Each line r prints the numbers 1 through r in rising order, separated by spaces.

The input is one integer on a line. The output starts with the exact text Please enter the positive integer N: with no trailing newline. For N at most zero, the text N must be greater than 0! follows on that same line. For positive N, the text The number-triangle that has N lines is: follows on that same line, then the triangle begins on the next line.

The bounds and judge limits are:

| Constraint | Value |
| --- | --- |
| Input | one integer |
| Positive case | N triangle lines |
| Non-positive case | one error line |
| Judge time | 1000 ms |
| Judge memory | 1536 MB |

The statement gives no upper bound on N, so the output size grows with the value read.

The sample input for the triangle case is 4. Its output follows.

    4

    Please enter the positive integer N:The number-triangle that has 4 lines is:
    1
    1 2
    1 2 3
    1 2 3 4

The sample input for the error case is 0. Its output follows.

    0

    Please enter the positive integer N:N must be greater than 0!

## Idea

A rising triangle is like writing a staircase: row r always adds the next step number.
The program reads N, prints the shared prompt, and splits into the invalid and valid paths.
On the valid path, row r emits the values 1 through r, with a space between neighbors.
Direct emission writes each token once and keeps no intermediate row strings.
Building whole rows as separate strings first would add extra allocation for every line.
The single-pass write keeps both code paths short and the output buffer full.

## Why It Works

1. The prompt is written before N is tested, so it appears in both cases.
2. A value of N at most zero selects the fixed error message and one newline.
3. A positive N selects a heading that interpolates N, followed by one newline.
4. Row r has r tokens, and a space is emitted before tokens two through r.
5. The inner counter runs from 1, so every row starts at 1 and ends at r.
6. Each row ends with a newline, so the last line also ends with a newline.

The terms carry the proof.

| Term | Meaning |
| --- | --- |
| entryPrompt | fixed text written before the branch |
| invalidMessage | fixed text for non-positive N |
| headingPrefix | fixed text before the interpolated value of N |
| headingSuffix | fixed text after the interpolated value of N |
| requestedLines | the parsed value of N |
| rowNumber | the current row index |
| columnNumber | the current ascending value in a row |

The term table names every value that shapes the output.

A script check of the sample with N equal to 4 gives 4 rows and 10 numbers.
The row lengths are 1, 2, 3 and 4 tokens, with 6 spaces in total.
For N equal to 0, the script gives 1 line with no triangle rows.

No rounding applies. The negative branch is omitted from the scanner because N is never negative.

## Code

**Constants and full input read.** The header holds the three fixed output strings.

```nim
const flushBlockBytes = 1 shl 17
const entryPrompt = "Please enter the positive integer N:"
const invalidMessage = "N must be greater than 0!"
const headingPrefix = "The number-triangle that has "
const headingSuffix = " lines is:"

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

The constants avoid repeated string literals in the driver. The read loop loads the whole input before scanning.

**Integer scanner.** The hand scanner skips non-digits and folds digits into an integer.

```nim
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

It advances one position per numeric character. No negative branch appears because N is non-negative.

**Buffered writer.** One buffer collects output and flushes in large blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Large blocks keep write calls rare. A final write empties any text left in the buffer.

**Triangle emission.** The driver branches on N and emits rising rows with inline separators.

```nim
let requestedLines = nextInt(inputData, scanPos)
appendOutput(entryPrompt)
if requestedLines <= 0:
  appendOutput(invalidMessage)
  outputBuffer.add '\n'
else:
  appendOutput(headingPrefix)
  appendOutput($requestedLines)
  appendOutput(headingSuffix)
  outputBuffer.add '\n'
  for rowNumber in 1 .. requestedLines:
    for columnNumber in 1 .. rowNumber:
      if columnNumber > 1:
        appendOutput(" ")
      appendOutput($columnNumber)
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The prompt is shared by both paths. The separator test skips the first value in each row. The final write closes the stream.

## Complexity

Output size grows with the square of N, since row lengths run from 1 to N.

| Phase | Time | Space |
| --- | --- | --- |
| input read | one pass over a small integer | one input string |
| row emission | N rows with N(N+1)/2 tokens | output buffer |
| output | one block flush plus a tail write | one block buffer |

The phase table shows that emission dominates the run.

| Measure | Big O |
| --- | --- |
| time | O(N^2) |
| space | O(1) beyond input and buffer |

A version that formatted every row into a separate string would allocate N extra strings.

The direct writer keeps memory flat while it grows the triangle.
