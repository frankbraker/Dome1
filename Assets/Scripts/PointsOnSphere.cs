
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class PointsOnSphere : MonoBehaviour
{
    public int pointCount = 16;
    public float scaling = 32;
    public float speed = 7f;
    public Vector3[] pts;
    public Transform tile;
    public string[] names = {
        "Rheiformes","Tinamiformes","Anseriformes","Galliformes","Gaviiformes","Podicipediformes","Phoenicopteriformes","Sphenisciformes","Procellariiformes","Phaethontiformes","Ciconiiformes","Suliformes","Pelecaniformes","Cathartiformes","Accipitriformes","Eurypygiformes","Gruiformes","Charadriiformes","Columbiformes","Opisthocomiformes","Cuculiformes","Strigiformes","Caprimulgiformes","Trogoniformes","Coraciiformes","Galbuliformes","Piciformes","Cariamiformes","Falconiformes","Psittaciformes","Passeriformes"
    };
    public Texture2D[] images;

    void Start ()
	{
		pts = doPointsOnSphere( pointCount );
		List<GameObject> uspheres = new List<GameObject>();
		int i = 0;

		foreach (Vector3 value in pts)
		{
            //uspheres.Add(GameObject.CreatePrimitive(PrimitiveType.Sphere));
            GameObject x = Instantiate(tile, new Vector3(transform.position.x, transform.position.y, transform.position.z), Quaternion.identity).gameObject;
            uspheres.Add( x );
            uspheres[i].transform.parent = transform;
            uspheres[i].transform.position = value * scaling;
            uspheres[i].transform.position += transform.position;
            uspheres[i].transform.name = names[i];// i.ToString();
            uspheres[i].transform.Rotate(new Vector3(-90, 0));
            //uspheres[i].transform.Find("Order").gameObject.GetComponent<TextMesh>().text = names[i]; // i.ToString();

            // set image
            Material material = new Material(Shader.Find("Diffuse"));
            material.mainTexture = images[i];
            uspheres[i].transform.gameObject.GetComponent<Renderer>().material = material;
            i++;
		}
	}

	Vector3[] doPointsOnSphere(int n)
	{
		List<Vector3> upts = new List<Vector3>();
		float inc = Mathf.PI * (3 - Mathf.Sqrt(5));
		float off = 2.0f / n;
		float x = 0;
		float y = 0;
		float z = 0;
		float r = 0;
		float phi = 0;

		for (var k = 0; k < n; k++){
			y = k * off - 1 + (off /2);
			r = Mathf.Sqrt(1 - y * y);
			phi = k * inc;

			x = Mathf.Cos(phi) * r;
			z = (Mathf.Sin(phi) * r );

			upts.Add(new Vector3(x, y, z));
		}
		Vector3[] pts = upts.ToArray();
		return pts;
	}

    void Update()
    {
        //if ((Time.time % 20) < 16)
        //{
            transform.parent.Rotate(Vector3.up, speed * Time.deltaTime);
        //}
        //else {
        //    transform.Rotate(Vector3.left, speed * Time.deltaTime);
        //}
    }

}
