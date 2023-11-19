# map-shortest-path
A zig implementation for Dijkstra, A* and ALT path finding algorithms for real world map data. The code in this repository was
my submission for an exercise given in my Algorithms and Datastructures class.

Build an executable first in order to get OK running times for preprocessing and searching:

```
zig build-exe -O ReleaseFast main.zig
./main
```

## TODO
- [ ] Generalize A* to take any heuristic function - then make dijsktra an alias of A* with heuristic function = 0
- [ ] Make the heuristic distance a separate property on the node (it does not need to be recalculated each time)
- [ ] Create a better implementation of PriorityQueue for faster update times
- [ ] Fix ALT to actually work
