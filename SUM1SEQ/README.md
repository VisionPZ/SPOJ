## Problem

Each case gives a length and a target sum. Print a sequence of that length that starts at zero and changes by one at each step. The values must add up to the target sum. Print No when no such sequence exists. End each case with an empty line.

The statement fixes these bounds:

| Quantity | Bound |
| --- | --- |
| Sequence length | 1 to 10,000 |
| Absolute target sum | up to 50,000,000 |
| Case count | not stated |
| Time limit | 3000 ms |
| Memory limit | 1536 MB |

The length sets the work per case, so the program builds each answer in one pass.

## Idea

Expand the sequence sum into signed weights from 1 to n-1. A step of +1 gives its weight a plus sign, and a step of -1 gives it a minus sign. A greedy pass from the largest weight down picks the minus signs. One more walk turns those signs into sequence values. Trying every step pattern would take 2^(n-1) attempts per case.

Cost per element: one sign lookup and one printed integer.

## Why It Works

Let step i be the change from value i to value i+1. Step i appears in exactly n-i later values. The target sum is therefore the signed sum of the weights n-1 down to 1.

Call the sum of all weights T. Changing one sign from plus to minus subtracts twice that weight. A target is reachable only when its absolute value is at most T and matches T in parity.

Every number from 0 to T is a sum of distinct weights from 1 to n-1. The greedy pass takes a weight whenever it fits the remaining amount. A target that passes both tests always gets a sequence.

The program marks signs with these values:

| Expression | Meaning |
| --- | --- |
| totalWeight | sum of all weights, equal to n(n-1)/2 |
| remainingSum | sum of minus-signed weights, equal to (totalWeight - targetSum)/2 |
| weightValue | weight of step i, equal to n-i |

The greedy pass only needs these three values.

The generator prints this worked example:

```
WORKED n=8 S=4 totalWeight=28 remainingSum=12 negative=[7, 5]
WORKED sequence 0 -1 0 -1 0 1 2 3
```

The minus signs fall on weights 7 and 5, so the steps are -1, +1, -1, +1, +1, +1, +1. The walk starts at 0 and prints the listed values. Their sum is 4.

## Code

The input loop reads the whole stream into one buffer before any case runs.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9') and data[position] != '-':
    position += 1
  var signValue = 1
  if position < data.len and data[position] == '-':
    signValue = -1
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return signValue * value
```

The scanner stops at the minus sign, so negative targets parse correctly. The digit loop runs once per input character.

One growable buffer holds all output and flushes in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var isNegative = newSeq[bool](0)
```

The flush keeps memory at one block and writes once per 256 KiB. The bool row grows only when a longer case arrives.

The case loop checks reachability, then marks the minus-signed weights.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let sequenceLength = nextInt(inputData, scanPos)
  let targetSum = nextInt(inputData, scanPos)
  let totalWeight = sequenceLength * (sequenceLength - 1) div 2
  let magnitudeSum = if targetSum < 0: -targetSum else: targetSum
  if (magnitudeSum + totalWeight) mod 2 != 0 or magnitudeSum > totalWeight:
    appendOutput("No\n\n")
    continue
  var remainingSum = (totalWeight - targetSum) div 2
  if isNegative.len <= sequenceLength:
    isNegative.setLen(sequenceLength + 1)
  var j = sequenceLength - 1
  while j >= 1:
    if j <= remainingSum:
      isNegative[j] = true
      remainingSum -= j
    else:
      isNegative[j] = false
    j -= 1
```

The while loop visits weights n-1 down to 1, so it costs O(n). Using magnitudeSum keeps the parity test valid for negative targets.

The last block prints the walk and flushes the remaining output.

```nim
  appendOutput("0\n")
  var currentValue = 0
  for i in 1..<sequenceLength:
    let weightValue = sequenceLength - i
    if isNegative[weightValue]:
      currentValue -= 1
    else:
      currentValue += 1
    appendOutput($(currentValue))
    outputBuffer.add '\n'
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The for loop prints n-1 values after the leading zero. The blank line closes each case, and the final write flushes the rest.

## Complexity

Reading takes time and space linear in the input size. Each case takes O(n) time for the greedy pass and O(n) bool space that the program reuses. Printing takes O(n) time per case because each value becomes one line.

Total time is O(input size plus printed values). Total space is O(n plus input size plus one output block). A search over step patterns would take O(2^(n-1)) time per case.
