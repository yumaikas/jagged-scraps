(defn main [_ to & args]
  (os/cd to)
  (os/execute args :p))
