# IDC1948 — Identity crisis (SPOJ)
<https://www.spoj.com/problems/IDC1948/>

## Problem

For each number n, measure the distance x(n) to the first larger number made only of digit 9. Report the smallest modulus p above one for which x(n) and n share a remainder, or -1 when none exists.

The first line holds T, the number of test cases. Each following line holds one integer n.
Print one answer per case on its own line.

The bounds are:

| item | bound |
|---|---|
| test cases T | 1 to 19 |
| value n | 1 to 29999999 |
| judge limit | 1000 ms, 1536 MB |

The small case count keeps divisor checking affordable.

Sample input:

```
2
234
5
```

Two numbers make two test cases.

Sample output:

```
3
-1
```

The second case has no valid modulus.

## Idea

Think of the gap to the next all-nine number as a bill, and find the smallest coin size above one that splits it.

Compute the all-nine value with a short loop. The answer is the smallest prime factor of the absolute difference between that value and twice n. Trial division reaches it by the square root. Scanning every possible modulus wastes time when the difference is prime.

A bounded divisor search answers one case.

## Why It Works

1. The next all-nine value is 10^k - 1 for the digit count k of n.
2. When n already equals 10^k - 1, the next value uses one more digit.
3. The distance x(n) equals that value minus n.
4. Congruence x(n) ≡ n (mod p) means p divides x(n) - n.
5. That difference equals the all-nine value minus twice n.
6. The smallest divisor above one of a positive integer is its smallest prime factor.
7. Trial division reaches that factor by the square root.

The main names are:

| term | meaning |
|---|---|
| `nextRepunit` | smallest all-nine value greater than n |
| `difference` | absolute value of the all-nine value minus twice n |
| `candidate` | current odd trial divisor |
| `smallestDivisor` | answer for one case |

The names follow the code directly.

The generator produced these numbers for n = 234:

| step | value | note |
|---|---|---|
| digit count | 3 | 234 has three digits |
| next all-nine | 999 | first all-nine value above 234 |
| x(n) | 765 | 999 minus 234 |
| difference | 531 | 765 minus 234 |
| first divisor | 3 | 531 equals 3 times 177 |

Three divides both 765 and 234, so the answer is 3.

An all-nine value is odd, so the difference is odd. Trial division starts at 3 and steps by 2. A difference of one has no divisor above one, so the program prints -1.

## Code

**Input and output helpers.** The reader loads all lines once, then scans integers by hand.

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

The scanner skips every non-digit byte.
One output buffer collects all answer lines.
Large buffers flush in blocks.

**One divisor search per case.** The loop grows the all-nine value, then tests odd divisors.

```nim
for caseIndex in 0 .. testCount - 1:
  let originalValue = nextInt(inputData, scanPos)
  var nextRepunit = 9
  while nextRepunit <= originalValue:
    nextRepunit = nextRepunit * 10 + 9
  var difference = int64(nextRepunit) - 2 * int64(originalValue)
  if difference < 0:
    difference = -difference
  if difference <= 1:
    appendOutput("-1")
  else:
    var smallestDivisor = difference
    var candidate = 3
    while int64(candidate) * int64(candidate) <= difference:
      if difference mod int64(candidate) == 0:
        smallestDivisor = int64(candidate)
        break
      candidate += 2
    appendOutput($smallestDivisor)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

```

Growth stops at the first all-nine value above n.
A negative difference becomes positive before testing.
The search breaks at the first divisor found.

## Complexity

The work splits into phases:

| phase | time | space |
|---|---|---|
| input read | one pass over T lines | one input string |
| repunit growth | up to nine steps per case | a few integers |
| divisor search | odd candidates up to the square root | constant |
| output | one line per case | block buffer |

The divisor search dominates the work.

The asymptotic costs are:

| measure | Big O |
|---|---|
| time | O(T times sqrt(D)) for difference D |
| space | O(T) input characters |

Trying every modulus up to D wastes time when D is prime.

Trial division stops at the square root and keeps every case short.
