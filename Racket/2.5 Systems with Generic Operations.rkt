#lang racket

; Systems with Generic Operations

; In the previous section, we saw how to design systems in which data objects
; can be represented in more than one way. The key idea is to link the code
; that specifies the data operations to the several representations by means
; of generic interface procedures. Now we will see how to use this same idea
; not only to define operations that are generic over different representations
; but also to define operations that are generic over different kinds of
; arguments. We have already seen several different packages of arithmetic
; operations: the primitive arithmetic (+, -, *, /) built into our language,
; the rational-number arithmetic (add-rat, sub-rat, mul-rat, div-rat) of
; section 2.1.1, and the complec-number arithmetic that we implemented in
; section 2.4.3. We will now use data-directed techniques to construct a
; package of arithmetic operations that incorporates all the arithmetic
; packages we have already constructed.
;
; Figure 2.23 shows the structure of the system we shal build. Notice the
; abstraction barriers. From the perspective of someone using "numbers", there
; is a single procedure add that operates on whatever numbers are supplied.
; add is part of a generic interface that allows the separate ordinary-arithmetic,
; rational-arithmetic, and complex-arithmetic packages to be accessed uniformly
; by programs that use numbers. Any individual arithmetic package (such as
; the complex package) may itself be accessed through generic procedures (such
; as add-complex) that combine packages designed for different representations
; (such as rectangular and polar). Moreover, the structure of the system is
; additive, so that one can design the individual arithmetic packages separately
; and combine them to produce a generic arithmetic system.

;                        Programs that use numbers
;                           +-----------------+
; --------------------------| add sub mul div |----------------------
;                           +-----------------+
;                         Generic arithmetic package
;   +-----------------+   +-------------------------+   +-----+
; __| add-rat sub-rat |___| add-complex sub-complex |___| + - |______
;   | mul-rat div-rat | | | mul-complex div-complex | | | * / |
;   +-----------------+ | +-------------------------+ | +-----+
;                       |     Complex arithmetic      |
;        Rational       |-----------------------------|   Ordinary
;       arithmetic      |   Rectangular |    Polar    |  arithmetic
; ----------------------+-----------------------------+--------------
;             List structure and primitive machine arithmetic
;
;  Figure 2.23: Generic arithmetic system

; 2.5.1 Generic Arithmetic Operations
; The task of designing generic arithmetic operations is analogous to that
; of designing the generic complex-number operations. We would like, for
; instance, to have a generic addition procedure add that acts like ordinary
; primitive addition + on ordinary numbers, like add-rat on rational numbers,
; and like add-complex on complex numbers. We can implement add, and the
; other generic arithmetic operations, by following the same strategy we
; used in Section 2.4.3 to implement generic selectors for complex numbers.
; We will attach a type tag to each kind of number and cause the generic
; procedure to dispatch to an appropriate package according to the data
; type of its arguments.

; The generic arithmetic procedures are defined as follows:

;(define (add x y) (apply-generic 'add x y))
;(define (sub x y) (apply-generic 'sub x y))
;(define (mul x y) (apply-generic 'mul x y))
;(define (div x y) (apply-generic 'div x y))

; We begin by installing a package for handling ordinary numbers, that is,
; the primitive numbers of our language. We will tag these with the symbol
; scheme-number. The arithmetic operations in this package are the primitive
; arithmetic procedures (so there is no need to define extra procedures to
; handle the untagged numbers). Since these operations each take two arguments,
; they are installed in the table keyed by the list
; (scheme-number scheme-number):

(define global-array '())

(define (make-entry k v) (list k v))
(define (key entry) (car entry))
(define (value entry) (cadr entry))

(define (put op type item)
  (define (put-helper k array)
    (cond ((null? array) (list(make-entry k item)))
          ((equal? (key (car array)) k) array)
          (else (cons (car array) (put-helper k (cdr array))))))
  (set! global-array (put-helper (list op type) global-array)))

(define (get op type)
  (define (get-helper k array)
    (cond ((null? array) #f)
          ((equal? (key (car array)) k) (value (car array)))
          (else (get-helper k (cdr array)))))
  (get-helper (list op type) global-array))
; from http://stackoverflow.com/questions/5499005/how-do-i-get-the-functions-put-and-get-in-sicp-scheme-exercise-2-78-and-on

(define (attach-tag type-tag contents)
  (cons type-tag contents))
(define (type-tag datum)
  (if (pair? datum)
      (car datum)
      (error "Bad tagged datum: TYPE-TAG" datum)))
(define (contents datum)
  (if (pair? datum)
      (cdr datum)
      (error "Bad tagged datum: CONTENTS" datum)))



(define (install-scheme-number-package)
  (define (tag x) (attach-tag 'scheme-number x))
  (put 'add '(scheme-number scheme-number)
       (lambda (x y) (tag (+ x y))))
  (put 'sub '(scheme-number scheme-number)
       (lambda (x y) (tag (- x y))))
  (put 'mul '(scheme-number scheme-number)
       (lambda (x y) (tag (* x y))))
  (put 'div '(scheme-number scheme-number)
       (lambda (x y) (tag (/ x y))))
  (put 'make 'scheme-number (lambda (x) (tag x)))
  'done)

; Users of the Scheme-number package will create (tagged) ordinary numbers by
; means of the procedure:

(install-scheme-number-package)

(define (make-scheme-number n)
  ((get 'make 'scheme-number) n))

(make-scheme-number 10)

; Now that the framework of the generic arithmetic system is in place, we can
; readily include new kinds of numbers. Here is a package that performs rational
; arithmetic. Notice that, as a benefit of additivity, we can use without
; modification the rational-number code from Section 2.1.1 as the internal
; procedures in the package:

(define (install-rational-package)
  ; Internal procedures
  (define (numer x) (car x))
  (define (denom x) (cdr x))
  (define (make-rat n d)
    (let ((g (gcd n d)))
      (cons (/ n g) (/ d g))))
  (define (add-rat x y)
    (make-rat (+ (* (numer x) (denom y))
                 (* (numer y) (denom x)))
              (* (denom x) (denom y))))
  (define (sub-rat x y)
    (make-rat (- (* (numer x) (denom y))
                 (* (numer y) (denom x)))
              (* denom x (denom y))))
  (define (mul-rat x y)
    (make-rat (* (numer x) (numer y))
              (* (denom x) (denom y))))
  (define (div-rat x y)
    (make-rat (* (numer x) (denom y))
              (* (denom x) (numer y))))
  ; interface to the rest of the system
  (define (tag x) (attach-tag 'rational x))
  (put 'add '(rational rational)
       (lambda (x y) (tag (add-rat x y))))
  (put 'sub '(rational rational)
       (lambda (x y) (tag (sub-rat x y))))
  (put 'mul '(rational rational)
       (lambda (x y) (tag (mul-rat x y))))
  (put 'div '(rational rational)
       (lambda (x y) (tag (div-rat x y))))
  (put 'make 'rational
       (lambda (n d) (tag (make-rat n d))))
  'done)
(install-rational-package)
(define (make-rational n d)
  ((get 'make 'rational) n d))

(make-rational 4 6)

; We can install a similar package to handle comlex numbers, using the tag
; complex. In creating the package, we extract from the table the operations
; make-from-real-imag and make-from-mag-ang that were defined by the rectangular
; and polar packages. Additivity permits us to use, as the internal operations,
; the same add-complex, sub-complex, mul-complex, and div-complex procedures
; from Section 2.4.1.


; First we must redefine the Rectangular and Polar packages from the previous
; section

(define (square x) (* x x))

(define (install-rectangular-package)
  ;; Internal procedures
  (define (real-part z) (car z))
  (define (imag-part z) (cdr z))
  (define (make-from-real-imag x y) (cons x y))
  (define (magnitude z)
    (sqrt (+ (square (real-part z))
             (square (imag-part z)))))
  (define (angle z)
    (atan (imag-part z) (real-part z)))
  (define (make-from-mag-ang r a)
    (cons (* r (cos a)) (* r (sin a))))
  
  ;; interface to the rest of the system
  (define (tag x) (attach-tag 'rectangular x))
  (put 'real-part '(rectangular) real-part)
  (put 'imag-part '(rectangular) imag-part)
  (put 'magnitude '(rectangular) magnitude)
  (put 'angle '(rectangular) angle)
  (put 'make-from-real-imag 'rectangular 
       (lambda (x y) (tag (make-from-real-imag x y))))
  (put 'make-from-mag-ang 'rectangular
       (lambda (r a) (tag (make-from-mag-ang r a))))
  'done)

(define (install-polar-package)
  ;; internal procedures
  (define (magnitude z) (car z))
  (define (angle z) (cdr z))
  (define (make-from-mag-ang r a) (cons r a))
  (define (real-part z) (* (magnitude z) (cos (angle z))))
  (define (imag-part z) (* (magnitude z) (sin (angle z))))
  (define (make-from-real-imag x y)
    (cons (sqrt (+ (square x) (square y)))
          (atan y x)))
  ;; interface to the rest of the system
  (define (tag x) (attach-tag 'polar x))
  (put 'real-part '(polar) real-part)
  (put 'imag-part '(polar) imag-part)
  (put 'magnitude '(polar) magnitude)
  (put 'angle '(polar) angle)
  (put 'make-from-real-imag 'polar
       (lambda (x y) (tag (make-from-real-imag x y))))
  (put 'make-from-mag-ang 'polar
       (lambda (r a) (tag (make-from-mag-ang r a))))
  'done)

(define (apply-generic op . args)
  (let ((type-tags (map type-tag args)))
    (let ((proc (get op type-tags)))
      (if proc
          (apply proc (map contents args))
          (error "No method for these types: APPLY-GENERIC"
                 (list op type-tags))))))

(define (real-part z) (apply-generic 'real-part z))
(define (imag-part z) (apply-generic 'imag-part z))
(define (magnitude z) (apply-generic 'magnitude z))
(define (angle z) (apply-generic 'angle z))

(define (make-from-real-imag x y)
  ((get 'make-from-real-imag 'rectangular) x y))
(define (make-from-mag-ang r a)
  ((get 'make-from-mag-ang 'polar) r a))

(install-rectangular-package)
(install-polar-package)


; Now write the Complex package
(define (install-complex-package)
  ;; imported procedures from rectangular and polar packages
  (define (make-from-real-imag x y)
    ((get 'make-from-real-imag 'rectangular) x y))
  (define (make-from-mag-ang r a)
    ((get 'make-from-mag-ang 'rectangular) r a))
  ;; internal procedures
  (define (add-complex z1 z2)
    (make-from-real-imag (+ (real-part z1) (real-part z2))
                         (+ (imag-part z1) (imag-part z2))))
  (define (sub-complex z1 z2)
    (make-from-real-imag (- (real-part z1) (real-part z2))
                         (- (imag-part z1) (imag-part z2))))
  (define (mul-complex z1 z2)
    (make-from-mag-ang (* (magnitude z1) (magnitude z2))
                       (+ (angle z1) (angle z2))))
  (define (div-complex z1 z2)
    (make-from-mag-ang (/ (magnitude z1) (magnitude z2))
                       (- (angle z1) (angle z2))))
  ;; interface to rest of the system
  (define (tag z) (attach-tag 'complex z))
  (put 'add '(complex complex)
       (lambda (z1 z2) (tag (add-complex z1 z2))))
  (put 'sub '(complex complex)
       (lambda (z1 z2) (tag (sub-complex z1 z2))))
  (put 'mul '(complex complex)
       (lambda (z1 z2) (tag (mul-complex z1 z2))))
  (put 'div '(complex complex)
       (lambda (z1 z2) (tag (div-complex z1 z2))))
  (put 'make-from-real-imag 'complex
       (lambda (x y) (tag (make-from-real-imag x y))))
  (put 'make-from-mag-ang 'complex
       (lambda (r a) (tag (make-from-mag-ang r a))))
  'done)
(install-complex-package)

; Programs outside the complex-number package can construct complex numbers
; either from real and imaginary parts or from magnitudes and angles. Notice
; how the underlying procedures, originally defined in the rectangular and
; polar packages, are exported to the complex package, and exported from there
; to the outside world.

(define (make-complex-from-real-imag x y)
  ((get 'make-from-real-imag 'complex) x y))
(define (make-complex-from-mag-ang r a)
  ((get 'make-from-mag-ang 'complex) r a))

(make-complex-from-real-imag 3 4)
(make-complex-from-mag-ang 3 0.2)

; What we have here is a two-level tag system. A typical complex number, such
; as 3 + 4i in rectangular form, would be represented as shown in Figure 2.24.
; The outer tag (complex) is used to direct the number to the complex package.
; Once within the complex package, the next tag (rectangular) is used to direct
; the number to the rectangular package. In a large and complicated system
; there might be many levels, each interfaced with the next by means of generic
; operations. As a data object is passed "downward," the outer tag that is used
; to direct it to the appropriate package is stripped off (by applying contents)
; and the next level of tag (if any) becomes visible to be used for further
; dispatching.

; In the above packages, we used add-rat, add-complex, and the other arithmetic
; procedures exactly as originally written. Once these definitions are internal
; to different installation procedures, however. they no longer need names that
; are distinct from each other: we could simply name them add, sub, mul, and
; div in both packages.


; 2.5.2 Combining Data of Different Types
; 