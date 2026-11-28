# LISA — Pocket Money (SPOJ)

<https://www.spoj.com/problems/LISA/>

## Problem

Place brackets in a row of digits joined by `+` and `*` to maximize and minimize the result. Print both values.

Input: the count `k`, then `k` lines. Each line holds digits from 0 to 9 separated by `+` or `*`, with no spaces. Output: one line per case, with the largest value first and the smallest value second, separated by one space.

The bounds from the statement:

| Item | Bound |
|---|---|
| Test cases | `k < 5000` |
| Expression length | fewer than 100 characters |
| Digits per expression | at most 50 |
| Result value | below `2^64` |
| Judge limit | 32 s, 1536 MB |

Line length fixes the table size, and the result bound fixes the integer width.

The sample case:

```
1
1+2*3+4*5
```

```
105 27
```

## Idea

Try every grouping, but remember only the best value for each piece. This is like filling a table of shortest routes between stops, then reusing short routes to build longer ones.

The algorithm is matrix-chain dynamic programming. For each consecutive run of digits, keep the smallest and largest value. A split at one operator combines two shorter runs. Each state checks at most 49 splits, so one case takes cubic time in the digit count.

Trying every bracketing on its own is slower. A row of 50 digits has billions of binary trees, while the table holds only 2500 states.

Keep two extremes per piece and combine them once per split.

## Why It Works

Three facts carry the proof.

1. Every digit and combined value is non-negative. Products grow with their factors. The smallest product uses the two smallest values, and the largest product uses the two largest values.
2. A full bracketing splits at exactly one top operator. Its two sides are independent, so their extremes decide every candidate value.
3. The table fills by increasing length. Every shorter piece is ready before a longer piece uses it.

Each candidate comes from one split and one operator:

| Term | Meaning |
|---|---|
| `split` | position of the operator that becomes the outermost one |
| `leftMin` | smallest value before `split` |
| `leftMax` | largest value before `split` |
| `rightMin` | smallest value after `split` |
| `rightMax` | largest value after `split` |
| `leftMin + rightMin` | smallest candidate when the operator is `+` |
| `leftMax + rightMax` | largest candidate when the operator is `+` |
| `leftMin * rightMin` | smallest candidate when the operator is `*` |
| `leftMax * rightMax` | largest candidate when the operator is `*` |

The program checks every split and keeps the two extreme candidates.

A script traces the sample expression. It lists each top-level split and the candidate extremes:

```
expr    1+2*3+4*5
digits  1 2 3 4 5
ops     + * + *
split 1 op +  left max   1 min   1  right max  70 min  26  cand max  71 min  27
split 2 op *  left max   3 min   3  right max  35 min  23  cand max 105 min  69
split 3 op +  left max   9 min   7  right max  20 min  20  cand max  29 min  27
split 4 op *  left max  21 min  11  right max   5 min   5  cand max 105 min  55
answer  max 105  min 27
```

The second and fourth splits reach 105, and the first and third reach 27.

## Code

**Constants.** Fixed sizes and the value used before any candidate exists.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxDigitCount = 64
const tableSize = maxDigitCount * maxDigitCount
const largestValue = 18446744073709551615'u64
```

The 64-slot limit covers the 50 digits a legal line holds. The sentinel is the largest 64-bit value, so any real candidate beats it. The block size keeps writes around 256 KiB.

**Count reader.** Reads the case count from the single input buffer.

```nim
proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

The scan position survives across calls, so no token list is built. Each byte becomes a digit through `firstDigitValue`. The loop stops at the first non-digit.

**Expression reader.** Returns one non-whitespace expression from the same buffer.

```nim
proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let tokenStart = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  return data[tokenStart .. pos - 1]
```

Expressions hold `+` and `*`, so a digit scanner cannot read them. The slice starts after the skipped whitespace. The scan position advances to the next token.

**Range table.** Fills both extremes for every consecutive run of digits.

```nim
proc evaluateExpression(expression: string, minTable: var array[tableSize, uint64], maxTable: var array[tableSize, uint64]): (uint64, uint64) =
  var digits: array[maxDigitCount, uint64]
  var operators: array[maxDigitCount, char]
  var digitCount = 0
  var charPos = 0
  while charPos < expression.len:
    let currentChar = expression[charPos]
    if currentChar >= '0' and currentChar <= '9':
      digits[digitCount] = uint64(int(currentChar) - firstDigitValue)
      digitCount += 1
    else:
      operators[digitCount - 1] = currentChar
    charPos += 1

  for length in 1 .. digitCount:
    for left in 0 .. digitCount - length:
      let right = left + length - 1
      let tableIndex = left * maxDigitCount + right
      if length == 1:
        minTable[tableIndex] = digits[left]
        maxTable[tableIndex] = digits[left]
      else:
        var smallest = largestValue
        var largest = 0'u64
        for split in left .. right - 1:
          let splitOperator = operators[split]
          let leftMin = minTable[left * maxDigitCount + split]
          let leftMax = maxTable[left * maxDigitCount + split]
          let rightMin = minTable[(split + 1) * maxDigitCount + right]
          let rightMax = maxTable[(split + 1) * maxDigitCount + right]
          if splitOperator == '+':
            let candidateMin = leftMin + rightMin
            let candidateMax = leftMax + rightMax
            if candidateMin < smallest: smallest = candidateMin
            if candidateMax > largest: largest = candidateMax
          else:
            let candidateMin = leftMin * rightMin
            let candidateMax = leftMax * rightMax
            if candidateMin < smallest: smallest = candidateMin
            if candidateMax > largest: largest = candidateMax
        minTable[tableIndex] = smallest
        maxTable[tableIndex] = largest

  return (minTable[digitCount - 1], maxTable[digitCount - 1])
```

Length runs from one to `digitCount`, so shorter pieces are ready first. Each `split` chooses one operator as the outermost one. Addition and multiplication both use like extremes because values stay non-negative. The flat index is `left * maxDigitCount + right`.

**Driver.** Reads stdin once, solves every case, and writes in blocks.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var minTable: array[tableSize, uint64]
var maxTable: array[tableSize, uint64]
var outputBuffer = ""

for caseIndex in 0 ..< caseCount:
  let expression = nextToken(inputData, scanPos)
  let (smallestResult, largestResult) = evaluateExpression(expression, minTable, maxTable)
  outputBuffer.add $(largestResult)
  outputBuffer.add ' '
  outputBuffer.add $(smallestResult)
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
```

Line reads append to one buffer, so no per-line parse cost remains. The two tables are allocated once and reused by every case. Each answer writes the largest value first. The last write flushes the tail.

## Complexity

The work splits into input, table filling, and output.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the input bytes | input bytes |
| Range table | 20 825 splits for 50 digits, per case | two flat tables |
| Output | one write per 256 KiB block | output block |

Table filling dominates, and input and output each scan their bytes once.

The overall asymptotic bounds:

| Measure | Big O |
|---|---|
| Time | O(k * d^3) for k cases and d digits |
| Space | O(d^2) for the two tables and the input |

Brute force visits Catalan(d) bracketings, which grow far faster than d^3. The table pays once per split instead of once per tree.
