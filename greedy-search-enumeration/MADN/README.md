# MADN — The Mad Numerologist (SPOJ)

<https://www.spoj.com/problems/MADN/>

## Problem

Build a name of a fixed length from uppercase English letters. Vowels fill odd positions and consonants fill even positions. Choose letters to keep the vowel total and the consonant total minimal, then make the name lexicographically smallest.

Input starts with the number of test cases. Each following line holds one name length. Output one line per case, written as Case k: followed by the chosen name, with k starting at 1.

The statement gives these bounds.

| item | bound |
|---|---|
| test cases | 1 to 250 |
| name length | 1 to 210 |
| uses of one vowel | up to 21 |
| uses of one consonant | up to 5 |
| judge limit | 1000 ms, 1536 MB |

The two class capacities total 105 slots each, so length 210 fills them exactly.

Sample input:

```
3
1
5
5
```

Sample output:

```
Case 1: A
Case 2: AJAJA
Case 3: AJAJA
```

## Idea

Spend the lowest-value letters first, like paying with the smallest coins until the purse runs empty.

The algorithm is a capped greedy fill followed by an alphabetic sort. Each letter costs one lookup and up to five or twenty-one copies. A naive scan would reconsider every consonant at every name position. The fixed order removes that repeated search.

## Why It Works

1. A letter's value is its alphabet position modulo nine, plus one.
2. Vowels fill odd slots and consonants fill even slots, so the two choices stay independent.
3. The smallest total uses the cheapest letters first, up to their usage cap.
4. Letters with equal value can be exchanged without changing the total.
5. Sorting the chosen letters alphabetically gives the smallest name at every position.

The main terms are listed below.

| term | meaning |
|---|---|
| `vowelOrder` | vowels sorted by value, then by letter |
| `consonantOrder` | consonants sorted by value, then by letter |
| `vowelCapacity` | maximum uses of one vowel, 21 |
| `consonantCapacity` | maximum uses of one consonant, 5 |

The two orders fix the value, and the final sort fixes the spelling.

A script trace for length 12 shows the fill and the sort.

```
n=12 vowel slots=6 consonant slots=6
vowel cost=6 picked=AAAAAA
consonant cost=6 picked=JJJJJS
name=AJAJAJAJAJAS
```

Both costs are minimal, and the name is the smallest spelling with those costs.

The capacities cover 105 slots per class, which reaches the largest allowed length.

## Code

**Input and scanning.** The reader loads every input line, and the scanner extracts integers.

```nim
const flushBlockBytes = 1 shl 17
const vowelCapacity = 21
const consonantCapacity = 5
const vowelOrder = "AUEOI"
const consonantOrder = "JSBKTCLDMVNWFXGPYHQZR"

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
```

The constant orders encode value first and letter second.
The scanner skips separators and builds each number digit by digit.
Both compilers accept the small insertion sort used below.

**Sorting and output buffering.** The helper sorts letters and flushes large blocks.

```nim
proc sortChars(values: var seq[char]) =
  for index in 1 ..< values.len:
    let currentValue = values[index]
    var previousIndex = index - 1
    while previousIndex >= 0 and values[previousIndex] > currentValue:
      values[previousIndex + 1] = values[previousIndex]
      previousIndex -= 1
    values[previousIndex + 1] = currentValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The sort handles at most 105 letters per class.
The buffer writes once per block instead of once per line.

**Case construction.** Each case fills two capped lists and interleaves them.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseNumber in 1 .. caseCount:
  let nameLength = nextInt(inputData, scanPos)
  let vowelSlots = (nameLength + 1) div 2
  let consonantSlots = nameLength div 2
  var vowelChars: seq[char] = @[]
  var consonantChars: seq[char] = @[]
  var remainingVowels = vowelSlots
  for vowelChar in vowelOrder:
    if remainingVowels <= 0: break
    let taken = min(remainingVowels, vowelCapacity)
    for copyIndex in 0 ..< taken:
      vowelChars.add vowelChar
    remainingVowels -= taken
  var remainingConsonants = consonantSlots
  for consonantChar in consonantOrder:
    if remainingConsonants <= 0: break
    let taken = min(remainingConsonants, consonantCapacity)
    for copyIndex in 0 ..< taken:
      consonantChars.add consonantChar
    remainingConsonants -= taken
  sortChars(vowelChars)
  sortChars(consonantChars)
  var luckyName = ""
  for position in 0 ..< nameLength:
    if (position mod 2) == 0:
      luckyName.add vowelChars[position div 2]
    else:
      luckyName.add consonantChars[position div 2]
  appendOutput("Case " & $caseNumber & ": " & luckyName)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Vowels take the odd slots and consonants take the even slots.
Sorting after the fill turns equal-value choices into a minimal name.
The final write flushes any remaining buffered text.

## Complexity

Each case touches only the fixed set of letter types.

| phase | time | space |
|---|---|---|
| input read | one pass over the case list | one input string |
| letter fill | up to 26 letters per case | two letter lists |
| output | one line per case | block buffer |

The fill and the sort work on 26 letter types, not on the whole alphabet per position.

| measure | Big O |
|---|---|
| time | O(n) per case |
| space | O(n) |

Reconsidering every consonant at every position would cost O(n^2) per case, while the capped order costs O(n).

The fixed orders keep each case linear in the name length.
