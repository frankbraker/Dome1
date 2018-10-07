// Upgrade NOTE: replaced 'samplerRECT' with 'sampler2D'

/**
 * extPrecision.cg -- a set of Cg routines for doing extended precision
 *   floating point operations using double-floats stored in float2 variables 
 *   (for real) or float4 (for complex), each with 32-bit (24-bit mantissa)
 *   to give ~48 bits with the single-precision float exponent
 *
 * A. Thall
 * Dec. 6, 2004
 * 
 * This code copyright 2004, 2006, 2010  Andrew Thall
 * 
 * This code is offered as is for experimental and research purposes.  Its correctness
 *   is highly dependent on the nuances of the floating point behavior on any particular
 *   graphics card.  To understand the issues involved, see the Hida paper on extended
 *   precision for CPU code.  This author (Thall) makes no guarantees that any of this
 *   code will work as advertised.  Feel free to swipe from this code, but if you copy
 *   verbatim, I'd appreciate you crediting me with my work and would appreciate also
 *   hearing about your application!
 *
 * Many of these routines are based on similar routines in the QD library of Hida et al.,
 *   themselves derived from the doubledouble library of Briggs.  The author would also
 *   like to express thanks to Dr. David Bremer (LLNL) and Dr. Jeremy Meredith (ORNL)
 *   for discussions of their experiments in extended precision on GPUs.
 * The author of the current code asserts no ownership of algorithms presented herein,
 *   and has tried to cite attributions where appropropriate.
 * See the Hida papers on the QD library for more information on extended precision in general.
 * External documentation and information on extended precision for GPUs is available as
 *    a technical report http://andrewthall.org/papers/df64_qf128.pdf .
 *
 * If you're interested in extended precision for modern GPUs (2010) under CUDA and such,
 *    you should look at a more modern treatment such as "Supporting Extended Precision on
 *    Graphics Processors" by M. Lu, 2010.  This discusses double-doubles and quad-doubles
 *    implemented using CUDA, which has much better IEEE compliance and programmability,
 *    compared to my poor double-floats in Cg.
 */

float ZERO = 0.0f;
float ONE = 1.0f;

uniform float4 E_INV;
uniform float4 PI_INV;
uniform float4 LOG2_INV;
uniform float4 LOG10_INV;
uniform float4 PI_2_PI_4;
uniform float4 PI_8_PI_16;
uniform float4 SC_PI_16;
uniform float4 SC_2PI_16;
uniform float4 SC_3PI_16;
uniform float4 SC_4PI_16;
uniform float2 ZEROONE;	

/**
 * These (for the time being) need to initialized externally.
 * The .xy will store the value, the .zw, the inverse.
 */
struct CONSTANTS {
	float2 E;
	float2 INV_E;
	float2 PI;
	float2 INV_PI;
	float2 LOG2;
	float2 INV_LOG2;
	float2 LOG10;
	float2 INV_LOG10;
	float2 PI_2, PI_4, PI_8, PI_16;
	float4 SINCOS_PI_16, SINCOS_2PI_16, SINCOS_3PI_16, SINCOS_4PI_16;
};

CONSTANTS df64M;

/**
 * the following splits a 24-bit IEEE floating point mantissa+E
 * into two numbers hi and low such that a = hi + low.  hi
 * will contain the first 12 bits, and low will contain the lower
 * order 12 bits.
 */
float2 split(float a) {

	const float split = 4097; // (1 << 12) + 1;	
	float t = a*split;
	float a_hi = t - (t - a);
	float a_lo = a - a_hi;
	
	return float2(a_hi, a_lo);
}

/**
 * simulateously split the real and imaginary component
 * of a pair of floats into two
 */
float4 splitComp(float2 c) {

	const float split = 4097; // (1 << 12) + 1;
	float2 t = c*split;	
	float2 c_hi = t - (t - c);
	float2 c_lo = c - c_hi;
	return float4(c_hi.x, c_lo.x, c_hi.y, c_lo.y);
}

float2 quickTwoSum(float a, float b) {
	float s = a + b;
	float e = b - (s - a);
	return float2(s, e);
}

/**
 * does a quick sum of the high-order real and imaginary
 * components of a_ri and b_ri
 */
float4 quickTwoSumComp(float2 a_ri, float2 b_ri) {

	float2 s = a_ri + b_ri;
	float2 e = b_ri - (s - a_ri);
	return float4(s.x, e.x, s.y, e.y);
}

float2 twoSum(float a, float b) {
	float s = a + b;
	float v = s - a;
	float e = (a - (s - v)) + (b - v);
	return float2(s, e);
}

float4 twoSumComp(float2 a_ri, float2 b_ri) {

	float2 s = a_ri + b_ri;
	float2 v = s - a_ri;
	// xxAT Should be a ONE* here on s?
	float2 e = (a_ri - (s - v)) + (b_ri - v);
	return float4(s.x, e.x, s.y, e.y);
}

float2 twoDiff(float a, float b) {
    float s = a - b;
    float v = s - a;
    float err = (a - (s - v)) - (b + v);
    return float2(s, err);
}

float4 twoDiffComp(float2 a_ri, float2 b_ri) {

	float2 s = a_ri - b_ri;
	float2 v = s - a_ri;
	float2 err = (a_ri - (s - v)) - (b_ri + v);
	return float4(s.x, err.x, s.y, err.y);
}

float2 twoProd(float a, float b) {
	float p = a*b;
	float2 aS = split(a);
	float2 bS = split(b);
	float err = ((aS.x*bS.x - p) + aS.x*bS.y + aS.y*bS.x) + aS.y*bS.y;
	return float2(p, err);
}

/**
 * faster twoProd that uses single call of split to complex version
 *   (which should run same speed as simple
 */
float2 twoProdFAST(float2 ab) {

	float p = ab.x*ab.y;
	float4 S = splitComp(ab);
	float err = ((S.x*S.z - p) + S.x*S.w + S.y*S.z) + S.y*S.w;
	return float2(p, err);
}

/* Computes fl(a*a) and err(a*a).  Faster than the above method. */
float2 twoSqr(float a) {
  float p = a*a;
  float2 hilo = split(a);
  float err = ((hilo.x*hilo.x - p) + 2.0*hilo.x*hilo.y) + hilo.y*hilo.y;
  return float2(p, err);
}

/**
 * Computes fl(ar*ar), err(ar, ar), and fl(ai, ai) and err(ai*ai) for each component
 *    of a complex float (ar, ai)
 */
float4 twoSqrComp(float2 a_ri) {
	float2 q = a_ri*a_ri;
	float4 hilo = splitComp(a_ri);
	float2 err = ((hilo.xz*hilo.xz - q) + 2.0*hilo.xz*hilo.yw) + hilo.yw*hilo.yw; 
	return float4(q.x, err.x, q.y, err.y);
}
 
/* double-float * double-float */
float2 df64_mult(float2 a, float2 b) {
    float2 p;

	p = twoProd(a.x, b.x);
	p.y += a.x * b.y;
	p.y += a.y * b.x;
	p = quickTwoSum(p.x, p.y);
	return p;
	/*
// Faster twoProd()
	p = twoProdFAST(float2(a.x, b.x));
	p.y += dot(a, b.yx);	
    p = quickTwoSum(p.x, p.y);
    return p;
    */
}

/* double-float * float */
float2 df64_mult(float2 a, float b) {
  
	float2 p;

	p = twoProd(a.x, b);
//	p = twoProdFAST(float2(a.x, b));
	p.y += (a.y * b);
	p = quickTwoSum(p.x, p.y);
	return p;
}

float2 df64_mult(float a, float2 b) {
	return df64_mult(b, a);
}

/**
 * since a 2x mult just changes the exponent
 *   this should work for mult by any power of 2
 */
float2 df64_multFASTX2(float2 a) {
	
	return a*2;;
}

float2 df64_divFASTX2(float2 a) {

	return a/2;
}

float2 df64_multPow2(float2 a, int b) {
	return a*b;
}

float2 df64_divPow2(float2 a, int b) {
	return a/b;
}

/**
 * df64 + float
 */
float2 df64_add(float2 a, float b) {
	float2 s;
	s = twoSum(a.x, b);
	s.y += a.y;
	s = quickTwoSum(s.x, s.y);
	return s;
}

/**
 * float + df64
 */
float2 df64_add(float a, float2 b) {
	float2 s;
	s = twoSum(b.x, a);
	s.y += b.y;
	s = quickTwoSum(s.x, s.y);
	return s;
}

/**
 * from Hida, with changes to return float2 rather than using out parameter.
 * Satisfies IEEE style error bound, due to K. Briggs and W. Kahan.
 */
float2 df64_addSLOW(float2 a, float2 b) {

    float2 s, t;
    s = twoSum(a.x, b.x);
    t = twoSum(a.y, b.y);
    s.y += t.x;
    s = quickTwoSum(s.x, s.y);
    s.y += t.y;
    s = quickTwoSum(s.x, s.y);
    return s;
}

/** same as above but uses twoSumComp() to perform both
 *   twoSum() ops at the same time
 */
float2 df64_add(float2 a, float2 b) {

	float4 st;
	st = twoSumComp(a, b);
	st.y += st.z;
	st.xy = quickTwoSum(st.x, st.y);
	st.y += st.w;
	st.xy = quickTwoSum(st.x, st.y);
	return st.xy;
}

/**
 * dfReal - float
 */
float2 df64_diff(float2 a, float b) {
	float2 s;
	s = twoDiff(a.x, b);
	s.y += a.y;
	s = quickTwoSum(s.x, s.y);
	return s;
}

/**
 * float - dfReal
 */
float2 df64_diff(float a, float2 b) {
	float2 s;
	s = twoDiff(a, b.x);
	s.y -= b.y;
	s = quickTwoSum(s.x, s.y);
	return s;
}

/**
 * Hida's method, using float2's instead of out parameters
 */
float2 df64_diffSLOW(float2 a, float2 b) {

    float2 s, t;
    s = twoDiff(a.x, b.x);
    t = twoDiff(a.y, b.y);
    s.y += t.x;
    s = quickTwoSum(s.x, s.y);
    s.y += t.y;
    s = quickTwoSum(s.x, s.y);
    return s;
}

/**
 * the above _diff method can be improved using the twoDiffComp()
 * to do the two twodiff() calls simultaneously
 */
float2 df64_diff(float2 a, float2 b) {

	float4 st;
	st = twoDiffComp(a, b);
	st.y += st.z;
	st.xy = quickTwoSum(st.x, st.y);
	st.y += st.w;
	st.xy = quickTwoSum(st.x, st.y);
	return st.xy;
}

/**
 * eq() & neq() -- equality tests
 */
// dfReal == float
bool df64_eq(float2 a, float b) {
  return (a.x == b && a.y == 0.0);
}

// float == dfReal
bool df64_eq(float a, float2 b) {
  return (a == b.x && b.y == 0.0);
}

/* double-float == double-float */
bool df64_eq(float2 a, float2 b) {
  return (a.x == b.x && a.y == b.y);
}

// dfReal != float
bool df64_neq(float2 a, float b) {
  return (a.x != b || a.y != 0.0);
}

// float != dfReal
bool df64_neq(float a, float2 b) {
  return (a != b.x || b.y != 0.0);
}

/* double-float != double-float */
bool df64_neq(float2 a, float2 b) {
  return (a.x != b.x || a.y != b.y);
}

/**
 * lt() & leq() -- less-than tests
 */
// dfReal < float
bool df64_lt(float2 a, float b) {
  return (a.x < b || (a.x == b && a.y < 0.0));
}

// float < dfReal
bool df64_lt(float a, float2 b) {
  return (a < b.x || (a == b.x && b.y > 0.0));
}

/* double-float < double-float */
bool df64_lt(float2 a, float2 b) {
  return (a.x < b.x || (a.x == b.x && a.y < b.y));
}

// dfReal <= float
bool df64_leq(float2 a, float b) {
  return (a.x < b || (a.x == b && a.y <= 0.0));
}

// float <= dfReal
bool df64_leq(float a, float2 b) {
	return (a < b.x || (a == b.x && b.y >= 0.0));
}

// dfReal <= dfReal
bool df64_leq(float2 a, float2 b) {
  return (a.x < b.x || (a.x == b.x && a.y <= b.y));
}

/**
 * gt() & geq() -- greater-than tests
 */
// dfReal > float
bool df64_gt(float2 a, float b) {
  return (a.x > b || (a.x == b && a.y > 0.0));
}

// float > dfReal
bool df64_gt(float a, float2 b) {
  return (a > b.x || (a == b.x && b.y < 0.0));
}

/* double-float > double-float */
bool df64_gt(float2 a, float2 b) {
  return (a.x > b.x || (a.x == b.x && a.y > b.y));
}

// dfReal >= float
bool df64_geq(float2 a, float b) {
  return (a.x > b || (a.x == b && a.y >= 0.0));
}

// float >= dfReal
bool df64_geq(float a, float2 b) {
	return (a > b.x || (a == b.x && b.y <= 0.0));
}

// dfReal >= dfReal
bool df64_geq(float2 a, float2 b) {
  return (a.x > b.x || (a.x == b.x && a.y >= b.y));
}

/*********** Squaring and higher powers **********/
float2 df64_sqr(float2 a) {
  float2 p;
  float2 s;
  p = twoSqr(a.x);
  p.y += 2.0 * a.x * a.y;
  p.y += a.y * a.y;
  s = quickTwoSum(p.x, p.y);
  return s;
}

float2 df64_sqr(float a) {
	float2 p1;
	p1 = twoSqr(a);
	return quickTwoSum(p1.x, p1.y);
}

/**
 * sqrt() -- this uses "Karp's Trick" according to Hida,
 *   which is just to use the single-precision sqrt as
 *   an approximation and does a Newton iteration using
 *   as few full-precision operations as possible.  See
 *   [Karp 93]
 *
 * "sqrt(a) = a*x + [a - (a*x)^2] * x / 2   (approx)
 *
 *   The approximation is accurate to twice the accuracy of x.
 *   Also, the multiplication (a*x) and [-]*x can be done with
 *   only half the precision."
 * 
 * @param A must be non-negative
 */
float2 df64_sqrt(float2 A) {

//	float xn = (A.x == 0.0) ? 0.0 : rsqrt(A.x);

	float xn = rsqrt(A.x);
	float yn = A.x*xn;
	float2 ynsqr = df64_sqr(yn);

	float diff = (df64_diff(A, ynsqr)).x;
	float2 prodTerm = twoProd(xn, diff) * 0.5f;
	
	return df64_add(yn, prodTerm);
}

/**
 * div() -- this also uses "Karp's Trick", using the
 *   single-precision recip() as an approximation.
 *   Hida's work was hard to decipher, due to operator
 *   overloading. Will implement their version later
 *   and compare it to this for speed and accuracy.
 *   For details, see [Karp 93].
 *
 *   xn = recip(A)
 *   yn = B*xn
 *   "div(B, A) = yn + xn*(B - A*yn)   (approx)
 *
 *   Since Newton's is quadratic convergent, should get double
 *      prec. from single-prec. approx
 *
 *      xn is single-prec.
 *      yn is single-prec. approx by prod. of two single-prec.
 *      A*yn is double*single
 *      B - Ayn is double-double
 *      xn*(...) multiplies two single-prec and gives double.
 * 
 * @param A must be non-zero
 */
float2 df64_div(float2 B, float2 A) {

	float xn = 1.0f/A.x;

	float yn = B.x*xn;
	float diffTerm = (df64_diff(B, df64_mult(A, yn))).x;
	float2 prodTerm = twoProd(xn, diffTerm);

	return df64_add(yn, prodTerm);
}

/**
 * similar to above, but A only specified to f32 precision
 */
float2 df64_div(float2 B, float A) {
	
	float xn = 1.0f/A;
	float yn = B.x*xn;
	float diffTerm = (df64_diff(B, twoProd(A, yn))).x;
	float2 prodTerm = twoProd(xn, diffTerm);
	
	return df64_add(yn, prodTerm);

}

/**
 * similar to above, but B only specified to f32 precision
 */
float2 df64_div(float B, float2 A) {
	
	float xn = 1.0f/A.x;
	float yn = B*xn;
	float diffTerm = (df64_diff(B, df64_mult(A, yn))).x;
	float2 prodTerm = twoProd(xn, diffTerm);
	
	return df64_add(yn, prodTerm);

}

/**
 * both values are only f32
 */
 float2 df64_div(float B, float A) {
 
	float xn = 1.0f/A;
	float yn = B*xn;
	float diffTerm = (df64_diff(B, twoProd(A, yn))).x;
	float2 prodTerm = twoProd(xn, diffTerm);
	
	return df64_add(yn, prodTerm);
}

/**
 * fabs is an easy one for df64 on the GPU
 *   --multiply a by sign of high-order float
 */
float2 df64_fabs(float2 a) {
	
	return sign(a.x)*a;
}

/**
 * if hi-float is integer already, add floor(lo)
 *    else lo = 0
 */
float2 df64_floor(float2 a) {
	
	/**
 * This will be faster on a vector processor, the below on a scalar
 *
	float2 outVal = floor(a);
	if (outVal.x == a.x)
		outVal = quickTwoSum(outVal.x, outVal.y);
	else
		outVal.y = 0;
 */
	float2 outVal;
	outVal.x = floor(a.x);
	if (outVal.x != a.x)
		outVal.y = 0;
	else
		outVal = quickTwoSum(a.x, floor(a.y));
	return outVal;
}


/**
 * if hi-float is integer already, add ceil(lo)
 *    else lo = 0
 */
float2 df64_ceil(float2 a) {

/**
 * This will be faster on a vector processor, the below on a scalar
 *
	float2 outVal = ceil(a);
	if (outVal.x == a.x)
		outVal = quickTwoSum(outVal.x, outVal.y);
	else
		outVal.y = 0;
 */
	float2 outVal;
	outVal.x = ceil(a.x);
	if (outVal.x != a.x)
		outVal.y = 0;
	else
		outVal = quickTwoSum(a.x, ceil(a.y));
	return outVal;
}

/**
 * nint() -- nearest int rounding code.  Adapted from Yozo Hida's code.
 *    This seems simple and easy, but may be inaccurate for values
 *    very near i + 0.5.
 */
 float2 df64_nint(float2 a) {
 
	return df64_floor(df64_add(a, ONE*0.5f));
 }

/**
 * df64_rem -- compute quotient and rem satisfying 
 *     a = quot*b + rem,  |rem| <= b/2,
 * @return rem, save quot in out var
 * Note that this does *not* return fmod(a, b),
 *     since |quot*b| may be > |a|
 * NOTE:  this needs to be done in extended precision;
 *  --it assumes values are exact, but, as below, we need higher
 *    than df64 for our M_PI values to get correct product and
 *    remainders for the trig. range-reductions.
 */

float2 df64_remOLD(float2 a, float2 b) {
	float2 quot = df64_nint(df64_div(a, b));
	return df64_diff(a, df64_mult(quot, b));
}

float2 df64_remOLD(float2 a, float2 b, out float2 quot) {
	quot = df64_nint(df64_div(a, b));
	return df64_diff(a, df64_mult(quot, b));
}

// Like Miller's modr
// a=n*b+rem, |rem|<=b/2, exact result.
float2 df64_rem(float2 a, float2 b, out float2 quot) {

  float2 temp;
  temp = df64_div(a, b);
  float n = round(temp.x);
  temp = twoProd(n, b.x);
  float2 rem = float2(a.x, ZERO);
  temp = df64_diff(rem, temp);
  rem = float2(a.y, ZERO);
  temp = df64_add(rem, temp);
  rem = df64_mult(n, float2(b.y, ZERO));
  rem = df64_diff(temp, rem);
  quot = float2(n, ZERO);
  
  return rem;
}

/**
 * pre: a > 0, n integer, there may be something wrong here xxAT
 */
float2 df64_npow(float2 a, int n) {

	/* if n = 0, return 1 unless a = 0, when Nan */
	/* for now xxAT don't bother checking a */
	float2 outVal;
	int nmag = n >= 0 ? n : -n;

	float2 r = a;
	
	if (nmag % 2 == 1)
		outVal = a;
	else
		outVal = float2(ONE, ZERO);
		
	nmag = nmag/2;	
	while (nmag > 0) {
		r = df64_sqr(r); 
		if (nmag % 2 == 1)
			outVal = df64_mult(outVal, r);
		nmag = nmag/2;
	}

	if (n < 0)
		outVal = df64_div(float2(ONE, ZERO), outVal);

	return outVal;
}	
	
float2 df64_npow(float a, int n) {

	return df64_npow(float2(a, ZERO), n);
}

/**
 * df64_npow2To6() -- compute a^64 = a^(2^6) power
 */
float2 df64_npow2To6(float2 a) {

	float2 outVal = a;
	
	outVal = df64_sqr(outVal);
	outVal = df64_sqr(outVal);
	outVal = df64_sqr(outVal);
	outVal = df64_sqr(outVal);
	outVal = df64_sqr(outVal);
	outVal = df64_sqr(outVal);

	return outVal;
}

/**
 * df64_npow4() -- compute a^4
 */
float2 df64_npow4(float2 a) {
	
	float2 outVal = a;
	outVal = df64_sqr(outVal);
	outVal = df64_sqr(outVal);

	return outVal;
}		

/**
 * df64_npow2ToLgN() -- compute a to the 2^lgn
 */
float2 df64_npow2ToLgN(float2 a, int lgn) {

	float2 outVal = a;
	
	for (int i = 1; i <= lgn; i++)
		outVal = df64_sqr(outVal);

	return outVal;
}

/**
 * expTAYLOR() -- compute Taylor series approx to e^a
 *   for |a| < 0.000542. [(ln 2)/2/64].  Should converge
 *   very rapidly.
 */
float2 df64_expTAYLOR(float2 a) {

	const float thresh = 1.0e-20*exp(a.x)*ONE;
	float2 t;  /* Term being added. */
	float2 p;  /* Current power of a. */
	float2 f;  /* Denominator. */
	float2 s;  /* Current partial sum. */
	float2 x;  /* = -sqr(a) */
	float m;
	
	s = df64_add(1.0f*ONE, a);  // first two terms
	p = df64_sqr(a);
	m = 2.0f*ONE;
	f = float2(2.0f*ONE, 0.0f);
	t = p/2.0f;
	while (abs(t.x) > thresh) {
		s = df64_add(s, t);
		p = df64_mult(p, a);
		m += 1.0f;
		f = df64_mult(f, m);
		t = df64_div(p, f);
	}

	return df64_add(s, t);
}

float2 df64_exp(float2 a) {
  /* (by Hida):
     Strategy:  We first reduce the size of x by noting that
     
          exp(kr + m) = exp(m) * exp(r)^k

     Thus by choosing m to be a multiple of log(2) closest
     to x, we can make |kr| <= log(2) / 2 = 0.3466.  Now
     we can set k = 64, so that |r| <= 0.000542.  Then

          exp(x) = exp(kr + s log 2) = (2^s) * [exp(r)]^64

     Then exp(r) is evaluated using the familiar Taylor series.
     Reducing the argument substantially speeds up the convergence.
  */  
	float2 outVal = float2(0.0f, 0.0f);
	float2 r;
	float2 rem, df_z;
	
	// RANGE REDUCTION IS SCREWED --- HOW TO FIX??? xxAT
	int lgk = 2;//(int) 1;    // using 1, 2 gives NaNs, but better log(x)
	int k = 4; //(int) 2;
	/**
	 * return +INF or 0 if exponent is out of range
	 * (just let outVal.x = exp(a.hi)
	 */
	
	if ((a.x >= 88.7) || (a.x <= -87.3)) 
//		outVal.x = exp(a.x);
		outVal.x = 1.0f*ZERO;
	else if (a.x == 0.0)
		outVal.x = 1.0f*ONE;
	else if (df64_eq(a, 1.0f*ONE))
		outVal = df64M.E;
	else if (abs(a.x) < 0.000542)
		outVal = df64_expTAYLOR(a);
	else {
		// ~150 fps
		// choice of test is 8: main_EXP_df64
		// EPS = 7.105427e-015 and numCount = 262144
		// For whole image, min error    = -18.486298 ulps
		//			max error    = 16.943582 ulps
		//			mean error   = -0.590102 ulps
        //			mean |error| = 2.199226 ulps
        //			r.m.s error  = 3.030591 ulps
		// with 0 NaNs or Infs
		r = a/k;
		r = df64_expTAYLOR(r);

		outVal = df64_npow4(r);
	}
	/* else {
		// ~360 fps
		//	choice of test is 8: main_EXP_df64
		//	EPS = 7.105427e-015 and numCount = 262144
		//  For whole image, min error    = -90.356737 ulps
		//             max error    = 53.146445 ulps
		//             mean error   = -4.933327 ulps
		//             mean |error| = 13.192848 ulps
		//             r.m.s error  = 18.129237 ulps
		//  with 0 NaNs or Infs
 
		k = 64;
		lgk = 6;
		rem = df64_rem(a, df64M.LOG2, df_z);
		int z = (int) df_z.x;

		// since k is 2^6, can simply divide the df64 number pairwise
		r = rem/k;
		r = df64_expTAYLOR(r);
		r = df64_nTo2ToThe6(r);
		
		outVal = df64_mult(r, pow(2.0, z));
	}
	*/
	return outVal;
}

float2 df64_exp(float a) {

	return df64_exp(float2(a, ZERO*1.0f));
}

/**
 * As Hida et al., use a Newton iteration for log_e(x)
 */
float2 df64_log(float2 a) {

	  /* Strategy.  The Taylor series for log converges much more
     slowly than that of exp, due to the lack of the factorial
     term in the denominator.  Hence this routine instead tries
     to determine the root of the function

         f(x) = exp(x) - a

     using Newton iteration.  The iteration is given by

         x' = x - f(x)/f'(x) 
            = x - (1 - a * exp(-x))
            = x + a * exp(-x) - 1.
	   
     Only one iteration is needed, since Newton's iteration
     approximately doubles the number of digits per iteration. */

	float2 xi = float2(0.0f, 0.0f);
	
	if (!df64_eq(a, 1.0f)) {
		if (a.x <= 0.0)	
			xi = log(a.x).xx;	// return NaN
		else {
			xi.x = log(a.x);
			xi = df64_add(df64_add(xi, df64_mult(df64_exp(-xi), a)), -1.0);
		//	xi = df64_add(df64_add(xi, df64_mult(df64_exp(-xi), a)), -1.0);
		//	xi = df64_add(df64_add(xi, df64_mult(df64_exp(-xi), a)), -1.0);
		}
	}
	return xi;
}

/**
 * nthRoot() -- return the positive nth-root of input using
 *   Newton iteration
 * From Hida (xxAT),
       Strategy:  Use Newton's iteration to solve
          1/(x^n) - a = 0
       Newton iteration becomes
          x' = x + x * (1 - a * x^n) / n
       Since Newton's iteration converges quadratically, 
       we only need to perform it twice.

 * xxAT This can probably be done more efficiently as per df64_sqrt().
 * @param x must be non-negative
 */
float2 df64_nroot(float2 A, int n) {
 
	float2 outVal;
	
	if (n % 2 == 0 && A.x <= 0.0f)
		outVal = sqrt(-ONE);
	else if (n == 0)
		outVal = float2(ONE, 0.0f);
	else if (n == 1)
		outVal = A;
	else if (n == 2)
		outVal = df64_sqrt(A);
	else {
		float2 r = df64_fabs(A);
		float2 x = df64_exp(-log(r.x)/n);

		outVal = x;
		float2 prodTerm = df64_mult(r, df64_npow(x, n));
		float2 sumExpr = df64_div(df64_diff(ONE, prodTerm), n);
		x = df64_add(x, df64_mult(x, sumExpr));
		
		if (A.x < 0.0f)
			x = -x;
		outVal = df64_div(ONE, x);
	}
	return outVal;		
}

/**
 * sincosPadeChebychev(a) -- use table-lookup to find
 */
float4 df64_sincosPade(float2 a) {return float4(0, 0, 0, 0);}

/**
 * sincosTAYLOR(a) -- computes sin(a) == .xy
 *                             cos(a) == .zw
 *   using Taylor series, assuming fabs(a) < PI/32
 * @return float4(df64:sin(a), df64:cos(a))
 */
float4 df64_sincosTAYLOR(float2 a) {

	const float thresh = 1.0e-20 * abs(a.x) * ONE;
	float2 t;  /* Term being added. */
	float2 p;  /* Current power of a. */
	float2 f;  /* Denominator. */
	float2 s;  /* Current partial sum. */
	float2 x;  /* = -sqr(a) */
	float m;

	float2 sin_a, cos_a;
	if (a.x == 0.0f) {
		sin_a = float2(ZERO, ZERO);
		cos_a = float2(ONE, ZERO);
	}
	else {
		x = -df64_sqr(a);
		s = a;
		p = a;
		m = ONE;
		f = float2(ONE, ZERO);
		while (true) {
			p = df64_mult(p, x);
			m += 2.0f;
			f = df64_mult(f, m*(m-1));
			t = df64_div(p, f);
			s = df64_add(s, t);
			if (abs(t.x) < thresh)
				break;
		}

		sin_a = s;
		cos_a = df64_sqrt(df64_add(ONE, -df64_sqr(s)));
	}
	return float4(sin_a, cos_a);
}

/**
 * sin(a) -- use Hida's method to do argument reduction and compute sin(x)
 * NOTE:  this really needs to be done in extended precision;
 *  --it assumes values are exact, but, as below, we need higher
 *    than df64 for our M_PI values to get correct product and
 *    remainders for the trig. range-reductions.
 *  Current values can be anywhere from great to really bad,
 *    whereas we'd like 0.5 ulps for our trig functions.
*/
float2 df64_sin(float2 a) {  

	/* Strategy.  To compute sin(x), we choose integers a, b so that
	x = s + a * (pi/2) + b * (pi/16)
	and |s| <= pi/32.  Using the fact that 
	sin(pi/16) = 0.5 * sqrt(2 - sqrt(2 + sqrt(2)))
	we can compute sin(x) from sin(s), cos(s).  This greatly 
	increases the convergence of the sine Taylor series. 
    */
	float2 outVal = float2(ZERO, ZERO);
	float2 r, t, s, c, j, k;
	float4 sin_t_cos_t;
	float4 uv;
	
	if (a.x != 0.0f) {
		/* First reduce modulo 2*pi so that |r| <= pi. */
		r = df64_rem(a, df64M.PI*2.0f, j);  // xxAT better pass in 2*PI as const

		/* Now reduce by modulo pi/2 and then by pi/16 so that
		we obtain numbers a, b, and t. */
		t = df64_rem(r, df64M.PI_2, j);
		float abs_j = round(abs(j.x));
		t = df64_rem(t, df64M.PI_16, k);
		float abs_k = round(abs(k.x));

		if (abs_j > 2 || abs_k > 4 )
			outVal = sqrt(-ONE);
		else {

			sin_t_cos_t = df64_sincosTAYLOR(t);

			if (abs_k == 0) {
				s = sin_t_cos_t.xy;
				c = sin_t_cos_t.zw;
			}
			else {
				if (abs_k == 1.0f)
					uv = df64M.SINCOS_PI_16.zwxy;
				else if (abs_k == 2.0f)
					uv = df64M.SINCOS_2PI_16.zwxy;
				else if (abs_k == 3.0f)
					uv = df64M.SINCOS_3PI_16.zwxy;
				else 
					uv = df64M.SINCOS_4PI_16.zwxy;

				float signK = sign(k.x);
				
				s = df64_add(df64_mult(uv.xy, sin_t_cos_t.xy),  signK*df64_mult(uv.zw, sin_t_cos_t.zw));
				c = df64_add(df64_mult(uv.xy, sin_t_cos_t.zw), -signK*df64_mult(uv.zw, sin_t_cos_t.xy));
			}

			if (abs_j == 0)
				outVal = s;
			else if (j.x == 1)
				outVal = c;
			else if (j.x == -1)
				outVal = -c;
			else
				outVal = -s;
		}
	}
	return outVal;;
}

/**
 * compute both sine and cosine of a -- virtually identical to df64_sin()
 */
float4 df64_sincos(float2 a) {  

	/* Strategy.  To compute sin(x), we choose integers a, b so that
	x = s + a * (pi/2) + b * (pi/16)
	and |s| <= pi/32.  Using the fact that 
	sin(pi/16) = 0.5 * sqrt(2 - sqrt(2 + sqrt(2)))
	we can compute sin(x) from sin(s), cos(s).  This greatly 
	increases the convergence of the sine Taylor series. 
    */
    
 	float4 outVal = float4(ZERO, ZERO, ONE, ZERO);
	float2 r, t, s, c, j, k, dummy;
	float4 sin_t_cos_t;
	float4 uv;
	
	if (a.x != 0.0f) {
		
		/* First reduce modulo 2*pi so that |r| <= pi. */
		r = df64_rem(a, df64M.PI*2.0f, dummy);  // xxAT better pass in 2*PI as const

		/* Now reduce by modulo pi/2 and then by pi/16 so that
		we obtain numbers a, b, and t. */
		t = df64_rem(r, df64M.PI_2, j);
		float abs_j = round(abs(j.x));
		t = df64_rem(t, df64M.PI_16, k);
		float abs_k = round(abs(k.x));

		if (abs_j > 2 || abs_k > 4 )
			outVal = sqrt(-ONE);
		else {
			
			sin_t_cos_t = df64_sincosTAYLOR(t);

			if (abs_k == 0) {
				s = sin_t_cos_t.xy;
				c = sin_t_cos_t.zw;
			}
			else {
				if (abs_k == 1.0f)
					uv = df64M.SINCOS_PI_16.zwxy;
				else if (abs_k == 2.0f)
					uv = df64M.SINCOS_2PI_16.zwxy;
				else if (abs_k == 3.0f)
					uv = df64M.SINCOS_3PI_16.zwxy;
				else 
					uv = df64M.SINCOS_4PI_16.zwxy;

				float signK = sign(k.x);
				
				s = df64_add(df64_mult(uv.xy, sin_t_cos_t.xy),  signK*df64_mult(uv.zw, sin_t_cos_t.zw));
				c = df64_add(df64_mult(uv.xy, sin_t_cos_t.zw), -signK*df64_mult(uv.zw, sin_t_cos_t.xy));
			}

			if (abs_j == 0)
				outVal = float4(s, c);
			else if (j.x == 1)
				outVal = float4(c, -s);
			else if (j.x == -1)
				outVal = float4(-c, s);
			else
				outVal = float4(-s, -c);
		}
	}
	
	return outVal;;
}

/**
 * cos(x) -- this is easy.  sincos() is almost identical in runtime to sin();
 *   any transformation of the sin's result will be more costly than simply
 *   running sinoos()
 */
float2 df64_cos(float2 a) {
 
	return df64_sincos(a).zw;
}

/**
 * Complex number routines, including
 *
 *    cdf64_add(float4, float4)
 *    cdf64_diff(float4, float4)
 *    cdf64_mult(float4, float4)
 *    cdf64_cmplxConj(float4)
 *    cdf64_div(float4, float4)
 *    cdf64_sqrc(float4) -- returns componentwise sqr,
 *       i.e., sqrc(float4(a, b)) = sqrc(a + bi) = (a*a + b*b*i)
 */

/**
 * does a df add of two complex df numbers,
 *   where the .xy is the df real components 
 *             .zw is the df complex components
 */
float4 cdf64_add(float4 a_ri, float4 b_ri) {

	float4 s, t;
	s = twoSumComp(a_ri.xz, b_ri.xz);
	t = twoSumComp(a_ri.yw, b_ri.yw);
	s.yw += t.xz;
	s = quickTwoSumComp(s.xz, s.yw);
	s.yw += t.yw;
	s = quickTwoSumComp(s.xz, s.yw);
	return s;
}

float4 cdf64_diff(float4 a_ri, float4 b_ri) {

	float4 s, t;
	s = twoDiffComp(a_ri.xz, b_ri.xz);
	t = twoDiffComp(a_ri.yw, b_ri.yw);
	s.yw += t.xz;
	s = quickTwoSumComp(s.xz, s.yw);
	s.yw += t.yw;
	s = quickTwoSumComp(s.xz, s.yw);
	return s;
}

/**
 * xxAT -- a true complex multiply.  Check for accuracy and efficiency.
 */
float4 cdf64_mult(float4 a, float4 b) {

	return float4(df64_diff(df64_mult(a.xy, b.xy), df64_mult(a.zw, b.zw)),
				  df64_add(df64_mult(a.xy, b.zw), df64_mult(a.zw, b.xy)));
}

/**
 * xxAT -- returns the complex conjugate
 */
float4 cdf64_cmplxConj(float4 a) {


	return float4(a.xy, -a.zw);
}

/**
 * squares the real and imaginary terms of a complex number
 *   individually (i.e., (r, i) --> (r*r, i*i)
 */
float4 cdf64_sqrc(float4 a) {

	float4 p;
	float4 s;
	p = twoSqrComp(a.xz);
	p.yw += 2.0*a.xz*a.yw;
	p.yw += a.yw*a.yw;
	s = quickTwoSumComp(p.xz, p.yw);
	return s;
}

/**
 * computes the square of the complex number (a + bi)
 *   as (a^2 - b^2) + 2abi
 */
float4 cdf64_sqr(float4 a) {

	float4 zed;
	float4 aCompSqr = cdf64_sqrc(a);
	zed.xy = df64_diff(aCompSqr.xy, aCompSqr.zw);
	zed.zw = df64_mult(a.xy, a.zw);
	zed.zw *= 2.0f;
	return zed;
}

/**
 * xxAT -- complex division
 * @param A must be non-zero
 */
float4 cdf64_div(float4 B, float4 A) {

	float4 subprod = cdf64_mult(B, cdf64_cmplxConj(A));
	float4 normA = cdf64_sqrc(A);
	float2 denom = df64_add(normA.xy, normA.zw);

	return float4(df64_div(subprod.xy, denom), df64_div(subprod.zw, denom));
}

/* double-float * double-float */
float2 dfReal_mult(float2 a, float2 b) {
    float2 p;

	/**

		p = twoProd(a.x, b.x);
		p.y += a.x * b.y;
		p.y += a.y * b.x;
		p = quickTwoSum(p.x, p.y);
		return p;
	*/
// Faster twoProd()
	p = twoProdFAST(float2(a.x, b.x));
	p.y += dot(a.xy, b.yx);	
    p = quickTwoSum(p.x, p.y);
    return p;
}

float2 dfReal_add(float2 a, float2 b) {

	float4 st;
	st = twoSumComp(a, b);
	st.y += st.z;
	st.xy = quickTwoSum(st.x, st.y);
	st.y += st.w;
	st.xy = quickTwoSum(st.x, st.y);
	return st.xy;
}

float2 dfReal_diff(float2 a, float2 b) {

	float4 st;
	st = twoDiffComp(a, b);
	st.y += st.z;
	st.xy = quickTwoSum(st.x, st.y);
	st.y += st.w;
	st.xy = quickTwoSum(st.x, st.y);
	return st.xy;
}

float4 dfComp_add(float4 a_ri, float4 b_ri) {

	float4 s, t;
	s = twoSumComp(a_ri.xz, b_ri.xz);
	t = twoSumComp(a_ri.yw, b_ri.yw);
	s.yw += t.xz;
	s = quickTwoSumComp(s.xz, s.yw);
	s.yw += t.yw;
	s = quickTwoSumComp(s.xz, s.yw);
	return s;
}

float4 dfComp_sqrc(float4 a) {

	float4 p;
	float4 s;
	p = twoSqrComp(a.xz);
	p.yw += 2.0*a.xz*a.yw;
	p.yw += a.yw*a.yw;
	s = quickTwoSumComp(p.xz, p.yw);
	return s;
}

/**
 * exp(df64 a) -- compute df64 e^a for the extended-precision a,
 * exp(float a) -- compute df64 e^a for single-precision a
 */
 
float4 mainTRIGFUN(float4 coords : TEXCOORD0,
			uniform sampler2D oldInputTexture,
			uniform float4 E_INV,
			uniform float4 PI_INV,
			uniform float4 LOG2_INV,
			uniform float4 LOG10_INV,
			uniform float4 PI_2_PI_4,
			uniform float4 PI_8_PI_16,
			uniform float4 SC_PI_16,
			uniform float4 SC_2PI_16,
			uniform float4 SC_3PI_16,
			uniform float4 SC_4PI_16,
			uniform float mult0,
			uniform float mult1,
			float2 loc : WPOS) : COLOR
{
	ZERO = mult0;
	ONE = mult1;
	df64M.E = E_INV.xy;
	df64M.PI = PI_INV.xy;
	df64M.LOG2 = LOG2_INV.xy;
	df64M.LOG10 = LOG10_INV.xy;
	df64M.INV_E = E_INV.zw;
	df64M.INV_PI = PI_INV.zw;
	df64M.INV_LOG2 = LOG2_INV.zw;
	df64M.INV_LOG10 = LOG10_INV.zw;
	df64M.PI_2 = PI_2_PI_4.xy;
	df64M.PI_4 = PI_2_PI_4.zw;
	df64M.PI_8 = PI_8_PI_16.xy;
	df64M.PI_16 = PI_8_PI_16.zw;
	df64M.SINCOS_PI_16 = SC_PI_16;
	df64M.SINCOS_2PI_16 = SC_2PI_16;
	df64M.SINCOS_3PI_16 = SC_3PI_16;
	df64M.SINCOS_4PI_16 = SC_4PI_16;
	
//	float4 inVals = texRECT(oldInputTexture, loc - 0.5f);
	
//	float4 outVals = float4(df64_npow(df64M.E, 1.275f), df64_exp(df64_div(ONE*1275.0f, ONE*1000.0f)));
	float2 df_eta = df64_mult(df64M.LOG2, ONE*14.0f);
//	float4 outVals = float4(df_eta, df64_log(df_eta));
	
//	float4 outVals = float4(df_eta, df64_nroot(df_eta, 3*ONE));

//	float4 outVals = float4(df_eta, df64_exp(df_eta));
	float4 outVals = float4(df_eta, df64_cos(df_eta));
	//float4(-df_eta, df64_exp(-df_eta));//df64_cos(df_eta));
	
	return outVals;
}
