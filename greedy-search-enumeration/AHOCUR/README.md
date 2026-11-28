# AHOCUR — Aho-Corasick Trie (SPOJ)

<https://www.spoj.com/problems/AHOCUR/>

## Problem

A generator writes a string of length `L` by picking each character independently from a given probability distribution. Given a dictionary of patterns, compute the probability that none of the patterns appears in the generated string.

The input starts with test count `T`. Each case has `K` pattern lines, then `N` lines of a character and its probability, then `L`. Print `Case #t: p` with six digits after the decimal point.

The statement gives these bounds:

| item | bound |
|---|---|
| test cases T | up to 100 |
| patterns K | up to 40 |
| pattern length | 1 to 20 |
| generated length L | up to 100 |
| valid characters | alphanumeric |
| judge limit | 1000 ms, 1536 MB |

Many patterns must be checked at once, so a single automaton replaces per-pattern searches.

Sample input:

```
2
1
a
2
a 0.5
b 0.5
2

2
ab
ab
2
a 0.2
b 0.8
2

```

Sample output:

```
Case #1: 0.250000
Case #2: 0.840000
```

## Idea

Picture a pinball board where each letter drops a ball into a pocket, like following a map of trails that already knows every forbidden route.

An Aho-Corasick automaton merges all patterns into one trie with failure links. A dynamic program walks that automaton for `L` steps, carrying probability mass only through states that have not matched a pattern. The surviving mass is the requested probability.

Checking every pattern separately multiplies the work by `K` and loses shared prefixes. The automaton checks them together in one pass. The takeaway is to merge the dictionary, then propagate probabilities through the merged states.

## Why It Works

1. A trie state records the longest pattern prefix that matches the generated suffix.
2. A failure link sends a state to the next shorter prefix that still matches.
3. Marking a state whose failure chain ends in a terminal node detects a completed pattern.
4. The transition table gives the next state for every valid character without searching.
5. Probability mass entering a marked state is dropped, because that string already matched.
6. After `L` steps the remaining mass is exactly the probability of no match.

The main terms are listed here:

| term | meaning |
|---|---|
| `nodes` | trie states with children and failure links |
| `transition` | next state for each state and character |
| `hasMatch` | whether a state completes a pattern |
| `probabilities` | current probability mass per state |

Transitions and match flags are precomputed once per case.

A script trace for the first sample uses patterns `a` with two equally likely letters:

| step | surviving states | masses |
|---|---|---|
| 0 | root | 1 |
| 1 | root | 0.5 |
| 2 | root | 0.25 |

The mass entering the matched state is discarded at every step, giving `0.250000`.

Guard: probabilities are parsed from tokens, so blank lines and spacing do not affect the scan.

## Code

**Token reader and helpers.** The scanner reads whole tokens, so patterns with digits stay intact.

```nim
import strutils

const flushBlockBytes = 1 shl 17
const alphabetSize = 62

type TrieNode = object
  next: array[alphabetSize, int]
  failure: int
  terminal: bool

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let tokenStart = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  return data[tokenStart .. pos - 1]

proc tokenInteger(token: string): int =
  var value = 0
  for character in token:
    value = value * 10 + int(character) - 48
  return value

proc tokenProbability(token: string): float64 =
  var wholePart = 0.0
  var fractionPart = 0.0
  var scaleValue = 1.0
  var afterPoint = false
  for character in token:
    if character == '.':
      afterPoint = true
    elif afterPoint:
      fractionPart = fractionPart * 10.0 + float64(int(character) - 48)
      scaleValue = scaleValue * 10.0
    else:
      wholePart = wholePart * 10.0 + float64(int(character) - 48)
  return wholePart + fractionPart / scaleValue

proc characterIndex(character: char): int =
  if character >= 'a' and character <= 'z':
    return int(character) - 97
  if character >= 'A' and character <= 'Z':
    return int(character) - 65 + 26
  return int(character) - 48 + 52

proc makeNode(): TrieNode =
  for letterIndex in 0 .. alphabetSize - 1:
    result.next[letterIndex] = -1
  result.failure = 0
  result.terminal = false

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Alphanumeric characters map into 62 fixed slots.
Missing children use minus one as the empty marker.
The decimal reader handles both whole and fractional probabilities.

**Trie construction.** Each pattern adds one path and marks its final state.

```nim
let caseCount = tokenInteger(nextToken(inputData, scanPos))
for caseNumber in 1 .. caseCount:
  let patternCount = tokenInteger(nextToken(inputData, scanPos))
  var nodes = newSeq[TrieNode](1)
  nodes[0] = makeNode()
  nodes[0].failure = -1
  for patternIndex in 0 .. patternCount - 1:
    let pattern = nextToken(inputData, scanPos)
    var state = 0
    for character in pattern:
      let letterIndex = characterIndex(character)
      if nodes[state].next[letterIndex] == -1:
        nodes.add makeNode()
        nodes[state].next[letterIndex] = nodes.len - 1
      state = nodes[state].next[letterIndex]
    nodes[state].terminal = true

  let characterCount = tokenInteger(nextToken(inputData, scanPos))
  var letterProbability = newSeq[float64](alphabetSize)
  var validLetters = newSeq[int](0)
  for characterIndexValue in 0 .. characterCount - 1:
    let symbolToken = nextToken(inputData, scanPos)
    let probabilityToken = nextToken(inputData, scanPos)
    let letterIndex = characterIndex(symbolToken[0])
    letterProbability[letterIndex] = tokenProbability(probabilityToken)
    validLetters.add letterIndex

  let generatedLength = tokenInteger(nextToken(inputData, scanPos))
```

Shared prefixes occupy one path in the trie.
Duplicate patterns simply mark the same state twice.
Only listed valid letters enter the later loops.

**Failure links and transitions.** A breadth-first pass fills failure links, then every state gets a full transition row.

```nim
var queue = newSeq[int](nodes.len)
  var queueHead = 0
  var queueTail = 0
  for letterIndex in 0 .. alphabetSize - 1:
    let child = nodes[0].next[letterIndex]
    if child != -1:
      nodes[child].failure = 0
      queue[queueTail] = child
      queueTail += 1
  while queueHead < queueTail:
    let currentNode = queue[queueHead]
    queueHead += 1
    for letterIndex in 0 .. alphabetSize - 1:
      let child = nodes[currentNode].next[letterIndex]
      if child == -1:
        continue
      var fallback = nodes[currentNode].failure
      while fallback != -1 and nodes[fallback].next[letterIndex] == -1:
        fallback = nodes[fallback].failure
      if fallback == -1:
        nodes[child].failure = 0
      else:
        nodes[child].failure = nodes[fallback].next[letterIndex]
      queue[queueTail] = child
      queueTail += 1

  var hasMatch = newSeq[bool](nodes.len)
  for state in 0 .. nodes.len - 1:
    hasMatch[state] = nodes[state].terminal or (state != 0 and hasMatch[nodes[state].failure])

  var transition = newSeq[array[alphabetSize, int]](nodes.len)
  for state in 0 .. nodes.len - 1:
    for letterIndex in 0 .. alphabetSize - 1:
      var currentNode = state
      while currentNode != -1 and nodes[currentNode].next[letterIndex] == -1:
        currentNode = nodes[currentNode].failure
      if currentNode == -1:
        transition[state][letterIndex] = 0
      else:
        transition[state][letterIndex] = nodes[currentNode].next[letterIndex]

  
```

The breadth-first order guarantees a failure target is ready.
Inherited match flags catch patterns found through failure links.
The transition row removes per-character failure walks from the dynamic program.

**Probability propagation and output.** Each step moves mass through non-matching states only.

```nim
var probabilities = newSeq[float64](nodes.len)
  var nextProbabilities = newSeq[float64](nodes.len)
  probabilities[0] = 1.0
  for stepIndex in 0 .. generatedLength - 1:
    for state in 0 .. nodes.len - 1:
      nextProbabilities[state] = 0.0
    for state in 0 .. nodes.len - 1:
      let stateProbability = probabilities[state]
      if stateProbability == 0.0:
        continue
      for letterIndex in validLetters:
        let nextState = transition[state][letterIndex]
        if not hasMatch[nextState]:
          nextProbabilities[nextState] += stateProbability * letterProbability[letterIndex]
    swap probabilities, nextProbabilities

  var noMatchProbability = 0.0
  for state in 0 .. nodes.len - 1:
    if not hasMatch[state]:
      noMatchProbability += probabilities[state]
  appendOutput("Case #" & $caseNumber & ": " & formatFloat(noMatchProbability, ffDecimal, 6))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Only non-matching transitions receive probability mass.
The two arrays rotate after each generated character.
The final sum is written with six decimal places.

## Complexity

Automaton construction and the probability walk determine the cost.

| phase | time | space |
|---|---|---|
| input read | one pass over token stream | one input string |
| automaton build | O(pattern characters times alphabet) | trie and transition rows |
| probability walk | O(L times states times valid letters) | two probability arrays |
| output | one line per case | block buffer |

The automaton is rebuilt for each test case.

| measure | Big O |
|---|---|
| time | O(K * 20 * 62 + L * states * valid letters) per case |
| space | O(states * 62) |

Searching each pattern separately would multiply the walk by `K`. Sharing one automaton is the takeaway.
