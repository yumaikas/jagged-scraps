(import ./rej)

(defn catchy [f] 
  (try (f)
    ([err fib]
     (if (tuple? err)
       (eprint (string/format "%q" err))
       (propagate err fib)))))

(defn dispatch [&opt key] 
  (if key
    (print (rej/search key))
    (eprint "usage: rf <term> -- find <term> in REJ_DB")))

(defn main [_ &opt key] 
  (catchy (fn [] (dispatch key))))
