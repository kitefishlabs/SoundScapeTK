package com.kitefishlabs.soundscapetk;

import android.graphics.Point;

public class LinkedCircleSFRegion {
	float centerLat, centerLon, radius, internalDistance, maxDuration, anchorLat, anchorLon;
	int idNum, attackTime, releaseTime, finishRule, numLives, active;
	String label, state;
	int idsToActivate[];
	
	public LinkedCircleSFRegion (float lat, float lon, float rad, int id, String lbl, int atk, int rel, int rule, int lives, int activeFlag, int [] toActivateIDs) {
		centerLat = lat;
		centerLon = lon;
		radius = rad;
		idNum = id;
		label = lbl;
//		linkedSoundFiles = lsf;
		attackTime = atk;
		releaseTime = rel;
		finishRule = rule;
        numLives = lives;
        active = activeFlag;
        for (int i=0; i<toActivateIDs.length; i++) {
        	idsToActivate[i] = toActivateIDs[i];
        }
		state = "ready";
		anchorLat = 0;
		anchorLon = 0;
		// stop timer?
		internalDistance = 0.f;
	}
}


