<https://www.spoj.com/problems/ACMAKER/>

## Problem

Count the ways an uppercase abbreviation can be drawn from the significant words of a phrase. Every significant word must supply at least one letter, and letters must be chosen left to right.

Input starts with scenarios. Each scenario begins with `n` insignificant words, one per line. Then test cases follow, one per line, until `LAST CASE`. A test case holds the abbreviation followed by phrase words. A line with `0` ends all input. Output `abbrev can be formed in i ways` or `abbrev is not a valid abbreviation`.

| item | bound |
|---|---|
| insignificant words per scenario | 1 to 100 |
| characters per line | at most 150 |
| answer | fits a signed 32-bit integer |
| judge limit | 1000 ms, 1536 MB |

Letter case does not block a match: uppercase abbreviation letters pair with lowercase phrase letters.

Sample input:

```
2
and
of
ACM academy of computer makers
RADAR radio detection and ranging
LAST CASE
2
a
an
APPLY an apple a day
LAST CASE
0
```

Sample output:

```
ACM can be formed in 2 ways
RADAR is not a valid abbreviation
APPLY can be formed in 1 ways
```

## Idea

Give each word a small set of tickets, one ticket for each possible letter it can donate, like choosing seats in a row. Count the tickets locally, then multiply choices across words with a running total. A two-level count handles both the order inside a word and the order between words. Enumerating full assignments would repeat the same local work again and again. The takeaway is that local subsequence counts collapse the search into simple integer updates.

## Why It Works

1. Insignificant words are removed before any counting starts.
2. `localWays` counts subsequences of one word that match a chosen slice of the abbreviation.
3. Scanning word letters backward prevents one letter from serving two abbreviation positions.
4. `globalWays` advances the abbreviation position by the number of letters a word donates.
5. A slice of length zero is never allowed, so every significant word contributes.

| term | meaning |
|---|---|
| `lowerAbbrev` | abbreviation letters in lowercase for comparison |
| `localWays` | subsequence counts for one word and one start position |
| `globalWays` | ways after processing words up to a given position |
| `answerCount` | ways after the last word completes the abbreviation |

The tables store exact integers, so no rounding is involved.

In the sample, `academy` supplies `A` from either of its two `a` letters, giving `2` choices. `computer` supplies `C` once and `makers` supplies `M` once. The product `2` matches the sample output.

## Code

**Input and scanning.** The reader loads all input, splits lines, and extracts whitespace-separated words.

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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = ""
  while pos < data.len and data[pos] > ' ':
    result.add data[pos]
    pos += 1
```

Line splitting keeps the scenario structure intact.
Blank lines are skipped by the line reader.
Extra spaces between words do not change the tokens.

**Output helper.** One buffer collects all report lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes only after reaching its block size.
A final write emits any remaining text.

**Scenario reader.** Insignificant words and test cases are parsed from the line list.

```nim
var allLines = newSeq[string]()
var lineStart = 0
for charIndex in 0 .. inputData.len - 1:
  if inputData[charIndex] == '\n':
    if charIndex > lineStart:
      allLines.add inputData[lineStart .. charIndex - 1]
    else:
      allLines.add ""
    lineStart = charIndex + 1

var lineIndex = 0

proc nextFilledLine(): string =
  while lineIndex < allLines.len:
    let candidate = allLines[lineIndex]
    lineIndex += 1
    var firstPos = 0
    while firstPos < candidate.len and candidate[firstPos] <= ' ':
      firstPos += 1
    if firstPos < candidate.len:
      return candidate
  return ""
```

The first word identifies a scenario count or the terminator.
The phrase is filtered before any counting begins.
The marker `LAST` closes the current scenario.

**Counting pass.** Local subsequence counts feed the running word-by-word total.

```nim
while true:
  let scenarioLine = nextFilledLine()
  if scenarioLine.len == 0:
    break
  var countPos = 0
  let insignificantCount = nextInt(scenarioLine, countPos)
  if insignificantCount == 0:
    break
  var insignificantWords = newSeq[string](insignificantCount)
  for wordIndex in 0 .. insignificantCount - 1:
    let wordLine = nextFilledLine()
    var wordPos = 0
    insignificantWords[wordIndex] = nextWord(wordLine, wordPos)
  while true:
    let caseLine = nextFilledLine()
    if caseLine.len == 0:
      break
    var casePos = 0
    let firstToken = nextWord(caseLine, casePos)
    if firstToken == "LAST":
      break
    let abbreviation = firstToken
    var lowerAbbrev = ""
    for letterChar in abbreviation:
      if letterChar >= 'A' and letterChar <= 'Z':
        lowerAbbrev.add chr(int(letterChar) - 65 + 97)
      else:
        lowerAbbrev.add letterChar
    let abbrevLen = lowerAbbrev.len
    var significantWords = newSeq[string]()
    while true:
      let phraseWord = nextWord(caseLine, casePos)
      if phraseWord.len == 0:
        break
      var isInsignificant = false
      for ignoredWord in insignificantWords:
        if ignoredWord == phraseWord:
          isInsignificant = true
          break
      if not isInsignificant:
        significantWords.add phraseWord
    let wordCount = significantWords.len
    var wordWays = newSeq[seq[int64]]()
    for wordIndex in 0 .. wordCount - 1:
      let currentWord = significantWords[wordIndex]
      var localWays = newSeq[int64]((abbrevLen + 1) * (abbrevLen + 1))
      for startPos in 0 .. abbrevLen - 1:
        let rowBase = startPos * (abbrevLen + 1)
        localWays[rowBase] = 1
        for charIndex in 0 .. currentWord.len - 1:
          var matchCount = abbrevLen - startPos
          while matchCount >= 1:
            if lowerAbbrev[startPos + matchCount - 1] == currentWord[charIndex]:
              localWays[rowBase + matchCount] += localWays[rowBase + matchCount - 1]
            matchCount -= 1
      wordWays.add localWays
    var globalWays = newSeq[int64](abbrevLen + 1)
    globalWays[0] = 1
    for wordIndex in 0 .. wordCount - 1:
      var nextWays = newSeq[int64](abbrevLen + 1)
      for startPos in 0 .. abbrevLen - 1:
        if globalWays[startPos] == 0:
          continue
        let rowBase = startPos * (abbrevLen + 1)
        for matchCount in 1 .. abbrevLen - startPos:
          let localCount = wordWays[wordIndex][rowBase + matchCount]
          if localCount > 0:
            nextWays[startPos + matchCount] += globalWays[startPos] * localCount
      globalWays = nextWays
    let answerCount = globalWays[abbrevLen]
    appendOutput(abbreviation)
    if answerCount == 0:
      appendOutput(" is not a valid abbreviation\n")
    else:
      appendOutput(" can be formed in " & $answerCount & " ways\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Backward scanning keeps each letter unique.
A zero final count produces the invalid message.
Every valid line gets one output line.

## Complexity

Local tables are built per word, then one running array advances through the words.

| phase | time | space |
|---|---|---|
| input read | one pass over input text | one input string |
| local tables | word length times squared abbreviation length | one table per word |
| word combine | words times squared abbreviation length | two arrays of abbreviation length |
| output | one line per test case | block buffer |

| measure | Big O |
|---|---|
| time per test case | `O(W * L^2 + total letters * L^2)` |
| space per test case | `O(W * L^2)` |

Brute force would enumerate whole assignments and repeat local counting for every partial choice.

The two-level split keeps both order rules exact.
