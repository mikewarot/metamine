(and
	; basic arith tests
	(=? 6 (+ 1 2 3))
	(=? 6 (+ (1 2 3)))
	(=? 0 (- 3 2 1))
	(=? 0 (- (3 2 1)))
	(=? 1 (+ 1 (- 2 2)))
	(=? 6 (* 1 2 3))
	(=? 1 (/ 4 2 2))
	(=? oo (/ 1 0))
	;(=? (|| 'a' 'b') 'ab')
	;(=? (+- 2) (| 1 -1))
	;(=? (+ (| 1 2) 3) (| 4 5))

	;(:= a 3)
	;(:= a 2)
)
