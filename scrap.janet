(import spork/path)

(def *SCRAP-DIR* "SCRAP_DIR")

(defn usage [] 
  """
  scrap: pipe data to/from a junk dir

  subcommands
  scrap put <name>: Saves stdin to name
  scrap get <name>: Cats <name> to stdout
  scrap add <name>: Appends stdin to name
  scrap map <name> <expr>: Passes each line of <name> through expr
  scrap ls <name?>: Lists the files in <name> scrap workspace, the current one if not provided
  scrap rm <name>: Deletes the <name> file in the current workspace
  scrap update <name> <expr>: Passes each line of <name> through the Janet expr <expr>, nil lines are removed
  scrap current: Gives the current scrap workspace
  scrap ws save <name?>: Saves the current set of scrap files to a backup folder. If <name>
  scrap ws load <name>: Clears the current scrap workspace, and then loads the workspace from <name>
  scrap ws ls: Lists the workspaces
  """
  )

(defn view [arg] 
  (string/format "%q" arg))

(defn- path-of [& elems] 
  (path/join (os/getenv *SCRAP-DIR*) ;elems))

(defn- current-workspace [] 
  (string/trim (slurp (path/join (os/getenv "SCRAP_DIR") "current.txt"))))


(defn stdin-to-fresh-file-trunc [name] 
  (eprint (path-of "index" name))
  (or (not (os/isatty stdin)) (error [:stdin-is-interactive]))
  (with [file (os/open (path-of "index" name) :wct)]
    (loop [line :iterate (:read stdin :line)]
      (:write file line))))

(defn stdin-to-exsting-file [name] 
  (or (not (os/isatty stdin)) (error [:stdin-is-interactive]))
  (with [file (file/open (path-of "index" name) :wa)]
    (loop [line :iterate (:read stdin :line)]
      (:write file line))))

(defn stdout-from-file [name] 
  (with [file (file/open (path-of "index" name))]
    (loop [line :iterate (:read file :line)]
      (:write stdout line))))

(defn map-over-ouput [name expr-str]
  (var nr 0)
  (defn NR? [n] (= nr n))
  # Running with scissors
  (def expr (eval-string (string "|" expr-str)))
  (with [file (os/open (path-of "index" name))]
    (loop [line :iterate (:read file :line)]
      (def updated-line (expr line))
      (when (not (nil? updated-line))
        (:write stdout line))
      (set nr (+ nr 1)))))

(defn update-inplace [name expr-str]
  (var nr 0)
  (def to-update (path-of "index" name))
  (defn NR? [n] (= nr n))
  (with [temp (path-of "temp" name) (os/rm temp)]
    # Running with scissors
    (def expr (eval-string (string "|" expr-str)))
    (with [file (os/open to-update) ]
      (with [dest (os/open temp)]
        (loop [line :iterate (:read file :line)]
          (def updated-line (expr line))
          (when (not (nil? updated-line))
            (:write dest line))
          (set nr (+ nr 1)))))
    (os/rename temp to-update)))

(defn list-files [& file] 
  (each l (os/dir (path-of "index"))
    (print l)))

(defn remove-file [name]
  (if (= (os/stat (path-of "index" name) :mode) :file)
    (os/rm (path-of "index" name))
    (error [:removing-not-file (os/stat (path-of "index"))])))

(defn save-workspace [name] 
  (def from (path-of "index"))
  (def to (path-of "ws" name))

  (each f (os/dir to)
    (when (= (os/stat f :mode) :file)
      (os/rm f)))
  (each f (os/dir from)
    (os/rename (path-of "index" f) (path-of "ws" name f))))

(defn load-workspace [name]
  (def from (path-of "ws" name))
  (def to (path-of "index"))
  (each f (os/dir to)
    (when (= (os/stat f :mode) :file)
      (os/rm f)))
  (each f (os/dir from)
    (spit (path-of "index" f) (slurp (path-of "ws" name f))))
  (spit (path-of "current.txt") name))

(defn list-workspaces []
  (each dir (os/dir (path-of "ws"))
    (print dir)))

(comment
  """
  $SCRAP_DIR/ws/ -- The workspaces directory
  $SCRAP_DIR/current.txt -- The current workspace's name
  $SCRAP_DIR/index/ -- The working copy of the current workspace
  """
  )

(defn- ensure-dir [& subpath] 
  (let [dest (path-of ;subpath)
        exists (= (os/stat dest :mode) :directory) ]
  (unless exists
    (os/mkdir dest))))


(defn- assert-setup []
  (or (os/getenv *SCRAP-DIR*) (error [:missing-env-var *SCRAP-DIR*]))
  (ensure-dir "ws")
  (ensure-dir "index")
  (ensure-dir "temp")
  (match (os/stat (path-of "current.txt") :mode)
    :file (do)
    nil (spit (path-of "current.txt") "notes")
    other (error [:current-file-bad-mode other])))


(defn main [exe & args] 
  (try
    (do
      (assert-setup)

      (match args
        ["put" name] (stdin-to-fresh-file-trunc name)
        ["get" name] (stdout-from-file name)
        ["add" name] (stdin-to-exsting-file name)
        ["map" name expr] (map-over-ouput name expr)
        ["update" name expr] (update-inplace name expr)
        ["ls"] (list-files)
        ["rm" name] (remove-file name)
        ["current"] (print (current-workspace))
        ["ws" "save" name] (save-workspace name)
        ["ws" "load" name] (load-workspace name)
        ["ws" "ls"] (list-workspaces)
        derp (do 
               (print (string "Did not understand some part of " (view  derp)))
               (print (usage)))
        ))
    ([err fib]
     (if (tuple? err)
       (eprint (string/format "%q" err))
       (propagate err fib))
       )
    ))
