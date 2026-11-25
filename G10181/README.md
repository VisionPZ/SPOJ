# G10181 — Diccionario Grado 10 (SPOJ)

<https://www.spoj.com/problems/G10181/>

Judge status: submissions return "Missing testcases", so the problem has no
test data and cannot be accepted. The solution below passes the local harness.
The statement's sample output also contains typos (`el ` with a trailing space,
`presat` for `presta`); the program prints clean lowercase words instead.

## Problem

The input is a text of at most 5000 lines, each up to 200 characters. A word is a run of consecutive letters, upper or lower case. Print every different word once, in lowercase, one per line, in alphabetical order. `casa` and `CASA` are the same word.

| Item | Bound |
|---|---|
| Lines | ≤ 5000 |
| Line length | ≤ 200 characters |
| Distinct words | ≤ 5000 |
| Judge limit | 1000 ms, 1536 MB |

The sample case:

```
los pollitos dicen
pio, PIO,pIo,
cuando tienen hambre.
cuando tiEnen frio,
La gallina busca,
el maiz y el trigo,
les da la comida,
y les presta abrigo
```

```
abrigo
busca
comida
cuando
da
dicen
el
frio
gallina
hambre
la
les
los
maiz
pio
pollitos
presta
tienen
trigo
y
```

## Idea

Sweep the bytes once, building the current word in a lowercase buffer; every non-letter byte flushes it into a set. Think of sorting mail: read each letter, drop it in its labeled box, and shake out the boxes at the end. Flushing appends one bytes object per word, so the pass costs one check per byte. Splitting on whitespace first would miss words glued to punctuation, like `pio,`.

## Why It Works

1. Uppercase ASCII sits 32 bytes above lowercase, so adding 32 folds `A-Z` onto `a-z`.
2. Commas, periods, digits and newlines all fail both letter tests, so they end a word.
3. A set removes duplicates as words arrive, so only distinct words are stored.
4. Sorting lowercase byte strings gives exactly alphabetical order.

| Term | Meaning |
|---|---|
| `seenWords` | set of finished words as bytes |
| `currentWord` | lowercase letters of the word being built |
| `lowercaseShift` | 32, the gap between upper and lower ASCII |
| `byteValue` | one byte of the input |
| `sortedWords` | the distinct words in order |

A word flush happens on any non-letter and once at the end, so the last line is never dropped.

A script-traced example from `gen.py`:

```
text "A a Bb"
words A->a, a->a, Bb->bb
set {a, bb} sorted: a, bb
```

The trace shows case folding and dedup in one pass.

## Code

**Sweep and flush.** This block builds words and drops them into the set.

```python
inputData = sys.stdin.buffer.read()
seenWords = set()
currentWord = bytearray()
for byteValue in inputData:
    if firstUpperValue <= byteValue <= lastUpperValue:
        currentWord.append(byteValue + lowercaseShift)
    elif firstLowerValue <= byteValue <= lastLowerValue:
        currentWord.append(byteValue)
    else:
        if currentWord:
            seenWords.add(bytes(currentWord))
            currentWord.clear()
if currentWord:
    seenWords.add(bytes(currentWord))
```

Each byte either extends the word or flushes it.
The final flush catches a last line without punctuation.
Cost is one pass over the input bytes.

**Sort and print.** This block orders the words and writes them.

```python
sortedWords = sorted(seenWords)
outputBuffer = b""
if sortedWords:
    outputBuffer = b"\n".join(sortedWords) + b"\n"
sys.stdout.buffer.write(outputBuffer)
```

Byte-string sort equals alphabetical order for lowercase words.
One write emits the whole dictionary.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Sweep | O(bytes) | distinct words |
| Sort | O(W log W) on word bytes | W items |
| Output | one write | joined buffer |

| Measure | Big O |
|---|---|
| Time | O(N + W log W) |
| Space | O(N) |

W is at most 5000, so the sort is trivial next to the scan.
