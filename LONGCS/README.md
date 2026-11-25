# LONGCS — Longest Common Substring (SPOJ)
<https://www.spoj.com/problems/LONGCS/>

## Problem

Find the length of the longest substring that appears in every one of K given lowercase strings. Print one length per test case.

Input starts with the test count. Each test gives K, followed by K strings.

| item | bound |
|---|---|
| tests | 1 to 20 |
| strings per test K | 1 to 10 |
| string length | up to 10000 |
| alphabet | a to z |
| judge limit | 1000 ms, 1536 MB |

A substring is a consecutive block of characters. The answer is an integer length.

Sample input:

```
2
2
aaabbb
bbaabb
3
icode
coder
contest
```

Sample output:

```
4
2
```

## Idea

Index every substring of the first string once, then read each other string through that index, like using one map to check several travellers. A suffix automaton stores all those substrings in a small graph. Each state keeps the longest match seen in every string.

Building the automaton costs one pass over the first string. Scanning another string costs one pass over its characters. A counting sort is added once so matches can be pushed from longer states to their suffix links.

## Why It Works

1. A suffix automaton state represents many substrings with lengths in one interval.
2. The maximum length in that interval is stored in `maxLength`.
3. Reading a string through the automaton records the longest match ending at each state.
4. Moving to a suffix link carries that match to the parent's shorter interval.
5. A state contributes its shortest surviving match only when all strings reach its minimum length.

| term | meaning |
|---|---|
| `suffixLink` | link to the state holding shorter suffixes |
| `maxLength` | longest substring represented by a state |
| `commonLengths` | longest match found in every processed string |
| `matchLengths` | longest match found in the current string |

For `aaabbb` and `bbaabb`, the automaton records the match `aabb` with length 4. No longer block appears in both strings, so the answer is 4. For `icode`, `coder` and `contest`, the shared block `co` has length 2.

## Code

**Parsing and buffering.** Tokens are read by hand from a single input string.

```nim
const flushBlockBytes = 1 shl 17
const alphabetSize = 26

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

The word scanner skips the integer separators.
Each answer waits in the block buffer.
The scanner works with any line break layout.

**Automaton construction.** Each added character extends the automaton by one state, sometimes cloning another.

```nim
var suffixLink: seq[int] = @[]
var maxLength: seq[int] = @[]
var transitions: seq[seq[int]] = @[]
var lastState = 0

proc newAutomatonState(lengthValue: int): int =
  let stateIndex = suffixLink.len
  suffixLink.add -1
  maxLength.add lengthValue
  var row = newSeq[int](alphabetSize)
  for letterIndex in 0 .. alphabetSize - 1:
    row[letterIndex] = -1
  transitions.add row
  return stateIndex

proc extendAutomaton(letterIndex: int) =
  let currentState = newAutomatonState(maxLength[lastState] + 1)
  var walkState = lastState
  while walkState != -1 and transitions[walkState][letterIndex] == -1:
    transitions[walkState][letterIndex] = currentState
    walkState = suffixLink[walkState]
  if walkState == -1:
    suffixLink[currentState] = 0
  else:
    let nextState = transitions[walkState][letterIndex]
    if maxLength[walkState] + 1 == maxLength[nextState]:
      suffixLink[currentState] = nextState
    else:
      let cloneState = newAutomatonState(maxLength[walkState] + 1)
      for index in 0 .. alphabetSize - 1:
        transitions[cloneState][index] = transitions[nextState][index]
      suffixLink[cloneState] = suffixLink[nextState]
      while walkState != -1 and transitions[walkState][letterIndex] == nextState:
        transitions[walkState][letterIndex] = cloneState
        walkState = suffixLink[walkState]
      suffixLink[nextState] = cloneState
      suffixLink[currentState] = cloneState
  lastState = currentState
```

Missing transitions hold -1.
A clone copies the transitions of the state it splits.
The root state has index zero and maximum length zero.

**Initial order.** A counting sort arranges states by increasing maximum length.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseNumber in 0 .. caseCount - 1:
  let stringCount = nextInt(inputData, scanPos)
  let firstString = nextWord(inputData, scanPos)
  suffixLink.setLen 0
  maxLength.setLen 0
  transitions.setLen 0
  discard newAutomatonState(0)
  lastState = 0
  for position in 0 .. firstString.len - 1:
    extendAutomaton(int(firstString[position]) - 97)
  let stateCount = suffixLink.len
  var commonLengths = newSeq[int](stateCount)
  var matchLengths = newSeq[int](stateCount)
  var order = newSeq[int](stateCount)
  var buckets = newSeq[int](firstString.len + 1)
  for stateIndex in 0 .. stateCount - 1:
    commonLengths[stateIndex] = maxLength[stateIndex]
    buckets[maxLength[stateIndex]] += 1
    matchLengths[stateIndex] = 0
  for lengthValue in 1 .. firstString.len:
    buckets[lengthValue] += buckets[lengthValue - 1]
  for stateIndex in countdown(stateCount - 1, 0):
    buckets[maxLength[stateIndex]] -= 1
    order[buckets[maxLength[stateIndex]]] = stateIndex
```

The first string contains every substring of itself.
So each state starts with its full maximum length.
The sorted order is reused for every other string.

**Scan each string.** A walk records matches, then pushes them through suffix links.

```nim
  for stringIndex in 1 .. stringCount - 1:
    let sampleString = nextWord(inputData, scanPos)
    for stateIndex in 0 .. stateCount - 1:
      matchLengths[stateIndex] = 0
    var walkState = 0
    var walkLength = 0
    for position in 0 .. sampleString.len - 1:
      let letterIndex = int(sampleString[position]) - 97
      if transitions[walkState][letterIndex] != -1:
        walkState = transitions[walkState][letterIndex]
        walkLength += 1
      else:
        while walkState != -1 and transitions[walkState][letterIndex] == -1:
          walkState = suffixLink[walkState]
        if walkState == -1:
          walkState = 0
          walkLength = 0
        else:
          walkLength = maxLength[walkState] + 1
          walkState = transitions[walkState][letterIndex]
      if walkLength > matchLengths[walkState]:
        matchLengths[walkState] = walkLength
    for orderIndex in countdown(stateCount - 1, 1):
      let stateIndex = order[orderIndex]
      let parentState = suffixLink[stateIndex]
      if parentState >= 0:
        let carried = min(matchLengths[stateIndex], maxLength[parentState])
        if carried > matchLengths[parentState]:
          matchLengths[parentState] = carried
    for stateIndex in 0 .. stateCount - 1:
      if matchLengths[stateIndex] < commonLengths[stateIndex]:
        commonLengths[stateIndex] = matchLengths[stateIndex]
```

A missing letter follows suffix links until a transition exists.
The walk length is reset when no transition survives.
Suffix propagation runs from long states to short states.

**Answer.** Only states whose minimum length is covered can contribute.

```nim
  var bestLength = 0
  for stateIndex in 1 .. stateCount - 1:
    let minimumLength = maxLength[suffixLink[stateIndex]] + 1
    if commonLengths[stateIndex] >= minimumLength and commonLengths[stateIndex] > bestLength:
      bestLength = commonLengths[stateIndex]
  appendOutput($bestLength)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The root state never contributes a positive length.
The largest surviving match is the answer.
The final flush writes one line per test.

## Complexity

Building the automaton is linear in the first string.

| phase | time | space |
|---|---|---|
| build automaton | one extension per character | two states per character at most |
| counting sort | one pass over states and lengths | one order array |
| scan other strings | one character step per string character | one match array |
| answer scan | one pass over states | no extra space |

| measure | Big O |
|---|---|
| time per test | O(K * L) for string length L |
| space per test | O(L) |

Building a suffix array for every string and sorting all suffixes costs more work.
The automaton indexes the first string once and reuses it for all others.
