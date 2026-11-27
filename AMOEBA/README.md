# AMOEBA — Amoeba (SPOJ)

<https://www.spoj.com/problems/AMOEBA/>

## Problem

A colony starts with one amoeba, and every day each amoeba spawns six more while surviving, giving 7^(d - 1) amoebae on day d. Given the last K digits of a colony size, find the earliest day that ends with those digits, or print -1 if none does.

Each input line holds one K-digit string, possibly with leading zeros. Print the earliest day on its own line, or -1 when impossible.

The constraints and judge limits:

| item | bound |
|---|---|
| digit count K | 1 to 9 |
| input lines | until end of file |
| judge limit | 301 ms, 1536 MB |

Leading zeros fix K, so the scanner reads raw tokens instead of plain integers.

Sample input and output:

```
01
143
743
600
```

```
1
20
12
-1
```

Each line maps a K-digit suffix to its first matching day.

## Idea

Lift the exponent one decimal digit at a time, like setting a combination lock one dial from right to left.

Starting from the last digit modulo 10, each step extends the solution from modulo 10^m to modulo 10^(m+1) by testing multiples of the current cycle length. This is Hensel lifting (extending a modular root one digit at a time), costing O(K^2) modular multiplications and O(1) memory per query. Building a full cycle table up to 10^9 would store millions of residues and waste both time and memory.

Lifting one digit per step solves each query in constant space and microseconds.

## Why It Works

1. Day d has 7^(d - 1) amoebae, so the last K digits equal 7^e mod 10^K with e = d - 1.
2. Modulo 10, powers of 7 cycle through 1, 7, 9, 3 with period 4.
3. Because 7^4 = 2401 ≡ 1 (mod 100), the period modulo 100 is still 4, so the second digit is fixed without branching.
4. When moving from 10^m to 10^(m+1), the cycle length multiplies by the order of `stepFactor = 7^period mod 10^(m+1)` (1, 5, or 10).
5. Testing each shift `e + shift * period` around that sub-cycle finds the unique lifted exponent when one exists.

The main terms used in the program:

| term | meaning |
|---|---|
| `modulus` | current power of ten, 10^m |
| `exponent` | smallest non-negative solution e modulo `modulus` |
| `period` | multiplicative order of 7 modulo `modulus` |
| `stepFactor` | 7^period mod `modulus`, used to step across candidates |
| `targetValue` | numeric value of the K-digit query |

Each lifted exponent stays unique inside one period, so `exponent + 1` is always the earliest day.

Worked trace for the query `743`:

```
digit | modulus | period | exponent | 7^exponent mod modulus
1     | 10      | 4      | 3        | 3
2     | 100     | 4      | 3        | 43
3     | 1000    | 20     | 11       | 743 (shift 2: 3 + 2 * 4)
earliest day = 11 + 1 = 12
```

The trace recovers day 12 for `743` in three lifting steps.

## Code

**Bulk input and buffered output.** The scanner preserves leading zeros by reading raw tokens, and output flushes in 128 KiB blocks.

```nim
const flushBlockBytes = 1 shl 17
const digitBase = 10
const growthFactor = 7'i64
const maxDigitCount = 9

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

One read loop loads stdin into `inputData`.
`nextToken` keeps every digit character, including leading zeros.
`appendOutput` flushes once `outputBuffer` reaches 128 KiB.

**Modular exponentiation and digit lifting.** `powerMod` computes 7^e mod 10^m in 64-bit integers, and `findEarliestDay` lifts the exponent from 1 digit to K digits.

```nim
proc powerMod(baseValue, exponentValue, modulus: int64): int64 =
  var answer: int64 = 1 mod modulus
  var factor = baseValue mod modulus
  var remaining = exponentValue
  while remaining > 0:
    if (remaining and 1) == 1:
      answer = (answer * factor) mod modulus
    factor = (factor * factor) mod modulus
    remaining = remaining shr 1
  return answer

proc findEarliestDay(targetValue: int64, digitCount: int): int64 =
  var modulus: int64 = 10
  var exponent: int64 = -1
  var currentPower: int64 = 1
  for step in 0 .. 3:
    if currentPower == targetValue mod modulus:
      exponent = int64(step)
      break
    currentPower = (currentPower * growthFactor) mod modulus
  if exponent < 0:
    return -1
  var period: int64 = 4
  for digitIndex in 2 .. digitCount:
    modulus = modulus * digitBase
    let wanted = targetValue mod modulus
    let stepFactor = powerMod(growthFactor, period, modulus)
    var candidatePower = powerMod(growthFactor, exponent, modulus)
    var found = false
    var shift: int64 = 0
    var factorPower: int64 = 1
    while true:
      if candidatePower == wanted:
        exponent += shift * period
        found = true
        break
      shift += 1
      factorPower = (factorPower * stepFactor) mod modulus
      if factorPower == 1:
        break
      candidatePower = (candidatePower * stepFactor) mod modulus
    if not found:
      return -1
    var orderFactor: int64 = 1
    var checkPower = stepFactor
    while checkPower != 1:
      checkPower = (checkPower * stepFactor) mod modulus
      orderFactor += 1
    period = period * orderFactor
  return exponent + 1
```

Because `modulus` is at most 10^9, every product fits inside signed 64-bit integers without overflow.
`factorPower` stops the shift scan once `stepFactor` cycles back to 1, handling orders 1, 5, and 10 uniformly.
`orderFactor` then scales `period` to the exact multiplicative order modulo `modulus`.

**Query loop.** Each token supplies both its digit count and numeric value.

```nim
while true:
  let queryToken = nextToken(inputData, scanPos)
  if queryToken.len == 0:
    break
  if queryToken.len < 1 or queryToken.len > maxDigitCount:
    continue
  var targetValue: int64 = 0
  for charIndex in 0 .. queryToken.len - 1:
    targetValue = targetValue * digitBase + int64(int(queryToken[charIndex]) - 48)
  let answerDay = findEarliestDay(targetValue, queryToken.len)
  appendOutput($answerDay)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

`queryToken.len` gives K directly, preserving leading zeros.
Digit values use `int(c) - 48` for Nim 0.19.4 compatibility.
The final write flushes any remaining buffered output.

## Complexity

Each query lifts at most 9 digits with no precomputed tables.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| digit lifting | at most 9 steps, O(K^2) multiplications per query | O(1) |
| output write | one line per query | one 128 KiB buffer |

Memory stays constant regardless of K.

| measure | Big O |
|---|---|
| time per query | O(K^2) |
| space | O(1) auxiliary |

Enumerating the full cycle modulo 10^K would cost O(5^K) time and space, whereas digit lifting finishes every query in microseconds.
