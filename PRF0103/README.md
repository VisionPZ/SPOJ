# PRF0103 — Division (SPOJ)
<https://www.spoj.com/problems/PRF0103/>

## Problem

Read two integers and print their quotient rounded to six decimal places. Stop at a zero denominator and print a fixed warning instead.

Input holds pairs of integers, a numerator then a denominator, separated by any whitespace. Output holds both prompts and one answer per pair. Each prompt ends without a newline, so the answer continues on the prompt line.

| item | bound |
|---|---|
| numerator | signed integer, 32-bit range |
| denominator | signed integer, 32-bit range |
| printed decimals | 6 |
| judge limit | 1000 ms, 1536 MB |

The statement prints typed numbers in its examples; those numbers come from the terminal echo.

Statement Example 1 appears verbatim here:

    Please enter numerator: 7
    Please enter denominator: 0
    The denominator can't be zero!

The judge feeds only the typed numbers and compares only program output.

Sample input:

    7
    0

Sample output:

    Please enter numerator: Please enter denominator: The denominator can't be zero!

## Idea

Ask for both numbers before answering, like a cashier who confirms the price and the count before quoting a total.

The program scans each pair, tests the denominator, then formats one floating-point quotient. Each pair costs a constant number of arithmetic steps and a few buffer appends. Printing every prompt and digit with a separate formatted write would add many small writes. One output buffer collects the whole reply before each flush. Read the numbers, decide the answer, append once, repeat.

## Why It Works

1. The scanner skips whitespace and reads digits one at a time.
2. A leading minus sign flips the sign of the parsed value.
3. A zero denominator has no quotient, so the warning replaces the result.
4. Float division keeps the fractional part that integer division discards.
5. Six fixed decimals match the sample lines exactly.

| term | meaning |
|---|---|
| `numerator` | first integer of a pair |
| `denominator` | second integer of a pair |
| `quotient` | floating-point result of the division |
| `formatFloat` | renders the quotient with six decimals |

The generator checks these exact pairs before writing test data:

    7 0     -> The denominator can't be zero!
    -8 -5   -> Result: -8 / -5 = 1.600000
    10 -2   -> Result: 10 / -2 = -5.000000
    1 4     -> Result: 1 / 4 = 0.250000

Halfway rounding uses the exact fraction in the oracle and binary floating point in the solution. The chosen pairs stay far from a rounding tie.

## Code

**Input and buffer setup.** One read loop collects stdin, and the hand scanner yields signed integers.

```nim
import strutils

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
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var numberValue = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    numberValue = numberValue * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * numberValue

proc hasNextNumber(data: string, pos: int): bool =
  var scanIndex = pos
  while scanIndex < data.len and (data[scanIndex] < '0' or data[scanIndex] > '9') and data[scanIndex] != '-':
    scanIndex += 1
  return scanIndex < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner handles minus signs before digit runs.
The lookahead prevents an extra empty pair after the last newline.
The buffer flushes in blocks and once at exit.

**Prompts and answers.** Each pair produces two prompts and one guarded result line.

```nim
const numeratorPrompt = "Please enter numerator: "
const denominatorPrompt = "Please enter denominator: "
const zeroDenominatorMessage = "The denominator can't be zero!"
const resultPrefix = "Result: "
const resultSeparator = " / "
const resultEquals = " = "

while hasNextNumber(inputData, scanPos):
  let numerator = nextInt(inputData, scanPos)
  let denominator = nextInt(inputData, scanPos)
  appendOutput(numeratorPrompt)
  appendOutput(denominatorPrompt)
  if denominator == 0:
    appendOutput(zeroDenominatorMessage)
  else:
    let quotient = float(numerator) / float(denominator)
    appendOutput(resultPrefix)
    appendOutput($numerator)
    appendOutput(resultSeparator)
    appendOutput($denominator)
    appendOutput(resultEquals)
    appendOutput(formatFloat(quotient, ffDecimal, 6))
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Both prompts print before the denominator test.
The quotient uses float division and fixed six-place rendering.
A trailing newline closes each answer.

## Complexity

Each pair needs one scan of its digits and one formatted division.

| phase | time | space |
|---|---|---|
| input read | one pass over stdin | one input string |
| pair scan | constant work per pair | two integers |
| output | one buffered write per block | one output string |

| measure | Big O |
|---|---|
| time | O(total input characters) |
| space | O(total input characters) |

Separate writes per prompt and digit would multiply system calls on every pair. One divisor check and one buffered answer per pair keeps the work linear in the input size.
