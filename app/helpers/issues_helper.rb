# -*- encoding : utf-8 -*-
module IssuesHelper
  def tracker_search_field(name, txt)
    str = "<input name='#{name}' id='#{name}' type='text' value='#{txt}'"
    str << "onblur=\"if(this.value==''){this.value='#{txt}';this.className='gray';}\""
    str << "onclick=\"if(this.value=='#{txt}'){this.value='';this.className='black';}\" class=\"gray\">"
    str.html_safe
  end
end
