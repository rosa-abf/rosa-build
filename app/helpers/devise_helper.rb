module DeviseHelper
  def getDeviseErrors(*name)
    res = Array.new(name.count)
    resource.errors.each do |attr, message|
      if index = name.index(attr)
        res[index] = message
      end
    end
    res
  end

  def showDeviseHintError(name, error, additional_class = '')
    if error
      "<div id='hint' class='error #{name.to_s} #{additional_class}' style='display: block;'> \
      <div class='img'></div> \
      <div class='msg'> #{error}</div> \
      </div>".html_safe
    end
  end
end
