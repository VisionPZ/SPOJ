# CSUBSEQS — Common Subsequences (SPOJ)

<https://www.spoj.com/problems/CSUBSEQS/>

## Problem

Count distinct non-empty strings that are subsequences of all four given strings. Print one integer.

Input has four lines, one lowercase string per line. Each string has at most 50 letters. Output has one integer.

| item | bound |
|---|---|
| strings | 4 |
| length of each string | at most 50 |
| letters | a to z |
| judge limit | 1000 ms, 1536 MB |

A subsequence skips letters but keeps the remaining order. Equal strings formed from different positions count once.

Sample input and output:

```
aabb
abab
baba
acba
```

```
4
```

The four strings are a, b, aa and ab.

## Idea

Count each distinct string at the earliest place it can finish, like filing a book under the first shelf where the whole title appears. For a chosen first letter, use its first occurrence in each string. Then solve the same problem on the four suffixes after those letters.

A state is a quadruple of positions. Weighted transitions append one letter and move every position to the next matching letter plus one. States are processed by increasing position sum, which is a topological order. Each state costs 26 transitions. Brute enumeration of all subsequences costs 2^50 in the worst case.

Earliest positions give each distinct string exactly one path.

## Why It Works

1. If w is common to all four strings, its first letter c has an occurrence in every string.
2. Replacing that occurrence by the first c at or after the current position keeps the rest of w a subsequence.
3. So every distinct string has one canonical path that starts from the empty state.
4. A state stores the number of distinct strings whose canonical path ends there.
5. Appending letter c to every state with count w adds w to the successor state.
6. A successor always raises every position by at least one, so its position sum is strictly larger.
7. Processing states by position sum applies every contribution before a state's own propagation.
8. The sum of all added weights equals the number of distinct non-empty common subsequences.

| term | meaning |
|---|---|
| `nextPositions` | first occurrence of each letter at or after each position |
| `stateCode` | packed quadruple of consumed positions |
| `stateWeight` | number of distinct strings ending at one state |
| `stateBuckets` | states grouped by position sum |
| `totalDistinct` | running sum of all transition weights |

The table names the state and the order used by the code.

A scripted trace of the sample lists the canonical consumed positions after each string.

```
a:  (1, 1, 2, 1)
b:  (3, 2, 1, 3)
aa: (2, 3, 4, 4)
ab: (3, 2, 3, 3)
number of reachable non-empty states = 4
```

The four paths match the four strings listed after the sample.

## Code

**Input and occurrence tables.** The reader loads four lowercase words and precomputes every next letter.

```nim
const flushBlockBytes = 1 shl 17
const textCount = 4
const letterCount = 26

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < 'a' or data[pos] > 'z'):
    pos += 1
  var word = ""
  while pos < data.len and data[pos] >= 'a' and data[pos] <= 'z':
    word.add data[pos]
    pos += 1
  return word

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The word scanner skips line breaks.
Each occurrence table has one sentinel entry per letter.
The sentinel keeps a missing letter from creating a false path.

**Position encoding and sweep.** Packed states are visited in increasing position sum.

```nim
var texts = newSeq[string](textCount)
for textIndex in 0 .. textCount - 1:
  texts[textIndex] = nextWord(inputData, scanPos)
var textLengths = newSeq[int](textCount)
for textIndex in 0 .. textCount - 1:
  textLengths[textIndex] = texts[textIndex].len
var letterStrides = newSeq[int](textCount)
for textIndex in 0 .. textCount - 1:
  letterStrides[textIndex] = textLengths[textIndex] + 1
var nextPositions = newSeq[seq[int]](textCount)
for textIndex in 0 .. textCount - 1:
  let letterStride = letterStrides[textIndex]
  nextPositions[textIndex] = newSeq[int](letterCount * letterStride)
  for letterIndex in 0 .. letterCount - 1:
    var lastPosition = textLengths[textIndex]
    nextPositions[textIndex][letterIndex * letterStride + textLengths[textIndex]] = lastPosition
    for charIndex in countdown(textLengths[textIndex] - 1, 0):
      if int(texts[textIndex][charIndex]) - 97 == letterIndex:
        lastPosition = charIndex
      nextPositions[textIndex][letterIndex * letterStride + charIndex] = lastPosition
let fourthStride = 1
let thirdStride = letterStrides[3]
let secondStride = letterStrides[2] * thirdStride
let firstStride = letterStrides[1] * secondStride
let stateSpaceSize = letterStrides[0] * firstStride
var maximumIndexSum = 0
for textIndex in 0 .. textCount - 1:
  maximumIndexSum += textLengths[textIndex]
var counts = newSeq[int64](stateSpaceSize)
counts[0] = 1
var stateBuckets = newSeq[seq[int]](maximumIndexSum + 1)
stateBuckets[0].add(0)
```

A mixed-radix code maps four positions to one index.
The four strides come from the four string lengths.
The empty state starts with weight one.

**Letter transitions.** Every letter that exists in all four suffixes creates or extends a state.

```nim
var totalDistinct: int64 = 0
for currentSum in 0 .. maximumIndexSum:
  for statePosition in 0 .. stateBuckets[currentSum].len - 1:
    let stateCode = stateBuckets[currentSum][statePosition]
    let stateWeight = counts[stateCode]
    var remainder = stateCode
    let firstIndex = remainder div firstStride
    remainder = remainder mod firstStride
    let secondIndex = remainder div secondStride
    remainder = remainder mod secondStride
    let thirdIndex = remainder div thirdStride
    let fourthIndex = remainder mod thirdStride
    for letterIndex in 0 .. letterCount - 1:
      let nextFirst = nextPositions[0][letterIndex * letterStrides[0] + firstIndex] + 1
      if nextFirst > textLengths[0]:
        continue
      let nextSecond = nextPositions[1][letterIndex * letterStrides[1] + secondIndex] + 1
      if nextSecond > textLengths[1]:
        continue
      let nextThird = nextPositions[2][letterIndex * letterStrides[2] + thirdIndex] + 1
      if nextThird > textLengths[2]:
        continue
      let nextFourth = nextPositions[3][letterIndex * letterStrides[3] + fourthIndex] + 1
      if nextFourth > textLengths[3]:
        continue
      let nextCode = nextFirst * firstStride + nextSecond * secondStride +
          nextThird * thirdStride + nextFourth * fourthStride
      let nextSum = nextFirst + nextSecond + nextThird + nextFourth
      if counts[nextCode] == 0:
        stateBuckets[nextSum].add(nextCode)
      counts[nextCode] += stateWeight
      totalDistinct += stateWeight
appendOutput($totalDistinct)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Increasing position sum is a topological order for all transitions.
A first visit places a state in a later bucket.
Weights are int64 because 50 letters allow about 2^50 strings.

## Complexity

The cost comes from reachable states and their letter transitions.

| phase | time | space |
|---|---|---|
| input read | four lines | four strings |
| occurrence tables | 4 times 26 times 50 | 4 tables over letters and positions |
| state sweep | up to 26 per reachable state | packed counts and buckets |
| output | one line | block buffer |

The state sweep dominates the runtime.

| measure | Big O |
|---|---|
| time | O(26 S), with S reachable states |
| space | O(N1 N2 N3 N4) in the worst case |

Enumerating all subsequences costs O(2^50) and cannot finish at the length bound.

Earliest positions collapse duplicate embeddings into one weighted state.
