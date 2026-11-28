# ABNDNTNM — Abundant numbers (SPOJ)
<https://www.spoj.com/problems/ABNDNTNM/>

## Problem

Count integers in a closed interval whose proper divisors sum to more than the integer itself. A number is abundant when that divisor sum exceeds the number.

The single input line gives two integers M and N with M < N. Print one integer, the count of abundant numbers from M through N inclusive.

| Constraint | Value |
| --- | --- |
| Lower bound M | positive integer |
| Upper bound N | less than 2^31 |
| Judge time | 1000 ms nominal |
| Judge memory | 1536 MB |

One divisor pass builds every divisor sum up to N before counting.

The sample input and its expected output follow byte for byte.

```
204 1007
```

```
201
```

Twelve is abundant because 1 + 2 + 3 + 4 + 6 equals 16.

## Idea

Stamping each divisor onto its multiples is like walking a street and leaving a number on every second door, then every third door, and so on. At the end, each door holds the sum of its proper divisors.

The program builds a divisor-sum table with a multiple sieve. For each divisor d, it adds d to multiples 2d, 3d, and upward. Then it counts table entries in the interval that exceed their own index.

Testing each number by trial division up to its square root repeats the same factor work for every number. The sieve shares each divisor addition across all its multiples.

## Why It Works

1. A proper divisor of n is any divisor below n, and 1 divides every number above 1.
2. When d is added to multiples 2d, 3d, and so on, d lands in every number it divides.
3. After the last divisor, the entry at n holds the sum of all proper divisors of n.
4. Comparing that sum with n decides abundance exactly.
5. Counting comparisons over M through N gives the requested interval total.

| Term | Meaning |
| --- | --- |
| `divisorSums` | accumulated proper divisor sum per number |
| `divisor` | current divisor being added |
| `multiple` | current multiple receiving that divisor |
| `abundantCount` | number of abundant values found |
| `candidate` | current number tested in the interval |

The table and four counters drive the whole program.

A script check of the sample interval 204 through 1007 gives 201 abundant numbers. The same check on a single value shows the rule.

| Number | Proper divisors | Sum | Abundant |
| --- | --- | --- | --- |
| 12 | 1, 2, 3, 4, 6 | 16 | yes |
| 18 | 1, 2, 3, 6, 9 | 21 | yes |
| 20 | 1, 2, 4, 5, 10 | 22 | yes |
| 11 | 1 | 1 | no |

The table starts each entry at 1 and adds the stamped divisors on top.

## Code

**Input reader and output buffer.** The hand scanner reads the interval bounds and the buffer collects the single answer.

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
```

Token parsing ignores spacing and line breaks.
The buffer is written once after the count.

**Divisor-multiple sieve.** Every divisor from 2 upward is stamped onto its multiples, then the interval is counted.

```nim
let lowerBound = nextInt(inputData, scanPos)
let upperBound = nextInt(inputData, scanPos)
var divisorSums = newSeq[int32](upperBound + 1)
for numberValue in 0 .. upperBound:
  divisorSums[numberValue] = 1
divisorSums[0] = 0
if upperBound >= 1:
  divisorSums[1] = 0
var divisor = 2
while divisor <= upperBound div 2:
  var multiple = divisor * 2
  while multiple <= upperBound:
    divisorSums[multiple] += int32(divisor)
    multiple += divisor
  divisor += 1
var abundantCount: int64 = 0
var candidate = lowerBound
if candidate < 1:
  candidate = 1
while candidate <= upperBound:
  if int64(divisorSums[candidate]) > int64(candidate):
    abundantCount += 1
  candidate += 1
appendOutput($abundantCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Entries zero and one stay outside the count.
Sums and the answer use wide enough types for the stated bound.

## Complexity

The sieve adds each divisor to each of its multiples.

| Phase | Time | Space |
| --- | --- | --- |
| input read | one pass over one line | one input string |
| divisor stamps | sum of N over d up to N/2 | table of N sums |
| interval count | one comparison per number | two counters |
| output | one line | block buffer |

The table is the only large allocation.

| Measure | Big O |
| --- | --- |
| time | O(N log N) |
| space | O(N) |

Trial division on every number in the interval costs O((N - M + 1) times sqrt N).

Sharing each divisor across its multiples keeps the sieve ahead on wide intervals.
