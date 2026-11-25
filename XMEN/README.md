# XMEN — X-MEN (SPOJ)

<https://www.spoj.com/problems/XMEN/>

## Problem

Find the longest common subsequence of two permutations of the numbers 1 to N. Each test case gives N and the two permutations. Output the subsequence length.

Input starts with the test count. Each case gives N, then one line of N integers for each permutation. Output one integer per case.

The bounds from the statement:

| item | bound |
|---|---|
| test cases | 1 to 10 |
| permutation length N | 1 to 100,000 |
| values | 1 to N, each used once |
| judge limit | 1000 ms, 1536 MB |

The length bound rules out the usual quadratic subsequence table.

Sample input:

```
2
2
1 2
2 1
3
1 2 3
1 3 2
```

Sample output:

```
1
2
```

## Idea

Replace the second permutation with its positions in the first, like rewriting a route as mile markers.

A common subsequence must increase in both permutations. After mapping, that condition becomes a strictly increasing list. The algorithm is the longest increasing subsequence with a tails array. Each value costs one binary search. The usual subsequence table costs O(N^2) time and memory.

One sorted tails array replaces a square table.

## Why It Works

1. A common subsequence picks values whose positions rise in both lists.
2. Map each value of the second permutation to its position in the first.
3. The answer is the longest strictly increasing subsequence of the mapped list.
4. `tails` keeps the smallest ending value for each subsequence length.
5. A binary search finds the slot for a new mapped value in O(log N).
6. The last used slot is the subsequence length.

The code uses these names:

| term | meaning |
|---|---|
| `positionInFirst` | index of each value in the first permutation |
| `mappedValue` | position of a value from the second permutation |
| `tails` | smallest ending value for each length |
| `subsequenceLength` | number of slots filled so far |

Each name covers one step of the mapping.

The second sample case traces as follows:

```
mapped list 0 2 1
value 0 -> tails [0]     length 1
value 2 -> tails [0, 2]  length 2
value 1 -> tails [0, 1]  length 2
answer 2
```

The mapped list gives the same length as the sample output.

Values cover 1..N exactly once, so every position lookup is valid.

## Code

**Input and scanning.** The reader loads all tokens with a hand scanner.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

`nextInt` skips separators before each number.
`appendOutput` buffers text for a large write.
The input is read once into one string.

**Position map and tails.** The map turns the second list into positions.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let elementCount = nextInt(inputData, scanPos)
  var positionInFirst = newSeq[int](elementCount + 1)
  for elementIndex in 0 ..< elementCount:
    let dnaValue = nextInt(inputData, scanPos)
    positionInFirst[dnaValue] = elementIndex
  var tails = newSeq[int](elementCount)
  var subsequenceLength = 0
  for elementIndex in 0 ..< elementCount:
    let mappedValue = positionInFirst[nextInt(inputData, scanPos)]
    var lowIndex = 0
    var highIndex = subsequenceLength
    while lowIndex < highIndex:
      let middleIndex = (lowIndex + highIndex) div 2
      if tails[middleIndex] < mappedValue:
        lowIndex = middleIndex + 1
      else:
        highIndex = middleIndex
    tails[lowIndex] = mappedValue
    if lowIndex == subsequenceLength:
      subsequenceLength = subsequenceLength + 1
  appendOutput($subsequenceLength)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`positionInFirst` is filled from the first permutation.
The binary search keeps `tails` sorted at every step.
Each case ends with one buffered length.

## Complexity

Each case builds a position map, then places N values with binary search.

| phase | time | space |
|---|---|---|
| input read | one pass over tokens | one input string |
| position map | one pass over first permutation | array of N+1 positions |
| tails update | one binary search per value | tails array of N slots |
| output | one line per case | block buffer |

The phase table shows a linear map and logarithmic placement per value.

| measure | Big O |
|---|---|
| time | O(N log N) per case |
| space | O(N) per case |

The usual subsequence table costs O(N^2) time and memory.
Mapping to an increasing list keeps both costs small.
