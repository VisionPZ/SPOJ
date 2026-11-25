# GAMETIME — Game Time (SPOJ)

<https://www.spoj.com/problems/GAMETIME/>

## Problem

A castle family forms parent links between Koopas. Mario defeats a castle at a known time cost; defeating the second child of a Koopa forces that Koopa to be defeated at once, which can cascade upward. The game ends when the King in castle N-1 falls. Report the largest total time Mario can spend before that moment.

Each case gives N, N defeat times T[i], and N parent indices P[i], where -1 means no parent. A case with N = 0 ends the input. Print one maximal total per case.

| item | bound |
|---|---|
| castles N | 1 to 100000 |
| defeat time T[i] | 1 to 100 |
| parent P[i] | -1 or 0 to N-1 |
| judge limit | 1000 ms, 1536 MB |

Parent links may form several trees; only the King ends the game.

Sample input:

```
5
1 2 3 4 5
4 4 4 4 -1
5
2 2 2 2 2
1 2 3 4 -1
9
1 1 1 1 1 1 1 1 1
6 6 6 7 7 7 8 8 -1
0
```

Sample output:

```
12
10
8
```

## Idea

Treat the parent links as a family tree and keep two scores per castle, like tracking both an untouched pile and a pile whose bottom card has been taken. One score is the best total with that Koopa still unbeaten; the other is the best total ending exactly when that Koopa falls. Each child offers either its untouched score or its full subtree total. Scanning every possible play order would revisit exponential states; the tree walk settles each castle once. The takeaway is that two scores per node capture every legal play.

## Why It Works

1. A Koopa falls when a second child has been defeated, or when Mario picks it directly.
2. While a Koopa stands unbeaten, at most one child can be fully defeated.
3. Once a Koopa falls, its remaining children can still be defeated later.
4. The untouched score adds all child untouched scores plus the best single child gain.
5. The ending score adds all untouched child scores plus the best gain from one full child and one ending child.
6. The King's ending score is the answer; other root trees can be fully defeated first.

| term | meaning |
|---|---|
| `subtreeTotals` | sum of defeat times in one subtree |
| `unbeatenScores` | best total with the Koopa still unbeaten |
| `lastScores` | best total ending with the Koopa defeated |
| `bestFullGain` | largest gain from defeating one child fully |
| `bestPair` | gain from one full child plus one ending child |

All totals fit in 64 bits since N is at most 100000.

A script trace of the third sample case gives these numbers:

```
node 6 untouched 1 ending 3 full subtree 4
node 7 untouched 1 ending 3 full subtree 4
King untouched 5 best full gain 3 pair gain 5
answer 1 + 2 + 5 = 8
```

The script value 8 matches the printed sample answer.

## Code

**Input and scanner.** The hand reader loads each case, and the scanner handles negative parents.

```nim
const flushBlockBytes = 1 shl 17
const noParent = -1

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

The minus branch reads -1 parent links.
Whitespace and line breaks need no special handling.
The position advances past one integer per call.

**Output buffer.** One buffer holds all answers.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes at 131072 bytes.
A final write clears any remainder.
No write happens per castle.

**Tree build and postorder.** Child links are stored as sibling lists.

```nim
while true:
  let castleCount = nextInt(inputData, scanPos)
  if castleCount == 0:
    break
  var conquerTimes = newSeq[int64](castleCount)
  var parentNodes = newSeq[int](castleCount)
  for castleIndex in 0 .. castleCount - 1:
    conquerTimes[castleIndex] = int64(nextInt(inputData, scanPos))
  for castleIndex in 0 .. castleCount - 1:
    parentNodes[castleIndex] = nextInt(inputData, scanPos)
  var childHeads = newSeq[int](castleCount)
  var nextSiblings = newSeq[int](castleCount)
  for castleIndex in 0 .. castleCount - 1:
    childHeads[castleIndex] = noParent
    nextSiblings[castleIndex] = noParent
  for castleIndex in 0 .. castleCount - 1:
    let parentNode = parentNodes[castleIndex]
    if parentNode >= 0:
      nextSiblings[castleIndex] = childHeads[parentNode]
      childHeads[parentNode] = castleIndex
  var traversalOrder = newSeq[int](castleCount)
  var traversalStack = newSeq[int](castleCount)
  var orderLength = 0
  var stackLength = 0
  for castleIndex in 0 .. castleCount - 1:
    if parentNodes[castleIndex] == noParent:
      traversalStack[stackLength] = castleIndex
      stackLength += 1
  while stackLength > 0:
    stackLength -= 1
    let currentNode = traversalStack[stackLength]
    traversalOrder[orderLength] = currentNode
    orderLength += 1
    var childNode = childHeads[currentNode]
    while childNode != noParent:
      traversalStack[stackLength] = childNode
      stackLength += 1
      childNode = nextSiblings[childNode]
```

Each castle gets exactly one child-list entry.
The stack walk avoids recursion at 100000 nodes.
Reversing the order visits children before parents.

**Tree scores.** The reverse walk combines two child gains per castle.

```nim
  var subtreeTotals = newSeq[int64](castleCount)
  var unbeatenScores = newSeq[int64](castleCount)
  var lastScores = newSeq[int64](castleCount)
  var reverseIndex = orderLength - 1
  while reverseIndex >= 0:
    let currentNode = traversalOrder[reverseIndex]
    var baseScore: int64 = 0
    var subtreeTotal: int64 = conquerTimes[currentNode]
    var bestFullGain: int64 = 0
    var secondFullGain: int64 = 0
    var bestFullChild = noParent
    var childNode = childHeads[currentNode]
    while childNode != noParent:
      baseScore = baseScore + unbeatenScores[childNode]
      subtreeTotal = subtreeTotal + subtreeTotals[childNode]
      let fullGain = subtreeTotals[childNode] - unbeatenScores[childNode]
      if fullGain > bestFullGain:
        secondFullGain = bestFullGain
        bestFullGain = fullGain
        bestFullChild = childNode
      elif fullGain > secondFullGain:
        secondFullGain = fullGain
      childNode = nextSiblings[childNode]
    unbeatenScores[currentNode] = baseScore + bestFullGain
    var bestPair: int64 = 0
    childNode = childHeads[currentNode]
    while childNode != noParent:
      let fullGainExcluding = if childNode == bestFullChild: secondFullGain else: bestFullGain
      let triggerGain = lastScores[childNode] - unbeatenScores[childNode]
      let pairScore = fullGainExcluding + triggerGain
      if pairScore > bestPair:
        bestPair = pairScore
      childNode = nextSiblings[childNode]
    if bestPair > bestFullGain:
      lastScores[currentNode] = conquerTimes[currentNode] + baseScore + bestPair
    else:
      lastScores[currentNode] = conquerTimes[currentNode] + baseScore + bestFullGain
    subtreeTotals[currentNode] = subtreeTotal
    reverseIndex -= 1
  let kingCastle = castleCount - 1
  var bestTime: int64 = 0
  for castleIndex in 0 .. castleCount - 1:
    if parentNodes[castleIndex] != noParent:
      continue
    if castleIndex == kingCastle:
      bestTime = bestTime + lastScores[castleIndex]
    else:
      bestTime = bestTime + subtreeTotals[castleIndex]
  appendOutput($bestTime)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The second gain prevents using one child twice.
Other root trees add their full subtree totals.
The King contributes its ending score.

## Complexity

Each castle is pushed, popped, and scored once.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| tree build | one pass over parent links | two link arrays |
| score walk | two passes over child lists | three score arrays |
| output | one buffered write per block | block buffer |

The score walk dominates each case.

| measure | Big O |
|---|---|
| time | O(N) per case |
| space | O(N) |

Trying every defeat order would take far longer than this linear walk.
The two scores keep the whole game in one bottom-up pass.
