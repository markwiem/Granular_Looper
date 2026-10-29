// Granular Looper: SynthDefs
//
// One slice player per channel count (\gl_slice_1 for mono files,
// \gl_slice_2 for stereo). Each synth plays one segment of a buffer under a
// linear attack/hold/release envelope and frees itself when the envelope ends.
// The pattern in looper.scd computes `hold` so the envelope ends exactly where
// the segment's `finish` point is reached, which is what Sonic Pi does for
// `sample ..., start:, finish:, attack:, release:`.
//
// `hold` is used instead of `sustain` because the default Event computes its
// own `sustain` (dur * legato) and would send that to the synth.

(
~gl = ~gl ? ();

~gl[\synthDefs] = [1, 2].collect { |numChannels|
	SynthDef(("gl_slice_" ++ numChannels).asSymbol, {
		|out = 0, buf = 0, startFrac = 0, rate = 1, amp = 1, pan = 0,
		attack = 0.1, hold = 0, release = 0.1|
		var env, sig;

		env = EnvGen.ar(
			Env.linen(attack, hold, release, curve: \lin),
			doneAction: Done.freeSelf
		);
		sig = PlayBuf.ar(
			numChannels,
			buf,
			rate * BufRateScale.kr(buf),
			startPos: startFrac * BufFrames.kr(buf),
			loop: 0
		);
		sig = sig * env * amp;
		sig = if(numChannels == 1) {
			Pan2.ar(sig, pan)
		} {
			Balance2.ar(sig[0], sig[1], pan)
		};
		Out.ar(out, sig);
	})
};

~gl[\synthDefs].do(_.add);
)
