# Elfos-xlife

This is for the 1802 with a TMS9XXX video display processor. It's built for video on I/O ports 1 (memory) and 5 (register).

This is a pretty direct implementation that recalculates each cell each generation by counting neighbors. It has some light optimization to take advantage of some 1802 characteristics. It runs about 1.6 generations per second for the 64 x 48 display area.
