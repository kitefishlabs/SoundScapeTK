package com.kitefishlabs.soundscapetk;

import java.io.IOException;
import java.io.InputStream;
import java.util.Iterator;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.util.Log;

// import android.content.Context;

public class ScapeManager {

	String jsonFile;
//	Context context;
	
	public ScapeManager (String filePath) {
//		context = ctxt;
		jsonFile = filePath;
		readJSON(jsonFile);
	}
	
	public void readJSON (String jsonFile) {
		String data = loadJSONFromAsset(jsonFile);
		Log.v("JSON String: ", data);
		
		try {
			JSONObject object = new JSONObject(data);
			JSONObject regions = object.getJSONObject("regions");
			Iterator<String> keys = regions.keys();
			while (keys.hasNext()) {
				String key = keys.next();
				Log.v("regionID: ", key);
				JSONObject reg = regions.getJSONObject(key);
				
				float lat = Float.valueOf( reg.getString("lat") );
				float lon = Float.valueOf( reg.getString("lon") );
				float rad = Float.valueOf( reg.getString("rad") );
				Log.v("lat: ", reg.getString("lat"));
				Log.v("lon: ", reg.getString("lon"));
				Log.v("rad: ", reg.getString("rad"));
				
				int atk = Integer.valueOf( reg.getString("attack") );
				int rls = Integer.valueOf( reg.getString("release") );
				Log.v("atk: ", reg.getString("attack"));
				Log.v("rls: ", reg.getString("release"));
				
				JSONArray params = reg.getJSONArray("params");
				float basefreq = Float.valueOf( params.getString(0) ); 
				int harms = Integer.valueOf( params.getString(1) );
				float lfofreqrate = Float.valueOf( params.getString(2) );
				float lfoamprate = Float.valueOf( params.getString(3) );
				float lfofreqdepth = Float.valueOf( params.getString(4) );
				float lfoampdepth = Float.valueOf( params.getString(5) );
				
				Log.v("A: ", params.getString(0));
				Log.v("B: ", params.getString(1));
				Log.v("C: ", params.getString(2));
				Log.v("D: ", params.getString(3));
				Log.v("E: ", params.getString(4));
				Log.v("F: ", params.getString(5));
				
				float amp = Float.valueOf( reg.getString("amp") );
				float maxdur= Float.valueOf( reg.getString("maxdur") );
				Log.v("amp: ", reg.getString("amp"));
				Log.v("max dur: ", reg.getString("maxdur"));
				
				String lbl = reg.getString("label");
				Log.v("lbl: ", reg.getString("label"));
				
				int k = Integer.parseInt(key);
				//LinkedCircleRegion (int id, float lat, float lon, float rad, int atk, int rel, 
				//	float fFreq, int nHarms, float fRate, float aRate, float fDepth, float aDepth, float amp, int maxdur, String lbl) {
				LinkedCircleRegion lcr = new LinkedCircleRegion(k, lat, lon, rad, atk, rls, 
					basefreq, harms, lfofreqrate, lfoamprate, lfofreqdepth, lfoampdepth, amp, maxdur, lbl);
				Log.v("LCR: ", lcr.toString());
			}
		} catch (JSONException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
			
		
//		JSONObject regions = new JSONObject(data);
	}
	
	public String loadJSONFromAsset(String filename) {
	    String json = null;
	    try {
	    	
	    	String file = "res/raw/test.gpson";
	    	InputStream is = this.getClass().getClassLoader().getResourceAsStream(file);
//	        InputStream is = getAssets().open(filename);

	        int size = is.available();

	        byte[] buffer = new byte[size];

	        is.read(buffer);

	        is.close();

	        json = new String(buffer, "UTF-8");


	    } catch (IOException ex) {
	        ex.printStackTrace();
	        return null;
	    }
	    return json;

	}
}
