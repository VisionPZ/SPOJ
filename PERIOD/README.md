## Problem

Read T strings, one length and one string per case. For each prefix, report its size and largest repetition count. A prefix qualifies when it equals a shorter block repeated more than once. Print a header line per case, the qualifying prefixes in increasing size, and a blank line after each case.

| Quantity | Bound |
| --- | --- |
| Test cases | 1 to 10 |
| String length | 2 to 1 000 000 |
| Character code | 97 to 126 |
| Time limit | 3000 ms |
| Memory limit | 1536 MB |

The string length drives the design, because every prefix needs an answer.

## Idea

Compute the border length of each prefix with the failure function from string matching. The smallest period of a prefix is its size minus that border length. When the size divides the smallest period, the prefix is one block repeated, and the count is the size divided by the period. Each character costs one amortized step, so the whole case is linear.

## Why It Works

A border is a proper prefix of a prefix that is also its suffix. The failure function stores the longest border for every position.

The period of a prefix of size i is:

period = i - border[i - 1]

The prefix repeats when i mod period = 0.

The repetition count is:

count = i / period

A count above one gives a line in the output. The smallest period gives the largest count, because any other repeating block is a multiple of it.

The script in `gen.py` checks the second sample string. The table lists each prefix size, its longest border, and its smallest period.

| Prefix size | Border | Period | Divides | Count |
| --- | --- | --- | --- | --- |
| 2 | 1 | 1 | yes | 2 |
| 3 | 0 | 3 | no | - |
| 4 | 1 | 3 | no | - |
| 5 | 2 | 3 | no | - |
| 6 | 3 | 3 | yes | 2 |
| 7 | 4 | 3 | no | - |
| 8 | 5 | 3 | no | - |
| 9 | 6 | 3 | yes | 3 |
| 10 | 7 | 3 | no | - |
| 11 | 8 | 3 | no | - |
| 12 | 9 | 3 | yes | 4 |

Only sizes 2, 6, 9 and 12 divide their period, which matches the sample output.

## Code

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

Each line is appended to one buffer, so the whole input is read before parsing. The trailing newline keeps the original line layout for the scanner. The loop runs once per input line.

```nim
proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextTokenStart(data: string, pos: var int, length: var int): int =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let startPos = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  length = pos - startPos
  return startPos
```

The integer scanner skips whitespace and builds values byte by byte. The token scanner records a string inside the buffer instead of copying it. Both stop at the end of the one input buffer.

```nim
proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendNumber(value: int) =
  let oldLen = outputBuffer.len
  outputBuffer.setLen(oldLen + 12)
  var pos = oldLen
  var rest = value
  if rest == 0:
    outputBuffer[pos] = '0'
    pos += 1
  else:
    let firstPos = pos
    while rest > 0:
      outputBuffer[pos] = char(firstDigitValue + rest mod 10)
      rest = rest div 10
      pos += 1
    var lowPos = firstPos
    var highPos = pos - 1
    while lowPos < highPos:
      swap outputBuffer[lowPos], outputBuffer[highPos]
      lowPos += 1
      highPos -= 1
  outputBuffer.setLen(pos)
```

The number writer places digits into the output buffer and reverses them in place. It avoids a temporary string for each number. The buffer is flushed once per block, not once per line.

```nim
  border.setLen(stringLength)
  border[0] = 0
  var matched = 0
  for position in 1..<stringLength:
    let currentChar = inputData[tokenStart + position]
    while matched > 0 and currentChar != inputData[tokenStart + matched]:
      matched = border[matched - 1]
    if currentChar == inputData[tokenStart + matched]:
      matched += 1
    border[position] = matched
```

The loop visits positions one through the end of the string. A mismatch falls back to the previous border, so the total fallback work is linear. Characters are read from the input buffer at `tokenStart + position`, with no extra copy.

```nim
  for prefixLength in 1..stringLength:
    let periodLength = prefixLength - border[prefixLength - 1]
    if prefixLength mod periodLength == 0:
      let repetitionCount = prefixLength div periodLength
      if repetitionCount > 1:
        appendNumber(prefixLength)
        outputBuffer.add ' '
        appendNumber(repetitionCount)
        outputBuffer.add '\n'
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop tests every prefix in increasing size, so the output is ordered. A count of one is skipped because a single copy is not a repetition. The final write empties any partial block left in the output buffer.

## Complexity

Reading the input takes time linear in its byte count. One case computes borders in O(n) time and writes at most n lines. The total is O(n) time per case and O(n) space for the border array. A naive version tests every possible block length for every prefix, which costs quadratic time or worse.
