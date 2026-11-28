# FACENEMY — Face the mate (SPOJ)

<https://www.spoj.com/problems/FACENEMY/>

## Problem

Two people stand at fixed points and rotate their facing directions at the same speed. Each turns toward the mate along the shortest arc. Report who reaches that direction first, or `0` on a tie.

Input: `t`, then `t` lines of `x1 y1 u1 v1 x2 y2 u2 v2`. Output: `Hero`, `Heroine`, or `0` per case.

| item | bound |
|---|---|
| test cases `t` | 1 to 500000 |
| each coordinate | 0 to 100 |
| distinct positions | hero, heroine, and their facing targets |
| judge limit | 2500 ms, 1536 MB |

Sample input:

```
10
9 3 6 0 4 4 6 6
1 8 6 3 4 9 7 8
8 2 3 5 9 1 9 8
4 0 3 6 7 6 1 5
4 2 7 3 0 9 7 2
6 0 5 7 1 6 5 4
1 2 1 4 0 0 6 0
7 1 7 7 7 7 3 3
5 9 1 8 9 8 2 6
6 0 0 1 3 8 2 5
```

Sample output:

```
0
Hero
Heroine
Hero
Heroine
Heroine
Heroine
Hero
Heroine
Heroine
```

## Idea

Compare two turning arcs without measuring angles, like comparing two clock hands by their shadows. The cross product gives the swept area and the dot product gives the alignment. Squaring both removes square roots and divisions from the comparison.

Each person turns from a facing vector to the vector pointing at the mate. A dot product above zero means an arc below 90 degrees. A dot product of zero means exactly 90 degrees. A negative dot product means an arc above 90 degrees, whose size is 180 degrees minus a smaller arc.

Using `atan2` and floating point needs a tolerance and loses exact ties. Integer products stay exact for all coordinate bounds.

The takeaway: classify the arc by its dot product, then compare squared tangents within one class.

## Why It Works

1. The facing vector is `(u - x, v - y)`, and the target vector points from one position to the other.
2. `cross = dirX * targetY - dirY * targetX` has magnitude `|dir| * |target| * sin(theta)`.
3. `dot = dirX * targetX + dirY * targetY` equals `|dir| * |target| * cos(theta)`.
4. The ratio `cross / dot` determines the arc size once the sign of `dot` fixes its class.
5. Squaring gives `cross^2 * otherDot^2` against `otherCross^2 * dot^2`, with no division.
6. For a negative dot, a larger ratio means a smaller turn, so the inequality reverses.

| term | meaning |
|---|---|
| `crossHero` | signed area between the hero's vectors |
| `dotHero` | alignment of the hero's vectors |
| `turnClass` | 0 below 90 degrees, 1 at 90, 2 above 90 |
| `compareTurns` | negative if the hero turns less, positive if the heroine turns less |

Worked example from sample case 2, with `(1,8)` facing `(6,3)` and `(4,9)` facing `(7,8)`:

| person | facing vector | target vector | cross | dot | arc |
|---|---|---|---|---|---|
| Hero | `(5,-5)` | `(3,1)` | 20 | 10 | 63.4 degrees |
| Heroine | `(3,-1)` | `(-3,-1)` | -6 | -8 | 143.1 degrees |

The hero's dot is positive, so the hero turns less than 90 degrees. The heroine's dot is negative, so her arc exceeds 90 degrees. The verdict is `Hero`.

Cross products stay within 20000, so squared products stay below `2 * 10^17`.

## Code

**Input and scanner.** The scanner skips separators and reads eight integers per case.

```nim
const flushBlockBytes = 1 shl 17

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
```

All coordinates are non-negative, so no sign branch is needed.

**Buffered output.** One buffer holds all verdicts.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Large case counts never create one write per line.

**Arc class.** The dot product splits the turn into three ranges.

```nim
proc turnClass(dotProduct: int64): int =
  if dotProduct > 0: return 0
  if dotProduct == 0: return 1
  return 2
```

Each class maps to one comparison rule.

**Arc comparison.** Equal classes compare squared tangents.

```nim
proc compareTurns(crossFirst: int64, dotFirst: int64, crossSecond: int64, dotSecond: int64): int =
  let classFirst = turnClass(dotFirst)
  let classSecond = turnClass(dotSecond)
  if classFirst != classSecond:
    if classFirst < classSecond: return -1
    return 1
  if classFirst == 1: return 0
  let scaledFirst = crossFirst * crossFirst * (dotSecond * dotSecond)
  let scaledSecond = crossSecond * crossSecond * (dotFirst * dotFirst)
  if classFirst == 0:
    if scaledFirst < scaledSecond: return -1
    if scaledFirst > scaledSecond: return 1
    return 0
  if scaledFirst > scaledSecond: return -1
  if scaledFirst < scaledSecond: return 1
  return 0
```

The last branch reverses the inequality for arcs above 90 degrees.

**Driver.** Vectors, products, and the verdict are built in one pass.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let heroX = int64(nextInt(inputData, scanPos))
  let heroY = int64(nextInt(inputData, scanPos))
  let heroFaceX = int64(nextInt(inputData, scanPos))
  let heroFaceY = int64(nextInt(inputData, scanPos))
  let heroineX = int64(nextInt(inputData, scanPos))
  let heroineY = int64(nextInt(inputData, scanPos))
  let heroineFaceX = int64(nextInt(inputData, scanPos))
  let heroineFaceY = int64(nextInt(inputData, scanPos))
  let heroDirX = heroFaceX - heroX
  let heroDirY = heroFaceY - heroY
  let heroTargetX = heroineX - heroX
  let heroTargetY = heroineY - heroY
  let heroineDirX = heroineFaceX - heroineX
  let heroineDirY = heroineFaceY - heroineY
  let heroineTargetX = heroX - heroineX
  let heroineTargetY = heroY - heroineY
  let crossHero = heroDirX * heroTargetY - heroDirY * heroTargetX
  let dotHero = heroDirX * heroTargetX + heroDirY * heroTargetY
  let crossHeroine = heroineDirX * heroineTargetY - heroineDirY * heroineTargetX
  let dotHeroine = heroineDirX * heroineTargetX + heroineDirY * heroineTargetY
  let verdict = compareTurns(crossHero, dotHero, crossHeroine, dotHeroine)
  if verdict < 0:
    appendOutput("Hero\n")
  elif verdict > 0:
    appendOutput("Heroine\n")
  else:
    appendOutput("0\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The final write flushes the tail of the buffer.

## Complexity

| phase | time per case | space |
|---|---|---|
| input read | one pass over all bytes | one input string |
| vector math | 8 multiplications | constant |
| verdict write | one buffered line | 128 KiB buffer |

| measure | Big O |
|---|---|
| time per case | O(1) |
| total time | O(t) |
| space | O(input size) |

A floating-point version needs trigonometric calls and a tie tolerance. The integer version uses a fixed number of products and stays exact.
