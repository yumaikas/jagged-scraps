(import spork/regex)
(defn usage [] 
  (print 
```
each -- execute a command for each input line from STDIN
args

-p   A peg-style regex to parse the input line. If matched, @0-9 have results
      Otherwise, @ refers to the whole line.

each 'echo @'

```
  ))

(defn parse-args [opts args] 
  (match args
    ["-p" patt & rest] (do (put opts :patt patt) (parse-args opts rest))
    [arg & rest] (do 
                   (put opts :cmd (get opts :cmd @[]))
                   (array/push (opts :cmd) arg)
                   (parse-args opts rest))
    [] opts
  ))

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
    (def line-match (when patt (regex/match patt line)))

    (var mismatch false)

    (def cmd (seq [a :in args] 
               (cond
                 (= a "@") line
                 (and (string/has-prefix? "@" a) patt line-match) 
                 (or (get line-match (scan-number (slice a 1))) 
                     (set mismatch true)
                     )

                  true a)
                 )
               )
    (unless mismatch
      (def exit-code (os/execute cmd :p))
      (unless (= exit-code 0) 
        (errorf "Command failed for %s" line)))))
