module LolKanren
  extend self
  # Nondeterministic functions
  def fail
    ->(x) { [] }
  end

  def succeed
    ->(x) { [x] }
  end

  def _disj
    ->(f1, f2) {
      ->(x) { [] + f1[x] + f2[x] }
    }
  end

  def disj
    ->(*fs) {
      return fail unless fs.any?
      _disj.call(fs.first, disj.call(*fs[1..-1]))
    }
  end

  def _conj
    ->(f1, f2) {
      ->(x) { f1[x].flat_map &f2 }
    }
  end

  def conj
    ->(*fs) {
      if fs.empty?
        succeed
      elsif fs.one?
        fs.first
      else
        _conj.call(fs.first, ->(s){ conj.call(*fs[1..-1])[s] })
      end
    }
  end

  # Logic variables

  def lvar
    ->(name) { "_.#{name}" }
  end

  def is_lvar
    ->(v) { v.kind_of?(String) && v[0..1] == "_." }
  end

  def empty_subst
    {}
  end

  def ext_s
    ->(var, val, s) { s.merge(var => val) }
  end

  def lookup
    ->(var ,s) {
      if !is_lvar[var]
        var
      elsif s[var]
        lookup.call(s[var], s)
      else
        var
      end
    }
  end

  def unify
    ->(t1, t2, s) {
      t1 = lookup[t1, s]
      t2 = lookup[t2, s]
      if t1 == t2
        s
      elsif is_lvar[t1]
        ext_s[t1, t2, s]
      elsif is_lvar[t2]
        ext_s[t2, t1, s]
      elsif t1.kind_of?(Array) && t2.kind_of?(Array)
        s = unify[t1.first, t2.first, s]
        s = unify.call(t1[1..-1], t2[1..-1], s) unless s.nil?
        s
      end
    }
  end

  %w(x y z q).each do |var|
    define_method("v#{var}") { lvar[var] }
  end

  # Logic engine

  def eq
    ->(t1, t2) {
      ->(s) {
        r = unify[t1, t2, s]
        r ? succeed[r] : fail[r]
      }
    }
  end

  def membero
    ->(var, *list) {
      return fail if list.empty?
      return disj[eq[var, list.first]], membero[var, list[1..-1]]
    }
  end

  def joino
    ->(a, b, l) { eq.call([a, b], l) }
  end

  def _lookup
    ->(var, s) {
      v = lookup[var, s]
      if is_lvar(v)
        v
      elsif v.kind_of?(Array)
        if v.empty?
          v
        else
          [_lookup[v.first, s]] + _lookup[v[1..-1], s]
        end
      else
        v
      end
    }
  end

  def run
    ->(v, g) {
      if v.kind_of?(Proc)
        g,v = v,nil
      end
      r = g[empty_subst]
      if v.nil?
        r
      else
        r.map &->(s) { _lookup[v, s] }
      end
    }
  end
end
