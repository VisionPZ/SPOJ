# SPOJ

![Nim 0.19.4](https://img.shields.io/badge/Nim-0.19.4-yellowgreen) ![1350 problems](https://img.shields.io/badge/problems-1350-brightgreen) ![GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-lightgrey)

## What it is

SPOJ is an online judge: it feeds a program input and checks its output against a time limit. The 1350 write-ups are grouped into topic folders; each folder has its own README index. Each problem folder holds four files:

- **`solution.nim`** — one file, no comments, bulk input, block output.
  Judge-restricted problems use `solution.cpp` (`NUMTH02`, `PLATON`, `QTREE`, `RAHIA`, `SIS110G401`), `solution.c`, `solution.bf`, or `solution.java` where Nim is not accepted. Algebra-heavy problems such as `PERIOD5` also use `solution.cpp`.
- **`gen.py`** — independent oracle that generates sample, edge, wide, random and max-output cases.
- **`test.sh`** — byte diff, hard kill, time gate, output gate.
- **`README.md`** — Problem, Idea, Why It Works, Code, Complexity.

Cases are generated, not committed.

## Index

| Category | Problems |
|---|---|
| [Strings & text](strings-text/README.md) | 115 |
| [Geometry & grids](geometry-grids/README.md) | 110 |
| [Graphs & trees](graphs-trees/README.md) | 98 |
| [Dynamic programming](dynamic-programming/README.md) | 90 |
| [Number theory & big integers](number-theory/README.md) | 125 |
| [Greedy, search & enumeration](greedy-search-enumeration/README.md) | 753 |
| [Data structures, bits & simulation](data-structures/README.md) | 59 |
| [Other (unlisted stubs)](other/README.md) | 9 |

## License

GPL-3.0. See [LICENSE](LICENSE).
