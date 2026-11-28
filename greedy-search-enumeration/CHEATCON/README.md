# CHEATCON — Cheating on the contest (SPOJ)
<https://www.spoj.com/problems/CHEATCON/>

## Problem

Answer whether each word belongs to the language of a small regular expression. Expressions use only `a`, `b`, concatenation, union and Kleene star. Print `Y` or `N` per query, then a blank line per test case.

Input runs until end of file. Each test starts with one expression line and a query count `P`. The next `P` lines hold words over `a` and `b`, and empty words are allowed.

| item | bound |
|---|---|
| expression length | 1 to 150 |
| queries P | 1 to 100 |
| word length | up to 50, may be empty |
| judge limit | 1000 ms, 1536 MB |

Every expression is either `a`, `b`, or a parenthesised combination. Operators are `.`, | and `*`.

Sample input:

```
(a)
3
a
b
aa
(a.b)
3
a
ab
b
(a|b)
4
a
b
ab
ba
(a*)
3
a
aaaaaaaaaaaaaaaa
baaaaa
((a*).(b*))
3
bbba
aaaa
abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
```

Sample output:

```
Y
N
N

N
Y
N

Y
Y
N
N

Y
Y
N

N
Y
Y

```

## Idea

Build a map of the expression where each arrow is either a free jump or a letter, like drawing train tracks before running trains. Try each word by marking every station reachable without reading a letter, then following the matching letter arrows.

The construction is Thompson's automaton. It uses two states per atom and a few extra states per operator. Running a word touches at most a few hundred states, so the work stays small.

## Why It Works

1. An atom creates a start state and a finish state joined by one letter edge.
2. Concatenation joins the finish of the first part to the start of the second with a free jump.
3. Union adds one new start and finish, with free jumps to both branches.
4. Star adds free jumps that skip the loop or repeat it.
5. A word is accepted exactly when its last set of states contains the finish state.

| term | meaning |
|---|---|
| `epsilonEdges` | free jumps that consume no letter |
| `charEdges` | letter-labeled arrows between states |
| `Fragment` | the start and finish states of one parsed part |
| `epsilonClosure` | every state reachable through free jumps |

Take `(a.b)` and the word `ab`. Reading `a` reaches the junction state; a free jump crosses to the `b` atom. Reading `b` reaches the finish state, so the answer is `Y`. The word `ba` never leaves the start atom and returns `N`.

## Code

**Input setup.** All input is read once and split back into lines.

```nim
const flushBlockBytes = 1 shl 17

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

proc splitInputLines(data: string): seq[string] =
  var lines: seq[string] = @[]
  var lineStart = 0
  for index in 0 .. data.len - 1:
    if data[index] == '\n':
      if index > lineStart:
        lines.add data[lineStart .. index - 1]
      else:
        lines.add ""
      lineStart = index + 1
  return lines
```

The line split preserves empty query words.
The integer scanner reads the query count.
Tests continue until the last line is consumed.

**Automaton builders.** Each operator rewires a small fragment of states.

```nim
type Fragment = tuple[start: int, finish: int]

var epsilonEdges: seq[seq[int]] = @[]
var charEdges: seq[seq[tuple[letter: char, target: int]]] = @[]

proc newState(): int =
  let stateIndex = epsilonEdges.len
  epsilonEdges.add @[]
  charEdges.add @[]
  return stateIndex

proc makeAtom(letter: char): Fragment =
  let startState = newState()
  let finishState = newState()
  charEdges[startState].add (letter, finishState)
  return (startState, finishState)

proc makeConcat(firstPart: Fragment, secondPart: Fragment): Fragment =
  epsilonEdges[firstPart.finish].add secondPart.start
  return (firstPart.start, secondPart.finish)

proc makeUnion(firstPart: Fragment, secondPart: Fragment): Fragment =
  let startState = newState()
  let finishState = newState()
  epsilonEdges[startState].add firstPart.start
  epsilonEdges[startState].add secondPart.start
  epsilonEdges[firstPart.finish].add finishState
  epsilonEdges[secondPart.finish].add finishState
  return (startState, finishState)

proc makeStar(innerPart: Fragment): Fragment =
  let startState = newState()
  let finishState = newState()
  epsilonEdges[startState].add innerPart.start
  epsilonEdges[startState].add finishState
  epsilonEdges[innerPart.finish].add innerPart.start
  epsilonEdges[innerPart.finish].add finishState
  return (startState, finishState)
```

Free jumps carry no letter.
Every fragment exposes one start and one finish.
The star builder adds both the skip and the repeat path.

**Recursive parsing.** The parser mirrors the grammar of the expression.

```nim
proc parsePattern(pattern: string, pos: var int): Fragment =
  if pos >= pattern.len:
    return makeAtom('a')
  if pattern[pos] != '(':
    let letter = pattern[pos]
    pos += 1
    return makeAtom(letter)
  pos += 1
  let firstPart = parsePattern(pattern, pos)
  if pos >= pattern.len:
    return firstPart
  if pattern[pos] == ')':
    pos += 1
    return firstPart
  let operation = pattern[pos]
  pos += 1
  if operation == '*':
    while pos < pattern.len and pattern[pos] != ')':
      pos += 1
    if pos < pattern.len:
      pos += 1
    return makeStar(firstPart)
  let secondPart = parsePattern(pattern, pos)
  if pos < pattern.len:
    pos += 1
  if operation == '.':
    return makeConcat(firstPart, secondPart)
  return makeUnion(firstPart, secondPart)
```

A bare letter becomes one atom.
Parentheses with no operator simply return the inner fragment.
The position advances past every consumed character.

**Word simulation.** Free jumps are closed before and after each letter.

```nim
proc epsilonClosure(seed: seq[bool]): seq[bool] =
  var reached = seed
  var pending: seq[int] = @[]
  for stateIndex in 0 .. reached.len - 1:
    if reached[stateIndex]:
      pending.add stateIndex
  while pending.len > 0:
    let stateIndex = pending[pending.len - 1]
    pending.setLen pending.len - 1
    for targetState in epsilonEdges[stateIndex]:
      if not reached[targetState]:
        reached[targetState] = true
        pending.add targetState
  return reached

proc acceptsWord(startState: int, finishState: int, word: string): bool =
  let stateCount = epsilonEdges.len
  var active = newSeq[bool](stateCount)
  active[startState] = true
  active = epsilonClosure(active)
  for letter in word:
    var moved = newSeq[bool](stateCount)
    for stateIndex in 0 .. stateCount - 1:
      if active[stateIndex]:
        for edge in charEdges[stateIndex]:
          if edge.letter == letter:
            moved[edge.target] = true
    active = epsilonClosure(moved)
  return active[finishState]
```

A stack visits each free-jump target once.
Only states active before a letter can move on that letter.
An empty word stops after the first closure.

**Driver.** Each test rebuilds the automaton and answers its queries.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let inputLines = splitInputLines(inputData)
var linePos = 0
while linePos < inputLines.len:
  while linePos < inputLines.len and inputLines[linePos].len == 0:
    linePos += 1
  if linePos >= inputLines.len:
    break
  let pattern = inputLines[linePos]
  linePos += 1
  while linePos < inputLines.len and inputLines[linePos].len == 0:
    linePos += 1
  if linePos >= inputLines.len:
    break
  scanPos = 0
  let queryCount = nextInt(inputLines[linePos], scanPos)
  linePos += 1
  epsilonEdges.setLen 0
  charEdges.setLen 0
  var patternPos = 0
  let automaton = parsePattern(pattern, patternPos)
  for queryIndex in 0 .. queryCount - 1:
    var word = ""
    if linePos < inputLines.len:
      word = inputLines[linePos]
      linePos += 1
    if acceptsWord(automaton.start, automaton.finish, word):
      appendOutput("Y")
    else:
      appendOutput("N")
    outputBuffer.add '\n'
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The automaton arrays are cleared for every expression.
One answer line is emitted per query.
A blank line closes each test case.

## Complexity

The automaton size is linear in the expression length.

| phase | time | space |
|---|---|---|
| parse expression | one pass over 150 characters | two edge lists |
| simulate one word | up to 50 times the state count | two boolean arrays |
| output | one line per query | block buffer |

| measure | Big O |
|---|---|
| time per query | O(150 * 50) worst case |
| space per test | O(150) |

Enumerating every generated word would be exponential.
Tracking reachable states turns each query into a short linear scan.
