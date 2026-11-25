# VORONOI — Revenge of Voronoi (SPOJ)

<https://www.spoj.com/problems/VORONOI/>

## Problem

Recover one generator pixel per letter from a discrete Manhattan Voronoi diagram. Ties go to the alphabetically smallest letter, and any valid generator set is accepted.

Each case gives width W and height H, followed by H rows of W lowercase letters. Two zeroes end the input. Print the case number, then each letter with its zero-based x and y, sorted alphabetically. Add a blank line after every case.

| item | bound |
|---|---|
| width W | 1 to 32 |
| height H | 1 to 32 |
| letters | lowercase a to z |
| judge limit | 100 ms, 1536 MB |

A tie at the nearest distance belongs to the smaller letter, so smaller letters need strict wins and larger letters allow ties.

Sample input:

```
4 3
ooxx
ooxx
ooxx
4 1
null
4 4
aabb
aabb
ccdd
ccdd
0 0
```

Sample output:

```
Case 1:
o 0 0
x 2 0

Case 2:
l 2 0
n 0 0
u 1 0

Case 3:
a 0 0
b 2 0
c 0 2
d 2 2

```

## Idea

Place flags so every pixel salutes its nearest flag. Ties go to the alphabetically earlier letter. A flag stands on a pixel of its own letter. That reduces the search to a finite candidate set.

For two letters, every pixel of one letter imposes a distance bound on the other letter's site. Precomputed bitmasks represent all grid positions within a given Manhattan distance. Intersecting those masks filters candidate sites in one pass per pixel.

Backtracking assigns letters with the smallest cells first. Each assignment narrows the candidate masks of later letters. Each filter step touches only a few 64-bit words. Takeaway: turn distance constraints into bitsets and let forward checking do the pruning.

## Why It Works

1. A generator at a distance zero beats every other generator at that pixel, so it lies on its own letter.
2. For a pixel of letter c and a smaller letter d, c must be strictly closer than d.
3. For a pixel of letter c and a larger letter d, c may tie with d.
4. The set of positions at least D away is the complement of positions closer than D.
5. Intersecting those complements over all pixels of one letter gives its allowed region.
6. Forward checking removes sites that cannot satisfy any remaining letter.

| term | meaning |
|---|---|
| `distanceTable` | Manhattan distance between any two pixel centers |
| `lessMasks` | bit mask of positions closer than a distance |
| `lessEqualMasks` | bit mask of positions no farther than a distance |
| `candidateMasks` | surviving site positions for each letter |
| `chosenSites` | final site chosen for each letter |

A worked example uses the row null. The generator for n sits at column zero, u at column one, and l at column two. Each pixel's closest generator matches its letter, and l also claims column three because its site is nearest there.

Precomputing masks once per case keeps each backtracking step cheap, even at 32 by 32.

## Code

**Input and output.** The reader loads whole rows as tokens and writes sites alphabetically.

```nim
import math
import algorithm

const flushBlockBytes = 1 shl 17
const maxLetters = 26

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var currentWidth = 0
var currentHeight = 0
var cellCount = 0
var wordCount = 0
var maxDistance = 0
var distanceTable: seq[uint8]
var lessMasks: seq[uint64]
var lessEqualMasks: seq[uint64]
var fullMasks: seq[uint64]
var cellLetters: seq[seq[int]]
var letterOrder: seq[int]
var candidateMasks: seq[seq[uint64]]
var chosenSites: seq[int]
```

Letters use zero-based indexes internally. Site cells convert back to x and y when printed. A blank line follows every case.

**Distance indexes.** All Manhattan distances and threshold bitmasks are built before the search.

```nim
proc allDistances() =
  distanceTable = newSeq[uint8](cellCount * cellCount)
  for row in 0 .. currentHeight - 1:
    for column in 0 .. currentWidth - 1:
      let firstCell = row * currentWidth + column
      for otherRow in 0 .. currentHeight - 1:
        for otherColumn in 0 .. currentWidth - 1:
          let secondCell = otherRow * currentWidth + otherColumn
          let manhattan = abs(row - otherRow) + abs(column - otherColumn)
          distanceTable[firstCell * cellCount + secondCell] = uint8(manhattan)

proc buildMasks() =
  lessMasks = newSeq[uint64](cellCount * (maxDistance + 1) * wordCount)
  lessEqualMasks = newSeq[uint64](cellCount * (maxDistance + 1) * wordCount)
  fullMasks = newSeq[uint64](wordCount)
  for wordIndex in 0 .. wordCount - 1:
    fullMasks[wordIndex] = 0xFFFFFFFFFFFFFFFF'u64
  let remainder = cellCount mod 64
  if remainder != 0:
    fullMasks[wordCount - 1] = (uint64(1) shl remainder) - 1'u64
  for firstCell in 0 .. cellCount - 1:
    var buckets = newSeq[seq[int]](maxDistance + 1)
    for distanceValue in 0 .. maxDistance:
      buckets[distanceValue] = newSeq[int](0)
    for secondCell in 0 .. cellCount - 1:
      let distanceValue = int(distanceTable[firstCell * cellCount + secondCell])
      buckets[distanceValue].add secondCell
    var accumulated = newSeq[uint64](wordCount)
    for distanceValue in 0 .. maxDistance:
      let baseIndex = (firstCell * (maxDistance + 1) + distanceValue) * wordCount
      for wordIndex in 0 .. wordCount - 1:
        lessMasks[baseIndex + wordIndex] = accumulated[wordIndex]
      for secondCell in buckets[distanceValue]:
        accumulated[secondCell div 64] = accumulated[secondCell div 64] or
          (uint64(1) shl (secondCell mod 64))
      for wordIndex in 0 .. wordCount - 1:
        lessEqualMasks[baseIndex + wordIndex] = accumulated[wordIndex]
```

The distance table holds values up to 62 in one byte. Buckets collect positions at each distance, then cumulative masks record strict and non-strict bounds.

**Site search.** Backtracking intersects masks and restores them after a failed branch.

```nim
proc searchSites(letterPosition: int): bool =
  if letterPosition == letterOrder.len:
    return true
  let currentLetter = letterOrder[letterPosition]
  var chosenWord = 0
  while chosenWord < wordCount:
    var candidateWord = candidateMasks[currentLetter][chosenWord]
    while candidateWord != 0'u64:
      var probeWord = candidateWord
      var trailingBits = 0
      while (probeWord and 1'u64) == 0'u64:
        probeWord = probeWord shr 1
        trailingBits += 1
      let siteCell = chosenWord * 64 + trailingBits
      candidateWord = candidateWord and (candidateWord - 1'u64)
      var greaterMask = newSeq[uint64](wordCount)
      var lesserMask = newSeq[uint64](wordCount)
      for wordIndex in 0 .. wordCount - 1:
        greaterMask[wordIndex] = fullMasks[wordIndex]
        lesserMask[wordIndex] = fullMasks[wordIndex]
      for pixelCell in cellLetters[currentLetter]:
        let distanceValue = int(distanceTable[pixelCell * cellCount + siteCell])
        let baseIndex = (pixelCell * (maxDistance + 1) + distanceValue) * wordCount
        for wordIndex in 0 .. wordCount - 1:
          greaterMask[wordIndex] = greaterMask[wordIndex] and
            (fullMasks[wordIndex] xor lessMasks[baseIndex + wordIndex])
          lesserMask[wordIndex] = lesserMask[wordIndex] and
            (fullMasks[wordIndex] xor lessEqualMasks[baseIndex + wordIndex])
      var savedMasks = newSeq[seq[uint64]](letterOrder.len - letterPosition - 1)
      var feasible = true
      var futureIndex = 0
      for futurePosition in letterPosition + 1 .. letterOrder.len - 1:
        let futureLetter = letterOrder[futurePosition]
        var boundaryMask = newSeq[uint64](wordCount)
        for wordIndex in 0 .. wordCount - 1:
          if futureLetter > currentLetter:
            boundaryMask[wordIndex] = greaterMask[wordIndex]
          else:
            boundaryMask[wordIndex] = lesserMask[wordIndex]
        for pixelCell in cellLetters[futureLetter]:
          let distanceValue = int(distanceTable[pixelCell * cellCount + siteCell])
          let baseIndex = (pixelCell * (maxDistance + 1) + distanceValue) * wordCount
          for wordIndex in 0 .. wordCount - 1:
            if currentLetter < futureLetter:
              boundaryMask[wordIndex] = boundaryMask[wordIndex] and
                lessMasks[baseIndex + wordIndex]
            else:
              boundaryMask[wordIndex] = boundaryMask[wordIndex] and
                lessEqualMasks[baseIndex + wordIndex]
        var hasCandidate = false
        savedMasks[futureIndex] = candidateMasks[futureLetter]
        futureIndex += 1
        for wordIndex in 0 .. wordCount - 1:
          candidateMasks[futureLetter][wordIndex] = candidateMasks[futureLetter][wordIndex] and
            boundaryMask[wordIndex]
          if candidateMasks[futureLetter][wordIndex] != 0'u64:
            hasCandidate = true
        if not hasCandidate:
          feasible = false
          break
      if feasible:
        chosenSites[currentLetter] = siteCell
        if searchSites(letterPosition + 1):
          return true
      for undoIndex in 0 .. futureIndex - 1:
        let undoLetter = letterOrder[letterPosition + 1 + undoIndex]
        candidateMasks[undoLetter] = savedMasks[undoIndex]
    chosenWord += 1
  return false
```

Smaller cells are assigned first to shrink later domains early. The mask for a chosen site separates farther letters from nearer ones. Restoring saved masks keeps sibling branches independent.

**Case driver.** The diagram is converted into per-letter cells, and the found sites are printed.

```nim
var caseNumber = 0
while true:
  currentWidth = nextInt(inputData, scanPos)
  currentHeight = nextInt(inputData, scanPos)
  if currentWidth == 0 and currentHeight == 0:
    break
  caseNumber += 1
  cellCount = currentWidth * currentHeight
  wordCount = (cellCount + 63) div 64
  maxDistance = currentWidth + currentHeight - 2
  var diagram = newSeq[string](0)
  for row in 0 .. currentHeight - 1:
    diagram.add nextToken(inputData, scanPos)
  cellLetters = newSeq[seq[int]](maxLetters)
  for letterIndex in 0 .. maxLetters - 1:
    cellLetters[letterIndex] = newSeq[int](0)
  for row in 0 .. currentHeight - 1:
    for column in 0 .. currentWidth - 1:
      let letterIndex = int(diagram[row][column]) - 96
      cellLetters[letterIndex].add row * currentWidth + column
  letterOrder = newSeq[int](0)
  for letterIndex in 0 .. maxLetters - 1:
    if cellLetters[letterIndex].len > 0:
      letterOrder.add letterIndex
  letterOrder.sort(proc (left: int, right: int): int =
    if cellLetters[left].len < cellLetters[right].len: return -1
    if cellLetters[left].len > cellLetters[right].len: return 1
    return left - right)
  candidateMasks = newSeq[seq[uint64]](maxLetters)
  for letterIndex in 0 .. maxLetters - 1:
    candidateMasks[letterIndex] = newSeq[uint64](wordCount)
  for letterIndex in letterOrder:
    for pixelCell in cellLetters[letterIndex]:
      candidateMasks[letterIndex][pixelCell div 64] = candidateMasks[letterIndex][pixelCell div 64] or
        (uint64(1) shl (pixelCell mod 64))
  chosenSites = newSeq[int](maxLetters)
  for letterIndex in 0 .. maxLetters - 1:
    chosenSites[letterIndex] = -1
  allDistances()
  buildMasks()
  discard searchSites(0)
  appendOutput("Case " & $caseNumber & ":\n")
  for letterIndex in 0 .. maxLetters - 1:
    if chosenSites[letterIndex] < 0:
      continue
    let siteCell = chosenSites[letterIndex]
    appendOutput(chr(letterIndex + 96) & " " & $(siteCell mod currentWidth) & " " &
      $(siteCell div currentWidth) & "\n")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Candidate sites start as each letter's own pixels. The statement guarantees a solution, so the search always finds a complete assignment.

## Complexity

Mask construction depends on the grid area, and the search depends on the chosen domains.

| phase | time | space |
|---|---|---|
| distance table | O((W*H)^2) | O((W*H)^2) bytes |
| mask build | O((W*H)^2 + W*H*D*words) | O(W*H*D*words) |
| site search | O(L^2 * C * words) worst case | O(L * words) live masks |

| measure | Big O |
|---|---|
| time per case | O((W*H)^2 + L^2 * C * words) |
| space per case | O(W*H*D*words) |

Here D is the largest Manhattan distance and C is the largest cell. Scanning every site combination without masks would be far slower.

Takeaway: bitset constraints make the inverse diagram cheap to search.
