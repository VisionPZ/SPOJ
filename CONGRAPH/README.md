# CONGRAPH — Connected Country (SPOJ)

<https://www.spoj.com/problems/CONGRAPH/>

## Problem

After an earthquake, some cities in GRAPH can no longer reach others.
Find the fewest new bidirectional roads needed to connect every city.

The first line holds N cities and M roads, with N up to 800000 and M below 4000000.
The next M lines each name two zero-based cities joined by a road.
Print one integer, the number of roads required.

| Item | Bound |
|---|---|
| Cities N | 1 to 800000 |
| Roads M | below 4000000 |
| Judge limit | 10000 ms |

Both counts are large, so each road must be processed in near constant time.

Sample input:

```
6 6
0 1
0 2
1 2
3 4
3 5
4 5
```

Sample output:

```
1
```

The two triangles need one road between them.

## Idea

Think of provinces linked by bridges, where a new bridge merges two provinces.

Maintain one representative per province.
For each road, merge the representatives of its two cities.
Count how many provinces remain after all roads are read.

Provinces can only decrease, so the answer is one less than the final count.

## Why It Works

1. A disjoint-set structure holds one representative for each province.
2. Joining two different representatives merges exactly two provinces.
3. Union by size keeps each tree shallow after every merge.
4. Path halving compresses chains as roots are looked up.

After all roads, the remaining provinces need a chain of new roads to connect them.

| Term | Meaning |
|---|---|
| `parent` | array mapping a city to its parent in a merge tree |
| `subtreeSize` | node count used to choose the new root |
| `componentCount` | running number of provinces |

Each successful merge lowers the count by one, which yields the exact answer.

Script-generated example from `gen.py`:

```
6 6 components 2, roads needed 1
```

The trace matches the sample graph and its single required road.

## Code

**Scanner and set structure.** This block reads input and implements root lookup.

```nim
{.push checks: off.}
{.passC: "-O3".}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextNumber(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc findRoot(parent: var seq[int], node: int): int =
  var current = node
  while parent[current] != current:
    parent[current] = parent[parent[current]]
    current = parent[current]
  return current
```

`nextNumber` skips non-digits and returns each city id.
`findRoot` halving-compresses the path while walking upward.
Checks are disabled and optimization flags are set for large inputs.

**Merging.** This block unions endpoints and tracks the component count.

```nim
let cityCount = nextNumber(inputData, scanPos)
let roadCount = nextNumber(inputData, scanPos)
var parent: seq[int] = @[]
parent.setLen(cityCount)
var subtreeSize: seq[int] = @[]
subtreeSize.setLen(cityCount)
for city in 0..<cityCount:
  parent[city] = city
  subtreeSize[city] = 1

var componentCount = cityCount
for roadIndex in 0..<roadCount:
  let firstCity = nextNumber(inputData, scanPos)
  let secondCity = nextNumber(inputData, scanPos)
  var firstRoot = findRoot(parent, firstCity)
  var secondRoot = findRoot(parent, secondCity)
  if firstRoot != secondRoot:
    if subtreeSize[firstRoot] < subtreeSize[secondRoot]:
      swap(firstRoot, secondRoot)
    parent[secondRoot] = firstRoot
    subtreeSize[firstRoot] += subtreeSize[secondRoot]
    componentCount -= 1
```

Every city starts as its own province of size one.
The smaller tree is attached under the larger root.
Only a merge between different roots changes the count.

**Answer output.** This block writes the final road count once.

```nim
var outputBuffer = ""
proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

appendOutput($(componentCount - 1))
appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The count is already correct after the last road.
One block buffer handles the short output.
A final write clears any remaining text.

## Complexity

Each road performs two near constant-time root lookups.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Merging | inverse Ackermann cost per endpoint | two city arrays |
| Output | one short write | block buffer |

The arrays use linear space in the number of cities.

| Measure | Big O |
|---|---|
| Time | O(M alpha(N) + I) |
| Space | O(N + I) |

A fresh traversal after every road costs O(M times N) instead.
