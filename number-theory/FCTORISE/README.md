# FCTORISE — Factorising Odd Numbers (SPOJ)

<https://www.spoj.com/problems/FCTORISE/>

## Problem

Write each odd number greater than 1 as a difference of two squares and show the matching factors. Use the pair with the smallest y, because the statement searches y from zero upward.

The first line holds the number of cases. Each following line holds one odd integer m greater than 1. Print m = x^2 - y^2 = (x+y)*(x-y) with the actual values, one line per case.

| item | bound |
|---|---|
| m | odd integer greater than 1 |
| output x, y | non-negative integers with x > y for m > 1 |
| judge limit | 1000 ms, 1536 MB |

The first matching y is required, so the factors must be the closest pair.

Sample input:

```
2
15
9929
```

Sample output:

```
15 = 4^2 - 1^2 = 5*3
9929 = 4965^2 - 4964^2 = 9929*1
```

## Idea

Finding the closest factor pair is like choosing the two nearest whole-number sides of a rectangle with a fixed area.

The method takes the largest divisor not above the square root, then derives x and y from that pair. Each candidate divisor costs one division. Scanning y upward can take about m/2 steps for a prime, so the divisor search is shorter.

Takeaway: search divisors near the square root, not offsets from zero.

## Why It Works

1. If m = x² − y², then m = (x + y) × (x − y).
2. Write a = x − y and b = x + y, so a × b = m and a ≤ b.
3. Then x = (a + b) / 2 and y = (b − a) / 2.
4. Both are integers because a and b are odd when m is odd.
5. A smaller y means a smaller gap b − a, hence a larger a up to the square root.
6. The largest divisor at or below the square root gives the first y from the statement.

| term | meaning |
|---|---|
| `numberValue` | the odd value m to factorise |
| `factorBelow` | largest divisor of m not above its square root |
| `factorAbove` | the partner divisor m divided by `factorBelow` |
| `squareRootX` | the value x in the difference of squares |
| `squareRootY` | the value y in the difference of squares |

Each term is a single integer in the solution.

For m = 15, the square root is 3 and the largest divisor there is 3. Its partner is 5, giving x = 4 and y = 1, so the line is 15 = 4^2 - 1^2 = 5*3. For m = 45, the largest divisor at or below 6 is 5, giving 45 = 7^2 - 2^2 = 9*5.

The square root uses division in its test, so no product overflows. The divisor search stops at 1, which handles primes such as 9929.

## Code

**Input and scanning.** The hand reader loads the case count and each value.

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

All values are positive, so the scanner needs no minus branch.
Line breaks and extra spaces are ignored.
The scan position moves past one number at a time.

**Buffered output.** One string holds the formatted lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes in large blocks.
A final write emits the remaining text.

**Integer square root.** A binary search finds the root without floating point.

```nim
proc integerSquareRoot(value: int64): int64 =
  var lowBound: int64 = 0
  var highBound: int64 = value
  while lowBound < highBound:
    let middle = (lowBound + highBound + 1) div 2
    if middle <= value div middle:
      lowBound = middle
    else:
      highBound = middle - 1
  return lowBound
```

The test `middle <= value div middle` avoids a large product.
The upper bound tightens on every false test.
The result is the floor of the true square root.

**Factor pair and line.** The closest divisor pair yields x, y, and the factors.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let numberValue = int64(nextInt(inputData, scanPos))
  var factorBelow = integerSquareRoot(numberValue)
  while factorBelow > 1 and numberValue mod factorBelow != 0:
    factorBelow -= 1
  let factorAbove = numberValue div factorBelow
  let squareRootX = (factorBelow + factorAbove) div 2
  let squareRootY = (factorAbove - factorBelow) div 2
  appendOutput($numberValue & " = " & $squareRootX & "^2 - " & $squareRootY & "^2 = " & $factorAbove & "*" & $factorBelow)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The search walks down from the square root to the first divisor.
The larger factor is printed before the smaller one.
Each case produces exactly one line.

## Complexity

Each case searches downward from the square root of its value.

| phase | time | space |
|---|---|---|
| input read | one pass over the cases | one input string |
| divisor search | up to the square root of m | constant |
| output | one line per case | one block buffer |

| measure | Big O |
|---|---|
| per case | O(sqrt(m)) |
| space | O(1) beyond the input |

Scanning y from zero upward takes O(m) steps for a prime.

Takeaway: the closest factor pair gives the required first match.
