using UnityEngine;

public class Spinner : MonoBehaviour {
    public Vector3 spin = Vector3.zero;
    public bool localRotate = false;

	// Update is called once per frame
	void FixedUpdate () {
        transform.Rotate(spin, localRotate ? Space.Self : Space.World);
    }
}

