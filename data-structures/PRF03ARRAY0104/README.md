# PRF03ARRAY0104 — ARRAY (MIN) (SPOJ)
<https://www.spoj.com/problems/PRF03ARRAY0104/>

## Problem

Read a count N and N signed integers, then show the input prompts and the smallest value. The prompt line carries every label with no newline, and the last line reports the minimum.

The input is N, then N integers, one per line. The output starts with How many element of numeric array: followed by The value of a[k] is: for k from 1 to N, all on one line. Two newlines follow, then Min: with the smallest value and a newline.

The bounds and judge limits are:

| item | bound |
| --- | --- |
| element count N | not stated; examples use 3 and 5 |
| values | signed integers, examples include -1 |
| output lines | N + 2 |
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

    Min:-1

The reported minimum is -1.

## Idea

Finding the smallest card in a hand is like picking the shortest pencil from a cup: keep the best one seen so far and replace it on a better find. A single linear minimum scan is the real algorithm.

Each value costs one comparison, so the scan is O(N) in total. Sorting the whole array to find the minimum would spend O(N log N) work and still need storage. Storing the parsed values once keeps the digit work linear.

## Why It Works

1. The count prompt and N value prompts are emitted before the result.
2. Each parsed integer is stored before the next prompt is written.
3. Two appended newlines place one blank line before the result.
4. The scan starts above every possible value and lowers the best on each find.
5. The result is written once with the Min: heading and a newline.

The terms carry the proof.

| term | meaning |
| --- | --- |
| `countPrompt` | fixed text before the count |
| `valuePromptPrefix` | fixed text before a one-based index |
| `valuePromptSuffix` | fixed text after each index |
| `minHeading` | fixed text before the result |
| `elementCount` | parsed number of values |
| `arrayValues` | stored list of parsed integers |
| `minValue` | smallest value seen during the scan |
| `elementIndex` | zero-based position in that list |

These names cover the whole driver.

The generator's oracle returns -1 for the sample. The scan starts with 2 at a[1] and lowers the best to -1 at a[2]. No later value drops it further.

No rounding applies. The scanner keeps the minus sign, so -1 survives the parse.

## Code

**Constants and full input read.** The header holds the fixed output strings.

```nim
const flushBlockBytes = 1 shl 17
const countPrompt = "How many element of numeric array:"
const valuePromptPrefix = "The value of a["
const valuePromptSuffix = "] is:"
const minHeading = "Min:"

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

**Prompt pass and minimum scan.** The driver reads values, then scans the stored list once.

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
var minValue = high(int)
for elementIndex in 0 .. elementCount - 1:
  if arrayValues[elementIndex] < minValue:
    minValue = arrayValues[elementIndex]
appendOutput(minHeading)
appendOutput($minValue)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The first loop prints prompts and saves values. The second loop keeps the smallest value. One write flushes the result.

## Complexity

Both parsing and the minimum scan are linear in N.

| phase | time | space |
| --- | --- | --- |
| input read | one pass over N integers | one input string |
| prompt pass | N prompt emissions | array of N integers |
| minimum scan | one comparison per value | one result variable |
| output | one result line | output buffer |

The phase table shows where the work goes.

| measure | Big O |
| --- | --- |
| time | O(N) |
| space | O(N) |

The measure table gives the growth rates.

Sorting the array to find the minimum would spend O(N log N) time on work the scan avoids.

The one-pass scan keeps the run linear from start to finish.
