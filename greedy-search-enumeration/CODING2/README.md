# CODING2 — Coding (SPOJ)

<https://www.spoj.com/problems/CODING2/>

## Problem

Given a message over an alphabet of 2 to the power N symbols, find a prefix-free binary code that uses the fewest bits for that message. Symbols missing from the message still need codewords, but they add no bits.

Each test case gives N and the message length M, followed by M symbol numbers. The line `0 0` ends the input. Print the minimum bit count for each test case on its own line.

| item | bound |
|---|---|
| alphabet parameter N | 1 to 15 |
| message length M | 1 to 1000000 |
| symbol value | 0 to 2 to the power N minus one |
| judge limit | 1000 ms, 1536 MB |

An alphabet with at least two symbols gives every used symbol at least one bit.

Sample input:

```
2 16
0 0 0 0 1 1 1 1 0 0 0 0 2 2 3 3
0 0
```

Sample output:

```
28
```

## Idea

Give the shortest codeword to the most common symbol, like handing out the shortest nickname to the name people say most. Huffman coding does exactly that by repeatedly merging the two lightest symbols. Each merge costs the sum of the two weights, and the running total is the answer. Rebuilding codeword lengths for every candidate tree would be far slower, so one pass of merges suffices.

## Why It Works

1. A prefix-free code is a binary tree whose leaves are the symbols.
2. The bit cost equals the sum of frequency times leaf depth.
3. Huffman's greedy merge of the two lightest weights gives optimal depths.
4. Zero-frequency symbols can take the deepest unused leaves without adding cost.
5. A lone used symbol still needs one bit, since the alphabet has at least two leaves.

| term | meaning |
|---|---|
| `symbolCounts` | occurrences of each symbol in the message |
| `heapValues` | active weights in the min-heap |
| `combinedWeight` | weight created by one merge |
| `totalBits` | sum of all merge weights |
| `usedSymbols` | number of symbols with positive frequency |

The heap holds exactly the active merge weights.

Script-generated trace for the sample:

```
quantity | value
symbol 0 count | 8
symbol 1 count | 4
symbol 2 count | 2
symbol 3 count | 2
first merge | 2 + 2 = 4
second merge | 4 + 4 = 8
third merge | 8 + 8 = 16
total bits | 4 + 8 + 16 = 28
```

The total matches the sample output.

## Code

**Bulk input and buffered output.** The whole stream is read once; answers are written in blocks.

```nim
const flushBlockBytes = 1 shl 17
const numberBase = 10

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
    value = value * numberBase + int(data[pos]) - 48
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips separators and line breaks.
The output buffer flushes at 128 KiB.
Both walk shared strings to keep allocations low.

**Binary min-heap.** A flat array keeps the two lightest weights at hand.

```nim
var heapValues = newSeq[int64]()

proc heapPush(value: int64) =
  heapValues.add value
  var childIndex = heapValues.len - 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if heapValues[parentIndex] <= heapValues[childIndex]:
      break
    let heldValue = heapValues[parentIndex]
    heapValues[parentIndex] = heapValues[childIndex]
    heapValues[childIndex] = heldValue
    childIndex = parentIndex

proc heapPop(): int64 =
  result = heapValues[0]
  let lastValue = heapValues[heapValues.len - 1]
  heapValues.setLen(heapValues.len - 1)
  if heapValues.len > 0:
    heapValues[0] = lastValue
    var parentIndex = 0
    while true:
      let leftIndex = parentIndex * 2 + 1
      if leftIndex >= heapValues.len:
        break
      let rightIndex = leftIndex + 1
      var smallerIndex = leftIndex
      if rightIndex < heapValues.len and heapValues[rightIndex] < heapValues[leftIndex]:
        smallerIndex = rightIndex
      if heapValues[parentIndex] <= heapValues[smallerIndex]:
        break
      let heldValue = heapValues[parentIndex]
      heapValues[parentIndex] = heapValues[smallerIndex]
      heapValues[smallerIndex] = heldValue
      parentIndex = smallerIndex
```

Insertion sifts a new weight toward the root.
Removal moves the last weight down along the smaller child.
Each step touches one path of the heap.

**Counting and merging.** Frequencies feed the heap, then merges produce the bit total.

```nim
while true:
  let alphabetBits = nextInt(inputData, scanPos)
  let messageLength = nextInt(inputData, scanPos)
  if alphabetBits == 0 and messageLength == 0:
    break
  let alphabetSize = 1 shl alphabetBits
  var symbolCounts = newSeq[int](alphabetSize)
  for symbolIndex in 0 .. alphabetSize - 1:
    symbolCounts[symbolIndex] = 0
  for messageIndex in 0 .. messageLength - 1:
    let symbolValue = nextInt(inputData, scanPos)
    symbolCounts[symbolValue] += 1
  heapValues.setLen 0
  var usedSymbols = 0
  for symbolIndex in 0 .. alphabetSize - 1:
    if symbolCounts[symbolIndex] > 0:
      heapPush(int64(symbolCounts[symbolIndex]))
      usedSymbols += 1
  var totalBits: int64 = 0
  if usedSymbols == 1:
    totalBits = heapValues[0]
  else:
    while heapValues.len > 1:
      let firstWeight = heapPop()
      let secondWeight = heapPop()
      let combinedWeight = firstWeight + secondWeight
      totalBits = totalBits + combinedWeight
      heapPush(combinedWeight)
  appendOutput($totalBits)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The count array is reset for every test case.
A single used symbol costs one bit per occurrence.
Every other case merges until one weight remains.

## Complexity

Counting reads the message once; merging shrinks the heap by one each round.

| phase | time | space |
|---|---|---|
| input read | one pass over message integers | one input string |
| frequency count | one integer per message symbol | array of alphabet size |
| Huffman merges | one heap pop and push per distinct symbol | heap of distinct weights |
| output | one line per test case | block buffer |

The heap keeps merging cheap even at 32768 symbols.

| measure | Big O |
|---|---|
| time per case | O(message length + distinct symbols log distinct symbols) |
| space per case | O(alphabet size) |

Trying every binary tree would be exponential in the alphabet size.

The greedy heap gives the optimum in one pass.
