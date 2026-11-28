# WORDEQ — Word equations (SPOJ)

<https://www.spoj.com/problems/WORDEQ/>

## Problem

The input gives two strings built from bits and variables, each variable having a fixed word length. Count the assignments of binary words that make both sides equal.

Input starts with `t`, then cases separated by blank lines. Each case has six lines: the count `k`, the `k` lengths, the left token count, and the left word. The last two lines give the right token count and the right word. Variables are the first `k` lowercase letters. Each side expands to at most 10000 symbols. Output one count per case.

The expanded length caps both the work and the size of the answer.

| Quantity | Bound |
| --- | --- |
| Test cases | not bounded by the statement |
| Variables `k` | 0 to 26 |
| Expanded length per side | at most 10000 |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

Variables of length `L` contribute `L` independent binary choices.

The sample input and output follow verbatim.

```
1
5
4 2 4 4 2
5
1bad1
4
acbe
```

```
16
```

## Idea

Treat each bit of each variable as a separate cell, then merge cells that must match. Think of connecting dots that must carry the same number, then counting the free dots left over.

The program expands both words into lists of bit codes. Union-find merges the codes at matching positions. A digit fixes the paired code to zero or one. If a component receives both values, the case has no solution. Otherwise each free component doubles the answer, so the program prints `2^freeCount`.

Trying every word assignment takes exponential time in the variable count. Counting components gives the answer with one union pass.

Union-find turns assignments into a component count.

## Why It Works

Four facts justify the counting.

1. A variable of length `L` contributes `L` independent bits, each with its own code. A digit at one position fixes the opposite code to zero or one.
2. Two variable bits at the same position must carry the same value. A merge joins their components. A component fixed to both digit values has no assignment.
3. Components are independent, so each free one contributes two choices. The answer is `2^freeCount`, where the count includes only root components with no fixed value.
4. The expanded lengths must match. If they differ, no assignment can work.

The table names the bit codes.

| Term | Meaning |
| --- | --- |
| `totalBits` | sum of all variable lengths |
| `variableBase[i]` | first bit code of variable `i` |
| `totalBits + digit` | code of a fixed digit, above every variable bit |
| `bitFixed[root]` | holds minus one, zero, or one for a root |
| `freeCount` | roots with no fixed value |

The generator searches the sample equation and prints this trace.

```
classes=6 fixed=2 free=4 answer=2^4=16
```

Two sample digits pin two components, and four components stay free.

## Code

**Input setup.** Constants, bulk input, scanner, and writer set up parsing.

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

The loop reads every input line into one buffer. The scanner skips whitespace, so blank lines need no branch. The writer flushes at 256 KiB.

**Union-find.** Union-find fixes and merges bit codes.

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

`findRoot` halves parent links until it reaches the root. `fixBit` rejects a component receiving both digit values. `mergeBits` carries one fixed value into the merged component.

**Expansion helpers.** Expansion and big-number printing complete the helpers.

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

`buildBits` expands one word into descriptor codes. A digit code sits above every variable bit. `powerText` doubles base-10^18 limbs exponent times, and a repeated exponent reuses the cached string.

**Case driver.** The driver compares the two descriptor arrays position by position.

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

The case loop gives each bit its own root before comparing. Digit pairs get `fixBit`, and variable pairs get `mergeBits`. The final write empties the remaining buffer.

## Complexity

Expansion and union work scale with the expanded length.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | O(input bytes) | one input string |
| Expand two words | O(N) | O(N) codes |
| Union-find | O(M alpha(M)) | O(M) parent links |
| Print 2^e | O(e · digits) | O(digits) limbs |

`N` is the expanded length and `M` is the total variable bits.

The totals use those two sizes.

| Measure | Big O |
| --- | --- |
| Time | O(N + M alpha(M) + e · digits) |
| Space | O(N + M) |

Trying every assignment takes `O(2^M · N)` time.
