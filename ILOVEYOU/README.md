# ILOVEYOU — I Love You (SPOJ)

<https://www.spoj.com/problems/ILOVEYOU/>

## Problem

Read one integer and place it inside a fixed sentence. The program echoes the value; it performs no arithmetic on it.

| item | contract |
|---|---|
| input | one line with a single integer x |
| output | one line: I Love you x times |
| judge limit | 1000 ms, 1536 MB |

The phrase uses an uppercase L and a lowercase y.
A trailing newline ends the output line.

Sample input:

```
3000
```

Sample output:

```
I Love you 3000 times
```

## Idea

Filling a blank on a form works the same way: copy the entered number into one fixed sentence. The real work is reading digits and joining them with two text pieces. Scanning builds the number digit by digit in one pass. Any other route still reads the same digits. One value means one line of output.

## Why It Works

1. The scanner skips bytes that are not digits or a minus sign.
2. Each digit enters the total after the total shifts by ten.
3. A leading minus sign negates the accumulated value.
4. Concatenation places the number between the two literal pieces.
5. The newline terminates the single output line.

| term | meaning |
|---|---|
| `inputData` | all input text, read in one pass |
| `scanPos` | current index inside `inputData` |
| `desiredCount` | integer parsed from the input |
| `outputBuffer` | pending output bytes |

A short script traces the sample digits and the joined phrase:

| step | visible result |
|---|---|
| scanned digits | 3, 0, 0, 0 |
| accumulated number | 3000 |
| joined pieces | "I Love you " + "3000" + " times" |

The sample number survives the scan unchanged.

## Code

**Input and scanning.** One read loop loads the whole input before parsing.

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

Non-digit bytes never enter the value.
The minus branch handles signed input.
The scanner stops after the first number.

**Output assembly.** The parsed value joins the two fixed text pieces.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let desiredCount = nextInt(inputData, scanPos)
appendOutput("I Love you " & $desiredCount & " times")
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The buffer collects the whole short line.
One write sends the result to stdout.

## Complexity

One scan reads the entire input once.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| parse | one pass over the number digits | constant |
| output | one line | one buffer string |

| measure | Big O |
|---|---|
| time | O(L), where L is input length |
| space | O(L) |

Parsing twice would add a second pass over the same digits.

For one integer, reading the input costs the whole run.
