require 'minitest/spec'
require 'minitest/autorun'
require 'pry'

require_relative 'lol_kanren'

K = LolKanren

describe LolKanren do
  describe "nondeterministic functions" do
    it "fail/succeed" do
      K.fail[5].must_equal []
      K.succeed[5].must_equal [5]
    end

    it "disj/conj" do
      f1 = ->(x) { K.succeed[x + "foo"] }
      f2 = ->(x) { K.succeed[x + "bar"] }
      f3 = ->(x) { K.succeed[x + "baz"] }

      K.disj[f1, f2, f3]["a "].must_equal ["a foo", "a bar", "a baz"]
      K.conj[f1, f2, f3]["a "].must_equal ["a foobarbaz"]
    end
  end

  describe "logic variables" do
    it "primitives" do
      K.is_lvar[K.lvar["ohai"]].must_equal true

      vx, vy = K.lvar['x'], K.lvar['y']
      s = K.ext_s[vx, vy, K.empty_subst]

      s.must_equal({vx => vy})
      K.empty_subst.must_equal({})

      s = K.ext_s[vy, 1, s]
      s.must_equal({vx => vy, vy => 1})
      K.empty_subst.must_equal({})

      K.lookup[vy, s].must_equal 1
      K.lookup[vx, s].must_equal 1
    end

    it "unify x and y" do
      K.unify[K.vx, K.vy, K.empty_subst].must_equal({"_.x" => "_.y"})
    end

    it "unify x and y with y == 1 and lookup x" do
      K.lookup[K.vy, K.unify[K.vx, 1, K.unify[K.vx, K.vy, K.empty_subst]]].must_equal 1
    end

    it "unify (x,y) with (y,1)" do
      K.unify[[K.vx, K.vy], [K.vy, 1], K.empty_subst].must_equal({"_.x" => "_.y", "_.y" => 1})
    end
  end

  describe "logic engine" do
    it "2 is a member of [1, 2, 3]" do
      res = K.membero[2, [1, 2, 3]]
      K.run[res].must_equal [{}]
    end
  end

end
