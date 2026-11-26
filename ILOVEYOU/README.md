# ILOVEYOU — I Love You (SPOJ)

<https://www.spoj.com/problems/ILOVEYOU/>

## Problem

Read one integer x and print the sentence `I Love you x times`, with x replaced by the number itself.

The input is a single line holding one integer. The output is one line with the number written in decimal, no extra punctuation.

| item | bound |
|---|---|
| x | one integer, fits in 64 bits |
| output | one line |
| judge limit | 1000 ms, 1536 MB |

One parse and one formatted write do the job.

Sample input:

```
3000
```

Sample output:

```
I Love you 3000 times
```

## Idea

A fill-in-the-blank card only needs the blank filled. The scanner pulls the integer out of the text, and the answer is built by gluing fixed strings around its decimal form.

The scanner also accepts a leading minus sign, so negative input still prints correctly.

Takeaway: echo the number, wrap it in the fixed words.

## Why It Works

1. The digits of x are the only number in the input, so the first parsed value is x.
2. Skipping non-digit characters handles spaces and newlines around it.
3. A minus sign is read before the digits and applied to the value.
4. String concatenation places the number between the exact words from the statement.

For the sample, the scanner reads 3000 and the line becomes `I Love you 3000 times`.

A negative x prints with its sign, matching the integer's decimal form.

## Code

**Input and scanning.** The hand reader loads the file and parses one signed integer.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var isNegative = false
  if pos < data.len and data[pos] == '-':
    isNegative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if isNegative:
    return -value
  return value
```

The scanner skips spaces and newlines.
The sign branch keeps negative values exact.

**Buffered output.** One string collects the answer line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Large outputs flush in blocks.
One final write closes the remaining text.

**Answer line.** The number is glued between the fixed words.

```nim
let desiredCount = nextInt(inputData, scanPos)
appendOutput("I Love you " & $desiredCount & " times")
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`$desiredCount` gives the decimal form of the integer.
The sentence spacing follows the statement exactly.

## Complexity

The program scans the input once and writes one line.

| phase | time | space |
|---|---|---|
| read input | one pass over the file | one string |
| parse | one number | none |
| output | one line | one block buffer |

| measure | Big O |
|---|---|
| time | O(input size) |
| space | O(input size) |

Storing the sentence in a table would waste space for one line.

Takeaway: parse once, print once.
