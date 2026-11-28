# MANGOES — Real Mangoes for Ranjith (SPOJ)

<https://www.spoj.com/problems/MANGOES/>

## Problem

Boxes carry counts equal to their labels. A box is real when every pair from its own count and the next two counts has gcd one. Report the sum of real box counts, reduced modulo the number of boxes.

Input starts with the test count T. Each following line holds one box count N. Output one reduced sum per line.

| item | bound |
|---|---|
| box count N | 3 to 100000000 |
| test count T | up to 10000 |
| judge limit | 1000 ms, 1536 MB |

The modulus grows with N, so the sum needs 64-bit arithmetic before reduction.

Sample input:

```
2
9
5
```

Sample output:

```
7
4
```

The first answer is 16 modulo 9; the second is 4 modulo 5.

## Idea

Picking real boxes is like counting every other house on a street: only odd labels qualify. The closed form for the sum of the first k odd numbers gives the answer in one multiplication per case. Checking every pair of counts would cost work proportional to N for each case. Reduce the gcd test to a parity test, then square one count.

## Why It Works

1. Consecutive counts i and i+1 are coprime, as are i+1 and i+2.
2. The remaining pair has gcd(i, i+2) equal to gcd(i, 2).
3. That gcd is one only when i is odd, so real boxes have odd labels up to N-2.
4. The sum of the first k odd numbers equals k squared.
5. Here k is (N-1)/2, and reducing k squared modulo N gives the result.

| term | meaning |
|---|---|
| `boxCount` | N, the label total and the modulus |
| `oddBoxCount` | count of qualifying odd labels |
| `realMangoes` | sum of qualifying labels modulo N |

Each term maps directly to one step of the closed form.

A script trace for both sample cases:

```
N = 9: labels 1 3 5 7, oddBoxCount = 4, 4^2 = 16, 16 mod 9 = 7
N = 5: labels 1 3, oddBoxCount = 2, 2^2 = 4, 4 mod 5 = 4
```

The trace reproduces both sample answers.

## Code

**Input and scanner.** The hand reader loads the test count and every N.

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

The scanner skips line breaks between cases.
Each value is built one digit at a time.
The loop runs once per test case.

**Closed-form reduction.** Each case squares an odd-label count and reduces it.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let boxCount = int64(nextInt(inputData, scanPos))
  let oddBoxCount = (boxCount - 1) div 2
  let realMangoes = (oddBoxCount * oddBoxCount) mod boxCount
  appendOutput($realMangoes)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

64-bit values hold the square before reduction.
Output collects in one buffer and flushes in blocks.
The final flush writes any remaining bytes.

## Complexity

Work splits into input reading and one constant-cost formula per case.

| phase | time | space |
|---|---|---|
| input read | one pass over the input | one input string |
| reduction | one square per case | a few scalars |
| output | one line per case | block buffer |

The phase table shows that input and output dominate.

| measure | Big O |
|---|---|
| time | O(T) |
| space | O(1) beyond input and output |

A pairwise gcd scan would cost O(N) per case instead of O(1).
The closed form keeps large N cheap.
