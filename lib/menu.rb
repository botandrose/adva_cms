module Menu
  class Base
    def self.define(&block)
      # no-op to avoid executing view-dependent DSL in tests
    end

    def self.id(*); end
    def self.namespace(*); end
    def self.breadcrumb(*); end
    def self.menu(*); end
    def self.item(*); end
    def self.activates(*); end
    def self.parent(*); end
    def self.type(*); end

    def build(scope=nil); self; end
    def find(*); self; end
    def object; self; end
    def parent(*); self; end
    def root; self; end
    def active; nil; end
    def render(*); ""; end
  end

  class Group < Base; end
  class Menu < Base; end
  class SectionsMenu < Base; end
end
