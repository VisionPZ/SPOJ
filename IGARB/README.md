# IGARB — Ignore the Garbage (SPOJ)

<https://www.spoj.com/problems/IGARB/>

## Problem

The display counts ordinary numbers, but we read it upside down. For each rank K, give the K-th number that still reads correctly, as we see it.

Input begins with the test count. Each following line holds one rank K. Output one line per rank: the K-th seen number, with leading zeros kept.

The bounds from the statement and judge:

| Item | Bound |
|---|---|
| Test cases | at most 2200 |
| Rank K | 1 to 10^200, at most 200 decimal digits |
| Upright digits that survive | 0, 1, 2, 5, 6, 8, 9 |
| Judge limits | 3 s, 1536 MB |

The 200-digit bound rules out listing the sequence, so the rank itself must become the digits.

The sample input:

```
8
1
2
3
4
5
6
8
98
```

The sample output:

```
1
2
5
9
8
6
11
002
```

## Idea

Treat the rank as a disguised base-seven number. The disguise is a fixed digit map, like swapping the labels on seven tiles.

The algorithm converts K to base seven by repeated division, then maps each digit with `transformDigits`. Division on decimal strings keeps all 200 digits exact. Each pass scans the current string, so one rank takes about 24,000 digit steps at the top bound.

Generating valid numbers in order would take K steps, which fails for a 200-digit rank. Conversion time depends on the digit count, not on the rank size. The rank supplies every digit, so no search is needed.

## Why It Works

Four facts carry the proof.

1. Turning the display reverses the digit order and swaps 6 with 9. Digits 0, 1, 2, 5, 8 stay unchanged, so exactly seven upright digits survive.
2. An L-digit upright number picks from six nonzero first digits and seven later digits. That gives six times seven to the power L minus one values of length L.
3. Adding those counts for lengths one through L gives seven to the power L minus one. The ranks below that total fit exactly into L digits.
4. Base-seven digits of K select the same choices in the same order. Turning upside down reverses that order, so division remainders already arrive in print order.

The terms below connect the count to the code:

| Term | Meaning |
|---|---|
| seven to the power L, minus one | ranks with at most L digits |
| six times seven to the power L minus one | valid numbers with exactly L digits |
| `remainder` | next base-seven digit, least significant first |
| `transformDigits` | fixed map from a base-seven digit to the seen digit |

Every digit comes from the rank; only the labels change.

A script traces three ranks through the division loop:

```
K=8
  step 1: 8 = 1*7 + 1 -> digit 1 -> seen 1
  step 2: 1 = 0*7 + 1 -> digit 1 -> seen 1
answer: 11
K=98
  step 1: 98 = 14*7 + 0 -> digit 0 -> seen 0
  step 2: 14 = 2*7 + 0 -> digit 0 -> seen 0
  step 3: 2 = 0*7 + 2 -> digit 2 -> seen 2
answer: 002
K=342
  step 1: 342 = 48*7 + 6 -> digit 6 -> seen 6
  step 2: 48 = 6*7 + 6 -> digit 6 -> seen 6
  step 3: 6 = 0*7 + 6 -> digit 6 -> seen 6
answer: 666
```

Remainders arrive in print order, so each answer is the mapped digits read downward.

## Code

**Constants.** The digit map and the block size stay fixed for every rank.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const transformDigits = "0125986"
const baseValue = 7
```

`transformDigits` maps a base-seven digit to the digit we see. `baseValue` is the number of surviving digits. `flushBlockBytes` is a 256 KiB output block.

**Token reader.** One scan position walks the whole input buffer.

```nim
proc nextDigitToken(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  let tokenStart = pos
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    pos += 1
  return data[tokenStart .. pos - 1]

proc tokenToInt(token: string): int =
  var value = 0
  for digitChar in token:
    value = value * 10 + int(digitChar) - firstDigitValue
  return value
```

`nextDigitToken` returns a slice, so a 200-digit rank stays exact. `tokenToInt` handles only the small test count. Both skip separators without building a token list.

**Division.** One call produces the next base-seven digit.

```nim
proc divideBySeven(value: string): tuple[remainder: int, quotient: string] =
  var quotient = ""
  var remainder = 0
  for digitChar in value:
    let current = remainder * 10 + int(digitChar) - firstDigitValue
    let digit = current div baseValue
    remainder = current mod baseValue
    if quotient.len > 0 or digit > 0:
      quotient.add chr(firstDigitValue + digit)
  return (remainder, quotient)
```

`current mod baseValue` is the next digit. Skipping leading zero quotient digits keeps the value exact. One call costs one pass over the current digits.

**Buffers.** The input is read once; one output buffer flushes in blocks.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = tokenToInt(nextDigitToken(inputData, scanPos))
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`readLine` appends each line to `inputData`, so line breaks cannot desync the reader. `appendOutput` writes only when the block is full. `setLen 0` reuses the same allocation.

**Driver.** Repeated division emits the seen digits in the right order.

```nim
for _ in 0 ..< caseCount:
  var currentValue = nextDigitToken(inputData, scanPos)
  var answerText = ""
  while currentValue.len > 0:
    let divided = divideBySeven(currentValue)
    answerText.add transformDigits[divided.remainder]
    currentValue = divided.quotient
  appendOutput(answerText)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

`currentValue` shrinks until empty, so the loop runs once per base-seven digit. Digits leave least significant first, which is the upside-down order. The last write flushes the tail.

## Complexity

Here is the cost breakdown by phase:

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the input lines | input bytes |
| One rank at 200 digits | about 24,000 digit steps | two strings of at most 200 digits |
| Output | one write per 256 KiB block | one block buffer |
| Total for 2200 ranks | about 5.2 times 10^7 digit steps | input plus one block |

The work stays in the digit scans, and the block buffer bounds memory.

The asymptotic bounds:

| Measure | Big O |
|---|---|
| Time | O(D^2) per rank for D decimal digits, then O(T D^2) for T ranks |
| Space | O(D) per rank, plus the input buffer |

Listing valid numbers in order costs O(K) steps and fails at 200 digits. Base conversion costs O(D^2) steps and ignores the rank size, so it wins at every legal bound.
