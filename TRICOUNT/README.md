# TRICOUNT — Counting Triangles (SPOJ)

<https://www.spoj.com/problems/TRICOUNT/>

## Problem

A large triangle is built from a triangular grid of level N. Count every triangle in the grid, of any size and either orientation.

Input starts with T, the number of test cases. Each of the next T lines holds one level N. Print one count per test case on its own line.

| item | bound |
|---|---|
| test cases T | at most 10000 |
| level N | 1 to 1000000 |
| answer | fits in a signed 64-bit integer |
| judge limit | 1000 ms, 1536 MB |

The level bound drives the design because no enumeration can touch every small triangle.

Sample input:

```
3
1
2
3
```

Sample output:

```
1
5
13
```

## Idea

Add upright and downward triangles as two stacks of bricks, then collapse each stack with one formula. The method is a closed-form count from a quadratic sum. Each test case costs constant time. Enumerating every candidate triangle costs work proportional to N and cannot handle a million levels across thousands of cases. Takeaway: reduce both families to one product before reading the whole grid.

## Why It Works

1. An upright triangle of side s starts at (N-s+1)(N-s+2)/2 positions.
2. A downward triangle of side s fits only when 2s is at most N, with (N-2s+1)(N-2s+2)/2 positions.
3. Both position counts are triangular numbers, so their sums have short polynomial forms.
4. Adding the two forms gives N(N+2)(2N+1)/8, and flooring removes the half-integer part.

| term | meaning |
|---|---|
| `level` | grid side length from the input |
| `uprightSpan` | level times level plus two |
| `doubledLevel` | twice the level plus one |
| `rawProduct` | numerator before division by eight |
| `triangleTotal` | floored count written to the output |

Every quantity is computed before the division, so rounding happens exactly once.

The generator traces level 4 as follows:

```
upright side counts: 10, 6, 3, 1 -> 20
downward side counts: 6, 1 -> 7
20 + 7 = 27
4 * 6 * 9 / 8 = 27
```

The split confirms that the single closed form equals the sum of both families.

## Code

**Input and scanning.** One pass loads all test levels into a string.

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
```

The scanner skips separators and builds each value digit by digit.
It visits every input byte once.
No token array is stored.

**Counting and output.** One product gives each answer, written through the block buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let level = int64(nextInt(inputData, scanPos))
  let uprightSpan = level * (level + 2)
  let doubledLevel = 2 * level + 1
  let rawProduct = uprightSpan * doubledLevel
  let triangleTotal = rawProduct div 8
  appendOutput($triangleTotal)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Products stay in int64 because the numerator reaches about two quintillion.
Floor division by eight matches the half-integer part of the sum.
The buffer flushes once after the loop.

## Complexity

The work is one arithmetic evaluation per test case.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| counting | constant work per test case | a few integers |
| output | one line per test case | block buffer |

| measure | Big O |
|---|---|
| time | O(T) |
| space | O(1) besides input |

Enumerating triangles would cost O(N) per case and fail at the upper level bound. The closed form keeps the largest test cases cheap.
