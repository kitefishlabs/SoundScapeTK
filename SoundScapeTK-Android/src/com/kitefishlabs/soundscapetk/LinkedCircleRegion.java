package com.kitefishlabs.soundscapetk;

import android.graphics.Point;

public class LinkedCircleRegion {
	float centerLat, centerLon, radius, fundFreq, freqLFORate, ampLFORate, freqLFODepth, ampLFODepth, amplitude, internalDistance, maxDuration;
	int idNum, attack, release, numHarms;
	String label, state;
	
	public LinkedCircleRegion (int id, float lat, float lon, float rad, int atk, int rel, float fFreq, int nHarms, float fRate, float aRate, float fDepth, float aDepth, float amp, float maxdur, String lbl) {
		idNum = id;
		centerLat = lat;
		centerLon = lon;
		radius = rad;
		attack = atk;
		release = rel;
		fundFreq = fFreq;
		numHarms = nHarms;
		freqLFORate = fRate;
		ampLFORate = aRate;
		freqLFODepth = fDepth;
		ampLFODepth = aDepth;
		amplitude = amp;		
		maxDuration = maxdur;
		label = lbl;
		state = "initialized";
		internalDistance = 0.f;
	}
	
	
	
}
