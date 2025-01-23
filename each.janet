(import spork/regex)
(defn usage [] 
  (print 
```
each -- execute a command for each input line from STDIN

arguments:

-p   A peg-style regex to parse the input line. If matched, @0-9 have results

-s   split the input line on spaces.
-S   DELIM split the input line on DELIM.

-- Stop processing normal args, and place the rest of the args on the subcommand

each 'echo @'

```
  ))

(defn parse-args [opts args] 
  (match args
    ["-p" patt & rest] (do (put opts :patt patt) (parse-args opts rest))
    ["-s" & rest] (do (put opts :split-on " ") (parse-args opts rest))
    ["-S" DELIM & rest] (do (put opts :split-on DELIM) (parse-args opts rest))
    ["--" & rest] (do
                   (put opts :cmd (get opts :cmd @[]))
                   (array/push (opts :cmd) ;rest)
                   opts)
    [arg & rest] (do 
                   (put opts :cmd (get opts :cmd @[]))
                   (array/push (opts :cmd) arg)
                   (parse-args opts rest))
    [] opts
  ))

(defn cmd-of [args line m]
  (var has-mismatch false)
  (def cmd
    (seq [a :in args] 
      (cond
        (= a "@") line
        (and (string/has-prefix? "@" a) m)
        (do
          (def k (scan-number (slice a 1)))
          (if (and k (get m k)) (get m k) (do (set has-mismatch true) a)))
        true a)
      ))
  (unless has-mismatch cmd)
  )

(defn args-of [opts] (mapcat |(string/split " " $) (opts :cmd)))

(defn exec-split-line [opts line]
  (def sep (opts :split-on))
  (def line-data (string/split sep line))
  (cmd-of (args-of opts) line line-data))

(defn exec-line [opts line] 
  (cmd-of (args-of opts) line @{}))

(defn exec-match-line [opts line] 
  (def line-data (regex/match (opts :patt) line))
  (when line-data
    (cmd-of (args-of opts) line line-data)))


(defn main [_ & args] 
  (def config (parse-args @{} args))
  (unless 
    (config :cmd) 
    (usage) 
    (error "Command required for `each`"))

  (def patt (when (config :patt) (regex/compile (config :patt))))
  (def args  (mapcat |(string/split " " $) (config :cmd)))
  (each line (file/lines stdin)
    (def line (string/trim line))

    (def cmd (cond
               (config :split-on) (exec-split-line config line)
               (config :patt) (exec-match-line config line)
               true (exec-line config line)))

    (when cmd
      (def exit-code (os/execute cmd :p))
      (unless (= exit-code 0) 
        (errorf "Command failed for %s" line)))))
