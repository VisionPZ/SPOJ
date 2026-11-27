# UC_OLAMUNDO — UCSAL - Olá Mundo! (SPOJ)

<https://www.spoj.com/problems/UC_OLAMUNDO/>

## Problem

A first program reads one name and greets that person in Portuguese. The greeting text is fixed; only the name changes.

The input is one line holding the name. Print the exact greeting line with that name inserted.

| item | bound |
|---|---|
| input | one name string |
| judge limit | 1000 ms, 1536 MB |

The sample fixes every character of the greeting, including accents.

Sample input:

```
Everton
```

Sample output:

```
Olá Everton, este é seu primeiro programa!
```

## Idea

Copy the fixed greeting around the name, like filling a blank on a printed form. Read the first line once, then write the greeting with that line inserted between its two fixed parts. No number parsing is needed because the input is text. One read and one buffered write settle the whole task.

## Why It Works

1. The first line of input holds the whole name.
2. The greeting has a fixed prefix and a fixed suffix.
3. Placing the name between them reproduces the required line exactly.
4. Trailing whitespace is dropped so the suffix starts at the right character.

| term | meaning |
|---|---|
| `raw` | byte accumulator holding the full input stream |
| `pos` | start byte index of the visitor name |
| `end` | end byte index before the line break |
| `out` | buffered output stream writing the greeting |

One line in, one line out.

Script-generated trace for the sample name:

```
prefix: "Olá "
name:   "Everton"
suffix: ", este é seu primeiro programa!"
```

Joining the three parts gives the sample output byte for byte.

## Code

**Bulk input and name bounds.** The stream is read in chunks once, then two walks isolate the name between line breaks.

```java
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;

class Main {
    public static void main(String[] args) throws Exception {
        InputStream in = System.in;
        ByteArrayOutputStream raw = new ByteArrayOutputStream();
        byte[] chunk = new byte[1 << 16];
        int got;
        while ((got = in.read(chunk)) > 0) {
            raw.write(chunk, 0, got);
        }
        byte[] data = raw.toByteArray();
        int pos = 0;
        while (pos < data.length && (data[pos] == '\n' || data[pos] == '\r' || data[pos] == ' ')) {
            pos++;
        }
        int end = pos;
        while (end < data.length && data[end] != '\n' && data[end] != '\r') {
            end++;
        }
```

The first walk skips leading whitespace, and the second stops at the first line break.
Reading in 64 KiB chunks preserves raw UTF-8 bytes without per-line calls.

**Greeting output.** Fixed UTF-8 slices wrap the scanned name slice cleanly.

```java
        OutputStream out = System.out;
        out.write("Ol\u00e1 ".getBytes(StandardCharsets.UTF_8));
        out.write(data, pos, end - pos);
        out.write(", este \u00e9 seu primeiro programa!\n".getBytes(StandardCharsets.UTF_8));
        out.flush();
    }
}
```

Writing byte slices directly avoids intermediate string concatenation.
One flush ends the run.

## Complexity

One line of text makes the whole run constant apart from reading and writing.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| greeting | one string join | one name slice |
| output | one buffered line | block buffer |

No parsing or search is needed beyond finding the line break.

| measure | Big O |
|---|---|
| time | O(input bytes) |
| space | O(input bytes) |

Analyzing every character for patterns would add work without changing the fixed greeting.
