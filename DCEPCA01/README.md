# DCEPCA01 — Good Luck (SPOJ)
<https://www.spoj.com/problems/DCEPCA01/>

## Problem

Choose the lucky numbers of length N that maximise a four-digit alternating score, then add the two smallest of them. Print that sum as an ordinary decimal integer.

Input starts with the test count, followed by one length per line. Output one line per test case with the required sum.

| item | bound |
|---|---|
| test cases T | 1 to 100 |
| length N | 4 to 100000 |
| digits allowed | 4 and 7 |
| judge limit | 1000 ms, 1536 MB |

Position zero is the most significant digit of the number.

Sample input:

```
1
4
```

Sample output:

```
8924
```

## Idea

The score counts unequal digit pairs two places apart, like checking alternating stripes on a fence. Split positions by parity: each parity strand must alternate, like a zipper with two independent tracks. Only three positions stay free, so eight strings can win, and the two smallest come from setting those free digits to four. Adding them digit by digit handles lengths beyond any built-in integer.

Each candidate costs one pass over N digits.

## Why It Works

1. The prefix difference in H collapses to a comparison of digits i+1 and i+3.
2. H equals one exactly when those two digits differ, and zero otherwise.
3. The largest possible score is N minus three, reached when every compared pair differs.
4. Parity strands give independent alternations, leaving digits zero, one, and two free.
5. Sorting the eight winners by value puts the two smallest first.

| term | meaning |
|---|---|
| `buildDynamicNumber` | builds a winning digit string for one even seed |
| `evenSeed` | digit chosen at position two |
| `sumDigits` | digit-by-digit result of adding two winners |
| `carry` | value passed to the next more significant digit |

The worked example uses length six and the two smallest winners.

| position | 0 | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|---|
| first number | 4 | 4 | 4 | 7 | 7 | 4 |
| second number | 4 | 4 | 7 | 7 | 4 | 4 |
| sum | 8 | 9 | 2 | 5 | 1 | 8 |

The sum reads 892518 from the table.

No rounding appears, and the carry stays below two.

## Code

**Input and scanner.** The reader loads every line and parses test lengths.

```nim
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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

```

**Output helper.** One string collects output and flushes in large blocks.

```nim
proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc buildDynamicNumber(length, evenSeed: int): string =
```

**Digit builder.** Each call expands the parity alternation from a free digit.

```nim
  for position in 0 .. length - 1:
    var digitValue = 4
    if position == 2:
      digitValue = evenSeed
    elif position >= 3 and (position mod 2) == 1:
      let stepIndex = (position - 3) div 2
      if stepIndex mod 2 == 0:
        digitValue = 7
      else:
        digitValue = 4
    elif position >= 4 and (position mod 2) == 0:
      let stepIndex = (position - 4) div 2
      if evenSeed == 4:
        if stepIndex mod 2 == 0:
          digitValue = 7
        else:
          digitValue = 4
      else:
        if stepIndex mod 2 == 0:
          digitValue = 4
        else:
          digitValue = 7
    result[position] = char(48 + digitValue)

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let numberLength = nextInt(inputData, scanPos)
  let firstNumber = buildDynamicNumber(numberLength, 4)
```

Odd positions alternate from the fixed leading seven, and even positions alternate from the seed.

**Main loop.** Two builders give the smallest winners, and a reversed add produces their sum.

```nim
  var sumDigits = newString(numberLength + 1)
  var writePosition = numberLength
  var carry = 0
  var position = numberLength - 1
  while position >= 0:
    let digitTotal = int(firstNumber[position]) + int(secondNumber[position]) - 96 + carry
    sumDigits[writePosition] = char(48 + (digitTotal mod 10))
    carry = digitTotal div 10
    writePosition -= 1
    position -= 1
  if carry > 0:
    sumDigits[writePosition] = char(48 + carry)
    writePosition -= 1
  appendOutput(sumDigits[writePosition + 1 .. numberLength])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Digits are added from right to left with a running carry.
The final slice drops any unused leading slot in the result string.
Each test case contributes exactly one line.

## Complexity

Each test case builds two strings and adds them once.

| phase | time | space |
|---|---|---|
| input read | one pass over T lengths | one input string |
| digit building | two passes over N positions | two strings of N digits |
| addition | one pass over N digits | result string of N digits |
| output | one line per case | block buffer |

| measure | Big O |
|---|---|
| time per case | O(N) |
| space per case | O(N) |

Enumerating all lucky strings would test two to the power of N candidates.

The parity argument reduces that search to eight fixed constructions.
