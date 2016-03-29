class Hash
  def deep_fetch(k, dv = nil)
    do_deep_fetch(k.split('.'), dv)
  end

  protected

  def do_deep_fetch(ks, dv)
    if ks.length == 1
      fetch(ks.first, dv)
    else
      fetch(ks.first, {}).do_deep_fetch(ks[1..-1], dv)
    end
  end
end
