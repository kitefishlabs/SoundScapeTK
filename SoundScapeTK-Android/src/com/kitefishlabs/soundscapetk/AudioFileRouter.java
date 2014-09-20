package com.kitefishlabs.soundscapetk;

import java.util.HashMap;

public class AudioFileRouter {
	String patchString;
	HashMap <Integer, Boolean> hashMap;
	int numSlots;
	
	public AudioFileRouter (String patchstring, int numslots) {
		patchString = patchstring;
		numSlots = numslots;
	}
	
}
