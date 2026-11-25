# STRMATCH — Match me if you can (SPOJ)

<https://www.spoj.com/problems/STRMATCH/>

## Problem

For each query string, report how many times it occurs in one fixed source string, counting overlapping matches. Think of a library index that maps every possible excerpt to the number of pages holding it. The source length is small, while the total query length is large.

| item | bound |
|---|---|
| source length N | up to 3000 |
| query count Q | positive |
| total query length | at most 500000 |
| judge limit | 1000 ms, 1536 MB |

The first line holds `N` and `Q`, followed by the source string and then one query per line.

Sample input:

```
7 5
acababa
a
bb
caba
aba
karp
```

Sample output:

```
4
0
1
2
0
```

## Idea

Build a suffix automaton once, like a compressed map of every substring, and walk each query through it in linear time. Each state stores the number of end positions of its substrings, which is exactly the occurrence count. Enumerating all substrings and hashing each one costs quadratic memory and time. The takeaway is that one compact automaton answers every query in time proportional to the query length.

## Why It Works

1. A suffix automaton is a finite-state machine accepting every substring of the source.
2. A string labels exactly one path from the start state, or no path at all.
3. The state reached by a query represents all substrings sharing that end-position set.
4. Each extension adds one end position, and suffix links pass those positions upward.
5. Processing states by decreasing length propagates all end-position counts correctly.

| term | meaning |
|---|---|
| `stateList` | all suffix automaton states |
| `nextStates` | transition table for one state |
| `suffixLink` | link to the state of the longest proper suffix |
| `stateLength` | longest substring represented by the state |
| `occurrences` | number of end positions propagated into the state |

The worked example walks queries through the automaton built from `acababa`, with counts produced by the generator's brute-force finder.

| query | automaton walk | occurrences |
|---|---|---|
| `a` | reaches the state for `a` | 4 |
| `bb` | missing transition | 0 |
| `caba` | reaches the state for `caba` | 1 |
| `aba` | reaches the state for `aba` | 2 |
| `karp` | missing transition | 0 |

A missing transition ends the walk immediately, so the answer is zero. Counting sort orders all automaton states by length before the propagation pass.

## Code

**State type and reader.** Each state keeps transitions, a suffix link, a length, and an occurrence count.

```nim
const flushBlockBytes = 1 shl 17
const alphabetSize = 26

type SuffixState = object
  nextStates: array[0 .. alphabetSize - 1, int]
  suffixLink: int
  stateLength: int
  occurrences: int

proc resetState(state: var SuffixState) =
  for letterIndex in 0 .. alphabetSize - 1:
    state.nextStates[letterIndex] = -1
  state.suffixLink = -1
  state.stateLength = 0
  state.occurrences = 0
```

The transition array uses `-1` for no edge.
New states start with an empty transition table.
The reader collects input before any automaton work.

```nim
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
  while pos < data.len and (data[pos] < 'a' or data[pos] > 'z'):
    pos += 1
  var word = ""
  while pos < data.len and data[pos] >= 'a' and data[pos] <= 'z':
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

Whitespace separates the header, source, and queries.
The output buffer batches all answer lines.

**Automaton construction.** Each source character extends the automaton and may clone a state.

```nim
let textLength = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)
let sourceText = nextWord(inputData, scanPos)

var stateList = newSeq[SuffixState](2 * textLength + 2)
var stateCount = 1
var lastState = 0
resetState(stateList[0])

for charIndex in 0 .. textLength - 1:
  let letterIndex = int(sourceText[charIndex]) - 97
  let currentState = stateCount
  stateCount += 1
  resetState(stateList[currentState])
  stateList[currentState].stateLength = stateList[lastState].stateLength + 1
  stateList[currentState].occurrences = 1
  var walkState = lastState
  while walkState != -1 and stateList[walkState].nextStates[letterIndex] == -1:
    stateList[walkState].nextStates[letterIndex] = currentState
    walkState = stateList[walkState].suffixLink
  if walkState == -1:
    stateList[currentState].suffixLink = 0
  else:
    let nextState = stateList[walkState].nextStates[letterIndex]
    if stateList[walkState].stateLength + 1 == stateList[nextState].stateLength:
      stateList[currentState].suffixLink = nextState
    else:
      let cloneState = stateCount
      stateCount += 1
      stateList[cloneState] = stateList[nextState]
      stateList[cloneState].stateLength = stateList[walkState].stateLength + 1
      stateList[cloneState].occurrences = 0
      while walkState != -1 and stateList[walkState].nextStates[letterIndex] == nextState:
        stateList[walkState].nextStates[letterIndex] = cloneState
        walkState = stateList[walkState].suffixLink
      stateList[nextState].suffixLink = cloneState
      stateList[currentState].suffixLink = cloneState
  lastState = currentState
```

Each extension starts with one new end position.
Clones begin with zero end positions.
Suffix links are redirected only when a state must split.

**Occurrence propagation and queries.** Counting sort gives reverse length order, then queries walk the transitions.

```nim
var countsByLength = newSeq[int](textLength + 1)
for stateIndex in 0 .. stateCount - 1:
  countsByLength[stateList[stateIndex].stateLength] += 1
var lengthTotal = 0
for lengthValue in 0 .. textLength:
  let previousCount = lengthTotal
  lengthTotal += countsByLength[lengthValue]
  countsByLength[lengthValue] = previousCount
var stateOrder = newSeq[int](stateCount)
for stateIndex in 0 .. stateCount - 1:
  let lengthValue = stateList[stateIndex].stateLength
  countsByLength[lengthValue] += 1
  stateOrder[countsByLength[lengthValue] - 1] = stateIndex
var orderIndex = stateCount - 1
while orderIndex >= 0:
  let stateIndex = stateOrder[orderIndex]
  let linkState = stateList[stateIndex].suffixLink
  if linkState != -1:
    stateList[linkState].occurrences += stateList[stateIndex].occurrences
  orderIndex -= 1

for queryIndex in 0 .. queryCount - 1:
  let queryWord = nextWord(inputData, scanPos)
  var activeState = 0
  var fullyMatched = true
  for charIndex in 0 .. queryWord.len - 1:
    let letterIndex = int(queryWord[charIndex]) - 97
    if letterIndex < 0 or letterIndex >= alphabetSize:
      fullyMatched = false
      break
    let nextState = stateList[activeState].nextStates[letterIndex]
    if nextState == -1:
      fullyMatched = false
      break
    activeState = nextState
  if fullyMatched:
    appendOutput($stateList[activeState].occurrences)
  else:
    appendOutput("0")
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Longer states pass counts to their suffix links.
A complete walk prints the state's occurrence count.
A missing edge prints zero and moves to the next query.

## Complexity

The automaton has at most twice the source length in states.

| phase | time | space |
|---|---|---|
| construction | one transition per character plus cloning | at most 2N states |
| propagation | one pass over states | counting array of N |
| queries | one transition per query character | block buffer |

| measure | Big O |
|---|---|
| time | O(N alphabet + total query length) |
| space | O(N alphabet) |

Scanning the source once per query would cost O(N times total query length). The takeaway is that the automaton pays for construction once and answers each query in linear time.
