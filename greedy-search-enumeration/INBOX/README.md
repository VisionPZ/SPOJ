# INBOX — India in Box (SPOJ)

<https://www.spoj.com/problems/INBOX/>

## Problem

Split boxes into a group of K boxes and the remaining group. Each group's average is its weight sum divided by its cost sum. Minimize the sum of the two averages and print it to five decimal places.

Each test starts with N and K, followed by one weight and cost per box. A line containing only zero ends the input. Print one value per test.

| item | bound |
|---|---|
| boxes N | 1 to 100 |
| chosen boxes K | 1 to N-1 |
| weight and cost | 1 to 50 |
| judge limit | 1000 ms, 1536 MB |

Both groups are nonempty, so both cost sums are positive.

Sample input:

```
8 4
2 1
3 2
4 3
5 4
6 5
7 6
8 7
10 8
0
```

Sample output:

```
2.49845
```

## Idea

Think of filling two shopping bags with a fixed number of items, like balancing a scale. For a fixed cost sum, the average formula is linear in the chosen weight, so only the smallest and largest reachable weights matter.

A knapsack-style table records both extremes for each box count and cost sum. Checking every subset would be impossible for 100 boxes.

## Why It Works

1. Let y be the cost of the K-box group, and x its weight.
2. The objective is x/y + (W-x)/(C-y), with totals W and C fixed.
3. For fixed y, the coefficient of x is 1/y - 1/(C-y).
4. That coefficient is positive below C/2, so pick the smallest reachable x.
5. Above C/2 the coefficient is negative, so pick the largest reachable x.

| term | meaning |
|---|---|
| `minimumWeights` | smallest weight for each count and cost sum |
| `maximumWeights` | largest weight for each count and cost sum |
| `totalWeight` | weight of all boxes |
| `rowWidth` | number of cost columns in one count row |

Script-generated trace for the sample case:

| quantity | value |
|---|---|
| chosen boxes | 1, 3, 6, 7 |
| chosen weight | 21 |
| chosen cost | 17 |
| remaining weight | 24 |
| remaining cost | 19 |
| objective | 21/17 + 24/19 = 2.49845 |

The printed value matches the sample output.

## Code

**Input and buffered output.** A hand scanner reads box pairs, and a helper pads decimals.

```nim
const flushBlockBytes = 1 shl 17
const unreachableWeight = 1000000000
const decimalPlaces = 100000

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

proc paddedDigits(value: int): string =
  var digits = $value
  while digits.len < 5:
    digits = "0" & digits
  return digits
```

The zero line ends all input.
Output is buffered across test cases.
The padding helper keeps exactly five digits.

**Extreme-weight table and answer.** Two passes over the table give min and max weights.

```nim
while true:
  let boxCount = nextInt(inputData, scanPos)
  if boxCount == 0:
    break
  let groupSize = nextInt(inputData, scanPos)
  var weights = newSeq[int](boxCount)
  var costs = newSeq[int](boxCount)
  var totalWeight = 0
  var totalCost = 0
  for boxIndex in 0 .. boxCount - 1:
    weights[boxIndex] = nextInt(inputData, scanPos)
    costs[boxIndex] = nextInt(inputData, scanPos)
    totalWeight = totalWeight + weights[boxIndex]
    totalCost = totalCost + costs[boxIndex]
  let rowWidth = totalCost + 1
  var minimumWeights = newSeq[int]((groupSize + 1) * rowWidth)
  var maximumWeights = newSeq[int]((groupSize + 1) * rowWidth)
  for index in 0 .. minimumWeights.len - 1:
    minimumWeights[index] = unreachableWeight
    maximumWeights[index] = -1
  minimumWeights[0] = 0
  maximumWeights[0] = 0
  var processedBoxes = 0
  for boxIndex in 0 .. boxCount - 1:
    let boxWeight = weights[boxIndex]
    let boxCost = costs[boxIndex]
    let highestCount = groupSize
    var chosenCount = highestCount
    if chosenCount > processedBoxes + 1:
      chosenCount = processedBoxes + 1
    var countIndex = chosenCount
    while countIndex >= 1:
      let previousRow = (countIndex - 1) * rowWidth
      let currentRow = countIndex * rowWidth
      var costIndex = totalCost - boxCost
      while costIndex >= 0:
        let target = currentRow + costIndex + boxCost
        let previousMinimum = minimumWeights[previousRow + costIndex]
        if previousMinimum != unreachableWeight:
          let candidateMinimum = previousMinimum + boxWeight
          if candidateMinimum < minimumWeights[target]:
            minimumWeights[target] = candidateMinimum
        let previousMaximum = maximumWeights[previousRow + costIndex]
        if previousMaximum >= 0:
          let candidateMaximum = previousMaximum + boxWeight
          if candidateMaximum > maximumWeights[target]:
            maximumWeights[target] = candidateMaximum
        costIndex -= 1
      countIndex -= 1
    processedBoxes += 1
  var bestValue = 1e30
  let answerRow = groupSize * rowWidth
  var costIndex = 1
  while costIndex <= totalCost - 1:
    let smallestWeight = minimumWeights[answerRow + costIndex]
    if smallestWeight != unreachableWeight:
      let largestWeight = maximumWeights[answerRow + costIndex]
      var chosenWeight = smallestWeight
      if 2 * costIndex > totalCost:
        chosenWeight = largestWeight
      let otherCost = totalCost - costIndex
      let candidateValue = float(chosenWeight) / float(costIndex) + float(totalWeight - chosenWeight) / float(otherCost)
      if candidateValue < bestValue:
        bestValue = candidateValue
    costIndex += 1
  let roundedValue = int(bestValue * float(decimalPlaces) + 0.5)
  appendOutput($(roundedValue div decimalPlaces))
  outputBuffer.add '.'
  appendOutput(paddedDigits(roundedValue mod decimalPlaces))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Both table directions use descending indices to avoid reusing a box.
The weight choice follows the sign of the linear coefficient.
Rounding and padding produce the required decimal output.

## Complexity

The table has one row per chosen count and one column per cost sum.

| phase | time | space |
|---|---|---|
| input scan | one pass over N box pairs | two arrays of N entries |
| extreme table | O(N K C) updates | two tables of K C cells |
| answer scan | O(C) cost values | buffered output |

| measure | Big O |
|---|---|
| time | O(N K C) |
| space | O(K C) |

Checking all K-subsets would grow with the binomial coefficient of N.

The table keeps only the two weights that can win.
