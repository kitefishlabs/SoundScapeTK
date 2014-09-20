package com.kitefishlabs.soundscapetk;

import java.util.Date;

public class TrackingMarker {
	Date timestamp;
	String markerType;
	// array args...
	
	public TrackingMarker (Date ts, String type) {
		timestamp = ts;
		markerType = type;
	}
}
