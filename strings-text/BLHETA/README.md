# BLHETA — Legend of Heta (SPOJ)

<https://www.spoj.com/problems/BLHETA/>

## Problem

Read a long uppercase string one letter at a time and delete any spell from the book as soon as it appears at the end of what remains. When several spells match at once, use the one listed first. Report the surviving string.

Input is a line of up to 100000 uppercase letters, then `N` from 1 to 100, then `N` spell lines of length 1 to 100. Output one line with the final string, which may be empty.

| Item | Bound |
|---|---|
| Source length | 1 to 100000 |
| Spell count | 1 to 100 |
| Spell length | 1 to 100 |
| Judge limit | 1000 ms, 1536 MB |

The product of source length and spell length rules out rescanning the whole string per spell.

The first sample uses two spells on a repeated pattern:

```
KUKUKAKIKUKAKEKKUKAKAKKUKAKUKAKU
2
KEK
UK
```

The expected output is:

```
KAKIKAKAKAKKAKAKU
```

Each `UK` or `KEK` disappears when its last letter arrives.

## Idea

Keep the surviving letters on a stack, like a text editor that undoes a typed word the moment it is completed. Store the spells backward in a trie so one backward walk of the stack finds every matching suffix. Pick the match with the smallest book index, delete it, and check again. Rechecking each typed letter over all spells would cost far more.

## Why It Works

1. A spell can only be detected when its final letter arrives.
2. Therefore every match is a suffix of the current stack.
3. A reversed trie walks the stack backward and visits exactly those suffixes.
4. Each terminal trie node stores the lowest book index of spells ending there.
5. After a deletion, the new stack may form another spell, so the check repeats.
6. Every deletion removes at least one letter, so the loop always ends.

| Term | Meaning |
|---|---|
| `trieChildren` | flat child table for the reversed trie |
| `trieBestIndex` | smallest book index ending at each node |
| `trieSpellLength` | length of the spell ending at each node |
| `survivorChars` | stack of letters still alive |

The table names the four pieces of state.

A script-traced run on the fourth sample:

```
read C  -> stack C
read A  -> stack CA
read B  -> stack CAB, suffix AB matches spell 1, delete -> stack C
read A  -> stack CA
read I  -> stack CAI, no match
```

The final stack is `CAI`, matching the sample output.

## Code

**Input and scanners.** Two hand readers split uppercase words from integer counts.

```nim
const flushBlockBytes = 1 shl 17
const alphabetSize = 26
const missingIndex = 1000000000

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
  while pos < data.len and (data[pos] < 'A' or data[pos] > 'Z'):
    pos += 1
  var word = ""
  while pos < data.len and data[pos] >= 'A' and data[pos] <= 'Z':
    word.add data[pos]
    pos += 1
  return word

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The word scanner reads only uppercase letters.
The integer scanner handles the spell count.
Both skip every line break.

**Reversed trie.** Spells are inserted from their last letter to their first.

```nim
var trieChildren = newSeq[int](alphabetSize)
for childIndex in 0 .. alphabetSize - 1:
  trieChildren[childIndex] = -1
var trieBestIndex = newSeq[int](1)
var trieSpellLength = newSeq[int](1)
trieBestIndex[0] = missingIndex
trieSpellLength[0] = 0
var trieNodeCount = 1

proc addTrieNode() =
  trieChildren.setLen(trieChildren.len + alphabetSize)
  let baseIndex = trieChildren.len - alphabetSize
  for childIndex in 0 .. alphabetSize - 1:
    trieChildren[baseIndex + childIndex] = -1
  trieBestIndex.add missingIndex
  trieSpellLength.add 0
  trieNodeCount += 1

proc insertSpell(spell: string, bookIndex: int) =
  var nodeIndex = 0
  var charIndex = spell.len - 1
  while charIndex >= 0:
    let letterIndex = int(spell[charIndex]) - 65
    let baseIndex = nodeIndex * alphabetSize
    var childIndex = trieChildren[baseIndex + letterIndex]
    if childIndex < 0:
      childIndex = trieNodeCount
      addTrieNode()
      trieChildren[baseIndex + letterIndex] = childIndex
    nodeIndex = childIndex
    charIndex -= 1
  if bookIndex < trieBestIndex[nodeIndex]:
    trieBestIndex[nodeIndex] = bookIndex
    trieSpellLength[nodeIndex] = spell.len
```

Minus one marks a missing child edge.
Duplicate spells keep the earlier book index.
The root holds no spell.

**Stack processing.** Each typed letter triggers a backward walk and repeated deletions.

```nim
let sourceWord = nextWord(inputData, scanPos)
let spellCount = nextInt(inputData, scanPos)
for spellIndex in 0 .. spellCount - 1:
  let spellWord = nextWord(inputData, scanPos)
  insertSpell(spellWord, spellIndex)

var survivorChars = ""
for sourceChar in sourceWord:
  survivorChars.add sourceChar
  while true:
    var nodeIndex = 0
    var stackCursor = survivorChars.len - 1
    var bestBookIndex = missingIndex
    var deleteLength = 0
    while stackCursor >= 0:
      let letterIndex = int(survivorChars[stackCursor]) - 65
      let baseIndex = nodeIndex * alphabetSize
      let childIndex = trieChildren[baseIndex + letterIndex]
      if childIndex < 0:
        break
      nodeIndex = childIndex
      stackCursor -= 1
      if trieBestIndex[nodeIndex] < bestBookIndex:
        bestBookIndex = trieBestIndex[nodeIndex]
        deleteLength = trieSpellLength[nodeIndex]
    if bestBookIndex >= missingIndex:
      break
    survivorChars.setLen(survivorChars.len - deleteLength)

appendOutput(survivorChars)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The walk stops when no child edge exists.
The smallest book index wins among all suffix matches.
The final flush writes the surviving string.

## Complexity

Trie setup is bounded by the spell text, and stack work depends on typed letters.

| Phase | Time | Space |
|---|---|---|
| Trie build | one step per spell letter | 26 edges per node |
| Stack processing | up to the longest spell per typed letter | one char per survivor |
| Output | one line | block buffer |

Every phase stays linear in its own input size.

| Measure | Big O |
|---|---|
| Time | O(source length × longest spell) |
| Space | O(total spell length + source length) |

Testing every spell at every letter would cost O(source length × spell count × spell length) instead.
