# FUCT_FOR_REFRAC — Reduced fraction (SPOJ)

<https://www.spoj.com/problems/FUCT_FOR_REFRAC/>

## Problem

Each test gives a numerator and a denominator. Print the fraction in lowest terms as `numerator denominator`, with the sign carried by the numerator. If the denominator is zero, print `the denominator can not be zero` instead. When the reduced denominator is 1, print only the numerator.

Input starts with a test count t. Output holds one line per test.

| Item | Bound |
|---|---|
| Test count | 0 < t ≤ 1000 |
| Values | fit in signed 64-bit |
| Judge limit | 1000 ms, 1536 MB |

The sample case:

```
8
-8 16
1 9
8 10
-3 0
150 200
-9 -12
27 9
45 -50
```

```
-1 2
1 9
4 5
the denominator can not be zero
3 4
3 4
3
-9 10
```

## Idea

Divide both numbers by their greatest common divisor. Euclid's algorithm does that in a few remainders, using absolute values so the sign never gets in the way. Afterwards, if the denominator ended up negative, flip both signs so the minus stays on top.

## Why It Works

1. Dividing both parts by a common divisor does not change the value.
2. Dividing by the greatest common divisor leaves no common factor, so the fraction is reduced.
3. Euclid's algorithm returns the gcd of the absolute values, which works for negative input.
4. Flipping both signs keeps the value and puts the minus on the numerator.
5. A denominator of 1 means the value is a whole number, so only the top is printed.

| Term | Meaning |
|---|---|
| `nextSignedInt64` | reads one integer, sign included |
| `gcdPositive` | Euclid's algorithm on absolute values |
| `divisorValue` | the gcd used to shrink the pair |
| `reducedNumerator` | numerator after dividing |
| `reducedDenominator` | denominator after dividing |

A script-traced example from `gen.py`:

```
pair -8 16
gcd of absolute values 8
reduced -1 2, sign kept on top
```

That matches the sample's first line.

## Code

**Bulk input and signed scanner.** This block loads all of stdin once and reads 64-bit integers by index.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextSignedInt64(data: string, position: var int, found: var bool): int64 =
  while position < data.len and data[position] != '-' and (data[position] < '0' or data[position] > '9'):
    position += 1
  if position >= data.len:
    found = false
    return 0
  var signValue = 1
  if data[position] == '-':
    signValue = -1
    position += 1
  var value: int64 = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int64(ord(data[position]) - firstDigitValue)
    position += 1
  found = true
  if signValue < 0:
    return -value
  return value
```

One pass over the bytes reads every number.
The sign is taken first, then the digits, so `-3` and `3` both parse.
`int64` holds values up to 2^63-1 without overflow.

**Euclid's algorithm.** This block finds the greatest common divisor.

```nim
proc absoluteValue(value: int64): int64 =
  if value < 0:
    return -value
  return value

proc gcdPositive(firstValue, secondValue: int64): int64 =
  var currentValue = absoluteValue(firstValue)
  var nextValue = absoluteValue(secondValue)
  while nextValue != 0:
    let remainderValue = currentValue mod nextValue
    currentValue = nextValue
    nextValue = remainderValue
  return currentValue
```

Both inputs are made non-negative first, so the result is always positive.
A zero numerator gives the other number, which still reduces correctly.
`mod` is used because judge 0.19.4 has no `%`.

**Reduce and print.** This block handles one pair per test.

```nim
var tokenFound = false
let caseCount = nextSignedInt64(inputData, scanPos, tokenFound)
for caseIndex in 0 ..< caseCount:
  let numeratorValue = nextSignedInt64(inputData, scanPos, tokenFound)
  let denominatorValue = nextSignedInt64(inputData, scanPos, tokenFound)
  if denominatorValue == 0:
    appendOutput("the denominator can not be zero\n")
  else:
    let divisorValue = gcdPositive(numeratorValue, denominatorValue)
    var reducedNumerator = numeratorValue div divisorValue
    var reducedDenominator = denominatorValue div divisorValue
    if reducedDenominator < 0:
      reducedNumerator = -reducedNumerator
      reducedDenominator = -reducedDenominator
    if reducedDenominator == 1:
      appendOutput($reducedNumerator & "\n")
    else:
      appendOutput($reducedNumerator & " " & $reducedDenominator & "\n")
```

The zero check runs before any division, so no divide-by-zero happens.
`appendOutput` fills a 128 KiB buffer and flushes when full.
The last `stdout.write` emits the final partial block.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Reduce | O(log min(a,b)) remainders per case | a few integers |
| Output | one write per 128 KiB block | block buffer |

| Measure | Big O |
|---|---|
| Time | O(t log V), V is the largest value |
| Space | O(input size + block buffer) |

Trying every divisor down from the smaller value costs O(V) per case; Euclid needs about 90 remainders at worst for 64-bit numbers.
