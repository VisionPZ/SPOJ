# DEC123 — Decorating the Palace (SPOJ)

<https://www.spoj.com/problems/DEC123/>

## Problem

A tower is a binary tree with N flowers at the root and height H. Each internal node splits its flowers between its two children, with the child counts differing as little as possible.

Count the distinct decorations modulo 1000000007. The input gives a case count and then one pair H, N per case, and the output gives one count per case.

| item | bound |
|---|---|
| height H | 1 to 50 |
| root flowers N | 1 to 50000 |
| test cases | at most 10 |
| judge limit | 104 ms, 1536 MB |

A bottom row can hold more nodes than any program could visit, so the count needs a compact rule.

Sample input:

```
2
1 1
2 1
```

Sample output:

```
1
2
```

## Idea

Count the binary choices, like counting coin flips without listing every sequence. An internal node with an odd value splits into two different ordered pairs, so it offers two choices. An even value splits into two equal halves, so it offers one choice.

The answer is two raised to the number of odd internal nodes. The values on each level are only the floor and ceiling of N divided by a power of two. Their counts can be carried forward level by level.

Visiting every node would be exponential in H.

## Why It Works

1. A node with value v has children with values floor(v/2) and ceil(v/2).
2. When v is odd those children differ, and swapping them gives a second decoration.
3. When v is even both children match, and swapping changes nothing.
4. Each node's choice is independent, so the total count is two to the number of odd internal nodes.
5. At depth d every value equals floor(N / 2^d) or ceil(N / 2^d), so two counts describe the whole level.
6. Splitting those two values produces the two counts of the next level.

| term | meaning |
|---|---|
| `towerHeight` | number of levels in the tower |
| `flowerCount` | flowers at the root |
| `oddExponent` | number of odd internal nodes found so far |
| `lowCount` | nodes holding the lower value at this depth |
| `highCount` | nodes holding the higher value at this depth |

The exponent is reduced modulo the prime through fast exponentiation.

A script-generated trace for H = 4 and N = 5 lists the levels.

| depth | values present | odd nodes |
|---|---|---|
| 0 | 5 | 1 |
| 1 | 2, 3 | 1 |
| 2 | 1, 1, 1, 2 | 3 |

The odd counts sum to 5, so the answer is 2 to the 5, or 32.

## Code

**Input, scanning, and helpers.** The reader loads cases, and two helpers support the sweep.

```nim
const flushBlockBytes = 1 shl 17
const modulusValue: int64 = 1000000007

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

proc powerMod(baseValue: int64, exponentValue: int64): int64 =
  var baseNow = baseValue mod modulusValue
  var exponentNow = exponentValue
  var resultValue: int64 = 1
  while exponentNow > 0:
    if exponentNow mod 2 == 1:
      resultValue = (resultValue * baseNow) mod modulusValue
    baseNow = (baseNow * baseNow) mod modulusValue
    exponentNow = exponentNow div 2
  return resultValue

proc addChildren(nodeCount: int64, nodeValue: int64, lowValue: int64, highValue: int64, lowTotal: var int64, highTotal: var int64) =
  if nodeCount == 0:
    return
  let firstChild = nodeValue div 2
  let secondChild = (nodeValue + 1) div 2
  if lowValue == highValue:
    lowTotal = lowTotal + nodeCount * 2
  else:
    if firstChild == lowValue:
      lowTotal = lowTotal + nodeCount
    else:
      highTotal = highTotal + nodeCount
    if secondChild == lowValue:
      lowTotal = lowTotal + nodeCount
    else:
      highTotal = highTotal + nodeCount
```

The power routine squares the base at every step.
The child helper classifies both children of one value.
Both helpers work on counts, never on individual nodes.

**Level sweep and output.** Each level adds its odd nodes to the exponent.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let towerHeight = nextInt(inputData, scanPos)
  let flowerCount = nextInt(inputData, scanPos)
  if towerHeight <= 1:
    appendOutput("1")
  else:
    var oddExponent: int64 = 0
    var lowCount: int64 = 1
    var highCount: int64 = 0
    var depth = 0
    while depth < towerHeight - 1:
      let powerAtDepth: int64 = 1 shl depth
      let lowValue: int64 = int64(flowerCount) div powerAtDepth
      let remainder: int64 = int64(flowerCount) mod powerAtDepth
      var highValue = lowValue
      if remainder != 0:
        highValue = highValue + 1
      if lowValue mod 2 == 1:
        oddExponent = oddExponent + lowCount
      if highValue mod 2 == 1:
        oddExponent = oddExponent + highCount
      let nextLowValue = lowValue div 2
      var nextHighValue = (highValue + 1) div 2
      var nextLowCount: int64 = 0
      var nextHighCount: int64 = 0
      addChildren(lowCount, lowValue, nextLowValue, nextHighValue, nextLowCount, nextHighCount)
      addChildren(highCount, highValue, nextLowValue, nextHighValue, nextLowCount, nextHighCount)
      lowCount = nextLowCount
      highCount = nextHighCount
      depth += 1
    appendOutput($(powerMod(2, oddExponent)))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop visits only the internal levels of the tower.
Once the quotient reaches zero, the two values stay at zero and one.
One buffered write delivers every answer.

## Complexity

Work depends on the height, not on the number of nodes.

| phase | time | space |
|---|---|---|
| input read | one pass over the input string | one input string |
| level sweep | two value splits per level | four counters |
| output | one modular power per case | block buffer |

The phase table shows that all cases stay small even for full towers.

| measure | Big O |
|---|---|
| time | O(H log modulus) per case |
| space | O(1) beyond the input string |

Enumerating every decoration costs O(2^H) per case, while counting odd nodes costs O(H).
