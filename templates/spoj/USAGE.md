# SPOJ solution template

Copy this directory when starting a new problem. It records the conventions used by every solution in this repository.

## Layout

One problem directory contains exactly one source file plus its harness:

```
CODE/
  solution.nim   driver and all helpers in one file, no comments
  gen.py         independent oracle, asserts, five test pairs
  test.sh        compile, byte diffs, hard timeouts, time and output gates
  README.md      five fixed explanation sections
  in/  out/      generated test data, ignored by git
  .gitignore     local build artifacts
```

Create a new problem with `bin/new.sh CODE LIMIT_MS`, then copy `solution.nim`, `gen.py`, `README.md` and `.gitignore` from this template. The scaffold supplies `test.sh` with the judge limit substituted. Use the limit from `.spoj/limits.tsv` and from the problem page.

## Program shape

- Read all of stdin once by looping `readLine(stdin, line)` into one `inputData` string, appending `'\n'` each time.
- Parse with a hand scanner. `nextInt(data, position)` skips non-digits and builds the value with `int(data[position]) - 48`. Add a minus branch only when the statement allows negative numbers.
- Keep one `outputBuffer`. `appendOutput(text)` adds text and flushes with `stdout.write` followed by `setLen 0` once the buffer reaches `flushBlockBytes`. Flush once more after the main loop.
- Name constants (`firstDigitValue`, `flushBlockBytes`), positions (`scanPos`, `leftIndex`), counts (`nodeCount`, `digitCount`) and buffers (`inputData`, `outputBuffer`). No single-letter names except one-line loop indices.
- Target Nim 0.19.4. Avoid `std/syncio`, `readAll`, `addInt`, `%`, `newSeqWith` and `seq.len = n`. Use `mod` and `setLen`. Sorting a `seq` needs an explicit comparator, so a small insertion sort is often simpler.
- Keep intermediates in `int64`; use two moduli and CRT when an exact determinant or product can overflow.

## Test generator

- Write an oracle that uses a genuinely different method from the solution. Cross-check it with brute force on small inputs.
- Assert at least two known values, including the sample.
- Emit `in/1_sample.txt` and `out/1_sample.out` verbatim from the statement. Check the bytes with `cat -A`.
- Emit `2_edges`, `3_wide`, `4_random` from a seeded generator, and `5_io` sized to exercise the output path within the statement's bounds. Do not build adversarial files so large that the local harness fails; keep stress files in `/tmp/CODE_big.txt`.

## Harness and local checks

- Compile with flags before the source file: `nim c -d:release --nimcache:.nimcache --out:build/solution solution.nim`. The local cache avoids collisions when several problems build at once.
- Run `./test.sh` with the default `nim` (0.19.4, the judge compiler) and with `NIM=~/.choosenim/toolchains/nim-2.4.2/bin/nim ./test.sh`. Both must print `sample OK`, the worst-case gate, the output gate, `generalized OK`, and exit 0.
- Break one constant and confirm the harness fails, then restore. Inject `while true: discard` and confirm a `TIMEOUT` line, then restore.
- Verify README headings with grep and every fenced block with a substring check against `solution.nim`.

## Judge submission

Local green is not proof of acceptance. Submit and poll:

```
node bin/spoj_submit.mjs CODE CODE/solution.nim --lang nim
node bin/spoj_status.mjs CODE
```

If a shared Vivaldi tab is occupied, set `SPOJ_PROFILE` and `SPOJ_PORT` to fresh paths under `/tmp/opencode`. Fix wrong answers and time limits, then resubmit until the status row says `accepted`. Some problems allow only Brainfuck or Intercal; submit those only if a solution exists in an allowed language.

## Git convention

One commit per solved challenge, named `Solve CODE in Nim`. Use the configured identity `Ping Zhao <ping.zhao@nidvue.com>` and do not pass `-c user.name` or `-c user.email` overrides. Commit only source, generator, harness, README and ignore rules. Never commit build output, generated `in/`/`out/` data, stress files or browser profiles.
