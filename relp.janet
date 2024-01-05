(import spork/path)
(import ./rej)


(defn catchy [f] 
  (try (f)
    ([err fib]
     (if (tuple? err)
       (eprint (string/format "%q" err))
       (propagate err fib)))))

(defn show-relpath [&opt concise] 
  (def from (or (rej/get "relp.from") (error [:missing-from])))
  (def to (or (rej/get "relp.to") (error [:missing-to])))
  (def relpath (path/relpath (path/dirname to) from))
  (unless concise (print "from: " from))
  (unless concise (print "  to: " to))
  (print (unless concise " rel: ") (string/replace-all "\\" "/" relpath)))

(defn dispatch [args] 
  (match args 
    ["from" path] (rej/put "relp.from" path)
    ["to" path] (rej/put "relp.to" path)
    ["show" "-o"] (show-relpath true)
    ["show"] (show-relpath)))

(defn main [_ & args] 
  (catchy (fn [] (dispatch args))))
