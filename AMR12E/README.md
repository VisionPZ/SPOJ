# AMR12E — Dyslexic Gollum (SPOJ)

<https://www.spoj.com/problems/AMR12E/>

## Problem

Count binary strings of length `N` that contain no palindromic substring of length `K` or more. Print each count modulo 1000000007.

Input starts with `T`, the test count. Each of the next `T` lines holds two integers, `N` and `K`. Print one count per line in the same order.

| item | bound |
|---|---|
| test cases `T` | 1 to 100 |
| string length `N` | 1 to 400 |
| tolerance `K` | 1 to 10 |
| modulo | 1000000007 |
| judge limit | 2000 ms, 1536 MB |

A palindrome reads the same forwards and backwards, so `00` and `010` are both palindromes.

Sample input:

```
3
2 2
3 3
3 4
```

Sample output:

```
2
4
8
```

## Idea

A long palindrome always contains a shorter one, like a nested set of boxes with the same contents on both sides. Removing matching outer characters reduces its length by two, so forbidding lengths `K` and `K + 1` forbids every longer palindrome too. Build valid strings one bit at a time and remember only the last `K` bits. There are at most 1024 such states, and each state tries two new bits.

Enumerating all 2^N strings is impossible at N = 400. The state DP touches at most 1024 states per position and precomputes every pair once. The takeaway is that the last `K` bits contain all the history the future needs.

## Why It Works

1. A palindrome of length L > K + 1 has an inner palindrome of length L - 2.
2. Repeating that reduction reaches length K or K + 1.
3. A new bit can only create a forbidden palindrome ending at the new position.
4. The last K bits decide every substring of length K ending there.
5. The last K + 1 bits decide the substring of length K + 1 ending there.
6. Appending a bit maps one state to at most two next states.

| term | meaning |
|---|---|
| `answerTable` | precomputed count for each K and N |
| `stateLimit` | number of states, 2 to the power K |
| `stateMask` | bit mask keeping the last K bits |
| `isBitPalindrome` | mirrored-bit test for a state |
| `current` | counts by state at the current length |
| `following` | counts by state after adding one bit |
| `powerOfTwo` | powers of two for lengths below K |

The table names the arrays used by the precomputation.

A script count for K = 3 gives the following visible results.

| length | valid strings | examples |
|---|---|---|
| 3 | 4 | 001, 011, 100, 110 |
| 4 | 2 | 0011, 1100 |
| 5 | 0 | none |

The count drops to zero once every possible ending creates a forbidden palindrome.

## Code

**Precomputation and bit helpers.** The table is filled once for all K up to 10 and all lengths up to 400.

```nim
const flushBlockBytes = 1 shl 17
const maxLength = 400
const maxTolerance = 10
const answerMod = 1000000007

proc isBitPalindrome(bits: int, width: int): bool =
  var leftIndex = 0
  var rightIndex = width - 1
  while leftIndex < rightIndex:
    if ((bits shr leftIndex) and 1) != ((bits shr rightIndex) and 1):
      return false
    leftIndex += 1
    rightIndex -= 1
  return true

var answerTable: array[maxTolerance + 1, array[maxLength + 1, int64]]
var powerOfTwo: array[maxLength + 1, int64]
powerOfTwo[0] = 1
for lengthIndex in 1 .. maxLength:
  powerOfTwo[lengthIndex] = (powerOfTwo[lengthIndex - 1] * 2) mod answerMod

for tolerance in 1 .. maxTolerance:
  let stateLimit = 1 shl tolerance
  let stateMask = stateLimit - 1
  for lengthIndex in 0 .. tolerance - 1:
    answerTable[tolerance][lengthIndex] = powerOfTwo[lengthIndex]
  var current = newSeq[int64](stateLimit)
  var following = newSeq[int64](stateLimit)
  for state in 0 .. stateLimit - 1:
    if not isBitPalindrome(state, tolerance):
      current[state] = 1
  var initialTotal: int64 = 0
  for state in 0 .. stateLimit - 1:
    initialTotal += current[state]
  answerTable[tolerance][tolerance] = initialTotal mod answerMod
  for lengthIndex in tolerance + 1 .. maxLength:
    for state in 0 .. stateLimit - 1:
      following[state] = 0
    for state in 0 .. stateLimit - 1:
      if current[state] == 0:
        continue
      for bit in 0 .. 1:
        let extended = (state shl 1) or bit
        if isBitPalindrome(extended, tolerance + 1):
          continue
        let nextState = extended and stateMask
        if isBitPalindrome(nextState, tolerance):
          continue
        following[nextState] = (following[nextState] + current[state]) mod answerMod
    for state in 0 .. stateLimit - 1:
      current[state] = following[state]
    var lengthTotal: int64 = 0
    for state in 0 .. stateLimit - 1:
      lengthTotal = (lengthTotal + current[state]) mod answerMod
    answerTable[tolerance][lengthIndex] = lengthTotal
```

`isBitPalindrome` compares mirrored bits.
`extended` holds K + 1 bits for the longer palindrome check.
`nextState` keeps the last K bits for the next step.

**Input and buffered output.** Each query reads its precomputed answer directly.

```nim
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

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let wordLength = nextInt(inputData, scanPos)
  let tolerance = nextInt(inputData, scanPos)
  appendOutput($answerTable[tolerance][wordLength])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`nextInt` reads the length and tolerance.
`answerTable` answers each case without more work.
`appendOutput` collects the lines before writing them.

## Complexity

The table is built once before any query is read.

| phase | time | space |
|---|---|---|
| table fill | 10 × 400 × 2^K transitions | 10 × 401 counts |
| input read | one pass over the query list | one input string |
| queries | O(1) per case | block buffer |

| measure | Big O |
|---|---|
| preprocessing | O(10 × 400 × 2^10) |
| per query | O(1) |
| extra space | O(10 × 400) |

Enumerating every string costs O(2^N) per case and fails past N = 60. The state table shifts that cost into one bounded preprocessing pass.
