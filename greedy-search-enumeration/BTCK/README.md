# BTCK — A problem of Backtracking (SPOJ)

<https://www.spoj.com/problems/BTCK/>

## Problem

Ten positive integers are given together with a limit `K`. Assign each digit from zero to nine to exactly one of the ten integers. The cost of an assignment is the sum of each digit times its partner integer. Find an assignment whose cost is at most `K`. Among all such assignments, print the lexicographically smallest one, or `-1` when none exists.

The first line holds the test count. Each case has a line of ten integers and a line with `K`. Print ten digits separated by single spaces, or `-1`.

| Item | Bound |
|---|---|
| Test cases | not stated by the statement |
| Each integer | 1 to 10<sup>9</sup> |
| Limit `K` | 1 to 10<sup>9</sup> |
| Judge limit | 1000 ms, 1536 MB |

The sample input:

```
2
1 2 3 4 5 6 7 8 9 10
200
1 2 3 4 5 6 7 8 9 10
100
```

The sample output:

```
2 6 8 9 7 5 4 3 1 0
-1
```

## Idea

Think of ten halls with different entrance fees and ten numbered tickets. Spend the cheapest tickets where the fees are highest, then decide the halls from left to right.

The program fixes digits from left to right. At each position it tries unused digits in ascending order. For a candidate it computes the spent cost plus the candidate cost plus the smallest possible remaining cost. The smallest remaining cost pairs the leftover digits in ascending order with the remaining integers in descending order. The first candidate that fits is kept. Each candidate costs one short insertion sort of at most nine numbers.

## Why It Works

1. Lexicographic order is decided by the earliest digit that differs.
2. Fixing digits from left to right keeps the prefix as small as possible at every step.
3. A fixed prefix leaves only one question: can the remaining digits pay for the remaining positions?
4. By the rearrangement inequality, ascending digits with descending integers minimize the remaining sum.
5. Insertion sort produces that descending order for the at most nine remaining integers.
6. When no digit fits a position, no completion of this prefix fits either.

| Term | Meaning |
|---|---|
| `coefficients` | the ten given integers |
| `limitValue` | the allowed cost `K` |
| `available` | which digits are still unused |
| `spentSoFar` | cost of the fixed prefix |
| `tailCoefficients` | remaining integers, sorted descending |
| `chosenDigit` | smallest fitting digit at the current position |

A script-generated trace of the first sample case:

```
rates: 1 2 3 4 5 6 7 8 9 10, budget 200
digit 0 at position 0 needs at least 210, rejected
digit 1 at position 0 needs at least 201, rejected
digit 2 at position 0 needs 193, accepted
digits 0 to 5 at position 1 all exceed the budget
digit 6 at position 1 is accepted
final digits: 2 6 8 9 7 5 4 3 1 0, cost 200
```

The traced digits match the sample output.

## Code

**Input and scanner.** Read all lines once and scan integers by index.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner accepts only digit bytes. The buffer flushes every 128 KiB.

**Best remaining cost.** Sort the later integers downward and pair them with unused digits upward.

```nim
proc minimalTailSum(coefficients: seq[int], available: seq[bool], position: int): int =
  if position >= 9:
    return 0
  var tailCoefficients = newSeq[int](9 - position)
  for index in position + 1 .. 9:
    tailCoefficients[index - position - 1] = coefficients[index]
  for outerIndex in 1 ..< tailCoefficients.len:
    let heldValue = tailCoefficients[outerIndex]
    var innerIndex = outerIndex - 1
    while innerIndex >= 0 and tailCoefficients[innerIndex] < heldValue:
      tailCoefficients[innerIndex + 1] = tailCoefficients[innerIndex]
      innerIndex -= 1
    tailCoefficients[innerIndex + 1] = heldValue
  var digitIndex = 0
  var total = 0
  for digit in 0 .. 9:
    if available[digit]:
      total += digit * tailCoefficients[digitIndex]
      digitIndex += 1
  return total
```

The insertion sort handles a tiny list without a generic comparator. Pairing order gives the least possible tail cost.

**Driver.** Choose digits left to right, then print the answer.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  var coefficients = newSeq[int](10)
  for coeffIndex in 0 .. 9:
    coefficients[coeffIndex] = nextInt(inputData, scanPos)
  let limitValue = nextInt(inputData, scanPos)
  var available = newSeq[bool](10)
  for digit in 0 .. 9:
    available[digit] = true
  var answer = newSeq[int](10)
  var possible = true
  var spentSoFar = 0
  for position in 0 .. 9:
    var chosenDigit = -1
    for digit in 0 .. 9:
      if not available[digit]:
        continue
      available[digit] = false
      let candidateTotal = spentSoFar + coefficients[position] * digit + minimalTailSum(coefficients, available, position)
      if candidateTotal <= limitValue:
        chosenDigit = digit
        break
      available[digit] = true
    if chosenDigit < 0:
      possible = false
      break
    spentSoFar += coefficients[position] * chosenDigit
    answer[position] = chosenDigit
  if not possible:
    appendOutput("-1\n")
  else:
    for position in 0 .. 9:
      if position > 0:
        appendOutput(" ")
      appendOutput($answer[position])
    appendOutput("\n")
stdout.write outputBuffer
```

A failed candidate restores its digit. The accumulated cost keeps later checks consistent.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | one input string |
| One candidate | sort of at most nine integers | nine integers |
| One case | ten positions times ten candidates | ten digits and ten integers |
| Output | one write per filled buffer | one output string |

| Measure | Big O |
|---|---|
| Time per case | O(10<sup>3</sup>), a constant |
| Total time | O(test cases + input size) |
| Space | O(1) beyond input |

Trying all 10! permutations would test 3,628,800 orders per case. The greedy check settles each position after at most ten tries.
