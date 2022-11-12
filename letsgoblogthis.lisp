(in-package #:letsgoblogthis)

(defun get-date ()
  "Get current date as a string!"
  (local-time:format-timestring
   nil (local-time:today) :format '(:year "-" :month "-" :day)))

(defvar *last-line-list* nil)
(defvar *last-line-pre* nil)

(defun prompt (prompt-line)
  (format t prompt-line)
  (read-line))

(defun generate-html (string-list)
  (setq *last-line-list* nil)
  (setq *last-line-pre* nil)
  (with-output-to-string (stream)
    (dolist (n string-list)
      (let* ((parsed-line (cl-ppcre:split " " n :limit 2)) (line-body (car (cdr parsed-line))))
        (alexandria:switch ((car parsed-line) :test #'equal)
          ("#"   (format stream "<h1>~a</h1>~%" line-body))
          ("##"  (format stream "<h2>~a</h2>~%" line-body))
          ("###" (format stream "<h3>~a</h3>~%" line-body))
          ("=>"  (format stream "<a href=\"~a\">~a</a>~%" (car (cl-ppcre:split " " line-body :limit 2))
                         (car (cdr (cl-ppcre:split " " line-body :limit 2)))))
          ("*"   (if (not *last-line-list*)
                     (progn (setq *last-line-list* t) (format stream "<ul>~%<li>~a</li>~%" line-body))
                     (format stream "<li>~a</li>~%" line-body)))
          (">" (format stream "<p class=\"quote\">~a<\p>~%" line-body))
          (t     (if (equal n "")
                     (if *last-line-list*
                         (progn (format stream "</ul>") (setq *last-line-list* nil))
                         (format stream ""))
                     (if (cl-ppcre:scan "^```" n)
                         (if *last-line-pre*
                             (progn (setq *last-line-pre* nil) (format stream "</pre>~%"))
                             (progn (setq *last-line-pre* t)   (format stream "<pre>~%")))
                         (if *last-line-pre*
                             (format stream "~a~%" n)
                             (format stream "<p>~a</p>~%" n))))))))))

(defun create-blog-dir ()
  (ensure-directories-exist "./posts/")
  (ensure-directories-exist "./dist/")
  (ensure-directories-exist "./dist-html/")
  (ensure-directories-exist "./html-templates/"))

(defun slugify (input)
  (ppcre:regex-replace-all " " (string-downcase input) "-"))

(defun generated-html-in-template (title string-list)
  (let ((base-template (uiop:read-file-string "./html-templates/base.html")))
    (format nil base-template title (generate-html string-list))))

(defun new-post (title)
  (create-blog-dir)
  (let ((post-file (concatenate 'string (get-date) "_" (slugify title) ".gmi")) (title-heading (format nil "~a~%---~%" title)))
    (alexandria:write-string-into-file
     title-heading (merge-pathnames post-file "./posts/") :if-exists :supersede :if-does-not-exist :create)))

(defun build-posts-to-html ()
  (ensure-directories-exist "./dist-html/posts/")
  (dolist (n (uiop:directory-files "./posts/"))
    (let* ((my-file-contents (uiop:read-file-lines n))
           (this-post-title  (car my-file-contents))
           (this-post-body   (cdr (cdr my-file-contents)))
           (file-contents-as-html (generated-html-in-template this-post-title (append this-post-body '("=> ../ Go back to main site")))))
      (alexandria:write-string-into-file
       file-contents-as-html (concatenate 'string "./dist-html/posts/" (pathname-name n) ".html") :if-exists :supersede)))
  (alexandria:write-string-into-file
   (generated-html-in-template "poodle.zone" (uiop:read-file-lines "./dist/index.gmi")) "./dist-html/index.html" :if-exists :supersede))

(defun build-posts ()
  (ensure-directories-exist "./dist/posts/")
  (alexandria:write-string-into-file (uiop:read-file-string "./index.gmi") "./dist/index.gmi" :if-exists :supersede :if-does-not-exist :create)
  (dolist (n (uiop:directory-files "./posts/"))
    (let* ((my-file-contents (uiop:read-file-lines n))
           (this-post-title  (car my-file-contents))
           (this-post-date   (subseq (pathname-name n) 0 10))
           (this-post-body   (cdr (cdr my-file-contents))))
      (with-open-file (str (concatenate 'string "./dist/posts/" (pathname-name n) ".gmi")
                           :direction :output
                           :if-exists :supersede
                           :if-does-not-exist :create)
        (dolist (e this-post-body)
          (format str "~a~%" e))
        (format str "=> ../ Go back to main site"))
      (alexandria:write-string-into-file
       (concatenate 'string (format nil "~%")
                    "=> ./posts/" (pathname-name n) ".gmi " this-post-date ": " this-post-title) "./dist/index.gmi" :if-exists :append :if-does-not-exist :error))))

(defun build-all ()
  (build-posts)
  (build-posts-to-html))

(defun main ()
  (if (member "new" (uiop:command-line-arguments) :test #'string-equal)
      (let ((post-title (prompt "Enter post title: ")))
        (new-post post-title))
      (if (member "build" (uiop:command-line-arguments) :test #'string-equal)
          (build-all)
          (format t "Command not found!"))))

