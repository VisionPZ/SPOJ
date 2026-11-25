# SPOJ — 306 problems, one method

![Nim 0.19.4](https://img.shields.io/badge/Nim-0.19.4-yellowgreen) ![290 problems](https://img.shields.io/badge/problems-306-brightgreen) ![1451 cases](https://img.shields.io/badge/cases-1531-blue) ![GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-lightgrey)

## What it is

SPOJ is an online judge: it feeds a program input and checks its output against a time limit. This repo answers 306 SPOJ problems. Each folder holds four files:

- **`solution.nim`** — one file, no comments, bulk input, block output.
- **`gen.py`** — independent oracle that generates sample, edge, wide, random and max-output cases.
- **`test.sh`** — byte diff, hard kill, time gate, output gate.
- **`README.md`** — Problem, Idea, Why It Works, Code, Complexity.

Cases are generated, not committed. Statements live in `stmts/`.

## The 306 problems

Every row links to a full write-up. The last group comes from the SPOJ basics list. Cost is the dominant step for one case; `N` means the whole input.

### Strings & text (32)

KMP, borders, tries and rolling hashes keep matching linear. Expression parsing and text rewriting add one stack pass. DP over all substrings is the only quadratic corner.

| Code | Idea | Cost |
|---|---|---|
| [ABWORDS](ABWORDS/README.md) | Treat each string as a nested fork and give every fork a canonical shape (children sorted into a fixed order). | O(n) |
| [ADDREV](ADDREV/README.md) | Read the tokens as least-significant digit first (units column first) and add them column by column. | O(n) |
| [ASCIRC](ASCIRC/README.md) | Build one expression tree per register and share identical subtrees. | O(n) |
| [BEADS](BEADS/README.md) | Find the smallest rotation by racing two cursors around a doubled string. | O(n) |
| [BRICKS](BRICKS/README.md) | Fix each brick's identity by its occurrence order. | O(n) |
| [CMEXPR](CMEXPR/README.md) | Unpack each expression like nested boxes. | O(n²) |
| [CMPLS](CMPLS/README.md) | Extend a table of differences, like continuing a column of numbers by copying the last change down. | O(n²) |
| [CODE1](CODE1/README.md) | Convert the number by repeated division, like rewriting a decimal number in a new base. | O(n log n) |
| [CRYPTO2](CRYPTO2/README.md) | Add one to undo the shift, like turning a page number forward by one. | O(n) |
| [CRYPTO3](CRYPTO3/README.md) | Print twice the input, like doubling a price written on paper one digit at a time. | O(n) |
| [CRYPTO4](CRYPTO4/README.md) | Turn each known letter pair into a clue on a 26-hour clock. | O(n) |
| [DYZIO](DYZIO/README.md) | Parse the word into a cut tree. | O(n) |
| [EDIT1](EDIT1/README.md) | Keep one current line and grow it in place. | O(n) |
| [EDIT2](EDIT2/README.md) | Fill a substring cost table once, like completing a multiplication chart instead of recomputing each cell. | O(n²) |
| [EXPR1](EXPR1/README.md) | Parentheses matter only after a minus sign, like flipping the sign of every later term in a sum. | O(n) |
| [HOTLINE](HOTLINE/README.md) | Treat each sentence as an index card with a subject, a verb, an object, and a sign. | O(n) |
| [JEWELS](JEWELS/README.md) | Treat each half as a line of stones; keeping matching stones means choosing a common subsequence. | O(n) |
| [MAYA](MAYA/README.md) | Count the marks on each row, then multiply by that row's weight. | O(n) |
| [MORSE](MORSE/README.md) | Convert each word into dots and dashes, then walk a trie along the signal. | O(n) |
| [NHAY](NHAY/README.md) | Build the KMP failure table for the needle once. | O(n) |
| [ONP](ONP/README.md) | Scan the expression once. Send letters straight to the answer | O(n) |
| [PALIN](PALIN/README.md) | A palindrome is fixed by its first half. | O(n) |
| [PALSEC](PALSEC/README.md) | Build the palindrome from both ends inward. | O(n) |
| [PERIOD](PERIOD/README.md) | Measure how much of each prefix echoes at its end, then read off the repeat count. | O(n) |
| [PHRASES](PHRASES/README.md) | Guess a length, fingerprint every substring of that length. | O(n) |
| [ROMAN](ROMAN/README.md) | Read each word by its first letter, then print each decimal digit as a fixed Roman fragment. | O(n) |
| [SBANK](SBANK/README.md) | Read every account line as one string. | O(n log n) |
| [SBSTR1](SBSTR1/README.md) | Slide a short ruler over each line, the way you check a word inside a sentence. | O(1) |
| [SCYPHER](SCYPHER/README.md) | Neighboring words reveal one letter order each. | O(n³) |
| [SORTING](SORTING/README.md) | Count the letters like tally marks on a sheet, then rewrite the alphabet from A to Z. | O(n) |
| [STABLEMP](STABLEMP/README.md) | Let each free man ask the next woman on his list, like an applicant knocking on doors. | O(n²) |
| [WORDEQ](WORDEQ/README.md) | Treat each bit of each variable as a separate cell, then merge cells that must match. | O(n) |

### Geometry & grids (47)

Sorting plus a sweep gives O(n log n) for most hulls, bands and hull-based scans. Grid fills and pixel sweeps cost O(area). Exact area and convexity formulas stay O(n) per shape.

| Code | Idea | Cost |
|---|---|---|
| [ALICEBOB](ALICEBOB/README.md) | Peel degree-two corners (ears) from the polygon, like trimming ears off paper until a triangle remains. | O(n) |
| [ALIENS](ALIENS/README.md) | Grow a circle from random starting points. | O(n) |
| [ALTARS](ALTARS/README.md) | Treat each wall as a blocked slope interval, like finding a clear angle between walls seen edge on. | O(n) |
| [BAC](BAC/README.md) | Clip the plate by each halfway boundary between two samples, like slicing the plate with straight cuts. | O(n) |
| [BALL1](BALL1/README.md) | Fold the bouncing path into a straight diagonal. | O(n) |
| [BITMAP](BITMAP/README.md) | Spread distances across the grid from each white pixel, like a wave advancing one cell per step. | O(n) |
| [BSHEEP](BSHEEP/README.md) | Build the convex hull with Andrew's monotone chain (a method that walks a sorted point list). | O(n log n) |
| [BULK](BULK/README.md) | Use the divergence theorem (a rule linking a closed surface to the volume inside). | O(n) |
| [CHOCOLA](CHOCOLA/README.md) | Cut the dearest line first, like paying the largest bills before the small ones. | O(n) |
| [CISTFILL](CISTFILL/README.md) | Walk the water level upward, like reading a row of gauges from the bottom to the top. | O(n) |
| [CUTOUT](CUTOUT/README.md) | Only cut edges and the square border can bound an optimal rectangle, like fence posts around a field. | O(n²) |
| [CUTSQRS](CUTSQRS/README.md) | Every turn follows the Euclidean algorithm (repeated division by remainders). | O(n) |
| [DIRVS](DIRVS/README.md) | Check sightlines first, then draw the route, like checking which stations are in view before choosing a path. | O(n²) |
| [EMPTY](EMPTY/README.md) | Sweep the x edge and keep a segment tree (a tree storing best values over intervals) for the y and z edges. | O(n log n) |
| [EQBOX](EQBOX/README.md) | Sort each shape's sides so the short side comes first, like lining up a box and a tile before testing a tilt. | O(n) |
| [FLBRKLIN](FLBRKLIN/README.md) | Rewrite each point using two diagonal coordinates, like measuring the same spot from two different axes. | O(n) |
| [FOOTBALL](FOOTBALL/README.md) | Count faces with Euler's formula. | O(n) |
| [FSHEEP](FSHEEP/README.md) | The shepherd sees every corner from the origin, like rays spreading from a single point. | O(n log n) |
| [GLUE](GLUE/README.md) | Treat the box as the bounding rectangle of all dabs in some orientation. | O(n log n) |
| [JASIEK](JASIEK/README.md) | Convert the walk into area, then let a lattice rule count the squares. | O(n) |
| [LITEPIPE](LITEPIPE/README.md) | Find the furthest x where one straight ray still fits. | O(n) |
| [MAP](MAP/README.md) | Sort the populations first, then cut the sorted list into color groups. | O(n) |
| [MAZE](MAZE/README.md) | Track which rows a passage can reach after each column, plus one special turn that switches sides. | O(n) |
| [MOULDS](MOULDS/README.md) | Store the deepest cut at each 1 mm cell in a flat array. | O(n) |
| [PICAD](PICAD/README.md) | The count changes only when someone arrives or leaves. | O(n log n) |
| [PIR](PIR/README.md) | Recover the corner angles from the edge lengths, then apply a determinant formula. | O(n) |
| [PLONK](PLONK/README.md) | Split the walk into horizontal and vertical parts, then pick the middle house on each axis. | O(n) |
| [POLY1](POLY1/README.md) | Count the triangles a chosen triangle misses, then subtract from the total. | O(n) |
| [POLYEQ](POLYEQ/README.md) | Find the peaks and valleys first, then search each stretch between them. | O(n) |
| [POLYGAME](POLYGAME/README.md) | Check how exposed the black triangle is, then use parity. | O(n) |
| [POSTERS](POSTERS/README.md) | Read the posters backwards, like peeling notices off a wall from the top sheet down. | O(n) |
| [PROPKEY](PROPKEY/README.md) | Model the fall as a sequence of sideways slides, like a Tetris piece that slides but never rotates. | O(n²) |
| [RAIN1](RAIN1/README.md) | Picture the rain as vertical threads from the sky. | O(n log n) |
| [RECTNG1](RECTNG1/README.md) | Group rectangles like overlapping rubber stamps, then count the distinct ink islands. | O(n log n) |
| [RHOMBS](RHOMBS/README.md) | Walk around the polygon and count diamonds as they appear in the wake of each side. | O(n) |
| [ROCKETS](ROCKETS/README.md) | Pair the leftmost point first, like untangling crossing strings by deciding the one strand that must reach… | O(log n) |
| [RUNAWAY](RUNAWAY/README.md) | Grow a circle from a spot until it touches a hole. | O(log n) |
| [SEGVIS](SEGVIS/README.md) | Sweep the segments from left to right, like sliding a curtain across a row of posts. | O(n²) |
| [SHAMAN](SHAMAN/README.md) | Wrap a rubber band around all the peaks before choosing corners. | O(n) |
| [STONE](STONE/README.md) | A polygon balances at the area-weighted average of its pieces. | O(n) |
| [STORE](STORE/README.md) | Forget the keeper's exact square and remember only which side of the parcel they stand on. | O(n²) |
| [TRICENTR](TRICENTR/README.md) | Triple each given distance to recover a full height, then follow one fixed formula chain. | O(n) |
| [TRIPART](TRIPART/README.md) | Store squared side lengths and reduce each triple by its gcd, like simplifying a fraction. | O(n) |
| [WATER](WATER/README.md) | Flood the grid from the outside, always expanding the field with the lowest wall first. | O(n) |
| [WINDOW1](WINDOW1/README.md) | Sweep thin horizontal bands from the window bottom to its top. | O(n) |
| [WMELON](WMELON/README.md) | Compress the used coordinates, then slide one window over columns and another over rows. | O(n) |
| [ZEBRA](ZEBRA/README.md) | Only people with your crossing time can collide. | O(n) |

### Graphs & trees (31)

BFS, Dijkstra, Kruskal and union-find run in O(V + E) or O(E log E). Strong components and flow add one linear pass. The cost tracks edges, not vertices alone.

| Code | Idea | Cost |
|---|---|---|
| [BIA](BIA/README.md) | A computer is critical when it has a child in the dominator tree (tree of forced relays). | O(n) |
| [BICYCLE](BICYCLE/README.md) | Treat the two circles as a tiny graph: start. | O(1) |
| [BLINNET](BLINNET/README.md) | Sort every link by cost, then join cities with Kruskal's algorithm (a minimum spanning tree method). | O(n) |
| [BTOUR](BTOUR/README.md) | Anchor every loop at its lowest numbered intersection. | O(n) |
| [CAVE](CAVE/README.md) | Split every corridor at crossings and endpoints, then walk from node to node. | O(n) |
| [CHASE1](CHASE1/README.md) | Peel away leaves to find the board's core. | O(n) |
| [CONNECT](CONNECT/README.md) | Keep a sorted shortlist of the best few routes to every town. | O(n) |
| [CORNET](CORNET/README.md) | Trace each link chain like an org chart, then write the final boss's name on every file you visited. | O(n) |
| [COURIER](COURIER/README.md) | Fill a timetable of shortest legs before planning the route, like checking train times before booking a tour. | O(n³) |
| [DICE1](DICE1/README.md) | Use Dijkstra's algorithm (shortest paths with non-negative costs) on a repeating pattern. | O(n) |
| [FISHER](FISHER/README.md) | Treat each state and each elapsed minute as one stop, like adding a time column to the table of states. | O(n²) |
| [HIGH](HIGH/README.md) | Turn the link list into a degree-and-minus-one matrix, like writing the allowed city links into a table. | O(n) |
| [HMRO](HMRO/README.md) | Every office code is given a slot in a table of all office codes of the test case. | O(log n) |
| [ICERINK](ICERINK/README.md) | Picture sliding across the rink until an obstacle wall stops you, then pushing off in another direction. | O(n) |
| [INCARDS](INCARDS/README.md) | Run two delivery rounds, one outbound and one back, like sending a letter and its prepaid return envelope. | O(n) |
| [LABYR1](LABYR1/README.md) | The graph is a tree, so its longest path is the tree diameter. | O(n) |
| [LIFTS](LIFTS/README.md) | Measure heights in half-metres and time in half-seconds, so every position and meeting stays a whole number. | O(n) |
| [MLAND](MLAND/README.md) | Trace the lower edge of a pile of straight lines; that edge bends down at most once. | O(n) |
| [NETADMIN](NETADMIN/README.md) | Turn colors into street capacity, then search for the smallest capacity that works. | O(n) |
| [OFBEAT](OFBEAT/README.md) | Treat the two street directions as two sides of a crossing graph. | O(n) |
| [PANIC](PANIC/README.md) | Spread the panic first, then work out the best escape from every plaza. | O(n) |
| [POTHOLE](POTHOLE/README.md) | Treat the cave as a downhill plumbing network and push as many routes through it as possible. | O(n) |
| [PRIMIT](PRIMIT/README.md) | Treat each feature as a one-way arrow between two numbers. | O(n) |
| [ROADNET](ROADNET/README.md) | Use the distance table as the map: a town sits between two others when the direct distance equals the sum… | O(n²) |
| [SCRAPER](SCRAPER/README.md) | Picture every elevator as a station and every shared floor as a connecting corridor. | O(n) |
| [SERVERS](SERVERS/README.md) | Count nearby servers by racing waves outward from each rank, like ripples in a pond. | O(n) |
| [SHPATH](SHPATH/README.md) | Group questions by their starting city, like a travel desk handling one departure point at a time. | O(n) |
| [TOUR](TOUR/README.md) | Group contestants who can reach one another, then find the group that beats every other group. | O(n) |
| [TWORK](TWORK/README.md) | Treat each group as a path of length two, with a center who knows both ends. | O(n) |
| [WATERWAY](WATERWAY/README.md) | Choose each channel's arc to spread the load, then count the busiest fragment. | O(n) |
| [WORDS1](WORDS1/README.md) | Model each word as a directed edge from its first letter to its last letter. | O(n) |

### Dynamic programming (34)

Most tables are O(n²) or O(n·budget), filled once and reused. Knapsack, interval and digit DP trade memory for a single sweep. Meet-in-the-middle halves the exponent.

| Code | Idea | Cost |
|---|---|---|
| [ALIBB](ALIBB/README.md) | Treat each sweep as choosing which end to visit next, extending a collected block one item at a time. | O(n) |
| [BABTWR](BABTWR/README.md) | Turn each block into three orientations (choices of height axis) and sort them by base. | O(n) |
| [BLOCKS](BLOCKS/README.md) | Treat one minute as one orientation: permute rows or permute columns. | O(n²) |
| [BOOKS1](BOOKS1/README.md) | Binary search the largest block sum, called the load. | O(log n) |
| [BUNDLE](BUNDLE/README.md) | Run a dynamic program over instruction prefixes. | O(1) |
| [BUS](BUS/README.md) | Treat a meeting as a channel that passes news both ways. | O(n²) |
| [CRSCNTRY](CRSCNTRY/README.md) | A meeting is a checkpoint both cards visit in order. | O(n²) |
| [CTGAME](CTGAME/README.md) | Stack the free cells above each row like books on a shelf. | O(n) |
| [EXCHNG](EXCHNG/README.md) | Track a token (a possible origin of the minimum) in each register, like tagging each candidate where it sits. | O(n) |
| [HANGLET](HANGLET/README.md) | Represent every register by a formula over the unknown starting bits. | O(n) |
| [IKEYB](IKEYB/README.md) | Cut the letter string into `K` consecutive blocks, like slicing a long ribbon. | O(n) |
| [INUMBER](INUMBER/README.md) | Build the answer digit by digit, like trying shorter lock codes before longer ones. | O(n) |
| [LITELANG](LITELANG/README.md) | Keep the `n` cheapest words in a growing prefix tree. | O(n) |
| [MINIMAX](MINIMAX/README.md) | Track the cheapest way to deliver the maximum of inputs `1..x` to position `x`. | O(n) |
| [MUSKET](MUSKET/README.md) | Survivors keep their circle order after every duel, so the final duel joins two neighboring arcs. | O(n) |
| [NAPTIME](NAPTIME/README.md) | Try both ways around the circle and keep the better answer. | O(n) |
| [ORDERS](ORDERS/README.md) | Fill the ranks from right to left, taking the next free rank that fits. | O(n) |
| [PAINTTMP](PAINTTMP/README.md) | Decide the hole pattern one bit at a time. | O(n) |
| [PARTIT](PARTIT/README.md) | Count whole blocks of answers, then skip blocks until the target rank fits. | O(n) |
| [PARTY](PARTY/README.md) | Fill a budget table one party at a time, and keep the smallest cost that reaches the top fun. | O(n) |
| [PIGBANK](PIGBANK/README.md) | Unbounded knapsack: `best[t]` is the cheapest price that weighs exactly `t` grams. | O(n) |
| [SCITIES](SCITIES/README.md) | Pair sellers with buyers, then improve one pairing at a time until no swap raises the total goods. | O(n²) |
| [SCUBADIV](SCUBADIV/README.md) | Pack a knapsack with two measurements at once. | O(n) |
| [SHORTCUT](SHORTCUT/README.md) | Lay the route on a grid and group rest points by row, like sorting addresses by street. | O(n) |
| [SOLIT](SOLIT/README.md) | Meet in the middle, like two hikers starting at opposite ends of a trail and hoping to meet halfway. | O(n) |
| [STEVE](STEVE/README.md) | Solve every small game once and store the answer, like a chess player who memorizes all endgames. | O(n⁴) |
| [SUMITR](SUMITR/README.md) | Merge the triangle from the bottom row upward, like pruning a family tree from the leaves. | O(n²) |
| [SUPPER](SUPPER/README.md) | Check which numbers lie on a longest increasing run, like marking the cards that fit a longest rising row. | O(n log n) |
| [THREECOL](THREECOL/README.md) | Color each subtree from its leaves upward, keeping only two numbers for each node. | O(n) |
| [TRANS](TRANS/README.md) | Fill a chart of target intervals from shortest to longest, reusing each shorter result. | O(n²) |
| [TREE1](TREE1/README.md) | Treat the two subtrees as ordered lists that may interleave, each keeping its own internal order. | O(n) |
| [TREE2](TREE2/README.md) | Treat each tree as a bitstring and flip the rightmost zero that still allows a valid ending. | O(n) |
| [TRIP](TRIP/README.md) | Keep one cache of all best routes for every pair of list positions. | O(n²) |
| [TTABLE](TTABLE/README.md) | Work backward from the destination and keep only journeys that cannot be beaten. | O(1) |

### Number theory & big integers (26)

Modular exponentiation costs O(log p) per query. Big-integer limbs make multiplication O(n^1.585) with Karatsuba and most other arithmetic linear in digit count.

| Code | Idea | Cost |
|---|---|---|
| [ARITH](ARITH/README.md) | Store digits least significant first, like writing a column sum from the right-hand edge. | O(n) |
| [ATMS](ATMS/README.md) | Convert the amount to signed binary digits (plus or minus powers of two). | O(n) |
| [BINSTIRL](BINSTIRL/README.md) | Replace the big counting table with one bitwise test. | O(n) |
| [CRYPTO1](CRYPTO1/README.md) | Undo the square with a modular square root, like opening a padlock with the one key that fits. | O(n²) |
| [CUBERT](CUBERT/README.md) | Scale first, like measuring a room in millimeters to keep fractions exact. | O(n) |
| [DANCE](DANCE/README.md) | Track the tangle as one fraction, like a subtraction you can undo from either end. | O(n) |
| [FAMILY](FAMILY/README.md) | Store each relationship as a big integer (a number held in binary limbs). | O(n) |
| [FCTRL](FCTRL/README.md) | Count the fives hidden in the factorial, like tallying the fives that each multiple contributes to a product. | O(n) |
| [FCTRL2](FCTRL2/README.md) | Build every factorial once, like filling a multiplication table whose cells you can read later. | O(n) |
| [HAREFOX](HAREFOX/README.md) | Find the dominant part of a recurrence, like spotting the largest term as it outgrows the rest. | O(n) |
| [HOLIDAY1](HOLIDAY1/README.md) | Picture metronomes ticking from the same starting beat. | O(n) |
| [HOLIDAY2](HOLIDAY2/README.md) | Think of a rhythm as a ruler whose marks fall every `r` days. | O(n) |
| [IMP](IMP/README.md) | Reachable squares form a lattice: all integer combinations of the two move vectors. | O(log n) |
| [JULKA](JULKA/README.md) | Solve the riddle as Julka does: hand Klaudia the extra apples first, then split what remains. | O(n) |
| [MARBLES](MARBLES/README.md) | Place one marble of each color first, then count the remaining placements. | O(n) |
| [MAYACAL](MAYACAL/README.md) | Picture two wheels with different teeth: one turns every 260 days, the other every 365 days. | O(n) |
| [MUL](MUL/README.md) | Numbers are stored as lists of base 1 000 000 000 limbs. | O(n^1.585) |
| [MULTIPLY](MULTIPLY/README.md) | Read the whole input once, parse digits by hand, then multiply each pair in one operation. | O(n) |
| [PON](PON/README.md) | Probe a number with a few clever arithmetic questions instead of dividing by every smaller number. | O(1) |
| [POUR1](POUR1/README.md) | Act out the pouring with one fixed routine. | O(log n) |
| [PRIME1](PRIME1/README.md) | Sieve the window, not the number line. | O((n−m+1) log log n) |
| [SCALES](SCALES/README.md) | Treat each weight like a signed digit and carry the leftover into the next column. | O(n) |
| [SQRROOT](SQRROOT/README.md) | Fix one root digit at a time, the way long division fixes one quotient digit. | O(n²) |
| [TETRA](TETRA/README.md) | Cut the tetrahedron into four pyramids whose tips meet at the sphere's center. | O(1) |
| [TWOSQRS](TWOSQRS/README.md) | Factor the value and inspect only primes of the form `4k + 3`. | O((n−m+1) log log n) |
| [VFMUL](VFMUL/README.md) | Split each operand into three-digit chunks and convolve the chunk lists. | O(n) |

### Greedy, search & enumeration (19)

Binary search, greedy scans and bounded BFS keep work near-linear. Some problems enumerate a fixed state space; the bound comes from the spec, not from input size.

| Code | Idea | Cost |
|---|---|---|
| [AGGRCOW](AGGRCOW/README.md) | Guess a distance and walk the sorted stalls, like checking whether a row of stalls fits a spacing rule. | O(n log n) |
| [COMMEDIA](COMMEDIA/README.md) | Treat the empty slot as the largest tile, like swapping a blank card into a sorted deck. | O(n) |
| [CONTPACK](CONTPACK/README.md) | Stack boxes into tokens of equal height, like pairing identical tubes on a shelf. | O(n) |
| [CTAIN](CTAIN/README.md) | Search states in order of moves. | O(1) |
| [EASYPIE](EASYPIE/README.md) | Close each team-problem pair at its first accept, like crossing it off a list the first time it succeeds. | O(n) |
| [INTERVAL](INTERVAL/README.md) | Fill the rightmost open integer positions first, like taking the highest free slots in a row. | O(n) |
| [MAWORK](MAWORK/README.md) | Track time by its remainder on one shared clock. | O(n) |
| [MMIND](MMIND/README.md) | Build the code one pin at a time and stop when a hint can no longer match. | O(n) |
| [MONODIG](MONODIG/README.md) | Precompute every short expression once per digit. | O(n) |
| [PAYING](PAYING/README.md) | Add one to the sum, then count binary digits by repeated halving on paper. | O(n) |
| [PERMUT1](PERMUT1/README.md) | Insert the largest number last and count how many smaller numbers it passes. | O(n) |
| [PHONY](PHONY/README.md) | Mark numbers by a congruence for each small prime, then test only the marked ones. | O(n) |
| [RENT](RENT/README.md) | Treat the offers as jobs on one calendar and decide each one by comparing take against skip. | O(n log n) |
| [SHOP](SHOP/README.md) | Spread ripples from the entrance across the grid, like water finding the fastest path around rocks. | O(n) |
| [SLEEP](SLEEP/README.md) | Read the roof like a map that repeats nine neighborhoods inside each neighborhood. | O(n) |
| [STPAR](STPAR/README.md) | Push every arriving truck onto the side street. | O(n) |
| [SUM1SEQ](SUM1SEQ/README.md) | Treat each step as a coin that adds a fixed weight to the final sum. | O(1) |
| [TEST](TEST/README.md) | Copy every line until the line reads `42`, then stop. | O(n) |
| [VONNY](VONNY/README.md) | Place one domino at a time, always covering the square with the fewest legal partners. | O(n) |

### Data structures, bits & simulation (11)

Segment trees and Fenwick trees answer each update in O(log n). Bit packing divides a boolean sweep by 64. The rest is fixed-size simulation with constant cost per step.

| Code | Idea | Cost |
|---|---|---|
| [BRCKTS](BRCKTS/README.md) | Keep a scoreboard for every interval of the word. | O(n) |
| [DFLOOR](DFLOOR/README.md) | Light chasing (sweeping rows so each step fixes the row above) turns a search into a fixed sweep. | O(n²) |
| [HASHIT](HASHIT/README.md) | Treat the table as 101 numbered slots. | O(n) |
| [HELPR2D2](HELPR2D2/README.md) | Keep the ships in a row and always fill the leftmost one with room, like choosing the nearest open starship. | O(n) |
| [LONER](LONER/README.md) | A jump only rewrites a small pattern of neighbor cells. | O(n) |
| [RELATS1](RELATS1/README.md) | Rewrite each label as a lower bound. | O(n) |
| [ROCK](ROCK/README.md) | Score sweet as +1 and sour as −1, then a piece sells when its score is positive. | O(n) |
| [SOPARADE](SOPARADE/README.md) | Turn the parade into yes-or-no questions, like deciding which side of a fence each soldier sits on. | O(n) |
| [SQDANCE](SQDANCE/README.md) | A square appears when a new pair joins two primes already linked by earlier pairs. | O(n) |
| [SQRBR](SQRBR/README.md) | Walk the row left to right and keep one tally per current balance. | O(n) |
| [TAUT](TAUT/README.md) | Check every assignment at once by flipping whole rows of a truth table. | O(2ⁿ/64) |

## License

GPL-3.0. See [LICENSE](LICENSE).
