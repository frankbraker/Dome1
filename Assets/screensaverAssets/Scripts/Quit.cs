using UnityEngine;
using System.Collections;

public class Quit : MonoBehaviour {

	[System.Serializable]
	public class allowedQuitConditions
	{
		public bool	onEscape;
		public bool onMouseAny;
		public bool	onSpecificButton;
	}

	public	allowedQuitConditions	conditions;

	// Update is called once per frame
	void Update () {

		if (Input.GetKey("escape") && conditions.onEscape )
			Application.Quit();

		if (Input.GetMouseButtonDown(0) && conditions.onMouseAny )
			Application.Quit();

		if (Input.GetMouseButtonDown(1) && conditions.onMouseAny )
			Application.Quit();

		if (Input.GetMouseButtonDown(2) && conditions.onMouseAny )
			Application.Quit();

	}

	public void doQuitNow() {

		Application.Quit();
		Debug.Log("doQuitNow");

	}

}
