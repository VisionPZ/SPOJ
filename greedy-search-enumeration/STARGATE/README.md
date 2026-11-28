# STARGATE — Stargates (SPOJ)

<https://www.spoj.com/problems/STARGATE/>

## Problem

Planets become linked by bidirectional stargates, and connectivity is transitive. Each command either defines a fresh set of planets, creates many links at once, or asks how many of a batch of pairs are connected. We print one answer line per query command.

A line starts with D, C, or Q in either case. D n starts a new data set with planets 1 through n. C and Q share five forms. Two numbers give one pair. Three give a starting pair, a count and a unit step. Four add an explicit destination step. Five also add a source step. A query prints the connected pair count, a space, and the disconnected pair count.

| item | bound |
|---|---|
| planets per data set N | up to 6000000 |
| numbers per command | 1 to 5 |
| command stream | no empty lines |
| judge limit | 100 ms, 1536 MB |

The planet count rules out rebuilding components from scratch.

Sample input:

```
d 5
C 1 3
D 20
q 1 3
c 1 10 10
Q 1 2 18 1 1
```

Sample output:

```
0 1
9 9
```

## Idea

Give each connected crowd one label, like stamping every name in a group with the same badge. Disjoint-set union keeps that badge in a parent array and follows parent links to find it. Path halving shortens those links, and attaching the smaller crowd to the larger one keeps trees shallow. A fresh breadth-first search per query would rebuild all badges every time.

One array of badges answers every query in the data set.

## Why It Works

1. A D command resets each planet to its own one-member component.
2. findRoot follows parent links and halves each link on the way.
3. uniteNodes hangs the smaller component under the larger one.
4. Component size then grows at least by a factor of two along any parent link.
5. A command with fewer than five numbers uses default steps of zero or one.
6. Each generated pair is either unioned or tested for equal roots.
7. Equal roots mean a path exists, so the pair counts as connected.
8. The two printed counts always add up to the number of pairs in the query.

| term | meaning |
|---|---|
| `parentNode` | parent badge for each planet |
| `componentSize` | member count of the component at a root |
| `findRoot` | badge lookup with path halving |
| `lineValues` | parsed integers of one command line |
| `pairCount` | number of pairs named by one command |

Combining size and halving keeps lookups nearly constant on average.

The first sample trace shows why the second answer is nine and nine:

```
D 20 resets all planets
C 1 10 10 links planet 1 with planets 10 through 19
Q 1 2 18 1 1 tests (1,2),(2,3),...,(18,19)
pairs (10,11) through (18,19) share a badge: 9 connected, 9 disconnected
```

The trace matches the sample output exactly.

Lowercase commands are uppercased before dispatch. A new D command discards all previous links by rebuilding both arrays.

## Code

**Input, line scanner, and output buffer.** Each line is scanned only up to its newline.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const lowerCaseOffset = 32

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextIntInLine(data: string, pos: var int, lineEnd: int): int =
  while pos < lineEnd and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < lineEnd and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner stops at the line end so commands never bleed together.
Command letters are uppercased with a fixed offset.
The buffer flushes after many kilobytes, not after each query.

**Disjoint-set operations.** Two flat arrays hold the badges and component sizes.

```nim
var parentNode = newSeq[int](1)
var componentSize = newSeq[int](1)

proc findRoot(node: int): int =
  var current = node
  while parentNode[current] != current:
    parentNode[current] = parentNode[parentNode[current]]
    current = parentNode[current]
  return current

proc uniteNodes(firstNode: int, secondNode: int) =
  var firstRoot = findRoot(firstNode)
  var secondRoot = findRoot(secondNode)
  if firstRoot == secondRoot:
    return
  if componentSize[firstRoot] < componentSize[secondRoot]:
    let swapRoot = firstRoot
    firstRoot = secondRoot
    secondRoot = swapRoot
  parentNode[secondRoot] = firstRoot
  componentSize[firstRoot] = componentSize[firstRoot] + componentSize[secondRoot]
```

Path halving rewrites every second parent link during a lookup.
The size check keeps the tree height logarithmic.
Union by size avoids deep chains on long command streams.

**Command dispatch.** Lines expand into pairs, then either union or count them.

```nim
var lineValues = newSeq[int]()

while scanPos < inputData.len:
  var lineEnd = scanPos
  while lineEnd < inputData.len and inputData[lineEnd] != '\n':
    lineEnd += 1
  var cursor = scanPos
  while cursor < lineEnd and inputData[cursor] <= ' ':
    cursor += 1
  if cursor < lineEnd:
    var command = inputData[cursor]
    cursor += 1
    if command >= 'a' and command <= 'z':
      command = chr(int(command) - lowerCaseOffset)
    lineValues.setLen(0)
    while cursor < lineEnd:
      while cursor < lineEnd and inputData[cursor] <= ' ':
        cursor += 1
      if cursor >= lineEnd:
        break
      lineValues.add nextIntInLine(inputData, cursor, lineEnd)
    if command == 'D':
      let planetCount = lineValues[0]
      parentNode.setLen(planetCount + 1)
      componentSize.setLen(planetCount + 1)
      for planetIndex in 0 .. planetCount:
        parentNode[planetIndex] = planetIndex
        componentSize[planetIndex] = 1
    else:
      let sourcePlanet = lineValues[0]
      let destinationPlanet = lineValues[1]
      var pairCount = 1
      var destinationStep = 0
      var sourceStep = 0
      if lineValues.len >= 3:
        pairCount = lineValues[2]
        destinationStep = 1
      if lineValues.len >= 4:
        destinationStep = lineValues[3]
      if lineValues.len >= 5:
        sourceStep = lineValues[4]
      var connectedPairs: int64 = 0
      var disconnectedPairs: int64 = 0
      for pairIndex in 0 .. pairCount - 1:
        let firstPlanet = sourcePlanet + pairIndex * sourceStep
        let secondPlanet = destinationPlanet + pairIndex * destinationStep
        if command == 'C':
          uniteNodes(firstPlanet, secondPlanet)
        else:
          if findRoot(firstPlanet) == findRoot(secondPlanet):
            connectedPairs += 1
          else:
            disconnectedPairs += 1
      if command == 'Q':
        appendOutput($connectedPairs)
        outputBuffer.add ' '
        appendOutput($disconnectedPairs)
        outputBuffer.add '\n'
  scanPos = lineEnd + 1

stdout.write outputBuffer
outputBuffer.setLen 0
```

Missing steps default to zero or one depending on the command form.
A D line resizes both arrays and gives every planet a fresh badge.
Only Q lines produce output, one line each.

## Complexity

Each named pair costs one or two badge lookups, almost constant on average.

| phase | time | space |
|---|---|---|
| input read | one pass over lines | one input string |
| D command | one pass over planets | two arrays of size N |
| C command | one union per named pair | no extra space |
| Q command | two lookups per named pair | no extra space |
| output | one append per query | block buffer |

The arrays use about sixteen bytes per planet with 64-bit integers.

| measure | Big O |
|---|---|
| time | O((N + P) alpha(N)) with P named pairs |
| space | O(N) |

Rebuilding connectivity with a graph traversal per query would cost O(N P) or worse.
