using UnityEngine;
using System.Collections;

public class Rotation : MonoBehaviour {

	public Vector3 base_worldSpaceRotateRates;
	public Vector3 base_localSpaceRotateRates;

	public float	base_worldMultiplier;
	public float	base_localMultiplier;

	private Vector3 worldSpaceRotateRates;
	private Vector3 localSpaceRotateRates;


	// Use this for initialization
	void Start () {

		worldSpaceRotateRates	=	new Vector3 ( base_worldSpaceRotateRates.x, base_worldSpaceRotateRates.y, base_worldSpaceRotateRates.z );

		localSpaceRotateRates	=	new Vector3 ( base_localSpaceRotateRates.x, base_localSpaceRotateRates.y, base_localSpaceRotateRates.z );
		
	}
	
	// Update is called once per frame
	void Update () {

		transform.Rotate( worldSpaceRotateRates, Time.deltaTime * base_worldMultiplier );

		transform.Rotate( localSpaceRotateRates, Time.deltaTime + base_localMultiplier );
	}

	public void set_worldSpaceRotateRate( Vector3 setter )
	{
		worldSpaceRotateRates	=	setter;
	}
	
	public void add_worldSpaceRotateRate( Vector3 adder )
	{
		worldSpaceRotateRates	+=	adder;
	}

	public void mult_worldSpaceRotateRate( float multiplier )
	{
		worldSpaceRotateRates	*=	multiplier;
	}
	
	public void mult_worldSpaceRotateRate( Vector3 multiplier )
	{
		Vector3	targetV3	=	new Vector3 ( worldSpaceRotateRates.x * multiplier.x, worldSpaceRotateRates.y * multiplier.y, worldSpaceRotateRates.z * multiplier.z );
		worldSpaceRotateRates	=	targetV3;
	}


	public void set_localSpaceRotateRate( Vector3 setter )
	{
		localSpaceRotateRates	=	setter;
	}
	
	public void add_localSpaceRotateRate( Vector3 adder )
	{
		localSpaceRotateRates	+=	adder;
	}
	
	public void mult_localSpaceRotateRate( float multiplier )
	{
		localSpaceRotateRates	*=	multiplier;
	}
	
	public void mult_localSpaceRotateRate( Vector3 multiplier )
	{
		Vector3	targetV3	=	new Vector3 ( localSpaceRotateRates.x * multiplier.x, localSpaceRotateRates.y * multiplier.y, localSpaceRotateRates.z * multiplier.z );
		localSpaceRotateRates	=	targetV3;
	}
}
