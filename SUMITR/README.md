## Problem

Read a number of test cases. Each case starts with a row count, then lists that many rows of numbers. Row k holds k numbers. Find the largest sum along a path that starts at the top number and ends at the base. Each step goes to the next row, either straight below or one place to the right. Print one answer per line.

The limits are:

| Quantity | Bound |
| --- | --- |
| Test cases | about 1000 |
| Rows per case | 1 to 99 |
| Cell value | 0 to 99 |
| Time limit | 2000 ms |
| Memory limit | 1536 MB |

The total number of cells reaches about five million, so reading and scoring must run in one streaming pass.

## Idea

Read all input into one string and turn it into one flat integer array. Work from the bottom row of each triangle upward, replacing each cell with the best sum from that cell to the base. The top cell then holds the answer, so no separate result array is needed.

Cost per cell: one integer addition and one comparison.

## Why It Works

A cell in row k has two children in row k+1. In the flat array, those children sit at offsets k+1 and k+2 from the cell. Adding the larger child to the cell gives the best sum from that cell to the base.

The update runs from the bottom row upward. Each child is already a finished sum when its parent is updated. The top cell of a case is the first number stored for that case, so reading it gives the answer.

The generator in gen.py prints the flat array for the first sample case after each row update:

```
start [1, 2, 1, 1, 2, 3]
k= 1 [1, 4, 4, 1, 2, 3]
k= 0 [5, 4, 4, 1, 2, 3]
answer: 5
```

The first entry ends at 5, which matches the sample output.

## Code

The program reads every byte of input once. `splitWhitespace` accepts spaces, tabs, newlines, and Windows line endings without producing empty tokens. `map(parseInt)` converts each token to an integer in one pass.

```nim
import strutils,sequtils
var s=stdin.readAll
var a=s.splitWhitespace.map(parseInt)
```

The read costs O(input size). Using `splitWhitespace` avoids the empty token that `split` creates at a carriage return. The conversion creates one integer array shared by all cases.

The case loop runs `a[0]` times. `p` points at each row count, then moves to the first triangle value. `countdown` walks rows from the bottom upward.

```nim
var p=1
for _ in 1..a[0]:
 let r=a[p];p+=1
 for k in countdown(r-2,0):
  let t=p+k*(k+1)div 2
  for j in 0..k:a[t+j]+=max(a[t+k+1+j],a[t+k+2+j])
```

The row index `k` runs from `r-2` down to 0. `t` is the start of row `k` inside the flat array, using the closed form `k*(k+1)div 2`. The inner loop visits `k+1` cells and costs one addition and one comparison each.

The answer is the first cell of the case. Advancing `p` by `r*(r+1)div 2` skips all values of the case.

```nim
 echo a[p];p+=r*(r+1)div 2
```

This line runs once per case. The final `echo` writes one line of output.

## Complexity

Reading and tokenizing take O(input size) time and O(input size) space for the string and integer array. The bottom-up pass takes O(R squared) time per case with R rows and O(1) extra space. Output takes O(T) time for T answer lines.

The totals are O(total cells) time and O(input size) space. Naive path enumeration takes O(2 to the R) time per case and cannot finish when R approaches 99.
