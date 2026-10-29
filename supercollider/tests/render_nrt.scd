// Granular Looper: offline render test
//
// Renders the looper to a sound file in non-realtime mode, so it can be
// checked without a sound card, and prints each slice's timing. Run it from
// a terminal:
//
//     sclang tests/render_nrt.scd [seconds] [sample.wav] [out.wav]
//
// Defaults: 20 seconds, the first file in samples/ (or SuperCollider's
// a11wlk01.wav), written to tests/render.wav. Uses config.scd as is.

(
var args = thisProcess.argv;
var seconds = (args[0] ? "20").asFloat;
var root = thisProcess.nowExecutingPath.dirname.dirname;
var outPath = args[2] ? (root +/+ "tests/render.wav");
var server = Server.default;
var samplePath, soundFile, buf, score, events;

~gl = ();
~gl[\root] = root;
(root +/+ "lib/synthdefs.scd").load;
(root +/+ "config.scd").load;
(root +/+ "lib/samples.scd").load;
(root +/+ "lib/looper.scd").load;

samplePath = args[1] ?? {
	var file = PathName(~gl[\sampleDir]).files.detect { |f|
		["wav", "aif", "aiff", "flac"].includesEqual(f.extension.toLower)
	};
	file !? (_.fullPath) ? ~gl[\fallbackSample]
};

// No server runs here, so describe the buffer by hand from the file header.
soundFile = SoundFile.openRead(samplePath) ?? {
	"Could not open %".format(samplePath).error; 1.exit
};
soundFile.close;
buf = Buffer(server, soundFile.numFrames, soundFile.numChannels, 0);
buf.sampleRate = soundFile.sampleRate;
buf.path = samplePath;
~gl[\samples][\test] = buf;
~gl[\sampleName] = \test;

"sample: % (% ch, % s)".format(
	samplePath, buf.numChannels, buf.duration.round(0.001)
).postln;

// Print the first two passes so the timing can be checked by eye.
"start  length  startFrac  attack   hold     release  next in  swing lag".postln;
events = Pdef(\granularLooper).source.asStream.nextN(
	min(~gl[\startPoints].size, ~gl[\playLengths].size) * 2, ()
);
events.do { |ev|
	"%  %  %  %  %  %  %  %".format(
		*[ev[\startPoint], ev[\playLength], ev[\startFrac], ev[\attack],
			ev[\hold], ev[\release], ev[\dur], ev[\lag]].collect { |v|
			v.round(0.0001).asString.padRight(7)
		}
	).postln;
};

score = Pdef(\granularLooper).source.asScore(seconds, 0.001);
score.add([0.0, [\b_allocRead, buf.bufnum, samplePath]]);
~gl[\synthDefs].do { |def| score.add([0.0, [\d_recv, def.asBytes]]) };
score.add([seconds, [\c_set, 0, 0]]);  // marks the end of the render
score.sort;

score.recordNRT(
	outputFilePath: outPath,
	headerFormat: "wav",
	sampleFormat: "int16",
	options: ServerOptions.new.numOutputBusChannels_(2),
	duration: seconds,
	action: {
		"rendered % s to %".format(seconds, outPath).postln;
		0.exit;
	}
);
)
