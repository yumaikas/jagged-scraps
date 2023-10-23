(import path)
(import spork/regex :as regex)
(defn split-input [file delim] 
  (string/split delim (:read file :all)))

# TODO: Move this into something threadsafe?
(var nr 0)
(defn NR= [n] (= nr n))
(def- mappers @[])
(def- mapped-rows @[])
(var ROW @"")
(def semi ";")
(def- aggs @[])

(defn view [arg] 
  (if (string? arg)
    arg
    (string/format "%q" arg)))

(defn split [delim &opt val] 
  (string/split delim (or val ROW)))

(defn has [sift &opt val] (not (nil? (string/find sift (or val ROW) ))))

(defn num [&opt val] (scan-number (or val ROW)))

(defn regex [patt &opt val]
  (or
    (when-let [locs (regex/find-all patt (or val ROW))]
      (map |(freeze (regex/match patt (or val ROW) $)) locs))
    (error [:regex-nomatch patt (or val ROW)])))

(defn columns [& cols] 
  (zipcoll cols ROW))


(def herp (curenv))
(defn str->fn [str] 
  (def restore-env (curenv))
  (with [_ (fiber/setenv (fiber/current) herp) (fn [&] (fiber/setenv (fiber/current) restore-env))]
    (def maybeFn? (try (eval-string str) ([err _] nil)))
    (if (or (cfunction? maybeFn?) (function? maybeFn?)) maybeFn?
      (eval-string (string "(fn [r] " str ")")))))

(defn str->reducer [str]
  (def restore-env (curenv))
  (with [_ (fiber/setenv (fiber/current) herp) (fn [&] (fiber/setenv (fiber/current) restore-env))]
    (def maybeFn? (try (eval-string str) ([err _] nil)))
    (if (or (cfunction? maybeFn?) (function? maybeFn?)) maybeFn?
      (eval-string (string "(fn [acc el] " str ")")))))
  

(var output @[])
(var pre-output @[])
(var joiner "\n")
(var output-set false)

(defn- jagg-end [& args] 
  (match args
    ["-M" expr-str] (do
                      (def mapper (str->fn expr-str))
                      (set output (map (fn [r] (set ROW r) (mapper r)) output))
                      (jagg-end ;(slice args 2)))
    ["-r" expr-str] (do
                      (def modifier (str->fn expr-str))
                      (set output-set true)
                      (array/concat output (modifier mapped-rows))
                      (jagg-end ;(slice args 2)))
    ["-r*" expr-str] (do 
                      (set output-set true)
                      (def reducer (str->reducer expr-str))
                      (array/concat output (reduce2 reducer mapped-rows))
                      (jagg-end ;(slice args 2)))

    ["-p" pre] (do (array/insert pre-output 0 pre) (jagg-end ;(slice args 2)))
    ["-j" delim] (do (set joiner delim) (jagg-end ;(slice args 2)))
    (q (empty? q)) (if (not output-set)
                     (do
                       (array/concat output mapped-rows)
                       (prin ;(map string pre-output))
                       (print (string/join (map view output) joiner)))
                     (do
                       (cond 
                         (string? output) (print output)

                         true (do
                                (prin ;(map view pre-output))
                                (print (string/join (map view output) joiner))))))
    _ (error [:invalid-args args])
    ))


(var splat? false)

(defn- jagg-main [rows & args] 
  
  (match args
    ["-m" expr-str] (let [expr (str->fn expr-str)]
                      (array/push mappers expr)
                      (jagg-main rows ;(slice args 2)))
    ["-f" expr-str] (let [expr (str->fn expr-str)]
                      (array/push mappers (fn [r] (when (expr r) r)))
                      (jagg-main rows ;(slice args 2)))
    ["-nf" expr-str] (let [expr (str->fn expr-str)]
                      (array/push mappers (fn [r] (unless (expr r) r)))
                      (jagg-main rows ;(slice args 2)))
    ["-%"] (do
              (array/push mappers (fn [r] (set splat? true) r))
              (jagg-main rows ;(slice args 1)))
    _ (do 
        (each r rows 
          (set splat? false)
          (set ROW r)
          (when (> (length mappers) 0)
            (each m mappers
              (unless (nil? ROW)
                (set ROW (m ROW)))))
          (set nr (+ nr 1))

          (if (not (nil? ROW))
            (cond 
              splat? (array/concat mapped-rows ROW)
              true  (array/push mapped-rows ROW))))

          (jagg-end ;args))))

(defn- jagg-get-rows [inputs & args] 

  (match args
    ["-re" patt] (jagg-main (mapcat (fn [input] (regex patt (input))) inputs) ;(slice args 2))
    ["-s" delim] (jagg-main (mapcat (fn [input] (string/split delim (input) )) inputs) ;(slice args 2))
    _ (jagg-main (mapcat (fn [input] (string/split "\n" (input))) inputs) ;args)
  ))

(defn- jagg-sources [inputs & args]

  (defn with-input [input-fn & args]
    (jagg-sources (array/concat inputs input-fn) ;args))

  (match args
    ["-F" file-path] (with-input (fn [] (slurp file-path)) ;(slice args 2))
    ["-C" constant] (with-input (fn [] constant) ;(slice args 2))
    ["-FE" env-var-name] (with-input (fn [] (slurp (os/getenv env-var-name))) ;(slice args 2))
    ["-E" env-var-name] (with-input (fn [] (os/getenv env-var-name)) ;(slice args 2))
    ["-I"] (with-input (fn [] (:read stdin :all)) ;(slice args 1))
    _ (jagg-get-rows 
        (if (> (length inputs) 0) 
          inputs 
          [(fn [] (:read stdin :all))]) 
        ;args)
  ))


(defn- main [_ & args] 
  (try 
    (jagg-sources @[] ;args)
    ([err fib]
      (cond
        (tuple? err) (eprint (view err))
        true (propagate err fib)
        ))))
