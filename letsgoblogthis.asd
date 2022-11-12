;;;; letsgoblogthis.asd

(asdf:defsystem #:letsgoblogthis
  :description "A simple Gemini/HTML blog tool. Don't use, probably."
  :author "bee"
  :license  "MIT"
  :version "1.0.0"
  :serial t
  :depends-on (#:cl-ppcre #:alexandria #:local-time)
  :components ((:file "package")
               (:file "letsgoblogthis"))
  :build-operation "program-op"
  :build-pathname "lgbt"
  :entry-point "letsgoblogthis:main")
