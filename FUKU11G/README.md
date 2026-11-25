# FUKU11G — Captain Qs Treasure (SPOJ)

<https://www.spoj.com/problems/FUKU11G/>

## Problem

Some map sections show how many chests lie in their three-by-three neighbourhood, and the rest may hide chests freely. Find the smallest total number of chests that satisfies every printed digit.

Input holds several maps. Each starts with height `h` and width `w`, followed by `h` rows of characters: `.` for water, `*` for an island section with an unknown count, and a digit for a required neighbourhood count. The line `0 0` ends the input. Output one minimum per map.

| item | bound |
|---|---|
| height `h` | 1 to 15 |
| width `w` | 1 to 15 |
| printed digits | 1 to 15 per map |
| chests per section | 0 or 1 |
| judge limit | 1743 ms, 1536 MB |

Only island sections next to a printed digit can affect an answer. Math spans `h`, `w`, and the three-by-three neighbourhood use grid coordinates.

Sample input:

```
5 6
*2.2**
..*...
..2...
..*...
*2.2**
6 5
.*2*.
..*..
..*..
..2..
..*..
.*2*.
5 6
.1111.
**...*
33....
**...0
.*2**.
6 9
....1....
...1.1...
....1....
.1..*..1.
1.1***1.1
.1..*..1.
9 9
*********
*4*4*4*4*
*********
*4*4*4*4*
*********
*4*4*4*4*
*********
*4*4*4***
*********
0 0
```

Sample output:

```
6
5
5
6
23
```

## Idea

Pack each digit's remaining count into four bits of one integer, like keeping a row of abacus beads that move only when a nearby chest is placed. Then walk the candidate sections in order and try both choices at each one. Memoization stores the best result for each packed state, and a simple bound discards states whose digits ask for more chests than remain available.

Enumerating every subset of candidate sections grows as two to the number of sections. Packing, pruning, and caching cut that search to the small neighbourhoods that matter.

## Why It Works

1. A digit constrains only sections within one row and one column of itself.
2. A section outside every digit neighbourhood can be left empty in a minimum solution.
3. Four bits hold a remaining count from zero to nine.
4. The packed integer holds up to fifteen such counts at once.
5. At a candidate section, a chest may be placed only when every affected digit still has a positive count.
6. If any digit wants more chests than the remaining sections can supply, that branch is dead.
7. Caching by section index and packed state prevents repeated work.

| term | meaning |
|---|---|
| `digitTargets` | required count for each printed digit |
| `candidateRows` | row of each section that can hold a chest |
| `affectsDigit` | which digits see each candidate section |
| `remainingPossible` | most chests still available to a digit |

A script solved the first sample map and listed its digit cells and chosen chest cells using zero-based coordinates.

| item | value |
|---|---|
| digit cells and counts | (0,1)=2, (0,3)=2, (2,2)=2, (4,1)=2, (4,3)=2 |
| candidate sections | 11 |
| chosen chest cells | (0,1), (0,4), (1,2), (3,2), (4,1), (4,4) |
| total chests | 6 |

Six matches the first line of the sample output.

## Code

**Input and scanning.** The reader loads the stream and scans numbers and map characters.

```nim
import tables

const flushBlockBytes = 1 shl 17
const nibbleMask: int64 = 15
const nibbleBits = 4
const unreachable = 1 shl 28

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

proc nextMapChar(data: string, pos: var int): char =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = data[pos]
  pos += 1
```

The table module stores memoized states.
Four-bit nibbles hold the remaining counts.
The sentinel value marks an impossible branch.

**Output buffering.** One buffer collects the per-map answers.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Each map contributes one line.
Blocks flush after crossing the size threshold.
The final flush ends the stream.

**Search state.** Global arrays describe one map during the recursive search.

```nim
var digitRows = newSeq[int]()
var digitColumns = newSeq[int]()
var digitTargets = newSeq[int]()
var candidateRows = newSeq[int]()
var candidateColumns = newSeq[int]()
var affectsDigit = newSeq[seq[bool]]()
var remainingPossible = newSeq[seq[int]]()
var memoResults = newSeq[Table[int64, int]]()
```

Digit arrays hold positions and required counts.
Candidate arrays hold sections that may carry chests.
The memo table is indexed by section position.

**Recursive search.** Each call returns the fewest chests still needed.

```nim
proc searchChests(cellIndex: int, state: int64): int =
  var allSatisfied = true
  for digitIndex in 0 .. digitTargets.len - 1:
    if ((state shr (nibbleBits * digitIndex)) and nibbleMask) != 0:
      allSatisfied = false
      break
  if allSatisfied:
    return 0
  if cellIndex == candidateRows.len:
    return unreachable
  if memoResults[cellIndex].hasKey(state):
    return memoResults[cellIndex][state]
  for digitIndex in 0 .. digitTargets.len - 1:
    let remaining = int((state shr (nibbleBits * digitIndex)) and nibbleMask)
    if remaining > remainingPossible[digitIndex][cellIndex]:
      memoResults[cellIndex][state] = unreachable
      return unreachable
  var bestPlacement = searchChests(cellIndex + 1, state)
  var mayPlace = true
  for digitIndex in 0 .. digitTargets.len - 1:
    if affectsDigit[digitIndex][cellIndex] and
       ((state shr (nibbleBits * digitIndex)) and nibbleMask) == 0:
      mayPlace = false
      break
  if mayPlace:
    var nextState = state
    for digitIndex in 0 .. digitTargets.len - 1:
      if affectsDigit[digitIndex][cellIndex]:
        nextState = nextState - (int64(1) shl (nibbleBits * digitIndex))
    bestPlacement = min(bestPlacement, 1 + searchChests(cellIndex + 1, nextState))
  memoResults[cellIndex][state] = bestPlacement
  return bestPlacement
```

A zero state ends the search early.
A digit with too few remaining sections prunes the branch.
The cheaper of skipping and placing is cached.

**Map driver.** The loop builds candidates, packs the state, and prints the answer.

```nim
while true:
  let mapHeight = nextInt(inputData, scanPos)
  let mapWidth = nextInt(inputData, scanPos)
  if mapHeight == 0 and mapWidth == 0:
    break
  var mapRows = newSeq[string](mapHeight)
  for rowIndex in 0 .. mapHeight - 1:
    var rowText = ""
    for columnIndex in 0 .. mapWidth - 1:
      rowText.add nextMapChar(inputData, scanPos)
    mapRows[rowIndex] = rowText
  digitRows.setLen 0
  digitColumns.setLen 0
  digitTargets.setLen 0
  for rowIndex in 0 .. mapHeight - 1:
    for columnIndex in 0 .. mapWidth - 1:
      let sectionChar = mapRows[rowIndex][columnIndex]
      if sectionChar >= '0' and sectionChar <= '9':
        digitRows.add rowIndex
        digitColumns.add columnIndex
        digitTargets.add int(sectionChar) - 48
```

The sentinel ends the input loop.
Each row is read as a string.
Digits become target counts.

```nim
  candidateRows.setLen 0
  candidateColumns.setLen 0
  for rowIndex in 0 .. mapHeight - 1:
    for columnIndex in 0 .. mapWidth - 1:
      if mapRows[rowIndex][columnIndex] == '.':
        continue
      var touchesDigit = false
      for digitIndex in 0 .. digitRows.len - 1:
        if abs(rowIndex - digitRows[digitIndex]) <= 1 and
           abs(columnIndex - digitColumns[digitIndex]) <= 1:
          touchesDigit = true
          break
      if touchesDigit:
        candidateRows.add rowIndex
        candidateColumns.add columnIndex
  let candidateCount = candidateRows.len
```

Water sections are ignored.
Only island sections near a digit become candidates.
The count fixes the search depth.

```nim
  affectsDigit = newSeq[seq[bool]]()
  remainingPossible = newSeq[seq[int]]()
  for digitIndex in 0 .. digitRows.len - 1:
    var digitAffects = newSeq[bool](candidateCount)
    for cellIndex in 0 .. candidateCount - 1:
      if abs(candidateRows[cellIndex] - digitRows[digitIndex]) <= 1 and
         abs(candidateColumns[cellIndex] - digitColumns[digitIndex]) <= 1:
        digitAffects[cellIndex] = true
    affectsDigit.add digitAffects
    var possibleCounts = newSeq[int](candidateCount + 1)
    var reverseIndex = candidateCount - 1
    while reverseIndex >= 0:
      possibleCounts[reverseIndex] = possibleCounts[reverseIndex + 1]
      if digitAffects[reverseIndex]:
        possibleCounts[reverseIndex] += 1
      reverseIndex -= 1
    remainingPossible.add possibleCounts
```

Each digit records the sections it sees.
A reverse pass fills the pruning bounds.
Bounds are indexed by search depth.

```nim
  memoResults = newSeq[Table[int64, int]](candidateCount + 1)
  for memoIndex in 0 .. candidateCount:
    memoResults[memoIndex] = initTable[int64, int]()
  var initialState: int64 = 0
  for digitIndex in 0 .. digitTargets.len - 1:
    initialState = initialState or (int64(digitTargets[digitIndex]) shl (nibbleBits * digitIndex))
  let minimumChests = searchChests(0, initialState)
  appendOutput($minimumChests)
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Every memo table starts empty.
Shifting places each target in its nibble.
The search result leaves through the buffer.

## Complexity

Each cached state is visited once.

| phase | time | space |
|---|---|---|
| candidate build | one pass over the map | two section arrays |
| search | one memo entry per reached state | memo tables |
| output | one line per map | block buffer |

| measure | Big O |
|---|---|
| time | O(candidates × reachable states) |
| space | O(candidates × reachable states) |

Trying each subset of candidate sections would need two to the power of the candidate count.

Pruning and memoization keep the search inside the small digit neighbourhoods.
