<https://www.spoj.com/problems/AKVOD06/>

## Problem

Cartman and Butters take turns removing money from boxes. A move takes K units from one box, where K lies between 1 and that box's current cap, and the cap then becomes K. The player with no legal move loses.

Input starts with T. Each case gives N and Z, then N amounts. Z is the starting cap of every box. Output prints Cartman when the first player wins, and Butters otherwise.

| item | bound |
|---|---|
| test cases T | 1 to 100 |
| boxes N | 1 to 50 |
| starting cap Z | 1 to 10000 |
| money per box | 1 to 1000 |
| judge limit | 1000 ms, 1536 MB |

A box ends when its money reaches zero. The amounts taken from one box form a non-increasing sequence.

Sample input:

```
4
1 1
2
2 2
3 3
4 8
3 8 5 10
5 10
8 5 10 20 15
```

Sample output:

```
Butters
Butters
Cartman
Cartman
```

## Idea

Each box acts like a Nim heap with a value that depends on money and cap, like a pile whose size shrinks under a rule. Compute that value once for every legal money and cap pair. XOR the values of all boxes; a nonzero total means the first player wins. A fresh search per move would revisit the same states again and again.

## Why It Works

1. A move from state (money, cap) takes K, giving state (money-K, K).
2. The Grundy value of a state is the mex of the values reachable in one move.
3. A state with zero money has value zero.
4. When cap exceeds money, the effective cap equals money.
5. For fixed money, caps grow one at a time, so each new cap adds one reachable value to the previous set.
6. XOR combines independent boxes, and a zero total marks a losing position.

| term | meaning |
|---|---|
| `grundyValues` | table indexed by money and effective cap |
| `seenValues` | reachable values for one money while caps grow |
| `currentMex` | smallest value not yet reachable |
| `nimTotal` | XOR of all box values in one case |
| `initialCap` | starting cap Z |

For the sample case with two boxes of 3 and cap 2, the first box has value mex(0, 1) = 2. Both boxes give 2, and 2 xor 2 is 0, so Butters wins. For the case with cap 8 and amounts 3, 8, 5, 10, the values are 2, 4, 3, 4, so the XOR is nonzero and Cartman wins. The table stops at 1000 because no box holds more money.

## Code

**Input and scanner.** The program reads every line once and parses integers directly.

```nim
const flushBlockBytes = 1 shl 17
const maxMoney = 1000

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

The constant bounds the money range.
The scanner ignores spaces and line breaks.
Each digit adds to the current integer.

**Grundy table.** Money grows outer, and the cap grows inner with a running mex.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var grundyValues = newSeq[seq[int]](maxMoney + 1)
for moneyValue in 0 .. maxMoney:
  grundyValues[moneyValue] = newSeq[int](moneyValue + 1)
for moneyValue in 1 .. maxMoney:
  var seenValues: array[maxMoney + 4, bool]
  for valueIndex in 0 .. maxMoney + 3:
    seenValues[valueIndex] = false
  var currentMex = 0
  for capValue in 1 .. moneyValue:
    let remainingMoney = moneyValue - capValue
    let previousValue = grundyValues[remainingMoney][min(capValue, remainingMoney)]
    seenValues[previousValue] = true
    while seenValues[currentMex]:
      currentMex += 1
    grundyValues[moneyValue][capValue] = currentMex
```

Each cap adds exactly one new reachable value.
The mex advances only while values are present.
A cap above money is clipped when the box is read.

**Case answers.** Every box contributes one table value to the XOR.

```nim
let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let boxCount = nextInt(inputData, scanPos)
  let initialCap = nextInt(inputData, scanPos)
  var nimTotal = 0
  for boxIndex in 0 .. boxCount - 1:
    let moneyInside = nextInt(inputData, scanPos)
    let useCap = min(initialCap, moneyInside)
    nimTotal = nimTotal xor grundyValues[moneyInside][useCap]
  if nimTotal != 0:
    appendOutput("Cartman\n")
  else:
    appendOutput("Butters\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The clipped cap indexes the table safely.
One line per case names the winner.
The buffer flushes once at the end.

## Complexity

The table visits each money value once and grows its cap once per step.

| phase | time | space |
|---|---|---|
| read input | one scan of all tokens | one input string |
| build values | sum over money of money steps | triangular table |
| answer cases | one lookup per box | none extra |

| measure | Big O |
|---|---|
| time per case | O(N) |
| preprocessing | O(Amax^2) |
| space | O(Amax^2) |

Searching move trees for every box would revisit many identical states. The shared table removes that repeated work.
