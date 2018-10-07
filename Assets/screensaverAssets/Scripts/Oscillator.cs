using UnityEngine;
using System.Collections;

public class Oscillator : MonoBehaviour {

	public Vector3	v3ValueMax;
	public Vector3	v3ValueMin;
	public Vector3	v3ValuePhase_0to1;

	public string[] v3TargetFunction;

	private Vector3 v3InitialPhase;
	private	Vector3	v3CurrentRate;

	
	public float	fValueMax;
	public float	fValueMin;
	public float	fValuePhase_0to1;

	public string[] fTargetFunction;

	private float	fInitialPhase;
	private float	fCurrentRate;

	private float	startTime;


	public float	rateInHz;
	public float	resolutionInSamplesPerSecond;

	Vector3	v3Lerp ( Vector3 from, Vector3 to, Vector3 delta )	{
		float	x	=	Mathf.Lerp ( from.x, to.x, delta.x );
		float	y	=	Mathf.Lerp ( from.y, to.y, delta.y );
		float	z	=	Mathf.Lerp ( from.z, to.z, delta.z );
		return new Vector3 ( x, y, z );
	}


	
	void Start ()	{

		fInitialPhase	=	Mathf.Lerp ( fValueMin, fValueMax, fValuePhase_0to1 );

		fCurrentRate	=	fInitialPhase;

		v3InitialPhase	=	v3Lerp( v3ValueMin, v3ValueMax, v3ValuePhase_0to1 );

		v3CurrentRate	=	v3InitialPhase;

		startTime		=	Time.time;
	}

	// Update is called once per frame
	void Update () {

	}
}
