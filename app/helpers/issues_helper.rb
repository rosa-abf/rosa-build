# -*- encoding : utf-8 -*-
module IssuesHelper
  def tracker_search_field(name, txt, classes = nil)
    str = "<input name='#{name}' id='#{name}' type='text' value='#{txt}'"
    str << "onblur=\"if(this.value==''){this.value='#{txt}';this.className='gray #{classes}';}\""
    str << "onclick=\"if(this.value=='#{txt}'){this.value='';this.className='black #{classes}';}\" class=\"gray #{classes}\">"
    str.html_safe
  end
end
