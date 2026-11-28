# ADASTRNG — Ada and Substring (SPOJ)

<https://www.spoj.com/problems/ADASTRNG/>

## Problem

Count the distinct substrings that start with each lowercase letter of a string. Report 26 integers in alphabetical order, one for `a` through `z`.

The input has one string on one line, of length `1` to `300000`. Print the 26 counts on one line, separated by single spaces.

| Item | Bound |
|---|---|
| String length | 1 to 300000 |
| Alphabet | lowercase English letters |
| Judge limit | 2000 ms, 1536 MB |

Repeated substrings count once, even when they occur at several positions.

The first sample case is:

```
aaa
```

The expected output is:

```
3 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
```

## Idea

Picture a suffix automaton as a family tree of endings, where each node owns a short run of new substrings. Build that automaton once, then charge each owned substring to the letter where it starts. A prefix-count array per letter turns each charge into one subtraction. Sorting suffixes and storing every substring in a set would cost far more.

## Why It Works

1. A state v owns substrings whose lengths run from len(link(v)) + 1 up to len(v).
2. All owned substrings end at the stored first position where v appeared.
3. A substring of length L starts at position firstPosition - L + 1.
4. The start positions therefore form one contiguous slice of the original string.
5. Prefix counts give the number of target letters inside that slice in one lookup.
6. Summing those counts over all states and letters gives every answer.

| Term | Meaning |
|---|---|
| `transition` | flat table of 26 next-state links per automaton state |
| `longestLength` | longest substring represented by a state |
| `linkState` | suffix link to the next shorter end-position class |
| `firstPosition` | stored end position used as a representative |
| `prefixCount` | running count of one letter over string positions |

The automaton has at most twice as many states as the string has characters.

A short trace with the sample string `abc`:

```
state for a: lengths 1..1, start 0 -> a gains 1
state for ab: lengths 1..2, starts 0..1 -> a gains 1, b gains 1
state for abc: lengths 1..3, starts 0..2 -> a gains 1, b gains 1, c gains 1
totals: a = 3, b = 2, c = 1
```

The trace matches the statement output for `abc`.

## Code

**Input and scanning.** The reader extracts lowercase words and keeps one output buffer.

```nim
const flushBlockBytes = 1 shl 17
const alphabetSize = 26

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < 'a' or data[pos] > 'z'):
    pos += 1
  var word = ""
  while pos < data.len and data[pos] >= 'a' and data[pos] <= 'z':
    word.add data[pos]
    pos += 1
  return word

proc hasNextWord(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len and (data[cursor] < 'a' or data[cursor] > 'z'):
    cursor += 1
  return cursor < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The word scanner skips whitespace and line breaks.
The sentinel loop also accepts several strings in one file.
All count lines pass through the block buffer.

**Automaton build.** Each character extends the automaton and may split an existing state.

```nim
while hasNextWord(inputData, scanPos):
  let text = nextWord(inputData, scanPos)
  let capacity = text.len * 2 + 2
  var linkState = newSeq[int](capacity)
  var longestLength = newSeq[int](capacity)
  var firstPosition = newSeq[int](capacity)
  var transition = newSeq[int](capacity * alphabetSize)
  for index in 0 .. capacity * alphabetSize - 1:
    transition[index] = -1
  linkState[0] = -1
  var stateCount = 1
  var lastState = 0
  for characterIndex in 0 .. text.len - 1:
    let letter = int(text[characterIndex]) - 97
    var currentState = stateCount
    stateCount += 1
    longestLength[currentState] = longestLength[lastState] + 1
    firstPosition[currentState] = characterIndex
    for letterIndex in 0 .. alphabetSize - 1:
      transition[currentState * alphabetSize + letterIndex] = -1
    var previousState = lastState
    while previousState != -1 and transition[previousState * alphabetSize + letter] == -1:
      transition[previousState * alphabetSize + letter] = currentState
      previousState = linkState[previousState]
    if previousState == -1:
      linkState[currentState] = 0
    else:
      let foundState = transition[previousState * alphabetSize + letter]
      if longestLength[previousState] + 1 == longestLength[foundState]:
        linkState[currentState] = foundState
      else:
        var cloneState = stateCount
        stateCount += 1
        longestLength[cloneState] = longestLength[previousState] + 1
        firstPosition[cloneState] = characterIndex
        linkState[cloneState] = linkState[foundState]
        for letterIndex in 0 .. alphabetSize - 1:
          transition[cloneState * alphabetSize + letterIndex] = transition[foundState * alphabetSize + letterIndex]
        while previousState != -1 and transition[previousState * alphabetSize + letter] == foundState:
          transition[previousState * alphabetSize + letter] = cloneState
          previousState = linkState[previousState]
        linkState[foundState] = cloneState
        linkState[currentState] = cloneState
    lastState = currentState
```

Transitions are stored in one flat array of 26 entries per state.
A clone copies the transitions of the state it splits.
Suffix-link walks add one transition per visited state.

**Letter attribution.** One letter prefix array scores all states at once.

```nim
  var counts = newSeq[int64](alphabetSize)
  var prefixCount = newSeq[int](text.len + 1)
  for letter in 0 .. alphabetSize - 1:
    prefixCount[0] = 0
    for characterIndex in 0 .. text.len - 1:
      prefixCount[characterIndex + 1] = prefixCount[characterIndex]
      if int(text[characterIndex]) - 97 == letter:
        prefixCount[characterIndex + 1] = prefixCount[characterIndex + 1] + 1
    for stateIndex in 1 .. stateCount - 1:
      let startIndex = firstPosition[stateIndex] - longestLength[stateIndex] + 1
      let endIndex = firstPosition[stateIndex] - longestLength[linkState[stateIndex]]
      counts[letter] = counts[letter] + int64(prefixCount[endIndex + 1] - prefixCount[startIndex])
  for letter in 0 .. alphabetSize - 1:
    if letter > 0:
      outputBuffer.add ' '
    appendOutput($counts[letter])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The root is skipped because it owns no substring.
Counts use 64-bit values because a long string has up to n squared substrings.
The final flush writes the buffered count lines.

## Complexity

The automaton is linear in size, and the attribution pass repeats a linear scan 26 times.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the string | one input string |
| Automaton build | linear amortized work | 26 links per state |
| Letter attribution | 26 prefix builds and state scans | one prefix array |
| Output | 26 buffered numbers | block buffer |

The automaton holds at most two states per character.

| Measure | Big O |
|---|---|
| Time | O(26 × N) |
| Space | O(26 × N) |

Storing every distinct substring in a set costs O(N squared) memory, so the automaton wins.
