// Granular Looper: the looper pattern
//
// Pdef(\granularLooper) steps through ~gl[\startPoints] and
// ~gl[\playLengths] in order, forever, playing one slice per step. This is
// the `loop do ... end` from the Sonic Pi script: each slice starts at
// startPoint (0-1 across the file), plays playLength seconds of the source,
// and the next slice starts playLength seconds later.
//
// The lists are re-read at the start of every pass and the other settings
// on every slice, so everything in config.scd can be changed while it runs.

(
var gl;
~gl = ~gl ? ();
gl = ~gl;  // captured so the pattern works from any environment

// Port of scale_UI_to_zero_one: a length in seconds as a fraction of the
// sample's length.
gl[\secondsToFraction] = { |seconds, sampleSeconds|
	seconds / sampleSeconds
};

// Work out where one slice starts and how its envelope is shaped, the way
// Sonic Pi does for `sample buf, start:, finish:, attack:, release:`.
// `finish` is clipped to the end of the file, the segment's real length
// (in output seconds) depends on the rate, and `hold` fills whatever the
// attack and release don't. If attack + release is longer than the segment,
// both are shortened in proportion so the slice still stops at `finish`.
// Returns [startFrac, hold, attack, release], or nil for a silent slice.
gl[\sliceTiming] = { |start, length, sampleSeconds, rate, attack, release|
	var finish, segment, ramps, scale;

	start = start.clip(0, 1);
	finish = (start + gl[\secondsToFraction].(length, sampleSeconds)).clip(0, 1);
	segment = (finish - start) * sampleSeconds / rate.abs;
	ramps = attack + release;

	if(rate == 0 or: { segment <= 0 }) {
		nil
	} {
		if(ramps > segment) {
			scale = segment / ramps;
			attack = attack * scale;
			release = release * scale;
		};
		[
			if(rate < 0) { finish } { start },
			max(0, segment - attack - release),
			attack,
			release
		]
	}
};

// One pass through the slice lists.
gl[\onePass] = {
	var count = min(gl[\startPoints].size, gl[\playLengths].size);

	if(count == 0 or: { gl[\currentBuffer].value.isNil }) {
		// Nothing to play: wait a beat and look again, rather than spin.
		Pn(Event.silent(1), 1)
	} {
		Pbind(
			\startPoint, Pseq(gl[\startPoints].keep(count)),
			\playLength, Pseq(gl[\playLengths].keep(count)),
			\buf, Pfunc { gl[\currentBuffer].value },
			\instrument, Pfunc { |ev|
				("gl_slice_" ++ ev[\buf].numChannels.clip(1, 2)).asSymbol
			},
			\rate, Pfunc { gl[\playRate] },
			\amp, Pfunc { gl[\level] },
			\pan, Pfunc { gl[\panPos] },
			\out, Pfunc { gl[\outBus] },
			\timing, Pfunc { |ev|
				gl[\sliceTiming].(
					ev[\startPoint], ev[\playLength], ev[\buf].duration,
					ev[\rate], gl[\attackTime], gl[\releaseTime]
				) ? \silent  // a nil here would end the Pbind
			},
			\type, Pfunc { |ev| if(ev[\timing] == \silent) { \rest } { \note } },
			[\startFrac, \hold, \attack, \release], Pfunc { |ev|
				if(ev[\timing] == \silent) { [0, 0, 0, 0] } { ev[\timing] }
			},
			// Sleep in seconds: one beat is one second at the default tempo.
			\dur, Pkey(\playLength)
		)
	}
};

gl[\pattern] = Pn(Plazy { gl[\onePass].value });

Pdef(\granularLooper, gl[\pattern]);
)
