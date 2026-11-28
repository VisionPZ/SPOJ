# GRC — Grandpa’s Rubik Cube (SPOJ)

<https://www.spoj.com/problems/GRC/>

## Problem

Apply a list of face turns to a Rubik's cube and decide whether every face ends with one color. A turn names a face from 1 to 6 and a direction; positive means clockwise as seen from outside that face.

The first input line gives the test count. Each test has nine grid lines showing the cube net, then rotation integers ending in zero. Print `Yes, grandpa!` for a winning cube and `No, you are wrong!` otherwise.

| item | bound |
|---|---|
| tests | given by first line |
| net per test | nine lines of color letters |
| rotation value | -6 to 6, excluding 0, plus a final 0 |
| judge limit | 1 s, 1536 MB |

Colors use the letters Y, R, B, G, W and M.

Sample input:

```
3
      G Y Y
      G Y Y
      G Y Y
W W W Y R R M M M G G B
W W W Y R R M M M G G B
W W W Y R R M M M G G B
      R B B
      R B B
      R B B
-1 0
      G Y Y
      G Y Y
      G Y Y
W W W Y R R M M M G G B
W M W Y R R M W M G G B
W W W Y R R M M M G G B
      R B B
      R B B
      R B B
-1 0
      M W M
      W W G
      W W Y
G Y Y M M B M B G W R B
B Y Y M M B M G G W R R
Y M G W B B R R G R R W
      R Y Y
      G B Y
      R G B
+4 +6 -2 +3 -4 +2 -3 -6 0
```

Sample output:

```
Yes, grandpa!
No, you are wrong!
Yes, grandpa!
```

## Idea

Treat every sticker as a small card with a position and an outward arrow, like beads on a wire frame. A turn rotates the beads in one slice of the frame, carrying both the card and its arrow. Fold the nine net lines into 54 such cards, spin the requested slices, then check whether the cards on each side share one color. Rebuilding and reprinting the whole net after each turn would be slower and harder to keep consistent.

## Why It Works

1. The net folds onto six planes at coordinates plus or minus one.
2. Each sticker stores a position and a normal vector, so its side is always known.
3. A turn selects the slice where the position dot the face normal equals one.
4. Clockwise as seen from outside is a minus 90 degree turn about that normal.
5. A cube wins when all nine normals of each side carry the same color.

| term | meaning |
|---|---|
| `placeSticker` | folds one net cell into a position and normal |
| `rotateVector` | applies one quarter turn to a coordinate triple |
| `applyRotation` | spins every sticker in the selected slice |
| `isWinning` | tests color uniformity on each side |
| `stickerCount` | the 54 facelets of a cube |

A script check of the first sample case reads four side strips around face one: front left Y, top left G, back right B and bottom left R. The turn minus one sends bottom to front, front to top, top to back and back to bottom. The front gains R, the top gains Y, the back gains G and the bottom gains B, so all six sides become single colors.

The turn direction follows the figure's arrows, so a sign flip would break the sample. All coordinates stay in minus one, zero or plus one, keeping the arithmetic exact.

## Code

**Input and line reading.** The reader loads stdin, parses signed turns and keeps whole grid lines.

```nim
const flushBlockBytes = 1 shl 17
const stickerCount = 54

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

proc nextLine(data: string, pos: var int): string =
  var line = ""
  while pos < data.len and data[pos] != '\n':
    line.add data[pos]
    pos += 1
  if pos < data.len:
    pos += 1
  return line

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner handles the minus sign in a rotation value.
Line reading preserves the spaces inside a grid row.

**Folding the net.** Each of the nine lines maps its letters onto cube stickers.

```nim
var positionX = newSeq[int](stickerCount)
var positionY = newSeq[int](stickerCount)
var positionZ = newSeq[int](stickerCount)
var normalX = newSeq[int](stickerCount)
var normalY = newSeq[int](stickerCount)
var normalZ = newSeq[int](stickerCount)
var stickerColor = newSeq[int](stickerCount)

proc colorCode(letter: char): int =
  case letter
  of 'Y': return 0
  of 'R': return 1
  of 'B': return 2
  of 'G': return 3
  of 'W': return 4
  of 'M': return 5
  else: return -1

proc placeSticker(faceNumber: int, row: int, column: int, color: int) =
  let stickerIndex = (faceNumber - 1) * 9 + row * 3 + column
  stickerColor[stickerIndex] = color
  case faceNumber
  of 1:
    positionX[stickerIndex] = -1
    positionY[stickerIndex] = 1 - row
    positionZ[stickerIndex] = column - 1
    normalX[stickerIndex] = -1
    normalY[stickerIndex] = 0
    normalZ[stickerIndex] = 0
  of 2:
    positionX[stickerIndex] = column - 1
    positionY[stickerIndex] = 1 - row
    positionZ[stickerIndex] = 1
    normalX[stickerIndex] = 0
    normalY[stickerIndex] = 0
    normalZ[stickerIndex] = 1
  of 3:
    positionX[stickerIndex] = 1
    positionY[stickerIndex] = 1 - row
    positionZ[stickerIndex] = 1 - column
    normalX[stickerIndex] = 1
    normalY[stickerIndex] = 0
    normalZ[stickerIndex] = 0
  of 4:
    positionX[stickerIndex] = 1 - column
    positionY[stickerIndex] = 1 - row
    positionZ[stickerIndex] = -1
    normalX[stickerIndex] = 0
    normalY[stickerIndex] = 0
    normalZ[stickerIndex] = -1
  of 5:
    positionX[stickerIndex] = column - 1
    positionY[stickerIndex] = 1
    positionZ[stickerIndex] = row - 1
    normalX[stickerIndex] = 0
    normalY[stickerIndex] = 1
    normalZ[stickerIndex] = 0
  else:
    positionX[stickerIndex] = column - 1
    positionY[stickerIndex] = -1
    positionZ[stickerIndex] = 1 - row
    normalX[stickerIndex] = 0
    normalY[stickerIndex] = -1
    normalZ[stickerIndex] = 0
```

Faces one to four occupy the middle rows of the net.
Face five sits above face two and face six sits below it.

**Quarter turns.** The slice selector and the direction table drive every move.

```nim
proc rotateVector(valueX: var int, valueY: var int, valueZ: var int,
                  axisCode: int, direction: int) =
  case axisCode
  of 0:
    let oldY = valueY
    let oldZ = valueZ
    if direction > 0:
      valueY = -oldZ
      valueZ = oldY
    else:
      valueY = oldZ
      valueZ = -oldY
  of 1:
    let oldX = valueX
    let oldZ = valueZ
    if direction > 0:
      valueX = oldZ
      valueZ = -oldX
    else:
      valueX = -oldZ
      valueZ = oldX
  else:
    let oldX = valueX
    let oldY = valueY
    if direction > 0:
      valueX = -oldY
      valueY = oldX
    else:
      valueX = oldY
      valueY = -oldX

proc applyRotation(rotation: int) =
  let faceNumber = abs(rotation)
  var axisCode = 0
  var layerValue = 0
  var direction = 1
  case faceNumber
  of 1:
    axisCode = 0
    layerValue = -1
    direction = if rotation > 0: 1 else: -1
  of 2:
    axisCode = 2
    layerValue = 1
    direction = if rotation > 0: -1 else: 1
  of 3:
    axisCode = 0
    layerValue = 1
    direction = if rotation > 0: -1 else: 1
  of 4:
    axisCode = 2
    layerValue = -1
    direction = if rotation > 0: 1 else: -1
  of 5:
    axisCode = 1
    layerValue = 1
    direction = if rotation > 0: -1 else: 1
  of 6:
    axisCode = 1
    layerValue = -1
    direction = if rotation > 0: 1 else: -1
  else:
    return
  for stickerIndex in 0 .. stickerCount - 1:
    var inLayer = false
    case axisCode
    of 0: inLayer = positionX[stickerIndex] == layerValue
    of 1: inLayer = positionY[stickerIndex] == layerValue
    else: inLayer = positionZ[stickerIndex] == layerValue
    if inLayer:
      rotateVector(positionX[stickerIndex], positionY[stickerIndex],
                   positionZ[stickerIndex], axisCode, direction)
      rotateVector(normalX[stickerIndex], normalY[stickerIndex],
                   normalZ[stickerIndex], axisCode, direction)
```

The direction table flips sign for faces whose normal points along a negative axis.
Both position and normal rotate, so a sticker keeps its side.

**Winning test and driver.** Each test ends with a plain yes or no line.

```nim
proc isWinning(): bool =
  for axisCode in 0 .. 2:
    for signValue in [-1, 1]:
      var firstColor = -1
      for stickerIndex in 0 .. stickerCount - 1:
        var belongs = false
        case axisCode
        of 0: belongs = normalX[stickerIndex] == signValue and
                        normalY[stickerIndex] == 0 and normalZ[stickerIndex] == 0
        of 1: belongs = normalY[stickerIndex] == signValue and
                        normalX[stickerIndex] == 0 and normalZ[stickerIndex] == 0
        else: belongs = normalZ[stickerIndex] == signValue and
                        normalX[stickerIndex] == 0 and normalY[stickerIndex] == 0
        if belongs:
          if firstColor == -1:
            firstColor = stickerColor[stickerIndex]
          elif stickerColor[stickerIndex] != firstColor:
            return false
  return true

let testCount = nextInt(inputData, scanPos)
while scanPos < inputData.len and inputData[scanPos] != '\n':
  scanPos += 1
if scanPos < inputData.len:
  scanPos += 1
for testIndex in 0 .. testCount - 1:
  for lineIndex in 0 .. 8:
    let gridLine = nextLine(inputData, scanPos)
    var letterIndex = 0
    for characterIndex in 0 .. gridLine.len - 1:
      let letter = gridLine[characterIndex]
      if letter == ' ':
        continue
      var faceNumber = 0
      var row = 0
      var column = 0
      if lineIndex < 3:
        faceNumber = 5
        row = lineIndex
        column = letterIndex
      elif lineIndex < 6:
        faceNumber = letterIndex div 3 + 1
        row = lineIndex - 3
        column = letterIndex mod 3
      else:
        faceNumber = 6
        row = lineIndex - 6
        column = letterIndex
      placeSticker(faceNumber, row, column, colorCode(letter))
      letterIndex += 1
  while true:
    let rotation = nextInt(inputData, scanPos)
    if rotation == 0:
      break
    applyRotation(rotation)
  while scanPos < inputData.len and inputData[scanPos] != '\n':
    scanPos += 1
  if scanPos < inputData.len:
    scanPos += 1
  if isWinning():
    appendOutput("Yes, grandpa!\n")
  else:
    appendOutput("No, you are wrong!\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The driver skips the rest of each header and rotation line before reading the next grid.
The final flush writes every answer line.

## Complexity

| phase | time | space |
|---|---|---|
| net fold | nine lines per test | 54 sticker slots |
| rotations | 54 sticker checks per turn | constant |
| winning test | one pass over 54 stickers | constant |

| measure | Big O |
|---|---|
| time per test | O(54 * rotations) |
| space | O(54) |

Keeping the net as face matrices and rewriting strips after every turn would need more bookkeeping for the same result.

The work per turn stays tiny, so long rotation lists finish quickly.
