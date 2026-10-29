// Granular Looper (SuperCollider)
// Port of the Sonic Pi Granular Looper v1.0 (Mark Wiem 2016/10/17).
//
// Plays one sample from several start points, for several lengths of time,
// one after another in a loop.
//
// Open this file in the SuperCollider IDE, put the cursor anywhere inside the
// block below and press Cmd-Return (Ctrl-Enter on Windows/Linux). It boots
// the server, loads lib/, config.scd and the samples, then starts the looper.
// From a terminal, `sclang main.scd` does the same.
//
// live.scd has lines to evaluate while it plays.

(
~gl = ~gl ? ();
~gl[\root] = thisProcess.nowExecutingPath.dirname;

s = Server.default;
s.waitForBoot {
	(~gl[\root] +/+ "lib/synthdefs.scd").load;
	(~gl[\root] +/+ "config.scd").load;
	(~gl[\root] +/+ "lib/samples.scd").load;
	(~gl[\root] +/+ "lib/looper.scd").load;

	~gl[\loadSamples].(~gl[\sampleDir], s);
	s.sync;  // wait for SynthDefs and Buffer.read to finish

	"Granular Looper: playing %".format(~gl[\currentBuffer].value.path).postln;
	Pdef(\granularLooper).play(quant: 0);
};
)

