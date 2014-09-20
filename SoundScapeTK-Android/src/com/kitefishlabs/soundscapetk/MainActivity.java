package com.kitefishlabs.soundscapetk;

import java.util.Locale;

import android.app.Activity;
import android.app.Dialog;
import android.content.Context;
import android.content.Intent;
import android.content.IntentSender;
import android.content.SharedPreferences;
import android.content.SharedPreferences.Editor;
import android.location.Location;
import android.os.Bundle;
import android.support.v4.app.DialogFragment;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentManager;
import android.support.v4.app.FragmentPagerAdapter;
import android.support.v4.app.FragmentTransaction;
import android.support.v4.view.ViewPager;
import android.support.v7.app.ActionBar;
import android.support.v7.app.ActionBarActivity;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.CompoundButton;
import android.widget.TextView;
import android.widget.Toast;
import android.widget.ToggleButton;

import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GooglePlayServicesClient;
import com.google.android.gms.common.GooglePlayServicesUtil;
import com.google.android.gms.location.LocationClient;
import com.google.android.gms.location.LocationListener;
import com.google.android.gms.location.LocationRequest;
import com.google.android.gms.maps.CameraUpdate;
import com.google.android.gms.maps.CameraUpdateFactory;
import com.google.android.gms.maps.GoogleMap;
import com.google.android.gms.maps.MapView;
import com.google.android.gms.maps.MapsInitializer;
import com.google.android.gms.maps.model.LatLng;

public class MainActivity extends ActionBarActivity implements
		ActionBar.TabListener,
		GooglePlayServicesClient.ConnectionCallbacks,
		GooglePlayServicesClient.OnConnectionFailedListener,
		LocationListener {
	// Global constants
	private final static int CONNECTION_FAILURE_RESOLUTION_REQUEST = 9000;
    // Milliseconds per second
    private static final int MILLISECONDS_PER_SECOND = 1000;
    // Update frequency in seconds
    public static final int UPDATE_INTERVAL_IN_SECONDS = 5;
    // Update frequency in milliseconds
    private static final long UPDATE_INTERVAL =
            MILLISECONDS_PER_SECOND * UPDATE_INTERVAL_IN_SECONDS;
    // The fastest update frequency, in seconds
    private static final int FASTEST_INTERVAL_IN_SECONDS = 1;
    // A fast frequency ceiling in milliseconds
    private static final long FASTEST_INTERVAL =
            MILLISECONDS_PER_SECOND * FASTEST_INTERVAL_IN_SECONDS;

	

	/**
	 * The {@link android.support.v4.view.PagerAdapter} that will provide
	 * fragments for each of the sections. We use a {@link FragmentPagerAdapter}
	 * derivative, which will keep every loaded fragment in memory. If this
	 * becomes too memory intensive, it may be best to switch to a
	 * {@link android.support.v4.app.FragmentStatePagerAdapter}.
	 */
	SectionsPagerAdapter mSectionsPagerAdapter;

	/**
	 * The {@link ViewPager} that will host the section contents.
	 */
	ViewPager mViewPager;
	ScapeManager scapeManager;
	LocationRequest mLocationRequest;
	LocationClient mLocationClient;
    boolean mUpdatesRequested;

    SharedPreferences mPrefs;
    Editor mEditor;
    
//    ToggleButton onoffTgl;

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(com.kitefishlabs.soundscapetk.R.layout.activity_main);

		// Set up the action bar.
		final ActionBar actionBar = getSupportActionBar();
		actionBar.setNavigationMode(ActionBar.NAVIGATION_MODE_TABS);

		// Create the adapter that will return a fragment for each of the three
		// primary sections of the activity.
		mSectionsPagerAdapter = new SectionsPagerAdapter(
				getSupportFragmentManager());

		// Set up the ViewPager with the sections adapter.
		mViewPager = (ViewPager) findViewById(com.kitefishlabs.soundscapetk.R.id.pager);
		mViewPager.setAdapter(mSectionsPagerAdapter);

		// When swiping between different sections, select the corresponding
		// tab. We can also use ActionBar.Tab#select() to do this if we have
		// a reference to the Tab.
		mViewPager
				.setOnPageChangeListener(new ViewPager.SimpleOnPageChangeListener() {
					@Override
					public void onPageSelected(int position) {
						actionBar.setSelectedNavigationItem(position);
					}
				});

		// For each of the sections in the app, add a tab to the action bar.
		for (int i = 0; i < mSectionsPagerAdapter.getCount(); i++) {
			// Create a tab with text corresponding to the page title defined by
			// the adapter. Also specify this Activity object, which implements
			// the TabListener interface, as the callback (listener) for when
			// this tab is selected.
			actionBar.addTab(actionBar.newTab()
					.setText(mSectionsPagerAdapter.getPageTitle(i))
					.setTabListener(this));
		}
		scapeManager = new ScapeManager("res/raw/test.gpson");
		
		// Open the shared preferences
		mPrefs = getSharedPreferences("SharedPreferences",
                Context.MODE_PRIVATE);
        // Get a SharedPreferences editor
        mEditor = mPrefs.edit();

		mLocationRequest = LocationRequest.create();
        // Use high accuracy
        mLocationRequest.setPriority(
                LocationRequest.PRIORITY_HIGH_ACCURACY);
        // Set the update interval to 5 seconds
        mLocationRequest.setInterval(UPDATE_INTERVAL);
        // Set the fastest update interval to 1 second
        mLocationRequest.setFastestInterval(FASTEST_INTERVAL);

        mLocationClient = new LocationClient(this, this, this);
        // Start with updates turned off
        mUpdatesRequested = false;

//        ToggleButton onoffTgl = (ToggleButton) findViewById(com.kitefishlabs.soundscapetk.R.id.btn_start);
//        
//        Log.v("tgl: ", onoffTgl.toString());
//        
//        onoffTgl.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
//            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
//                if (isChecked) {
//                    // The toggle is enabled
//                	mUpdatesRequested = true;
//                	mEditor.putBoolean("KEY_UPDATES_ON", true);
//                	mEditor.commit();
//                } else {
//                    // The toggle is disabled
//                	mUpdatesRequested = false;
//                  	mEditor.putBoolean("KEY_UPDATES_ON", false);
//                  	mEditor.commit();
//                }
//            }
//        });
	}
	
	

	@Override
    protected void onStart() {
        mLocationClient.connect();
        Log.v("ONCONNECT: ", "connect()!");
//        mUpdatesRequested = true;
//        mEditor.putBoolean("KEY_UPDATES_ON", true);
//        mEditor.commit();
        super.onStart();
    }
    
	@Override
    protected void onPause() {
        // Save the current setting for updates
        Log.v("ONPAUSE: ", "onPause()!");
        mEditor.putBoolean("KEY_UPDATES_ON", mUpdatesRequested);
        mEditor.commit();
        super.onPause();
    }
    
    @Override
    protected void onResume() {
        /*
         * Get any previous setting for location updates
         * Gets "false" if an error occurs
         */
        Log.v("ONRESUME: ", "onResume()!");
        if (mPrefs.contains("KEY_UPDATES_ON")) {
            mUpdatesRequested =
                    mPrefs.getBoolean("KEY_UPDATES_ON", false);
        Log.v("updates requested?: ", String.valueOf(mUpdatesRequested));

        // Otherwise, turn off location updates
        } else {
            mEditor.putBoolean("KEY_UPDATES_ON", false);
            mEditor.commit();
        }
        super.onResume();
    }
    
    /*
     * Called when the Activity is no longer visible at all.
     * Stop updates and disconnect.
     */
    @Override
    protected void onStop() {
        // If the client is connected
        Log.v("ONSTOP: ", "onStop()!");
        if (mLocationClient.isConnected()) {
            /*
             * Remove location updates for a listener.
             * The current Activity is the listener, so
             * the argument is "this".
             */
//            removeLocationUpdates(this);
        }
        /*
         * After disconnect() is called, the client is
         * considered "dead".
         */
        mLocationClient.disconnect();
        super.onStop();
    }

	
	@Override
	public boolean onCreateOptionsMenu(Menu menu) {

		// Inflate the menu; this adds items to the action bar if it is present.
		getMenuInflater().inflate(com.kitefishlabs.soundscapetk.R.menu.main, menu);
		return true;
	}

	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		// Handle action bar item clicks here. The action bar will
		// automatically handle clicks on the Home/Up button, so long
		// as you specify a parent activity in AndroidManifest.xml.
		int id = item.getItemId();
		if (id == com.kitefishlabs.soundscapetk.R.id.action_settings) {
			return true;
		}
		return super.onOptionsItemSelected(item);
	}

	@Override
	public void onTabSelected(ActionBar.Tab tab,
			FragmentTransaction fragmentTransaction) {
		// When the given tab is selected, switch to the corresponding page in
		// the ViewPager.
		Log.v("SELECTED...", "selected");
		mViewPager.setCurrentItem(tab.getPosition());
	}

	@Override
	public void onTabUnselected(ActionBar.Tab tab,
			FragmentTransaction fragmentTransaction) {
	}

	@Override
	public void onTabReselected(ActionBar.Tab tab,
			FragmentTransaction fragmentTransaction) {
		Log.v("reselected...", "reselected");
	}

	/**
	 * A {@link FragmentPagerAdapter} that returns a fragment corresponding to
	 * one of the sections/tabs/pages.
	 */
	public class SectionsPagerAdapter extends FragmentPagerAdapter {

		public SectionsPagerAdapter(FragmentManager fm) {
			super(fm);
		}

		@Override
		public Fragment getItem(int position) {
			// getItem is called to instantiate the fragment for the given page.
			// Return a PlaceholderFragment (defined as a static inner class
			// below).
			Fragment frag;
			switch (position) {
			case 1: frag = StatusFragment.newInstance(2);
					break;
			case 2: frag = MapFragment.newInstance(3);
					break;
			default: frag = MainFragment.newInstance(1);
					break;
			}
			return frag;
		}

		@Override
		public int getCount() {
			// Show 3 total pages.
			return 3;
		}

		@Override
		public CharSequence getPageTitle(int position) {
			Locale l = Locale.getDefault();
			switch (position) {
			case 0:
				return getString(com.kitefishlabs.soundscapetk.R.string.title_main).toUpperCase(l);
			case 1:
				return getString(com.kitefishlabs.soundscapetk.R.string.title_status).toUpperCase(l);
			case 2:
				return getString(com.kitefishlabs.soundscapetk.R.string.title_map).toUpperCase(l);
			}
			return null;
		}
	}

	/**
	 * A placeholder fragment containing a simple view.
	 */
	public static class MainFragment extends Fragment {
		
		/**
		 * The fragment argument representing the section number for this
		 * fragment.
		 */
		private static final String ARG_SECTION_NUMBER = "section_number";

		/**
		 * Returns a new instance of this fragment for the given section number.
		 */
		public static MainFragment newInstance(int sectionNumber) {
			MainFragment fragment = new MainFragment();
			Bundle args = new Bundle();
			args.putInt(ARG_SECTION_NUMBER, sectionNumber);
			fragment.setArguments(args);
			return fragment;
		}

		public MainFragment() {
		}

		@Override
		public View onCreateView(LayoutInflater inflater, ViewGroup container,
				Bundle savedInstanceState) {
			View rootView = inflater.inflate(com.kitefishlabs.soundscapetk.R.layout.fragment_main, container,
					false);
			// 
			return rootView;
		}
		
//        mUpdatesRequested = true;
//        mEditor.putBoolean("KEY_UPDATES_ON", true);
//        mEditor.commit();

	}
	
	public static class StatusFragment extends Fragment {
		/**
		 * The fragment argument representing the section number for this
		 * fragment.
		 */
		private static final String ARG_SECTION_NUMBER = "section_number";

		/**
		 * Returns a new instance of this fragment for the given section number.
		 */
		public static StatusFragment newInstance(int sectionNumber) {
			StatusFragment fragment = new StatusFragment();
			Bundle args = new Bundle();
			args.putInt(ARG_SECTION_NUMBER, sectionNumber);
			fragment.setArguments(args);
			return fragment;
		}

		public StatusFragment() {
		}

		@Override
		public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
			View rootView = inflater.inflate(com.kitefishlabs.soundscapetk.R.layout.fragment_status, container, false);
			// 
			return rootView;
		}
		public void updateLatLonReadings(double newLat, double newLon) {
			TextView latview = (TextView) getView().findViewById(com.kitefishlabs.soundscapetk.R.id.loc_lat_label);
			latview.setText(String.valueOf(newLat));
			TextView lonview = (TextView) getView().findViewById(com.kitefishlabs.soundscapetk.R.id.loc_lon_label);
			lonview.setText(String.valueOf(newLon));
		}
	}
	
	
	public static class MapFragment extends Fragment {
		MapView mapView;
		GoogleMap map;
		
		private static final String ARG_SECTION_NUMBER = "section_number";

		/**
		 * Returns a new instance of this fragment for the given section number.
		 */
		public static MapFragment newInstance(int sectionNumber) {
			MapFragment fragment = new MapFragment();
			Bundle args = new Bundle();
			args.putInt(ARG_SECTION_NUMBER, sectionNumber);
			fragment.setArguments(args);
			return fragment;
		}

		public MapFragment() {
		}
		
		@Override
		public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
			View rootView = inflater.inflate(com.kitefishlabs.soundscapetk.R.layout.fragment_map, container, false);
			// Gets the MapView from the XML layout and creates it

//			try {
			    MapsInitializer.initialize(getActivity());
//			} catch (GooglePlayServicesNotAvailableException e) {
//			    Log.e("Address Map", "Could not initialize google play", e);
//			}

			switch (GooglePlayServicesUtil.isGooglePlayServicesAvailable(getActivity()) ) {
				case ConnectionResult.SUCCESS:
					Toast.makeText(getActivity(), "SUCCESS", Toast.LENGTH_SHORT).show();
					mapView = (MapView) rootView.findViewById(com.kitefishlabs.soundscapetk.R.id.map);
					mapView.onCreate(savedInstanceState);
					// Gets to GoogleMap from the MapView and does initialization stuff
					if(mapView!=null) {
						map = mapView.getMap();
						map.getUiSettings().setMyLocationButtonEnabled(false);
						map.setMyLocationEnabled(true);
						CameraUpdate cameraUpdate = CameraUpdateFactory.newLatLngZoom(new LatLng(42.72887,-73.683522), 17);
						map.animateCamera(cameraUpdate);
					}
					break;
					case ConnectionResult.SERVICE_MISSING: 
						Toast.makeText(getActivity(), "SERVICE MISSING", Toast.LENGTH_SHORT).show();
						break;
					case ConnectionResult.SERVICE_VERSION_UPDATE_REQUIRED: 
						Toast.makeText(getActivity(), "UPDATE REQUIRED", Toast.LENGTH_SHORT).show();
						break;
					default: Toast.makeText(getActivity(), GooglePlayServicesUtil.isGooglePlayServicesAvailable(getActivity()), Toast.LENGTH_SHORT).show();
					}

			// Updates the location and zoom of the MapView

			return rootView;
		}

		@Override
		public void onResume() {
			mapView.onResume();
			super.onResume();
		}
		@Override
		public void onDestroy() {
			super.onDestroy();
			mapView.onDestroy();
		}
		@Override
		public void onLowMemory() {
			super.onLowMemory();
			mapView.onLowMemory();
		}
	}



	/**
	 * Location setup
	 */

	// Define a DialogFragment that displays the error dialog
    public static class ErrorDialogFragment extends DialogFragment {
        // Global field to contain the error dialog
        private Dialog mDialog;
        // Default constructor. Sets the dialog field to null
        public ErrorDialogFragment() {
            super();
            mDialog = null;
        }
        // Set the dialog to display
        public void setDialog(Dialog dialog) {
            mDialog = dialog;
        }
        // Return a Dialog to the DialogFragment.
        @Override
        public Dialog onCreateDialog(Bundle savedInstanceState) {
            return mDialog;
        }
    }
    
    /*
     * Handle results returned to the FragmentActivity
     * by Google Play services
     */
    @Override
    protected void onActivityResult(
            int requestCode, int resultCode, Intent data) {
        // Decide what to do based on the original request code
        Log.v("result code: ", String.valueOf(resultCode));
    	switch (requestCode) {
            
            case CONNECTION_FAILURE_RESOLUTION_REQUEST :
            /*
             * If the result code is Activity.RESULT_OK, try
             * to connect again
             */
            	switch (resultCode) {
                    case Activity.RESULT_OK :
                    /*
                     * Try the request again
                     */
                    break;
                }
        }
    }

    private boolean servicesConnected() {
        // Check that Google Play services is available
    	int errorCode = GooglePlayServicesUtil.isGooglePlayServicesAvailable(this);
    	if (errorCode != ConnectionResult.SUCCESS) {
    	  GooglePlayServicesUtil.getErrorDialog(errorCode, this, 0).show();
    	  return false;
    	} else {
            // In debug mode, log the status
            Log.d("Location Updates",
                    "Google Play services is available.");
            return true;
        }
    }



    /*
     * Called by Location Services when the request to connect the
     * client finishes successfully. At this point, you can
     * request the current location or start periodic updates
     */
    @Override
    public void onConnected(Bundle dataBundle) {
    	// Display the connection status
    	Toast.makeText(this, "Connected", Toast.LENGTH_SHORT).show();
    	// If already requested, start periodic updates
        if (mUpdatesRequested) {
            mLocationClient.requestLocationUpdates(mLocationRequest, this);
        }
    }

    /*
     * Called by Location Services if the connection to the
     * location client drops because of an error.
     */
    @Override
    public void onDisconnected() {
    	// Display the connection status
    	Toast.makeText(this, "Disconnected. Please re-connect.",
    			Toast.LENGTH_SHORT).show();
    }

    /*
     * Called by Location Services if the attempt to
     * Location Services fails.
     */
    @Override
    public void onConnectionFailed(ConnectionResult connectionResult) {
    	/*
    	 * Google Play services can resolve some errors it detects.
    	 * If the error has a resolution, try sending an Intent to
    	 * start a Google Play services activity that can resolve
    	 * error.
    	 */
    	if (connectionResult.hasResolution()) {
    		try {
    			// Start an Activity that tries to resolve the error
    			connectionResult.startResolutionForResult(
    					this,
    					CONNECTION_FAILURE_RESOLUTION_REQUEST);
    			/*
    			 * Thrown if Google Play services canceled the original
    			 * PendingIntent
    			 */
    		} catch (IntentSender.SendIntentException e) {
    			// Log the error
    			e.printStackTrace();
    		}
    	} else {
    /*
     * If no resolution is available, display a dialog to the
     * user with the error.
     */
    		Log.v("onConnectionFailed error code:", String.valueOf(connectionResult.getErrorCode()));
//    		showErrorDialog(connectionResult.getErrorCode());
		}
	}
    
    @Override
    public void onLocationChanged(Location location) {
        // Report to the UI that the location was updated
    	Double lat = location.getLatitude();
    	Double lon = location.getLongitude();
    	float acc = location.getAccuracy();
        String msg = "Updated Location: " +
                String.valueOf(lat) + ", " +
                String.valueOf(lon) + " (acc=" + String.valueOf(acc) + ")";
        Log.v("last loc: ", msg);
        //Toast.makeText(this, msg, Toast.LENGTH_SHORT).show();
        
        if((lat != null) && (lon != null)) {
        	
        	TextView latTV = (TextView) findViewById(com.kitefishlabs.soundscapetk.R.id.loc_lat);
        	TextView lonTV = (TextView) findViewById(com.kitefishlabs.soundscapetk.R.id.loc_lon);
        	latTV.setText(String.valueOf(lat));
        	lonTV.setText(String.valueOf(lon));
        }
    }
}
