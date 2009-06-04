require 'test_helper'

class RegexpWithNamedGroupsTest < Test::Unit::TestCase
  Strexp = Rack::Mount::Strexp

  if Rack::Mount::Const::SUPPORTS_NAMED_CAPTURES
    def test_compile
      assert_equal %r{^foo$}, Strexp.compile('foo')
      assert_equal eval('%r{^foo/(?<bar>[^/]+)$}'), Strexp.compile('foo/:bar', {}, ['/'])
      assert_equal eval('%r{^(?<foo>.+)\.example\.com$}'), Strexp.compile(':foo.example.com')
      assert_equal eval('%r{^foo/(?<bar>[a-z]+)$}'), Strexp.compile('foo/:bar', {:bar => /[a-z]+/}, ['/'])
      assert_equal eval('%r{^foo(\.(?<extension>.+))?$}'), Strexp.compile('foo(.:extension)')
      assert_equal eval('%r{^src/(?<files>.+)$}'), Strexp.compile('src/*files')
    end
  else
    def test_compile
      assert_equal %r{^foo$}, Strexp.compile('foo')
      assert_equal %r{^foo/(?:<bar>[^/]+)$}, Strexp.compile('foo/:bar', {}, ['/'])
      assert_equal %r{^(?:<foo>.+)\.example\.com$}, Strexp.compile(':foo.example.com')
      assert_equal %r{^foo/(?:<bar>[a-z]+)$}, Strexp.compile('foo/:bar', {:bar => /[a-z]+/}, ['/'])
      assert_equal %r{^foo(\.(?:<extension>.+))?$}, Strexp.compile('foo(.:extension)')
      assert_equal %r{^src/(?:<files>.+)$}, Strexp.compile('src/*files')

      # Pending
      # assert_equal %r{^/foo(/bar)?$}, Strexp.compile('/foo(/bar)')
      # assert_equal %r{^/foo(/bar)?(/baz)?$}, Strexp.compile('/foo(/bar)(/baz)')
      # assert_equal %r{^/foo\(/bar\)$}, Strexp.compile('/foo\(/bar\)')
      # assert_equal %r{^/foo\((/bar)?$}, Strexp.compile('/foo\((/bar)')
      # assert_raise(ArgumentError) { Strexp.compile('/foo((/bar)') }
    end
  end
end
