# ULTREVEN — Ultra-even (SPOJ)

<https://www.spoj.com/problems/ULTREVEN/>

## Problem

An array is called ultra even when the sum of every consecutive subarray is even. The program reads the array and prints `YES` or `NO`.

Input starts with `n`, the array length, followed by `n` space-separated integers. Output holds one line with the verdict.

| Item | Bound |
|---|---|
| Length `n` | 1 ≤ n ≤ 100000 |
| Array values | no stated bound; tests use up to 10^9 |
| Judge limit | 1000 ms, 1536 MB |

The sample cases:

```
4
1 4 5 2
```

```
NO
```

```
3
2 4 6
```

```
YES
```

## Idea

A subarray of size one is a single element, so an ultra even array must have every element even. The reverse also holds: adding even numbers always gives an even sum. So the whole test collapses to one question — is every number even? Think of a bouncer checking IDs at the door: one odd number turns the array away, costing one parity test per element instead of testing all n(n+1)/2 subarrays.

## Why It Works

1. Every single element is a subarray, so an odd element alone makes some subarray sum odd.
2. If all elements are even, each is `2k`, and any subarray sum is `2` times an integer, hence even.
3. The two facts together make "all elements even" exactly the same property as "all subarray sums even".
4. `allEven` starts true and is cleared by the first odd value, so the answer is `NO` whenever one exists.
5. Reading stops at the last digit of the last number, so no end-of-array handling is needed.

| Term | Meaning |
|---|---|
| `numberCount` | `n`, the array length |
| `currentNumber` | the array value currently scanned |
| `allEven` | stays true only while every value read is even |

A traced run of the first sample:

```
read 4 numbers: 1 4 5 2
1 is odd -> allEven = false
answer NO
```

## Code

**Input and hand scanner.** This block loads stdin and reads the integers.

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

One readLine loop collects all input bytes.
The scanner skips whitespace between digits.
Scanning costs one pass over the consumed characters.

**Buffered output.** This block holds the verdict line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after reaching 128 KiB.
One final write emits any remaining bytes.

**Parity scan.** This block reads the array and tracks one flag.

```nim
let numberCount = nextInt(inputData, scanPos)
var allEven = true
for numberIndex in 0 .. numberCount - 1:
  let currentNumber = nextInt(inputData, scanPos)
  if currentNumber mod 2 != 0:
    allEven = false
if allEven:
  appendOutput("YES")
else:
  appendOutput("NO")
outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop keeps scanning after the flag is cleared, which keeps the code short and the branch predictable.
Only the last bit of each number matters, and `mod 2` reads it.
No array is stored: values are checked as they arrive.

## Complexity

The cost splits into input, one parity test per value, and output.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Parity scan | O(n) | constant |
| Output | one small write | buffer |

| Measure | Big O |
|---|---|
| Time | O(n) |
| Space | O(input size) |

Testing every subarray sum would take O(n²), which is 10^10 operations at n = 100000.
