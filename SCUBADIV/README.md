# SCUBADIV — Scuba diver (SPOJ)
<https://www.spoj.com/problems/SCUBADIV/>

## Problem

A scuba diver needs fixed amounts of oxygen and nitrogen, and each available cylinder holds some of each gas with a given weight. Choose cylinders meeting both needs with the smallest total weight.

Input: an integer c, then c cases separated by blank lines. Each case gives oxygen t and nitrogen a, then cylinder count n, then n lines with oxygen, nitrogen and weight. Output: one integer per case, the minimum total weight.

The statement sets these bounds.

| Item | Bound |
| --- | --- |
| Oxygen needed t | 1 to 21 liters |
| Nitrogen needed a | 1 to 79 liters |
| Cylinders n | 1 to 1000 |
| Gas per cylinder | up to 21 oxygen and 79 nitrogen |
| Weight per cylinder | 1 to 800 decagrams |
| Judge time limit | 5000 ms |
| Judge memory limit | 1536 MB |

The two gas ranges bound the whole table.

The sample input:

```
1
5 60
5
3 36 120
10 25 129
5 50 250
1 45 130
4 20 119
```

The sample output:

```
249
```

## Idea

Pack a knapsack with two measurements at once, like fitting items into a box with both a width and a height limit. Each cell stores the lightest way to reach one oxygen amount and one nitrogen amount. Both amounts cap at the demand.

The program uses 0/1 knapsack, so each cylinder is taken at most once. One cylinder costs one pass over at most 22 times 80 cells. Indexes walk downward, so a write never feeds the same cylinder again. Listing all subsets would cost 2 to the n, which is impossible for 1000 cylinders.

Two capped indexes keep the table small.

## Why It Works

Four facts carry the program.

1. Capping a partial gas amount at the demand is safe. Extra gas never helps a later cylinder, so two states that cap to the same pair have the same future choices.
2. Both indexes walk down to zero. Every write lands on a cell with equal or larger indexes, so the current cylinder cannot be read again during its pass.
3. `impossibleWeight` exceeds any real total, since 1000 cylinders weigh at most 800 each. Unreachable cells therefore lose every comparison.
4. The answer sits at the demand cell, because larger amounts were capped into it.

Each term has one job.

| Term | Meaning |
| --- | --- |
| `bestWeight` | lightest total reaching a capped gas pair |
| `nitrogenStride` | row width of 80 cells |
| `oxygenDemand` | target oxygen amount |
| `nitrogenDemand` | target nitrogen amount |

Every cell holds an integer weight, so no rounding occurs.

A script traces demand 2, 2 with cylinders 1, 2, 10; 2, 1, 10; and 1, 1, 15.

```text
cylinder 1 (1,2,10): state (1,2) weight 10, target unreachable
cylinder 2 (2,1,10): state (2,1) weight 10, target 20
cylinder 3 (1,1,15): state (1,1) weight 15, target stays 20
```

The third cylinder cannot lower the 20 stored at the target.

## Code

**Constants, reader and scanner.** One buffer holds the whole stream.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const nitrogenStride = 80
const maxOxygen = 21
const maxCells = (maxOxygen + 1) * nitrogenStride
const impossibleWeight = 1 shl 29

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

`nextInt` skips the blank lines between cases. `flushBlockBytes` caps memory during output. The scanner touches each input byte a constant number of times.

**Table setup.** Each case clears only the cells it can reach.

```nim
var bestWeight: array[maxCells, int]

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let oxygenDemand = nextInt(inputData, scanPos)
  let nitrogenDemand = nextInt(inputData, scanPos)
  let cylinderCount = nextInt(inputData, scanPos)
  for cellIndex in 0..<(oxygenDemand + 1) * nitrogenStride:
    bestWeight[cellIndex] = impossibleWeight
  bestWeight[0] = 0
```

The clear covers `(oxygenDemand + 1) * nitrogenStride` cells. Cell zero is free, since no gas costs nothing. The fixed array avoids a per-case allocation.

**Knapsack pass.** Both loops run from the demand down to zero.

```nim
  for cylinderIndex in 0..<cylinderCount:
    let cylinderOxygen = nextInt(inputData, scanPos)
    let cylinderNitrogen = nextInt(inputData, scanPos)
    let cylinderWeight = nextInt(inputData, scanPos)
    var oxygenIndex = oxygenDemand
    while oxygenIndex >= 0:
      var nitrogenIndex = nitrogenDemand
      while nitrogenIndex >= 0:
        let currentIndex = oxygenIndex * nitrogenStride + nitrogenIndex
        let currentWeight = bestWeight[currentIndex]
        if currentWeight < impossibleWeight:
          var newOxygen = oxygenIndex + cylinderOxygen
          if newOxygen > oxygenDemand:
            newOxygen = oxygenDemand
          var newNitrogen = nitrogenIndex + cylinderNitrogen
          if newNitrogen > nitrogenDemand:
            newNitrogen = nitrogenDemand
          let candidateWeight = currentWeight + cylinderWeight
          let targetIndex = newOxygen * nitrogenStride + newNitrogen
          if candidateWeight < bestWeight[targetIndex]:
            bestWeight[targetIndex] = candidateWeight
        nitrogenIndex -= 1
      oxygenIndex -= 1
  appendOutput($(bestWeight[oxygenDemand * nitrogenStride + nitrogenDemand]))
  outputBuffer.add '\n'
```

Downward indexes keep each cylinder single use. The two cap lines prevent an out-of-bounds cell. Work is at most 1000 times 22 times 80 comparisons per case.

**Final write.** The tail leaves the buffer here.

```nim
stdout.write outputBuffer
outputBuffer.setLen 0
```

One write emits the remaining answer text. No write happens inside the cylinder loop.

## Complexity

The table pass dominates each case.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | O(B) for B bytes | B bytes |
| Table clear | O(t times a) per case | fixed array |
| Cylinder pass | O(n times t times a) per case | O(t times a) |
| Output | O(c) lines | one block |

Here t is at most 21 and a is at most 79, so the table has 1760 cells.

| Measure | Big O |
| --- | --- |
| Time | O(n times t times a) per case |
| Space | O(t times a) working, O(B) input |

Trying every subset would cost O(2 to the n) time per case.
