;; core-keybinds.lisp

(defmacro def-key! (map key command)
  "Wrapper around `define-key'.
MAP and COMMAND remain unaffected, same syntax.
KEY is a string which expands to (kbd \"KEY\").

@example
(define-key *top-map* (kbd \"s-K\") \"kill\")
(def-key! *top-map* \"s-K\" \"kill\")
@end example

Both expressions are equivalent."
  `(stumpwm:define-key ,map (stumpwm:kbd ,key) ,command))
