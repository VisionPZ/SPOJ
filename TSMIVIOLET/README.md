# TSMIVIOLET — Violet and Her Dream Land (SPOJ)

<https://www.spoj.com/problems/TSMIVIOLET/>

## Problem

Violet calls each weekday by a food name. Given one weekday, print the food name she chose.

Input: one string `S`, a day name. Output: the matching unique name, on its own line.

| Item | Bound |
|---|---|
| Input tokens | one day name |
| Possible names | seven |
| Judge limit | 1 s, 1536 MB |

Seven fixed names make a direct lookup the whole task.

Sample input:

```
Wednesday
```

Sample output:

```
Waffles
```

## Idea

Think of a seven-page address book: you flip to the one page that matches the name in your hand.
The algorithm reads one token, then checks it against the seven day names in order.
Each comparison is constant cost, and the first match wins.
A general hash table or map needs extra setup, which buys nothing for seven fixed strings.

## Why It Works

1. The input holds exactly one day token, so one token scan is enough.
2. The seven day names are distinct, so at most one comparison branch matches.
3. Skipping whitespace before the token makes trailing blanks harmless.

| Term | Meaning |
|---|---|
| `dayName` | the single token read from the input buffer |
| `scanPos` | current byte index in `inputData` |
| `outputBuffer` | one buffer holding the answer before the final write |

The trace below comes from `gen.py` on the sample case:

```
trace: token='Wednesday' -> 'Waffles'
```

That is the same mapping the sample shows.

## Code

**Input scan.** Reads every line once, then lifts out the first token.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
while scanPos < inputData.len and inputData[scanPos] <= ' ':
  scanPos += 1
var dayName = ""
while scanPos < inputData.len and inputData[scanPos] > ' ':
  dayName.add inputData[scanPos]
  scanPos += 1
```

The loop skips spaces before the token. The second loop stops at any whitespace, so a trailing blank line cannot extend the name. Cost is one pass over the input bytes.

**Output helper.** Appends text and flushes only when the buffer is large.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`flushBlockBytes` is 128 KiB. A single answer never reaches it, so the final write emits the whole answer. The buffer is reused, not rebuilt.

**Mapping.** Seven fixed comparisons select the answer.

```nim
if dayName == "Saturday":
  appendOutput("Sandwich")
elif dayName == "Sunday":
  appendOutput("Soup")
elif dayName == "Monday":
  appendOutput("Macaroon")
elif dayName == "Tuesday":
  appendOutput("Toffee")
elif dayName == "Wednesday":
  appendOutput("Waffles")
elif dayName == "Thursday":
  appendOutput("Taco")
elif dayName == "Friday":
  appendOutput("French Fries")

appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The order follows the story, not the alphabet. The newline is appended after the branch, so every answer ends with one line feed. Cost is at most seven string comparisons.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Token scan | one pass over the day name | token bytes |
| Lookup | at most seven comparisons | none |
| Output | one final write | answer bytes |

Total work does not grow with anything except the short input token.

| Measure | Big O |
|---|---|
| Time | O(L), where L is the input length |
| Space | O(L) for the single input buffer |

A map or a sorted table costs O(1) expected lookup but needs a build step and more memory. For seven fixed names, direct comparisons are simpler and just as fast.
