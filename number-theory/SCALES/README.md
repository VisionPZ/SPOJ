# SCALES — Balancing the Stone (SPOJ)
<https://www.spoj.com/problems/SCALES/>

## Problem

A stone of weight W sits on one pan of a balance, with N weights of masses 1, 2, 4, up to 2^(N-1). Count the ways to place weights on either pan that balance the stone, modulo D.

Input: an integer t, then t cases. Each case gives N, L and D on one line, followed by a line holding exactly L binary digits for W. Output: one integer per case, the count modulo D.

The bounds come from the statement.

| Item | Bound |
| --- | --- |
| Weights N | 1 to 1000000 |
| Binary length L | 1 to N |
| Modulus D | 2 to 100 |
| Test cases | bounded by input size |
| Judge time limit | 7000 ms |
| Judge memory limit | 1536 MB |

Only two carry states matter, so each bit costs a few additions.

The sample input:

```
2
6 4 6
1000
6 6 100
100110
```

The sample output:

```
3
5
```

## Idea

Treat each weight like a signed digit and carry the leftover into the next column, the way you carry in paper addition. The signed digits are minus 1, 0 and 1, one per weight. Balancing means the signed binary sum equals W.

The program walks W from its low bit to its high bit. Two counters hold how many placements reach each carry state. A one bit updates one counter, and a zero bit updates the other. The leftover high bits are all zero, so one multiplication folds them in. Each bit costs one comparison and a few modular additions, while a search over all placements would try 3 to the N options.

Two counters replace an exponential search.

## Why It Works

Four facts carry the program.

1. Give each weight a signed digit: plus 1 for the left pan, minus 1 for the right pan, 0 for aside. The signed sum of digit times power of two must equal W.
2. After i low bits, the partial signed sum differs from the low i bits of W by c times 2 to the i. Here c is the carry, and c stays 0 or minus 1.
3. For a zero bit, the two counters merge into `countZero`. For a one bit, they merge into `countOne`. Each merge is one modular addition.
4. The N minus L high bits of W are zero. Each such bit adds `countOne` to `countZero`, so the program uses one product.

Each term has one job.

| Term | Meaning |
| --- | --- |
| `countZero` | number of placements reaching carry 0 |
| `countOne` | number of placements reaching carry minus 1 |
| `bitLength` | number of supplied binary digits L |
| `weightCount` | total weights N |

Every counter stays below the modulus because each update takes a remainder.

A script walks the string 1000 from the low bit toward the high bit.

```text
start (countZero, countOne) = (1, 0)
bit 0 = 0: (1, 0)
bit 1 = 0: (1, 0)
bit 2 = 0: (1, 0)
bit 3 = 1: (1, 1)
two folded high bits: (3, 1)
answer 3 mod 6 = 3
```

The answer is 3, which matches the first sample case. Modular reduction at every step keeps values small.

## Code

**Constants and input buffer.** One loop collects the whole stream.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

The loop stops at end of file, so no case triggers a read. Added newlines preserve token boundaries. The cost is one pass over the input bytes.

**Integer scanner and space skipper.** Both use one scan position.

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

`nextInt` skips the newline before a binary string. `skipSpace` then lands on the first digit. No token is copied, so parsing allocates nothing.

**Output helper.** One buffer collects every answer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The flush threshold is 256 KiB. `setLen 0` reuses the same storage after each write.

**Case loop.** The bit walk runs from the low bit upward.

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

Index `j` starts at the last character and falls to `scanPos`, so no bit is missed. The loop runs `bitLength` times. The final product folds all N minus L high zero bits into one update.

**Final write.** The tail leaves the buffer here.

```nim
stdout.write outputBuffer
outputBuffer.setLen 0
```

No stream write happens inside the bit loop. One final write emits the remaining bytes.

## Complexity

Reading dominates the input side, and the bit walk dominates each case.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over B bytes | B bytes |
| One case | O(L) bit steps | O(1) counters |
| Output | one write per 256 KiB block | one block |
| Total | O(B), since L sums to at most B | O(B) |

B is the number of input bytes, and L is at most 1 000 000.

| Measure | Big O |
| --- | --- |
| Time | O(B) overall, O(L) per case |
| Space | O(B) for input, O(1) working state |

A search over 3 to the N placements cannot finish for large N.
