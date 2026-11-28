# G11183 — FOLLOWING Grado 11 (SPOJ)

<https://www.spoj.com/problems/G11183/>

## Problem

Simulate the blocks world and print the final contents of every pile. Commands move one block or a whole stack, either onto a target block or over its pile.

The first input token is the number of blocks. Later lines give the commands move a onto b, move a over b, pile a onto b, and pile a over b, ending with quit. Output has one line per position: the position number, a colon, and its stack of block numbers from bottom to top.

The bounds that shape the simulation:

| item | bound |
|---|---|
| blocks | up to 1000 |
| commands | one per line, ending at quit |
| output lines | one per block |
| judge limit | 1000 ms, 1536 MB |

The block count fixes both the pile matrix and the output size.

Sample input:

```
10
move 9 onto 1
move 8 over 1
move 7 over 1
move 6 over 1
pile 8 over 6
pile 8 over 5
move 2 over 1
move 4 over 9
quit
```

Sample output:

```
0: 0
1: 1 9 2 4
2:
3: 3
4:
5: 5 8 7 6
6:
7:
8:
9:
```

## Idea

Track each block with its pile number and height, like a book carrying a shelf number and a slot on that shelf. Then a command becomes a short pointer update instead of a search. Arrays store stack contents, pile sizes, and each block's location. Onto clears blocks above the target, while over leaves them in place. Pile moves the whole top segment, while move isolates one block first. Searching every pile for each block would cost far more than direct indexing. Keep the arrays current and every command stays local.

## Why It Works

1. Each block stores the pile that holds it and its height in that pile.
2. Returning blocks above a height restores each one to its home pile.
3. Onto clears the target's top blocks before placement, and over keeps them.
4. Pile transfers the source segment from the moved block upward, preserving order.
5. Move clears the source above the chosen block before appending it to the target.

The names below hold the world state:

| term | meaning |
|---|---|
| `pileContents` | block numbers stored by pile and height |
| `pileSizes` | number of blocks in each pile |
| `blockPositions` | pile holding each block |
| `blockDepths` | height of each block in its pile |
| `returnBlocksAbove` | restores blocks above a given height |

These arrays give constant-time access to every block and pile.

A script trace from the generator:

```
start: [1]
move 9 onto 1 -> [1, 9]
after 4 moves pile 1 holds [1,9,8,7,6]
pile 8 over 6: same pile, no-op
pile 8 over 5: sub [8,7,6] joins pile 5 -> [5, 8, 7, 6]
move 2 over 1 -> [1, 9, 2]
move 4 over 9 -> [1, 9, 2, 4]
```

The trace ends with pile 1 holding 1, 9, 2, 4, exactly as the sample shows.

## Code

**Input and tokens.** The reader loads all text and provides number and word scanners.

```nim
const flushBlockBytes = 1 shl 17
const maxBlocks = 1000

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
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\t' or data[pos] == '\n' or data[pos] == '\r'):
    pos += 1
  if pos >= data.len:
    return ""
  let start = pos
  while pos < data.len and data[pos] != ' ' and data[pos] != '\t' and data[pos] != '\n' and data[pos] != '\r':
    pos += 1
  return data[start ..< pos]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The number scanner skips non-digit separators.
The token scanner reads command words up to whitespace.
Both scanners share one position in the input string.

**World state.** Flat arrays store piles, and two helpers keep each block indexed.

```nim
proc pileSlot(base: int, height: int): int =
  return base * maxBlocks + height

var pileContents = newSeq[int](maxBlocks * maxBlocks)
var pileSizes = newSeq[int](maxBlocks)
var blockPositions = newSeq[int](maxBlocks)
var blockDepths = newSeq[int](maxBlocks)

proc putBlockHome(blockNumber: int): int =
  let homeBase = blockNumber
  let height = pileSizes[homeBase]
  pileContents[pileSlot(homeBase, height)] = blockNumber
  pileSizes[homeBase] = height + 1
  blockPositions[blockNumber] = homeBase
  blockDepths[blockNumber] = height
  return height

proc returnBlocksAbove(base: int, height: int) =
  while pileSizes[base] > height + 1:
    let topSlot = pileSizes[base] - 1
    let movedBlock = pileContents[pileSlot(base, topSlot)]
    pileSizes[base] = topSlot
    discard putBlockHome(movedBlock)
```

Each pile gets a fixed stride in the flat array.
A home move appends the block to its own numbered pile.
Returning blocks updates position and depth for each one.

**Command loop.** Four commands update the arrays while preserving stack order.

```nim
let blockCount = nextInt(inputData, scanPos)
for base in 0 .. blockCount - 1:
  pileContents[pileSlot(base, 0)] = base
  pileSizes[base] = 1
  blockPositions[base] = base
  blockDepths[base] = 0

while true:
  let command = nextToken(inputData, scanPos)
  if command.len == 0:
    break
  if command.len == 4 and command[0] == 'q':
    break
  let isPileCommand = command.len == 4 and command[0] == 'p'
  let sourceBlock = nextInt(inputData, scanPos)
  let relation = nextToken(inputData, scanPos)
  let isOnto = relation.len == 4 and relation[1] == 'n'
  let targetBlock = nextInt(inputData, scanPos)

  var sourceBase = blockPositions[sourceBlock]
  let sourceDepth = blockDepths[sourceBlock]
  let targetBase = blockPositions[targetBlock]
  let targetDepth = blockDepths[targetBlock]

  if isPileCommand:
    if sourceBase == targetBase:
      continue
    if isOnto:
      returnBlocksAbove(targetBase, targetDepth)
    let movedCount = pileSizes[sourceBase] - sourceDepth
    let destinationBase = pileSizes[targetBase]
    var offset = 0
    while offset < movedCount:
      let movedBlock = pileContents[pileSlot(sourceBase, sourceDepth + offset)]
      pileContents[pileSlot(targetBase, destinationBase + offset)] = movedBlock
      blockPositions[movedBlock] = targetBase
      blockDepths[movedBlock] = destinationBase + offset
      offset += 1
    pileSizes[targetBase] = destinationBase + movedCount
    pileSizes[sourceBase] = sourceDepth
  else:
    returnBlocksAbove(sourceBase, sourceDepth)
    var destinationBase = targetBase
    if isOnto:
      destinationBase = blockPositions[targetBlock]
      returnBlocksAbove(destinationBase, blockDepths[targetBlock])
    sourceBase = blockPositions[sourceBlock]
    let newSourceDepth = blockDepths[sourceBlock]
    destinationBase = blockPositions[targetBlock]
    pileSizes[sourceBase] = newSourceDepth
    let newHeight = pileSizes[destinationBase]
    pileContents[pileSlot(destinationBase, newHeight)] = sourceBlock
    pileSizes[destinationBase] = newHeight + 1
    blockPositions[sourceBlock] = destinationBase
    blockDepths[sourceBlock] = newHeight
```

A same-pile command for pile leaves the world unchanged.
Onto clears the target before any blocks arrive.
Move and pile both update every relocated block's index.

**Final layout.** One line per position lists its stack from bottom to top.

```nim
for base in 0 .. blockCount - 1:
  appendOutput($base)
  appendOutput(":")
  var height = 0
  while height < pileSizes[base]:
    appendOutput(" ")
    appendOutput($pileContents[pileSlot(base, height)])
    height += 1
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Empty piles print a position and a colon only.
Blocks appear from index zero upward, so bottom comes first.
The final write drains the remaining buffer.

## Complexity

Let b be the block count and c the command count.

| phase | time | space |
|---|---|---|
| input read | one pass over the command text | one input string |
| command loop | up to b block updates per command | flat pile matrix |
| output | one line per block | block buffer |

The pile matrix stays fixed, and each command touches at most b blocks.

| measure | Big O |
|---|---|
| time | O(c times b) worst case |
| space | O(b squared) for the pile matrix |

Searching every pile for each block would add another factor of b.
