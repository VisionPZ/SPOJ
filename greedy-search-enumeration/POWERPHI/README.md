# POWERPHI — Power of Phi(medium) (SPOJ)
<https://www.spoj.com/problems/POWERPHI/>

## Problem

Print the integer closest to the golden-ratio power φⁿ, reduced modulo 1000000007. The exponent can be as large as one billion, so the power itself is never written out.

Input starts with t, followed by t lines each holding one integer n. Print one reduced answer per line.

| item | bound |
|---|---|
| test cases t | up to 100000 |
| exponent n | 0 to 1000000000 |
| modulus | 1000000007 |
| judge limit | 1000 ms, 1536 MB |

Sample input:

```
2
1
3
```

Sample output:

```
2
4
```

## Idea

A conjugate root cancels the irrational part, like pairing a wobbly scale reading with its mirror to hit a whole number. Let ψ be (1 − √5)/2, the other root of x² = x + 1. The Lucas number Lₙ equals φⁿ + ψⁿ, and |ψⁿ| stays below one half once n reaches two. Fast doubling finds Fibonacci numbers in O(log n) steps, and Lₙ equals 2Fₙ₊₁ − Fₙ. The takeaway is to replace a floating power with an exact integer pair.

## Why It Works

1. Both φ and ψ satisfy x² = x + 1, so their nth powers add to an integer Lucas number.
2. The conjugate ψ equals −1/φ and has absolute value below one half.
3. For n ≥ 2, φⁿ lies within one half of Lₙ, so the closest integer is Lₙ.
4. The identities 2Fₙ₊₁ − Fₙ = Lₙ and fast doubling give that integer in logarithmic time.

| term | meaning |
|---|---|
| `fibonacciPair` | returns Fₙ and Fₙ₊₁ modulo `answerModulus` |
| `halfExponent` | exponent floor-divided by two |
| `termSuccessor` | the Fibonacci successor Fₙ₊₁ |
| `answerValue` | the reduced closest integer |

A script computed these rows with a separate matrix power:

| n | Fₙ | Fₙ₊₁ | 2Fₙ₊₁ − Fₙ |
|---|---|---|---|
| 3 | 2 | 3 | 4 |
| 10 | 55 | 89 | 123 |
| 50 | 12586269025 | 20365011074 | 28143753123 |

The row for ten matches φ¹⁰ ≈ 122.99.

## Code

**Fast doubling.** The helper returns a Fibonacci pair for any exponent.

```nim
const flushBlockBytes = 1 shl 17
const answerModulus: int64 = 1000000007'i64

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

proc fibonacciPair(exponentValue: int64): (int64, int64) =
  if exponentValue == 0:
    return (0'i64, 1'i64)
  let halfExponent = exponentValue div 2
  let (halfFibonacci, halfSuccessor) = fibonacciPair(halfExponent)
  let doubledSuccessor = (2'i64 * halfSuccessor) mod answerModulus
  let difference = (doubledSuccessor - halfFibonacci + answerModulus) mod answerModulus
  let evenFibonacci = (halfFibonacci * difference) mod answerModulus
  let evenSuccessor = (halfFibonacci * halfFibonacci + halfSuccessor * halfSuccessor) mod answerModulus
  if (exponentValue and 1'i64) == 0'i64:
    return (evenFibonacci, evenSuccessor)
  return (evenSuccessor, (evenFibonacci + evenSuccessor) mod answerModulus)
```

One recursive level handles two exponent bits.
Every product stays below one quintillion.
The odd branch shifts the pair forward by one term.

**Answer and output.** The driver treats exponents zero and one as special cases.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let exponentValue = int64(nextInt(inputData, scanPos))
  var answerValue: int64
  if exponentValue == 0:
    answerValue = 1'i64
  elif exponentValue == 1:
    answerValue = 2'i64
  else:
    let (termFibonacci, termSuccessor) = fibonacciPair(exponentValue)
    answerValue = (2'i64 * termSuccessor - termFibonacci) mod answerModulus
    if answerValue < 0:
      answerValue += answerModulus
  appendOutput($answerValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The two small exponents break the conjugate bound.
The subtraction uses the modulus to avoid a negative value.
Buffered writes handle many test cases at once.

## Complexity

The table counts work for one exponent.

| phase | time | space |
|---|---|---|
| input read | one pass over all exponents | one input string |
| fast doubling | one level per exponent bit | recursion of logarithmic depth |
| output | one buffered line | block buffer |

The bound measures one test case.

| measure | Big O |
|---|---|
| time per test | O(log n) |
| space | O(log n) |

A linear Fibonacci loop would take O(n) steps per test.
The takeaway is that doubling turns a huge exponent into a short recursion.
