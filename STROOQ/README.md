<https://www.spoj.com/problems/STROOQ/>

## Problem

For each test case, k is given and the task is to find the kth positive integer whose cube ends in the digits 888. Numbers are counted from one, and the result is below 2 to the power 63.

| item | bound |
|---|---|
| test cases | 1 to 100000 |
| rank k | 1 to 2000000000000 |
| answer | less than 2 to the power 63 |
| judge limit | 1000 ms, 1536 MB |

The answer grows almost linearly with k, so each case must be solved in constant time.

Sample input:

```
1
1
```

Sample output:

```
192
```

## Idea

Cube endings repeat every 1000, like a clock face repeating each hour. Only four residues in one period work: 192, 442, 692, and 942. Rank k selects block (k minus one) divided by four and one residue from that block.

## Why It Works

1. Adding 1000 to a number does not change its cube modulo 1000.
2. Exactly four residues modulo 1000 have cubes ending in 888.
3. Those residues are 192, 442, 692, and 942 in increasing order.
4. Rank k chooses block (k-1)/4 and residue index (k-1)%4.
5. Adding the block offset yields the kth smallest valid number.

| term | meaning |
|---|---|
| `residuesPerBlock` | number of valid endings per 1000 integers |
| `blockSpan` | period of the cube endings, equal to 1000 |
| `firstResidue` | smallest valid ending, equal to 192 |
| `residueGap` | spacing between endings, equal to 250 |
| `rank` | the input value k |

A fixed number of arithmetic steps replaces a search over billions of integers.

## Code

**Constants and scanner.** Four residues repeat inside every block of 1000.

```nim
const flushBlockBytes = 1 shl 17
const residuesPerBlock = 4
const blockSpan = 1000
const firstResidue = 192
const residueGap = 250

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

The residue gap is 250, so the four values fit one block.
The hand scanner reads one integer at a time.
All ranks fit in a 64-bit integer.

**Rank to number.** Division and modulo locate the answer directly.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rank = nextInt(inputData, scanPos)
  let blockIndex = (rank - 1) div residuesPerBlock
  let residueIndex = (rank - 1) mod residuesPerBlock
  let answer = blockIndex * blockSpan + firstResidue + residueIndex * residueGap
  appendOutput($answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The block index contributes whole thousands.
The residue index adds one of the four endings.
Output is flushed in blocks of 128 KiB.

## Complexity

Every test case performs a constant number of operations.

| phase | time | space |
|---|---|---|
| input read | one pass over all tokens | one input string |
| rank mapping | constant arithmetic per case | a few integers |
| output | one write per 128 KiB block | block buffer |

| measure | Big O |
|---|---|
| time | O(1) per test case |
| space | O(1) besides the input buffer |

Testing consecutive cubes would cost O(k) per case and cannot finish for large k.

