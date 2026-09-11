package iron.format.gif;

/*
 * Copyright (c) 1994 Anthony Dekker
 * Ported to Java by Kevin Weiner, FM Software
 * Ported to Haxe by Tilman Schmidt and Sven Bergström
 *
 * NEUQUANT Neural-Net quantization algorithm by Anthony Dekker, 1994.
 * See "Kohonen neural networks for optimal colour quantization"
 * in "Network: Computation in Neural Systems" Vol. 5 (1994) pp 351-367.
 * for a discussion of the algorithm.
 *
 * Any party obtaining a copy of these files from the author, directly or
 * indirectly, is granted, free of charge, a full and unrestricted irrevocable,
 * world-wide, paid up, royalty-free, nonexclusive right and license to deal
 * in this software and documentation files (the "Software"), including without
 * limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons who receive
 * copies from any such party to do so, with the only requirement being
 * that this copyright notice remain intact.
 *
 */

import haxe.io.Int32Array;
import haxe.io.UInt8Array;

class NeuQuant {

	inline static var netsize         : Int = 256; // Number of colours used

	// Four primes near 500 - assume no image has a length so large that it is divisible by all four primes
	inline static var prime1          : Int = 499;
	inline static var prime2          : Int = 491;
	inline static var prime3          : Int = 487;
	inline static var prime4          : Int = 503;

	inline static var minpicturebytes : Int = (3 * prime4); // Minimum size for input image

	// Network Definitions
	inline static var netbiasshift    : Int = 4; // Bias for colour values
	inline static var ncycles         : Int = 100; // No. of learning cycles

	// Defs for freq and bias
	inline static var intbiasshift    : Int = 16; // Bias for fractions
	inline static var intbias         : Int = (1 << intbiasshift);
	inline static var gammashift      : Int = 10; // Gamma = 1024
	inline static var gamma           : Int = (1 << gammashift);
	inline static var betashift       : Int = 10;
	inline static var beta            : Int = (intbias >> betashift); // Beta = 1/1024
	inline static var betagamma       : Int = (intbias << (gammashift - betashift));

	// Defs for decreasing radius factor
	inline static var initrad         : Int = (netsize >> 3); // For 256 cols, radius starts
	inline static var radiusbiasshift : Int = 6; // At 32.0 biased by 6 bits
	inline static var radiusbias      : Int = (1 << radiusbiasshift);
	inline static var initradius      : Int = (initrad * radiusbias); // And decreases by a
	inline static var radiusdec       : Int = 30; // Factor of 1/30 each cycle

	// Defs for decreasing alpha factor
	inline static var alphabiasshift  : Int = 10; /* alpha starts at 1.0 */
	inline static var initalpha       : Int = (1 << alphabiasshift);

	// Radbias and alpharadbias used for radpower calculation
	inline static var radbiasshift    : Int = 8;
	inline static var radbias         : Int = (1 << radbiasshift);
	inline static var alpharadbshift  : Int = (alphabiasshift + radbiasshift);
	inline static var alpharadbias    : Int = (1 << alpharadbshift);

	var alphadec:Int; // Biased by 10 bits

		// Types and Global Variables

	var thepicture: UInt8Array;     // The input image itself
	var lengthcount: Int;           // Lengthcount = H*W*3
	var samplefac: Int;             // Sampling factor 1..30
	var network: Int32Array;        // The network itself - [netsize][4]
	var netindex: Int32Array;       // For network lookup - really 256
	var bias: Int32Array;           // Bias array for learning
	var freq: Int32Array;           // Frequency array for learning
	var radpower: Int32Array;       // Radpower for precomputation
	var colormap_map: UInt8Array;   // Cached color map array
	var colormap_index: Int32Array; // Cached color map index

	var learn_i: Int;
	var learn_pix: Int;
	var learn_samplepixels: Int;
	var learn_delta: Int;
	var learn_alpha: Int;
	var learn_radius: Int;
	var learn_rad: Int;
	var learn_step: Int;
	var learn_lim: Int;

	public function new()
	{
		netindex = new Int32Array(256);
		bias = new Int32Array(netsize);
		freq = new Int32Array(netsize);
		radpower = new Int32Array(initrad);
		network = new Int32Array(netsize * 4);
		colormap_map = new UInt8Array(3 * netsize);
		colormap_index = new Int32Array(netsize);
	}

	// Reset network in range (0,0,0) to (255,255,255) and set parameters
	public function reset(thepic:UInt8Array, len:Int, sample:Int):Void {
		thepicture = thepic;
		lengthcount = len;
		samplefac = sample;

		for (i in 0...netsize) {
			network[i*4 + 0] = network[i*4 + 1] = network[i*4 + 2] = Std.int((i << (netbiasshift + 8)) / netsize);
			freq[i] = Std.int(intbias / netsize); // 1 / netsize
			bias[i] = 0; // allocated to zero?
		}
	}

	public function colormap():UInt8Array
	{   
		for(i in 0...netsize) {
			colormap_index[network[i * 4 + 3]] = i;
		}

		var k:Int = 0;
		for (i in 0...netsize)
		{
			var j = colormap_index[i];
			colormap_map[k++] = network[j * 4];
			colormap_map[k++] = network[j * 4 + 1];
			colormap_map[k++] = network[j * 4 + 2];
		}

		return colormap_map;
	}

	// Insertion sort of network and building of netindex[0..255] (to do after unbias)
	public function inxbuild():Void
	{
		//var t0 = haxe.Timer.stamp();
		var i:Int;
		var j:Int;
		var smallpos:Int;
		var smallval:Int;
		var previouscol:Int;
		var startpos:Int;

		previouscol = 0;
		startpos = 0;

		for (i in 0...netsize)
		{
			smallpos = i;
			smallval = network[i*4 + 1]; // Index on g

			// Find smallest in i..netsize-1
			for (j in (i + 1)...netsize)
			{
				if (network[j*4 + 1] < smallval)
				{
					smallpos = j;
					smallval = network[j*4 + 1]; // Index on g
				}
			}


			// Swap p (i) and q (smallpos) entries
			if (i != smallpos)
			{
				j = network[smallpos*4 + 0];
				network[smallpos*4 + 0] = network[i*4 + 0];
				network[i*4 + 0] = j;
				j = network[smallpos*4 + 1];
				network[smallpos*4 + 1] = network[i*4 + 1];
				network[i*4 + 1] = j;
				j = network[smallpos*4 + 2];
				network[smallpos*4 + 2] = network[i*4 + 2];
				network[i*4 + 2] = j;
				j = network[smallpos*4 + 3];
				network[smallpos*4 + 3] = network[i*4 + 3];
				network[i*4 + 3] = j;
			}

			// Smallval entry is now in position i
			if (smallval != previouscol)
			{
				netindex[previouscol] = (startpos + i) >> 1;

				for (j in (previouscol + 1)...smallval)
					netindex[j] = i;

				previouscol = smallval;
				startpos = i;
			}
		}

		var maxnetpos = netsize - 1;

		netindex[previouscol] = (startpos + maxnetpos) >> 1;

		for (j in (previouscol + 1)...256)
			netindex[j] = maxnetpos;

		//var t1 = haxe.Timer.stamp();
		//trace("inxbuild time: " + (t1 - t0) + "s");
	}

	// Main learning Loop
	public function learn():Void
	{
		var t0 = haxe.Timer.stamp();
		learnInit();
		while (!learnStep(learn_samplepixels)) {}
		//var t1 = haxe.Timer.stamp();
		//trace("learn total time: " + (t1 - t0) + "s");
	}

	public function learnInit():Void
	{
		if (lengthcount < minpicturebytes)
			samplefac = 1;

		alphadec = 30 + Std.int((samplefac - 1) / 3);
		learn_pix = 0;
		learn_lim = lengthcount;
		learn_samplepixels = Std.int(lengthcount / (3 * samplefac));
		learn_delta = Std.int(learn_samplepixels / ncycles);
		learn_alpha = initalpha;
		learn_radius = initradius;

		learn_rad = learn_radius >> radiusbiasshift;

		if (learn_rad <= 1)
			learn_rad = 0;

		for (i in 0...learn_rad)
			radpower[i] = Std.int(learn_alpha * (((learn_rad * learn_rad - i * i) * radbias) / (learn_rad * learn_rad)));

		if (lengthcount < minpicturebytes)
		{
			learn_step = 3;
		}
		else if ((lengthcount % prime1) != 0)
		{
			learn_step = 3 * prime1;
		}
		else
		{
			if ((lengthcount % prime2) != 0)
			{
				learn_step = 3 * prime2;
			}
			else
			{
				if ((lengthcount % prime3) != 0)
					learn_step = 3 * prime3;
				else
					learn_step = 3 * prime4;
			}
		}

		learn_i = 0;
	}

	public function learnStep(maxSteps:Int):Bool
	{
		var processed = 0;
		var p = thepicture;

		while (processed < maxSteps && learn_i < learn_samplepixels)
		{
			var b = (p[learn_pix + 0] & 0xff) << netbiasshift;
			var g = (p[learn_pix + 1] & 0xff) << netbiasshift;
			var r = (p[learn_pix + 2] & 0xff) << netbiasshift;
			var j = contest(b, g, r);

			altersingle(learn_alpha, j, b, g, r);

			if (learn_rad != 0)
				alterneigh(learn_rad, j, b, g, r); // Alter neighbours

			learn_pix += learn_step;

			if (learn_pix >= learn_lim)
				learn_pix -= lengthcount;

			learn_i++;

			if (learn_delta == 0)
				learn_delta = 1;

			if (learn_i % learn_delta == 0)
			{
				learn_alpha -= Std.int(learn_alpha / alphadec);
				learn_radius -= Std.int(learn_radius / radiusdec);
				learn_rad = learn_radius >> radiusbiasshift;

				if (learn_rad <= 1)
					learn_rad = 0;

				for (k in 0...learn_rad)
					radpower[k] = Std.int(learn_alpha * (((learn_rad * learn_rad - k * k) * radbias) / (learn_rad * learn_rad)));
			}

			processed++;
		}

		return learn_i >= learn_samplepixels;
	}

	// Search for BGR values 0..255 (after net is unbiased) and return colour index
	public function map(b:Int, g:Int, r:Int):Int
	{
		var i:Int;
		var j:Int;
		var dist:Int;
		var a:Int;
		var bestd:Int;
		var best:Int;

		bestd = 1000; // Biggest possible dist is 256*3
		best = -1;
		i = netindex[g]; // Index on g
		j = i - 1; // Start at netindex[g] and work outwards

		while ((i < netsize) || (j >= 0))
		{
			if (i < netsize)
			{
				dist = network[i*4 + 1] - g; // Inx key

				if (dist >= bestd)
				{
					i = netsize; // Stop iter
				}
				else
				{
					if (dist < 0)
						dist = -dist;

					a = network[i*4 + 0] - b;

					if (a < 0)
						a = -a;

					dist += a;

					if (dist < bestd)
					{
						a = network[i*4 + 2] - r;

						if (a < 0)
							a = -a;

						dist += a;

						if (dist < bestd)
						{
							bestd = dist;
							best = network[i*4 + 3];
						}
					}

					i++;
				}
			}

			if (j >= 0)
			{
				dist = g - network[j*4 + 1]; // Inx key - reverse dif

				if (dist >= bestd)
				{
					j = -1; // Stop iter
				}
				else
				{
					if (dist < 0)
						dist = -dist;

					a = network[j*4 + 0] - b;

					if (a < 0)
						a = -a;

					dist += a;

					if (dist < bestd)
					{
						a = network[j*4 + 2] - r;

						if (a < 0)
							a = -a;

						dist += a;

						if (dist < bestd)
						{
							bestd = dist;
							best = network[j*4 + 3];
						}
					}

					j--;
				}
			}
		}

		return best;
	}

	public function process():UInt8Array
	{
		learn();
		unbiasnet();
		inxbuild();
		return colormap();
	}

	// Unbias network to give byte values 0..255 and record position i to prepare for sort
	public function unbiasnet():Void
	{
		for (i in 0...netsize)
		{
			network[i*4] >>= netbiasshift;
			network[i*4 + 1] >>= netbiasshift;
			network[i*4 + 2] >>= netbiasshift;
			network[i*4 + 3] = i; // Record colour no
		}
	}

	// Move adjacent neurons by precomputed alpha*(1-((i-j)^2/[r]^2)) in radpower[|i-j|]
	function alterneigh(rad:Int, i:Int, b:Int, g:Int, r:Int):Void
	{
		var j:Int;
		var k:Int;
		var lo:Int;
		var hi:Int;
		var a:Int;
		var m:Int;

		lo = i - rad;

		if (lo < -1)
			lo = -1;

		hi = i + rad;

		if (hi > netsize)
			hi = netsize;

		j = i + 1;
		k = i - 1;
		m = 1;

		while ((j < hi) || (k > lo))
		{
			a = radpower[m++];

			if (j < hi)
			{
				network[j * 4 + 0] -= Std.int((a * (network[j * 4 + 0] - b)) / alpharadbias);
				network[j * 4 + 1] -= Std.int((a * (network[j * 4 + 1] - g)) / alpharadbias);
				network[j * 4 + 2] -= Std.int((a * (network[j * 4 + 2] - r)) / alpharadbias);
				j++;
			}

			if (k > lo)
			{
				network[k * 4 + 0] -= Std.int((a * (network[k * 4 + 0] - b)) / alpharadbias);
				network[k * 4 + 1] -= Std.int((a * (network[k * 4 + 1] - g)) / alpharadbias);
				network[k * 4 + 2] -= Std.int((a * (network[k * 4 + 2] - r)) / alpharadbias);
				k--;
			}
		}
	}

	// Move neuron i towards biased (b,g,r) by factor alpha
	function altersingle(alpha:Int, i:Int, b:Int, g:Int, r:Int):Void
	{
		/* Alter hit neuron */
		network[i*4 + 0] -= Std.int((alpha * (network[i*4 + 0] - b)) / initalpha);
		network[i*4 + 1] -= Std.int((alpha * (network[i*4 + 1] - g)) / initalpha);
		network[i*4 + 2] -= Std.int((alpha * (network[i*4 + 2] - r)) / initalpha);
	}

	inline function make_abs(value:Int) : Int {
		var tmp = value >> 31;
		value ^= tmp;
		value += tmp & 1;
		return value;
	}

	// Search for biased BGR values
	static inline var bestd_init = ~(1 << 31);
	function contest(b:Int, g:Int, r:Int):Int
	{
		// Finds closest neuron (min dist) and updates freq
		// Finds best neuron (min dist-bias) and returns position
		// For frequently chosen neurons, freq[i] is high and bias[i] is negative
		// bias[i] = gamma*((1/netsize)-freq[i])

		var i:Int;
		var dist:Int;
		var a:Int;
		var biasdist:Int;
		var betafreq:Int;
		var bestpos:Int;
		var bestbiaspos:Int;
		var bestd:Int;
		var bestbiasd:Int;

		bestd = bestd_init;
		bestbiasd = bestd;
		bestpos = -1;
		bestbiaspos = bestpos;

		for (i in 0...netsize)
		{
			var i_n = i * 4;
			var b_i = i_n + 0;
			var g_i = i_n + 1;
			var r_i = i_n + 2;

			var b_a = network[b_i];
			var g_a = network[g_i];
			var r_a = network[r_i];

			b_a = make_abs(b_a - b);
			g_a = make_abs(g_a - g);
			r_a = make_abs(r_a - r);

			dist = b_a + g_a + r_a;

			if (dist < bestd)
			{
				bestd = dist;
				bestpos = i;
			}

			biasdist = dist - ((bias[i]) >> (intbiasshift - netbiasshift));

			if (biasdist < bestbiasd)
			{
				bestbiasd = biasdist;
				bestbiaspos = i;
			}

			betafreq = (freq[i] >> betashift);
			freq[i] -= betafreq;
			bias[i] += (betafreq << gammashift);
		}

		freq[bestpos] += beta;
		bias[bestpos] -= betagamma;
		return bestbiaspos;
	}

}