# SUM1SEQ — Sum of one-sequence (SPOJ)

<https://www.spoj.com/problems/SUM1SEQ/>

## Problem

A hiker starts at altitude zero and climbs or descends one meter at each step. Given the total of all visited altitudes, find a walk with the required length.

Input: `t` test cases, each separated by a blank line. A case gives `n` on one line and the target sum `S` on the next.

Output: `n` integers, one per line, with a blank line after each case. Print `No` when no such walk exists.

The statement gives these bounds:

| Item | Bound |
| --- | --- |
| Sequence length `n` | 1 to 10,000 |
| Target sum `S` | absolute value at most 50,000,000 |
| Output size | `n` lines per feasible case |
| Judge limit | 3000 ms, 1536 MB |

The output can reach thousands of lines per case, so one shared buffer writes them.

The sample input and output:

```
1
8
4
```

```
0
-1
0
-1
0
1
2
3

```

## Idea

Treat each step as a coin that adds a fixed weight to the final sum. Spend the largest coins first, like paying a bill with big bills before small ones.

The program uses a greedy construction on step weights. Step `i` changes every later altitude, so its weight is `n - i`.

Flipping that step from up to down lowers the total by twice its weight. The greedy choice takes weights from `n - 1` down to 1, so one case costs `O(n)`.

Trying all `2^(n - 1)` up-down patterns cannot reach `n = 10,000`. The greedy choice succeeds whenever the parity and size tests pass.

Largest-first selection turns an exponential search into one descending pass.

## Why It Works

Four facts justify the construction.

1. Starting at zero with unit steps gives `a_i` as the sum of the first `i - 1` steps.
2. Each step at position `i` appears in `n - i` later altitudes, so it contributes weight `n - i` to the total.
3. With all steps up, the total is `totalWeight = n(n - 1)/2`. Flipping one step lowers the total by `2 × weight`, so the target must match `totalWeight` in parity and not exceed it.
4. The weights `1..n - 1` can sum to any value from 0 to `totalWeight`. Taking them from largest to smallest therefore empties `remainingSum` exactly.

The quantities used by the driver:

| Term | Meaning |
| --- | --- |
| `totalWeight` | sum of all step weights, `n(n - 1)/2` |
| `magnitudeSum` | absolute value of `S` |
| `remainingSum` | half the gap from `totalWeight` down to `S` |
| `isNegative[j]` | true when the step of weight `j` goes down |
| `currentValue` | altitude after the current step |

The parity test uses `magnitudeSum` so negative targets follow the same rule.

A script trace of the sample case:

```
length 8, target 4, total weight 28, remaining 12
weight 7: take=True, remaining=5
weight 6: take=False, remaining=5
weight 5: take=True, remaining=0
weight 4: take=False, remaining=0
weight 3: take=False, remaining=0
weight 2: take=False, remaining=0
weight 1: take=False, remaining=0
chosen weights [7, 5]
sequence [0, -1, 0, -1, 0, 1, 2, 3]
sum 4
```

Weights 7 and 5 lower the total by `2 × 12 = 24`, from 28 down to 4.

The scanner keeps a sign branch, since `S` may be negative. Each case ends with one blank line, even when the answer is `No`.

## Code

**Input, scanner, and output helper.** One buffer holds the stream, and the scanner accepts a minus sign.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9') and data[position] != '-':
    position += 1
  var signValue = 1
  if position < data.len and data[position] == '-':
    signValue = -1
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return signValue * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The sign branch runs before the digit loop, so negative targets parse correctly.
`appendOutput` flushes at 256 KiB to handle large outputs.
The buffer `isNegative` starts empty and grows only when needed.

**Case driver.** The program tests feasibility, then builds the walk.

```nim
var isNegative = newSeq[bool](0)

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let sequenceLength = nextInt(inputData, scanPos)
  let targetSum = nextInt(inputData, scanPos)
  let totalWeight = sequenceLength * (sequenceLength - 1) div 2
  let magnitudeSum = if targetSum < 0: -targetSum else: targetSum
  if (magnitudeSum + totalWeight) mod 2 != 0 or magnitudeSum > totalWeight:
    appendOutput("No\n\n")
    continue
  var remainingSum = (totalWeight - targetSum) div 2
  if isNegative.len <= sequenceLength:
    isNegative.setLen(sequenceLength + 1)
  var j = sequenceLength - 1
  while j >= 1:
    if j <= remainingSum:
      isNegative[j] = true
      remainingSum -= j
    else:
      isNegative[j] = false
    j -= 1
  appendOutput("0\n")
  var currentValue = 0
  for i in 1..<sequenceLength:
    let weightValue = sequenceLength - i
    if isNegative[weightValue]:
      currentValue -= 1
    else:
      currentValue += 1
    appendOutput($(currentValue))
    outputBuffer.add '\n'
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The parity test rejects impossible targets before any construction.
The descending loop takes a weight when it fits `remainingSum`.
The print loop walks positions `1..n - 1` and converts each chosen weight back into a step.

## Complexity

Each case performs a constant-time test plus two linear passes.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | input bytes |
| Feasibility test | O(1) per case | O(1) |
| Greedy weights | O(n) from weight `n - 1` to 1 | O(n) for `isNegative` |
| Sequence output | O(n) lines | 256 KiB block |
| Total per case | O(n) | O(n) |

At `n = 10,000` the program writes 10,000 lines through one buffer.

The asymptotic bounds follow from the table:

| Measure | Big O |
| --- | --- |
| Time | O(n) per case, O(total length) overall |
| Space | O(n) for the step flags, plus buffers |

Enumerating all step-sign patterns takes `O(2^n)` time and cannot handle the length bound.
