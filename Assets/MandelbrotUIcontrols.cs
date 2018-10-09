using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MandelbrotUIcontrols : MonoBehaviour {

    public Camera _camera;
    RaycastHit _hit;
    Ray _ray;
    Vector3 _mousePos, _smoothPoint;
    public Vector2 DragOffset;
    public float _smoothTime;
    bool virgin;
    float zoom = 0.3f;
    float maxIterations = 2000.0f;

    // Use this for initialization
    void Start () {

        virgin = true;
        Shader.SetGlobalVector("GLOBALmask_zoom", new Vector4(zoom, 0, 0, 0));
        Shader.SetGlobalVector("GLOBALmask_maxIterations", new Vector4(maxIterations, 0, 0, 0));
    }

    Vector3 hitPos(float initX, float initY, Camera c)
    {
        Vector3 mousePos = new Vector3(initX, initY, 0);    // Input.mousePosition.x, Input.mousePosition.y, 0);
        Ray ray = c.ScreenPointToRay(mousePos);             // _camera.ScreenPointToRay(mousePos);
        RaycastHit hit;
        Vector3 retPos = new Vector3(0f, 0f);

        if (Physics.Raycast(ray, out hit))
        {
            return hit.point;
        }
        return retPos;
    }

    // Update is called once per frame
    void Update () {

        if (Input.GetKey(KeyCode.Mouse0) || Input.GetKey(KeyCode.Mouse1) || virgin)
        {
            Vector2 goWorld2Screen = new Vector2(); goWorld2Screen = _camera.WorldToScreenPoint(gameObject.transform.position);
            Vector3 hitMouse = virgin ? hitPos(goWorld2Screen.x, goWorld2Screen.y, _camera) : hitPos(Input.mousePosition.x, Input.mousePosition.y, _camera);
            hitMouse.x += DragOffset.x;
            hitMouse.y += DragOffset.y;
            Debug.Log("hitMouse=" + hitMouse.x + "," + hitMouse.y+", virgin="+virgin);

            _smoothPoint = Vector3.MoveTowards(_smoothPoint, hitMouse, Vector3.Distance(hitMouse, _smoothPoint) * (Time.deltaTime / ((zoom/50) * Mathf.Max(0.01f, _smoothTime))));
            Shader.SetGlobalVector("GLOBALmask_xyOffset", new Vector4(_smoothPoint.x, _smoothPoint.y, _smoothPoint.z, 0));
            virgin = false;
// nasty test
//            _camera.orthographicSize = 0.00005f;
//            gameObject.transform.position = new Vector3(-1.401f, -0.74f, 6.0f);
        }

        if (Input.GetKey(KeyCode.DownArrow))
        {
            zoom *= 0.95f * (1+ (Time.deltaTime / (zoom* Mathf.Max(0.01f, _smoothTime*50))));
            Shader.SetGlobalVector("GLOBALmask_zoom", new Vector4(zoom, 0, 0, 0));
            Debug.Log("zoom=" + zoom);

        }
        if (Input.GetKey(KeyCode.UpArrow))
        {
            zoom *= 1.05f * (1+ (Time.deltaTime / (zoom* Mathf.Max(0.01f, _smoothTime*50))));
            Shader.SetGlobalVector("GLOBALmask_zoom", new Vector4(zoom, 0, 0, 0));
            Debug.Log("zoom=" + zoom);

        }

        if (Input.GetKey(KeyCode.Period))
        {
            maxIterations *= 0.95f * (1 + (Time.deltaTime / (maxIterations * Mathf.Max(0.01f, _smoothTime * 50))));
            Shader.SetGlobalVector("GLOBALmask_maxIterations", new Vector4(maxIterations, 0, 0, 0));
            Debug.Log("maxIterations=" + maxIterations);
        }
        if (Input.GetKey(KeyCode.Comma))
        {
            maxIterations *= 1.05f * (1 + (Time.deltaTime / (maxIterations * Mathf.Max(0.01f, _smoothTime * 50))));
            Shader.SetGlobalVector("GLOBALmask_maxIterations", new Vector4(maxIterations, 0, 0, 0));
            Debug.Log("maxIterations=" + maxIterations);
        }

        if (Input.GetKey(KeyCode.W))
        {
            Vector3 gop = gameObject.transform.position;
            gop.y -= Time.deltaTime / (zoom * Mathf.Max(0.01f, _smoothTime * 5));
            gameObject.transform.position = gop;
        }
        if (Input.GetKey(KeyCode.S))
        {
            Vector3 gop = gameObject.transform.position;
            gop.y += Time.deltaTime / (zoom * Mathf.Max(0.01f, _smoothTime * 5));
            gameObject.transform.position = gop;
        }
        if (Input.GetKey(KeyCode.A))
        {
            Vector3 gop = gameObject.transform.position;
            gop.x += Time.deltaTime / (zoom * Mathf.Max(0.01f, _smoothTime * 5));
            gameObject.transform.position = gop;
        }
        if (Input.GetKey(KeyCode.D))
        {
            Vector3 gop = gameObject.transform.position;
            gop.x -= Time.deltaTime / (zoom * Mathf.Max(0.01f, _smoothTime * 5));
            gameObject.transform.position = gop;
        }
        if (Input.GetKey(KeyCode.LeftArrow))
        {
            float fov = _camera.orthographicSize;
                //Camera.main.fieldOfView;
            fov *= 1 + Time.deltaTime / (zoom * Mathf.Max(0.01f, _smoothTime * 1));
            _camera.orthographicSize = fov;
        }
        if (Input.GetKey(KeyCode.RightArrow))
        {
            float fov = _camera.orthographicSize;
            fov *= 1 - Time.deltaTime / (zoom * Mathf.Max(0.01f, _smoothTime * 1));
            _camera.orthographicSize = fov;
        }
    }

}
