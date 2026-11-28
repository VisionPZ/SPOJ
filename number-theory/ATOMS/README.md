# ATOMS — Atoms in the Lab (SPOJ)

<https://www.spoj.com/problems/ATOMS/>

## Problem

Starting with N atoms, every atom splits into K atoms each second. Report the last second whose atom count stays at or below M.

Input starts with the test count. Each test gives N, K, and M on one line. Print one time per test.

| item | bound |
|---|---|
| test count P | up to 10000 |
| N, K, M | 2 to 1000000000000000000 |
| judge limit | 1000 ms, 1536 MB |

At time zero the count is N, and after t seconds it is N times K to the power t.

Sample input:

```
2
2 2 7
2 2 8
```

Sample output:

```
1
2
```

## Idea

Think of doubling grains in a jar with a fixed lid: keep pouring while the next doubling fits. Division answers the fit question without ever forming an overflowing product. Direct multiplication can overflow 64 bits, while division-based growth keeps every intermediate value inside the limit.

## Why It Works

1. At time t the lab holds N times K to the power t atoms.
2. The reaction may run while the next count N times K to the power t+1 stays at most M.
3. Testing `atomCount <= atomLimit div splitFactor` is equivalent to testing atomCount times splitFactor at most atomLimit.
4. The division test never computes the product, so large values cannot overflow.
5. Each successful test grows the count by the factor and adds one second.
6. When the test fails, the current count is the largest allowed count and the elapsed time is the answer.

| term | meaning |
|---|---|
| `atomCount` | atoms present at the current second |
| `splitFactor` | number of atoms produced per atom each second |
| `atomLimit` | largest allowed atom count |
| `elapsedSeconds` | seconds already simulated |

The loop runs at most 60 times because the factor is at least two and M fits in 64 bits.

A worked trace from `gen.py`:

```
N=2 K=2 M=7
t=0: 2 <= 7 div 2 = 3 -> grow to 4, elapsed 1
t=1: 4 <= 3 false -> stop at 1
N=2 K=2 M=8
t=0: 2 <= 4 -> grow to 4, elapsed 1
t=1: 4 <= 4 -> grow to 8, elapsed 2
t=2: 8 <= 4 false -> stop at 2
```

Both sample lines match the trace.

## Code

**Input and scanner.** The whole input is read once and parsed by hand.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

Every value fits in a signed 64-bit integer.
The scanner skips spaces and newlines between values.
No special handling for signs is needed.

**Buffered output.** All answers go through one string buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

One line is appended per test.
The buffer flushes only after reaching the block size.
A final write clears the remaining text.

**Growth loop.** Division guards each multiplication and counts the seconds.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  var atomCount = int64(nextInt(inputData, scanPos))
  let splitFactor = int64(nextInt(inputData, scanPos))
  let atomLimit = int64(nextInt(inputData, scanPos))
  var elapsedSeconds: int64 = 0
  while atomCount <= atomLimit div splitFactor:
    atomCount = atomCount * splitFactor
    elapsedSeconds += 1
  appendOutput($elapsedSeconds)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The division test replaces a potentially overflowing product.
The count grows only while the next count still fits.
The loop stops after roughly 60 steps at most.

## Complexity

Each test performs a short growth loop and writes one line.

| phase | time | space |
|---|---|---|
| input read | one pass over all test lines | one input string |
| growth loop | one step per second | constant |
| output | one line per test | block buffer |

The growth loop has a hard bound of about 60 steps per test.

| measure | Big O |
|---|---|
| time | O(P log M) |
| space | O(1) besides input and output buffers |

Computing powers directly would overflow or need big integers.
The division guard gives the same answer with plain 64-bit arithmetic.
