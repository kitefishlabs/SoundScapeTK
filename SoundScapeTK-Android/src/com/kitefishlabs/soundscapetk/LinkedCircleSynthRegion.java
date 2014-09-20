package com.kitefishlabs.soundscapetk;

public class LinkedCircleSynthRegion {
	float centerLat, centerLon, radius, internalDistance, maxDuration, anchorLat, anchorLon;
	int idNum, attackTime, releaseTime, finishRule, numLives, active;
	String label, state;
	int idsToActivate[];
	
	public LinkedCircleSynthRegion (float lat, float lon, float rad, int id, String lbl, int atk, int rel, int frule, int lives, int activeFlag, int [] toActivateIDs) {
		centerLat = lat;
		centerLon = lon;
		radius = rad;
		idNum = id;
		label = lbl;
		attackTime = atk;
		releaseTime = rel;
		finishRule = frule;
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