# SECSYS — Security System (SPOJ)

<https://www.spoj.com/problems/SECSYS/>

## Problem

A house has `C` safes numbered `0` to `C - 1`, each storing a linear rule `Y = A * X + B`. Starting from the digit sum of a six-digit password, each step moves to safe `X mod C` and replaces `X` with `A * X + B` at that safe. After `I` intermediate safes, report the final safe number `X mod C` and the final value `X`.

Input contains multiple test cases ending with `0 0 0`. Each test case gives `C P I`, followed by `C` lines of `A B` pairs, followed by a six-digit string. Output one line `<safe> <value>` per test case.

This table lists the constraints and judge limits.

| item | bound |
|---|---|
| safes `C` | 3 <= C <= 10 |
| intermediate steps `I` | 0 < I <= C - 2 |
| coefficients `A, B` | 0 <= A, B <= 100 |
| judge limit | 1000 ms, 1536 MB, 50000 B |

Every intermediate value fits inside a signed 64-bit integer.

Sample input:

```
6 3 2
10 25
4 45
10 99
8 7
0 0
1 81
908710
10 5 8
100 100
100 100
100 100
100 100
100 100
100 100
100 100
100 100
100 100
100 100
999999
0 0 0
```

Sample output:

```
1 625
0 550101010101010100
```

## Idea

Following the circuit is like walking a scavenger hunt where every clue hands you a new number and tells you which box to open next. Direct simulation runs `I` multiply-add steps in `O(I)` time using 64-bit arithmetic.

Converting the password string into a big integer or using arbitrary-precision math adds needless overhead because `54 * 100^8` is under `6 * 10^17`, well below `int64` max (`9.22 * 10^18`).

## Why It Works

1. The first display value is the sum of the six password digits, at most `6 * 9 = 54`.
2. Each step multiplies by at most `100` and adds at most `100`, and `I <= C - 2 <= 8`.
3. The largest possible output occurs at `C = 10`, `I = 8`, `A = B = 100`, password `999999`, giving `550101010101010100 < 2^63 - 1`.
4. Summing digits directly from the ASCII token handles leading zeros such as `000001` without losing digits.

This table defines the key variables used in the simulation.

| term | meaning |
|---|---|
| `vaultCount` | number of safes `C` |
| `stepCount` | number of intermediate safes `I` |
| `coeffA`, `coeffB` | linear rules for safes `0 .. C - 1` |
| `currentValue` | displayed number `X` after each step |
| `currentVault` | next safe index `X mod C` |

Fixed-size arrays hold all safe rules with zero per-case heap allocations.

Worked example for the first sample case (`C = 6, I = 2`, password `908710`):

```
start : digitSum("908710") = 25, vault = 25 mod 6 = 1
step 1: safe 1 (4*25 + 45) = 145, vault = 145 mod 6 = 1
step 2: safe 1 (4*145 + 45) = 625, vault = 625 mod 6 = 1
result: 1 625
```

After two steps the circuit lands on safe 1 with value 625.

## Code

**Bulk input, digit scanners, and output buffer.** Reads stdin once, scans unsigned integers and password digit sums directly from the buffer, and flushes output in 128 KiB blocks.

```nim
const flushBlockBytes = 1 shl 17
const maxVaults = 10

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

proc nextDigitSum(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var digitSum: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    digitSum += int64(int(data[pos]) - 48)
    pos += 1
  return digitSum

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`nextDigitSum` accumulates ASCII digit values directly, avoiding both string slicing and integer division. Every value in the spec is non-negative, so no sign check is needed.

**Circuit simulation loop.** Reads each case into fixed 10-element arrays, runs `stepCount` updates in `int64`, and appends the final safe and code.

```nim
var coeffA: array[maxVaults, int64]
var coeffB: array[maxVaults, int64]

while scanPos < inputData.len:
  let vaultCount = nextInt(inputData, scanPos)
  let startVault = nextInt(inputData, scanPos)
  let stepCount = nextInt(inputData, scanPos)
  if vaultCount == 0 and startVault == 0 and stepCount == 0:
    break
  for idx in 0 .. vaultCount - 1:
    coeffA[idx] = int64(nextInt(inputData, scanPos))
    coeffB[idx] = int64(nextInt(inputData, scanPos))
  var currentValue = nextDigitSum(inputData, scanPos)
  var currentVault = int(currentValue mod int64(vaultCount))
  for step in 0 .. stepCount - 1:
    currentValue = coeffA[currentVault] * currentValue + coeffB[currentVault]
    currentVault = int(currentValue mod int64(vaultCount))
  appendOutput($currentVault)
  appendOutput(" ")
  appendOutput($currentValue)
  appendOutput("\n")

if outputBuffer.len > 0:
  stdout.write outputBuffer
  outputBuffer.setLen 0
```

Reusing `coeffA` and `coeffB` across cases eliminates per-case allocations. The loop bound `stepCount - 1` runs at most 8 times per case.

## Complexity

This table summarizes time and space per test case.

| phase | time | space |
|---|---|---|
| read safe rules | O(C) | O(1) |
| simulate circuit | O(I) | O(1) |
| emit answer | O(1) | O(1) |

With `C <= 10` and `I <= 8`, every test case takes constant work.

This table states the overall Big O bounds for `T` test cases.

| measure | big O |
|---|---|
| time | O(T * C) |
| space | O(input bytes) |

Using fixed 64-bit arithmetic avoids arbitrary-precision multiplication, keeping every case in a few nanoseconds.
