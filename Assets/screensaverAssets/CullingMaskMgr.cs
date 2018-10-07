using UnityEngine;
using System.Collections;

public class CullingMaskMgr : MonoBehaviour {

	const int	defaultMask		=	1;


	public Camera	cam;

	public int	mask;

	public void Start	()	{
		mask	=	cam.cullingMask;
	}


	public void ToggleDefault()	{
		int		flip		=	mask	&	defaultMask;
		flip				=	~flip;
		flip				=	flip	&	defaultMask;

		mask				=	mask	&	~defaultMask;
		mask				|=	flip;

		cam.cullingMask	=	mask;
	}

}
