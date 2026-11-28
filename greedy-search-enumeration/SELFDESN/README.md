# SELFDESN — Self Descriptive Number (SPOJ)

<https://www.spoj.com/problems/SELFDESN/>

## Problem

A number is self-descriptive in base b when its b digits count themselves: digit i tells how many times i appears among the digits. Given the rank n and a modulus m, report the n-th smallest self-descriptive number in base 10, reduced modulo m.

Input starts with the number of test cases. Each case gives n and m on one line. Print one integer per case, the required value modulo m.

| item | bound |
|---|---|
| test cases | 1 to 100000 |
| rank n | 1 to 10^18 |
| modulus m | 1 to 10^9 |
| judge limit | 25000 ms, 1536 MB |

The huge rank forces a formula, since no program can print a number with 10^18 digits.

Sample input:

```
2
1 1000
2 1000
```

Sample output:

```
100
136
```

Those two answers are the smallest two self-descriptive numbers in base 4.

## Idea

Treat each base as a shelf holding a few labeled boxes. This is like a row of counters where each box reports how often its label appears. Only four shapes of the count vector work in any base. For bases from 7 upward there is exactly one number per base, so the rank maps straight to the base. Evaluate that number modulo m with repeated squaring, which takes O(log n) steps per case. Enumerating digits up to the chosen rank would take far longer. The rank-to-base map is the whole trick.

## Why It Works

1. The digit sum of a self-descriptive number equals b, because the digits count all b positions.
2. The weighted digit sum also equals b, because each counted label contributes its own index.
3. Solving the equations leaves two numbers in base 4 and one in base 5. Base 6 has none. Every base from 7 upward has one.
4. Values grow with the base, so the sorted order is base 4 twice, base 5 once, then one per base from 7.
5. Rank 1 and 2 give the base 4 numbers. Rank 3 gives base 5. Rank n at least 4 uses base n + 3.

| term | meaning |
|---|---|
| indexValue | the requested rank n |
| baseValue | n + 3 for ranks from 4 upward |
| leadingDigit | b - 4, reduced modulo m |
| powerMod | repeated squaring of a base modulo m |

The table names the pieces used to evaluate the number without storing its digits.

The generator prints the first few ordered numbers as follows:

```
first bases: [(4, '1210'), (4, '2020'), (5, '21200'), (7, '3211000'), (8, '42101000'), (9, '521001000')]
```

Rank 4 maps to base 7, whose value 389305 matches the fourth entry in the generated table.

For base b at least 7, the digits are b - 4, 2, 1, then zeros with a single 1 at position b - 4. The value has four terms. The first is (b - 4) times b to the power b - 1. The second is 2 times b to the power b - 2. The third is b to the power b - 3. The last is b cubed. Reducing the base before multiplying keeps every intermediate product under 10^18.

## Code

**Input and modular power.** The reader handles both query values, and squaring keeps products small.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc powerMod(baseValue: int64, exponentValue: int64, modulus: int64): int64 =
  var powerResult: int64 = 1 mod modulus
  var factor = baseValue mod modulus
  var remaining = exponentValue
  while remaining > 0:
    if (remaining and 1) == 1:
      powerResult = (powerResult * factor) mod modulus
    factor = (factor * factor) mod modulus
    remaining = remaining div 2
  return powerResult
```

The scanner reads only non-negative integers.
Each square is taken modulo m before the next step.
The exponent fits in a signed 64-bit value.

**Rank mapping.** Three small ranks have fixed values, and larger ranks use the base formula.

```nim
proc selfValueMod(indexValue: int64, modulus: int64): int64 =
  if indexValue == 1:
    return 100 mod modulus
  if indexValue == 2:
    return 136 mod modulus
  if indexValue == 3:
    return 1425 mod modulus
  let baseValue = indexValue + 3
  let reducedBase = baseValue mod modulus
  let leadingExponent = baseValue - 1
  let leadingPower = powerMod(reducedBase, leadingExponent, modulus)
  let secondPower = powerMod(reducedBase, leadingExponent - 1, modulus)
  let thirdPower = powerMod(reducedBase, leadingExponent - 2, modulus)
  let cubePower = powerMod(reducedBase, 3, modulus)
  let leadingDigit = (reducedBase - 4 + modulus) mod modulus
  let total = (leadingDigit * leadingPower + 2 * secondPower + thirdPower + cubePower) mod modulus
  return total
```

The first three ranks come from bases 4 and 5.
The leading digit is reduced before it multiplies a power.
All four powers use the same reduced base.

**Query loop.** Each case converts its inputs and writes one buffered answer.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let indexValue = int64(nextInt(inputData, scanPos))
  let modulus = int64(nextInt(inputData, scanPos))
  appendOutput($selfValueMod(indexValue, modulus))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Both query values are widened before use.
One line is appended per test case.
The final flush writes the whole buffer once.

## Complexity

Repeated squaring dominates each query.

| phase | time | space |
|---|---|---|
| input read | one pass over query pairs | one input string |
| exponentiation | four O(log n) powers | constant scratch |
| output | one line per case | block buffer |

Every case does the same fixed amount of exponentiation work.

| measure | Big O |
|---|---|
| time per case | O(log n) |
| space per case | O(1) |

Building every digit up to the rank would need O(n) work and an impossible amount of memory.

Repeated squaring reduces an enormous rank to about sixty multiplication steps.
