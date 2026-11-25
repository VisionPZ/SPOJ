# IAPCR2D — Find The Number (SPOJ)
<https://www.spoj.com/problems/IAPCR2D/>

## Problem

Given the number of divisors of some factorial `X!`, find the smallest `X` that produces that count. If no such `X` exists, print `nai`.

Input starts with `T`. Each of the next `T` lines holds one integer `N`, the divisor count. Output `X` or `nai` on one line per case. The statement guarantees `X < 110`; the output rule rejects any `X` above 10000.

| item | bound |
|---|---|
| cases T | 1 to 100000 |
| query N | 0 to 1000000000000000000 |
| guaranteed X | below 110 |
| accepted X | 1 to 10000 |
| judge limit | 300 ms, 1536 MB |

The large case count drives the design, so each query must be answered by a table lookup.

Sample input:

```
5
1
2
3
4
5
```

Sample output:

```
1
2
nai
3
nai
```

## Idea

The divisor count of `X!` is a product of small factors, one for each prime exponent. Think of it as a sorted phone book: build the book once, then look up each query quickly.

The program precomputes the divisor count for every `X` up to 10000 as a decimal string. Counts grow strictly with `X`, so binary search finds the matching entry. Each query costs O(log 10000) string comparisons.

Recomputing factorials for every query would cost far more. The table is shared by all cases.

Takeaway: precompute once and search a sorted answer table.

## Why It Works

1. If `X! = product(p^e)`, then the divisor count is `product(e + 1)`.
2. Moving from `(X−1)!` to `X!` adds the prime exponents of `X`.
3. For a prime p, the exponent changes from `old` to `new`, so the divisor count changes by a factor `(new + 1) / (old + 1)`.
4. That ratio is an exact integer division, because the old factor is still present.
5. Divisor counts grow strictly with `X`, since each step multiplies the count by a value above 1.
6. Binary search over the sorted table returns the smallest matching `X`, or no match at all.

| term | meaning |
|---|---|
| `smallestFactor` | smallest prime factor of each value |
| `primeExponents` | exponent of each prime in the current factorial |
| `currentProduct` | divisor count as a decimal string |
| `divisorCounts` | precomputed count for each factorial |
| `compareDecimal` | length-first comparison of two decimal strings |

The sample builds these counts.

```
X = 1: 1! = 1,     divisors = 1
X = 2: 2! = 2,     divisors = 2
X = 3: 3! = 6,     divisors = 4
X = 4: 4! = 24,    divisors = 8
X = 5: 5! = 120,   divisors = 16
query 3 is absent -> nai, query 4 -> X = 3
```

Decimal strings avoid overflow, since divisor counts eventually exceed 64-bit range.

## Code

**Input and token scanner.** One read pass loads the stream; two scanners cover integers and large query strings.

```nim
const flushBlockBytes = 1 shl 17
const maxNumber = 10000

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

proc nextNumber(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  let startPos = pos
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    pos += 1
  var firstDigit = startPos
  while firstDigit < pos - 1 and data[firstDigit] == '0':
    firstDigit += 1
  return data[firstDigit .. pos - 1]
```

Queries stay as strings, so values beyond 64 bits are safe. Leading zeros are stripped. The case count fits in an integer and uses `nextInt`.

**Decimal arithmetic.** Multiply and divide a decimal string by a small integer.

```nim
proc multiplyDecimal(value: string, factor: int): string =
  var carry = 0
  var digits = newSeq[int](value.len)
  for index in 0 .. value.len - 1:
    let digitPos = value.len - 1 - index
    let product = (int(value[digitPos]) - 48) * factor + carry
    digits[index] = product mod 10
    carry = product div 10
  var carryDigits = ""
  while carry > 0:
    carryDigits.add char(48 + carry mod 10)
    carry = carry div 10
  var decimalResult = ""
  for index in 0 .. carryDigits.len - 1:
    decimalResult.add char(carryDigits[carryDigits.len - 1 - index])
  for index in 0 .. value.len - 1:
    decimalResult.add char(48 + digits[value.len - 1 - index])
  return decimalResult

proc divideDecimal(value: string, divisor: int): string =
  var remainder = 0
  var decimalResult = ""
  for digitChar in value:
    let current = remainder * 10 + int(digitChar) - 48
    decimalResult.add char(48 + current div divisor)
    remainder = current mod divisor
  var firstDigit = 0
  while firstDigit < decimalResult.len - 1 and decimalResult[firstDigit] == '0':
    firstDigit += 1
  return decimalResult[firstDigit .. decimalResult.len - 1]

proc compareDecimal(left: string, right: string): int =
  if left.len < right.len:
    return -1
  if left.len > right.len:
    return 1
  for index in 0 .. left.len - 1:
    if left[index] < right[index]:
      return -1
    if left[index] > right[index]:
      return 1
  return 0
```

Carry digits are emitted in reverse so the most significant digit comes first. Long division keeps an exact remainder. Comparison checks length before digits.

**Output helper.** Answers are buffered in one string.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes by byte count, not by line. One final write emits the remaining text. A hundred thousand answers still produce few writes.

**Table construction.** Prime exponents of each factorial update one product.

```nim
var smallestFactor = newSeq[int](maxNumber + 1)
for prime in 2 .. maxNumber:
  if smallestFactor[prime] == 0:
    var multiple = prime
    while multiple <= maxNumber:
      if smallestFactor[multiple] == 0:
        smallestFactor[multiple] = prime
      multiple += prime

var primeExponents = newSeq[int](maxNumber + 1)
var divisorCounts = newSeq[string](maxNumber + 1)
divisorCounts[0] = "1"
var currentProduct = "1"
for factorialIndex in 1 .. maxNumber:
  var remaining = factorialIndex
  while remaining > 1:
    let prime = smallestFactor[remaining]
    var added = 0
    while remaining mod prime == 0:
      added += 1
      remaining = remaining div prime
    let oldExponent = primeExponents[prime]
    let newExponent = oldExponent + added
    currentProduct = multiplyDecimal(currentProduct, newExponent + 1)
    if oldExponent > 0:
      currentProduct = divideDecimal(currentProduct, oldExponent + 1)
    primeExponents[prime] = newExponent
  divisorCounts[factorialIndex] = currentProduct
```

The sieve gives a prime factor in O(1) per division step. Each new exponent updates the product with one multiply and one divide. The table grows strictly, which the search relies on.

**Query loop.** Binary search maps each count to its factorial.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let query = nextNumber(inputData, scanPos)
  var low = 1
  var high = maxNumber
  while low < high:
    let middle = (low + high) div 2
    if compareDecimal(divisorCounts[middle], query) < 0:
      low = middle + 1
    else:
      high = middle
  if compareDecimal(divisorCounts[low], query) == 0:
    appendOutput($(low))
  else:
    appendOutput("nai")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The first matching index is the smallest valid `X`. A missing match prints `nai`, which also covers `N = 0`. Query cost is logarithmic in the table size.

## Complexity

Precomputation dominates startup; each query is a short binary search.

| phase | time | space |
|---|---|---|
| smallest-factor sieve | O(maxNumber log log maxNumber) | one integer per value |
| divisor table | O(maxNumber · digits · factors) | decimal strings |
| per query | O(log maxNumber · digits) | none extra |
| output | one line per case | block buffer |

The divisor table is the largest phase, but it runs once for all cases.

| measure | Big O |
|---|---|
| preprocessing | O(maxNumber · digits · log maxNumber) |
| all queries | O(T · log maxNumber · digits) |
| working space | O(maxNumber · digits) |

Recomputing prime exponents for each query would multiply that work by the case count. Table reuse removes it.

Takeaway: a sorted precomputed table turns many hard queries into cheap lookups.
