(declare-project 
  :name "scrap"
  :description "Pipe data to/from a configured location"
  :author "Andrew Owen <yumaikas94@gmail.com>"
  :dependencies [ :path :spork ]
  )


(declare-executable :name "scrap" :entry "scrap.janet" :install true)
(declare-executable :name "jag" :entry "jag.janet" :install true)

