
module Flor

  class Loader

    # NB: tasker configuration entries start with "loa_"

    def initialize(unit)

      @unit = unit

      @cache = {}
      @mutex = Mutex.new
    end

    def shutdown
    end

    def variables(domain)

      Dir[File.join(root, '**/*.json')]
        .select { |f| f.index('/etc/variables/') }
        .collect { |pa| [ pa, expose_d(pa, {}) ] }
        .select { |pa, d| is_subdomain?(domain, d) }
        .sort_by { |pa, d| d.count('.') }
        .inject({}) { |vars, (pa, d)| vars.merge!(interpret(pa)) }
    end

    #def procedures(path)
    #
    #  # TODO
    #  # TODO work with Flor.load_procedures
    #end

    # If found, returns [ source_path, path ]
    #
    def library(domain, name=nil, opts={})

      domain, name, opts = [ domain, nil, name ] if name.is_a?(Hash)
      domain, name = split_dn(domain, name)

      if m = name.match(/(\.flor?)\z/)
        name = name[0..m[1].length - 1]
      end

      path, d, n = (Dir[File.join(root, '**/*.{flo,flor}')])
        .select { |f| f.index('/lib/') }
        .collect { |pa| [ pa, *expose_dn(pa, opts) ] }
        .select { |pa, d, n| n == name && is_subdomain?(domain, d) }
        .sort_by { |pa, d, n| d.count('.') }
        .last

      path ? [ Flor.relativize_path(path), File.read(path) ] : nil
    end

    def tasker(domain, name=nil)

      domain, name = split_dn(domain, name)

      path, d, n = Dir[File.join(root, '**/*.json')]
        .select { |pa| pa.index('/lib/taskers/') }
        .collect { |pa| [ pa, *expose_dn(pa, {}) ] }
        .select { |pa, d, n|
          is_subdomain?(domain, [ d, n ].join('.')) ||
          (n == name && is_subdomain?(domain, d)) }
        .sort_by { |pa, d, n| d.count('.') }
        .last

      return nil unless path

      conf = interpret(path)

      return conf if n == name

      con = conf[name]

      return nil unless con

      con.merge!('_path' => conf['_path'])
    end

    protected

    # is da a subdomain of db?
    #
    def is_subdomain?(da, db)

      da == db ||
      db == '' ||
      da[0, db.length + 1] == db + '.'
    end

    def split_dn(domain, name)

      if name
        [ domain, name ]
      else
        elts = domain.split('.')
        [ elts[0..-2].join('.'), elts[-1] ]
      end
    end

    def expose_d(path, opts)

      pa = path[root.length..-1]
      pa = pa[5..-1] if pa[0, 5] == '/usr/'

      libregex =
        opts[:subflows] ?
        /\/lib\/(subflows|flows|taskers)\// :
        /\/lib\/(flows|taskers)\//

      pa
        .sub(/\/etc\/variables\//, '/')
        .sub(libregex, '/')
        .sub(/\/\z/, '')
        .sub(/\/(flo|flor|dot)\.json\z/, '')
        .sub(/\.(flo|flor|json)\z/, '')
        .sub(/\A\//, '')
        .gsub(/\//, '.')
    end

    def expose_dn(path, opts)

      pa = expose_d(path, opts)

      if ri = pa.rindex('.')
        [ pa[0..ri - 1], pa[ri + 1..-1] ]
      else
        [ '', pa ]
      end
    end

    def root

      if lp = @unit.conf['lod_path']
        File.absolute_path(lp)
      else
        File.dirname(File.absolute_path(@unit.conf['_path'] + '/..'))
      end
    end

    def interpret(path)

      @mutex.synchronize do

        mt1 = File.mtime(path)
        val, mt0 = @cache[path]
        #p [ :cached, path ] if val && mt1 == mt0
        return val if val && mt1 == mt0

        (@cache[path] = [ Flor::ConfExecutor.interpret(path), mt1 ]).first
      end
    end
  end
end

