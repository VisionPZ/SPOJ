# PIB — Pibonacci (SPOJ)

<https://www.spoj.com/problems/PIB/>

## Problem

Compute Pibonacci numbers at integer arguments. The function equals 1 below 4 and otherwise satisfies P(x) = P(x-1) + P(x-pi).

Input holds several non-negative integers below 30000, one per line. A line containing -1 ends the input. For each query, print P(x). When the answer has more than 50 digits, print 50 digits per line and put the remainder on a final shorter line.

| item | bound |
|---|---|
| query value x | 0 to 29999 |
| input terminator | -1 |
| output line width | 50 digits |
| judge limit | 7000 ms, 1536 MB |

The answers grow past 50 digits, so the output needs its own line width rule.

Sample input:

```
0
4
11
-1
```

Sample output:

```
1
2
20
```

## Idea

Count the paths in the recursion tree instead of walking the tree, like counting routes on a ladder with steps of 1 and pi. Each route picks a number of unit steps and pi steps before dropping below 4. A route that ends after j unit steps and k pi steps contributes a binomial coefficient. Grouping routes by k leaves only a few endpoints per k, because pi is larger than 3. The algorithm walks k upward and updates one binomial by a few small multiplications each time. Expanding every recursive call would create quadratically many intermediate values. Takeaway: turn the call tree into a short sum of binomial coefficients.

## Why It Works

1. Set T = x - 4. A recursive route stops when its total step length first exceeds T.
2. With k pi steps and j unit steps, the route count is C(j+k, k).
3. The last step is either a unit step or a pi step. The first case needs the prefix sum in (T-1, T], and the second case needs it in (T-pi, T].
4. For each k, the valid j values lie in an interval of length pi or 1, so at most four j values qualify.
5. Consecutive binomial coefficients change by multiplying and dividing by numbers below 30000, so one shared big integer updates through the whole sum.

| term | meaning |
|---|---|
| `threshold` | x minus 4, the last pre-base value |
| `highestP` | largest pi-step count with a valid unit-step count |
| `lowestFirst` | smallest j for the pi-step branch |
| `lowestSecond` | smallest j for the unit-step branch |
| `binomial` | current value of C(currentN, currentK) |
| `limbBase` | decimal base of each big-integer limb |

The table names the values that drive the summation.

For x = 11 the threshold is 7, and there are 20 valid routes. For x = 30 the sum is 27193. Both match the direct recursion.

The sample answers follow from the same route count.

## Code

**Input and scanning.** The hand reader supports the negative terminator.

```nim
import math

const flushBlockBytes = 1 shl 17
const limbBase = int64(1000000000)
const piValue = 3.14159265358979323846

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner keeps a sign for -1.
Numbers are built one digit at a time.
Output is written through a block buffer.

**Big integers.** Numbers use base one billion limbs.

```nim
proc trimNumber(value: var seq[int32]) =
  while value.len > 0 and value[value.len - 1] == 0:
    value.setLen(value.len - 1)

proc addNumber(target: var seq[int32], source: seq[int32]) =
  let maxLength = max(target.len, source.len)
  target.setLen(maxLength)
  var carry: int64 = 0
  for index in 0 .. maxLength - 1:
    var limbTotal = carry
    if index < target.len:
      limbTotal += int64(target[index])
    if index < source.len:
      limbTotal += int64(source[index])
    target[index] = int32(limbTotal mod limbBase)
    carry = limbTotal div limbBase
  if carry > 0:
    target.add int32(carry)

proc multiplyNumber(value: var seq[int32], factor: int64) =
  var carry: int64 = 0
  for index in 0 .. value.len - 1:
    let product = int64(value[index]) * factor + carry
    value[index] = int32(product mod limbBase)
    carry = product div limbBase
  while carry > 0:
    value.add int32(carry mod limbBase)
    carry = carry div limbBase

proc divideNumber(value: var seq[int32], divisor: int64) =
  var remainder: int64 = 0
  var index = value.len - 1
  while index >= 0:
    let current = remainder * limbBase + int64(value[index])
    value[index] = int32(current div divisor)
    remainder = current mod divisor
    index -= 1
  trimNumber(value)

proc numberToText(value: seq[int32]): string =
  if value.len == 0:
    return "0"
  result = $value[value.len - 1]
  var index = value.len - 2
  while index >= 0:
    var chunk = $value[index]
    while chunk.len < 9:
      chunk = "0" & chunk
    result.add chunk
    index -= 1
```

Multiplication and division use small factors only.
Each division is exact because the result is a binomial.
Text conversion prints nine digits per limb.

**Route sum.** The query is accumulated from updated binomials.

```nim
proc solveQuery(query: int): string =
  if query < 4:
    return "1"
  let threshold = query - 4
  var total = newSeq[int32](0)
  var currentN = threshold
  var currentK = threshold
  var binomial = newSeq[int32](1)
  binomial[0] = 1
  var firstTerm = true
  var stepCount = 0
  while true:
    let baseValue = float(threshold) - float(stepCount) * piValue
    let highestP = int(floor(baseValue + 1e-9))
    if highestP < 0:
      break
    let lowestFirst = int(floor(baseValue - piValue + 1e-9)) + 1
    let lowestSecond = int(floor(baseValue - 1.0 + 1e-9)) + 1
    var keptP = highestP
    while keptP >= max(0, lowestFirst):
      let wantedN = keptP + stepCount
      let wantedK = keptP
      if firstTerm:
        currentN = wantedN
        currentK = wantedK
        firstTerm = false
      else:
        while currentK > wantedK:
          multiplyNumber(binomial, int64(currentK))
          divideNumber(binomial, int64(currentN - currentK + 1))
          currentK -= 1
        while currentN > wantedN:
          multiplyNumber(binomial, int64(currentN - currentK))
          divideNumber(binomial, int64(currentN))
          currentN -= 1
      addNumber(total, binomial)
      if keptP >= lowestSecond:
        addNumber(total, binomial)
      keptP -= 1
    stepCount += 1
  return numberToText(total)

while true:
  let query = nextInt(inputData, scanPos)
  if query < 0:
    break
  let answerText = solveQuery(query)
  var digitPos = 0
  while digitPos < answerText.len:
    let chunkLength = min(50, answerText.len - digitPos)
    appendOutput(answerText.substr(digitPos, digitPos + chunkLength - 1))
    outputBuffer.add '\n'
    digitPos += chunkLength
stdout.write outputBuffer
outputBuffer.setLen 0
```

Both route branches add the same binomial when needed.
The step count ends once no unit steps remain.
The answer text is emitted in blocks of 50 digits.

## Complexity

The summation visits a few binomials per pi step.

| phase | time | space |
|---|---|---|
| input read | one pass over the query lines | one input string |
| route sum | O(x/pi) updated binomials | one big integer per accumulator |
| output | one write per 50 digits | block buffer |

Big integers hold about x decimal digits at most.

| measure | Big O |
|---|---|
| time per query | O(x^2) limb work |
| space per query | O(x) limbs |

Expanding the recursion would build quadratically many intermediate arguments. The route sum keeps only one running binomial.
