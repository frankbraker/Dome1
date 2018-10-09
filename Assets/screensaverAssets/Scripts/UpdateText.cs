using UnityEngine;
using System.Collections;
using UnityEngine.UI;

public class UpdateText : MonoBehaviour {

	public string update;

	//public GameObject thing;

	public void doUpdateText()
	{
		Text	ts	=	gameObject.GetComponent<Text>();

		if ( ts != null )	{

			ts.text		=	ts.text+'\n'+update;
		}

	}

	public void setUpdateText( string s )
	{
		update	=	s;
	}

}
