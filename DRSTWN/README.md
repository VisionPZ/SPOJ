# DRSTWN — input24021986 (SPOJ)

<https://www.spoj.com/problems/DRSTWN/>

## Problem

Read two natural numbers and print their sum. The two values may arrive on one line or on separate lines.

Input holds exactly two integers. Output holds one integer, the sum.

The numbers are small.

| item | bound |
|---|---|
| each number | 0 to 200 |
| judge limit | 1000 ms, 1536 MB |

White space between the two numbers is unimportant, so a single scanner handles both layouts.

Sample input:

```
4 5
```

Sample output:

```
9
```

## Idea

Scan the two integers and add them, like counting two piles of stones by combining them.

The real algorithm is integer addition after a hand parse. A loop over every number would add needless work. One addition per run is the whole task. The takeaway is to parse once and add once.

## Why It Works

1. The scanner skips white space, so line layout does not matter.
2. `firstNumber` holds the first value read.
3. `secondNumber` holds the second value read.
4. Their sum is the required output.

| term | meaning |
|---|---|
| `firstNumber` | first scanned value |
| `secondNumber` | second scanned value |
| `numberSum` | sum written to the output buffer |

The sum of two small numbers fits easily in an `int`.

For the sample the scanner reads 4 then 5. The sum is 9.

No overflow guard is needed because each input stays below 201.

## Code

**Input and scanner.** One read loop collects all text, and a digit scanner yields each value.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

The scanner builds values digit by digit.
It skips both spaces and newlines.
No sign handling appears because inputs are natural numbers.

**Addition and buffered output.** The answer is written once through the block buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let firstNumber = nextInt(inputData, scanPos)
let secondNumber = nextInt(inputData, scanPos)
let numberSum = firstNumber + secondNumber
appendOutput($numberSum)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The two scanned values are added directly.
One newline follows the answer.
The final write clears the buffer.

## Complexity

Every step runs once.

| phase | time | space |
|---|---|---|
| input read | one pass over the stream | one input string |
| scan and add | two integer reads | constant |
| output | one line | one output buffer |

The counts below describe the whole run.

| measure | Big O |
|---|---|
| time | O(1) |
| space | O(input size) |

Testing every possible pair would take quadratic work, while one addition settles the answer.
