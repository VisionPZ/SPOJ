# URJC2_C — Will it blend? (SPOJ)
<https://www.spoj.com/problems/URJC2_C/>

## Problem

Each test gives a blender power and a list of item powers. An item blends only when the blender power is strictly greater than the item power. Print one verdict line per item, in input order.

The first line gives the test count. Each test starts with N and K. Then N lines hold one item power each. Print `Yes, it blends!` when K exceeds the item, otherwise `Well, it mostly blended`.

The bounds from the statement:

| Item | Bound |
|---|---|
| Items per test N | 1 ≤ N ≤ 1000 |
| Blender power K | 1 ≤ K ≤ 10^9 |
| Item power Ni | 1 ≤ Ni ≤ 10^9 |
| Judge time | 1000 ms |

The item count drives the output size; each item costs one comparison.

The sample case:

```
2
3 5
1
200
4
2 5000
4999
5000
```

```
Yes, it blends!
Well, it mostly blended
Yes, it blends!
Yes, it blends!
Well, it mostly blended
```

## Idea

Each item gets one comparison. Think of a turnstile that opens only when the visitor is shorter than the guard; exact height still fails. A strict `>` check captures that rule. Buffered output keeps thousands of verdict lines cheap.

## Why It Works

1. The judge shows that power equal to K does not blend.
2. A strict comparison returns true only when K is larger.
3. Items are read in order, so verdicts keep that same order.
4. The buffer flushes in blocks, which limits write calls.

The main terms:

| Term | Meaning |
|---|---|
| `K` | the blender power for one test |
| `Ni` | the power needed to blend one item |
| `caseCount` | number of tests |
| `itemCount` | number of items in the current test |

These terms reduce each test to one loop over its items.

A script check sorts powers 1, 200 and 4 with K = 5. All three fall below 5, so all three blend. With K = 5000, power 5000 is blocked while 4999 blends.

## Code

**Input buffer and scanner.**
```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const blendYes = "Yes, it blends!"
const blendNo = "Well, it mostly blended"

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    pos += 1
  return value
```
One read pass stores the whole input. The scanner skips line breaks by index.

**Verdict loop.**
```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = int(nextInt(inputData, scanPos))
for j in 0..<caseCount:
  let itemCount = int(nextInt(inputData, scanPos))
  let blenderPower = nextInt(inputData, scanPos)
  for k in 0..<itemCount:
    let neededPower = nextInt(inputData, scanPos)
    if blenderPower > neededPower:
      appendOutput(blendYes)
    else:
      appendOutput(blendNo)
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```
The strict comparison rejects equal powers. One final flush writes any remaining bytes.

## Complexity

The cost is one read pass and one verdict per item.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Verdicts | one comparison per item | constant |
| Output | one write per 128 KiB block | block buffer |

Every phase grows linearly with the number of integers.

Big O uses I as the total item count.

| Measure | Big O |
|---|---|
| Time | O(I) |
| Space | O(I) for stored input |

Sorting the items before comparing would add a log factor. The direct test skips that cost.
