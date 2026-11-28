<https://www.spoj.com/problems/SIOKULE/>

## Problem

One tower of N cubes is split by Petar into at least two smaller towers, which he orders in a row. Tux keeps the kth tower and Petar pays k squared dinars immediately; play repeats on that kept tower until it has one cube. Report the amount Petar pays when both players play optimally, for N up to ten to the hundredth power.

| item | bound |
|---|---|
| cubes N | 2 to 10^100 |
| answer | small enough for a machine integer |
| judge limit | 1000 ms, 1536 MB |

Payment for choosing tower position k is k multiplied by k.

Sample input:

```
7
```

Sample output:

```
8
```

## Idea

Splitting a tower is like cutting a rope into pieces while the buyer names the piece they keep. A larger kept piece belongs earlier in the row, because later positions cost more. Work backwards: record how many cubes a player can afford for a given maximum payment, then search for the smallest payment covering N.

## Why It Works

1. Let capacity(K) be the largest tower size whose game value is at most K.
2. A split into k ordered parts stays affordable when part i has value at most K minus i squared.
3. Hence capacity(K) equals the sum of capacity(K minus i squared) over legal positions i.
4. The smallest K with capacity(K) at least N is exactly the game value of N.
5. Adding parts only raises the sum, so all positions through the square root of K are used.

| term | meaning |
|---|---|
| `capacityByCost` | table of affordable tower sizes by payment limit |
| `rootPart` | largest position whose square does not exceed the limit |
| `cubeCount` | input tower size as decimal digits |
| `answerCost` | smallest affordable payment limit |

Decimal digits use base ten with the least significant digit first.

## Code

**Input and arithmetic helpers.** The hand reader extracts a decimal number of arbitrary length.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextDigits(data: string, pos: var int): seq[int] =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var reversedDigits = newSeq[int]()
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    reversedDigits.insert(int(data[pos]) - 48, 0)
    pos += 1
  while reversedDigits.len > 1 and reversedDigits[reversedDigits.len - 1] == 0:
    reversedDigits.setLen(reversedDigits.len - 1)
  return reversedDigits

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner keeps digits without converting them to a machine integer.
Leading zeroes are removed after reading.
Output buffering follows the shared convention.

**Big addition and comparison.** Decimal digits make the table arithmetic exact.

```nim
proc addNumbers(leftNumber: seq[int], rightNumber: seq[int]): seq[int] =
  var sumDigits = newSeq[int]()
  var carry = 0
  var digitIndex = 0
  while digitIndex < leftNumber.len or digitIndex < rightNumber.len:
    var digitTotal = carry
    if digitIndex < leftNumber.len:
      digitTotal += leftNumber[digitIndex]
    if digitIndex < rightNumber.len:
      digitTotal += rightNumber[digitIndex]
    sumDigits.add digitTotal mod 10
    carry = digitTotal div 10
    digitIndex += 1
  if carry > 0:
    sumDigits.add carry
  return sumDigits

proc compareNumbers(leftNumber: seq[int], rightNumber: seq[int]): int =
  if leftNumber.len < rightNumber.len:
    return -1
  if leftNumber.len > rightNumber.len:
    return 1
  for digitIndex in countdown(leftNumber.len - 1, 0):
    if leftNumber[digitIndex] < rightNumber[digitIndex]:
      return -1
    if leftNumber[digitIndex] > rightNumber[digitIndex]:
      return 1
  return 0
```

Carries propagate one decimal place at a time.
Comparison checks length before individual digits.
Both procedures ignore absent digits as zeroes.

**Capacity table and search.** The table grows until it covers the input tower.

```nim
proc numberToString(value: seq[int]): string =
  var result = ""
  for digitIndex in countdown(value.len - 1, 0):
    result.add char(48 + value[digitIndex])
  return result

let cubeCount = nextDigits(inputData, scanPos)
var capacityByCost = newSeq[seq[int]]()
capacityByCost.add @[1]
capacityByCost.add @[1]
capacityByCost.add @[1]
capacityByCost.add @[1]

var answerCost = 0
var currentCost = 4
while true:
  var rootPart = 0
  while (rootPart + 1) * (rootPart + 1) <= currentCost:
    rootPart += 1
  var capacity = newSeq[int]()
  for splitIndex in 1 .. rootPart:
    capacity = addNumbers(capacity, capacityByCost[currentCost - splitIndex * splitIndex])
  capacityByCost.add capacity
  if compareNumbers(capacity, cubeCount) >= 0:
    answerCost = currentCost
    break
  currentCost += 1

appendOutput($answerCost)
appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Four base entries cover payment limits below four.
Every later entry sums the capacities of smaller limits.
The loop stops once the table covers the input.

## Complexity

The answer stays below seven hundred even for a hundred-digit tower.

| phase | time | space |
|---|---|---|
| input read | one pass over the digits | one input string |
| table build | up to about seven hundred additions | one digit table |
| search | one comparison per limit | constant |
| output | one line | block buffer |

| measure | Big O |
|---|---|
| time | O(answer times square root of answer times digits) |
| space | O(answer times digits) |

Enumerating every split of the original tower would take exponential time.
