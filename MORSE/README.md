# MORSE — Decoding Morse Sequences (SPOJ)
<https://www.spoj.com/problems/MORSE/>

## Problem

A radio signal arrives without pauses between letters. A dictionary decides which word sequences could have produced it.

The input starts with the data-set count. Each set gives a Morse string, a word count, and the dictionary words. Print the number of full phrase decodings.

The judge bounds are:

| Item | Bound |
| --- | --- |
| Data sets | 1 to 20 |
| Morse length | at most 10000 symbols |
| Dictionary size | 1 to 10000 |
| Word length | at most 20 letters |
| Answer | at most 2 * 10^9 |
| Judge time | 7000 ms |
| Memory | 1536 MB |
| Source size | 50000 B |

Every signal must end exactly at a word boundary.

Sample input and output:

Input:

```
1
.---.--.-.-.-.---...-.---.
6
AT
TACK
TICK
ATTACK
DAWN
DUSK
```

Output:

```
2
```

## Idea

Convert each word into dots and dashes, then walk a trie along the signal. Think of tracing a maze with a dictionary in hand and noting every exit.

The program stores words in a trie (a tree of shared prefixes). Dynamic programming counts ways to reach each signal position. A start position advances at most 80 pulses, the longest word code. Trying every word at every position would cost far more.

Takeaway: shared prefixes turn dictionary lookup into one signal walk.

## Why It Works

Each dictionary word ends at one node of the trie.

1. `morseCodes` maps every capital letter to dots and dashes.
2. `addWordToTrie` inserts one word along its pulse path.
3. `trieWordCount` counts words ending at a node.
4. `ways[j]` holds decodings of the signal prefix of length `j`.
5. Reaching the end adds `ways[j] * wordCount` to the next position.

The terms are:

| Term | Meaning |
| --- | --- |
| `trieDotChild` | Child node after a dot |
| `trieDashChild` | Child node after a dash |
| `ways` | Prefix decoding counts |
| `morseLength` | Number of pulses in the signal |

The root starts with one way.

A script decoded the sample:

| Word | Morse form |
| --- | --- |
| `AT` | `.--` |
| `ATTACK` | `.---.--.-.-.-` |
| `DAWN` | `-...-.---.` |
| `DUSK` | `-....-...-.-` |

Two full phrases match: `ATTACK AT DAWN` and `AT TACK AT DAWN`.

## Code

**Morse table and constants.**

```nim
const flushBlockBytes = 1 shl 16
const firstDigitValue = 48
const firstUpperValue = 65
const dashCharacter = '-'
const morseCodes = [
  ".-", "-...", "-.-.", "-..", ".", "..-.", "--.", "....", "..", ".---",
  "-.-", ".-..", "--", "-.", "---", ".--.", "--.-", ".-.", "...", "-",
  "..-", "...-", ".--", "-..-", "-.--", "--.."
]
```

The 26 codes follow alphabet order. Constants hold digit and character offsets.

**Token reading.**

```nim
proc readToken(inputData: string, i: var int, dataLength: int,
               j: var int, tokenLength: var int) =
  while i < dataLength and inputData[i] <= ' ':
    i += 1
  j = i
  while i < dataLength and inputData[i] > ' ':
    i += 1
  tokenLength = i - j

proc parseCount(inputData: string, i: int, tokenLength: int): int =
  result = 0
  for j in 0 ..< tokenLength:
    result = result * 10 + (int(inputData[i + j]) - firstDigitValue)
```

`readToken` finds the next word boundary by index. `parseCount` converts a numeric token without allocation.

**Trie insertion.**

```nim
proc addWordToTrie(inputData: string, i: int, wordLength: int,
                   trieDotChild: var seq[int], trieDashChild: var seq[int],
                   trieWordCount: var seq[int]) =
  var j = 0
  for k in 0 ..< wordLength:
    let code = morseCodes[int(inputData[i + k]) - firstUpperValue]
    for l in 0 ..< code.len:
      if code[l] == dashCharacter:
        if trieDashChild[j] == 0:
          trieDashChild.add 0
          trieDotChild.add 0
          trieWordCount.add 0
          trieDashChild[j] = trieWordCount.len - 1
        j = trieDashChild[j]
      else:
        if trieDotChild[j] == 0:
          trieDashChild.add 0
          trieDotChild.add 0
          trieWordCount.add 0
          trieDotChild[j] = trieWordCount.len - 1
        j = trieDotChild[j]
  trieWordCount[j] += 1
```

Each pulse follows or creates one child node. The final node increments the word count. One insert costs the word code length.

**Decoding count.**

```nim
proc countDecodings(inputData: string, i: int, morseLength: int,
                    ways: var seq[int], trieDotChild: seq[int],
                    trieDashChild: seq[int], trieWordCount: seq[int]): int =
  for j in 0 .. morseLength:
    ways[j] = 0
  ways[0] = 1
  for j in 0 ..< morseLength:
    let waysHere = ways[j]
    if waysHere == 0:
      continue
    var l = 0
    var k = j
    while k < morseLength:
      var nextNode: int
      if inputData[i + k] == dashCharacter:
        nextNode = trieDashChild[l]
      else:
        nextNode = trieDotChild[l]
      if nextNode == 0:
        break
      l = nextNode
      k += 1
      let wordCount = trieWordCount[l]
      if wordCount != 0:
        ways[k] += waysHere * wordCount
  return ways[morseLength]
```

The loop starts at every reachable position and stops at a missing trie edge. Each step adds ways when a word ends.

**Driver and output.**

```nim
proc main() =
  var inputData = ""
  var line = ""
  while readLine(stdin, line):
    inputData.add line
    inputData.add '\n'
  let dataLength = inputData.len
  var i = 0
  var j = 0
  var tokenLength = 0
  readToken(inputData, i, dataLength, j, tokenLength)
  let dataSetCount = parseCount(inputData, j, tokenLength)
  var ways: seq[int] = @[1]
  for k in 0 ..< dataSetCount:
    readToken(inputData, i, dataLength, j, tokenLength)
    let l = j
    let morseLength = tokenLength
    readToken(inputData, i, dataLength, j, tokenLength)
    let wordCount = parseCount(inputData, j, tokenLength)
    var trieDotChild: seq[int] = @[0]
    var trieDashChild: seq[int] = @[0]
    var trieWordCount: seq[int] = @[0]
    for k in 0 ..< wordCount:
      readToken(inputData, i, dataLength, j, tokenLength)
      addWordToTrie(inputData, j, tokenLength, trieDotChild,
                    trieDashChild, trieWordCount)
    if ways.len <= morseLength:
      ways.setLen(morseLength + 1)
    let answer = countDecodings(inputData, l, morseLength, ways,
                                trieDotChild, trieDashChild, trieWordCount)
    outputBuffer.add $answer
    outputBuffer.add '\n'
    if outputBuffer.len >= flushBlockBytes:
      stdout.write outputBuffer
      outputBuffer.setLen 0
  if outputBuffer.len > 0:
    stdout.write outputBuffer
    outputBuffer.setLen 0

main()
```

The program reads all lines once. It builds a fresh trie per data set and reuses the ways array. One write flushes the answers.

## Complexity

Trie size and signal length set the cost.

| Phase | Time | Space |
| --- | --- | --- |
| Input | O(Total characters) | O(Input size) |
| Trie build | O(Total word codes) | O(Total word codes) |
| Decode | O(Morse length * 80) | O(Morse length) |
| Output | O(D) | O(1) |

Eighty pulses is the longest word code.

| Measure | Bound |
| --- | --- |
| Time | O(Morse length * 80) per set |
| Space | O(Morse length + trie nodes) |

One pass over the signal visits each prefix once.

Matching every word at every position would multiply that pass by the dictionary size.
