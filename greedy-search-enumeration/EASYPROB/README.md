# EASYPROB — Easy Powers (SPOJ)

<https://www.spoj.com/problems/EASYPROB/>

## Problem

Print seven fixed numbers in hereditary base-2 notation. Each number is written as a sum of powers of two, and every exponent is written with the same rule until only zeros and the symbol 2 remain.

Input: none. Output: exactly seven lines, one per target number, in the listed order. Each line starts with the number, then an equals sign, then its notation.

| item | bound |
|---|---|
| output lines | exactly 7 |
| target numbers | 137, 1315, 73, 136, 255, 1384, 16385 |
| judge limit | 1000 ms, 1536 MB |

The fixed target list makes a recursive formatter sufficient.

The first two lines of the correct output:

```
137=2(2(2)+2+2(0))+2(2+2(0))+2(0)
1315=2(2(2+2(0))+2)+2(2(2+2(0)))+2(2(2)+2(0))+2+2(0)
```

Both lines use nested powers of two.

## Idea

Write each exponent as its own small sum, like nesting boxes inside boxes. The formatter walks set bits from high to low and wraps each exponent greater than two in another call to itself. Three small cases stop the recursion: zero, one and two.

The algorithm is recursive base conversion with memo-free string building. Each set bit costs one recursive call on the exponent. A hard-coded seven-line answer would work but would hide the pattern.

The same rule at every level keeps the notation unique.

## Why It Works

1. Every positive integer has a unique binary expansion.
2. A set bit at position k contributes 2 to the k-th power.
3. A power with exponent k is written as 2 followed by the notation of k in parentheses.
4. The exponent one is the base itself, so it is written as 2.
5. The exponent zero is written as 2(0).
6. Recursion terminates because every exponent is smaller than the number that produced it.

| term | meaning |
|---|---|
| `highestPower` | exponent of the leading set bit |
| `probe` | current power of two while scanning bits |
| `exponent` | bit position being formatted |
| `terms` | joined notation pieces for one number |

The four names cover the scan and the string assembly.

Here is the expansion of 137 from `gen.py`:

| level | value | notation |
|---|---|---|
| target | 137 | bits 7, 3, 0 |
| exponent 7 | 4 + 2 + 1 | 2(2)+2+2(0) |
| exponent 3 | 2 + 1 | 2+2(0) |
| exponent 0 | zero | 2(0) |

Joining the three terms gives the first sample line.

## Code

**Input and recursive formatter.** The program reads stdin once and formats each binary digit recursively.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc represent(value: int): string =
  if value == 0:
    return "0"
  if value == 1:
    return "2(0)"
  if value == 2:
    return "2"
  var highestPower = 0
  var probe = 1
  while probe * 2 <= value:
    probe *= 2
    highestPower += 1
  var terms = ""
  var exponent = highestPower
  while exponent >= 0:
    if (value div probe) mod 2 == 1:
      var term = ""
      if exponent == 1:
        term = "2"
      elif exponent == 0:
        term = "2(0)"
      else:
        term = "2(" & represent(exponent) & ")"
      if terms.len > 0:
        terms.add '+'
      terms.add term
    probe = probe div 2
    exponent -= 1
  return terms
```

The three base cases stop the recursion.
The first loop finds the leading bit.
The second loop emits terms from high bit to low bit.
One buffer collects the seven output lines.

**Target list and output.** The driver prints the required numbers in the required order.

```nim
let targets = @[137, 1315, 73, 136, 255, 1384, 16385]
for target in targets:
  appendOutput($(target) & "=" & represent(target))
  outputBuffer.add '\n'
```

The list fixes both the values and their order.
Each line joins the decimal number with its notation.
The final flush writes all seven lines.

## Complexity

The seven inputs are tiny, so recursion depth drives the cost.

| phase | time | space |
|---|---|---|
| input read | one pass over stdin | one input string |
| formatting | one step per bit and exponent | recursion depth |
| output | one buffered write | block buffer |

Formatting dominates the short run.

| measure | Big O |
|---|---|
| time | O(log N) per number |
| space | O(log N) recursion depth |

A hard-coded table removes the recursion but records no rule, while the formatter derives every line from its number.
The bounded targets keep the output at seven lines.
