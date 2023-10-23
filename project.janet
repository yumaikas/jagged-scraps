(declare-project 
  :name "scrap"
  :description "Pipe data to/from a configured location"
  :author "Andrew Owen <yumaikas94@gmail.com>"
  :dependencies ["spork"])

(declare-executable :name "scrap" :entry "scrap.janet")
(declare-executable :name "jag" :entry "jag.janet")

