using UnityEngine;
using System.Collections;

public class DuplicateMe : MonoBehaviour {

	public GameObject	whatToDuplicate             ;
	public int	        howmany							=	1;
	public Vector3  	RotateOffset				;
	public Vector3  	PositionOffset              ;

	// Use this for initialization
	void Start () {

		if ( whatToDuplicate != null )
		{
            Vector3 rSource = new Vector3(whatToDuplicate.transform.rotation.x, whatToDuplicate.transform.rotation.y, whatToDuplicate.transform.rotation.z);

            for ( int i=1; i<howmany; i++ )	{   // i=1 to skip whatToDuplicate's instance

				Vector3 rOff	=	new Vector3( RotateOffset.x*i, RotateOffset.y*i, RotateOffset.z*i );

                Quaternion qR	=	Quaternion.Euler( rOff.x+rSource.x, rOff.y+rSource.y, rOff.z+rSource.z );
				Vector3 pOff	=	new Vector3( PositionOffset.x*i, PositionOffset.y*i, PositionOffset.z*i );

                GameObject child =  Object.Instantiate<GameObject>(whatToDuplicate, pOff, qR); // ( whatToDuplicate, pOff, qR ) as GameObject;
				child.transform.parent	=	gameObject.transform;

			}

		}
	
	}
	
}
