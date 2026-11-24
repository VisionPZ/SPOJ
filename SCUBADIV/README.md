## Problem

The diver needs set amounts of oxygen and nitrogen for each trip. Each test case gives those amounts and a list of cylinders with gas volumes and a weight. Pick each cylinder at most once, meet both amounts, and print the smallest total weight on one line per case.

| Quantity | Bound |
| --- | --- |
| Oxygen needed | 1 to 21 litres |
| Nitrogen needed | 1 to 79 litres |
| Cylinders per case | 1 to 1000 |
| Gas in one cylinder | 1 to 21 oxygen, 1 to 79 nitrogen litres |
| Weight of one cylinder | 1 to 800 decagrams |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

The two gas ranges bound the whole search table.

## Idea

Use a 0/1 knapsack (each cylinder is used once) over the two gas amounts. Each cell stores the lightest way to reach one oxygen amount and one nitrogen amount, both capped at the demand. One cylinder costs one pass over at most 22 times 80 cells, while listing all subsets would be exponential.

## Why It Works

Capping a partial gas amount at the demand is safe. Extra gas never helps a later cylinder, so two states that cap to the same pair have the same future choices.

Both indexes walk down to zero. Every write lands on a cell with equal or larger indexes, so the current cylinder cannot be read again during its pass.

`impossibleWeight` exceeds any real total: at most 1000 cylinders weigh 800 each. Unreachable cells therefore lose every comparison.

The generator prints this trace for demand (2, 2) with cylinders (1, 2, 10), (2, 1, 10), and (1, 1, 15).

| Cylinder | New state | New weight | Best at (2, 2) |
| --- | --- | --- | --- |
| 1: (1, 2, 10) | (1, 2) | 10 | unreachable |
| 2: (2, 1, 10) | (2, 1) | 10 | 20 |
| 3: (1, 1, 15) | (1, 1) | 15 | 20 |

The third cylinder cannot lower the 20 stored at the target.

## Code

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

One read loop fills `inputData`, and `nextInt` skips the blank lines between cases. `flushBlockBytes` caps memory during output. The scanner touches each input byte a constant number of times.

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

Each case clears `(oxygenDemand + 1) * nitrogenStride` cells, then marks amount zero free. The fixed array avoids a per-case allocation. Reset cost is at most 22 times 80 cells.

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

Both loops run from the demand down to zero, which keeps each cylinder single use. The two cap lines prevent an out-of-bounds cell. Work is at most 1000 times 22 times 80 comparisons per case.

```nim
stdout.write outputBuffer
outputBuffer.setLen 0
```

One final write emits the remaining answer text.

## Complexity

Reading and scanning take O(B) time for B input bytes. The DP takes O(n * t * a) time per case, at most 1000 x 22 x 80 steps. Output takes O(c) time for c cases. Total space is O(t * a) for the table plus O(B) for input. Trying every subset takes O(2^n) time per case.
