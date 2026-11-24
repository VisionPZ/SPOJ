## Problem

A stone of weight W rests on one pan of a balance. You own N weights with masses 1, 2, 4, up to 2^(N-1). Count the placements that put each weight on a pan or aside and balance the stone. W arrives as a binary string of L characters. Print the count modulo D, one line per case.

| Quantity | Bound |
| --- | --- |
| Weights N | 1 to 1 000 000 |
| Binary length L | 1 to N |
| Modulus D | 2 to 100 |
| Test cases | bounded by the input size |
| Time limit | 7000 ms |
| Memory limit | 1536 MB |

Only two carry states matter, so each bit costs a few additions.

## Idea

Give each weight a signed digit: +1 for the left pan, -1 for the right pan, 0 for aside. Balancing then means the signed binary sum equals W. A carry runs from the low bit upward and holds only 0 or -1. Two counters track the placements that reach each carry, which replaces the 3^N placements a brute-force search would try.

Cost per bit: one comparison and one modular addition, plus one modular product for the omitted high bits.

## Why It Works

After i bits, the partial signed sum differs from the low i bits of W by c times 2^i. Here c is the carry. Choosing digit d at bit i gives a new carry.

| term | meaning |
| --- | --- |
| c' = (c + d - w_i) / 2 | carry after choosing digit d for binary digit w_i |
| w_i = 0 | carry 0 stays 0; carry -1 goes to 0 or -1 |
| w_i = 1 | carry 0 goes to 0 or -1; carry -1 stays -1 |

The equation closes because d lies in -1, 0, 1 and w_i lies in 0, 1. The quotient stays 0 or -1, so two counters hold every reachable state.

A one bit adds the two counters into countOne and leaves countZero. A zero bit adds the two counters into countZero and leaves countOne. The high N - L bits of W are zero. Each adds countOne to countZero, so k such bits add k times countOne in one step.

A script walks the string "1000" from its last character, the low bit, toward its first character:

```
start (countZero, countOne) = (1, 0)
bit 3 = 0: (1, 0)
bit 2 = 0: (1, 0)
bit 1 = 0: (1, 0)
bit 0 = 1: (1, 1)
two trailing zero bits: (3, 1)
```

The first sample case counts 3 placements, and 3 modulo 6 is 3.

## Code

The first block reads the whole input once and converts digits by hand.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

The loop ends at EOF, so no case triggers a read. The scan costs one pass over the input bytes.

The scanner keeps one position in that single buffer.

```nim
var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

proc skipSpace(data: string, position: var int) =
  while position < data.len and (data[position] == ' ' or data[position] == '\n' or
      data[position] == '\r' or data[position] == '\t'):
    position += 1
```

nextInt skips past the newline before a binary string. skipSpace then lands on the first character of that string. Both use scanPos, so no token is allocated.

One output buffer collects the answers.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

flushBlockBytes is 256 KiB. The buffer reuses its storage after each flush.

The case loop reads three numbers and walks the binary string from the low bit.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let weightCount = nextInt(inputData, scanPos)
  let bitLength = nextInt(inputData, scanPos)
  let modulus = nextInt(inputData, scanPos)
  skipSpace(inputData, scanPos)
  var countZero = 1 mod modulus
  var countOne = 0
  for i in 0..<bitLength:
    let j = scanPos + bitLength - 1 - i
    if inputData[j] == '1':
      countOne = (countZero + countOne) mod modulus
    else:
      countZero = (countZero + countOne) mod modulus
  scanPos += bitLength
  countZero = (countZero + (weightCount - bitLength) * countOne) mod modulus
  appendOutput($countZero)
  outputBuffer.add '\n'
```

The loop runs caseCount times. Index j falls to scanPos at the last character, so no bit is missed. The product folds all N - L high zero bits into one update.

A final write clears the tail.

```nim
stdout.write outputBuffer
outputBuffer.setLen 0
```

No stream write happens inside the bit loop.

## Complexity

Reading costs O(total input bytes) time and space for inputData. Each case costs O(L) time and O(1) extra space, since the two counters never grow. The output buffer adds O(flushBlockBytes) space. The whole run costs O(total input bytes) time, because the bit lengths sum to at most the input size.

A brute-force search tries 3^N placements per case and cannot finish for large N.
