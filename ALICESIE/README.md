# ALICESIE — Alice Sieve (SPOJ)

<https://www.spoj.com/problems/ALICESIE/>

## Problem

Alice repeatedly picks the largest unmarked number and marks its proper divisors. The task counts the numbers that stay unmarked when this process ends at limit N.

Input starts with T, then gives one limit N per case.

Output gives one count per case.

The bounds from the statement:

| item | bound |
|---|---|
| test cases T | 1 to 10000 |
| limit N | 2 to 1000000 |
| judge limit | 1000 ms, 1536 MB |

T and N together decide how cheap each answer must be.

Sample input:

```
3
2
3
5
```

The sample asks for limits 2, 3, and 5.

Sample output:

```
1
2
3
```

The surviving sets are 2, then 2 and 3, then 3, 4, and 5.

## Idea

Numbers above half the limit have no larger multiple nearby, like the top row of a multiplication table. The rest all feed into that top row and get crossed off.

The method counts those upper-half numbers directly, so each case takes constant time. It replaces a full sieve simulation with the closed form N minus N divided by two. A simulation marks divisors for every chosen P and costs quadratic work in N.

## Why It Works

1. A number greater than N divided by two has no larger multiple at most N.
2. Marking only hits proper divisors, which are smaller than the chosen number.
3. Therefore every number above the halfway point stays unmarked.
4. For any x at or below the halfway point, repeated doubling reaches a multiple greater than the halfway point and at most N.
5. That multiple stays unmarked, so the process picks it and marks x as a proper divisor.
6. Exactly the upper-half numbers survive, and their count is N minus N divided by two.

The main terms and formulas:

| term | meaning |
|---|---|
| `sieveLimit` | the limit N for one case |
| `unmarkedCount` | number of survivors, computed in one step |
| `caseCount` | number of test cases |

The upper-half count needs one division.

A script trace over limit 10 shows the marking order:

```
P=10: mark [2, 5]
  next P = 9
P=9: mark [3]
  next P = 8
P=8: mark [2, 4]
  next P = 7
P=7: mark []
  next P = 6
P=6: mark [2, 3]
  next P = -1
unmarked [6, 7, 8, 9, 10]
```

The doubling step proves the lower half always gets marked.

No rounding is needed, since integer division gives the exact halfway count.

## Code

**Input and buffer.** One read loads stdin, and answers collect in one string.

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

The scanner skips line breaks between limits.
The block size limits write calls.
One final write emits the tail of the buffer.

**Closed-form answer.** Each limit needs one division and one line.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let sieveLimit = nextInt(inputData, scanPos)
  let unmarkedCount = (sieveLimit + 1) div 2
  appendOutput($unmarkedCount)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Adding one before division gives the upper count for even and odd N.
The loop runs once per case.
Every answer ends with a newline.

## Complexity

Work divides into reading, computing answers, and writing.

| phase | time | space |
|---|---|---|
| input read | one pass over the limits | one input string |
| answer computation | one division per case | constant |
| output | one line per case | block buffer |

Reading and writing dominate when T is large.

The overall asymptotic bounds:

| measure | Big O |
|---|---|
| time | O(T) |
| space | O(1) beyond the input string |

A literal sieve simulation would cost O(N^2) per case, which is too slow for 10000 cases.
