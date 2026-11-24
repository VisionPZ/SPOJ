## Problem

An equation sets a word of digits and variables equal to another such word. Each variable stands for a binary word of a fixed length. Print how many assignments of those words make the equality hold.

The statement and judge page set these bounds:

| Quantity | Bound |
| --- | --- |
| Test cases | not bounded by the statement |
| Variables k | 0 to 26 |
| Expanded length per side | at most 10000 |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

The expanded length of 10000 caps both the work and the exponent of the answer.

## Idea

Union-find merges the variable bits that each position of the equation forces to be equal. A component fixed by a digit has one choice and a free component has two, so the program counts components instead of trying assignments. Cost per expanded position: one amortized union, then one decimal conversion of 2^freeCount at the end.

## Why It Works

Each variable of length L contributes L independent bits. A digit at one position fixes the bit at the other position to 0 or 1. Two variable bits at the same position share one component. A component fixed to both values has no assignment. Each free component can be chosen on its own, so the answer is 2^freeCount.

- `base[variable] + offset` is the index of one variable bit.
- `totalBits + digit` is the code of a fixed digit above every variable bit.
- `bitFixed[root]` holds -1, 0, or 1 for the component root.

The generator searches the sample graph and prints:

```
classes=6 fixed=2 free=4 answer=2^4=16
```

Two sample digits pin two components, and four components stay free.

## Code

```nim
const firstDigitValue = 48
const firstLetterValue = 97
const flushBlockBytes = 1 shl 18
const maxVariableCount = 26
const maxWordSize = 10000
const digitBase = int64(1000000000000000000)
const limbWidth = 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The loop reads every input line into one buffer. The scanner skips whitespace, so blank lines between cases need no special case. The writer flushes at 256 KiB and costs O(1) per line.

```nim
var variableLengths: array[0..maxVariableCount - 1, int]
var variableBase: array[0..maxVariableCount - 1, int]
var totalBits = 0
var bitParent = newSeq[int](maxWordSize + 2)
var bitFixed = newSeq[int](maxWordSize + 2)
var leftBits = newSeq[int](0)
var rightBits = newSeq[int](0)
var cachedExponent = -1
var cachedPower = ""

proc findRoot(bit: int): int =
  var node = bit
  while bitParent[node] != node:
    bitParent[node] = bitParent[bitParent[node]]
    node = bitParent[node]
  return node

proc fixBit(bit: int, value: int, possible: var bool) =
  let root = findRoot(bit)
  if bitFixed[root] == -1:
    bitFixed[root] = value
  elif bitFixed[root] != value:
    possible = false

proc mergeBits(firstBit: int, secondBit: int, possible: var bool) =
  let rootFirst = findRoot(firstBit)
  let rootSecond = findRoot(secondBit)
  if rootFirst == rootSecond: return
  let fixedFirst = bitFixed[rootFirst]
  let fixedSecond = bitFixed[rootSecond]
  if fixedFirst != -1 and fixedSecond != -1 and fixedFirst != fixedSecond:
    possible = false
    return
  bitParent[rootSecond] = rootFirst
  if fixedFirst == -1:
    bitFixed[rootFirst] = fixedSecond
```

`findRoot` halves parent links until it reaches the root. `fixBit` rejects a component that receives both digit values. `mergeBits` carries one fixed value into the merged component. The arrays hold at most 10000 bits and two digit codes.

```nim
proc buildBits(data: string, position: var int, tokenCount: int, bits: var seq[int]) =
  bits.setLen 0
  for i in 0..<tokenCount:
    while position < data.len and data[position] <= ' ':
      position += 1
    let tokenChar = data[position]
    position += 1
    if tokenChar == '0' or tokenChar == '1':
      bits.add(totalBits + int(tokenChar) - firstDigitValue)
    else:
      let variableIndex = int(tokenChar) - firstLetterValue
      let startBit = variableBase[variableIndex]
      for j in 0..<variableLengths[variableIndex]:
        bits.add(startBit + j)

proc powerText(exponent: int): string =
  var limbs = newSeq[int64](1)
  limbs[0] = 1
  for i in 0..<exponent:
    var carry = int64(0)
    for j in 0..<limbs.len:
      let doubled = limbs[j] * int64(2) + carry
      if doubled >= digitBase:
        limbs[j] = doubled - digitBase
        carry = int64(1)
      else:
        limbs[j] = doubled
        carry = int64(0)
    if carry != 0: limbs.add int64(1)
  var text = $limbs[limbs.len - 1]
  var j = limbs.len - 2
  while j >= 0:
    var limbText = $limbs[j]
    while limbText.len < limbWidth:
      limbText = "0" & limbText
    text.add limbText
    j -= 1
  return text
```

`buildBits` expands one word into descriptor codes over tokenCount tokens. The code `totalBits + digit` stays above every variable bit. `powerText` doubles base-10^18 limbs exponent times. A repeated exponent reuses the cached decimal string.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let variableCount = nextInt(inputData, scanPos)
  totalBits = 0
  for i in 0..<variableCount:
    variableLengths[i] = nextInt(inputData, scanPos)
    variableBase[i] = totalBits
    totalBits += variableLengths[i]
  if totalBits >= bitParent.len:
    bitParent.setLen(totalBits + 1)
    bitFixed.setLen(totalBits + 1)
  for i in 0..<totalBits:
    bitParent[i] = i
    bitFixed[i] = -1
  let leftTokenCount = nextInt(inputData, scanPos)
  buildBits(inputData, scanPos, leftTokenCount, leftBits)
  let rightTokenCount = nextInt(inputData, scanPos)
  buildBits(inputData, scanPos, rightTokenCount, rightBits)
  var possible = true
  if leftBits.len == rightBits.len:
    for i in 0..<leftBits.len:
      let leftCode = leftBits[i]
      let rightCode = rightBits[i]
      if leftCode >= totalBits:
        if rightCode >= totalBits:
          if leftCode != rightCode: possible = false
        else:
          fixBit(rightCode, leftCode - totalBits, possible)
      else:
        if rightCode >= totalBits:
          fixBit(leftCode, rightCode - totalBits, possible)
        else:
          mergeBits(leftCode, rightCode, possible)
  else:
    possible = false
  if not possible:
    appendOutput("0")
  else:
    var freeCount = 0
    for i in 0..<totalBits:
      if bitParent[i] == i and bitFixed[i] == -1:
        freeCount += 1
    if freeCount != cachedExponent:
      cachedPower = powerText(freeCount)
      cachedExponent = freeCount
    appendOutput(cachedPower)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The case loop reads lengths and gives each bit its own root. It compares the two descriptor arrays position by position. The final write empties the remaining buffer.

## Complexity

Reading and scanning take O(input bytes). Expanding two words takes O(N) time and O(N) space per case. Union-find takes O(M alpha(M)) time for M variable bits. Printing 2^e takes O(e times digits) with base-10^18 limbs. Total per case: O(N + M alpha(M) + e times digits) time and O(N + M) space, with e at most 10000. Trying every assignment takes O(2^M N) time.
