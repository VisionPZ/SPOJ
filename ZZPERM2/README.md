# ZZPERM2 — Zig-Zag Permutation 2 (SPOJ)

<https://www.spoj.com/problems/ZZPERM2/>

## Problem

List the zig-zag rearrangements of a sorted word whose lexicographic rank is a multiple of D, then print how many zig-zag rearrangements exist. Print an empty line after each case.

A word is zig-zag when adjacent comparisons alternate. Either odd positions are greater than the next position and even positions are smaller, or the reverse holds. Ranks start at one in increasing lexicographic order.

Input contains up to 15 cases, each a word and a positive integer D. The word uses letters `a` to `j`, is sorted, and has at most 64 characters. D is at most 1000000000. Input ends at end of file. Output lists the chosen words, then the total count, then an empty line.

| item | bound |
|---|---|
| cases | up to 15 |
| word length | 1 to 64 |
| divisor D | 1 to 1000000000 |
| output lines per case | at most 365 |
| judge limit | 2274 ms, 1536 MB |

The output bound allows direct writing of every chosen word.

Sample input:

```
j 1
abc 2
aaabc 1
aaabb 2
aaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbcccdd 123456
aaaaaaaaabbbbbbbbbcccccccccddddddddd 1000000000
```

Sample output:

```
j
1

bac
cab
4

abaca
acaba
2

1

babacbcabacabadabababababababababadab
213216

abacbcacbdadcdbcadbdacbdacbdadbcbcad
abadadcdcdcdbdbdadbcabacacbdbcbcacab
acabacbcbdbcbdcdadadacbcadbcbcadadbd
acacbcbdacbdcdacbcadbdbcbcadadbdabad
acadbcadbdbcacadbdbcacbdbdacbdbcadac
acbcacbcadbdadadadbcbdcdabacacbdbdbc
acbcbdadbdcdbcbcbcacbdadadadadbcacab
acbdadcdcdadadbdababacbcbcbcacbdbdac
acbdcdbdbcacbcbcadabadbcabadbdcdacad
adacbcacbcbcbdcdcdbdadadabadbdbcacab
adadbcbcadbcabacadbdbcbdabadcdcdacbc
adbcadbcabacbdacacbcbcbdcdadbdadbdac
adbdacababacadadcdbcbcadbdacbcbdcdbc
adbdcdacbdbcbdbcadadadbcadacbcacbcab
adcdbdacadacbdbcbdadacbcbcadbdbcacab
babacbdcdbdcdbcadcdbcabacacadadbdacb
bacacadbdcdbcbdbdcdacbdacabacadbcadb
bacadcdbcbdabacbcacacadadadcdbdbdbcb
bacbdadacabacadacbdcdbcadbcbdbcbdadc
badacadbcadacbcbdadbdbcacbcbdcdabadc
badbcacbdabadcdbcadbdacabacbdacbdcdc
badbdcdbdadacbcbcacacbdbdacbdadbcaca
bcabacadbdbdacacbdadcdadbcbcbcadacbd
bcacadacbcbdcdbdbcbdbdadadabacbdacac
bcacbdbdcdcdababadacbcadacacbdbdbcad
bcadbcadbdbdcdcdadbcbcacbcababadacad
bcbcabadacadcdadacbdadbcbdcdbcacbdab
bcbcbcadbcadbcadbdadbcbcadabacadadcd
bcbdacbdacbdbcbdadacacbdcdbdadacabac
bcbdbdbdcdacacacbdbcadadbcababacadcd
bdabadcdbdadbcadcdbcbdcdbcabacabacac
bdacbcbcbcadadbcadcdabadbcacbdcdabad
bdadbcabacbcbcababadacadcdcdbdcdacbd
bdbcacacbdbcadbcbdabacbcadacadadbdcd
bdbcbdacacbdadbdcdababadadcdbcacbcac
bdbdbcadbcacadbcadacadbdbdcdbcacacab
bdcdacbdadadbcbcacacbcacabadbdbcadbd
bdcdcdadacadcdbdbcababadbcacbcadbcab
cabacbdcdbdadacacadbcbcacadbcbdbdadb
cacabadcdbdbdbcbcbdacabadbdacbdacadc
cacadcdbcbcbdcdacababacbcadbdbdbdada
cacbdadbdadacbdababacbcbdcdcdcdabacb
cadacadbdabacbcacbdbdcdadbcadadbcbcb
cadbcacbcbdcdbdbcadbcbdadabacbdacada
cadbdbcbdacadbdacadacbdbcbcadbcabadc
cbcabacbcbdadabacbcadbdadcdcdadacbdb
cbcadacadadbdbcacbcadbdbdacbcabadcdb
cbcbcadacbcadadadbcbdacadbcbdbdacadb
cbcbdbcadcdacbdadacbdbcacadacbdabadb
cbdacadacbcbdcdbdabadbcbcacabadcdadb
cbdadbdadabadcdabadcdacbcbcabacbcbdc
cbdbcbdcdbcbdacacbdadadcdababacabadc
cbdcdacbdbcbdadacacadbcabababadcdbdc
cdabadacabadcdbdcdbdbcabadbcbcacadbc
cdacbcbcadabadcdbdbcbcacbdadadabadbc
cdadbcacacbcadadbdbdbcabadbcbcbcadad
cdbcacadbcbdbcadbdadadbdbcacbcadabac
cdbcbdadadacbdbcabacbcbcabadacadcdbd
cdbdbcabadcdbdbdcdacacababadbdacacbc
cdcdacacbcadbcabadbdcdbcbcabadadbdab
dababacbcbcadbdacacbcacbdbdcdadcdadb
dabadbdcdacacadabadcdbdbcbcbcacbdbca
dacadacbdbdbcacbcadbdbcacbcadbdcdaba
dacbcbdadadcdbdacadcdababacbcacbdbcb
dadabadbcbcadcdbdacbcadacadbcbcbdbca
dadbcadadbdcdcdabacbcbdbcacbdbcabaca
dadcdbcacabadadbcabadbcadcdadbcbcbcb
dbcacbcadacadbcacbdadacbcbdacbdbdadb
dbcadcdbcbdbdadbdadbcacbcacacbcabada
dbcbdacbcadbdacbdadbdacbcadbcacadacb
dbdacacbdadbcbcbcbcadbdadbcadbcadaca
dbdbcacadacabacbcadacbdadcdbdbdbcbca
dbdcdabacadadbcbdcdbcacacbcbdbdacaba
dcdacadadbcbcabacbcacbdbcbdbcadadadb
dcdbcadadbcbcadbcbcadabadbdcdbcacaba
dcdcdacabadbdbdacacbcacbdababadbcbdc
76317369490

```

## Idea

Think of a fence with posts that must alternate high and low, like choosing a repeating up-down pattern of letter sizes. A prefix can be completed in a fixed number of ways, and that count tells how many ranks the prefix owns. Skip whole prefixes when they contain no wanted rank, then unrank each wanted word. Brute-force enumeration would visit every zig-zag word and cannot handle counts above billions. Takeaway: count completions first, then unrank only the requested ranks.

## Why It Works

1. Zig-zag letters use strict comparisons, so equal adjacent letters are forbidden.
2. The first two letters decide which of the two patterns applies.
3. A prefix state stores the remaining letter counts, the last letter, and the next comparison direction.
4. The completion count for a state equals the sum of completion counts of its valid next letters.
5. Lexicographic ranks fill a prefix subtree in one contiguous block, so unranking subtracts subtree sizes.

| term | meaning |
|---|---|
| `countCompletions` | number of zig-zag tails from a prefix state |
| `fullState` | mixed-radix encoding of all letter counts |
| `radixMultipliers` | place values for that encoding |
| `pairCompletionCount` | count of tails after a fixed first pair |
| `unrankWord` | build the word at a given rank |

A script trace for the word abc:

```
rank 1 : acb
rank 2 : bac
rank 3 : bca
rank 4 : cab
```

With D = 2 the chosen words are bac and cab, matching the sample.

Mixed-radix keys fit in int64 because the product of letter-count plus one stays below ten billion.

## Code

**Input and scanner.** The reader stores each case and parses words and divisors.

```nim
import tables

const flushBlockBytes = 1 shl 17
const alphabetSize = 10
const stateMultiplier = 22'i64

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = ""
  while pos < data.len and data[pos] > ' ':
    result.add data[pos]
    pos += 1

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value
```

The word reader stops at whitespace.
The integer scanner skips non-digit bytes.
All input is read before processing starts.

**Completion counting.** A memoized recursion counts tails from any prefix state.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var letterTotals = newSeq[int](alphabetSize)
var typeLetters = newSeq[int](alphabetSize)
var typeCounts = newSeq[int](alphabetSize)
var radixMultipliers = newSeq[int64](alphabetSize)
var typeCount = 0
var fullState: int64 = 0
var memoTable = initTable[int64, int64]()

proc remainingCount(stateIndex: int64, typeIndex: int): int64 =
  return (stateIndex div radixMultipliers[typeIndex]) mod int64(typeCounts[typeIndex] + 1)

proc countCompletions(stateIndex: int64, lastLetter: int, needUp: bool): int64 =
  if stateIndex == 0:
    return 1
  let cacheKey = stateIndex * stateMultiplier + int64((lastLetter + 1) * 2 + (if needUp: 1 else: 0))
  if memoTable.hasKey(cacheKey):
    return memoTable[cacheKey]
  var totalWays: int64 = 0
  for typeIndex in 0 .. typeCount - 1:
    if remainingCount(stateIndex, typeIndex) == 0:
      continue
    let candidateLetter = typeLetters[typeIndex]
    if lastLetter >= 0:
      if needUp and candidateLetter <= lastLetter:
        continue
      if (not needUp) and candidateLetter >= lastLetter:
        continue
    totalWays = totalWays + countCompletions(stateIndex - radixMultipliers[typeIndex], candidateLetter, not needUp)
  memoTable[cacheKey] = totalWays
  return totalWays
```

The mixed-radix key encodes counts, last letter, and direction.
Memoization shares results across unranking calls.
A state with no letters left contributes one tail.

**Pair counts and totals.** Two initial letters fix the comparison pattern.

```nim
proc pairCompletionCount(firstType: int, secondType: int): int64 =
  let stateAfterPair = fullState - radixMultipliers[firstType] - radixMultipliers[secondType]
  return countCompletions(stateAfterPair, typeLetters[secondType], secondType < firstType)

proc totalZigzags(wordLength: int): int64 =
  if wordLength == 1:
    return 1
  var totalWays: int64 = 0
  for firstType in 0 .. typeCount - 1:
    for secondType in 0 .. typeCount - 1:
      if secondType == firstType:
        continue
      totalWays = totalWays + pairCompletionCount(firstType, secondType)
  return totalWays
```

A smaller second letter forces an upward third step.
A larger second letter forces a downward third step.
The total sums every valid first pair.

**Unranking.** The target rank picks a path through the prefix tree.

```nim
proc unrankWord(targetRank: int64, wordLength: int): string =
  if wordLength == 1:
    return $char(typeLetters[0] + int('a'))
  var rankLeft = targetRank
  var chosenFirst = 0
  var chosenSecond = 0
  for firstType in 0 .. typeCount - 1:
    var groupTotal: int64 = 0
    for secondType in 0 .. typeCount - 1:
      if secondType != firstType:
        groupTotal = groupTotal + pairCompletionCount(firstType, secondType)
    if rankLeft > groupTotal:
      rankLeft = rankLeft - groupTotal
    else:
      chosenFirst = firstType
      break
  for secondType in 0 .. typeCount - 1:
    if secondType == chosenFirst:
      continue
    let branchTotal = pairCompletionCount(chosenFirst, secondType)
    if rankLeft > branchTotal:
      rankLeft = rankLeft - branchTotal
    else:
      chosenSecond = secondType
      break
  result = ""
  result.add char(typeLetters[chosenFirst] + int('a'))
  result.add char(typeLetters[chosenSecond] + int('a'))
  var stateIndex = fullState - radixMultipliers[chosenFirst] - radixMultipliers[chosenSecond]
  var lastLetter = typeLetters[chosenSecond]
  var needUp = chosenSecond < chosenFirst
  while stateIndex != 0:
    for typeIndex in 0 .. typeCount - 1:
      if remainingCount(stateIndex, typeIndex) == 0:
        continue
      let candidateLetter = typeLetters[typeIndex]
      if needUp and candidateLetter <= lastLetter:
        continue
      if (not needUp) and candidateLetter >= lastLetter:
        continue
      let branchTotal = countCompletions(stateIndex - radixMultipliers[typeIndex], candidateLetter, not needUp)
      if rankLeft > branchTotal:
        rankLeft = rankLeft - branchTotal
      else:
        result.add char(candidateLetter + int('a'))
        stateIndex = stateIndex - radixMultipliers[typeIndex]
        lastLetter = candidateLetter
        needUp = not needUp
        break
```

First pairs are tried in lexicographic order.
Subtree sizes decide which branch owns the rank.
The tail loop repeats the same choice at every position.

**Driver.** Each case emits chosen words, a count, and a blank line.

```nim
while scanPos < inputData.len:
  let sourceWord = nextWord(inputData, scanPos)
  if sourceWord.len == 0:
    break
  let divisorValue = nextInt(inputData, scanPos)
  for letterIndex in 0 .. alphabetSize - 1:
    letterTotals[letterIndex] = 0
  for charIndex in 0 .. sourceWord.len - 1:
    letterTotals[int(sourceWord[charIndex]) - int('a')] += 1
  typeCount = 0
  fullState = 0
  var multiplierValue: int64 = 1
  for letterIndex in 0 .. alphabetSize - 1:
    if letterTotals[letterIndex] > 0:
      typeLetters[typeCount] = letterIndex
      typeCounts[typeCount] = letterTotals[letterIndex]
      radixMultipliers[typeCount] = multiplierValue
      fullState = fullState + int64(letterTotals[letterIndex]) * multiplierValue
      multiplierValue = multiplierValue * int64(letterTotals[letterIndex] + 1)
      typeCount += 1
  memoTable.clear()
  let permutationTotal = totalZigzags(sourceWord.len)
  var targetRank = int64(divisorValue)
  while targetRank <= permutationTotal:
    appendOutput(unrankWord(targetRank, sourceWord.len))
    outputBuffer.add '\n'
    targetRank = targetRank + int64(divisorValue)
  appendOutput($permutationTotal)
  outputBuffer.add '\n'
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Letter counts are reset for every case.
Ranks advance by D until the total is passed.
One buffer flushes all output at the end.

## Complexity

Counting dominates for cases with many zig-zag words.

| phase | time | space |
|---|---|---|
| input read | one pass over case text | one input string |
| completion table | one entry per reachable state | memo table |
| unranking | word length times alphabet size per output | one word |
| output | one line per chosen word | block buffer |

The state count is bounded by the product of letter counts plus one.

| measure | Big O |
|---|---|
| time | O(states * alphabet + outputs * length * alphabet) |
| space | O(states) |

Enumerating every zig-zag word would scale with the total count and overflow the time limit. Takeaway: memoized counts turn ranking into a small number of tree descents.
