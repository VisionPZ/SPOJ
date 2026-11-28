# SPEC_SET — Special Set (SPOJ)

<https://www.spoj.com/problems/SPEC_SET/>

## Problem

Choose the largest subset of the numbers 1 through n in which no chosen number equals k times another chosen number. The pair may use the same number twice, so k = 1 allows an empty set only.

Input starts with the test count t. Each of the next t lines holds n and k. Output one line per test with the largest subset size.

| item | bound |
|---|---|
| test count t | 1 to 100000 |
| universe size n | 1 to 100000000 |
| forbidden factor k | 1 to 100000000 |
| judge limit | 1000 ms, 1536 MB |

Large t drives the design, so each test must cost only a few operations.

Sample input:

```
1
6 2
```

Sample output:

```
4
```

## Idea

Numbers sit on strings that link x to k times x, and picking numbers is like choosing non-touching seats in a row. The real algorithm finds a maximum independent set on disjoint paths, then collapses it to an alternating sum of floor divisions. Each test costs O(log n) steps. Scanning every candidate subset would cost exponential time.

The alternating sum gives the answer without building any string.

## Why It Works

1. Multiplying by k links each number to at most one larger number and one smaller number.
2. Links form disjoint paths, since k of at least 2 makes numbers strictly grow.
3. A path of length L contributes ceil(L / 2) chosen numbers.
4. A path starting at m has length at least L exactly when m times k to the power L minus 1 stays at most n.
5. Counting starts by length turns the total into floor(n / k to the power j) with alternating signs.

| term | meaning |
|---|---|
| `universeSize` | the largest allowed number n |
| `forbidFactor` | the multiplication factor k |
| `levelSize` | n divided by a growing power of k |
| `answer` | running alternating sum, the subset size |

For the sample n = 6 and k = 2, the strings are 1-2-4, 3-6 and 5. Their best picks are 2, 1 and 1 numbers, so the answer is 4. The sum 6 - 3 + 1 gives the same 4.

The k = 1 branch returns zero before any division, which prevents an endless loop.

## Code

**Hand scanner and buffer.** The reader loads all input once and parses integers without library calls.

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

The scanner skips whitespace and stops at the last digit.
The buffer flushes only after many lines accumulate.
One read pass covers all test cases.

**Alternating sum per case.** Each test adds and subtracts successive floor divisions.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let universeSize = int64(nextInt(inputData, scanPos))
  let forbidFactor = int64(nextInt(inputData, scanPos))
  if forbidFactor == 1:
    appendOutput("0")
  else:
    var answer: int64 = 0
    var levelSize = universeSize
    var adding = true
    while levelSize > 0:
      if adding:
        answer = answer + levelSize
      else:
        answer = answer - levelSize
      levelSize = levelSize div forbidFactor
      adding = not adding
    appendOutput($answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop ends when repeated division reaches zero.
The sign flip implements the alternating floor sum exactly.
Every quotient stays in int64 because n is at most 1e8.

## Complexity

Each test divides n by k until the quotient vanishes.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| alternating sum | one division per power of k | constant |
| output | one flush per block | block buffer |

The work per test shrinks as k grows.

| measure | Big O |
|---|---|
| time | O(t log n), at most about 27 divisions per test |
| space | O(1) beyond input and output buffers |

Building and solving every path explicitly would cost O(n) per test.

The alternating sum keeps all 100000 tests well inside the time limit.
