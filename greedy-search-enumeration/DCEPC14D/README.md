# DCEPC14D — Finding GP (SPOJ)

<https://www.spoj.com/problems/DCEPC14D/>

## Problem

Count subsets of at least two array positions whose values form a geometric progression with an integral common ratio. Count subsets by position, so equal values give several copies of the same progression. Print the count modulo 1000000007.

The first input line holds N. The second line holds N integers. A suffix is a progression when its sorted values are v, v times R, v times R squared, and so on for an integer ratio R. Ratio one is allowed and uses equal values.

| Item | Bound |
|---|---|
| Array length N | 1 to 100000 |
| Array value | 1 to 1000000 |
| Judge limit | 600 ms, 1536 MB |

The large array rules out enumerating subsets; the bounded value range makes chains of multiples practical.

Sample input:

```
7
2 4 4 2 8 16 8
```

The sample repeats values two, four, and eight to exercise duplicate counting.

Sample output:

```
41
```

The output is the subset count after grouping by common ratio.

## Idea

Counting progressions is like counting runs of dominoes placed end to end along a row of values. Each run starts at a value whose predecessor by the ratio is absent, then extends while the next multiple exists.

The algorithm stores a frequency for each value. Ratio one contributes every subset of equal values of size at least two. For each larger ratio, it walks each maximal chain of multiples and sums the products of frequencies over all contiguous runs of length two or more. A rolling suffix sum gives each run in constant time. Checking all subsets would take two to the N steps; the chain walk touches far fewer states.

Takeaway: group by value, walk chains of multiples, and add each run once.

## Why It Works

1. A subset with ratio one must use equal values, and any two or more copies form a progression.
2. If a value has frequency f, ratio one contributes 2 to the f minus one minus f subsets.
3. For ratio R at least two, a progression is a contiguous slice of the chain v, vR, vR squared, and so on.
4. A chain is counted only from value v when v divided by R is absent, which prevents double counting.
5. The product of frequencies in a run counts all position choices for that run.
6. A rolling sum of products over runs ending at the previous cell gives the next run total in one step.

| Term | Meaning |
|---|---|
| `frequencies` | number of array positions holding each value |
| `powersOfTwo` | two to the f modulo the modulus, for ratio one |
| `suffixProducts` | sum of run products ending at the previous chain value |
| `chainTotal` | all run products for one chain |
| `answer` | accumulated count modulo the modulus |

The table connects duplicate counts and chain products to the printed total.

A script-generated trace of the sample:

```
sample by ratio: {1: 3, 2: 30, 4: 6, 8: 2} total 41
freq 2: total 0, suffix 2
freq 2: total 4, suffix 6
freq 2: total 16, suffix 14
freq 1: total 30, suffix 15
```

The four ratio groups add to the sample answer, and the chain trace reproduces the ratio two group.

All products are reduced modulo the same modulus. The rolling sum stays below the modulus after each step, so a 64-bit product holds the multiplication safely.

## Code

**Input and helpers.** One pass loads the array, and powers of two support ratio one.

```nim
const flushBlockBytes = 1 shl 17
const maxArrayValue = 1000000
const modulusValue: int64 = 1000000007

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

let countNumbers = nextInt(inputData, scanPos)
var frequencies = newSeq[int](maxArrayValue + 1)
var maxValue = 0
for numberIndex in 0 .. countNumbers - 1:
  let value = nextInt(inputData, scanPos)
  frequencies[value] = frequencies[value] + 1
  if value > maxValue:
    maxValue = value

var powersOfTwo = newSeq[int64](countNumbers + 1)
powersOfTwo[0] = 1
for powerIndex in 1 .. countNumbers:
  powersOfTwo[powerIndex] = (powersOfTwo[powerIndex - 1] * 2) mod modulusValue
```

`maxArrayValue` bounds the frequency table. `powersOfTwo` is built once up to the array length. This block runs once.

**Chain sweep and output.** Each base value tests each ratio whose first multiple fits.

```nim
var answer: int64 = 0
for baseValue in 1 .. maxValue:
  let multiplicity = frequencies[baseValue]
  if multiplicity == 0:
    continue
  let sameValueWays = (powersOfTwo[multiplicity] - 1 - int64(multiplicity) +
                       2 * modulusValue) mod modulusValue
  answer = (answer + sameValueWays) mod modulusValue
  var ratio = 2
  while baseValue <= maxValue div ratio:
    if baseValue mod ratio == 0 and frequencies[baseValue div ratio] > 0:
      ratio += 1
      continue
    var currentValue = baseValue
    var suffixProducts: int64 = 0
    var chainTotal: int64 = 0
    while currentValue <= maxValue and frequencies[currentValue] > 0:
      let currentFrequency = int64(frequencies[currentValue])
      chainTotal = (chainTotal + currentFrequency * suffixProducts) mod modulusValue
      suffixProducts = currentFrequency * (suffixProducts + 1) mod modulusValue
      if currentValue > maxValue div ratio:
        break
      currentValue = currentValue * ratio
    answer = (answer + chainTotal) mod modulusValue
    ratio += 1

appendOutput($answer)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The predecessor check skips chains already counted from a smaller base. The guard before multiplication avoids values above the table. One final flush writes the single answer.

## Complexity

Frequency collection and power precomputation cover the array once. The chain sweep visits only base values that occur and ratios whose product fits.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over all numbers | one input string |
| Frequency table | one increment per number | bounded value array |
| Ratio one | one formula per occurring value | powers array |
| Chain sweep | one rolling step per chain cell | a few integers |
| Output | one line | block buffer |

The phase table shows that the cost follows the value range and the chains, not the number of subsets.

| Measure | Big O |
|---|---|
| Time | O(N plus maxValue plus S), S is the visited chain steps |
| Space | O(N plus maxValue) |

Enumerating all subsets would cost two to the N, which is impossible for the largest array. Chain counting reaches the same total in a small number of arithmetic steps.
