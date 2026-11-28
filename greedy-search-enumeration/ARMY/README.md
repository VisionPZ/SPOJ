# ARMY — Army Strength (SPOJ)

<https://www.spoj.com/problems/ARMY/>

## Problem

Two armies of monsters fight until one army is empty. Each battle kills the weakest surviving monster, and a tie kills one of MechaGodzilla's monsters. Report which army wins.

The first input line holds the test count `T`. Each test starts with two counts, then Godzilla's strengths, then MechaGodzilla's strengths. Print `Godzilla`, `MechaGodzilla`, or `uncertain` on its own line.

| item | bound |
|---|---|
| tests T | positive integer, blank line before each test |
| army sizes | positive integers |
| monster strength | positive integer fitting in a 32-bit int |
| judge limit | 500 ms, 1536 MB |

The tie rule drives the design: equal strengths favour Godzilla.

Sample input:

```
2

1 1
1
1

3 2
1 3 2
5 5
```

Sample output:

```
Godzilla
MechaGodzilla
```

## Idea

Think of the fight as peeling strength lists from the bottom, like removing the shortest cards from two stacks. The largest strength never dies, so its owner wins. One pass per army finds that maximum; sorting or simulating every battle would cost more. Take the maximum comparison as the whole algorithm.

## Why It Works

1. A monster dies only while a weaker or equal monster survives in the other army.
2. The strongest monster overall never faces a weaker opponent.
3. If both armies share that top strength, MechaGodzilla's copy dies first on a tie.
4. Therefore Godzilla wins when its maximum is at least MechaGodzilla's maximum.
5. Otherwise MechaGodzilla holds the top strength and wins.

| term | meaning |
|---|---|
| `strongestGodzilla` | largest strength in Godzilla's army |
| `strongestMecha` | largest strength in MechaGodzilla's army |

Both maxima come directly from the two strength lines.

A script trace for `1 1 / 1 / 1` gives maxima `1` and `1`, so the tie kills MechaGodzilla's monster and Godzilla wins. For `3 2 / 1 3 2 / 5 5` the maxima are `3` and `5`, so Godzilla's three monsters die and MechaGodzilla wins.

Both traces match the sample output.

## Code

**Input and scanning.** The hand reader stores stdin once and extracts integers with a digit scanner.

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

Blank lines and spaces are skipped by the scanner.
No strength list needs to be stored.
Parsing stops when the last monster is read.

**Output buffer.** One string collects every answer and flushes in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

This keeps write calls rare for large test counts.
A final write empties the remaining text.

**Maximum scan.** Each army is reduced to its strongest monster, then compared once.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let godzillaCount = nextInt(inputData, scanPos)
  let mechaCount = nextInt(inputData, scanPos)
  var strongestGodzilla = 0
  for monsterIndex in 0 .. godzillaCount - 1:
    let strength = nextInt(inputData, scanPos)
    if strength > strongestGodzilla:
      strongestGodzilla = strength
  var strongestMecha = 0
  for monsterIndex in 0 .. mechaCount - 1:
    let strength = nextInt(inputData, scanPos)
    if strength > strongestMecha:
      strongestMecha = strength
  if strongestGodzilla >= strongestMecha:
    appendOutput("Godzilla")
  else:
    appendOutput("MechaGodzilla")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The two loops consume exactly the listed strengths.
Using `>=` applies the tie rule to MechaGodzilla.
The result text is appended once per test.

## Complexity

Each monster strength is read and compared once, so cost follows total input size.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| maximum scan | one comparison per monster | constant |
| output | one write per buffer block | block buffer |

No army list is kept in memory.

| measure | Big O |
|---|---|
| time | O(total monsters) |
| space | O(input bytes) |

Simulating every battle would sort both armies and cost extra work. Reading maxima directly keeps each test linear.
