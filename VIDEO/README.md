# VIDEO — Video game combos (SPOJ)
<https://www.spoj.com/problems/VIDEO/>

## Problem

Bessie presses exactly K buttons from A, B, and C. Each of N target strings scores one point every time it ends at the current position. Report the largest score.

Input starts with N and K. The next N lines hold the distinct target strings, each of length 1 to 15. Output one line with the maximum score.

| item | bound |
|---|---|
| combos N | 1 to 20 |
| presses K | 1 to 1000 |
| combo length | 1 to 15 |
| judge limit | 100 ms, 1536 MB |

Combos may overlap, may end together, and may score repeatedly.

Sample input:

```
3 7
ABA
CB
ABACB
```

Sample output:

```
4
```

## Idea

Remember only the last few letters, like a reader who keeps the tail of a word in mind while scanning text.

The algorithm builds an Aho-Corasick automaton over the combos. Each state stores the score earned when that state is reached. A step-by-step dynamic program tracks the best score at every state after each press.

Enumerating all button strings costs 3^K, which is enormous. The automaton has at most 301 states, so each press costs O(states) and the whole run costs O(K × states).

Score inheritance through failure links makes overlapping combos count at the same position.

## Why It Works

1. A trie state represents the longest combo prefix that is a suffix of the pressed string.
2. Failure links point to the next shorter suffix state.
3. Adding a link target's score to a state counts every combo ending there.
4. Pressing one letter moves from a state to one successor state.
5. Keeping the best score per state after each press gives the optimum after K presses.

| term | meaning |
|---|---|
| `transitionTable` | next state for each state and letter |
| `failureLinks` | fallback state for suffix matches |
| `nodeScores` | points earned on arrival at a state |
| `currentScores` | best score at each state after the last press |

The automaton has at most one node per combo letter, so it stays under 301 states.

For the sample, the sequence ABACB scores 3. It ends ABA at position 3, ABACB at position 5, and CB at position 5.

| press | state suffix | points gained | running best |
|---|---|---|---|
| A | A | 0 | 0 |
| B | AB | 0 | 0 |
| A | ABA | 1 | 1 |
| C | ABAC | 0 | 1 |
| B | ABACB | 1 + 1 | 3 |
| C | CB | 1 | 4 |
| B | B | 0 | 4 |

The sequence ABACBCB scores 4, which matches the sample output.

Scores use plain integers because K ≤ 1000 and at most 20 combos score per press. Unreachable states use `impossibleScore` and are skipped.

## Code

**Input, word reader, and output setup.** The reader loads numbers and combo words from one string.

```nim
const flushBlockBytes = 1 shl 17
const buttonLetters = 3
const firstLetter = 65
const impossibleScore = -1000000000

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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < 'A' or data[pos] > 'C'):
    pos += 1
  var word = ""
  while pos < data.len and data[pos] >= 'A' and data[pos] <= 'C':
    word.add data[pos]
    pos += 1
  return word
```

The word reader accepts only A, B, and C.
The number scanner skips the combo lines when needed.
All tokens come from the single input string.

**Trie construction.** Each combo adds nodes and one score at its final node.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let comboCount = nextInt(inputData, scanPos)
let pressCount = nextInt(inputData, scanPos)
var transitionTable = newSeq[int](buttonLetters)
for letterIndex in 0 .. buttonLetters - 1:
  transitionTable[letterIndex] = -1
var failureLinks = newSeq[int](1)
var nodeScores = newSeq[int](1)
var nodeCount = 1
for comboIndex in 0 .. comboCount - 1:
  let comboWord = nextWord(inputData, scanPos)
  var currentNode = 0
  for letterIndex in 0 .. comboWord.len - 1:
    let letterValue = int(comboWord[letterIndex]) - firstLetter
    var targetNode = transitionTable[currentNode * buttonLetters + letterValue]
    if targetNode < 0:
      targetNode = nodeCount
      nodeCount += 1
      for addedLetter in 0 .. buttonLetters - 1:
        transitionTable.add -1
      failureLinks.add 0
      nodeScores.add 0
      transitionTable[currentNode * buttonLetters + letterValue] = targetNode
    currentNode = targetNode
  nodeScores[currentNode] += 1
```

Missing transitions start at minus one.
New nodes extend the flat transition table by three slots.
Shared prefixes reuse the same trie nodes.

**Failure links.** A breadth-first pass completes every transition and inherits scores.

```nim
var traversalQueue = newSeq[int](nodeCount)
var queueHead = 0
var queueTail = 0
for letterIndex in 0 .. buttonLetters - 1:
  let childNode = transitionTable[letterIndex]
  if childNode < 0:
    transitionTable[letterIndex] = 0
  else:
    failureLinks[childNode] = 0
    traversalQueue[queueTail] = childNode
    queueTail += 1
while queueHead < queueTail:
  let currentNode = traversalQueue[queueHead]
  queueHead += 1
  nodeScores[currentNode] += nodeScores[failureLinks[currentNode]]
  for letterIndex in 0 .. buttonLetters - 1:
    let childNode = transitionTable[currentNode * buttonLetters + letterIndex]
    if childNode < 0:
      transitionTable[currentNode * buttonLetters + letterIndex] = transitionTable[failureLinks[currentNode] * buttonLetters + letterIndex]
    else:
      failureLinks[childNode] = transitionTable[failureLinks[currentNode] * buttonLetters + letterIndex]
      traversalQueue[queueTail] = childNode
      queueTail += 1
```

Each node enters the queue once.
Missing transitions copy the fallback state's transition.
Inherited scores count suffixes that end at the same position.

**Press dynamic program.** Each press advances every reachable state by one letter.

```nim
var currentScores = newSeq[int](nodeCount)
var nextScores = newSeq[int](nodeCount)
for nodeIndex in 0 .. nodeCount - 1:
  currentScores[nodeIndex] = impossibleScore
currentScores[0] = 0
for pressIndex in 0 .. pressCount - 1:
  for nodeIndex in 0 .. nodeCount - 1:
    nextScores[nodeIndex] = impossibleScore
  for stateIndex in 0 .. nodeCount - 1:
    let baseScore = currentScores[stateIndex]
    if baseScore <= impossibleScore div 2:
      continue
    for letterIndex in 0 .. buttonLetters - 1:
      let targetNode = transitionTable[stateIndex * buttonLetters + letterIndex]
      let candidateScore = baseScore + nodeScores[targetNode]
      if candidateScore > nextScores[targetNode]:
        nextScores[targetNode] = candidateScore
  swap currentScores, nextScores
var bestScore = 0
for nodeIndex in 0 .. nodeCount - 1:
  if currentScores[nodeIndex] > bestScore:
    bestScore = currentScores[nodeIndex]
appendOutput($bestScore)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The start state begins with score zero.
Unreachable states carry `impossibleScore` and are skipped.
The answer is the best score after the last press.

## Complexity

The automaton is small, and one pass over its states handles each press.

| phase | time | space |
|---|---|---|
| trie build | one step per combo letter | one node per letter |
| failure links | three transitions per node | queue of nodes |
| press dynamic program | three updates per state per press | two score arrays |
| output | one line | block buffer |

The automaton holds at most 301 nodes because there are 20 combos of length at most 15.

| measure | Big O |
|---|---|
| time | O(K × states × 3) |
| space | O(states) |

Trying every button string would cost O(3^K), which grows far beyond the judge limit.

The automaton and dynamic program reduce the search to a few hundred states per press.
