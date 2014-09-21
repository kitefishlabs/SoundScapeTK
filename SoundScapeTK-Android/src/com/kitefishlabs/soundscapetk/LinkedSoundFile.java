package com.kitefishlabs.soundscapetk;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import android.content.Context;
import android.content.res.AssetFileDescriptor;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.net.Uri;
import android.os.Environment;
import android.util.Log;
import android.widget.Toast;

public class LinkedSoundFile {
	
	Context context;
	String fileName;
	int idNum, channels, assignedSlot, attackTime, releaseTime, uniqueID;
	float duration, pausedOffset, startTime;
	
//	??? audioPlayer;

	public LinkedSoundFile(Context cntxt, String fname, int id, int aSlot, int atk, int rls, int unique, float dur, float poffset, float start) {
		context = cntxt;
		fileName = fname;
		idNum = id;
		assignedSlot = aSlot;
		attackTime = atk;
		releaseTime = rls;
		uniqueID = unique;
		duration = 0;
		pausedOffset = poffset;
		startTime = start;
		
		MediaPlayer metadataPlayer;
		
		if (isExternalStorageReadable()) {
			
			metadataPlayer = new MediaPlayer();
			
			Uri lsfURI = Uri.parse(Environment.getExternalStorageDirectory().getPath()+fileName);
			Log.v("lsf URI: ", lsfURI.getPath());
		    try {
		    	metadataPlayer.setDataSource(context.getApplicationContext(), lsfURI);
		    } catch (IllegalArgumentException e) {
		    	Toast.makeText(context.getApplicationContext(), "You might not set the URI correctly!", Toast.LENGTH_LONG).show();
		    } catch (SecurityException e) {
		    	Toast.makeText(context.getApplicationContext(), "You might not set the URI correctly!", Toast.LENGTH_LONG).show();
		    } catch (IllegalStateException e) {
		    	Toast.makeText(context.getApplicationContext(), "You might not set the URI correctly!", Toast.LENGTH_LONG).show();
		    } catch (IOException e) {
		    	e.printStackTrace();
		    }
			
		    metadataPlayer.setOnPreparedListener(new MediaPlayer.OnPreparedListener() {
				public void onPrepared(MediaPlayer mp) {
					duration = mp.getDuration();
					channels = 2;
				}
			});
		    
		    try {
		    	metadataPlayer.prepare();
		    } catch (IOException e) {
		    	e.printStackTrace();
		    }
		}		
	}
	
	public boolean isExternalStorageReadable() {
	    String state = Environment.getExternalStorageState();
	    if (Environment.MEDIA_MOUNTED.equals(state) ||
	        Environment.MEDIA_MOUNTED_READ_ONLY.equals(state)) {
	        return true;
	    }
	    return false;
	}

	boolean hasExternalStoragePrivateFile(String fileName) {
	    // Get path for the file on external storage.  If external
	    // storage is not currently mounted this will fail.
	    File file = new File(context.getExternalFilesDir(null), fileName);
	    if (file != null) {
	        return file.exists();
	    } else {	
	    	return false;
	    }
	}
}
