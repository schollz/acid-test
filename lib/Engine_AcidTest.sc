// Engine_AcidTest
Engine_AcidTest : CroneEngine {
	// <acidTest>
	var acidTestBusDelay;
	var acidTestBusReverb;
	var acidTestFX;
	var acidTestSynthBass;
	var acidTestSynthLead;
	// </acidTest>


	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {

		// <acidTest>

		// add synth defs
		SynthDef("mxfx",{ 
			arg inDelay, inReverb, reverb=0.05, reverbAttack=0.1,reverbDecay=0.5, out, secondsPerBeat=1/4,delayBeats=4,delayFeedback=0.1,bufnumDelay, t_trig=1;
			var snd,snd2,y,z;

			// delay
			// snd = In.ar(inDelay,2);
			// snd = CombC.ar(
			// 	snd,
			// 	2,
			// 	secondsPerBeat*delayBeats,
			// 	secondsPerBeat*delayBeats*LinLin.kr(delayFeedback,0,1,2,128),// delayFeedback should vary between 2 and 128
			// ); 
			// Out.ar(out,snd);

			// reverb
			snd2 = In.ar(inReverb,2);
			snd2 = DelayN.ar(snd2, 0.03, 0.03);
			snd2 = CombN.ar(snd2, 0.1, {Rand(0.01,0.099)}!32, 4);
			snd2 = SplayAz.ar(2, snd2);
			snd2 = LPF.ar(snd2, 1500);
			5.do{snd2 = AllpassN.ar(snd2, 0.1, {Rand(0.01,0.099)}!2, 3)};
			snd2 = LPF.ar(snd2, 1500);
			snd2 = LeakDC.ar(snd2);

			snd2=snd2*(1-EnvGen.ar(Env.perc(reverbAttack,reverbDecay), t_trig));

			Out.ar(out,snd2);
		}).add;

		// hotroded version of "08091500acidTest309 by_otophilia"

		SynthDef("kick", {
			arg outBus=0, amp=1.0, pitch=40,
			reverbOut, reverbSend=0, delayOut, delaySend=0;
			var env0, env1, env1m, out, snd;

			env0 =  EnvGen.ar(Env.new([0.5, 1, 0.5, 0], [0.005, 0.06, 0.26], [-4, -2, -4]), doneAction:2);
			env1 = EnvGen.ar(Env.new([110, 59, 29], [0.005, 0.29], [-4, -5]));
			env1m = env1.midicps;

			out = LFPulse.ar(env1m, 0, 0.5, 1, -0.5);
			out = out + WhiteNoise.ar(1);
			out = LPF.ar(out, env1m*1.5, env0);
			out = out + SinOsc.ar(env1m, 0.5, env0);

			out = out * 1.2;
			out = out.clip2(1);

			snd = out.dup;

			Out.ar(delayOut,snd*delaySend);
			Out.ar(reverbOut,snd*reverbSend);
			Out.ar(outBus, snd*amp);
		}).add;

		SynthDef("snare", {
			arg outBus=0, amp=1.0, pitch=40,
			reverbOut, reverbSend=0, delayOut, delaySend=0;
			var env0, env1, env2, env1m, oscs, noise, out, snd;

			env0 = EnvGen.ar(Env.new([0.5, 1, 0.5, 0], [0.005, 0.03, 0.10], [-4, -2, -4]));
			env1 = EnvGen.ar(Env.new([110, 60, 49], [0.005, 0.1], [-4, -5]));
			env1m = env1.midicps;
			env2 = EnvGen.ar(Env.new([1, 0.4, 0], [0.05, 0.13], [-2, -2]), doneAction:2);

			oscs = LFPulse.ar(env1m, 0, 0.5, 1, -0.5) + LFPulse.ar(env1m * 1.6, 0, 0.5, 0.5, -0.25);
			oscs = LPF.ar(oscs, env1m*1.2, env0);
			oscs = oscs + SinOsc.ar(env1m, 0.8, env0);

			noise = WhiteNoise.ar(0.2);
			noise = HPF.ar(noise, 200, 2);
			noise = BPF.ar(noise, 6900, 0.6, 3) + noise;
			noise = noise * env2;

			out = oscs + noise;
			out = out.clip2(1) * amp;
			snd = out.dup;

			Out.ar(delayOut,snd*delaySend);
			Out.ar(reverbOut,snd*reverbSend);
			Out.ar(outBus, snd);
		}).add;

		SynthDef("clap", {
			arg outBus=0, amp=1.0, pitch=40,
			reverbOut, reverbSend=0, delayOut, delaySend=0;
			var env1, env2, out, noise1, noise2, snd;

			env1 = EnvGen.ar(Env.new([0, 1, 0, 1, 0, 1, 0, 1, 0], [0.001, 0.013, 0, 0.01, 0, 0.01, 0, 0.03], [0, -3, 0, -3, 0, -3, 0, -4]));
			env2 = EnvGen.ar(Env.new([0, 1, 0], [0.02, 0.3], [0, -4]), doneAction:2);

			noise1 = WhiteNoise.ar(env1);
			noise1 = HPF.ar(noise1, 600);
			noise1 = BPF.ar(noise1, 2000, 3);

			noise2 = WhiteNoise.ar(env2);
			noise2 = HPF.ar(noise2, 1000);
			noise2 = BPF.ar(noise2, 1200, 0.7, 0.7);

			out = noise1 + noise2;
			out = out * 2;
			out = out.softclip * amp;

			snd = out.dup;

			Out.ar(delayOut,snd*delaySend);
			Out.ar(reverbOut,snd*reverbSend);
			Out.ar(outBus, snd);
		}).add;

		SynthDef("hat", {
			arg outBus=0, amp=1.0, pitch=40,
			reverbOut, reverbSend=0, delayOut, delaySend=0;
			var env1, env2, out, oscs1, noise, n, n2, snd;

			n = 5;
			thisThread.randSeed = 4;

			env1 = EnvGen.ar(Env.new([0, 1.0, 0], [0.001, 0.2], [0, -12]));
			env2 = EnvGen.ar(Env.new([0, 1.0, 0.05, 0], [0.002, 0.05, 0.03], [0, -4, -4]), doneAction:2);

			oscs1 = Mix.fill(n, {|i|
				SinOsc.ar(
					( i.linlin(0, n-1, 42, 74) + rand2(4.0) ).midicps,
					SinOsc.ar( (i.linlin(0, n-1, 78, 80) + rand2(4.0) ).midicps, 0.0, 12),
					1/n
				)
			});

			oscs1 = BHiPass.ar(oscs1, 1000, 2, env1);
			n2 = 8;
			noise = WhiteNoise.ar;
			noise = Mix.fill(n2, {|i|
				var freq;
				freq = (i.linlin(0, n-1, 40, 50) + rand2(4.0) ).midicps.reciprocal;
				CombN.ar(noise, 0.04, freq, 0.1)
			}) * (1/n) + noise;
			noise = BPF.ar(noise, 6000, 0.9, 0.5, noise);
			noise = BLowShelf.ar(noise, 3000, 0.5, -6);
			noise = BHiPass.ar(noise, 1000, 1.5, env2);

			out = noise + oscs1;
			out = out.softclip;
			out = out * amp;

			snd = out.dup;

			Out.ar(delayOut,snd*delaySend);
			Out.ar(reverbOut,snd*reverbSend);
			Out.ar(outBus, snd);
		}).add;

		SynthDef("acidTest", {
			arg outBus=0, amp=1.0,
			gate=1, pitch=50,port=0,
			reverbOut, reverbSend=0, delayOut, delaySend=0;
			var env1, env2, out, snd;
			pitch = Lag.kr([pitch,pitch+0.05], port);
			env1 = EnvGen.ar(Env.new([0, 1.0, 0, 0], [0.001, 2.0, 0.04], [0, -4, -4], 2), gate, amp);
			env2 = EnvGen.ar(Env.adsr(0.001, 0.8, 0, 0.8, 70, -4), gate);
			out = LFSaw.ar(pitch.midicps, 2, -1);

			out = MoogLadder.ar(out, (pitch + env2/2).midicps+(LFNoise1.kr(0.2,1100,1500)),LFNoise1.kr(0.4,0.9).abs+0.3,3);
			out = LeakDC.ar((out * env1).tanh/2.7);

			snd = out.tanh;

			Out.ar(delayOut,snd*delaySend);
			Out.ar(reverbOut,snd*reverbSend);
			Out.ar(outBus, snd);
		}).add;


		SynthDef("acidTest2", {
			arg outBus=0, amp=1.0,
			gate=1, pitch=50,port=0,
			reverbOut, reverbSend=0, delayOut, delaySend=0;
			var env1, env2, out, snd;
			pitch = Lag.kr([pitch,pitch+0.05], port);
			env1 = EnvGen.ar(Env.perc(0.01,0.7,4,-4), gate, amp);
			env2 = EnvGen.ar(Env.perc(0.001,0.3,600*SinOsc.kr(0.123).range(0.5,4),-3), gate);
			out = LFPulse.ar(pitch.midicps, 0, 0.5);

			out = MoogLadder.ar(out, 100+pitch.midicps + env2,LinExp.kr(SinOsc.kr(0.153),-1,1,0.01,0.6));
			out = LeakDC.ar((out * env1).tanh);

			snd = out.tanh;

			Out.ar(delayOut,snd*delaySend);
			Out.ar(reverbOut,snd*reverbSend);
			Out.ar(outBus, snd);
		}).add;

		// initialize fx synth and bus
		context.server.sync;
		acidTestBusDelay = Bus.audio(context.server,2);
		acidTestBusReverb = Bus.audio(context.server,2);
		context.server.sync;
		acidTestFX = Synth.new("mxfx",[\out,0,\inDelay,acidTestBusDelay,\inReverb,acidTestBusReverb]);
		context.server.sync;
		acidTestSynthLead = Synth.before(acidTestFX,"acidTest",[\amp,0,\out,0,\delayOut,acidTestBusDelay,\reverbOut,acidTestBusReverb]);
		acidTestSynthBass = Synth.before(acidTestFX,"acidTest2",[\amp,0,\out,0,\delayOut,acidTestBusDelay,\reverbOut,acidTestBusReverb]);
		context.server.sync;

		// add norns commands
		this.addCommand("acidTest_bass","fffff",{ arg msg;
			acidTestSynthBass.set(
				\amp,msg[1],
				\pitch,msg[2],
				\delaySend,msg[3],
				\reverbSend,msg[4],
				\port,msg[5],
			);
		});
		this.addCommand("acidTest_bass_gate","i",{ arg msg;
			acidTestSynthBass.set(
				\gate,msg[1],
			);
		});

		this.addCommand("acidTest_lead","fffff",{ arg msg;
			acidTestSynthLead.set(
				\amp,msg[1],
				\pitch,msg[2]+12,
				\delaySend,msg[3],
				\reverbSend,msg[4],
				\port,msg[5],
			);
		});

		this.addCommand("acidTest_lead_gate","i",{ arg msg;
			acidTestSynthLead.set(
				\gate,msg[1],
			);
		});

		this.addCommand("acidTest_drum","sfff",{ arg msg;
			Synth.before(acidTestFX,msg[1].asString,[
				\amp,msg[2],
				\delayOut,acidTestBusDelay,
				\delaySend,msg[3],
				\reverbOut,acidTestBusReverb,
				\reverbSend,msg[4],
			]);
		});

		this.addCommand("acidTest_reverb","iff",{ arg msg;
			acidTestFX.set(
				\t_trig,msg[1],
				\reverbAttack,msg[2],
				\reverbDecay,msg[3],
			);
		});

		// engine.acidTest_delay(clock.get_beats()/16,8,0.5)
		this.addCommand("acidTest_delay","fff",{ arg msg;
			acidTestFX.set(
				\secondsPerBeat,msg[1],
				\delayBeats,msg[2],
				\delayFeedback,msg[3],
			);
		});
		// </acidTest>
	}

	free {
		// <acidTest>
		acidTestSynthBass.free;
		acidTestSynthLead.free;
		acidTestFX.free;
		acidTestBusDelay.free;
		acidTestBusReverb.free;
		// </acidTest>
	}
}
