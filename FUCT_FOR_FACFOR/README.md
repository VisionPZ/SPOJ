# FUCT_FOR_FACFOR — Factorial formula (SPOJ)

<https://www.spoj.com/problems/FUCT_FOR_FACFOR/>

## Problem

Each test gives one integer n. The task is to print n! written out step by step, like `5!=1*2*3*4*5=120`. A negative n gets the message `accept positive integer only!` instead. Zero counts as positive here: `0!=1`.

Input starts with a test count. Each test line holds one integer, which may be negative. Output holds one line per test.

| Item | Bound |
|---|---|
| Test count | 1 ≤ t ≤ 1000 |
| n | integer, negatives possible |
| Judge limit | 1000 ms, 1536 MB |

The sample case:

```
5
0
5
9
-3
1
```

```
0!=1
5!=1*2*3*4*5=120
9!=1*2*3*4*5*6*7*8*9=362880
accept positive integer only!
1!=1
```

## Idea

The answer line is the product spelled out, then its value. The value can have hundreds of digits, so the program keeps factorials as big numbers made of 9-digit blocks, like column arithmetic with base 1,000,000,000 columns. It reads all queries first, then builds every factorial from 0! up to the largest asked, each from the previous one by one multiply. That costs about 300,000 block operations for n = 1000, shared by all tests. Recomputing each factorial from scratch repeats the same multiplications once per test.

## Why It Works

1. k! = (k−1)! × k, so one multiply per step walks from 0! to the largest needed factorial.
2. Storing digits in base 10⁹ blocks keeps every product under 10⁹ × 10⁴, inside a 64-bit integer.
3. `multiplySmall` pushes the overflow as a carry into higher blocks, exactly like hand multiplication.
4. Printing pads every block below the top to 9 digits, so no leading zeros appear at the front and none are lost in the middle.
5. Lines for n = 0 and n = 1 are special-cased to `n!=1`, matching the sample.

| Term | Meaning |
|---|---|
| `factorialDigits` | running k! as 9-digit blocks, low block first |
| `multiplySmall` | multiplies one big number by a small factor |
| `groupsToText` | turns blocks into decimal text with padding |
| `factorialTexts` | table of finished factorial strings |
| `largestQuery` | biggest n among the tests |

One pass over the table answers every test.

A script-traced example from `gen.py`:

```
n = 5
terms: 1*2*3*4*5
value: 120
line: 5!=1*2*3*4*5=120
```

The trace matches the second sample answer.

## Code

**Input and hand scanner.** This block loads stdin and reads signed integers by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const bigBase = 1000000000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextSignedInt(data: string, position: var int): int =
  while position < data.len and data[position] != '-' and (data[position] < '0' or data[position] > '9'):
    position += 1
  var isNegative = false
  if position < data.len and data[position] == '-':
    isNegative = true
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  if isNegative:
    return -value
  return value
```

One readLine loop collects all input bytes.
The '-' branch lets negative tests parse.
Scanning costs one pass over the consumed characters.

**Big-number multiply and print.** This block handles factorials with hundreds of digits.

```nim
proc multiplySmall(number: var seq[int], factor: int) =
  var carry = 0
  for groupIndex in 0..<number.len:
    let product = number[groupIndex] * factor + carry
    number[groupIndex] = product mod bigBase
    carry = product div bigBase
  while carry > 0:
    number.add carry mod bigBase
    carry = carry div bigBase

proc groupsToText(number: seq[int]): string =
  var text = ""
  var groupIndex = number.len - 1
  text.add $(number[groupIndex])
  while groupIndex > 0:
    groupIndex -= 1
    var part = $(number[groupIndex])
    while part.len < 9:
      part = "0" & part
    text.add part
  return text
```

Each block product stays below 2⁶³, so no overflow occurs.
The top block prints unpadded; lower blocks get leading zeros.
One multiply costs one pass over the blocks of k!.

**Table build.** This block reads all queries, then grows factorials up to the largest.

```nim
var queries: seq[int] = @[]
var largestQuery = 0
let caseCount = nextSignedInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let queryValue = nextSignedInt(inputData, scanPos)
  queries.add queryValue
  if queryValue > largestQuery:
    largestQuery = queryValue

var factorialTexts: seq[string] = @[]
factorialTexts.setLen(largestQuery + 1)
var factorialDigits: seq[int] = @[1]
factorialTexts[0] = "1"
for factor in 1..largestQuery:
  multiplySmall(factorialDigits, factor)
  factorialTexts[factor] = groupsToText(factorialDigits)
```

`setLen` fills the table with empty strings before assignment.
Each line of the table reuses the previous factorial, one multiply per row.

**Answer loop.** This block writes the spelled-out product and the table value.

```nim
for caseIndex in 0..<caseCount:
  let queryValue = queries[caseIndex]
  if queryValue < 0:
    appendOutput("accept positive integer only!\n")
  elif queryValue <= 1:
    appendOutput($(queryValue) & "!=1\n")
  else:
    appendOutput($(queryValue) & "!=")
    for factor in 1..queryValue:
      if factor != 1:
        appendOutput("*")
      appendOutput($(factor))
    appendOutput("=")
    appendOutput(factorialTexts[queryValue])
    appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The buffer flushes every 128 KiB inside `appendOutput`.
Each test writes its factors, then one table lookup.

## Complexity

Startup builds the factorial table once; tests only print.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Table build | O(M² / 9) block ops, M = largest n | factorial strings |
| Answers | O(sum of n) characters printed | block buffer |

At M = 1000 the table build is under a million block operations.

| Measure | Big O |
|---|---|
| Time | O(N + M² / 9 + output) |
| Space | O(N + M² / 9) |

Recomputing each factorial per test costs O(t × M² / 9); the shared table cuts that to one pass.
