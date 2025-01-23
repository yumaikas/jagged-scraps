(import spork/path)
(defn parse-args [opts args] 
  (match args
    ["-abs" & rest] (do (put opts :print-absdir true) (parse-args opts rest))
    ["-D" & rest] (do (put opts :show-dirs false) (parse-args opts rest))
    ["-F" & rest] (do (put opts :show-files false) (parse-args opts rest))
    [arg & rest] (do 
            (put opts :to-list (get opts :to-list @[]))
            (array/push (get opts :to-list)  arg)
            (parse-args opts rest))
    [] opts
  ))

(defn print-loc [opts loc] 
  (if (opts :print-absdir)
    (print (path/abspath loc))
    (print loc)))

(defn maybe-print-path [opts p] 
  (def info (os/stat p))
  (cond
    (and (get opts :show-dirs true) (= (info :mode) :directory)) 
    (print-loc opts p)
    (and (get opts :show-files true) (= (info :mode) :file)) 
    (print-loc opts p)))

(defn main [_ & args] 
  (def opts (parse-args @{} args))

  (cond
    (opts :to-list) (each d (opts :to-list) 
                      (os/cd (path/abspath d))
                      (each p (os/dir ".") (maybe-print-path opts p)))
    true (each p (os/dir ".") (maybe-print-path opts p))))
