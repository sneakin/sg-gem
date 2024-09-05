# frozen_string_literal: true
include T('default/module')

def init
  super
end

def format_object_title obj
  obj.title
end

def children
  @refs = object[:refinements]
  erb(:refinements)  
end
