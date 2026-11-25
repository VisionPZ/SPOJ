# NUMTH02 — Worst Mango (SPOJ)

<https://www.spoj.com/problems/NUMTH02/>

## Problem

Count buckets as a power, share them among rooms, and report the leftovers. Then share the total mangoes among those leftover buckets and report the mango leftovers.

Input begins with three integers `b`, `n`, and `r`. The next line holds the partition count `p`. The following `p` lines each hold one mango amount `xi`.

Output holds two numbers on one line: the extra buckets and the extra mangoes.

| item | bound |
|---|---|
| base b and exponent n | 1 to 10^6 |
| rooms r | 1 to 5000 |
| partitions p | 1 to 50 |
| each amount xi | 1 to 10^18 |
| judge limit | 500 ms, 1536 MB |

The exponent makes the raw bucket count far too large to store, so the remainder is computed directly.

Sample input:

```
2 3 5
3
2
4
4
```

Sample output:

```
3 1
```

## Idea

Find the remainder of a huge power by repeated squaring, like folding a long rope in half again and again. Reduce the mango total at each addition so the running sum stays small.

Modular exponentiation halves the exponent on every loop, so it costs logarithmic steps. The mango amounts are summed modulo the bucket remainder, which avoids ever holding the full total. Each step uses only one 64-bit value.

Shrink the power first, then reduce the mango sum with it.

## Why It Works

1. The number of buckets equals `b` raised to `n`, written as `b^n` in the note.
2. Equal sharing among `r` rooms leaves `b^n mod r` spare buckets.
3. Repeated squaring preserves the remainder after every multiplication.
4. The mango remainder equals the sum of all amounts modulo the spare buckets.
5. Reducing each amount before adding keeps every intermediate inside 64 bits.

| term | meaning |
|---|---|
| `bucketBase` | the base of the bucket power |
| `bucketExponent` | the exponent of the bucket power |
| `powerResult` | running remainder of the bucket power |
| `extraBuckets` | spare buckets after room sharing |
| `mangoRemainder` | spare mangoes after bucket sharing |

The note traces `2^3 = 8`, `8 mod 5 = 3`, and `(2+4+4) mod 3 = 1`. The sample answer is therefore `3 1`.

The code prints `0 0` when the room count divides the power exactly.

## Code

**Input and modular power.** The reader loads the header and squares the base while halving the exponent.

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

let bucketBase = nextInt(inputData, scanPos)
let bucketExponent = nextInt(inputData, scanPos)
let roomCount = nextInt(inputData, scanPos)
var powerBase = bucketBase mod roomCount
var powerResult = 1 mod roomCount
var exponentCursor = bucketExponent
while exponentCursor > 0:
  if (exponentCursor and 1) == 1:
    powerResult = (powerResult * powerBase) mod roomCount
  powerBase = (powerBase * powerBase) mod roomCount
  exponentCursor = exponentCursor shr 1
let extraBuckets = powerResult
```

The room count is at most 5000, so each product stays tiny.
Only the low bit of the exponent is tested on each pass.
The loop runs once per exponent bit.

**Reduced mango sum.** Each amount is reduced before it enters the running remainder.

```nim
var mangoRemainder: int64 = 0
if extraBuckets > 0:
  let partitionCount = nextInt(inputData, scanPos)
  for partitionIndex in 0 .. partitionCount - 1:
    let mangoAmount = nextInt(inputData, scanPos)
    mangoRemainder = (mangoRemainder + int64(mangoAmount) mod int64(extraBuckets)) mod int64(extraBuckets)
appendOutput($extraBuckets & " " & $mangoRemainder & "\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The guard avoids division by zero when no buckets remain.
A 64-bit accumulator holds every reduced amount.
The single output line passes through the block buffer.

## Complexity

The power loop follows the exponent bits, and the mango loop follows the partitions.

| phase | time | space |
|---|---|---|
| input read | one pass over the tokens | one input string |
| modular power | one squaring per exponent bit | three integers |
| mango sum | one reduction per partition | one accumulator |
| output | one line | block buffer |

The exponent drives the power loop and p drives the mango loop.

| measure | Big O |
|---|---|
| time | O(log n + p) |
| space | O(1) beyond the input string |

Building `b^n` as a full integer would need n multiplication steps and enormous memory.

Reduce the power early, reduce each mango amount early, and print both remainders.
