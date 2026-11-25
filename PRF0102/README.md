# PRF0102 — sqrt (SPOJ)

<https://www.spoj.com/problems/PRF0102/>

## Problem

Read one number and print its square root with six digits after the decimal point. A negative input prints a refusal line instead of a root.

| item | contract |
|---|---|
| input | one number n |
| output for n at least zero | Square root of n is root, both with six decimals |
| output for negative n | Accept positive number only! |
| judge limit | 1000 ms, 1536 MB |

The number and its root share one output line.
Both values show exactly six digits after the decimal point.

Sample input:

```
6
```

Sample output:

```
Square root of 6.000000 is 2.449490
```

## Idea

Walking halfway toward a target each step closes in on a square root. The program instead uses one library square-root call, which already performs that work. It first rejects negative input, then formats the input and the root to six decimals. Each item costs one square-root call and two format calls. Printing the default float form would produce a different digit count. One guarded line of output finishes the run.

## Why It Works

1. The hand scanner keeps digits, a leading minus sign, and a decimal point.
2. A negative value stops processing before any square-root call.
3. A nonnegative value passes through the library square-root function.
4. Both the input and the root are formatted with six decimal places.
5. Concatenation joins the pieces, and a newline ends the line.

| term | meaning |
|---|---|
| `inputData` | text read from stdin |
| `scanPos` | current index inside `inputData` |
| `enteredNumber` | parsed input value as a float |
| `decimalPlaces` | fixed count of digits after the decimal point |
| `formattedRoot` | square root rendered with six decimals |

A short script checks the sample root by repeated averaging:

| step | estimate |
|---|---|
| start | 6.0000000 |
| after one averaging step | 3.5000000 |
| after two averaging steps | 2.6071429 |
| after four averaging steps | 2.4494944 |
| after five averaging steps | 2.4494897 |

Rounding to six decimals gives 2.449490, the printed value.

## Code

**Input handling.** The scanner accepts signed and decimal numbers.

```nim
import math
import strutils

const flushBlockBytes = 1 shl 17
const decimalPlaces = 6

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextNumber(data: string, pos: var int): float =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-' and data[pos] != '.':
    pos += 1
  var tokenStart = pos
  while pos < data.len and ((data[pos] >= '0' and data[pos] <= '9') or data[pos] == '-' or data[pos] == '.'):
    pos += 1
  if pos == tokenStart:
    return 0.0
  return parseFloat(data[tokenStart .. pos - 1])
```

The math module supplies the square-root function.
The strutils module supplies parsing and formatting.
The token keeps the sign and the decimal point.

**Guard and output.** A sign test selects the refusal or the formatted root.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let enteredNumber = nextNumber(inputData, scanPos)
if enteredNumber < 0:
  appendOutput("Accept positive number only!")
else:
  let formattedInput = formatFloat(enteredNumber, ffDecimal, decimalPlaces)
  let formattedRoot = formatFloat(sqrt(enteredNumber), ffDecimal, decimalPlaces)
  appendOutput("Square root of " & formattedInput & " is " & formattedRoot)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Negative input never reaches the square-root call.
Both printed values use the same fixed precision.
One write sends the completed line.

## Complexity

The run handles a single number.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| parse and root | one parse and one square-root call | constant |
| output | one line with two formatted values | one buffer string |

| measure | Big O |
|---|---|
| time | O(L), where L is input length |
| space | O(L) |

Computing the root by repeated averaging would add many divisions per item.

The library call and one buffered write cover the whole problem.
