# THR18B — Chaarshanbegaan at Cafebazaar (SPOJ)
<https://www.spoj.com/problems/THR18B/>

## Problem

Each dart is scored by its distance from the origin, then the shot scores are added. Ten concentric rings give 10 points at the center down to 1 point at radius 190, and 0 outside.

Input starts with one integer N from 1 to 100. The next N lines each hold two integers x and y, with absolute values at most 300. Output is one line with the total score.

| item | bound |
|---|---|
| dart count N | 1 to 100 |
| coordinate x, y | -300 to 300 |
| scoring radii | 10, 30, 50, 70, 90, 110, 130, 150, 170, 190 |
| maximum total | 1000 |
| judge limit | 1000 ms, 1536 MB |

Sample input:

```
2
4 7
-31 -5
```

Sample output:

```
18
```

## Idea

Compare a dart's squared distance with squared ring radii, like checking which box a parcel fits into before paying postage. The algorithm loops over the darts and then over the ten radii. Each dart costs ten integer comparisons and no square root. Taking a square root would add floating-point work and rounding risk. Takeaway: compare squared distances, and add the first matching ring score.

## Why It Works

1. Distance d from the origin satisfies d squared = x squared + y squared.
2. Comparing squared distances with squared radii gives the same ring as comparing distances.
3. Radii 10, 30, ..., 190 have squares 100, 900, ..., 36100.
4. The first radius whose square is at least the shot's square decides the score.
5. Score equals 10 minus the zero-based ring position, or 0 past the last ring.

| term | meaning |
|---|---|
| `squaredDistance` | x squared plus y squared for one shot |
| `ringSquaredLimits` | the ten squared radii in increasing order |
| `shotScore` | points earned by the current dart |
| `totalScore` | sum of all shot scores |

The sample shot (4, 7) has squared distance 65, which is at most 100, so it scores 10.
The sample shot (-31, -5) has squared distance 986, which is at most 2500 and above 900, so it scores 8.
The total is 10 + 8 = 18, matching the sample output. Floating-point roots never enter the computation.

## Code

**Input and scanning.** The reader accepts signed coordinates and stores the whole input once.

```nim
const flushBlockBytes = 1 shl 17
const ringSquaredLimits = [100, 900, 2500, 4900, 8100, 12100, 16900, 22500, 28900, 36100]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value
```

`ringSquaredLimits` lists the ten squared radii.
`nextInt` handles the minus sign on negative coordinates.

**Scoring and output.** One pass assigns each score and accumulates the total.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let dartCount = nextInt(inputData, scanPos)
var totalScore = 0
for dartIndex in 0 .. dartCount - 1:
  let xCoord = nextInt(inputData, scanPos)
  let yCoord = nextInt(inputData, scanPos)
  let squaredDistance = xCoord * xCoord + yCoord * yCoord
  var shotScore = 0
  for ringIndex in 0 .. ringSquaredLimits.len - 1:
    if squaredDistance <= ringSquaredLimits[ringIndex]:
      shotScore = 10 - ringIndex
      break
  totalScore += shotScore
appendOutput($totalScore)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`squaredDistance` stays below 180000, so plain integers suffice.
The loop breaks at the first matching ring.
`appendOutput` writes the single total line.

## Complexity

The program scores at most 100 darts against ten rings.

| phase | time | space |
|---|---|---|
| input read | one pass over 2N coordinates | one input string |
| scoring | N times ten comparisons | ten squared radii |
| output | one line | block buffer |

| measure | Big O |
|---|---|
| time | O(N) |
| space | O(1) |

A floating-point square root per dart would add cost and rounding risk. Takeaway: squared comparisons score every dart in linear time.
