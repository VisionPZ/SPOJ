# PRHYME — Perfect Rhyme (SPOJ)

<https://www.spoj.com/problems/PRHYME/>

## Problem

For each query word, find the dictionary word with the longest common suffix that is not the query itself, breaking ties by the smallest original spelling. The output is that word, one line per query.

Input first lists the dictionary words, one per line, then an empty line, then the queries, one per line. Words contain lowercase letters and no two dictionary words are equal. Output one lowercase word per query.

| item | bound |
|---|---|
| words per part | up to 250000 |
| word length | up to 30 |
| input size | less than 5 MB |
| judge limit | 3000 ms, 1536 MB |

Total input characters bound the work, since every word is visited once when the trie is built.

Sample input:

```
perfect
rhyme
crime
time

crime
rhyme
```

Sample output:

```
time
crime
```

## Idea

Reverse every word and store the dictionary in a trie, like filing books by the letters at the end of their titles. A shared reversed prefix is exactly a shared original suffix, so walking the trie as far as the query allows finds the maximum suffix length. Each trie node keeps the two smallest original words in its subtree, which handles a query that is itself in the dictionary. Scanning the whole dictionary for every query would multiply two large word counts. One trie walk per query is the takeaway.

## Why It Works

1. Reversing words turns common suffixes into common prefixes.
2. A trie node at depth d represents one reversed prefix of length d.
3. Every dictionary word below that node shares the corresponding original suffix with the query.
4. The two smallest original words in a subtree give the best answer when the query word is one of the candidates.
5. Walking deeper always improves the suffix length, so the deepest valid candidate wins.
6. If the deepest node holds only the query word, the saved candidate from a shallower node is used.

| term | meaning |
|---|---|
| `nodeHeads` | first outgoing edge of each trie node |
| `nodeBests` | smallest original word in a subtree |
| `nodeSeconds` | second smallest original word in a subtree |
| `considerCandidate` | merges one candidate into those two slots |
| `sameAsQuery` | rejects the query word itself |

The table names the structures that make one walk per query enough.

A script trace of the sample queries shows the suffix lengths:

```text
crime vs perfect: 0
crime vs rhyme: 2
crime vs time: 3 -> time wins
rhyme vs perfect: 0
rhyme vs crime: 2
rhyme vs time: 2 -> tie, crime is smaller
```

The trace matches the sample output and shows why the tie rule matters.

## Code

**Input parsing.** One pass over the input string splits lines into words and queries.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var wordStarts = newSeq[int]()
var wordLengths = newSeq[int]()
var queryStarts = newSeq[int]()
var queryLengths = newSeq[int]()
var readingQueries = false
var lineStart = 0
for charIndex in 0 .. inputData.len - 1:
  if inputData[charIndex] == '\n':
    let lineLength = charIndex - lineStart
    if lineLength == 0:
      readingQueries = true
    elif readingQueries:
      queryStarts.add lineStart
      queryLengths.add lineLength
    else:
      wordStarts.add lineStart
      wordLengths.add lineLength
    lineStart = charIndex + 1
```

Offsets avoid copying every word into a new string.
The empty line switches from dictionary words to queries.
Every line ends with a newline because the reader appends one.

**Word comparison.** Original spelling decides ties.

```nim
proc compareWords(firstStart: int, firstLength: int, secondStart: int, secondLength: int): int =
  let commonLength = min(firstLength, secondLength)
  for offset in 0 .. commonLength - 1:
    let firstChar = inputData[firstStart + offset]
    let secondChar = inputData[secondStart + offset]
    if firstChar < secondChar:
      return -1
    if firstChar > secondChar:
      return 1
  if firstLength < secondLength:
    return -1
  if firstLength > secondLength:
    return 1
  return 0

proc sameAsQuery(queryStart: int, queryLength: int, wordIndex: int): bool =
  let wordLength = wordLengths[wordIndex]
  if wordLength != queryLength:
    return false
  for offset in 0 .. wordLength - 1:
    if inputData[wordStarts[wordIndex] + offset] != inputData[queryStart + offset]:
      return false
  return true
```

A shorter word that is a prefix sorts first.
The equality check compares characters without allocating.
Both helpers read directly from the single input string.

**Candidate merge.** Each node keeps its two best original words.

```nim
proc considerCandidate(candidate: int32, bestValue: var int32, secondValue: var int32) =
  if candidate < 0:
    return
  if bestValue < 0 or compareWords(wordStarts[int(bestValue)], wordLengths[int(bestValue)],
                                   wordStarts[int(candidate)], wordLengths[int(candidate)]) > 0:
    if bestValue != candidate:
      secondValue = bestValue
      bestValue = candidate
  elif candidate != bestValue and (secondValue < 0 or
       compareWords(wordStarts[int(secondValue)], wordLengths[int(secondValue)],
                    wordStarts[int(candidate)], wordLengths[int(candidate)]) > 0):
    secondValue = candidate
```

The second slot covers queries that equal the best word.
Duplicates are ignored because dictionary words are unique.
Each comparison costs at most the word length.

**Trie construction.** Words are inserted from their last letter to their first.

```nim
var nodeHeads = newSeq[int32]()
var nodeWords = newSeq[int32]()
var nodeBests = newSeq[int32]()
var nodeSeconds = newSeq[int32]()
var edgeLetters = newSeq[int32]()
var edgeChildren = newSeq[int32]()
var edgeNexts = newSeq[int32]()
nodeHeads.add 0
nodeWords.add -1
nodeBests.add -1
nodeSeconds.add -1

for wordIndex in 0 .. wordStarts.len - 1:
  var currentNode = 0
  let wordStart = wordStarts[wordIndex]
  let wordLength = wordLengths[wordIndex]
  var reverseOffset = wordLength - 1
  while reverseOffset >= 0:
    let letterValue = int32(int(inputData[wordStart + reverseOffset]) - 96)
    var edgeIndex = nodeHeads[currentNode]
    var matchedEdge: int32 = 0
    while edgeIndex != 0:
      if edgeLetters[int(edgeIndex) - 1] == letterValue:
        matchedEdge = edgeIndex
        break
      edgeIndex = edgeNexts[int(edgeIndex) - 1]
    if matchedEdge == 0:
      let newNodeIndex = nodeHeads.len
      nodeHeads.add 0
      nodeWords.add -1
      nodeBests.add -1
      nodeSeconds.add -1
      let newEdgeIndex = edgeLetters.len + 1
      edgeLetters.add letterValue
      edgeChildren.add int32(newNodeIndex)
      edgeNexts.add nodeHeads[currentNode]
      nodeHeads[currentNode] = int32(newEdgeIndex)
      matchedEdge = int32(newEdgeIndex)
    currentNode = int(edgeChildren[int(matchedEdge) - 1])
    reverseOffset -= 1
  nodeWords[currentNode] = int32(wordIndex)
```

Edges use one-based numbers so zero can mean no edge.
Child nodes always receive a larger number than their parent.
Sibling lists keep the structure compact for large dictionaries.

**Bottom-up merge.** Children are processed before their parents.

```nim
for nodeIndex in countdown(nodeHeads.len - 1, 0):
  var bestValue = nodeWords[nodeIndex]
  var secondValue: int32 = -1
  var edgeIndex = nodeHeads[nodeIndex]
  while edgeIndex != 0:
    let childNode = int(edgeChildren[int(edgeIndex) - 1])
    considerCandidate(nodeBests[childNode], bestValue, secondValue)
    considerCandidate(nodeSeconds[childNode], bestValue, secondValue)
    edgeIndex = edgeNexts[int(edgeIndex) - 1]
  nodeBests[nodeIndex] = bestValue
  nodeSeconds[nodeIndex] = secondValue
```

The countdown order follows the creation order of nodes.
A terminal word is always the first candidate at its node.
The root ends with the two smallest words in the dictionary.

**Queries.** Each query walks the reversed trie and keeps the deepest valid word.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

for queryIndex in 0 .. queryStarts.len - 1:
  let queryStart = queryStarts[queryIndex]
  let queryLength = queryLengths[queryIndex]
  var answerWord: int32 = -1
  var currentNode = 0
  var matchedDepth = 0
  while true:
    var candidate: int32 = -1
    let bestValue = nodeBests[currentNode]
    let secondValue = nodeSeconds[currentNode]
    if bestValue >= 0 and not sameAsQuery(queryStart, queryLength, int(bestValue)):
      candidate = bestValue
    elif secondValue >= 0 and not sameAsQuery(queryStart, queryLength, int(secondValue)):
      candidate = secondValue
    if candidate >= 0:
      answerWord = candidate
    if matchedDepth >= queryLength:
      break
    let letterValue = int32(int(inputData[queryStart + queryLength - 1 - matchedDepth]) - 96)
    var edgeIndex = nodeHeads[currentNode]
    var matchedEdge: int32 = 0
    while edgeIndex != 0:
      if edgeLetters[int(edgeIndex) - 1] == letterValue:
        matchedEdge = edgeIndex
        break
      edgeIndex = edgeNexts[int(edgeIndex) - 1]
    if matchedEdge == 0:
      break
    currentNode = int(edgeChildren[int(matchedEdge) - 1])
    matchedDepth += 1
  if answerWord < 0:
    answerWord = nodeBests[0]
  let answerStart = wordStarts[int(answerWord)]
  let answerLength = wordLengths[int(answerWord)]
  var answerText = ""
  for offset in 0 .. answerLength - 1:
    answerText.add inputData[answerStart + offset]
  appendOutput(answerText)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A deeper candidate overwrites the earlier one.
A node holding only the query word keeps the earlier answer.
Fallback to the root cannot trigger when the dictionary has another word.

## Complexity

The trie is built once and queried once per word.

| phase | time | space |
|---|---|---|
| input read | one pass over input characters | one input string |
| trie build | one step per dictionary character | node and edge arrays |
| bottom-up merge | one merge per node | constant working space |
| queries | one trie walk per query | block buffer |

Trie construction and query walks dominate the run.

| measure | Big O |
|---|---|
| time | O(total input characters times alphabet lookup) |
| space | O(total dictionary characters) |

Checking every dictionary word for every query would cost N times Q comparisons.
The trie reduces each query to one short walk, and that is the takeaway.
