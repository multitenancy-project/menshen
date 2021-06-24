## Optimization Plan

### Parser
In current implementation, when packet filter module connects with one FIFO (i.e., Data Cache) and 
paser. The backpressure signal comes from (1) whether FIFO is full and (2) whether paresr is able
to accept new packets.

**Problem**: the packet filter is stuck at the parser waiting first 2 or 4 segments.

#### Fix
We can break parser into two modules: (1) the first module accepts incoming packet and output to a
FIFO; (2) the second module read from FIFO and do the parsing work.

