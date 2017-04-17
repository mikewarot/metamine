(and
	(=> (if (not C) T E)	(if C E T) )
	(=> (if true X Y)		X )
	(=> (if false X Y)		Y )
	(=> (if X Y Y) 			Y )
	(=> (if X false true)	(not X) )
	(=> (if X true false)	X )
	(=> (if C (if C T A) E)	(if C T A) )
	(=> (if C C E)			(or C E) )
	(=> (if C T C)			(and C T) )

	(=> (+ X 0)			X )
	(=> (+ 0 X)			X )
	(=> (* X 0)			0 )
	(=> (* 0 X)			0 )
	(=> (* X 1)			X )
	(=> (* 1 X)			X )
	(=> (- X 0)			X )
	(=> (- X X)			0 )
	(=> (/ X 1)			X )
	(=> (/ 0 X)			0 )
	(=> (/ X 0)			1e100 )
	(=> (/ X X)			1 )
	(=> (% X X)			0 )
	(=> (% X 0)			0 )
	(=> (% 0 X)			0 )
	(=> (* (- A) (- B))	(* A B) )

	(=> (or true X)		true )
	(=> (or X true)		true )
	(=> (or false X)	X )
	(=> (or X false)	X )
	(=> (or X X)		X )
	(=> (and true X)	X )
	(=> (and X true)	X )
	(=> (and false X)	false )
	(=> (and X false)	false )
	(=> (and X X)		X )
	(=> (and X (not X))	false )
	(=> (and (not X) X)	false )
	(=> (xor true X)	(not X) )
	(=> (xor X true)	(not X) )
	(=> (xor false X)	X )
	(=> (xor X false)	X )
	(=> (xor X X)		false )
	(=> (not (xor X Y))	(xor X Y) )
	(=> (max A A)		A )
	(=> (min A A)		A )
	(=> (max (to A B) C)	(to (max A C) (max B C)) )
	(=> (min (to A B) C)	(to (min A C) (min B C)) )

	(=> (sqrt (^ A 2))	A)
	(=> (^ (sqrt A) 2)	A)
	(=> (* (^ A X) (^ B Y))	(^ A (+ X Y)) )
	(=> (/ (^ A X) (^ B Y))	(^ A (- X Y)) )

	(=> (+ (.. A B) (.. C D))	(.. (+ A C) (+ B D)) )
	(=> (+ X (.. A B))	(.. (+ X A) (+ X B)) )
	(=> (* X (.. A B))	(.. (* X A) (* X B)) )
	(=> (+ (.. A B) X)	(.. (+ X A) (+ X B)) )
	(=> (* (.. A B) X)	(.. (* X A) (* X B)) )
	(=> (.. X X)		X )
	(=> (sqrt (.. X Y))	(.. (sqrt X) (sqrt Y)) )
	(=> (.. (A B C) (A B C)) true)

	(=> (+ (to A B) (to C D))	(to (+ A C) (+ B D)) )
	(=> (+ X (to A B))	(to (+ X A) (+ X B)) )
	(=> (+ (to A B) X)	(to (+ X A) (+ X B)) )
	(=> (to X X)		X )

	(=> (sin (to A B)) (to -1 1) )
	(=> (cos (to A B)) (to -1 1) )
	(=> (atan (to A B) X) (to 0 tau) )

	(=> (> A B)			(< B A) )
	(=> (>= A B)		(<= B A) )

	(=> (+ D (| A B))	(| (+ D A) (+ D B)) )
	(=> (+ (| A B) D)	(| (+ D A) (+ D B)) )
	(=> (- D (| A B))	(| (- D A) (- D B)) )
	(=> (- (| A B) D)	(| (- D A) (- D B)) )
	(=> (* D (| A B))	(| (* D A) (* D B)) )
	(=> (* (| A B) D)	(| (* D A) (* D B)) )
	(=> (/ D (| A B))	(| (/ D A) (/ D B)) )
	(=> (/ (| A B) D)	(| (/ D A) (/ D B)) )
	(=> (.. D (| A B))	(| (.. D A) (.. D B)) )
	(=> (.. (| A B) D)	(| (.. D A) (.. D B)) )
	(=> (sum (| A B)) (| (sum A) (sum B)) )
	(=> (< D (| A B))	(| (< D A) (< D B)) )
	(=> (<= D (| A B))	(| (<= D A) (<= D B)) )
	(=> (| X X)			X)
	(=> (+- X)			(| X (- X)) )
	(=> (| false X)		X)
	(=> (| X false)		X)
	(=> (| X true)		X)
	(=> (| true X)		X)
	(=> (F undefined)	undefined)
	(=> (F undefined A) undefined)
	(=> (F A undefined) undefined)

	(=> (and
		  (= A (| B C))
		  (< A D)
		)
		(|
		  (if (< B D) (= A B) false)
		  (if (< C D) (= A C) false)
		)
	)

	(<=> (and (* A B) (: A number) (: B number)) (* B A) )
	(<=> (+ (* C A) (* C B))	(* C (+ A B)) )
	(<=> (/ A B)				(* A (/ 1 B)) )
	(<=>
		(and
			(commutative F)
			(F A (F B C))
		)
		(F B (F A C))
	)
	(<=> (and (commutative F) (F A B))	(F B A) )
	(=> (commutative
		  	(| and or xor min max + | =))
			true )

	(=> (+ (+ X Y) X) (+ (* X 2) Y) )
	(=> (/ (+ A B) C) (+ (/ A C) (/ B C)) )
	(=> (/ (* A B) B)	A)
	(=> (- (+ A B) A)	B)
	(=> (* (+ A B) C)	(+ (* A C) (* B C)) )
	
	(=> (sum (.. A B))
		(*
		  (/ (+ B A) 2)
		  (+ 1 (- B A))
		)
	)
	(=> (sum X) X)

	(=> (= 0 (+
			   (* A (^ X 2))
			   (* B X)
			   C
			  )
		)

		(= X (/
		  (-
			(+- 
			  (sqrt
				(-
				  (^ B 2)
				  (* 4 (* A C))
				  )
				)
			  )
			B)
		  (* 2 A)
		) )
	)
)
