package com.kitefishlabs.soundscapetk;

import java.util.Date;

public class LocationSegment {
	Date tsA, tsB;
	double latitude, longitude, accuracy;
	
	public LocationSegment (Date timeA, Date timeB, float lat, float lon, float acc) {
		tsA = timeA;
		tsB = timeB;
		latitude = lat;
		longitude = lon;
		accuracy = acc;
	}
	
}

