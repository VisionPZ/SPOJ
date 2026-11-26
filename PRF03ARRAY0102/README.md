# PRF03ARRAY0102 — ARRAY (SORT ASC) (SPOJ)
<https://www.spoj.com/problems/PRF03ARRAY0102/>

## Problem

Read a count N and N signed integers, then show the input prompts and the values sorted from smallest to largest. The prompt line carries every label with no newline, and the listing repeats each label beside a sorted value.

The input is N, then N integers, one per line. The output starts with How many element of numeric array: followed by The value of a[k] is: for k from 1 to N, all on one line.

Two newlines follow, then ASC: on its own line, then N element of numeric array:. The next N lines hold each prompt and one sorted value.

The bounds and judge limits are:

| item | bound |
| --- | --- |
| element count N | not stated; examples use 3 and 5 |
| values | signed integers, examples include -1 |
| output lines | N + 4 |
| judge time | 1000 ms |
| judge memory | 1536 MB |

The statement gives no upper bound on the count or the values.

The sample input follows.

    5
    2
    -1
    8
    3
    0

These six integers supply the count and five values.

The expected output follows.

    How many element of numeric array:The value of a[1] is:The value of a[2] is:The value of a[3] is:The value of a[4] is:The value of a[5] is:

    ASC:
    5 element of numeric array:
    The value of a[1] is:-1
    The value of a[2] is:0
    The value of a[3] is:2
    The value of a[4] is:3
    The value of a[5] is:8

The listing holds the same values in ascending order.

## Idea

Sorting a hand of cards means putting the smallest card first, then the next smallest, until the row is in order. This program does not write its own sorting loop; it borrows the compiler's battle-tested routine, the same one shipped with the language, and only supplies the data and the direction.

A naive approach rereads the raw text for every output line and reparses every digit. Storing the values once, calling one library sort, and printing from the stored list keeps parsing linear and the code short.

## Why It Works

1. The count prompt and N value prompts are emitted before the listing.
2. Each parsed integer is stored before the next prompt is written.
3. Two appended newlines place one blank line, then the ASC: label line, then the heading.
4. The library sort orders the stored list from smallest to largest.
5. The listing loop pairs one-based prompts with sorted values in matching positions.

The terms carry the proof.

| term | meaning |
| --- | --- |
| `countPrompt` | fixed text before the count |
| `valuePromptPrefix` | fixed text before a one-based index |
| `valuePromptSuffix` | fixed text after each index |
| `orderLabel` | the ASC: line between blank line and heading |
| `listHeadingSuffix` | fixed text after the count in the heading |
| `elementCount` | parsed number of values |
| `arrayValues` | stored values, then sorted ascending |
| `cmp` | library comparator for the ascending order |
| `sort` | library routine that rearranges the list |

These names cover the whole driver.

The generator's oracle merge-sorts the sample values 2, -1, 8, 3, 0 into -1, 0, 2, 3, 8: it splits the row in half, sorts each half, then walks both halves together, always taking the smaller head. The listing prints -1 at a[1] and 8 at a[5].

No rounding applies. The scanner keeps the minus sign, so -1 survives the parse.

## Code

**Constants and full input read.** The header holds the five fixed output strings.

```nim
import algorithm

const flushBlockBytes = 1 shl 17
const countPrompt = "How many element of numeric array:"
const valuePromptPrefix = "The value of a["
const valuePromptSuffix = "] is:"
const orderLabel = "ASC:"
const listHeadingSuffix = " element of numeric array:"

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

The constants avoid repeated literals. The read loop loads all input before scanning.

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

Large blocks keep write calls rare. The final write empties any leftover text.

**Prompt pass, sort and listing.** The driver reads values, sorts them, then reuses the stored list.

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
appendOutput(orderLabel)
outputBuffer.add '\n'
appendOutput($elementCount)
appendOutput(listHeadingSuffix)
outputBuffer.add '\n'
sort(arrayValues, cmp)
for elementIndex in 0 .. elementCount - 1:
  appendOutput(valuePromptPrefix)
  appendOutput($(elementIndex + 1))
  appendOutput(valuePromptSuffix)
  appendOutput($arrayValues[elementIndex])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The first loop prints prompts and saves values. One library call orders the saved list. The second loop prints the sorted values.

## Complexity

Parsing and listing grow with N, and the library sort dominates the work.

| phase | time | space |
| --- | --- | --- |
| input read | one pass over N integers | one input string |
| prompt pass | N prompt emissions | array of N integers |
| library sort | comparisons and swaps | array of N integers |
| listing pass | N value lines | output buffer |

The phase table shows where the work goes.

| measure | Big O |
| --- | --- |
| time | O(N log N) |
| space | O(N) |

The measure table gives the growth rates.

Reparsing the input once per output line would add quadratic text work on top of the sort.

Storing the values once and sorting them gives one clean O(N log N) pass.
