#lang typed/racket

(provide top-python)

(require "parse.rkt")

;; Translates an S-expression representing a LC to a python string
(define (top-python [s : Sexp]) : String
  (python (parse s)))

;; Translates the AST back into a string representing equivalent python code
(define (python [e : ExprLC]) : String
  (match e
    [(or (? symbol?) (? real?)) (~a e)]
    [(LamC arg body) (format "(lambda ~a: ~a)" arg (python body))]
    [(AppC f arg) (format "(~a(~a))" (python f) (python arg))]
    [(PrimC (or '+ '*) (list a b)) (format "(~a ~a ~a)" (python a) (PrimC-name e) (python b))]
    [(PrimC 'ifleq0 (list f t e))
     (format "(~a if (~a <= 0) else ~a)" (python t) (python f) (python e))]
    [(PrimC 'println (list e)) (format "print(~a)" (python e))]))

;; ---------------------------------------------------------------------------------------------------

(module+ test
  (require typed/rackunit)

  (check-equal?
   (python (AppC (LamC 'a (PrimC 'println (list (PrimC '+ '(a 1)))))
                 (PrimC 'ifleq0 (list 1 (PrimC '* '(5 7)) 6))))
   "((lambda a: print((a + 1)))(((5 * 7) if (1 <= 0) else 6)))")

  (check-equal?
   (top-python '((/ a => (println (+ a 1))) (ifleq0 1 (* 5 7) 6)))
   "((lambda a: print((a + 1)))(((5 * 7) if (1 <= 0) else 6)))")

  (check-equal?
   (top-python
    '(println ((/ fact => ((fact fact) 10))
               (/ self =>
                  (/ v =>
                     (ifleq0 v 1 (* v ((self self) (+ v -1)))))))))
   (string-append "print(((lambda fact: ((fact(fact))(10)))"
                  "((lambda self: (lambda v: "
                  "(1 if (v <= 0) else (v * ((self(self))((v + -1))))))))))")))