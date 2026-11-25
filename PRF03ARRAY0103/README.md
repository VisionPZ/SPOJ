# PRF03ARRAY0103 — ARRAY (SORT DESC) (SPOJ)
<https://www.spoj.com/problems/PRF03ARRAY0103/>

## Problem

Read a count N and N signed integers, then show the input prompts and the values sorted from largest to smallest. The prompt line carries every label with no newline, and the listing repeats each label beside a sorted value.

The input is N, then N integers, one per line. The output starts with How many element of numeric array: followed by The value of a[k] is: for k from 1 to N, all on one line.

Two newlines follow, then N element of numeric array: on its own line. The next N lines hold each prompt and one sorted value.

The bounds and judge limits are:

| item | bound |
| --- | --- |
| element count N | not stated; examples use 3 and 5 |
| values | signed integers, examples include -1 |
| output lines | N + 3 |
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

    5 element of numeric array:
    The value of a[1] is:8
    The value of a[2] is:3
    The value of a[3] is:2
    The value of a[4] is:0
    The value of a[5] is:-1

The listing holds the same values in descending order.

## Idea

Sorting numbered cards means sliding each card left until the cards before it sit in order, like arranging cards on a desk. Insertion sort is the real algorithm here.

Each inserted value scans at most N earlier values, so the cost is O(N) per item and O(N^2) overall. A naive approach rereads the raw text for every output line and reparses every digit. Storing the values once and sorting them keeps parsing linear.

## Why It Works

1. The count prompt and N value prompts are emitted before the listing.
2. Each parsed integer is stored before the next prompt is written.
3. Two appended newlines place one blank line before the heading.
4. Insertion sort moves each value left past smaller values, so the list ends descending.
5. The listing loop pairs one-based prompts with sorted values in matching positions.

The terms carry the proof.

| term | meaning |
| --- | --- |
| `countPrompt` | fixed text before the count |
| `valuePromptPrefix` | fixed text before a one-based index |
| `valuePromptSuffix` | fixed text after each index |
| `listHeadingSuffix` | fixed text after the count in the heading |
| `elementCount` | parsed number of values |
| `arrayValues` | stored values, then sorted descending |
| `holdValue` | value being inserted during a sort step |
| `priorIndex` | position scanned left during a sort step |

These names cover the whole driver.

The generator's oracle turns the sample values 2, -1, 8, 3, 0 into 8, 3, 2, 0, -1. The third sort step holds 8 and moves 2 and -1 right. The listing prints 8 at a[1] and -1 at a[5].

No rounding applies. The scanner keeps the minus sign, so -1 survives the parse.

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
appendOutput($elementCount)
appendOutput(listHeadingSuffix)
outputBuffer.add '\n'
for sortIndex in 1 .. elementCount - 1:
  var holdValue = arrayValues[sortIndex]
  var priorIndex = sortIndex - 1
  while priorIndex >= 0 and arrayValues[priorIndex] < holdValue:
    arrayValues[priorIndex + 1] = arrayValues[priorIndex]
    priorIndex -= 1
  arrayValues[priorIndex + 1] = holdValue
for elementIndex in 0 .. elementCount - 1:
  appendOutput(valuePromptPrefix)
  appendOutput($(elementIndex + 1))
  appendOutput(valuePromptSuffix)
  appendOutput($arrayValues[elementIndex])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The first loop prints prompts and saves values. The insertion sort orders the saved list. The second loop prints the sorted values.

## Complexity

Parsing and listing grow with N, and insertion sorting dominates the work.

| phase | time | space |
| --- | --- | --- |
| input read | one pass over N integers | one input string |
| prompt pass | N prompt emissions | array of N integers |
| insertion sort | up to N shifts per value | array of N integers |
| listing pass | N value lines | output buffer |

The phase table shows where the work goes.

| measure | Big O |
| --- | --- |
| time | O(N^2) |
| space | O(N) |

The measure table gives the growth rates.

Reparsing the input once per output line would also cost O(N^2) and duplicate digit work.

Storing the values once and sorting them gives one clean quadratic pass.
