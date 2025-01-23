(import spork/path :as path)
(import jdn)
(import spork/regex)

(def *REJ-DB* "REJ_DB")

(defn usage [] 
  `
    rej(istry): A CLI kv store for use in scripts.

rej get <key> <output>? -- 
rej set <key> <value> -- Set 
rej del <key> -- Delete value under key
rel find term -- List keys from min to max, inclusive

<value>
	<string>

 
  `
  )

(def- unimpl `
<value>
	-o (<key> <value>){1,}
	-j <JSON String>
	-F <filepath>
<output>
	-J output as JSON
	-O output as rel kvo syntax
	-Y output as yaml (?)
  `)


(defn- load [&opt path] 
  (def db-path (or path (os/getenv *REJ-DB*) (error [:env-missing *REJ-DB*])))
  (match (slurp db-path) 
    (s (empty? s)) @{} 
    (s (buffer? s)) (jdn/decode s)))

(defn- save [db &opt path] 
  (def db-path (or path (os/getenv *REJ-DB*) (error [:env-missing *REJ-DB*])))
  (spit db-path (jdn/encode db)))

(defn- get-value [key] (get (load) key))

(defn- set-value [key value]
  (let [db (load)]
    (put db key value)
    (save db)))

(defn search [term] 
  (let [db (load)
        patt (regex/compile term)]
    (eachk k db
      (when (regex/find patt k)
        (print k ": " (get db k))))))
  

(defn catchy [f] 
  (try (f)
    ([err fib]
     (if (tuple? err)
       (eprint (string/format "%q" err))
       (propagate err fib)))))

(defn main [_ & args] 
  (catchy 
    (fn []
      (match args
        ["get" key] (print (get-value key))
        ["set" key value] (set-value key value)
        ["del" key] (set-value key nil)
        ["find" term] (search term)
        _ (print (usage))
        ))))

(defn get [key] (get-value key))
(defn put [key value] (set-value key value))
