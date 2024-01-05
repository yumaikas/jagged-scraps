(declare-project 
  :name "scrap"
  :description "Pipe data to/from a configured location"
  :author "Andrew Owen <yumaikas94@gmail.com>"
  :dependencies [ 
                 :path 
                 :spork 
                 "https://github.com/andrewchambers/janet-jdn.git"
                 ]
  )

(declare-executable :name "scrap" :entry "scrap.janet" :install true)
(declare-executable :name "jdoc" :entry "jdoc.janet" :install true)
(declare-executable :name "jag" :entry "jag.janet" :install true)
(declare-executable :name "proc" :entry "proc.janet" :install true)
(declare-executable :name "rej" :entry "rej.janet" :install true)
(declare-executable :name "rk" :entry "rk.janet" :install true)
(declare-executable :name "rf" :entry "rf.janet" :install true)
(declare-executable :name "relp" :entry "relp.janet" :install true)

