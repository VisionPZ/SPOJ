# GNY07I — Spatial Concepts Test (SPOJ)

<https://www.spoj.com/problems/GNY07I/>

## Problem

Check which corner views match a folded cube, then report how many of five choices match. A cube net and five three-face views use letter labels plus a direction digit.

The first line holds the number of questions. Each question takes six lines: one net, then five answers. A net has six letter-digit pairs in a fixed net order. An answer has three pairs in top, right, left order around a corner. Each answer line holds the question number, the match count, and five `Y` or `N` verdicts.

| item | bound |
|---|---|
| questions | 1 to 1000 |
| faces per net | 6 |
| answers per question | 5 |
| judge limit | 1000 ms, 1536 MB |

The net order is a row of four side faces, with one face above and one below the third face in that row.

Sample input:

```
2
F3E4E2D3C2F3
C2D2F2
E3F3C4
F2C2D2
D1E1F3
E1C1E1
A2F4F1A3A3C4
C3A4A2
F3F4A1
F3C4A1
A2C3A2
A4A4F1
```

Sample output:

```
1 2 Y N Y N N
2 0 N N N N N
```

## Idea

Treat each cube corner as a fixed trio of faces with fixed rotations, like listing the three walls that meet at a room corner. Fold the net once to get eight trios. Rotate each trio in three cyclic orders to cover every view direction. Compare each answer against those 24 signatures. Generating every signature once beats unfolding the cube for each answer.

## Why It Works

1. The net has four side faces in a row, plus a top face and a bottom face.
2. Each cube corner joins the top or bottom face with two adjacent side faces.
3. There are four corners around the top face and four around the bottom face.
4. Folding fixes how each face's up direction points in a corner view.
5. A shift of 0, 1, 2, or 3 turns maps a net orientation to a view digit.
6. Cyclic rotations of a trio cover the three placements of a face at the top.

| term | meaning |
|---|---|
| `cornerFaceIndices` | net face positions at each of eight corners |
| `cornerTurnShifts` | quarter turns added to each face orientation |
| `cornerImages` | face letters after folding |
| `cornerTurns` | view digits after folding |

The two tables capture all folding geometry.

The generator traces the first sample net. Corner two joins net faces 0, 4, and 3, which carry F, C, and D. Their folded view digits are 2, 2, and 2. The cyclic rotation starting at C gives `C2D2F2`.

| view string | folded trio | verdict |
|---|---|---|
| `C2D2F2` | C, D, F rotated from F, C, D | Y |
| `F2C2D2` | F, C, D in base order | Y |
| `E3F3C4` | no matching corner trio | N |

Both accepted views are rotations of the same corner.

## Code

**Input parsing.** The reader locates letter-digit pairs inside the input text.

```nim
const flushBlockBytes = 1 shl 17
const cornerFaceIndices: array[8, array[3, int]] = [
  [0, 2, 1], [0, 3, 2], [0, 4, 3], [0, 1, 4],
  [5, 1, 2], [5, 2, 3], [5, 3, 4], [5, 4, 1]]
const cornerTurnShifts: array[8, array[3, int]] = [
  [1, 0, 3], [2, 0, 3], [3, 0, 3], [0, 0, 3],
  [0, 2, 1], [3, 2, 1], [2, 2, 1], [1, 2, 1]]

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

proc nextPair(data: string, pos: var int): tuple[image: int, turn: int] =
  while pos < data.len and (data[pos] < 'A' or data[pos] > 'F'):
    pos += 1
  let image = int(data[pos]) - 65
  pos += 1
  let turn = int(data[pos]) - 49
  pos += 1
  return (image, turn)
```

Letters are stored as numbers from zero to five.
Digits are stored as quarter turns from zero to three.
The scanner skips whitespace between specifications.

**Corner construction.** Each net produces eight folded corners.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  var flatImages: array[6, int]
  var flatTurns: array[6, int]
  for faceIndex in 0 .. 5:
    let pair = nextPair(inputData, scanPos)
    flatImages[faceIndex] = pair.image
    flatTurns[faceIndex] = pair.turn
  var cornerImages: array[8, array[3, int]]
  var cornerTurns: array[8, array[3, int]]
  for corner in 0 .. 7:
    for slot in 0 .. 2:
      let faceIndex = cornerFaceIndices[corner][slot]
      cornerImages[corner][slot] = flatImages[faceIndex]
      cornerTurns[corner][slot] = (flatTurns[faceIndex] + cornerTurnShifts[corner][slot]) mod 4
```

Repeated letters keep their distinct face positions.
The shift table depends only on the corner and slot.
All eight corners are built before any answer is read.

**Answer comparison.** Each answer is tested against eight corners and three rotations.

```nim
  var verdicts = ""
  var solutionCount = 0
  for answerIndex in 0 .. 4:
    var answerImages: array[3, int]
    var answerTurns: array[3, int]
    for slot in 0 .. 2:
      let pair = nextPair(inputData, scanPos)
      answerImages[slot] = pair.image
      answerTurns[slot] = pair.turn
    var matched = false
    block search:
      for corner in 0 .. 7:
        for rotation in 0 .. 2:
          var agrees = true
          for slot in 0 .. 2:
            let target = (rotation + slot) mod 3
            if cornerImages[corner][target] != answerImages[slot] or cornerTurns[corner][target] != answerTurns[slot]:
              agrees = false
              break
          if agrees:
            matched = true
            break search
```

A match fixes both letter and view digit on all three faces.
The first matching corner ends the search.
A failed answer contributes `N` and no count.

**Result line.** One buffered line reports the five verdicts.

```nim
    if matched:
      solutionCount += 1
      verdicts.add 'Y'
    else:
      verdicts.add 'N'
  appendOutput($(caseIndex))
  outputBuffer.add ' '
  appendOutput($(solutionCount))
  for answerIndex in 0 .. 4:
    outputBuffer.add ' '
    outputBuffer.add verdicts[answerIndex]
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Verdicts are separated by single spaces.
Question numbers start at one.
The buffer flushes once after all questions.

## Complexity

Each question builds eight corners and checks five answers.

| phase | time | space |
|---|---|---|
| input read | one pass over all tokens | one input string |
| corner build | eight corners of three faces | two small tables |
| answer check | five times 24 comparisons | one verdict string |

The work per question is fixed and independent of input size.

| measure | Big O |
|---|---|
| time | O(N) |
| space | O(N) for input text |

Unfolding the cube for every answer would repeat the same folding work. Fold once, then compare against the stored corner signatures.
