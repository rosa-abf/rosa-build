class Object
  def with_skip
    begin
      Thread.current[:skip] = true
      yield
    ensure
      Thread.current[:skip] = false
    end
  end
end
