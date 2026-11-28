# BEANGAME — Help MR BEAN (SPOJ)

<https://www.spoj.com/problems/BEANGAME/>

## Problem

A runner stands on one of three tracks with a starting energy. Each level charges a hurdle on the track he chooses; changing track on the way to the next level earns drinks. Find moves that finish with the most energy, or report that the runner stops.

The input holds one game. The first line gives the start track, the start energy, and the number of levels. The next three lines give the hurdle on each track at every level. The last two lines give the drinks between tracks 1 and 2 and between tracks 2 and 3 at every gap between levels.

Output `DONE IT!` and then the moves, or `GAME OVER!`. Moves use `L` and `R` for one track, `LL` and `RR` for two tracks, and `U` for staying. A dash separates the move groups of consecutive levels.

| item | bound |
|---|---|
| levels | one game per input |
| tracks | 3 |
| values | 32-bit integers |
| judge limit | 1000 ms, 1536 MB |

Sample input and output:

```
1 6 5
3 2 9 16 3
4 0 7 26 1
1 7 3 30 9
8 19 8 3
10 3 6 4
```

```
DONE IT!
RR-LL-RR-LL-R
```

Each move group moves the runner before the hurdle of the next level.

## Idea

Keep only the best energy for each track after every hurdle, like a runner who remembers only his best time in each lane.

This is dynamic programming over levels and three tracks. From a track, the runner can stay, move one step left or right, or move two steps left or right, so each state has five outgoing moves. The program tries all five, adds the drinks on the crossed boundaries, pays the hurdle, and keeps the largest energy on each target track. It stores the previous track for each kept state, so the winning path can be read backwards. Trying every full path would cost 5 to the power of the number of levels; the program keeps three energies per level instead.

The program finishes in linear time and recovers one optimal path.

## Why It Works

1. Energy after a level depends only on the track and energy before that level.
2. Two states on the same track with different energy have the same future drinks and hurdles.
3. The lower-energy state can never overtake the higher-energy state, so it can be discarded.
4. A move across two boundaries collects the drink on each boundary in the order crossed.
5. The first gap has no drinks, because drinks sit between later levels.
6. A parent entry for every kept state reconstructs the path after the last level.

| term | meaning |
|---|---|
| `bestEnergy` | largest energy after the hurdle at the current level for each track |
| `hurdles` | energy paid on a track at a level |
| `leftDrink` | drink between tracks 1 and 2 at a gap |
| `rightDrink` | drink between tracks 2 and 3 at a gap |
| `parentTrack` | track occupied before each kept state |
| `parentMovedRight` | direction used to reach each kept state |

The sample path gives this energy trace:

| step | action | energy |
|---|---|---|
| start | track 1 | 6 |
| gap 0 | `RR`, then hurdle 1 | 5 |
| gap 1 | `LL` with drinks 10 and 8, then hurdle 2 | 21 |
| gap 2 | `RR` with drinks 19 and 3, then hurdle 3 | 40 |
| gap 3 | `LL` with drinks 6 and 8, then hurdle 16 | 38 |
| gap 4 | `R` with drink 3, then hurdle 1 | 40 |

No other path ends above 40, so the trace is the printed answer.

## Code

**Input buffer and integer scanner.** The whole input is read once; the scanner walks it by index.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

One read loop loads every line into `inputData`.
The newline keeps the last token separated.
Scanning never allocates a token string.

```nim
proc nextInt(): int =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value
```

The scanner skips separators before each number.
Digit values come from the character code minus 48.
No sign branch is needed because every input value is non-negative.

```nim
  for sourceTrack in 0 .. trackCount - 1:
    if bestEnergy[sourceTrack] <= 0:
      continue
    for targetTrack in 0 .. trackCount - 1:
      var energy = bestEnergy[sourceTrack]
      var movedRight = targetTrack > sourceTrack
      var stepCount = targetTrack - sourceTrack
      if stepCount < 0:
        stepCount = -stepCount
      var stepIndex = 0
      var valid = true
      while stepIndex < stepCount:
        if gapIndex > 0:
          let boundary = if movedRight: sourceTrack + stepIndex else: sourceTrack - 1 - stepIndex
          if boundary == 0:
            energy += leftDrink[gapIndex - 1]
          else:
            energy += rightDrink[gapIndex - 1]
        if energy <= 0:
          valid = false
          break
        stepIndex += 1
```

The two loops cover all 9 track pairs.
`boundary` names the drink crossed by one step.
An energy of zero ends the game, so the move is rejected.

```nim
  appendOutput("DONE IT!\n")
  appendOutput(moveGroups[0])
  for gapIndex in 1 .. levelCount - 1:
    appendOutput("-")
    appendOutput(moveGroups[gapIndex])
  appendOutput("\n")
```

The path is written after all groups are rebuilt backwards.
One buffer holds the whole answer until it flushes.
A dash separates adjacent groups, never the last one.

## Complexity

Reading and scanning cost O(input size). Each level processes 9 track pairs and at most 2 drink steps, so the dynamic program costs O(levels). Path reconstruction also costs O(levels).

| phase | time | space |
|---|---|---|
| scan input | O(input size) | O(input size) |
| dynamic program | O(9 × levels) | O(levels) for parents |
| path output | O(levels) | O(levels) |

The total is O(input size + levels) time and O(input size + levels) space. Enumerating all move sequences would cost O(5 to the power of levels), which grows far faster than the linear program.
