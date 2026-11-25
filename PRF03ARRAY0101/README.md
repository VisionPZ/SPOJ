# PRF03ARRAY0101 — ARRAY (INPUT,OUTPUT) (SPOJ)
<https://www.spoj.com/problems/PRF03ARRAY0101/>

## Problem

Read a count N and N integers, then echo them in a fixed two-part layout. The first part prints every input prompt with no newline; the second part prints a heading and the saved values.

The input is N followed by N integers, each on its own line. The output begins with the exact text How many element of numeric array:. A prompt named The value of a[k] is: follows for each k from 1 to N, all on one line. Two newlines follow, then N element of numeric array: on its own line. The last N lines repeat each prompt with its value appended.

The bounds and judge limits are:

| Constraint | Value |
| --- | --- |
| Input | one count and that many integers |
| Values | may be negative |
| Output lines | N + 3 |
| Judge time | 1000 ms |
| Judge memory | 1536 MB |

The statement gives no upper bound on N or on the values.

The sample input is 5 with values 2, -1, 8, 3 and 0. It follows.

    5
    2
    -1
    8
    3
    0

The expected output follows.

    How many element of numeric array:The value of a[1] is:The value of a[2] is:The value of a[3] is:The value of a[4] is:The value of a[5] is:

    5 element of numeric array:
    The value of a[1] is:2
    The value of a[2] is:-1
    The value of a[3] is:8
    The value of a[4] is:3
    The value of a[5] is:0

## Idea

Filling an array is like completing a labelled form: write each field label while you read its value, then show the filled form.
The program prints the count prompt, then one value prompt per input number.
It stores the parsed integers in `arrayValues` while it reads.
After reading, it writes two newlines, the count heading and the saved values one per line.
A second scan over raw text to recover values would reread every digit.
Storing the parsed values once keeps each digit read a single time.
The shared prompt constants keep the two output parts identical in spelling.

## Why It Works

1. The count prompt is emitted before any value is read, like an interactive terminal.
2. Each value prompt is emitted immediately before its number is parsed.
3. The scanner skips separators and accepts a leading minus sign.
4. Two appended newlines create the blank line between the prompt line and the heading.
5. The heading interpolates the count, which matches the sample text.
6. The listing loop pairs each stored value with its one-based index.

The terms carry the proof.

| Term | Meaning |
| --- | --- |
| countPrompt | fixed text before the count is read |
| valuePromptPrefix | fixed text before a one-based index |
| valuePromptSuffix | fixed text after each index |
| listHeadingSuffix | fixed text after the count in the heading |
| elementCount | parsed number of array elements |
| arrayValues | stored list of parsed integers |
| elementIndex | zero-based position in that list |

The term table names every value that shapes the output.

A script check of the sample gives 5 input values and 10 prompt occurrences.
The count heading reads 5 element of numeric array:. The listing holds 5 lines.
The value -1 keeps its minus sign in the last line of the sample.

No rounding applies. The minus branch in the scanner is the guard for signed values.

## Code

**Constants and full input read.** The header holds the four fixed output strings.

```nim
const flushBlockBytes = 1 shl 17
const countPrompt = "How many element of numeric array:"
const valuePromptPrefix = "The value of a["
const valuePromptSuffix = "] is:"
const listHeadingSuffix = " element of numeric array:"

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

The constants avoid repeated string literals in the driver. The read loop loads the whole input before scanning.

**Integer scanner with sign.** The hand scanner skips separators and handles negative numbers.

```nim
var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and ((data[pos] < '0' or data[pos] > '9') and data[pos] != '-'):
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value
```

The sign is applied after the digits are folded. This matches the negative value in the sample.

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

**Prompt pass and listing pass.** The driver reads values, then reuses the stored list.

```nim
let elementCount = nextInt(inputData, scanPos)
appendOutput(countPrompt)
var arrayValues = newSeq[int](elementCount)
for elementIndex in 0 .. elementCount - 1:
  appendOutput(valuePromptPrefix)
  appendOutput($(elementIndex + 1))
  appendOutput(valuePromptSuffix)
  arrayValues[elementIndex] = nextInt(inputData, scanPos)
outputBuffer.add '\n'
outputBuffer.add '\n'
appendOutput($elementCount)
appendOutput(listHeadingSuffix)
outputBuffer.add '\n'
for elementIndex in 0 .. elementCount - 1:
  appendOutput(valuePromptPrefix)
  appendOutput($(elementIndex + 1))
  appendOutput(valuePromptSuffix)
  appendOutput($arrayValues[elementIndex])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The first loop prints prompts and saves values. The two newlines create the blank line. The second loop prints the saved values.

## Complexity

Both the input and the output grow linearly with N.

| Phase | Time | Space |
| --- | --- | --- |
| input read | one pass over N integers | one input string |
| prompt pass | N prompt emissions | array of N integers |
| listing pass | N value lines | output buffer |

The phase table shows that each pass visits every element once.

| Measure | Big O |
| --- | --- |
| time | O(N) |
| space | O(N) for the stored values |

Parsing the input twice would double the digit work and still need storage.

The single parse with stored values keeps the run linear from start to finish.
