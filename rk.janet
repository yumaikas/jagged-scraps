(import ./rej)

(defn catchy [f] 
  (try (f)
    ([err fib]
     (if (tuple? err)
       (eprint (string/format "%q" err))
       (propagate err fib)))))

(defn dispatch [&opt key] 
  (if key
    (print (rej/get key))
    (eprint "usage: rk <key> -- get <key> from REJ_DB")))

(defn main [_ &opt key] 
  (catchy (fn [] (dispatch key))))
