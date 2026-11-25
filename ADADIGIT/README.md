# ADADIGIT — Ada and Digits 2 (SPOJ)

<https://www.spoj.com/problems/ADADIGIT/>

## Problem

Rearrange a list of digits into a number that maximizes its divisor count, and into another number that maximizes its divisor sum. Use every digit once. When several arrangements tie, choose the smallest resulting number. Drop leading zeroes from the printed value.

The input has one case. The first line gives the digit count `N`. The next line gives `N` digits from zero to nine. Print two integers separated by a space: the divisor-count winner first and the divisor-sum winner second.

| Item | Bound |
|---|---|
| Digits N | 1 to 9 |
| Each digit | 0 to 9 |
| Judge limit | 3000 ms, 1536 MB |

An arrangement with leading zeroes becomes the smaller integer those digits spell.

The first sample case is:

```
1
5
```

The expected output is:

```
5 5
```

## Idea

Try every ordering of the digits, like rearranging a handful of numbered tiles and scoring each row. Use the next-permutation routine to walk the orderings in sorted order. Score each assembled number by factoring it with primes up to its square root. Track the smallest value at every tie.

## Why It Works

1. Sorting the digits first and applying next-permutation visits every ordering once.
2. Leading zeroes add nothing, so each ordering maps directly to one integer value.
3. When a number factors into primes with exponents e, the divisor count is the product of e + 1.
4. The divisor sum multiplies the geometric sum of powers for each prime exponent.
5. Scanning primes in increasing order, then testing divisibility, produces those exponents.
6. Comparing value on a tie keeps the smaller arrangement for both winners.

| Term | Meaning |
|---|---|
| `primes` | sieve list of primes up to the square-root limit |
| `divisorData` | divisor count and divisor sum of one assembled value |
| `nextPermutation` | advances the digit list to its next sorted ordering |
| `bestCountNumber` | smallest value seen with the largest divisor count |
| `bestSumNumber` | smallest value seen with the largest divisor sum |

The factorization uses only primes up to 31623, which covers all nine-digit values.

A short trace with the sample digits `1 2 3 4 5`:

```
43512 = 2^3 * 3 * 7^2 * 37 -> 48 divisors, divisor sum 129960
51324 = 2^2 * 3 * 7 * 13 * 47 -> 48 divisors, divisor sum 150528
divisor-count tie: 43512 is smaller, so it wins that slot
divisor-sum winner: 150528 exceeds 129960, so 51324 wins that slot
```

The trace reproduces the statement output for that sample.

## Code

**Input and scanning.** The hand reader loads one digit list per case.

```nim
const flushBlockBytes = 1 shl 17
const largestFactorBase = 31623

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

proc hasNextNumber(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len and (data[cursor] < '0' or data[cursor] > '9'):
    cursor += 1
  return cursor < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The sentinel loop also accepts several cases in one file.
One output buffer handles all answer lines.
Token parsing ignores how digits are wrapped across lines.

**Prime sieve and scoring.** A small sieve supports fast factorization of every candidate.

```nim
var isComposite = newSeq[bool](largestFactorBase + 1)
var primes = newSeq[int]()
for candidate in 2 .. largestFactorBase:
  if not isComposite[candidate]:
    primes.add candidate
    let stride = candidate * candidate
    if stride <= largestFactorBase:
      var multiple = stride
      while multiple <= largestFactorBase:
        isComposite[multiple] = true
        multiple = multiple + candidate

proc divisorData(value: int): tuple[count: int64, sum: int64] =
  if value == 0:
    return (0.int64, 0.int64)
  var remaining = value
  var count: int64 = 1
  var divisorSum: int64 = 1
  for prime in primes:
    if prime * prime > remaining:
      break
    if remaining mod prime == 0:
      var exponent = 0
      var power = 1
      while remaining mod prime == 0:
        remaining = remaining div prime
        exponent += 1
        power = power * prime
      count = count * (exponent + 1)
      divisorSum = divisorSum * (power * prime - 1) div (prime - 1)
  if remaining > 1:
    count = count * 2
    divisorSum = divisorSum * (remaining + 1)
  return (count, divisorSum)
```

The sieve marks composites from each prime square.
A leftover above one is a final prime factor.
Both results use 64-bit arithmetic for large divisor sums.

**Permutation walk.** The next ordering is built in place from the current one.

```nim
proc nextPermutation(digits: var seq[int]): bool =
  let digitCount = digits.len
  var pivot = digitCount - 2
  while pivot >= 0 and digits[pivot] >= digits[pivot + 1]:
    pivot -= 1
  if pivot < 0:
    return false
  var successor = digitCount - 1
  while digits[successor] <= digits[pivot]:
    successor -= 1
  swap digits[pivot], digits[successor]
  var leftIndex = pivot + 1
  var rightIndex = digitCount - 1
  while leftIndex < rightIndex:
    swap digits[leftIndex], digits[rightIndex]
    leftIndex += 1
    rightIndex -= 1
  return true
```

The pivot is the first digit smaller than its right neighbour.
The suffix is reversed into its lowest order.
Equal digits produce repeated values, which only cost extra comparisons.

**Winner selection.** Each candidate updates one or both winners, then the next ordering begins.

```nim
while hasNextNumber(inputData, scanPos):
  let digitCount = nextInt(inputData, scanPos)
  var digits = newSeq[int](digitCount)
  for digitIndex in 0 .. digitCount - 1:
    digits[digitIndex] = nextInt(inputData, scanPos)
  for firstIndex in 1 .. digitCount - 1:
    let held = digits[firstIndex]
    var previousIndex = firstIndex - 1
    while previousIndex >= 0 and digits[previousIndex] > held:
      digits[previousIndex + 1] = digits[previousIndex]
      previousIndex -= 1
    digits[previousIndex + 1] = held
  var bestCount: int64 = -1
  var bestSum: int64 = -1
  var bestCountNumber = 0
  var bestSumNumber = 0
  while true:
    var assembled = 0
    for digit in digits:
      assembled = assembled * 10 + digit
    let data = divisorData(assembled)
    if data.count > bestCount or (data.count == bestCount and assembled < bestCountNumber):
      bestCount = data.count
      bestCountNumber = assembled
    if data.sum > bestSum or (data.sum == bestSum and assembled < bestSumNumber):
      bestSum = data.sum
      bestSumNumber = assembled
    if not nextPermutation(digits):
      break
  appendOutput($bestCountNumber & " " & $bestSumNumber)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Insertion sort sets up the first ordering.
Each candidate updates a winner only on a better score or a smaller tie.
The final flush writes both winner values.

## Complexity

At most nine digits give at most 9! orderings, and scoring one value is short.

| Phase | Time | Space |
|---|---|---|
| Sieve | one pass up to 31623 | composite flags and prime list |
| Permutation walk | up to 9! orderings | one digit list |
| Scoring | primes up to the square root per value | one small result pair |
| Output | one line per case | block buffer |

Prime divisibility ends early for most candidates.

| Measure | Big O |
|---|---|
| Time | O(B + D! × π(√M)) |
| Space | O(B + D) |

`B` is 31623, `D` is at most nine, and `M` is the largest assembled value.
Testing every divisor up to the square root would multiply the scoring work by about a thousand.
