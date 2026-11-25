# AFSK — Power Factor Sum Sum (hard) (SPOJ)
<https://www.spoj.com/problems/AFSK/>

## Problem

For each query (n, k, m), print the sum over j from one to n of the kth powers of all divisors of j, reduced modulo m. This equals the running power-divisor sequence aₖ[n], because aₖ[1] is one.

Input starts with t, followed by t lines each holding n, k and m. Print one reduced integer per line.

| item | bound |
|---|---|
| test cases t | 1 to 100 |
| index n | 1 to 999999999 |
| power k | 1 to 10 |
| modulus m | 2 to 99999999999999999 |
| judge limit | 15000 ms, 1536 MB |

Sample input:

```
3
3 1 10
4 2 55
5 3 97
```

Sample output:

```
8
37
43
```

## Idea

Each divisor contributes to many later multiples, like one coin counted in every stack it supports. Rewrite the answer as the sum over d of dᵏ times floor(n/d). Divisors with the same quotient form one range, so a sweep takes about 2√n steps. A scaled Faulhaber polynomial gives the sum of kth powers inside each range with a short Horner evaluation. The takeaway is to combine quotient grouping with an exact power-sum formula.

## Why It Works

1. The sequence adds the kth powers of the divisors of each j from two through n, starting from aₖ[1] = 1.
2. A divisor d appears once for each multiple of d up to n, giving dᵏ × floor(n/d).
3. Equal quotients define a range [l, r] whose contribution is q times the difference of two power sums.
4. Scaling the power-sum polynomial by 27720 clears every denominator for powers up to ten.
5. Evaluating that polynomial modulo 27720 × m and dividing by 27720 recovers the sum modulo m exactly.

| term | meaning |
|---|---|
| `queryValue` | the queried index n |
| `powerValue` | the exponent k |
| `modulusValue` | the modulus m |
| `previousPowerSum` | power sum at the previous range edge |
| `rangeSum` | power sum difference for one range |
| `answerValue` | accumulated answer modulo `modulusValue` |

A script generated these chunk values for n equal three and k equal one:

| divisor range | quotient | power sum difference | contribution |
|---|---|---|---|
| 1 to 1 | 3 | 1 | 3 |
| 2 to 3 | 1 | 5 | 5 |
| total | | | 8 |

The total of eight agrees with the first sample answer.

## Code

**Scaled power sums.** The embedded helper evaluates a degree k+1 polynomial under the enlarged modulus.

```nim
const flushBlockBytes = 1 shl 17

{.emit: """
typedef __int128 wide_value;
static const long long powerCoefficients[11][11] = {
  {0,0,0,0,0,0,0,0,0,0,0},
  {13860,13860,0,0,0,0,0,0,0,0,0},
  {4620,13860,9240,0,0,0,0,0,0,0,0},
  {0,6930,13860,6930,0,0,0,0,0,0,0},
  {-924,0,9240,13860,5544,0,0,0,0,0,0},
  {0,-2310,0,11550,13860,4620,0,0,0,0,0},
  {660,0,-4620,0,13860,13860,3960,0,0,0,0},
  {0,2310,0,-8085,0,16170,13860,3465,0,0,0},
  {-924,0,6160,0,-12936,0,18480,13860,3080,0,0},
  {0,-4158,0,13860,0,-19404,0,20790,13860,2772,0},
  {2100,0,-13860,0,27720,0,-27720,0,23100,13860,2520}
};
static NU64 wide_power_sum(NU64 limitValue, unsigned int powerValue, NU64 modulusValue) {
  wide_value reducedModulus = (wide_value)modulusValue * 27720;
  wide_value accumulated = 0;
  int degree = (int)powerValue + 1;
  int idx = degree;
  while (idx >= 1) {
    accumulated = (accumulated * (wide_value)limitValue + (wide_value)powerCoefficients[powerValue][idx - 1]) % reducedModulus;
    idx -= 1;
  }
  accumulated = (accumulated * (wide_value)limitValue) % reducedModulus;
  return (NU64)(accumulated / 27720);
}
static NU64 wide_multiply_mod(NU64 firstValue, NU64 secondValue, NU64 modulusValue) {
  return (NU64)((__int128)firstValue * secondValue % modulusValue);
}
""".}

proc powerSumModulo(limitValue: uint64, powerValue: cuint, modulusValue: uint64): uint64 {.importc: "wide_power_sum", cdecl.}
proc multiplyModulo(firstValue: uint64, secondValue: uint64, modulusValue: uint64): uint64 {.importc: "wide_multiply_mod", cdecl.}
```

The coefficient rows are integers after scaling.
The Horner loop performs one reduction per degree.
The second helper multiplies two reduced values without overflow.

**Input and buffering.** The scanner loads all tokens, and the writer batches answer lines.

```nim
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
```

The scanner ignores spacing and line breaks.
One buffer collects every answer line.
A large block triggers a single write.

**Quotient sweep.** The driver walks ranges and reuses the previous range edge.

```nim
let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let queryValue = uint64(nextInt(inputData, scanPos))
  let powerValue = cuint(nextInt(inputData, scanPos))
  let modulusValue = uint64(nextInt(inputData, scanPos))
  var answerValue: uint64 = 0
  var previousPowerSum: uint64 = 0
  var leftValue: uint64 = 1
  while leftValue <= queryValue:
    let quotientValue = queryValue div leftValue
    let rightValue = queryValue div quotientValue
    let currentPowerSum = powerSumModulo(rightValue, powerValue, modulusValue)
    let rangeSum = (currentPowerSum - previousPowerSum + modulusValue) mod modulusValue
    let chunkProduct = multiplyModulo(rangeSum, quotientValue mod modulusValue, modulusValue)
    answerValue = (answerValue + chunkProduct) mod modulusValue
    previousPowerSum = currentPowerSum
    leftValue = rightValue + 1
  appendOutput($answerValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each range edge is evaluated once.
The subtraction wraps with the modulus before multiplication.
One flush writes all buffered answers.

## Complexity

The sweep covers one range per distinct quotient.

| phase | time | space |
|---|---|---|
| input read | one pass over all query triples | one input string |
| power sums | about 2√n ranges, k+1 steps each | constant |
| output | one buffered line per query | block buffer |

The bounds count work for one query.

| measure | Big O |
|---|---|
| time per query | O(k√n) |
| space | O(1) |

Summing divisors one by one would take O(n) steps per query.
The takeaway is that grouping quotients and evaluating a polynomial remove that scan.
