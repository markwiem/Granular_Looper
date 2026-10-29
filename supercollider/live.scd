// Granular Looper: live controls
//
// Start the looper with main.scd first. Then evaluate any of these lines
// (Shift-Return for one line, Cmd/Ctrl-Return for a block in parentheses)
// to change it while it plays. This file is a scratchpad; it is never loaded.

~gl[\startPoints] = [0.1, 0.35, 0.36, 0.7];
~gl[\playLengths] = [0.25, 0.25, 2, 1];
~gl[\playRate] = 0.5;
~gl[\attackTime] = 0.01; ~gl[\releaseTime] = 0.3;

// Swap samples: anything in samples/ by file name, or load one from anywhere.
~gl[\samples].keys.postln;
~gl[\sampleName] = \a11wlk01;
~gl[\loadSample].(\mySound, "/path/to/sound.wav");

// Stop, start, and clean up.
Pdef(\granularLooper).stop;
Pdef(\granularLooper).play;
(Pdef(\granularLooper).stop; ~gl[\freeSamples].value;)
