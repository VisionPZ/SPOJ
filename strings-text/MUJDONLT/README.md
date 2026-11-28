<https://www.spoj.com/problems/MUJDONLT/>

## Problem

A class has n students numbered 1 through n. Farabi holds roll number n and invites every student whose number shares no divisor greater than 1 with n. Report how many students he invites.

| item | bound |
|---|---|
| class size n | 1 to 1000000000 |
| input lines | 1 |
| judge limit | 1000 ms, 1536 MB |

The common divisor condition is exactly gcd(roll, n) = 1. The invited rolls are the totatives of n, and their count is Euler's totient function.

Sample input:

```
1
```

Sample output:

```
1
```

## Idea

Counting coprime rolls one by one is like checking every guest at a door, while factoring n is like reading the guest list once. Remove each distinct prime factor p of n and scale the count by (p-1)/p. Trial division up to the square root of n finishes quickly.

## Why It Works

1. A shared divisor of at least 2 exists exactly when gcd(roll, n) is greater than 1.
2. The invited rolls are the integers from 1 to n that are coprime with n.
3. Euler's totient counts those integers, so the answer is the totient of n.
4. For a prime p dividing n, exactly one out of every p values is divisible by p.
5. Multiplying the running count by (p-1)/p for each distinct prime removes all non-coprime rolls.

| term | meaning |
|---|---|
| `classSize` | the largest roll number and the class size n |
| `remainingValue` | the unfactored part of n during trial division |
| `inviteCount` | running totient value |
| `primeCandidate` | current trial divisor |

The worked case n = 12 has distinct primes 2 and 3. The count starts at 12, becomes 6 after p = 2, then becomes 4 after p = 3. Rolls 1, 5, 7 and 11 are coprime with 12.

The leftover value after the loop is a prime factor when it exceeds 1. Integer division stays exact because each processed prime divides the running count.

## Code

**Input and scanning.** The hand reader loads the single class size.

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

Token parsing ignores trailing whitespace and line breaks.
The output buffer collects the one answer line.

**Totient computation.** Trial division strips each distinct prime factor once.

```nim
let classSize = nextInt(inputData, scanPos)
var remainingValue = classSize
var inviteCount = classSize
var primeCandidate = 2
while primeCandidate * primeCandidate <= remainingValue:
  if remainingValue mod primeCandidate == 0:
    while remainingValue mod primeCandidate == 0:
      remainingValue = remainingValue div primeCandidate
    inviteCount = inviteCount div primeCandidate * (primeCandidate - 1)
  primeCandidate += 1
if remainingValue > 1:
  inviteCount = inviteCount div remainingValue * (remainingValue - 1)
appendOutput($inviteCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The inner loop removes every power of the current prime.
The loop bound shrinks as factors are removed, so large primes need little work.
The final answer is written once.

## Complexity

Trial division runs up to the square root of the shrinking remainder.

| phase | time | space |
|---|---|---|
| input read | one pass over one integer | one input string |
| factoring | trial divisors up to sqrt of n | constant scalars |
| output | one line | block buffer |

| measure | Big O |
|---|---|
| time | O(sqrt n) worst case |
| space | O(1) |

Checking every roll would cost O(n) time, which is too slow for n near 1e9.

Trial division gives the exact totient with a short loop and constant memory.
