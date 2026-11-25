# ROMAN — Converting number formats (SPOJ)

<https://www.spoj.com/problems/ROMAN/>

## Problem

Integers are given spelled out in uppercase English words. Convert each to extended Roman numerals, with overlines and lowercase letters for large values.

Input: a count `n`, spelled out like every other number, then `n` lines of spelled-out values. Output: two lines per value, an overline bar line followed by the numeral line.

The bounds from the statement:

| Item | Bound |
|---|---|
| Values | positive integers below 2^32 |
| Count `n` | given in the same spelled-out format |
| Source limit | 2048 bytes, strictly enforced |
| Judge limit | 1052 ms, 1536 MB |

The first sample word, THREE, is the number of cases, not a case itself.

The sample input and output:

```
THREE
FOUR OH
ONE NINE NINE NINE NINE NINE NINE NINE NINE NINE
ONE TWO THREE ZERO FOUR FIVE
```

```
  
XL
       ______      
mcmxcixCMXCIXCMXCIX
___      
CXXMMMXLV
```

## Idea

Read each word by its first letter, then print each decimal digit as a fixed Roman fragment. Think of a translator with two small lookup tables: one for word-to-digit, one for digit-to-symbols.

The program uses lookup strings. `firstDigit` maps a word's first letter to its digit, with corrections for ONE, TWO, SIX, and FOUR. `brTransData` lists the symbol kinds each digit uses. `brEquivData` supplies the character, and `brBarData` supplies the overline underscore.

Parsing a line costs a few steps per word. Rendering walks nine decimal places and emits a fixed number of symbols. Both are constant-time work.

Two compact lookup tables turn the spelling and numeral rules into simple indexing.

## Why It Works

Four facts carry the translation.

1. Every value is spelled with English words. The first letter separates most digits, so `firstDigit` needs only a few corrections.
2. OH acts as ZERO, and word length separates ONE, TWO, SIX, and FOUR from other words starting with the same letter.
3. Each decimal place uses a fixed Roman fragment. `brTransData` gives the symbol count and kinds; `brEquivData` chooses uppercase, overlined uppercase, or lowercase forms.
4. Rendering prints the bar line first, so each underscore sits above the symbol it modifies.

The lookup tables:

| Term | Meaning |
|---|---|
| `firstDigit` | first-letter lookup from word to digit |
| `brTransData` | symbol kinds used by one decimal digit |
| `brEquivData` | character printed for each symbol kind |
| `brBarData` | underscore printed above a symbol needing an overline |

The two output lines stay aligned because both use the same symbol order.

A script-traced example with the three sample values:

```
count = THREE = 3

FOUR OH                     = 40
  bar "  " / numeral "XL"

ONE NINE x8                 = 1999999999
  bar "       ______      "
  numeral "mcmxcixCMXCIXCMXCIX"
  1,999,000,000 + 999,000 + 999

ONE TWO THREE ZERO FOUR FIVE = 123045
  bar "___      "
  numeral "CXXMMMXLV"
  120,000 (CXX, overlined) + 3,000 (MMM) + 45 (XLV)
```

## Code

**Lookup tables and input.** Four strings hold the whole translation dictionary.

```nim
const firstDigit = "....84.......90...62.....0"
const brTransData = "00000100002000030000212001200022100321104211121300"
const brEquivData = "IIVXXXLCCCDMMIVXXXLCCCDMMivxxxlcccdmmivx"
const brBarData = "             ____________            ___"

var inputBuf = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputBuf.add inputLine
  inputBuf.add '\n'

var scanPos = 0
```

`firstDigit` is indexed by the first letter's offset from A. The other three tables share symbol positions, so one index serves all of them.

**Word parser.** Each word becomes one decimal digit.

```nim
proc nextValue(data: string, pos: var int): int =
  var value = 0
  while pos < data.len and data[pos] != '\n':
    if data[pos] < 'A':
      pos += 1
      continue
    let start = pos
    while pos < data.len and data[pos] >= 'A' and data[pos] <= 'Z':
      pos += 1
    let first = data[start]
    let wlen = pos - start
    var digit = int(firstDigit[int(first) - 65]) - 48
    if (first == 'O' and wlen > 2) or (first == 'T' and wlen > 3) or
       (first == 'S' and wlen > 3) or (first == 'F' and data[start + 1] != 'O'):
      digit += 1
    value = value * 10 + digit
  pos += 1
  return value
```

`nextValue` reads one line and stops at the newline. The length tests distinguish ONE, TWO, SIX, and FOUR from same-letter words. Digits accumulate left to right into the value.

**Output helper.** Both output lines travel in one buffer.

```nim
var outputBuf = ""

proc appendOutput(text: string) =
  outputBuf.add text
  if outputBuf.len >= (1 shl 18):
    stdout.write outputBuf
    outputBuf.setLen 0
```

The flush threshold is 256 KiB. `setLen 0` reuses the same allocation.

**Renderer.** Each decimal place appends symbols to both lines.

```nim
var numLine = ""
var barLine = ""

proc renderValue(value: int) =
  numLine.setLen 0
  barLine.setLen 0
  if value == 0:
    barLine.add '_'
  else:
    var place = 1000000000
    var digitPlace = 9
    while digitPlace >= 0:
      let digitValue = (value div place) mod 10
      let transStart = digitValue * 5
      let equivStart = digitPlace * 4
      var k = 1
      while k <= int(brTransData[transStart]) - 48:
        let symbolKind = int(brTransData[transStart + k]) - 48
        numLine.add brEquivData[equivStart + symbolKind]
        barLine.add brBarData[equivStart + symbolKind]
        k += 1
      digitPlace -= 1
      place = place div 10
  appendOutput(barLine & "\n" & numLine & "\n")
```

`digitPlace` runs from 9 down to 0, so `place` shrinks by ten each round. `brTransData` controls how many symbols a digit emits. `appendOutput` writes the bar line first, then the numeral line.

**Driver.** The count is parsed first, then each value is rendered.

```nim
let caseCount = nextValue(inputBuf, scanPos)
for i in 0..<caseCount:
  renderValue(nextValue(inputBuf, scanPos))

stdout.write outputBuf
```

`nextValue` serves both the count and the cases, so no special parser exists. The final write covers the tail.

## Complexity

Each value is parsed and rendered with fixed tables.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Word parse | O(words in one line) | O(1) |
| Render | nine decimal places | O(1) |
| Output | one write per 256 KiB block | 256 KiB |
| Total per case | constant work | O(1) |

The four lookup strings replace all rule logic.

| Measure | Big O |
|---|---|
| Time | O(1) per number |
| Space | O(1) plus input and output buffers |

A general word dictionary and repeated-subtraction numeral builder cost more work and more code per value.

Looking up each word and digit in a fixed string is faster and shorter than searching a general dictionary.
