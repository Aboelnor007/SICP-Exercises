#lang racket

; 2.2 Hierarchical Data and the Closure Property

; As we have seen , pairs provide a primitive "glue" that we can use to construct compound data 
; objects. Cons can be used to combine not only numbers but pairs as well. As a consequence, pairs
; provide a universal building block from which we can construct all sorts of data structures.

; The ability to create pairs whose elements are pairs is the essence of list structure's importance
; as a representational tool. We refer to this ability as the closure property of cons. In general,
; an operation for combining data objects satisfies the closure property if the results of combining 
; things with that operation can themselves be combined using the same operation. Closure is the key
; to power in any means of combination because it permits us to create hierarchical structures --
; structures made up of parts, which themselves are made up of parts, and so on.


; 2.2.1 Representing Sequences
; One of the useful structures we can build with pairs is a sequence -- an ordered collection of
; data objects. There are, of course, many ways to represent sequences in terms of pairs. One
; particularly striaghtforward representation is shown below for the sequence 1, 2, 3, 4.

(cons 1
      (cons 2
            (cons 3
                  (cons 4 '()))))

; The car of each pair is the corresponding item in the chain, and the cdr of the pair is the next
; pair in the chain. The cdr of the final pair signals the end of the sequence by pointing to a
; distinguished value that is not a pair (nil in scheme or empty list in Racket '())

; Such a sequence of pairs, formed by nested conses is called a list. There is a primitive for such
; a construct called list

(list 1 2 3 4)

(define one-through-four (list 1 2 3 4))
one-through-four

; We can think of car as selecting the first item in the list, and of cdr as selecting the sublist 
; consisting of all but the first item. Nested applications of car and cdr can be used to extract
; the second, third, and subsequent items in the list. The constructor cons makes a list like the 
; original one but with an additional item at the beginning.

(car one-through-four)

(cdr one-through-four)
(car (cdr one-through-four))

(cons 10 one-through-four)
(cons 5 one-through-four)


; List operations
; The use of pairs to represent sequences of elements as lists is accompanied by conventional
; programming techniques for manipulating lists by successively "cdring down" the lists. For example
; the procedure list-ref takes as arguments a list and a number n and returns the nth item of the list.
; It is customary to number the elements of the list beginning with 0. The method for computing
; list-ref is the following:
; - For n = o, list-ref should return the car of the list
; - Otherwise, list-ref shold return the (n-1)st item of the cdr of the list

(define (list-ref items n)
  (if (= n 0)
      (car items)
      (list-ref (cdr items) (- n 1))))

(define squares (list 1 4 9 16 25))
(list-ref squares 3)

; Often we cdr down the whole list. To aid in this, Racket includes a primitive predicate null?,
; which tests whether its argument is the empty list. The procedure length, which returns the number 
; of items in a list, illustrates this typical pattern of use:

(define (length items)
  (if (null? items)
      0
      (+ 1 (length (cdr items)))))

(define odds (list 1 3 5 7))

(length odds)

; The length procedure implements a simple recursive plan. The reduction step is:
; - The length of any list is 1 plus the length of the cdr of the list

; This is applied successively until we reach the base case:
; - The length of the empty list is 0.

; We could also compute length in an iterative style:

(define (length2 items)
  (define (length-iter a count)
    (if (null? a)
        count
        (length-iter (cdr a) (+ 1 count))))
  (length-iter items 0))
(length2 odds)

; Another conventional programming technique is to "cons up" an answer list while cdring down a
; list, as in the procedure append, which takes two lists as arguments and combines their elements
; to make a new list:

(append squares odds)
(append odds squares)

; Append is also implmented using a recursive plan. To append lists list1 and list2, do the following
; - If list1 is the empty list, then the result is just list2
; - Otherwise, append the cdr of list1 and list 2, and cons the car of list1 onto the result

(define (append2 list1 list2)
  (if (null? list1)
      list2
      (cons (car list1) (append (cdr list1) list2))))
(append2 squares odds)
(append2 odds squares)


; Mapping over lists
; One extremely useful operation is to apply some transformation to each element in a list
; and generate the list of results. For instance, the following procedure scales each number
; in a list by a given factor

(define (scale-list items factor)
  (if (null? items)
      '()
      (cons (* (car items) factor)
            (scale-list (cdr items) factor))))
(scale-list (list 1 2 3 4 5) 10)
; (10 20 30 40 50)

; We can abstract this general idea and capture it as a common pattern expressed as a higher-order
; procedure, just as in section 1.3. The higher-order procedure here is called map. Map takes as
; arguments a procedure of one argument and a list, and returns a list of the results produced
; by applying the procedure to each element in the list

(define (map proc items)
  (if (null? items)
      '()
      (cons (proc (car items))
            (map proc (cdr items)))))
(map abs (list -10 2.5 -11.6 17))
; (10 2.5 11.6 17)

(map (lambda (x) (* x x))
     (list 1 2 3 4))
; (1 4 9 16)

; Now we can give a new definition of scale-list in terms of map

(define (scale-list2 items factor)
  (map (lambda (x) (* x factor))
       items))
(scale-list2 (list 1 2 3 4 5) 10)
; (10 20 30 40 50)

; Map is an important construct, not only because it captures a common pattern, but because it
; establishes a higherlevel of abstraction in dealing with lists. In the original definition of 
; scale-list, the recursive structure of the program draws attention to the element-by-element
; processing of the list. Defining scale-list2 in terms of map suppresses that level of detail
; and emphasizes that scaling transforms a list of elements to a list of results. The difference
; between the two definitions is not that the computer is performing a different process (it isn't)
; but that we think about the process differently. In effect, map helps establish an abstraction
; barrier that isolates the implementation of procedures that transform lists from the details
; of how the elements of the list are extracted and combined. Like the barriers shown in figure
; 2.1, this abstraction gives us the flexibility to change the los-level details of how sequences
; are implemented, while preserving the conceptual framework of operations that transform
; sequences to sequences. Section 2.2.3 expands on this use of sequences as a framework for
; organizing programs.
