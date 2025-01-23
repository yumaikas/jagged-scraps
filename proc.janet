(import spork/path :as path)
(import jdn)

(def *SCRAP-PROC-DB* "SCRAP_PROC_DB")

(defn usage []
  `
  proc: Run and register scripts

  proc def <name> <interp> <script> <args>:   Registers <script> as <name> exeuted with <interp> and <args>
  proc def-here <name> <cmdline>:  Registers command under <name>
  proc rm <name>: Removes the command under <name>
  proc <script>: Runs script previous registered under <name>
  `)

(defn- ensure-file [path default-contents] 
  (let [path-mode (os/stat path :mode)
        valid (or (nil? path-mode) (= path-mode :file))]
    (if valid 
      (when (nil? path-mode) (spit path default-contents))
      (error [:invalid-path path]))))

(defn assert-setup [] 
  (or (os/getenv *SCRAP-PROC-DB*) (error [:missing-env-var *SCRAP-PROC-DB*]))
  (or (= (os/stat (os/getenv *SCRAP-PROC-DB*) :mode) :file) (error [:db-env-path-not-file (os/getenv *SCRAP-PROC-DB*)]))
  (ensure-file (os/getenv *SCRAP-PROC-DB*) (jdn/encode @{})))

(defn remove [name]
  (let [
        path (os/getenv *SCRAP-PROC-DB*)
        db (jdn/decode (slurp path))]
    (spit path (jdn/encode (put db (thaw name) nil)))))

(defn register [name interp script & args]
  (let  [ path (os/getenv *SCRAP-PROC-DB*)
         db (jdn/decode (slurp path)) ]
    (or (nil? (get db name)) (error [:script-exists name]))
    (put db name { :interp interp :script (path/abspath script) :args args })
    (spit path (jdn/encode db))))

(defn register-here [name interp script & args]
  (let  [path (os/getenv *SCRAP-PROC-DB*)
         db (jdn/decode (slurp path))]
    (or (nil? (get db name)) (error [:script-exists name]))
    (put db name { :pwd (os/cwd) :interp interp :script (path/abspath script) :args args })
    (spit path (jdn/encode db))))

(defn list-scripts [] 
  (let  [path (os/getenv *SCRAP-PROC-DB*)
         db (jdn/decode (slurp path))]
    (map print (keys db))))

(defn exec-script [name]
  (let  [path (os/getenv *SCRAP-PROC-DB*)
         db (jdn/decode (slurp path)) 
         proc-def (get db name)]
    (if proc-def
      (do
        (when (proc-def :pwd) (os/cd (proc-def :pwd)))
        (os/execute [(proc-def :interp) (proc-def :script) ;(proc-def :args)] :p))
      (error [:script-does-not-exist name])
      )))

(defn main [_ & args] 
  (try 
    (do
      (assert-setup)
      (match args
        ["def" name interp script] (register name interp script ;(slice args 4))
        ["def-here" name] (register-here name ;(slice args 2))
        ["rm" name] (remove name)
        ["ls"] (list-scripts)
        ["help"] (print usage)
        [name] (exec-script name)
        ))
    ([err fib]
     (if (tuple? err)
       (eprint (string/format "%q" err))
       (propagate err fib)))))
